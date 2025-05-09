Okay, let's design a smart contract for a Decentralized Autonomous Organization (DAO) focused on governing the parameters for *generative art*. This combines NFTs, DAO governance, and managing on-chain parameters that influence off-chain creation.

We will build the core logic for:
1.  **DAO Governance Token Staking:** Users stake a native token (let's call it `ARTG`) to gain voting power.
2.  **Generative Art Parameter Management:** The contract stores configuration parameters (e.g., color palettes, shape types, complexity limits) that an *off-chain* renderer would use. These parameters are changed only via DAO proposals.
3.  **Art Piece Minting:** Users can mint NFTs ("ArtPieces") based on the *currently active* approved parameters. A record of parameters used for each piece is stored.
4.  **DAO Proposals:** Token stakers can create and vote on proposals to change art parameters, manage a treasury (funded by minting fees), or other approved actions.
5.  **Treasury:** A contract-owned treasury funded by minting fees, controlled by DAO votes.

This contract won't contain the *actual* generative art rendering code (that's too complex/expensive for Solidity), but it governs the *inputs* to that process and tracks the resulting NFTs. We'll manage token staking and art piece ownership internally rather than inheriting full ERC-20/ERC-721 to be less of a direct "duplicate" of standard libraries, focusing on the interaction logic.

---

**GenerativeArtDAO Smart Contract**

**Outline:**

1.  **State Variables:** Define core state for staking, art pieces, parameters, proposals, and treasury.
2.  **Structs and Enums:** Define data structures for `ArtParameters` and `Proposal`, and an enum for `ProposalState`.
3.  **Events:** Define events for key actions (staking, voting, minting, proposals, parameter changes).
4.  **Modifiers:** (Not strictly needed, can use `require` internally).
5.  **Constructor:** Initialize contract with basic parameters.
6.  **Staking Functions:** Stake, unstake, check balance, manage cooldowns.
7.  **Art Parameter Functions:** View current parameters, propose changes (via DAO).
8.  **Art Piece (NFT) Functions:** Mint new pieces, view ownership, get piece details, token URI.
9.  **DAO Governance Functions:** Create proposals, vote, execute proposals, manage proposal state.
10. **Treasury Functions:** View balance, withdraw funds (via DAO execution).
11. **Internal Helper Functions:** Functions called only internally, often by executed proposals.

**Function Summary:**

*   `constructor()`: Initializes the contract, setting initial parameters and owner.
*   `stake(uint256 amount)`: Allows a user to stake ARTG tokens to gain voting power.
*   `unstake(uint256 amount)`: Allows a user to unstake ARTG tokens after a cooldown period.
*   `claimStakingRewards()`: Allows stakers to claim their share of accumulated rewards (if any).
*   `distributeStakingRewards()`: (Callable by DAO vote) Adds funds to the staking rewards pool.
*   `getTotalStaked(address account)`: Returns the amount of ARTG staked by an account. (View)
*   `getTotalVotingPower(address account)`: Returns the voting power of an account (based on staked balance). (View)
*   `getUnstakeCooldown(address account)`: Returns the timestamp when an account's unstake cooldown ends. (View)
*   `setUnstakeCooldownDuration(uint40 seconds)`: (Callable by DAO vote) Sets the duration of the unstake cooldown period.
*   `getCurrentArtParameters()`: Returns the currently active generative art parameters. (View)
*   `proposeParameterChange(string description, ArtParameters memory newParams)`: Creates a proposal to change the active art parameters.
*   `mintArtPiece()`: Mints a new ArtPiece NFT based on the current parameters. Requires a mint fee paid to the treasury.
*   `getArtPieceOwner(uint256 artPieceId)`: Returns the owner of a specific ArtPiece NFT. (View)
*   `getArtPieceParameters(uint256 artPieceId)`: Returns the parameters used to mint a specific ArtPiece NFT. (View)
*   `tokenURI(uint256 artPieceId)`: Returns the metadata URI for a specific ArtPiece NFT (standard ERC-721 metadata function). (View)
*   `burnArtPiece(uint256 artPieceId)`: Allows the owner of an ArtPiece to burn it.
*   `setBaseTokenURI(string memory newUri)`: (Callable by DAO vote) Sets the base URI for ArtPiece metadata.
*   `setMintFee(uint256 fee)`: (Callable by DAO vote) Sets the fee required to mint an ArtPiece.
*   `getMintFee()`: Returns the current mint fee. (View)
*   `createProposal(string memory description, bytes memory callData, address targetContract)`: Creates a general proposal to execute a function call (on this contract or a designated target) if successful.
*   `voteOnProposal(uint256 proposalId, bool support)`: Allows a staker to vote on an active proposal.
*   `getProposalState(uint256 proposalId)`: Returns the current state of a proposal. (View)
*   `getProposalVotes(uint256 proposalId)`: Returns the vote counts (for and against) for a proposal. (View)
*   `executeProposal(uint256 proposalId)`: Executes a successful proposal.
*   `setVotingPeriod(uint256 duration)`: (Callable by DAO vote) Sets the duration for proposal voting.
*   `getVotingPeriod()`: Returns the proposal voting duration. (View)
*   `getTreasuryBalance()`: Returns the current balance of the contract's treasury. (View)
*   `_applyArtParameters(ArtParameters memory newParams)`: Internal function to update active art parameters (only callable by successful proposal execution).
*   `_withdrawTreasuryFunds(uint256 amount, address payable recipient)`: Internal function to withdraw treasury funds (only callable by successful proposal execution).
*   `_addAllowedShapeType(string memory shape)`: Internal function to add an allowed shape type (only callable by successful proposal execution).
*   `_removeAllowedShapeType(string memory shape)`: Internal function to remove an allowed shape type (only callable by successful proposal execution).
*   `getAllowedShapeTypes()`: Returns the list of currently allowed shape types. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal Context for msg.sender, msg.value (similar to OpenZeppelin Context)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}

// Minimal Ownable (for initial setup, DAO takes over core control)
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// --- Contract Start ---

/**
 * @title GenerativeArtDAO
 * @dev A DAO contract for governing the parameters used to generate generative art pieces (NFTs).
 * Users stake tokens to gain voting power and propose/vote on changes to art parameters,
 * manage the DAO treasury, and mint art pieces based on approved configurations.
 * Art pieces are represented as NFTs with parameters stored on-chain,
 * while the actual rendering happens off-chain based on the on-chain parameters.
 */
contract GenerativeArtDAO is Ownable {

    // --- State Variables ---

    // --- DAO Token & Staking ---
    string public constant DAO_TOKEN_SYMBOL = "ARTG"; // Placeholder, assume ARTG token is managed externally or is symbolic staking power here.
    // In a real system, this would likely interact with an ERC-20 token contract.
    // For this example, we track staked balance internally as voting power.
    mapping(address => uint256) private _stakedBalances; // Amount of ARTG tokens staked by an address

    mapping(address => uint40) private _unstakeCooldowns; // Timestamp when unstake cooldown ends for an address
    uint40 public unstakeCooldownDuration = 7 days; // Default cooldown duration

    uint256 private _totalStaked = 0; // Total amount of ARTG tokens staked in the contract

    // Staking reward pool (funded by DAO proposals/treasury)
    uint256 private _stakingRewardsPool = 0;
    mapping(address => uint256) private _accruedRewards; // Rewards accrued per staker (simplistic model)

    // --- Generative Art Parameters ---
    struct ArtParameters {
        uint256 colorCount; // Max number of colors to use
        uint256 shapeCount; // Max number of shapes/elements
        uint256 complexityScore; // Abstract score influencing density/detail
        string[] allowedShapes; // Array of allowed shape types (e.g., "circle", "square", "triangle")
        bytes32 randomnessSeed; // Seed influencing the generation (can be updated via DAO)
        // Add more parameters as needed for different art styles
    }
    ArtParameters public currentArtParameters; // The currently active parameters for minting

    // --- Art Pieces (NFTs) ---
    struct ArtPiece {
        uint256 tokenId;
        address owner;
        ArtParameters parametersUsed; // Snapshot of parameters when minted
        // string tokenURI; // We'll generate this based on base URI and ID
    }
    mapping(uint256 => ArtPiece) private _artPieces; // Stores details for each minted art piece
    mapping(uint256 => address) private _artPieceOwner; // ERC-721 like ownership mapping
    uint256 private _currentTokenId = 0; // Counter for unique ArtPiece IDs

    string private _baseTokenURI; // Base URI for NFT metadata

    uint256 public mintFee = 0.01 ether; // Fee (in native currency, e.g., ETH) to mint an art piece

    // --- DAO Governance ---
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description; // Description of the proposal
        uint256 creationBlock; // Block number when proposal was created (for voting power snapshot)
        uint256 votingDeadline; // Timestamp when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 quorumRequired; // Minimum votes required for proposal to be valid
        ProposalState state;
        bytes callData; // Data for function call if proposal succeeds
        address targetContract; // Contract to call if proposal succeeds (usually `address(this)`)
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals; // Stores details for each proposal
    mapping(address => mapping(uint256 => bool)) private _hasVoted; // Tracks if an address has voted on a proposal
    mapping(uint256 => mapping(address => uint256)) private _proposalVotingPower; // Snapshot of voting power per voter per proposal

    uint256 private _nextProposalId = 1; // Counter for unique proposal IDs
    uint256 public votingPeriodDuration = 3 days; // Default voting period duration
    uint256 public proposalQuorumBasisPoints = 500; // 5% quorum required (500/10000)

    // --- Treasury ---
    // The contract's balance is the treasury.
    // Funds are collected from minting fees.
    // Withdrawal requires a successful DAO proposal.

    // --- Events ---
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event StakingRewardsClaimed(address indexed account, uint256 amount);
    event StakingRewardsDistributed(uint256 amount);

    event ArtParametersChanged(ArtParameters newParameters);
    event ArtPieceMinted(address indexed owner, uint256 indexed tokenId, ArtParameters parametersUsed);
    event ArtPieceBurned(address indexed owner, uint256 indexed tokenId);
    event BaseTokenURIUpdated(string newUri);
    event MintFeeUpdated(uint256 newFee);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event VotingPeriodUpdated(uint256 duration);

    // --- Constructor ---
    constructor(string memory initialBaseURI) {
        // Set initial basic art parameters (DAO can change these later)
        currentArtParameters = ArtParameters({
            colorCount: 5,
            shapeCount: 10,
            complexityScore: 100,
            allowedShapes: new string[](0), // Start empty, DAO adds shapes
            randomnessSeed: bytes32(uint256(keccak256(abi.encodePacked("initial seed", block.timestamp))))
        });

        // Add some initial allowed shapes (can also be done via proposal)
        _addAllowedShapeType("circle");
        _addAllowedShapeType("square");
        _addAllowedShapeType("triangle");

        _baseTokenURI = initialBaseURI;
        // Owner is set by Ownable constructor
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes ARTG tokens. Assumes ARTG is sent to this contract beforehand (e.g., via ERC-20 transfer).
     * In a real scenario, this would likely require `IERC20(artgTokenAddress).transferFrom(msg.sender, address(this), amount);`
     * For this example, we just update internal balances.
     */
    function stake(uint256 amount) public {
        require(amount > 0, "Stake amount must be > 0");
        // In a real system, verify tokens received
        // require(IERC20(artgTokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        _stakedBalances[msg.sender] += amount;
        _totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Initiates the unstaking process. Amount will be available after cooldown.
     */
    function unstake(uint256 amount) public {
        require(amount > 0, "Unstake amount must be > 0");
        require(_stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        require(_unstakeCooldowns[msg.sender] <= block.timestamp, "Unstake cooldown active");

        _stakedBalances[msg.sender] -= amount;
        _totalStaked -= amount;

        // Set cooldown for future unstakes
        _unstakeCooldowns[msg.sender] = uint40(block.timestamp + unstakeCooldownDuration);

        emit Unstaked(msg.sender, amount);

        // In a real system, transfer tokens back here
        // require(IERC20(artgTokenAddress).transfer(msg.sender, amount), "Token transfer failed");
    }

    /**
     * @dev Sets the duration for the unstake cooldown. Callable only via successful DAO proposal.
     */
    function setUnstakeCooldownDuration(uint40 seconds) external {
        // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call"); // Simplified check: only internal calls allowed

        unstakeCooldownDuration = seconds;
        // No specific event for this, covered by ProposalExecuted
    }

    /**
     * @dev (Simplified) Claims staking rewards. Assumes rewards are distributed manually to the pool.
     * In a real system, rewards calculation would be more complex (e.g., based on duration staked, total pool size).
     */
    function claimStakingRewards() public {
        uint256 rewards = _accruedRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");

        _stakingRewardsPool -= rewards;
        _accruedRewards[msg.sender] = 0;

        // In a real system, transfer reward tokens (or ETH)
        // payable(msg.sender).transfer(rewards); // If rewards are in native currency
        // OR IERC20(rewardTokenAddress).transfer(msg.sender, rewards);

        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev (Simplified) Adds funds to the staking rewards pool. Callable only via successful DAO proposal.
     * The distribution mechanism (how accruedRewards is calculated) is not fully implemented here for simplicity.
     */
    function distributeStakingRewards() external payable {
         // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call"); // Simplified check: only internal calls allowed

        _stakingRewardsPool += msg.value;
        emit StakingRewardsDistributed(msg.value);

        // Note: A real system would need logic here or in claimStakingRewards
        // to correctly allocate rewards to stakers based on their stake over time.
    }


    // --- View Functions for Staking ---

    function getTotalStaked(address account) public view returns (uint256) {
        return _stakedBalances[account];
    }

    function getTotalVotingPower(address account) public view returns (uint256) {
        // Basic 1:1 mapping for voting power to staked balance
        return _stakedBalances[account];
    }

    function getUnstakeCooldown(address account) public view returns (uint40) {
        return _unstakeCooldowns[account];
    }

    // --- Generative Art Parameter Functions ---

    /**
     * @dev Returns the parameters currently used for minting new art pieces.
     */
    function getCurrentArtParameters() public view returns (ArtParameters memory) {
        return currentArtParameters;
    }

    /**
     * @dev Creates a proposal to change the parameters used for generating art.
     * Only stakers with sufficient voting power can create proposals.
     */
    function proposeParameterChange(string memory description, ArtParameters memory newParams) public {
        // Encode the function call to _applyArtParameters
        bytes memory callData = abi.encodeWithSelector(this._applyArtParameters.selector, newParams);

        // Reuse the general proposal creation function
        createProposal(description, callData, address(this));
        // Note: The proposal creation checks (staking, min power) are within createProposal
    }

    /**
     * @dev Internal function to apply new art parameters. Only callable via a successful proposal execution.
     */
    function _applyArtParameters(ArtParameters memory newParams) internal {
        // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call");

        currentArtParameters = newParams;
        emit ArtParametersChanged(currentArtParameters);
    }

    /**
     * @dev Internal function to add an allowed shape type. Only callable via a successful proposal execution.
     */
    function _addAllowedShapeType(string memory shape) internal {
        // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call");

        // Prevent duplicates (basic check)
        for(uint i = 0; i < currentArtParameters.allowedShapes.length; i++) {
            if(keccak256(bytes(currentArtParameters.allowedShapes[i])) == keccak256(bytes(shape))) {
                // Shape already exists, do nothing or revert. Reverting is cleaner for proposal execution logic.
                revert("Shape already allowed");
            }
        }

        currentArtParameters.allowedShapes.push(shape);
        // No specific event for this, covered by ProposalExecuted
    }

     /**
     * @dev Internal function to remove an allowed shape type. Only callable via a successful proposal execution.
     * Note: This is less gas efficient for large arrays.
     */
    function _removeAllowedShapeType(string memory shape) internal {
        // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call");

        bool found = false;
        for(uint i = 0; i < currentArtParameters.allowedShapes.length; i++) {
            if(keccak256(bytes(currentArtParameters.allowedShapes[i])) == keccak256(bytes(shape))) {
                // Found the shape, remove it by swapping with last and shrinking array
                currentArtParameters.allowedShapes[i] = currentArtParameters.allowedShapes[currentArtParameters.allowedShapes.length - 1];
                currentArtParameters.allowedShapes.pop();
                found = true;
                break; // Assuming no duplicates, exit loop
            }
        }
        require(found, "Shape not found");
        // No specific event for this, covered by ProposalExecuted
    }

    /**
     * @dev Returns the list of currently allowed shape types.
     */
    function getAllowedShapeTypes() public view returns (string[] memory) {
        return currentArtParameters.allowedShapes;
    }


    // --- Art Piece (NFT) Functions ---

    /**
     * @dev Mints a new ArtPiece NFT to the caller. Requires payment of the mint fee.
     * The art piece is minted with the parameters active at the time of minting.
     */
    function mintArtPiece() public payable {
        require(_msgValue() >= mintFee, "Insufficient mint fee");

        uint256 tokenId = _currentTokenId;
        _currentTokenId++;

        _artPieceOwner[tokenId] = msg.sender;

        // Store the parameters used for this specific piece
        _artPieces[tokenId] = ArtPiece({
            tokenId: tokenId,
            owner: msg.sender,
            parametersUsed: currentArtParameters // Snapshot the current parameters
        });

        // Refund excess payment
        if (_msgValue() > mintFee) {
            payable(_msgSender()).transfer(_msgValue() - mintFee);
        }

        // Mint fee goes to the treasury (contract balance)
        // This happens automatically because msg.value is sent to the contract

        emit ArtPieceMinted(msg.sender, tokenId, currentArtParameters);
    }

    /**
     * @dev Returns the owner of the specified ArtPiece. Follows ERC-721 naming.
     */
    function getArtPieceOwner(uint256 artPieceId) public view returns (address) {
         require(_artPieceOwner[artPieceId] != address(0), "Art piece does not exist");
        return _artPieceOwner[artPieceId];
    }

     /**
     * @dev Returns the parameters used to mint the specified ArtPiece.
     */
    function getArtPieceParameters(uint256 artPieceId) public view returns (ArtParameters memory) {
        require(_artPieces[artPieceId].owner != address(0), "Art piece does not exist"); // Check existence via owner mapping
        return _artPieces[artPieceId].parametersUsed;
    }

    /**
     * @dev Returns the metadata URI for a specific ArtPiece. Follows ERC-721 naming.
     * The actual metadata JSON should live off-chain (e.g., IPFS) at baseURI/tokenId.json
     */
    function tokenURI(uint256 artPieceId) public view returns (string memory) {
        require(_artPieces[artPieceId].owner != address(0), "Art piece does not exist"); // Check existence
        // Construct the URI: baseURI + tokenId
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(artPieceId), ".json"));
    }

    /**
     * @dev Allows the owner of an ArtPiece to burn it.
     */
    function burnArtPiece(uint256 artPieceId) public {
        require(_artPieceOwner[artPieceId] == msg.sender, "Not owner of this art piece");

        delete _artPieceOwner[artPieceId];
        delete _artPieces[artPieceId]; // Delete associated parameters/data

        emit ArtPieceBurned(msg.sender, artPieceId);
    }

     /**
     * @dev Sets the base URI for ArtPiece metadata. Callable only via successful DAO proposal.
     */
    function setBaseTokenURI(string memory newUri) external {
         // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call");

        _baseTokenURI = newUri;
        emit BaseTokenURIUpdated(newUri);
    }

    /**
     * @dev Sets the fee required to mint an ArtPiece. Callable only via successful DAO proposal.
     */
    function setMintFee(uint256 fee) external {
         // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call");

        mintFee = fee;
        emit MintFeeUpdated(fee);
    }

    /**
     * @dev Returns the current mint fee.
     */
    function getMintFee() public view returns (uint256) {
        return mintFee;
    }

    // --- DAO Governance Functions ---

    /**
     * @dev Creates a new general proposal. Requires the proposer to have staking power.
     * The proposal includes calldata to be executed on a target contract (usually `address(this)`) if successful.
     */
    function createProposal(string memory description, bytes memory callData, address targetContract) public {
        uint256 proposerVotingPower = getTotalVotingPower(msg.sender);
        // require(proposerVotingPower > 0, "Must have staking power to propose"); // Optional: enforce minimum proposal power

        uint256 proposalId = _nextProposalId;
        _nextProposalId++;

        uint256 quorumRequired = (_totalStaked * proposalQuorumBasisPoints) / 10000; // Calculate quorum based on total stake

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            creationBlock: block.number, // Snapshot block for voting power (basic)
            votingDeadline: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            quorumRequired: quorumRequired,
            state: ProposalState.Active,
            callData: callData,
            targetContract: targetContract,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, description, proposals[proposalId].votingDeadline);
    }

    /**
     * @dev Allows a staker to vote on an active proposal.
     * Voting power is snapshotted at the block the proposal was created.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!_hasVoted[msg.sender][proposalId], "Already voted on this proposal");

        // Get voting power at the block the proposal was created
        // Note: requires node support for historic balance checks or a separate snapshot system.
        // Simplified here by using current voting power, but storing it per vote.
        // A more robust system would use a checkpoint/snapshot library.
        uint256 voterVotingPower = getTotalVotingPower(msg.sender);
        require(voterVotingPower > 0, "Must have staking power to vote");

        _hasVoted[msg.sender][proposalId] = true;
        _proposalVotingPower[proposalId][msg.sender] = voterVotingPower; // Store power used for this vote

        if (support) {
            proposal.votesFor += voterVotingPower;
        } else {
            proposal.votesAgainst += voterVotingPower;
        }

        emit Voted(proposalId, msg.sender, support, voterVotingPower);
    }

    /**
     * @dev Executes a successful proposal. Checks conditions like voting period end, success criteria (more 'for' votes, meeting quorum).
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal must be active");
        require(block.timestamp > proposal.votingDeadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        // Check if quorum is met (total votes >= quorumRequired)
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        bool quorumMet = totalVotes >= proposal.quorumRequired;

        // Check if proposal succeeded (more 'for' votes than 'against', and quorum met)
        bool succeeded = proposal.votesFor > proposal.votesAgainst && quorumMet;

        if (succeeded) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalStateChanged(proposalId, ProposalState.Succeeded);

            // Execute the proposal's action
            // Use low-level call for flexibility, requires careful targetContract and callData validation
            (bool success, ) = proposal.targetContract.call(proposal.callData);

            proposal.executed = true;
            emit ProposalExecuted(proposalId, success);

            // If execution failed, you might want to change the proposal state or handle it
            // require(success, "Proposal execution failed"); // Decide if failed execution should revert executeProposal
        } else {
            proposal.state = ProposalState.Defeated;
             emit ProposalStateChanged(proposalId, ProposalState.Defeated);
             emit ProposalExecuted(proposalId, false); // Still emit execution event marking failure
        }
    }

    /**
     * @dev Cancels a proposal. Can potentially be added later (e.g., by proposer before voting starts, or by governance).
     * Not implemented here to keep function count focused on core loop, but good concept.
     */
    // function cancelProposal(uint256 proposalId) public { ... }


     /**
     * @dev Sets the duration for proposal voting periods. Callable only via successful DAO proposal.
     */
    function setVotingPeriod(uint256 duration) external {
        // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call");

        votingPeriodDuration = duration;
        emit VotingPeriodUpdated(duration);
    }

    /**
     * @dev Returns the current duration for proposal voting periods.
     */
    function getVotingPeriod() public view returns (uint256) {
        return votingPeriodDuration;
    }


    // --- View Functions for Governance ---

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        // Check if proposal exists (optional, but good practice)
        if (proposals[proposalId].creationBlock == 0 && proposalId != 0) return ProposalState.Pending; // Assume 0 is non-existent or initial state

        ProposalState currentState = proposals[proposalId].state;

        // If active, check if voting period ended to potentially update state implicitly
        if (currentState == ProposalState.Active && block.timestamp > proposals[proposalId].votingDeadline) {
             // Note: This view function doesn't change state. executeProposal() must be called
             // to finalize the state based on votes after the deadline.
             // This just provides an updated state *view* based on time.
             uint256 totalVotes = proposals[proposalId].votesFor + proposals[proposalId].votesAgainst;
             bool quorumMet = totalVotes >= proposals[proposalId].quorumRequired;

             if (proposals[proposalId].votesFor > proposals[proposalId].votesAgainst && quorumMet) {
                 return ProposalState.Succeeded; // Would be Succeeded if executed
             } else {
                 return ProposalState.Defeated; // Would be Defeated if executed
             }
        }

        return currentState;
    }

    function getProposalVotes(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        return (proposals[proposalId].votesFor, proposals[proposalId].votesAgainst);
    }

    // --- Treasury Functions ---

    /**
     * @dev Returns the current balance of the contract's treasury (native currency).
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Internal function to withdraw funds from the treasury. Only callable via a successful proposal execution.
     */
    function _withdrawTreasuryFunds(uint256 amount, address payable recipient) internal {
        // Ensure this function is only called via executeProposal with the correct target/calldata
        require(msg.sender == address(this), "Unauthorized call");
        require(address(this).balance >= amount, "Insufficient treasury balance");

        recipient.transfer(amount);
        // No specific event for this, covered by ProposalExecuted
    }

    // --- Internal Helper Functions ---

    // Helper to convert uint256 to string (simple, avoids full library)
    // From OpenZeppelin's Strings library
    library Strings {
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
}
```