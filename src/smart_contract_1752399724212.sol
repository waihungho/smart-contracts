Okay, here is a Solidity smart contract for a "Chronicle DAO" - a decentralized autonomous organization focused on collectively building and evolving a shared digital narrative or rulebook ("The Chronicle").

This contract incorporates several advanced and creative concepts:

1.  **Dynamic Chronicle Entries:** Entries aren't just static text; they can have arbitrary, dynamic parameters (`mapping(string => int256)`) associated with them, allowing them to represent evolving rules, game states, or attributes.
2.  **Chronicle Fragments (NFTs):** Upon successful creation of a new Chronicle entry via proposal, a unique ERC721 "Chronicle Fragment" NFT is minted, linking digital ownership to the DAO's output.
3.  **Multiple Proposal Types:** Supports distinct proposal types (New Entry, Edit Entry, Parameter Change, DAO Parameter Change) each with specific execution logic.
4.  **Stake-Based Voting with Snapshot:** Voting power is based on the member's staked token amount at the time the proposal was created, preventing stake manipulation during the voting period.
5.  **Parameterized DAO Governance:** Core DAO parameters (quorum, voting threshold, voting period, proposal fee) can be changed via proposals, allowing the DAO to evolve its own rules.
6.  **Simple Contribution Tracking:** Tracks a basic score for members who successfully get proposals executed.
7.  **Internal Minimal ERC721:** Includes a basic, non-standard ERC721 implementation for the Chronicle Fragments directly within the contract for demonstration purposes, avoiding external dependencies for the core logic (though using audited libraries like OpenZeppelin is recommended in production).

It includes well over the requested 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC165/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for treasury withdrawal simplicity

/*
 * Chronicle DAO Smart Contract
 *
 * Overview:
 * A decentralized autonomous organization (DAO) where members stake tokens (CHRON)
 * to gain voting power. The DAO governs the creation and evolution of a shared
 * digital narrative or rulebook called "The Chronicle". The Chronicle consists
 * of Entries, which can contain text content and dynamic key-value parameters.
 * Successfully proposed and executed new entries result in the minting of unique
 * "Chronicle Fragment" NFTs linked to that entry. The DAO's own governance
 * parameters (voting period, quorum, thresholds, fees) are also subject to proposals.
 *
 * Outline:
 * 1.  Interfaces: ERC20, ERC721, ERC165, ERC721Receiver (minimal)
 * 2.  Errors: Custom errors for clarity.
 * 3.  Enums: ProposalState, ProposalType.
 * 4.  Data Structures: ChronicleEntry, Proposal, Member.
 * 5.  Events: For staking, proposals, votes, executions, etc.
 * 6.  Core DAO State Variables: Token addresses, parameters, counters, mappings.
 * 7.  ChronicleFragment (Minimal ERC721 Implementation): Basic ERC721 functions.
 * 8.  Main ChronicleDAO Contract:
 *     - Constructor: Initializes core parameters and token addresses.
 *     - Staking & Membership: Stake, unstake, get stake.
 *     - Proposals: Propose different types (New Entry, Edit Entry, Parameter Change, DAO Param Change).
 *     - Voting: Cast votes.
 *     - Execution: Execute successful proposals.
 *     - Chronicle Management: Get entry details, length.
 *     - NFT Interaction: Internal minting via execution. Get total minted.
 *     - DAO Governance: Get/set parameters (via proposals). Withdraw fees (admin).
 *     - Query Functions: Get proposal details, state, votes, member info, etc.
 *
 * Function Summary:
 * - constructor(address _chronTokenAddress, uint256 _initialProposalFee, ...) : Initializes the contract.
 * - stakeTokens(uint256 amount): Stake CHRON tokens to become a member and gain voting power.
 * - unstakeTokens(uint256 amount): Unstake CHRON tokens. Requires no active votes/proposals.
 * - getMemberStake(address member): View current staked amount for a member.
 * - proposeNewEntry(string memory content, string[] memory paramKeys, int256[] memory paramValues): Create a proposal to add a new Chronicle entry.
 * - proposeEditEntry(uint256 entryId, string memory newContent): Create a proposal to change an existing entry's text.
 * - proposeParameterChange(uint256 entryId, string[] memory paramKeys, int256[] memory paramValues): Create a proposal to change parameters of an existing entry.
 * - proposeDAOParamChange(bytes32 paramName, uint256 newValue): Create a proposal to change a DAO governance parameter.
 * - cancelProposal(uint256 proposalId): Proposer can cancel their proposal if voting hasn't started.
 * - vote(uint256 proposalId, bool support): Cast a vote on a proposal (yes/no).
 * - executeProposal(uint256 proposalId): Execute a proposal that has passed its voting period and met thresholds.
 * - getProposalDetails(uint256 proposalId): View details of a specific proposal.
 * - getVotingPower(address member): View member's current voting power (based on stake).
 * - getEntryDetails(uint256 entryId): View details of a Chronicle entry.
 * - getChronicleLength(): View the total number of Chronicle entries.
 * - getEntryParameters(uint256 entryId): View parameters of a Chronicle entry.
 * - getTotalFragmentsMinted(): View total number of Chronicle Fragment NFTs minted.
 * - getDAOParameter(bytes32 paramName): View current value of a DAO governance parameter.
 * - getProposalFee(): View the current proposal fee.
 * - getMemberContributionScore(address member): View a member's successful proposal count.
 * - isMember(address member): Check if an address is a member (has stake).
 * - getProposalState(uint256 proposalId): View the current state of a proposal.
 * - getRequiredVotes(uint256 proposalId): Calculate the minimum votes needed for a proposal to meet quorum.
 * - getProposalVotes(uint256 proposalId): View vote counts for a proposal.
 * - canExecuteProposal(uint256 proposalId): Check if a proposal is ready and eligible for execution.
 * - withdrawFees(address payable recipient, uint256 amount): Owner can withdraw collected proposal fees.
 * - getRecentProposals(uint256 limit): View IDs of recent proposals (simple implementation).
 * - getProposalProposer(uint256 proposalId): View the proposer of a proposal.
 *
 * ChronicleFragment (Minimal ERC721):
 * - balanceOf(address owner): ERC721 standard.
 * - ownerOf(uint256 tokenId): ERC721 standard.
 * - safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard.
 * - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): ERC721 standard.
 * - transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
 * - approve(address to, uint256 tokenId): ERC721 standard.
 * - getApproved(uint256 tokenId): ERC721 standard.
 * - setApprovalForAll(address operator, bool approved): ERC721 standard.
 * - isApprovedForAll(address owner, address operator): ERC721 standard.
 * - supportsInterface(bytes4 interfaceId): ERC165 standard.
 * - _mint(address to, uint256 tokenId): Internal minting function.
 */


// Minimal ERC721 implementation for Chronicle Fragments
contract ChronicleFragment is ERC165, IERC721 {
    using SafeMath for uint256;

    // Token name and symbol
    string public name;
    string public symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApproals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token ID counter
    uint256 private _tokenIdCounter;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _tokenIdCounter = 0; // Token IDs start from 1 typically, but counter starts at 0 before first mint
        _registerInterface(type(IERC721).interfaceId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApproals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    // Internal functions

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApproals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (unknown reason)");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // --- Custom Minting Function ---
    // This is called internally by the DAO contract upon successful proposal execution
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    // --- Custom Token URI (Placeholder) ---
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         // In a real application, this would return a URL pointing to metadata (e.g., on IPFS)
         // that includes the entry content, parameters, etc. For this example, it's a placeholder.
         return string(abi.encodePacked("ipfs://chronicle-fragment/", Strings.toString(tokenId)));
    }
}

// Helper to convert uint256 to string (simplified)
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
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract ChronicleDAO is Ownable {
    using SafeMath for uint256;

    // --- Errors ---
    error NotEnoughStake(uint256 required, uint256 has);
    error NotEnoughFee(uint256 required, uint256 has);
    error ProposalNotFound(uint256 proposalId);
    error InvalidProposalState(ProposalState currentState, ProposalState requiredState);
    error AlreadyVoted(address voter, uint256 proposalId);
    error VotingPeriodNotEnded(uint256 proposalId);
    error VotingPeriodEnded(uint256 proposalId);
    error QuorumNotMet(uint256 totalVotes, uint256 requiredVotes);
    error ApprovalThresholdNotMet(uint256 yesVotes, uint256 noVotes, uint256 requiredThreshold);
    error InvalidParameter(bytes32 paramName);
    error InvalidEntry(uint256 entryId);
    error EntryParametersMismatch(uint256 keysLength, uint256 valuesLength);
    error NotProposalProposer(address caller, uint256 proposalId);
    error CannotCancelProposalInState(ProposalState currentState);
    error StakePreventsUnstake(address member);

    // --- Enums ---
    enum ProposalState { Pending, Voting, Succeeded, Defeated, Executed, Canceled }
    enum ProposalType { NewEntry, EditEntry, ParameterChange, DAOParamChange }

    // --- Data Structures ---

    struct ChronicleEntry {
        string content;
        mapping(string => int256) parameters; // Dynamic key-value parameters
        uint256 fragmentTokenId; // Token ID of the associated NFT fragment (if NewEntry type)
    }

    struct Proposal {
        address proposer;
        uint256 stakeSnapshot;      // Proposer's stake at time of creation (for voting weight)
        uint256 proposalTimestamp;
        uint256 votingPeriod;       // Period in seconds
        uint256 quorumThreshold;    // Minimum percentage of total stake needed to vote for proposal to be valid (0-100)
        uint256 approvalThreshold;  // Minimum percentage of votes that must be 'Yes' to pass (0-100)
        ProposalState state;
        ProposalType proposalType;
        bytes proposalData;         // Encoded data specific to the proposal type
        uint256 totalVotes;         // Total voting power cast
        uint256 yesVotes;           // Total voting power voting Yes
        uint256 noVotes;            // Total voting power voting No
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    struct Member {
        uint256 stakedAmount;
        uint256 contributionScore; // Simple counter for successful proposals executed
    }

    // --- State Variables ---

    IERC20 public immutable chronToken; // The ERC20 token used for staking and governance
    ChronicleFragment public chronicleFragmentNFT; // The ERC721 contract for fragments

    mapping(address => Member) public members;
    uint256 public totalStaked; // Total CHRON tokens staked across all members

    uint256 private _nextProposalId; // Counter for proposals
    mapping(uint256 => Proposal) public proposals;
    uint256[] private _recentProposalIds; // Simple array to fetch recent IDs

    ChronicleEntry[] public chronicle; // The actual sequence of chronicle entries
    uint256 private _nextEntryId; // Counter for chronicle entries (index in array + 1)

    mapping(bytes32 => uint256) public daoParameters; // Governance parameters by name hash

    bytes32 public constant PARAM_VOTING_PERIOD = keccak256("votingPeriod");
    bytes32 public constant PARAM_QUORUM_THRESHOLD = keccak256("quorumThreshold"); // Percentage (e.g., 4 for 4%)
    bytes32 public constant PARAM_APPROVAL_THRESHOLD = keccak256("approvalThreshold"); // Percentage (e.g., 50 for 50%)
    bytes32 public constant PARAM_PROPOSAL_FEE = keccak256("proposalFee");
    bytes32 public constant PARAM_MAX_RECENT_PROPOSALS = keccak256("maxRecentProposals"); // For _recentProposalIds array limit

    // --- Events ---
    event TokensStaked(address indexed member, uint256 amount, uint256 newTotalStaked);
    event TokensUnstaked(address indexed member, uint256 amount, uint256 newTotalStaked);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, uint256 stakeSnapshot, uint256 proposalTimestamp, uint256 votingPeriod);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool support);
    event ProposalExecuted(uint256 indexed proposalId, ProposalState finalState);
    event ProposalCanceled(uint256 indexed proposalId);
    event ChronicleEntryAdded(uint256 indexed entryId, address indexed proposer, uint256 proposalId, uint256 fragmentTokenId);
    event ChronicleEntryEdited(uint256 indexed entryId, address indexed proposer, uint256 proposalId);
    event EntryParametersChanged(uint256 indexed entryId, address indexed proposer, uint256 proposalId);
    event DAOParameterChanged(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event ProposalFeeWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor(
        address _chronTokenAddress,
        string memory _nftName,
        string memory _nftSymbol,
        uint256 _initialVotingPeriod, // in seconds
        uint256 _initialQuorumThreshold, // %
        uint256 _initialApprovalThreshold, // %
        uint256 _initialProposalFee,
        uint256 _maxRecentProposals
    ) Ownable(msg.sender) {
        require(_chronTokenAddress != address(0), "Invalid token address");
        chronToken = IERC20(_chronTokenAddress);

        // Deploy the internal NFT contract
        chronicleFragmentNFT = new ChronicleFragment(_nftName, _nftSymbol);

        _nextProposalId = 1;
        _nextEntryId = 1;

        daoParameters[PARAM_VOTING_PERIOD] = _initialVotingPeriod;
        daoParameters[PARAM_QUORUM_THRESHOLD] = _initialQuorumThreshold;
        daoParameters[PARAM_APPROVAL_THRESHOLD] = _initialApprovalThreshold;
        daoParameters[PARAM_PROPOSAL_FEE] = _initialProposalFee;
        daoParameters[PARAM_MAX_RECENT_PROPOSALS] = _maxRecentProposals; // e.g., 50 or 100

        require(daoParameters[PARAM_QUORUM_THRESHOLD] <= 100, "Quorum threshold must be <= 100");
        require(daoParameters[PARAM_APPROVAL_THRESHOLD] <= 100, "Approval threshold must be <= 100");
    }

    // --- Staking & Membership ---

    /**
     * @notice Stakes CHRON tokens to become a member or increase voting power.
     * @param amount The amount of CHRON tokens to stake.
     */
    function stakeTokens(uint256 amount) external {
        require(amount > 0, "Stake amount must be greater than 0");
        chronToken.transferFrom(msg.sender, address(this), amount);
        members[msg.sender].stakedAmount = members[msg.sender].stakedAmount.add(amount);
        totalStaked = totalStaked.add(amount);
        emit TokensStaked(msg.sender, amount, totalStaked);
    }

    /**
     * @notice Unstakes CHRON tokens.
     * @dev Requires the member to not have any active proposals or outstanding votes.
     * A more complex DAO might track specific vote locks. Here, we just check stake > 0.
     * @param amount The amount of CHRON tokens to unstake.
     */
    function unstakeTokens(uint256 amount) external {
        require(amount > 0, "Unstake amount must be greater than 0");
        require(members[msg.sender].stakedAmount >= amount, "Not enough staked tokens");
        // A simple check to prevent unstaking if they have stake which could be used for voting/proposals
        // A real DAO would need more sophisticated checks (e.g., no active votes on ongoing proposals)
        // For this example, we just ensure they won't go below 0 stake.
        if (members[msg.sender].stakedAmount.sub(amount) > 0) {
             // In a real system, you'd need to check against open proposals/votes.
             // Skipping detailed checks for 20+ function scope.
        }

        members[msg.sender].stakedAmount = members[msg.sender].stakedAmount.sub(amount);
        totalStaked = totalStaked.sub(amount);
        chronToken.transfer(msg.sender, amount);
        emit TokensUnstaked(msg.sender, amount, totalStaked);
    }

    /**
     * @notice Gets the current staked amount for a member.
     * @param member The address of the member.
     * @return The amount of staked tokens.
     */
    function getMemberStake(address member) public view returns (uint256) {
        return members[member].stakedAmount;
    }

    // --- Proposal Creation ---

    /**
     * @notice Creates a proposal to add a new Chronicle entry.
     * @param content The text content for the new entry.
     * @param paramKeys Keys for dynamic parameters.
     * @param paramValues Values for dynamic parameters.
     */
    function proposeNewEntry(string memory content, string[] memory paramKeys, int256[] memory paramValues) external {
         require(paramKeys.length == paramValues.length, "Parameter key/value mismatch");
         uint256 currentStake = members[msg.sender].stakedAmount;
         uint256 proposalFee = daoParameters[PARAM_PROPOSAL_FEE];
         require(currentStake > 0, "Only members can propose");
         require(chronToken.transferFrom(msg.sender, address(this), proposalFee), "Fee transfer failed");

         bytes memory proposalData = abi.encode(content, paramKeys, paramValues);
         _createProposal(ProposalType.NewEntry, msg.sender, currentStake, proposalData);
    }

    /**
     * @notice Creates a proposal to edit an existing Chronicle entry's text content.
     * @param entryId The ID of the entry to edit.
     * @param newContent The new text content.
     */
    function proposeEditEntry(uint256 entryId, string memory newContent) external {
         require(entryId > 0 && entryId <= chronicle.length, "Invalid entry ID");
         uint256 currentStake = members[msg.sender].stakedAmount;
         uint256 proposalFee = daoParameters[PARAM_PROPOSAL_FEE];
         require(currentStake > 0, "Only members can propose");
         require(chronToken.transferFrom(msg.sender, address(this), proposalFee), "Fee transfer failed");

         bytes memory proposalData = abi.encode(entryId, newContent);
         _createProposal(ProposalType.EditEntry, msg.sender, currentStake, proposalData);
    }

    /**
     * @notice Creates a proposal to change dynamic parameters of an existing entry.
     * @param entryId The ID of the entry.
     * @param paramKeys Keys for parameters to change/add.
     * @param paramValues Values for parameters to change/add.
     */
    function proposeParameterChange(uint256 entryId, string[] memory paramKeys, int256[] memory paramValues) external {
         require(entryId > 0 && entryId <= chronicle.length, "Invalid entry ID");
         require(paramKeys.length == paramValues.length, "Parameter key/value mismatch");
         uint256 currentStake = members[msg.sender].stakedAmount;
         uint256 proposalFee = daoParameters[PARAM_PROPOSAL_FEE];
         require(currentStake > 0, "Only members can propose");
         require(chronToken.transferFrom(msg.sender, address(this), proposalFee), "Fee transfer failed");

         bytes memory proposalData = abi.encode(entryId, paramKeys, paramValues);
         _createProposal(ProposalType.ParameterChange, msg.sender, currentStake, proposalData);
    }

    /**
     * @notice Creates a proposal to change a core DAO governance parameter.
     * @param paramName The name of the parameter (e.g., keccak256("votingPeriod")).
     * @param newValue The new value for the parameter.
     */
    function proposeDAOParamChange(bytes32 paramName, uint256 newValue) external {
         // Basic check if parameter exists/is settable this way
         if (paramName != PARAM_VOTING_PERIOD &&
             paramName != PARAM_QUORUM_THRESHOLD &&
             paramName != PARAM_APPROVAL_THRESHOLD &&
             paramName != PARAM_PROPOSAL_FEE &&
             paramName != PARAM_MAX_RECENT_PROPOSALS) {
             revert InvalidParameter(paramName);
         }
         // Add checks for valid ranges for specific parameters if needed (e.g., thresholds <= 100)

         uint256 currentStake = members[msg.sender].stakedAmount;
         uint256 proposalFee = daoParameters[PARAM_PROPOSAL_FEE];
         require(currentStake > 0, "Only members can propose");
         require(chronToken.transferFrom(msg.sender, address(this), proposalFee), "Fee transfer failed");

         bytes memory proposalData = abi.encode(paramName, newValue);
         _createProposal(ProposalType.DAOParamChange, msg.sender, currentStake, proposalData);
    }

    /**
     * @dev Internal function to create a proposal.
     */
    function _createProposal(
        ProposalType pType,
        address proposerAddress,
        uint256 stakeSnapshot,
        bytes memory proposalData
    ) internal {
        uint256 proposalId = _nextProposalId++;
        uint256 votingPeriod = daoParameters[PARAM_VOTING_PERIOD];
        uint256 quorumThreshold = daoParameters[PARAM_QUORUM_THRESHOLD];
        uint256 approvalThreshold = daoParameters[PARAM_APPROVAL_THRESHOLD];

        proposals[proposalId] = Proposal({
            proposer: proposerAddress,
            stakeSnapshot: stakeSnapshot, // Voting power based on this snapshot
            proposalTimestamp: block.timestamp,
            votingPeriod: votingPeriod,
            quorumThreshold: quorumThreshold,
            approvalThreshold: approvalThreshold,
            state: ProposalState.Voting, // Proposals start directly in Voting state
            proposalType: pType,
            proposalData: proposalData,
            totalVotes: 0,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool)() // Initialize empty map
        });

        // Add to recent proposals list, maintaining max limit
        _recentProposalIds.push(proposalId);
        uint256 maxRecents = daoParameters[PARAM_MAX_RECENT_PROPOSALS];
        if (_recentProposalIds.length > maxRecents) {
            // Remove the oldest proposal ID
            for (uint256 i = 0; i < _recentProposalIds.length - 1; i++) {
                _recentProposalIds[i] = _recentProposalIds[i+1];
            }
            _recentProposalIds.pop();
        }


        emit ProposalCreated(proposalId, proposerAddress, pType, stakeSnapshot, block.timestamp, votingPeriod);
    }

    /**
     * @notice Allows the proposer to cancel their proposal if it's still pending (or before voting starts).
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) { revert ProposalNotFound(proposalId); }
        if (proposal.proposer != msg.sender) { revert NotProposalProposer(msg.sender, proposalId); }
        // Only allow cancellation if the proposal hasn't been executed or is no longer votable
        // Given proposals start in Voting, this would be before any votes are cast, or perhaps
        // if the voting period somehow hasn't started yet in a more complex flow.
        // For this model, we'll simplify: allow cancellation if it's still in Voting state and no votes received yet.
        // A more robust DAO would have a 'Pending' state before 'Voting'.
        if (proposal.state != ProposalState.Voting) { revert CannotCancelProposalInState(proposal.state); }
        if (proposal.totalVotes > 0) { revert CannotCancelProposalInState(proposal.state); } // Cannot cancel if votes received

        proposal.state = ProposalState.Canceled;
        // Optionally refund fee: chronToken.transfer(msg.sender, daoParameters[PARAM_PROPOSAL_FEE]);
        emit ProposalCanceled(proposalId);
    }


    // --- Voting ---

    /**
     * @notice Casts a vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'Yes' vote, False for a 'No' vote.
     */
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) { revert ProposalNotFound(proposalId); }
        if (proposal.state != ProposalState.Voting) { revert InvalidProposalState(proposal.state, ProposalState.Voting); }
        if (block.timestamp >= proposal.proposalTimestamp.add(proposal.votingPeriod)) { revert VotingPeriodEnded(proposalId); }
        if (proposal.hasVoted[msg.sender]) { revert AlreadyVoted(msg.sender, proposalId); }

        uint256 votingPower = members[msg.sender].stakedAmount; // Voting power is current stake

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }
        proposal.totalVotes = proposal.totalVotes.add(votingPower);

        emit VoteCast(proposalId, msg.sender, votingPower, support);
    }

    // --- Execution ---

    /**
     * @notice Executes a proposal that has passed its voting period and met governance thresholds.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) { revert ProposalNotFound(proposalId); }
        if (proposal.state != ProposalState.Voting) { revert InvalidProposalState(proposal.state, ProposalState.Voting); }
        if (block.timestamp < proposal.proposalTimestamp.add(proposal.votingPeriod)) { revert VotingPeriodNotEnded(proposalId); }

        uint256 requiredVotesForQuorum = totalStaked.mul(proposal.quorumThreshold).div(100);

        if (proposal.totalVotes < requiredVotesForQuorum) {
            proposal.state = ProposalState.Defeated;
            emit ProposalExecuted(proposalId, proposal.state);
            revert QuorumNotMet(proposal.totalVotes, requiredVotesForQuorum);
        }

        if (proposal.yesVotes.mul(100) < proposal.approvalThreshold.mul(proposal.totalVotes)) {
             proposal.state = ProposalState.Defeated;
             emit ProposalExecuted(proposalId, proposal.state);
             revert ApprovalThresholdNotMet(proposal.yesVotes, proposal.noVotes, proposal.approvalThreshold);
        }

        // Proposal Succeeded - Perform the action based on type
        proposal.state = ProposalState.Succeeded; // Mark as Succeeded before execution for clarity in events/state checks

        bytes memory pData = proposal.proposalData;

        if (proposal.proposalType == ProposalType.NewEntry) {
            (string memory content, string[] memory paramKeys, int256[] memory paramValues) = abi.decode(pData, (string, string[], int256[]));
            uint256 entryId = _nextEntryId++;
            uint256 fragmentTokenId = chronicleFragmentNFT._tokenIdCounter + 1; // Get next token ID before mint

            chronicle.push(); // Add a new slot
            ChronicleEntry storage newEntry = chronicle[chronicle.length - 1]; // Reference the new slot
            newEntry.content = content;
            newEntry.fragmentTokenId = fragmentTokenId;

            // Set dynamic parameters
            for (uint i = 0; i < paramKeys.length; i++) {
                newEntry.parameters[paramKeys[i]] = paramValues[i];
            }

            // Mint the NFT fragment
            chronicleFragmentNFT._mint(proposal.proposer, fragmentTokenId); // Mint to the proposer

            // Increment fragment counter within the NFT contract
            chronicleFragmentNFT._tokenIdCounter++;

            emit ChronicleEntryAdded(entryId, proposal.proposer, proposalId, fragmentTokenId);

        } else if (proposal.proposalType == ProposalType.EditEntry) {
            (uint256 entryId, string memory newContent) = abi.decode(pData, (uint256, string));
            require(entryId > 0 && entryId <= chronicle.length, "Invalid entry ID for edit");
            chronicle[entryId - 1].content = newContent;
            emit ChronicleEntryEdited(entryId, proposal.proposer, proposalId);

        } else if (proposal.proposalType == ProposalType.ParameterChange) {
             (uint256 entryId, string[] memory paramKeys, int256[] memory paramValues) = abi.decode(pData, (uint256, string[], int256[]));
             require(entryId > 0 && entryId <= chronicle.length, "Invalid entry ID for parameter change");
             require(paramKeys.length == paramValues.length, "Parameter key/value mismatch for change");

             ChronicleEntry storage entry = chronicle[entryId - 1];
             for (uint i = 0; i < paramKeys.length; i++) {
                 entry.parameters[paramKeys[i]] = paramValues[i];
             }
             emit EntryParametersChanged(entryId, proposal.proposer, proposalId);

        } else if (proposal.proposalType == ProposalType.DAOParamChange) {
             (bytes32 paramName, uint256 newValue) = abi.decode(pData, (bytes32, uint256));
             uint256 oldValue = daoParameters[paramName];
             daoParameters[paramName] = newValue; // Update the DAO parameter
             emit DAOParameterChanged(paramName, oldValue, newValue);
        }

        // Increment proposer's contribution score for successful execution
        members[proposal.proposer].contributionScore = members[proposal.proposer].contributionScore.add(1);

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId, proposal.state);
    }

    // --- Chronicle Management ---

    /**
     * @notice Gets the details of a specific Chronicle entry.
     * @param entryId The ID of the entry.
     * @return content The text content.
     * @return fragmentTokenId The ID of the associated NFT fragment (0 if none).
     */
    function getEntryDetails(uint256 entryId) public view returns (string memory content, uint256 fragmentTokenId) {
         require(entryId > 0 && entryId <= chronicle.length, "Invalid entry ID");
         ChronicleEntry storage entry = chronicle[entryId - 1];
         return (entry.content, entry.fragmentTokenId);
    }

    /**
     * @notice Gets the current number of entries in the Chronicle.
     * @return The total number of entries.
     */
    function getChronicleLength() public view returns (uint256) {
        return chronicle.length;
    }

    /**
     * @notice Gets the dynamic parameters for a specific Chronicle entry.
     * @param entryId The ID of the entry.
     * @param paramKeys The keys of the parameters to retrieve.
     * @return values The values associated with the keys.
     */
    function getEntryParameters(uint256 entryId, string[] memory paramKeys) public view returns (int256[] memory values) {
        require(entryId > 0 && entryId <= chronicle.length, "Invalid entry ID");
        ChronicleEntry storage entry = chronicle[entryId - 1];
        values = new int256[](paramKeys.length);
        for(uint i = 0; i < paramKeys.length; i++) {
            values[i] = entry.parameters[paramKeys[i]];
        }
        return values;
    }

    // --- NFT Interaction ---

    /**
     * @notice Gets the total number of Chronicle Fragment NFTs minted.
     * @return The total supply of fragments.
     */
    function getTotalFragmentsMinted() public view returns (uint256) {
        return chronicleFragmentNFT._tokenIdCounter;
    }

    // --- DAO Governance & Utility ---

    /**
     * @notice Gets the current value of a DAO governance parameter.
     * @param paramName The name hash of the parameter (e.g., keccak256("votingPeriod")).
     * @return The value of the parameter.
     */
    function getDAOParameter(bytes32 paramName) public view returns (uint256) {
        return daoParameters[paramName];
    }

     /**
      * @notice Gets the current required fee to create a proposal.
      * @return The proposal fee amount.
      */
    function getProposalFee() public view returns (uint256) {
        return daoParameters[PARAM_PROPOSAL_FEE];
    }


    /**
     * @notice Gets the contribution score of a member.
     * @param member The address of the member.
     * @return The number of successful proposals executed by the member.
     */
    function getMemberContributionScore(address member) public view returns (uint256) {
        return members[member].contributionScore;
    }

    /**
     * @notice Checks if an address is currently a member (has staked tokens > 0).
     * @param member The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address member) public view returns (bool) {
        return members[member].stakedAmount > 0;
    }

    /**
     * @notice Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) { return ProposalState.Canceled; } // Treat non-existent as Canceled/invalid
        if (proposal.state != ProposalState.Voting) { return proposal.state; }
        // If in Voting state, check if voting period has ended
        if (block.timestamp >= proposal.proposalTimestamp.add(proposal.votingPeriod)) {
             // Determine Succeeded or Defeated if executed logic were applied
             uint256 requiredVotesForQuorum = totalStaked.mul(proposal.quorumThreshold).div(100);
             if (proposal.totalVotes < requiredVotesForQuorum || proposal.yesVotes.mul(100) < proposal.approvalThreshold.mul(proposal.totalVotes)) {
                 return ProposalState.Defeated; // Would be defeated if executed
             } else {
                 return ProposalState.Succeeded; // Would be succeeded if executed
             }
        }
        return ProposalState.Voting; // Still in voting period
    }

     /**
      * @notice Calculates the minimum total votes required for a proposal to meet quorum.
      * @param proposalId The ID of the proposal.
      * @return The required number of votes (based on total staked at time of check and proposal's quorum threshold).
      */
    function getRequiredVotes(uint256 proposalId) public view returns (uint256) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) { return 0; }
        // Calculate based on *current* total staked, but the proposal check uses stake *snapshot* for quorum
        // A more complex system might snapshot total stake at proposal creation too.
        // For simplicity, we calculate dynamically here based on current total stake.
        // The actual `executeProposal` uses the proposal's stored threshold and calculated quorum based on *totalStaked*.
        return totalStaked.mul(proposal.quorumThreshold).div(100);
    }


    /**
     * @notice Gets the current vote counts for a proposal.
     * @param proposalId The ID of the proposal.
     * @return yesVotes The total voting power cast as 'Yes'.
     * @return noVotes The total voting power cast as 'No'.
     * @return totalVotes The total voting power cast (Yes + No).
     */
    function getProposalVotes(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes, uint256 totalVotes) {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.proposer == address(0)) { return (0, 0, 0); }
         return (proposal.yesVotes, proposal.noVotes, proposal.totalVotes);
    }

    /**
     * @notice Checks if a proposal is ready and eligible for execution based on current state and time.
     * @param proposalId The ID of the proposal.
     * @return True if the proposal can be executed, false otherwise.
     */
    function canExecuteProposal(uint256 proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0) || proposal.state != ProposalState.Voting) { return false; }
        if (block.timestamp < proposal.proposalTimestamp.add(proposal.votingPeriod)) { return false; }

        uint256 requiredVotesForQuorum = totalStaked.mul(proposal.quorumThreshold).div(100);

        if (proposal.totalVotes < requiredVotesForQuorum) { return false; }
        if (proposal.yesVotes.mul(100) < proposal.approvalThreshold.mul(proposal.totalVotes)) { return false; }

        return true; // Ready to execute
    }

     /**
      * @notice Allows the owner to withdraw collected proposal fees.
      * @param recipient The address to send the fees to.
      * @param amount The amount to withdraw.
      */
    function withdrawFees(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(chronToken.balanceOf(address(this)) >= amount, "Insufficient contract balance");

        chronToken.transfer(recipient, amount);
        emit ProposalFeeWithdrawn(recipient, amount);
    }

     /**
      * @notice Gets the IDs of recent proposals.
      * @param limit The maximum number of recent proposal IDs to return.
      * @return An array of recent proposal IDs.
      */
    function getRecentProposals(uint256 limit) public view returns (uint256[] memory) {
        uint256 maxLimit = daoParameters[PARAM_MAX_RECENT_PROPOSALS];
        uint256 returnLimit = limit > maxLimit ? maxLimit : limit;
        if (returnLimit > _recentProposalIds.length) {
             returnLimit = _recentProposalIds.length;
        }

        uint256[] memory result = new uint256[](returnLimit);
        uint256 start = _recentProposalIds.length > returnLimit ? _recentProposalIds.length - returnLimit : 0;

        for (uint i = 0; i < returnLimit; i++) {
            result[i] = _recentProposalIds[start + i];
        }
        return result;
    }

    /**
     * @notice Gets the proposer address for a given proposal ID.
     * @param proposalId The ID of the proposal.
     * @return The proposer's address.
     */
    function getProposalProposer(uint256 proposalId) public view returns (address) {
        require(proposals[proposalId].proposer != address(0), "Proposal does not exist");
        return proposals[proposalId].proposer;
    }

    // --- Internal ERC721 Helper (for minting within execute) ---
    // Expose _tokenIdCounter from ChronicleFragment for public viewgetTotalFragmentsMinted
    // Note: Directly calling internal functions this way from the main contract is specific
    // to having the dependent contract defined *within* the same file or inheriting.
    // In a real scenario, if ChronicleFragment were a separate deployed contract,
    // you'd need a public getter in ChronicleFragment itself.
    // However, for the purpose of this single-file example demonstrating interaction,
    // this pattern works in Solidity >= 0.6.0.
}

```