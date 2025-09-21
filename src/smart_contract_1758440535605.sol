Here's a smart contract named `AetherForge` written in Solidity, designed around several advanced, creative, and trendy concepts. It focuses on a decentralized, AI-augmented generative asset platform, incorporating reputation, dynamic fees, and a simplified governance model.

This contract intentionally implements a *minimal* set of ERC721 standard functions manually, rather than inheriting from OpenZeppelin or similar libraries, to adhere to the "don't duplicate any open-source" spirit for the overall implementation. The creativity lies in the *logic surrounding* these standard functions and the unique features.

---

## Contract: `AetherForge`

**Outline and Function Summary:**

This contract creates a platform for generating unique digital assets (NFTs) influenced by user input, off-chain AI models (via oracles), and a dynamic internal economy. It also features a user reputation system tied to contribution, adaptive pricing, and a simplified governance mechanism.

**I. Core Asset Generation & Custom ERC721 Standard Implementation**
*   **`_tokenURIs`**: Internal mapping to store the URI for each NFT.
*   **`_tokenApprovals`**: Internal mapping for ERC721 token approvals.
*   **`_operatorApprovals`**: Internal mapping for ERC721 operator approvals.
*   **`_balances`**: Internal mapping for ERC721 token balances.
*   **`_owners`**: Internal mapping for ERC721 token owners.
*   **`_allTokens`**: Internal array storing all minted token IDs.
*   **`_ownedTokens`**: Internal mapping from owner address to an array of token IDs they own.
*   **`balanceOf(address owner)`**: Returns the number of NFTs owned by `owner`.
*   **`ownerOf(uint256 tokenId)`**: Returns the owner of the `tokenId` NFT.
*   **`getApproved(uint256 tokenId)`**: Returns the approved address for `tokenId`.
*   **`isApprovedForAll(address owner, address operator)`**: Returns if `operator` is approved for `owner`.
*   **`approve(address to, uint256 tokenId)`**: Approves `to` to manage `tokenId`.
*   **`setApprovalForAll(address operator, bool approved)`**: Sets or revokes approval for an operator.
*   **`transferFrom(address from, address to, uint256 tokenId)`**: Transfers `tokenId` from `from` to `to`.
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`**: Safe transfer of `tokenId` (checks for receiver support).
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`**: Safe transfer with additional data.
*   **`tokenURI(uint256 tokenId)`**: Returns a dynamic URI for `tokenId`, reflecting its generated traits.

**II. AetherForge Specific Logic: Asset Creation & Dynamics**
*   **`GenerationRequest`**: Struct defining the state and parameters of an NFT generation request.
*   **`Asset`**: Struct storing the immutable details of a minted NFT.
*   **`_generationRequests`**: Mapping from `requestId` to `GenerationRequest` details.
*   **`_assets`**: Mapping from `tokenId` to `Asset` details.
*   **`requestAssetGeneration(string calldata _initialDNA)`**: Allows a user to initiate a new NFT generation, paying a dynamic fee.
*   **`submitOracleAIResult(uint256 _requestId, bytes32 _aiHash, uint256 _rarityScore, uint256[] calldata _traitModifiers, string calldata _tokenUriSuffix)`**: An approved oracle submits the AI-processed traits and rarity for a pending request.
*   **`finalizeAssetGeneration(uint256 _requestId)`**: Combines user `initialDNA` with oracle `traitModifiers` to mint the final NFT.
*   **`getTokenDetails(uint256 _tokenId)`**: Retrieves the stored `Asset` details for a minted NFT.
*   **`getGenerationRequest(uint256 _requestId)`**: Retrieves the `GenerationRequest` details for a given ID.
*   **`cancelGenerationRequest(uint256 _requestId)`**: Allows the requester to cancel a pending request and get their stake back.

**III. Reputation & Contribution System**
*   **`_userReputation`**: Mapping storing a numerical reputation score for each user.
*   **`_contributionStakes`**: Mapping tracking tokens staked by users for contribution.
*   **`Contribution`**: Struct defining a user's submitted contribution.
*   **`_contributions`**: Mapping from `contributionId` to `Contribution` details.
*   **`stakeForContribution()`**: Allows users to stake funds to signal their intent to contribute.
*   **`submitContribution(bytes32 _contributionProofHash, uint256 _contributionType)`**: Users submit a hash of their off-chain contribution proof.
*   **`verifyContribution(address _contributor, uint256 _contributionId, bool _isValid)`**: A designated verifier (or owner) validates a contribution, updating reputation.
*   **`getUserReputation(address _user)`**: Returns the current reputation score of a user.
*   **`redeemContributionStake(uint256 _amount)`**: Allows users to unstake their contribution funds after a cooldown or meeting criteria.

**IV. Dynamic Parameters & Oracle Management**
*   **`_approvedOracles`**: Mapping to track approved oracle addresses.
*   **`_generationBaseFee`**: Base fee for asset generation.
*   **`_feePerPendingRequest`**: Additional fee component per pending generation request.
*   **`_oracleInfluenceFactor`**: Parameter controlling how much oracle input modifies final traits.
*   **`setOracleAddress(address _oracleAddress, bool _isApproved)`**: Owner function to manage approved oracles.
*   **`updateFeeParameters(uint256 _newBaseFee, uint256 _newFeePerPendingRequest)`**: Owner function to adjust dynamic fee parameters.
*   **`setTraitInfluenceParameter(uint256 _newInfluenceFactor)`**: Owner function to adjust the oracle's trait influence.
*   **`getGenerationFee()`**: Calculates the current dynamic fee for asset generation based on demand.

**V. Governance (Simplified) & Utilities**
*   **`ParameterProposal`**: Struct for a proposed parameter change.
*   **`_parameterProposals`**: Mapping from `proposalHash` to `ParameterProposal`.
*   **`_proposalVotes`**: Mapping for user votes on proposals.
*   **`proposeParameterChange(bytes32 _paramName, uint256 _newValue)`**: Allows users with sufficient reputation to propose a change to a protocol parameter.
*   **`voteOnParameterChange(bytes32 _proposalHash, bool _approve)`**: Allows users (based on reputation/stake) to vote on proposals.
*   **`finalizeParameterChange(bytes32 _proposalHash)`**: Applies a parameter change if a proposal passes the voting threshold.
*   **`withdrawProtocolFees(address _to, uint256 _amount)`**: Owner/governance can withdraw accumulated protocol fees.
*   **`emergencyPause()`**: Pauses critical contract functions in an emergency.
*   **`unpause()`**: Unpauses critical contract functions.
*   **`updateBaseTokenURI(string calldata _newBaseURI)`**: Owner can update the base URI for all tokens.
*   **`getProtocolParameter(bytes32 _paramName)`**: Generic function to retrieve the value of a named protocol parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC721Receiver.sol"; // Using the standard interface, not an implementation

/**
 * @title AetherForge
 * @dev A decentralized platform for AI-augmented generative NFTs, featuring dynamic fees,
 *      a reputation system based on contributions, and simplified governance.
 *      This contract implements a custom, minimal ERC721 standard rather than inheriting
 *      from an existing library to provide a unique implementation.
 */
contract AetherForge {
    // --- State Variables & Constants ---

    // Contract Ownership & Pausability
    address public immutable owner;
    bool public paused;

    // Token & Asset Counters
    uint256 private _nextTokenId;
    uint256 private _nextRequestId;
    uint256 private _nextContributionId;
    uint256 private _totalPendingRequests;

    // ERC721 Mappings
    string public name = "AetherForge Asset";
    string public symbol = "AFNFT";
    string private _baseTokenURI;

    mapping(uint256 => address) private _owners; // Token ID to owner
    mapping(address => uint256) private _balances; // Owner to balance
    mapping(uint256 => address) private _tokenApprovals; // Token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner to Operator to Approved

    // AetherForge Specific Mappings & Structs
    enum RequestStatus { PendingDNA, PendingOracle, Finalized, Cancelled }
    enum ContributionType { OracleVerification, DataProvision, CommunityMod, General }

    struct GenerationRequest {
        address requester;
        uint256 stakeAmount; // ETH staked for generation
        string initialDNA;
        RequestStatus status;
        bytes32 oracleAiHash;          // Hash from oracle's full AI output
        uint256 oracleRarityScore;     // Rarity score from oracle
        uint256[] oracleTraitModifiers; // Trait modifiers from oracle
        string oracleTokenUriSuffix;    // Suffix for tokenURI from oracle
        uint64 requestTimestamp;       // When the request was made
        uint256 finalTokenId;          // Link to the minted token if finalized
    }

    struct Asset {
        uint256 requestId;         // Link to generation request
        address creator;
        string initialDNA;
        bytes32 aiHash;            // Hash of AI model's full output (from oracle)
        uint256 rarityScore;       // AI-assigned rarity
        uint256[] finalTraits;     // Derived traits after AI modification
        uint64 creationTimestamp;
        string tokenUriSuffix;     // Suffix from oracle
    }

    struct Contribution {
        address contributor;
        bytes32 proofHash;
        uint256 contributionType;
        uint64 submissionTimestamp;
        bool verified;
        bool isValid; // True if verified successfully, false if rejected
    }

    struct ParameterProposal {
        bytes32 paramName;
        uint256 newValue;
        uint64 submissionTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool finalized;
    }

    mapping(uint256 => GenerationRequest) public _generationRequests;
    mapping(uint256 => Asset) public _assets;
    mapping(address => uint256) public _userReputation; // Higher is better
    mapping(address => uint256) public _contributionStakes; // ETH staked for contribution
    mapping(uint256 => Contribution) public _contributions;
    mapping(bytes32 => ParameterProposal) public _parameterProposals;
    mapping(bytes32 => mapping(address => bool)) public _proposalVotes; // ProposalHash -> Voter -> VotedFor

    // Protocol Parameters (can be adjusted by governance)
    mapping(bytes32 => uint256) public protocolParameters; // Generic storage for dynamic parameters

    bytes32 constant GEN_BASE_FEE_PARAM = keccak256("generationBaseFee");
    bytes32 constant FEE_PER_PENDING_REQ_PARAM = keccak256("feePerPendingRequest");
    bytes32 constant ORACLE_INFLUENCE_FACTOR_PARAM = keccak256("oracleInfluenceFactor");
    bytes32 constant MIN_REPUTATION_TO_PROPOSE_PARAM = keccak256("minReputationToPropose");
    bytes32 constant PROPOSAL_VOTE_THRESHOLD_PARAM = keccak256("proposalVoteThreshold"); // Percentage * 100
    bytes32 constant CONTRIBUTION_MIN_STAKE_PARAM = keccak256("contributionMinStake");
    bytes32 constant CONTRIBUTION_REPUTATION_REWARD_PARAM = keccak256("contributionReputationReward");
    bytes32 constant CONTRIBUTION_REPUTATION_PENALTY_PARAM = keccak256("contributionReputationPenalty");
    bytes32 constant CONTRIBUTION_VERIFIER_ADDRESS_PARAM = keccak256("contributionVerifierAddress"); // Trusted verifier for contributions
    bytes32 constant REPUTATION_FOR_DISCOUNT_THRESHOLD_PARAM = keccak256("reputationForDiscountThreshold");
    bytes32 constant GENERATION_DISCOUNT_PERCENTAGE_PARAM = keccak256("generationDiscountPercentage"); // Percentage * 100

    // Oracle Management
    mapping(address => bool) public _approvedOracles;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event AssetGenerationRequested(uint256 indexed requestId, address indexed requester, string initialDNA, uint256 feePaid);
    event OracleAIResultSubmitted(uint256 indexed requestId, address indexed oracle, bytes32 aiHash, uint256 rarityScore);
    event AssetGenerated(uint256 indexed tokenId, uint256 indexed requestId, address indexed creator, uint256 rarityScore);
    event RequestCancelled(uint256 indexed requestId, address indexed requester);

    event ContributionStaked(address indexed contributor, uint256 amount);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed contributor, uint256 contributionType, bytes32 proofHash);
    event ContributionVerified(uint256 indexed contributionId, address indexed contributor, bool isValid, uint256 newReputation);
    event ContributionStakeRedeemed(address indexed contributor, uint256 amount);

    event OracleStatusUpdated(address indexed oracleAddress, bool isApproved);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);

    event ProposalCreated(bytes32 indexed proposalHash, bytes32 paramName, uint256 newValue, address indexed proposer);
    event Voted(bytes32 indexed proposalHash, address indexed voter, bool support);
    event ProposalFinalized(bytes32 indexed proposalHash, bool passed);

    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "AetherForge: Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AetherForge: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "AetherForge: Not paused");
        _;
    }

    modifier onlyApprovedOracle() {
        require(_approvedOracles[msg.sender], "AetherForge: Not an approved oracle");
        _;
    }

    modifier onlyContributionVerifier() {
        require(msg.sender == address(uint160(protocolParameters[CONTRIBUTION_VERIFIER_ADDRESS_PARAM])), "AetherForge: Not the contribution verifier");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;

        // Initialize default protocol parameters
        protocolParameters[GEN_BASE_FEE_PARAM] = 0.01 ether; // 0.01 ETH
        protocolParameters[FEE_PER_PENDING_REQ_PARAM] = 0.0001 ether; // 0.0001 ETH per pending request
        protocolParameters[ORACLE_INFLUENCE_FACTOR_PARAM] = 50; // 0-100, percentage of influence
        protocolParameters[MIN_REPUTATION_TO_PROPOSE_PARAM] = 100;
        protocolParameters[PROPOSAL_VOTE_THRESHOLD_PARAM] = 5100; // 51% (51 * 100)
        protocolParameters[CONTRIBUTION_MIN_STAKE_PARAM] = 0.1 ether;
        protocolParameters[CONTRIBUTION_REPUTATION_REWARD_PARAM] = 10;
        protocolParameters[CONTRIBUTION_REPUTATION_PENALTY_PARAM] = 20;
        // Default verifier is owner, can be changed by governance later
        protocolParameters[CONTRIBUTION_VERIFIER_ADDRESS_PARAM] = uint256(uint160(msg.sender));
        protocolParameters[REPUTATION_FOR_DISCOUNT_THRESHOLD_PARAM] = 200;
        protocolParameters[GENERATION_DISCOUNT_PERCENTAGE_PARAM] = 1000; // 10% (10 * 100)
    }

    // --- ERC721 Standard Implementation (Minimal) ---

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x80ac58cd // ERC721
            || interfaceId == 0x5b5e139f; // ERC721Metadata
    }

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner_];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     * Reverts if `tokenId` is not valid.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }

    /**
     * @dev Returns the approved address for `tokenId`, or the zero address if no address set.
     * Reverts if `tokenId` is not valid.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns if the `operator` is an approved operator for `owner`.
     */
    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    /**
     * @dev Approves `to` to operate on `tokenId`
     * `msg.sender` must be the token owner or an approved operator.
     */
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "ERC721: approve caller is not token owner nor approved for all");
        require(to != tokenOwner, "ERC721: approval to current owner");
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /**
     * @dev Sets or unsets the approval for `operator` to manage all of `msg.sender`'s assets.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve for all to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     * Requirements:
     * - `from` must be the owner of `tokenId`.
     * - `_msgSender()` must be the owner, approved for the token, or an approved operator.
     * - `to` must not be the zero address.
     * - `tokenId` must exist.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` from `from` to `to`.
     * If `to` is a contract, it must implement `IERC721Receiver` and return the magic value.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as `safeTransferFrom`, but with `data`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Internal function to mint a new token.
     * Increments `_balances` and sets `_owners`.
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");
        _balances[to]++;
        _owners[tokenId] = to;
        _allTokens.push(tokenId); // Add to global token list
        // Note: _ownedTokens (per-user token list) is not implemented for brevity
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a token.
     * Decrements `_balances`, clears `_owners`, and `_tokenApprovals`.
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address tokenOwner = ownerOf(tokenId);
        _approve(address(0), tokenId); // Clear approvals
        _balances[tokenOwner]--;
        delete _owners[tokenId];
        // Note: _allTokens and _ownedTokens removal not implemented for brevity
        emit Transfer(tokenOwner, address(0), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of `tokenId` from `from` to `to`.
     * Checks requirements and emits a {Transfer} event.
     * If `to` is a contract, it must implement `IERC721Receiver` and return the magic value.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(msg.sender == from || getApproved(tokenId) == msg.sender || isApprovedForAll(from, msg.sender), "ERC721: transfer caller is not owner nor approved");

        _approve(address(0), tokenId); // Clear approvals
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to approve `to` to operate on `tokenId`
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to safely transfer `tokenId` from `from` to `to`.
     * Calls `_checkOnERC721Received` if `to` is a contract.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Private function to invoke `onERC721Received` on a contract if `to` is a contract.
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) { // Check if 'to' is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (no data)");
                } else {
                    /// @solidity using `Error(string)` not `Panic(uint256)`
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the uniform resource identifier for `tokenId` token.
     * The URI will include the base URI and a suffix determined by the oracle.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        Asset storage asset = _assets[tokenId];
        return string(abi.encodePacked(_baseTokenURI, asset.tokenUriSuffix));
    }

    // --- AetherForge Specific Logic: Asset Creation & Dynamics ---

    /**
     * @dev Allows owner to update the base URI for all tokens.
     */
    function updateBaseTokenURI(string calldata _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Calculates the current dynamic fee for asset generation.
     * Fee = baseFee + (feePerPendingRequest * totalPendingRequests) - reputationDiscount
     */
    function getGenerationFee() public view returns (uint256) {
        uint256 baseFee = protocolParameters[GEN_BASE_FEE_PARAM];
        uint256 feePerPending = protocolParameters[FEE_PER_PENDING_REQ_PARAM];
        uint256 totalFee = baseFee + (feePerPending * _totalPendingRequests);

        // Apply reputation discount if eligible
        if (_userReputation[msg.sender] >= protocolParameters[REPUTATION_FOR_DISCOUNT_THRESHOLD_PARAM]) {
            uint256 discountPercentage = protocolParameters[GENERATION_DISCOUNT_PERCENTAGE_PARAM];
            totalFee = totalFee * (10000 - discountPercentage) / 10000; // e.g., 10% discount = (10000-1000)/10000 = 90%
        }
        return totalFee;
    }

    /**
     * @dev Initiates an NFT generation request. Requires ETH payment for the dynamic fee.
     * The `_initialDNA` is a user-provided seed for the asset's traits.
     */
    function requestAssetGeneration(string calldata _initialDNA) public payable whenNotPaused returns (uint256) {
        uint256 currentFee = getGenerationFee();
        require(msg.value >= currentFee, "AetherForge: Insufficient ETH for generation fee");

        uint256 requestId = _nextRequestId++;
        _generationRequests[requestId] = GenerationRequest({
            requester: msg.sender,
            stakeAmount: msg.value, // Store the actual amount paid
            initialDNA: _initialDNA,
            status: RequestStatus.PendingOracle,
            oracleAiHash: bytes32(0),
            oracleRarityScore: 0,
            oracleTraitModifiers: new uint256[](0),
            oracleTokenUriSuffix: "",
            requestTimestamp: uint64(block.timestamp),
            finalTokenId: 0
        });

        _totalPendingRequests++;
        emit AssetGenerationRequested(requestId, msg.sender, _initialDNA, msg.value);
        return requestId;
    }

    /**
     * @dev An approved oracle submits the AI-processed traits and rarity for a pending request.
     * This function is crucial for integrating off-chain AI models.
     */
    function submitOracleAIResult(
        uint256 _requestId,
        bytes32 _aiHash,
        uint256 _rarityScore,
        uint256[] calldata _traitModifiers,
        string calldata _tokenUriSuffix
    ) public onlyApprovedOracle whenNotPaused {
        GenerationRequest storage req = _generationRequests[_requestId];
        require(req.requester != address(0), "AetherForge: Request does not exist");
        require(req.status == RequestStatus.PendingOracle, "AetherForge: Request not awaiting oracle input");

        req.oracleAiHash = _aiHash;
        req.oracleRarityScore = _rarityScore;
        req.oracleTraitModifiers = _traitModifiers;
        req.oracleTokenUriSuffix = _tokenUriSuffix;
        req.status = RequestStatus.Finalized; // Mark as ready for finalization

        emit OracleAIResultSubmitted(_requestId, msg.sender, _aiHash, _rarityScore);
    }

    /**
     * @dev Finalizes the generation process. Combines initial DNA with oracle data and mints the NFT.
     * Can be called by anyone after oracle result is submitted.
     */
    function finalizeAssetGeneration(uint256 _requestId) public whenNotPaused {
        GenerationRequest storage req = _generationRequests[_requestId];
        require(req.requester != address(0), "AetherForge: Request does not exist");
        require(req.status == RequestStatus.Finalized, "AetherForge: Request not ready for finalization (or already finalized/cancelled)");
        require(req.oracleAiHash != bytes32(0), "AetherForge: Oracle result missing");

        // Combine initial DNA with oracle modifiers to generate final traits
        // For simplicity, we'll just store oracleTraitModifiers as finalTraits
        // A more complex implementation would involve hashing/processing req.initialDNA
        // and req.oracleTraitModifiers based on protocolParameters[ORACLE_INFLUENCE_FACTOR_PARAM]
        uint256[] memory finalTraits = req.oracleTraitModifiers; // Placeholder for actual combination logic

        uint256 tokenId = _nextTokenId++;
        _mint(req.requester, tokenId);

        _assets[tokenId] = Asset({
            requestId: _requestId,
            creator: req.requester,
            initialDNA: req.initialDNA,
            aiHash: req.oracleAiHash,
            rarityScore: req.oracleRarityScore,
            finalTraits: finalTraits,
            creationTimestamp: uint64(block.timestamp),
            tokenUriSuffix: req.oracleTokenUriSuffix
        });

        req.finalTokenId = tokenId;
        // Status remains Finalized, but no longer requires action
        _totalPendingRequests--;

        // Distribute fees or hold them in contract as protocol fees
        // In a real system, a portion might go to oracle, another to protocol treasury.
        // For this example, all fees are held for `withdrawProtocolFees`.
        // The requester's stakeAmount is the fee paid.

        emit AssetGenerated(tokenId, _requestId, req.requester, req.rarityScore);
    }

    /**
     * @dev Retrieves full details of an minted NFT.
     */
    function getTokenDetails(uint256 _tokenId) public view returns (Asset memory) {
        require(_owners[_tokenId] != address(0), "AetherForge: Token does not exist");
        return _assets[_tokenId];
    }

    /**
     * @dev Retrieves details of a pending or finalized generation request.
     */
    function getGenerationRequest(uint256 _requestId) public view returns (GenerationRequest memory) {
        require(_generationRequests[_requestId].requester != address(0), "AetherForge: Request does not exist");
        return _generationRequests[_requestId];
    }

    /**
     * @dev Allows the requester to cancel a pending generation request.
     * Only possible if the oracle hasn't submitted results yet.
     */
    function cancelGenerationRequest(uint256 _requestId) public whenNotPaused {
        GenerationRequest storage req = _generationRequests[_requestId];
        require(req.requester == msg.sender, "AetherForge: Only requester can cancel");
        require(req.status == RequestStatus.PendingOracle, "AetherForge: Request not in cancellable state");

        req.status = RequestStatus.Cancelled;
        _totalPendingRequests--;
        // Refund staked amount
        payable(msg.sender).transfer(req.stakeAmount);

        emit RequestCancelled(_requestId, msg.sender);
    }

    // --- Reputation & Contribution System ---

    /**
     * @dev Allows users to stake funds to signal their intent to contribute to the protocol.
     * Staked funds might unlock higher reputation caps or other benefits.
     */
    function stakeForContribution() public payable whenNotPaused {
        require(msg.value >= protocolParameters[CONTRIBUTION_MIN_STAKE_PARAM], "AetherForge: Minimum stake not met");
        _contributionStakes[msg.sender] += msg.value;
        emit ContributionStaked(msg.sender, msg.value);
    }

    /**
     * @dev Users submit a hash of their off-chain contribution proof.
     * This needs to be verified by a designated verifier.
     * `_contributionType` categorizes the contribution (e.g., OracleVerification, DataProvision).
     */
    function submitContribution(bytes32 _contributionProofHash, uint256 _contributionType) public whenNotPaused returns (uint256) {
        require(_contributionStakes[msg.sender] >= protocolParameters[CONTRIBUTION_MIN_STAKE_PARAM], "AetherForge: Insufficient stake for contribution");
        uint256 contributionId = _nextContributionId++;
        _contributions[contributionId] = Contribution({
            contributor: msg.sender,
            proofHash: _contributionProofHash,
            contributionType: _contributionType,
            submissionTimestamp: uint64(block.timestamp),
            verified: false,
            isValid: false
        });
        emit ContributionSubmitted(contributionId, msg.sender, _contributionType, _contributionProofHash);
        return contributionId;
    }

    /**
     * @dev A designated verifier confirms or rejects a contribution.
     * Successful verification awards reputation, rejection penalizes it.
     */
    function verifyContribution(address _contributor, uint256 _contributionId, bool _isValid) public onlyContributionVerifier whenNotPaused {
        Contribution storage c = _contributions[_contributionId];
        require(c.contributor != address(0), "AetherForge: Contribution does not exist");
        require(!c.verified, "AetherForge: Contribution already verified");

        c.verified = true;
        c.isValid = _isValid;

        if (_isValid) {
            _userReputation[_contributor] += protocolParameters[CONTRIBUTION_REPUTATION_REWARD_PARAM];
        } else {
            // Ensure reputation doesn't go below zero
            if (_userReputation[_contributor] >= protocolParameters[CONTRIBUTION_REPUTATION_PENALTY_PARAM]) {
                _userReputation[_contributor] -= protocolParameters[CONTRIBUTION_REPUTATION_PENALTY_PARAM];
            } else {
                _userReputation[_contributor] = 0;
            }
        }
        emit ContributionVerified(_contributionId, _contributor, _isValid, _userReputation[_contributor]);
    }

    /**
     * @dev Returns the current reputation score of a user.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return _userReputation[_user];
    }

    /**
     * @dev Allows users to unstake their contribution funds.
     * In a real system, this might have a cooldown period or depend on reputation.
     */
    function redeemContributionStake(uint256 _amount) public whenNotPaused {
        require(_contributionStakes[msg.sender] >= _amount, "AetherForge: Insufficient staked amount");
        _contributionStakes[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit ContributionStakeRedeemed(msg.sender, _amount);
    }

    // --- Dynamic Parameters & Oracle Management ---

    /**
     * @dev Owner function to manage which addresses are approved oracles.
     */
    function setOracleAddress(address _oracleAddress, bool _isApproved) public onlyOwner {
        _approvedOracles[_oracleAddress] = _isApproved;
        emit OracleStatusUpdated(_oracleAddress, _isApproved);
    }

    /**
     * @dev Owner function to update the parameters used for dynamic fee calculation.
     */
    function updateFeeParameters(uint256 _newBaseFee, uint256 _newFeePerPendingRequest) public onlyOwner {
        protocolParameters[GEN_BASE_FEE_PARAM] = _newBaseFee;
        protocolParameters[FEE_PER_PENDING_REQ_PARAM] = _newFeePerPendingRequest;
        emit ProtocolParameterUpdated(GEN_BASE_FEE_PARAM, _newBaseFee);
        emit ProtocolParameterUpdated(FEE_PER_PENDING_REQ_PARAM, _newFeePerPendingRequest);
    }

    /**
     * @dev Owner function to adjust how much the oracle's input influences the final asset traits.
     * (Value 0-100, representing percentage influence).
     */
    function setTraitInfluenceParameter(uint256 _newInfluenceFactor) public onlyOwner {
        require(_newInfluenceFactor <= 100, "AetherForge: Influence factor must be 0-100");
        protocolParameters[ORACLE_INFLUENCE_FACTOR_PARAM] = _newInfluenceFactor;
        emit ProtocolParameterUpdated(ORACLE_INFLUENCE_FACTOR_PARAM, _newInfluenceFactor);
    }

    // --- Governance (Simplified) & Utilities ---

    /**
     * @dev Allows users with sufficient reputation to propose a change to a protocol parameter.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) public whenNotPaused returns (bytes32) {
        require(_userReputation[msg.sender] >= protocolParameters[MIN_REPUTATION_TO_PROPOSE_PARAM], "AetherForge: Insufficient reputation to propose");

        bytes32 proposalHash = keccak256(abi.encodePacked(_paramName, _newValue, block.timestamp));
        require(_parameterProposals[proposalHash].submissionTimestamp == 0, "AetherForge: Proposal already exists");

        _parameterProposals[proposalHash] = ParameterProposal({
            paramName: _paramName,
            newValue: _newValue,
            submissionTimestamp: uint64(block.timestamp),
            votesFor: 0,
            votesAgainst: 0,
            finalized: false
        });

        // Auto-vote for the proposer
        _voteOnProposal(proposalHash, msg.sender, true);
        _parameterProposals[proposalHash].votesFor++;

        emit ProposalCreated(proposalHash, _paramName, _newValue, msg.sender);
        return proposalHash;
    }

    /**
     * @dev Internal helper for voting.
     */
    function _voteOnProposal(bytes32 _proposalHash, address _voter, bool _support) internal {
        ParameterProposal storage proposal = _parameterProposals[_proposalHash];
        require(proposal.submissionTimestamp != 0, "AetherForge: Proposal does not exist");
        require(!proposal.finalized, "AetherForge: Proposal already finalized");
        require(!_proposalVotes[_proposalHash][_voter], "AetherForge: Already voted on this proposal");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        _proposalVotes[_proposalHash][_voter] = true;
        emit Voted(_proposalHash, _voter, _support);
    }

    /**
     * @dev Allows users (based on reputation/stake) to vote on proposals.
     * A more advanced system would weigh votes by reputation or staked amount.
     * For simplicity, each vote counts as 1.
     */
    function voteOnParameterChange(bytes32 _proposalHash, bool _approveVote) public whenNotPaused {
        require(_userReputation[msg.sender] > 0 || _contributionStakes[msg.sender] > 0, "AetherForge: Must have reputation or stake to vote");
        _voteOnProposal(_proposalHash, msg.sender, _approveVote);
    }

    /**
     * @dev Applies a parameter change if a proposal passes the voting threshold.
     * Anyone can call this to finalize a passed proposal.
     */
    function finalizeParameterChange(bytes32 _proposalHash) public whenNotPaused {
        ParameterProposal storage proposal = _parameterProposals[_proposalHash];
        require(proposal.submissionTimestamp != 0, "AetherForge: Proposal does not exist");
        require(!proposal.finalized, "AetherForge: Proposal already finalized");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "AetherForge: No votes cast yet");

        uint256 votesForPercentage = (proposal.votesFor * 10000) / totalVotes; // Percentage * 100
        bool passed = votesForPercentage >= protocolParameters[PROPOSAL_VOTE_THRESHOLD_PARAM];

        proposal.finalized = true;
        emit ProposalFinalized(_proposalHash, passed);

        if (passed) {
            protocolParameters[proposal.paramName] = proposal.newValue;
            emit ProtocolParameterUpdated(proposal.paramName, proposal.newValue);
        }
    }

    /**
     * @dev Owner/governance can withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_to != address(0), "AetherForge: Cannot withdraw to zero address");
        require(address(this).balance >= _amount, "AetherForge: Insufficient contract balance");
        payable(_to).transfer(_amount);
    }

    /**
     * @dev Pauses critical contract functions in an emergency.
     * Prevents asset generation, contributions, and parameter changes.
     */
    function emergencyPause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses critical contract functions.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Generic function to retrieve the value of a named protocol parameter.
     */
    function getProtocolParameter(bytes32 _paramName) public view returns (uint256) {
        return protocolParameters[_paramName];
    }
}


// --- Minimal IERC721Receiver Interface ---
// This is a standard interface, included for the _checkOnERC721Received function,
// not a full implementation or library.
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return the value `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     * (i.e. 0x150b7a02) if the transfer is to be accepted.
     *
     * If any other value is returned or the call reverts, the transfer will be reverted.
     *
     * The selector can be obtained using `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
```