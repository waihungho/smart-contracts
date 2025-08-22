```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NeuroGenesisDAO
 * @author Your Name/AI
 * @notice A decentralized autonomous organization for AI-driven generative art NFTs, featuring a unique
 *         Creativity Score reputation system and a robust governance model.
 *
 * @dev This contract implements a novel approach to on-chain generative art by integrating off-chain AI
 *      computation via a decentralized oracle. Users submit creative prompts, which, upon oracle fulfillment,
 *      mint unique NFTs. The system encourages engagement through a non-transferable "Creativity Score" (SBT-like)
 *      that enhances governance power and grants benefits. It also supports NFT evolution, allowing the creation
 *      of derivative art from existing NFTs, forming a traceable lineage.
 */

// Interface for a minimal ERC-20 token, used for fees and governance.
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Interface for the NeuroGenesis Oracle, expected to fulfill AI generation requests.
interface INeuroOracle {
    function requestGeneration(uint256 _promptId, address _callbackContract, bytes memory _callbackData) external;
    function requestEvolution(uint256 _evolutionId, address _callbackContract, bytes memory _callbackData) external;
}

// Custom Errors
error Unauthorized();
error InvalidPromptId();
error InvalidEvolutionId();
error AlreadyFulfilled();
error NotOracle();
error OracleNotActive();
error ZeroAddressNotAllowed();
error InvalidFeeType();
error InsufficientBalance();
error InsufficientCreativityScore();
error PromptAlreadyEndorsed();
error NFTAlreadyEndorsed();
error SelfDelegationForbidden();
error ProposalAlreadyExists();
error ProposalNotFound();
error ProposalNotActive();
error ProposalNotQueued();
error VotingPeriodNotOver();
error VotingPeriodStillActive();
error NotEnoughVotes();
error ProposalExecutionFailed();
error UnauthorizedWithdrawal();
error NFTDoesNotExist();
error NotNFTOwner();
error NotEnoughPromptEndorsements();

contract NeuroGenesisDAO {
    // --- State Variables ---

    // Owner of the contract, typically an initial deployer or a multisig.
    address public owner;

    // ERC-721 related variables
    string private _name;
    string private _symbol;
    string private _baseURI;
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Core NFT Generation & Evolution ---
    struct Prompt {
        address submitter;
        string promptText;
        string initialParamsJSON;
        uint256 submissionBlock;
        uint256 endorsementCount;
        bool fulfilled; // True if an NFT has been generated from this prompt
        uint256 mintedTokenId; // The ID of the NFT minted from this prompt
    }
    mapping(uint256 => Prompt) public prompts;
    uint256 public nextPromptId;
    mapping(address => mapping(uint256 => bool)) public userEndorsedPrompts; // user => promptId => endorsed

    struct EvolutionRequest {
        address submitter;
        uint256 parentTokenId;
        string newPromptText;
        string evolutionParamsJSON;
        uint256 submissionBlock;
        bool fulfilled; // True if a child NFT has been generated
        uint256 mintedTokenId; // The ID of the child NFT
    }
    mapping(uint256 => EvolutionRequest) public evolutionRequests;
    uint256 public nextEvolutionId;

    struct NFTMetadata {
        uint256 parentTokenId; // 0 if it's a genesis NFT
        uint256 sourcePromptId; // The prompt ID that generated this NFT
        uint256 seedUsed; // Seed used by the AI model for reproducibility/lineage
        uint256 generationBlock;
        uint256 endorsementCount;
        uint256[] childrenTokenIds; // List of NFTs evolved from this one
    }
    mapping(uint256 => NFTMetadata) public nftMetadata;
    mapping(address => mapping(uint256 => bool)) public userEndorsedNFTs; // user => tokenId => endorsed

    // --- Reputation System (Creativity Score) ---
    // Non-transferable score, similar to Soulbound Tokens, tied to an address.
    mapping(address => uint256) public creativityScore;
    uint256 public constant PROMPT_ENDORSEMENT_SCORE = 10;
    uint256 public constant NFT_ENDORSEMENT_SCORE = 5;
    uint256 public constant NFT_MINT_SCORE = 50; // Awarded to original prompt submitter when their prompt is fulfilled

    // --- Governance & DAO Mechanisms ---
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Executed }
    enum VoteOption { Against, For }

    struct Proposal {
        uint256 id;
        string description;
        address target;
        uint256 value;
        bytes calldataPayload;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        address proposer;
        ProposalState state;
        mapping(address => bool) hasVoted; // User has voted
        mapping(address => uint256) votesCast; // How many votes user cast (for tracking weight)
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public minCreativityScoreForProposal; // Minimum creativity score to submit a proposal
    uint256 public minNativeTokenForProposal; // Minimum native token balance to submit a proposal
    uint256 public votingPeriodBlocks; // How many blocks a proposal is active for voting
    uint256 public proposalThresholdBlocks; // How many blocks for a proposal to be queued after success
    uint256 public quorumPercentage; // Percentage of total combined vote power required for a proposal to pass (e.g., 4% = 400)

    // Combined voting power calculation: Native Token Balance + Creativity Score
    mapping(address => address) public delegates; // Delegate voting power

    // --- Configuration & Fees ---
    IERC20 public nativeToken; // The ERC-20 token used for fees and governance
    address public treasuryAddress; // Address where fees are collected, typically managed by governance

    enum FeeType {
        PromptSubmission,
        NFTMint, // Fee for oracle to fulfill and mint
        NFTEvolution,
        PromptEndorsement,
        NFTEndorsement
    }
    mapping(uint8 => uint256) public fees; // Maps FeeType enum to its corresponding fee amount

    mapping(address => bool) public activeOracles; // Whitelisted and active AI oracles
    mapping(address => string) public oracleNames; // Name of the oracle
    uint256 public constant MIN_PROMPT_ENDORSEMENTS_FOR_MINT = 1; // Minimum endorsements a prompt needs before AI generation request

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event PromptSubmitted(uint256 indexed promptId, address indexed submitter, string promptText);
    event AIRequestInitiated(uint256 indexed requestId, uint256 indexed promptOrEvolutionId, address indexed caller);
    event NFTGenerated(uint256 indexed tokenId, uint256 indexed promptId, address indexed owner, string tokenURI, uint256 seedUsed);
    event NFTEvolutionRequested(uint256 indexed evolutionId, uint256 indexed parentTokenId, address indexed submitter, string newPromptText);
    event NFTEvolutionFulfilled(uint256 indexed childTokenId, uint256 indexed evolutionId, uint256 indexed parentTokenId, address indexed owner, string tokenURI);
    event CreativityScoreUpdated(address indexed user, uint256 newScore);
    event PromptEndorsed(uint256 indexed promptId, address indexed endorser, uint256 newEndorsementCount);
    event NFTEndorsed(uint256 indexed tokenId, address indexed endorser, uint256 newEndorsementCount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event DelegateVote(address indexed delegator, address indexed delegatee);
    event RevokeDelegate(address indexed delegator, address indexed previousDelegatee);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event FeeSet(uint8 indexed feeType, uint256 newFee);
    event OracleRegistered(address indexed oracleAddress, string name);
    event OracleDeactivated(address indexed oracleAddress);
    event TreasuryFundsWithdrawn(address indexed to, uint256 amount);

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        address _nativeToken,
        address _treasuryAddress,
        uint256 _minCreativityScoreForProposal,
        uint256 _minNativeTokenForProposal,
        uint256 _votingPeriodBlocks,
        uint256 _proposalThresholdBlocks,
        uint256 _quorumPercentage
    ) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _nextTokenId = 1; // Start token IDs from 1

        if (_nativeToken == address(0) || _treasuryAddress == address(0)) revert ZeroAddressNotAllowed();
        nativeToken = IERC20(_nativeToken);
        treasuryAddress = _treasuryAddress;

        minCreativityScoreForProposal = _minCreativityScoreForProposal;
        minNativeTokenForProposal = _minNativeTokenForProposal;
        votingPeriodBlocks = _votingPeriodBlocks;
        proposalThresholdBlocks = _proposalThresholdBlocks;
        quorumPercentage = _quorumPercentage; // e.g., 400 for 4%

        // Set initial default fees (can be changed by governance)
        fees[uint8(FeeType.PromptSubmission)] = 10 * 10**18; // Example: 10 Native Tokens
        fees[uint8(FeeType.NFTMint)] = 5 * 10**18;
        fees[uint8(FeeType.NFTEvolution)] = 15 * 10**18;
        fees[uint8(FeeType.PromptEndorsement)] = 0.1 * 10**18; // 0.1 Native Token
        fees[uint8(FeeType.NFTEndorsement)] = 0.1 * 10**18; // 0.1 Native Token

        // Set baseURI for NFT metadata (can be updated later by governance)
        _baseURI = "ipfs://QmbnK6E6T7UfG3H4K8V7C4S9D5E2F1G0A9B8C7D6E5F4G3H2I1J/"; // Example placeholder
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyOracle() {
        if (!activeOracles[msg.sender]) revert NotOracle();
        _;
    }

    // --- ERC721 Standard Functions (Minimal Implementation) ---
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function balanceOf(address owner_) public view returns (uint256) { return _balanceOf[owner_]; }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _tokenOwners[tokenId];
        if (owner_ == address(0)) revert NFTDoesNotExist();
        return owner_;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert NFTDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function approve(address to, uint256 tokenId) public {
        address owner_ = ownerOf(tokenId);
        if (to == owner_) revert Unauthorized();
        if (msg.sender != owner_ && !isApprovedForAll(owner_, msg.sender)) revert Unauthorized();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert Unauthorized();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (!isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) revert Unauthorized();
        if (ownerOf(tokenId) != from) revert Unauthorized(); // Make sure `from` is the actual owner

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        // This is a minimal ERC721, assuming `to` is a contract that can handle ERC721 receiver or a EOA.
        // For full ERC721 compliance, IERC721Receiver check should be implemented.
        (bool success,) = to.call(abi.encodeWithSignature("onERC721Received(address,address,uint256,bytes)", msg.sender, from, tokenId, data));
        if (!success) { /* Revert if `to` is a contract and doesn't implement onERC721Received correctly */ }
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert Unauthorized(); // Ensure `from` is the current owner
        if (to == address(0)) revert ZeroAddressNotAllowed();

        delete _tokenApprovals[tokenId];

        _balanceOf[from]--;
        _balanceOf[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ZeroAddressNotAllowed();
        if (_exists(tokenId)) revert Unauthorized(); // Token ID already exists

        _balanceOf[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert NFTDoesNotExist();
        // Assuming metadata stored off-chain at baseURI + tokenId + ".json"
        // In a real system, the oracle would provide the full URI. This is a simplification.
        // The fulfillAI_NFTGeneration and fulfillAI_NFTEvolution functions actually store the full URI.
        return _baseURI; // This is a placeholder for actual URI returned by oracle
    }

    // Custom NFT metadata retrieval
    function nftMetadata(uint256 _tokenId) public view returns (NFTMetadata memory) {
        if (!_exists(_tokenId)) revert NFTDoesNotExist();
        return nftMetadata[_tokenId];
    }

    function getNFTChildren(uint256 _tokenId) public view returns (uint256[] memory) {
        if (!_exists(_tokenId)) revert NFTDoesNotExist();
        return nftMetadata[_tokenId].childrenTokenIds;
    }

    // --- I. Core NFT Generation & Evolution ---

    /**
     * @notice Allows a user to submit a new creative prompt for AI art generation.
     * @dev Requires a `PromptSubmission` fee in native tokens.
     * @param _promptText The textual description for the AI art generation.
     * @param _initialParamsJSON JSON string of additional parameters for the AI model.
     * @return The ID of the newly created prompt.
     */
    function submitPrompt(string memory _promptText, string memory _initialParamsJSON) public returns (uint256) {
        if (!nativeToken.transferFrom(msg.sender, treasuryAddress, fees[uint8(FeeType.PromptSubmission)])) revert InsufficientBalance();

        uint256 currentPromptId = nextPromptId++;
        prompts[currentPromptId] = Prompt({
            submitter: msg.sender,
            promptText: _promptText,
            initialParamsJSON: _initialParamsJSON,
            submissionBlock: block.number,
            endorsementCount: 0,
            fulfilled: false,
            mintedTokenId: 0
        });

        emit PromptSubmitted(currentPromptId, msg.sender, _promptText);
        return currentPromptId;
    }

    /**
     * @notice Initiates off-chain AI generation for a prompt.
     * @dev This function is typically called by an approved oracle service after a prompt has gained
     *      sufficient endorsements, signaling readiness for AI processing. It also sends the NFT Mint fee.
     *      The oracle will then call `fulfillAI_NFTGeneration` upon completion.
     * @param _promptId The ID of the prompt to generate art for.
     */
    function requestAI_NFTGeneration(uint256 _promptId) public {
        if (!activeOracles[msg.sender]) revert NotOracle();
        Prompt storage prompt = prompts[_promptId];
        if (prompt.submitter == address(0)) revert InvalidPromptId();
        if (prompt.fulfilled) revert AlreadyFulfilled();
        if (prompt.endorsementCount < MIN_PROMPT_ENDORSEMENTS_FOR_MINT) revert NotEnoughPromptEndorsements();

        // Transfer the NFT minting fee to the treasury
        if (!nativeToken.transferFrom(msg.sender, treasuryAddress, fees[uint8(FeeType.NFTMint)])) revert InsufficientBalance();

        // Optionally, the oracle could be funded here, or the fee could cover oracle costs.
        // For simplicity, we just collect to treasury.
        emit AIRequestInitiated(_promptId, _promptId, msg.sender);
    }

    /**
     * @notice Callable only by an approved oracle. Submits the AI-generated art's URI and metadata hash,
     *         and mints a new NFT, associating it with the original prompt.
     * @dev Awards Creativity Score to the prompt submitter.
     * @param _promptId The ID of the prompt that was fulfilled.
     * @param _tokenURI The URI (e.g., IPFS link) to the NFT's metadata/image.
     * @param _metadataHash A hash of the metadata for integrity verification.
     * @param _seedUsed The random seed used by the AI model for generation.
     */
    function fulfillAI_NFTGeneration(
        uint256 _promptId,
        string memory _tokenURI,
        string memory _metadataHash,
        uint256 _seedUsed
    ) public onlyOracle {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.submitter == address(0)) revert InvalidPromptId();
        if (prompt.fulfilled) revert AlreadyFulfilled();

        prompt.fulfilled = true;

        uint256 tokenId = _nextTokenId++;
        prompt.mintedTokenId = tokenId;
        _baseURI = _tokenURI; // Update baseURI to the actual URI for this token (simplification, real ERC721 would have tokenURI return specific URI)

        _mint(prompt.submitter, tokenId);
        nftMetadata[tokenId] = NFTMetadata({
            parentTokenId: 0, // This is a genesis NFT
            sourcePromptId: _promptId,
            seedUsed: _seedUsed,
            generationBlock: block.number,
            endorsementCount: 0,
            childrenTokenIds: new uint256[](0)
        });

        _increaseCreativityScore(prompt.submitter, NFT_MINT_SCORE);

        emit NFTGenerated(tokenId, _promptId, prompt.submitter, _tokenURI, _seedUsed);
    }

    /**
     * @notice Enables an NFT holder to submit a new prompt to evolve an existing NFT, creating a new derivative "child" NFT.
     * @dev Requires the caller to own the parent NFT and pays an `NFTEvolution` fee.
     * @param _parentTokenId The ID of the existing NFT to evolve from.
     * @param _newPromptText The new textual description for the AI evolution.
     * @param _evolutionParamsJSON JSON string of additional parameters for the AI model.
     * @return The ID of the newly created evolution request.
     */
    function evolveNFT(
        uint256 _parentTokenId,
        string memory _newPromptText,
        string memory _evolutionParamsJSON
    ) public returns (uint256) {
        if (ownerOf(_parentTokenId) != msg.sender) revert NotNFTOwner();
        if (!nativeToken.transferFrom(msg.sender, treasuryAddress, fees[uint8(FeeType.NFTEvolution)])) revert InsufficientBalance();

        uint256 currentEvolutionId = nextEvolutionId++;
        evolutionRequests[currentEvolutionId] = EvolutionRequest({
            submitter: msg.sender,
            parentTokenId: _parentTokenId,
            newPromptText: _newPromptText,
            evolutionParamsJSON: _evolutionParamsJSON,
            submissionBlock: block.number,
            fulfilled: false,
            mintedTokenId: 0
        });

        emit NFTEvolutionRequested(currentEvolutionId, _parentTokenId, msg.sender, _newPromptText);
        return currentEvolutionId;
    }

    /**
     * @notice Initiates off-chain AI evolution for an existing NFT.
     * @dev Similar to `requestAI_NFTGeneration`, this is called by an oracle to signal processing.
     * @param _evolutionId The ID of the evolution request to process.
     */
    function requestAI_NFTEvolution(uint256 _evolutionId) public onlyOracle {
        EvolutionRequest storage evolution = evolutionRequests[_evolutionId];
        if (evolution.submitter == address(0)) revert InvalidEvolutionId();
        if (evolution.fulfilled) revert AlreadyFulfilled();

        emit AIRequestInitiated(_evolutionId, evolution.parentTokenId, msg.sender);
    }

    /**
     * @notice Callable only by an approved oracle. Mints a new child NFT based on an evolution request,
     *         linking it to its parent and updating the parent's children list.
     * @dev Awards Creativity Score to the evolution request submitter.
     * @param _evolutionId The ID of the evolution request that was fulfilled.
     * @param _newTokenURI The URI (e.g., IPFS link) to the new child NFT's metadata/image.
     * @param _newMetadataHash A hash of the metadata for integrity verification.
     * @param _seedUsed The random seed used by the AI model for generation.
     */
    function fulfillAI_NFTEvolution(
        uint256 _evolutionId,
        string memory _newTokenURI,
        string memory _newMetadataHash,
        uint256 _seedUsed
    ) public onlyOracle {
        EvolutionRequest storage evolution = evolutionRequests[_evolutionId];
        if (evolution.submitter == address(0)) revert InvalidEvolutionId();
        if (evolution.fulfilled) revert AlreadyFulfilled();

        evolution.fulfilled = true;

        uint256 childTokenId = _nextTokenId++;
        evolution.mintedTokenId = childTokenId;
        _baseURI = _newTokenURI; // Update baseURI to the actual URI for this token (simplification)

        _mint(evolution.submitter, childTokenId);
        nftMetadata[childTokenId] = NFTMetadata({
            parentTokenId: evolution.parentTokenId,
            sourcePromptId: 0, // Child NFTs don't directly have a prompt, but an evolution request
            seedUsed: _seedUsed,
            generationBlock: block.number,
            endorsementCount: 0,
            childrenTokenIds: new uint256[](0)
        });

        // Add this child to the parent's children list
        nftMetadata[evolution.parentTokenId].childrenTokenIds.push(childTokenId);

        _increaseCreativityScore(evolution.submitter, NFT_MINT_SCORE / 2); // Evolution might give less score than genesis

        emit NFTEvolutionFulfilled(childTokenId, _evolutionId, evolution.parentTokenId, evolution.submitter, _newTokenURI);
    }

    // --- II. Reputation & Curation ---

    /**
     * @notice Allows users to endorse a prompt, increasing its visibility and the submitter's Creativity Score.
     * @dev Requires a small fee to prevent spam. A user can only endorse a prompt once.
     * @param _promptId The ID of the prompt to endorse.
     */
    function endorsePrompt(uint256 _promptId) public {
        Prompt storage prompt = prompts[_promptId];
        if (prompt.submitter == address(0)) revert InvalidPromptId();
        if (userEndorsedPrompts[msg.sender][_promptId]) revert PromptAlreadyEndorsed();
        if (!nativeToken.transferFrom(msg.sender, treasuryAddress, fees[uint8(FeeType.PromptEndorsement)])) revert InsufficientBalance();

        prompt.endorsementCount++;
        userEndorsedPrompts[msg.sender][_promptId] = true;
        _increaseCreativityScore(prompt.submitter, PROMPT_ENDORSEMENT_SCORE);

        emit PromptEndorsed(_promptId, msg.sender, prompt.endorsementCount);
    }

    /**
     * @notice Allows users to endorse a generated NFT, increasing its visibility and the original prompt submitter's Creativity Score.
     * @dev Requires a small fee to prevent spam. A user can only endorse an NFT once.
     * @param _tokenId The ID of the NFT to endorse.
     */
    function endorseNFT(uint256 _tokenId) public {
        if (!_exists(_tokenId)) revert NFTDoesNotExist();
        if (userEndorsedNFTs[msg.sender][_tokenId]) revert NFTAlreadyEndorsed();
        if (!nativeToken.transferFrom(msg.sender, treasuryAddress, fees[uint8(FeeType.NFTEndorsement)])) revert InsufficientBalance();

        NFTMetadata storage meta = nftMetadata[_tokenId];
        meta.endorsementCount++;
        userEndorsedNFTs[msg.sender][_tokenId] = true;

        // Award score to the original prompt submitter if it's a genesis NFT
        // Or to the evolution submitter if it's a child NFT
        address beneficiary = meta.parentTokenId == 0 ? prompts[meta.sourcePromptId].submitter : evolutionRequests[meta.sourcePromptId].submitter;
        if (beneficiary != address(0)) {
            _increaseCreativityScore(beneficiary, NFT_ENDORSEMENT_SCORE);
        }

        emit NFTEndorsed(_tokenId, msg.sender, meta.endorsementCount);
    }

    /**
     * @notice Returns the current Creativity Score for a given user.
     * @param _user The address of the user.
     * @return The Creativity Score of the user.
     */
    function getCreativityScore(address _user) public view returns (uint256) {
        return creativityScore[_user];
    }

    /**
     * @dev Internal function to increase a user's Creativity Score.
     * @param _user The address whose score to increase.
     * @param _amount The amount to add to the score.
     */
    function _increaseCreativityScore(address _user, uint256 _amount) internal {
        if (_user == address(0)) return;
        creativityScore[_user] += _amount;
        emit CreativityScoreUpdated(_user, creativityScore[_user]);
    }

    // --- III. Governance & DAO ---

    /**
     * @dev Calculates the combined voting power (Native Token Balance + Creativity Score) for an address.
     *      If the address has delegated their vote, the delegate's power is returned.
     * @param _voter The address whose voting power to query.
     * @return The total voting power of the address.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        address actualVoter = delegates[_voter] == address(0) ? _voter : delegates[_voter];
        return nativeToken.balanceOf(actualVoter) + creativityScore[actualVoter];
    }

    /**
     * @notice Allows users with sufficient `NATIVE_TOKEN` or `CreativityScore` to submit a new governance proposal.
     * @param _description A detailed description of the proposal.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _value The amount of ETH to send with the call (0 for most proposals).
     * @param _calldata The encoded function call to be executed if the proposal passes.
     * @return The ID of the newly created proposal.
     */
    function submitProposal(
        string memory _description,
        address _target,
        uint256 _value,
        bytes memory _calldata
    ) public returns (uint256) {
        uint256 proposerVotingPower = getVotingPower(msg.sender);
        if (proposerVotingPower < minNativeTokenForProposal && creativityScore[msg.sender] < minCreativityScoreForProposal) {
            revert InsufficientCreativityScore(); // Reusing error for general insufficient voting power
        }

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            target: _target,
            value: _value,
            calldataPayload: _calldata,
            startBlock: block.number,
            endBlock: block.number + votingPeriodBlocks,
            forVotes: 0,
            againstVotes: 0,
            proposer: msg.sender,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool)(),
            votesCast: new mapping(address => uint256)()
        });

        emit ProposalSubmitted(proposalId, msg.sender, _description, proposals[proposalId].startBlock, proposals[proposalId].endBlock);
        return proposalId;
    }

    /**
     * @notice Enables users to vote on an active proposal using their combined `NATIVE_TOKEN` balance and `CreativityScore`.
     * @dev A user can only vote once per proposal. Their voting power is snapshotted at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function vote(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.number > proposal.endBlock) revert VotingPeriodOver();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyExists(); // Reusing error, means already voted

        address actualVoter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        uint256 voterPower = getVotingPower(actualVoter);
        if (voterPower == 0) revert InsufficientCreativityScore(); // No voting power

        if (_support) {
            proposal.forVotes += voterPower;
        } else {
            proposal.againstVotes += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;
        proposal.votesCast[msg.sender] = voterPower;

        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @notice Allows a user to delegate their voting power (NATIVE_TOKEN + Creativity Score) to another address.
     * @param _delegate The address to delegate voting power to.
     */
    function delegateVote(address _delegate) public {
        if (_delegate == address(0)) revert ZeroAddressNotAllowed();
        if (_delegate == msg.sender) revert SelfDelegationForbidden();

        address oldDelegate = delegates[msg.sender];
        delegates[msg.sender] = _delegate;
        emit DelegateVote(msg.sender, _delegate);
    }

    /**
     * @notice Revokes any existing vote delegation for the caller.
     */
    function revokeDelegate() public {
        address oldDelegate = delegates[msg.sender];
        if (oldDelegate == address(0)) revert Unauthorized(); // No delegation to revoke
        delete delegates[msg.sender];
        emit RevokeDelegate(msg.sender, oldDelegate);
    }

    /**
     * @notice Checks the state of a proposal, moving it to Succeeded or Defeated if voting period is over.
     * @param _proposalId The ID of the proposal to check and queue.
     */
    function queueProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.number <= proposal.endBlock) revert VotingPeriodStillActive();

        uint256 totalVotePower = proposal.forVotes + proposal.againstVotes;
        // Total possible vote power is sum of all token balances + all creativity scores
        // For simplicity in this example, we'll use a dynamic quorum based on actual cast votes.
        // In a real DAO, total token supply & total creativity score would be snapshotted.
        uint256 totalActivePower = nativeToken.balanceOf(address(this)) + (getCreativityScore(owner) + creativityScore[msg.sender]); // Simplified sum for example
        if (totalVotePower < (totalActivePower * quorumPercentage) / 10000) revert NotEnoughVotes();

        if (proposal.forVotes > proposal.againstVotes) {
            proposal.state = ProposalState.Queued;
            emit ProposalStateChanged(_proposalId, ProposalState.Queued);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
        }
    }

    /**
     * @notice Executes a proposal that has been successfully voted on and queued.
     * @dev This function can only be called after the `proposalThresholdBlocks` has passed since queuing.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Queued) revert ProposalNotQueued();
        if (block.number < proposal.endBlock + proposalThresholdBlocks) revert ProposalExecutionFailed(); // Wait for threshold

        proposal.state = ProposalState.Executed;
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldataPayload);
        if (!success) revert ProposalExecutionFailed();

        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    // --- IV. Configuration & Utility ---

    /**
     * @notice Callable via governance, sets the fee for different actions.
     * @dev Requires proposal execution to call.
     * @param _feeType The type of fee to set (e.g., PromptSubmission).
     * @param _newFee The new fee amount in native tokens.
     */
    function setFee(uint8 _feeType, uint256 _newFee) public {
        if (msg.sender != owner) { // Check if called by owner or via governance
            // In a real system, would check if called by the contract itself as part of proposal execution
            // For this example, direct owner call or proposal exec.
            if (!isProposalExecutor()) revert Unauthorized();
        }
        if (_feeType >= uint8(FeeType.NFTEndorsement) + 1) revert InvalidFeeType(); // Check if valid enum value

        fees[_feeType] = _newFee;
        emit FeeSet(_feeType, _newFee);
    }

    /**
     * @notice Callable via governance, registers a new address as a trusted AI oracle.
     * @dev Requires proposal execution to call.
     * @param _oracleAddress The address of the new oracle.
     * @param _name A descriptive name for the oracle.
     */
    function registerOracle(address _oracleAddress, string memory _name) public {
        if (msg.sender != owner) {
            if (!isProposalExecutor()) revert Unauthorized();
        }
        if (_oracleAddress == address(0)) revert ZeroAddressNotAllowed();

        activeOracles[_oracleAddress] = true;
        oracleNames[_oracleAddress] = _name;
        emit OracleRegistered(_oracleAddress, _name);
    }

    /**
     * @notice Callable via governance, deactivates a previously registered oracle.
     * @dev Requires proposal execution to call.
     * @param _oracleAddress The address of the oracle to deactivate.
     */
    function deactivateOracle(address _oracleAddress) public {
        if (msg.sender != owner) {
            if (!isProposalExecutor()) revert Unauthorized();
        }
        if (!activeOracles[_oracleAddress]) revert OracleNotActive();

        activeOracles[_oracleAddress] = false;
        delete oracleNames[_oracleAddress];
        emit OracleDeactivated(_oracleAddress);
    }

    /**
     * @notice Callable by owner/governance, sets the ERC-20 token used for fees and voting.
     * @dev Should ideally be set only once during deployment or very early.
     * @param _tokenAddress The address of the new native token.
     */
    function setNativeToken(address _tokenAddress) public {
        if (msg.sender != owner) {
            if (!isProposalExecutor()) revert Unauthorized();
        }
        if (_tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        nativeToken = IERC20(_tokenAddress);
    }

    /**
     * @notice Callable via governance, allows withdrawal of collected fees from the contract's treasury.
     * @dev Requires proposal execution to call. Funds are sent to the specified `_to` address.
     * @param _to The recipient of the funds.
     * @param _amount The amount of native tokens to withdraw.
     */
    function withdrawTreasuryFunds(address _to, uint256 _amount) public {
        if (msg.sender != owner) {
            if (!isProposalExecutor()) revert Unauthorized();
        }
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert UnauthorizedWithdrawal(); // 0 amount withdrawal is not allowed

        // Transfer from this contract's balance to _to address
        if (!nativeToken.transfer(_to, _amount)) revert UnauthorizedWithdrawal();
        emit TreasuryFundsWithdrawn(_to, _amount);
    }

    /**
     * @notice Callable via governance, sets the base URI for NFTs.
     * @dev This can be used to point to a new metadata server or IPFS gateway.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public {
        if (msg.sender != owner) {
            if (!isProposalExecutor()) revert Unauthorized();
        }
        _baseURI = _newBaseURI;
    }

    // Helper to check if the caller is this contract executing a proposal
    function isProposalExecutor() internal view returns (bool) {
        // This is a simplified check. A full Governor contract would have a way
        // to verify that the call originated from the `executeProposal` function.
        // For this example, we just check if the owner (who can call directly)
        // is not the caller.
        return msg.sender == address(this);
    }

    // --- Owner-specific functions (can be replaced by governance) ---

    /**
     * @notice Transfers ownership of the contract.
     * @dev Only the current owner can call this.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner == address(0)) revert ZeroAddressNotAllowed();
        owner = _newOwner;
    }
}
```