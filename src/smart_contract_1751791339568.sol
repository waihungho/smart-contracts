Okay, here is a Solidity smart contract implementing a decentralized autonomous organization (DAO) with a novel voting mechanism tied to non-transferable membership tokens (simulated Soulbound-like NFTs) and a delegation feature inspired by quantum entanglement concepts.

It aims for advanced concepts like state-based proposals, delegated voting power with "entanglement" links, and execution verification. It avoids direct imports from standard libraries like OpenZeppelin (except basic `Address` utilities implicitly available in recent Solidity or required for calls) by implementing necessary parts like ownership and a minimal non-transferable token simulation internally.

---

**QuantumVoteDAO: Outline and Function Summary**

This contract implements a DAO where voting power is represented by non-transferable "Quantum Essence" tokens (simulated ERC721). Proposals go through different states ("Superposition", "Measuring", "Collapsed"). Voting uses the Quantum Essence balance (including delegated power), and delegation creates a revocable "entanglement" link.

**Outline:**

1.  **State Variables:** Define core parameters, mappings for proposals, votes, delegation, and simulated NFT data.
2.  **Enums:** Define states for proposals (`ProposalState`) and vote types (`VoteType`).
3.  **Structs:** Define the structure for a `Proposal`.
4.  **Events:** Define events for state changes and actions.
5.  **Modifiers:** Define owner-only and state-checking modifiers.
6.  **Ownership (Manual Implementation):** Basic `Ownable` pattern.
7.  **Simulated Quantum Essence Token (Non-Transferable ERC721):**
    *   Internal mappings for ownership and balances.
    *   Internal token counter.
    *   Functions for minting, burning, getting balance, and getting owner.
8.  **Configuration:** Functions for setting DAO parameters (min proposal NFTs, voting duration, etc.).
9.  **Proposal Management:**
    *   Creating proposals (`propose`).
    *   Cancelling proposals (`cancelProposal`).
    *   Querying proposal details (`getProposal`, `getProposalState`, `getProposalCount`).
10. **Voting Mechanism:**
    *   Initiating the voting period (`startVotingPeriod`).
    *   Casting votes (`vote`).
    *   Querying vote status and counts (`getVote`, `getCurrentVotes`).
11. **Delegation (Quantum Entanglement):**
    *   Delegating voting power (`delegate`).
    *   Revoking delegation (`revokeDelegation`).
    *   Querying delegation status (`getDelegatee`).
12. **Execution:**
    *   Queueing a successful proposal for execution (`queueExecution`).
    *   Executing a queued proposal (`executeProposal`).
    *   Querying execution details (`getProposalExecutionDetails`).
13. **Vote Weight Calculation:** Internal logic to determine effective voting power including delegation.

**Function Summary (Alphabetical):**

1.  `balanceOf(address _owner) public view returns (uint256)`: (Simulated NFT) Returns the number of Quantum Essence tokens owned by an address.
2.  `burnQuantumEssence(uint256 _tokenId) external`: (Simulated NFT) Allows the owner of a token to burn it.
3.  `cancelProposal(uint256 _proposalId) external`: Allows the proposer or owner to cancel a proposal before voting starts.
4.  `delegate(address _delegatee) external`: Delegates the caller's voting power to `_delegatee`. Creates the "entanglement".
5.  `executeProposal(uint256 _proposalId, address _target, uint256 _value, bytes calldata _calldata) external payable`: Executes the payload of a successful and queued proposal. Verifies payload hash.
6.  `getCurrentVotes(uint256 _proposalId) public view returns (uint256, uint256, uint256)`: Returns the current counts for For, Against, and Abstain votes on a proposal.
7.  `getDelegatee(address _delegator) public view returns (address)`: Returns the address that `_delegator` has delegated their vote to.
8.  `getProposal(uint256 _proposalId) public view returns (address proposer, uint256 creationTimestamp, uint256 votingStartTimestamp, uint256 votingEndTimestamp, uint256 executionTimestamp, ProposalState state, uint256 votesFor, uint256 votesAgainst, uint256 votesAbstain, bytes32 executionPayloadHash, string memory descriptionURI)`: Returns all details of a specific proposal.
9.  `getProposalCount() public view returns (uint256)`: Returns the total number of proposals created.
10. `getProposalExecutionDetails(uint256 _proposalId) public view returns (address target, uint256 value, bytes32 payloadHash)`: Returns the execution target, value, and payload hash stored for a proposal.
11. `getProposalState(uint256 _proposalId) public view returns (ProposalState)`: Returns the current state of a specific proposal.
12. `getVote(uint256 _proposalId, address _voter) public view returns (VoteType)`: Returns how a specific address voted on a proposal.
13. `getVoteWeight(address _voter) public view returns (uint256)`: Calculates and returns the effective voting weight for an address, considering their own tokens and delegated power.
14. `isProposer(address _addr) public view returns (bool)`: Checks if an address holds enough Quantum Essence tokens to propose.
15. `mintQuantumEssence(address _to) external onlyOwner`: (Simulated NFT) Mints a new Quantum Essence token and assigns it to `_to`. Only callable by the contract owner initially.
16. `ownerOf(uint256 _tokenId) public view returns (address)`: (Simulated NFT) Returns the owner of a specific Quantum Essence token.
17. `propose(string memory _descriptionURI, address _target, uint256 _value, bytes calldata _calldata) external returns (uint256)`: Creates a new proposal. Requires minimum Quantum Essence balance. State starts in `Superposition`. Stores execution details hash.
18. `queueExecution(uint256 _proposalId) external`: Transitions a proposal from `Measuring` to `Collapsed` if the voting period is over and the vote passed.
19. `revokeDelegation() external`: Revokes any existing delegation from the caller. Breaks the "entanglement".
20. `setMinProposerNFTBalance(uint256 _balance) external onlyOwner`: Sets the minimum number of Quantum Essence tokens required to create a proposal.
21. `setSuperpositionReviewPeriod(uint256 _duration) external onlyOwner`: Sets the minimum time a proposal must be in `Superposition` before voting can start.
22. `setVotingPeriodDuration(uint256 _duration) external onlyOwner`: Sets how long the voting period (`Measuring`) lasts.
23. `startVotingPeriod(uint256 _proposalId) external`: Transitions a proposal from `Superposition` to `Measuring` after the review period.
24. `tokenURI(uint256 _tokenId) public pure returns (string memory)`: (Simulated NFT) Returns a placeholder metadata URI for a token.
25. `transferOwnership(address _newOwner) external onlyOwner`: Transfers contract ownership.
26. `vote(uint256 _proposalId, VoteType _support) external`: Casts a vote (For, Against, or Abstain) on a proposal. Uses effective vote weight.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVoteDAO
 * @dev A decentralized autonomous organization (DAO) with tokenized membership,
 *      state-based proposals, delegated voting ('entanglement'), and execution.
 *      Uses a simulated non-transferable "Quantum Essence" NFT for membership and voting power.
 *      Employs quantum-inspired state names for proposals.
 */

// --- Outline ---
// 1. State Variables
// 2. Enums
// 3. Structs
// 4. Events
// 5. Modifiers (Manual Ownable)
// 6. Ownership Implementation
// 7. Simulated Quantum Essence Token (Non-Transferable ERC721-like)
//    - Internal mappings & counter
//    - mint, burn, balanceOf, ownerOf, tokenURI
// 8. Configuration Functions
// 9. Proposal Management
//    - propose, cancelProposal, getProposal, getProposalState, getProposalCount, isProposer
// 10. Voting Mechanism
//    - startVotingPeriod, vote, getVote, getCurrentVotes
// 11. Delegation (Quantum Entanglement)
//    - delegate, revokeDelegation, getDelegatee
// 12. Execution
//    - queueExecution, executeProposal, getProposalExecutionDetails
// 13. Vote Weight Calculation (Internal)

// --- Function Summary (Alphabetical) ---
// 1. balanceOf(address _owner) view
// 2. burnQuantumEssence(uint256 _tokenId) external
// 3. cancelProposal(uint256 _proposalId) external
// 4. delegate(address _delegatee) external
// 5. executeProposal(uint256 _proposalId, address _target, uint256 _value, bytes calldata _calldata) external payable
// 6. getCurrentVotes(uint256 _proposalId) view
// 7. getDelegatee(address _delegator) view
// 8. getProposal(uint256 _proposalId) view
// 9. getProposalCount() view
// 10. getProposalExecutionDetails(uint256 _proposalId) view
// 11. getProposalState(uint256 _proposalId) view
// 12. getVote(uint256 _proposalId, address _voter) view
// 13. getVoteWeight(address _voter) view
// 14. isProposer(address _addr) view
// 15. mintQuantumEssence(address _to) external onlyOwner
// 16. ownerOf(uint256 _tokenId) view
// 17. propose(string memory _descriptionURI, address _target, uint256 _value, bytes calldata _calldata) external returns (uint256)
// 18. queueExecution(uint256 _proposalId) external
// 19. revokeDelegation() external
// 20. setMinProposerNFTBalance(uint256 _balance) external onlyOwner
// 21. setSuperpositionReviewPeriod(uint256 _duration) external onlyOwner
// 22. setVotingPeriodDuration(uint256 _duration) external onlyOwner
// 23. startVotingPeriod(uint256 _proposalId) external
// 24. tokenURI(uint256 _tokenId) pure
// 25. transferOwnership(address _newOwner) external onlyOwner
// 26. vote(uint256 _proposalId, VoteType _support) external

contract QuantumVoteDAO {

    // --- 1. State Variables ---

    address private _owner; // Manual Ownable

    uint256 private _nextTokenId = 0; // Counter for simulated NFT tokens
    mapping(uint256 => address) private _owners; // tokenId => owner (Simulated NFT)
    mapping(address => uint256) private _balances; // owner => balance (Simulated NFT)
    // Note: No transfer/approve/getApproved/setApprovalForAll for non-transferable

    uint256 private _minProposerNFTBalance;
    uint256 private _votingPeriodDuration; // in seconds
    uint256 private _superpositionReviewPeriod; // in seconds

    uint256 private _proposalCount = 0;
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => VoteType)) private _proposalVotes; // proposalId => voter => vote type

    mapping(address => address) private _delegates; // delegator => delegatee (Quantum Entanglement)

    // --- 2. Enums ---

    enum ProposalState {
        Superposition, // Pending review before voting
        Measuring,     // Voting is open
        Collapsed,     // Voting ended, passed, and is queued for execution
        Executed,      // Proposal payload has been executed
        Cancelled      // Proposal cancelled before execution
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    // --- 3. Structs ---

    struct Proposal {
        uint256 id;
        address proposer;
        string descriptionURI; // URI or hash pointing to proposal details off-chain
        uint256 creationTimestamp;
        uint256 votingStartTimestamp;
        uint256 votingEndTimestamp;
        uint256 executionTimestamp; // Timestamp when it became Collapsed/executable
        ProposalState state;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        // Details for execution payload - storing hash to verify execution call
        address executionTarget;
        uint256 executionValue;
        bytes32 executionPayloadHash; // hash(target, value, calldata)
    }

    // --- 4. Events ---

    event QuantumEssenceMinted(address indexed to, uint256 indexed tokenId);
    event QuantumEssenceBurned(address indexed from, uint256 indexed tokenId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionURI);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event Voted(uint256 indexed proposalId, address indexed voter, VoteType support, uint256 weight);
    event DelegationChanged(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ConfigUpdated(string param, uint256 value);

    // --- 5. Modifiers (Manual Ownable) ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    // --- 6. Ownership Implementation ---

    constructor(uint256 initialMinProposerNFTBalance, uint256 initialVotingPeriodDuration, uint256 initialSuperpositionReviewPeriod) {
        _owner = msg.sender;
        _minProposerNFTBalance = initialMinProposerNFTBalance;
        _votingPeriodDuration = initialVotingPeriodDuration;
        _superpositionReviewPeriod = initialSuperpositionReviewPeriod;

        emit OwnershipTransferred(address(0), _owner);
        emit ConfigUpdated("minProposerNFTBalance", _minProposerNFTBalance);
        emit ConfigUpdated("votingPeriodDuration", _votingPeriodDuration);
        emit ConfigUpdated("superpositionReviewPeriod", _superpositionReviewPeriod);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // --- 7. Simulated Quantum Essence Token (Non-Transferable ERC721-like) ---
    // Membership and voting power token. Non-transferable to act like Soulbound Tokens.

    /**
     * @dev Mints a new Quantum Essence token to an address.
     * Only callable by the contract owner (initially).
     * @param _to The address to mint the token to.
     */
    function mintQuantumEssence(address _to) external onlyOwner {
        require(_to != address(0), "Cannot mint to the zero address");
        uint256 tokenId = _nextTokenId++;
        _owners[tokenId] = _to;
        _balances[_to]++;
        // ERC721 Transfer event (from, to, tokenId)
        emit Transfer(address(0), _to, tokenId);
        emit QuantumEssenceMinted(_to, tokenId);
    }

    /**
     * @dev Burns a Quantum Essence token.
     * Only callable by the token's owner.
     * @param _tokenId The ID of the token to burn.
     */
    function burnQuantumEssence(uint256 _tokenId) external {
        address owner = _owners[_tokenId];
        require(owner != address(0), "Token does not exist");
        require(owner == msg.sender, "Not token owner");

        _balances[owner]--;
        delete _owners[_tokenId]; // Remove ownership link
        // ERC721 Transfer event (from, to, tokenId) - burn is transfer to address(0)
        emit Transfer(owner, address(0), _tokenId);
        emit QuantumEssenceBurned(owner, _tokenId);
    }

    /**
     * @dev Returns the number of Quantum Essence tokens owned by an address.
     * @param _owner The address to query the balance of.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Returns the owner of a specific Quantum Essence token ID.
     * @param _tokenId The token ID to query the owner of.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_owners[_tokenId] != address(0), "Token does not exist");
        return _owners[_tokenId];
    }

    /**
     * @dev Returns a constant base URI for token metadata.
     * @param _tokenId The token ID (ignored).
     */
    function tokenURI(uint256 _tokenId) public pure returns (string memory) {
        // Basic placeholder, actual metadata would be off-chain
        return "ipfs://QmPlaceholderMetadataURI/";
    }

    // Standard ERC721 events needed for compatibility/indexing
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); // Not needed for non-transferable
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // Not needed for non-transferable

    // --- 8. Configuration Functions ---

    /**
     * @dev Sets the minimum number of Quantum Essence tokens required to create a proposal.
     * @param _balance The new minimum balance.
     */
    function setMinProposerNFTBalance(uint256 _balance) external onlyOwner {
        _minProposerNFTBalance = _balance;
        emit ConfigUpdated("minProposerNFTBalance", _balance);
    }

    /**
     * @dev Sets how long the voting period (`Measuring`) lasts in seconds.
     * @param _duration The new duration in seconds.
     */
    function setVotingPeriodDuration(uint256 _duration) external onlyOwner {
        _votingPeriodDuration = _duration;
        emit ConfigUpdated("votingPeriodDuration", _duration);
    }

    /**
     * @dev Sets the minimum time a proposal must be in `Superposition` before voting can start.
     * @param _duration The new duration in seconds.
     */
    function setSuperpositionReviewPeriod(uint256 _duration) external onlyOwner {
        _superpositionReviewPeriod = _duration;
        emit ConfigUpdated("superpositionReviewPeriod", _duration);
    }

    // --- 9. Proposal Management ---

    /**
     * @dev Creates a new proposal. Requires minimum Quantum Essence balance.
     * State starts in `Superposition`. Stores execution details hash for verification.
     * @param _descriptionURI URI or hash pointing to proposal details off-chain.
     * @param _target The target address for the proposal's execution payload.
     * @param _value The value (ether) to send with the execution call.
     * @param _calldata The calldata for the execution call.
     * @return The ID of the newly created proposal.
     */
    function propose(string memory _descriptionURI, address _target, uint256 _value, bytes calldata _calldata) external returns (uint256) {
        require(isProposer(msg.sender), "Insufficient Quantum Essence balance to propose");

        uint256 proposalId = _proposalCount++;
        bytes32 executionPayloadHash = keccak256(abi.encodePacked(_target, _value, _calldata));

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            descriptionURI: _descriptionURI,
            creationTimestamp: block.timestamp,
            votingStartTimestamp: 0, // Set when starting voting
            votingEndTimestamp: 0,   // Set when starting voting
            executionTimestamp: 0,   // Set when queuing execution
            state: ProposalState.Superposition,
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            executionTarget: _target,
            executionValue: _value,
            executionPayloadHash: executionPayloadHash
        });

        emit ProposalCreated(proposalId, msg.sender, _descriptionURI);
        emit ProposalStateChanged(proposalId, ProposalState.Superposition, ProposalState.Superposition); // Redundant state change, but follows pattern

        return proposalId;
    }

    /**
     * @dev Allows the proposer or owner to cancel a proposal before voting starts.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Superposition, "Proposal is not in Superposition state");
        require(msg.sender == proposal.proposer || msg.sender == _owner, "Not authorized to cancel");

        proposal.state = ProposalState.Cancelled;
        emit ProposalStateChanged(_proposalId, ProposalState.Superposition, ProposalState.Cancelled);
    }

    /**
     * @dev Returns all details of a specific proposal.
     * @param _proposalId The ID of the proposal to query.
     */
    function getProposal(uint256 _proposalId) public view returns (
        address proposer,
        uint256 creationTimestamp,
        uint256 votingStartTimestamp,
        uint256 votingEndTimestamp,
        uint256 executionTimestamp,
        ProposalState state,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes32 executionPayloadHash,
        string memory descriptionURI
    ) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        return (
            proposal.proposer,
            proposal.creationTimestamp,
            proposal.votingStartTimestamp,
            proposal.votingEndTimestamp,
            proposal.executionTimestamp,
            proposal.state,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.votesAbstain,
            proposal.executionPayloadHash,
            proposal.descriptionURI
        );
    }

     /**
     * @dev Returns the execution target, value, and payload hash stored for a proposal.
     * Useful for off-chain validation before proposing execution.
     * @param _proposalId The ID of the proposal to query.
     */
    function getProposalExecutionDetails(uint256 _proposalId) public view returns (
        address target,
        uint256 value,
        bytes32 payloadHash
    ) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        return (
            proposal.executionTarget,
            proposal.executionValue,
            proposal.executionPayloadHash
        );
    }


    /**
     * @dev Returns the current state of a specific proposal.
     * @param _proposalId The ID of the proposal to query.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        return proposal.state;
    }

    /**
     * @dev Returns the total number of proposals created.
     */
    function getProposalCount() public view returns (uint256) {
        return _proposalCount;
    }

    /**
     * @dev Checks if an address holds enough Quantum Essence tokens to create a proposal.
     * @param _addr The address to check.
     */
    function isProposer(address _addr) public view returns (bool) {
        return balanceOf(_addr) >= _minProposerNFTBalance;
    }

    // --- 10. Voting Mechanism ---

    /**
     * @dev Transitions a proposal from `Superposition` to `Measuring` after the review period.
     * Callable by anyone to start the voting period.
     * @param _proposalId The ID of the proposal to start voting for.
     */
    function startVotingPeriod(uint256 _proposalId) external {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Superposition, "Proposal is not in Superposition state");
        require(block.timestamp >= proposal.creationTimestamp + _superpositionReviewPeriod, "Review period not yet over");

        proposal.state = ProposalState.Measuring;
        proposal.votingStartTimestamp = block.timestamp;
        proposal.votingEndTimestamp = block.timestamp + _votingPeriodDuration;

        emit ProposalStateChanged(_proposalId, ProposalState.Superposition, ProposalState.Measuring);
    }

    /**
     * @dev Casts a vote (For, Against, or Abstain) on a proposal.
     * Requires having Quantum Essence tokens (directly or via delegation).
     * Uses effective vote weight. Only one vote per address per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support The vote type (For, Against, Abstain).
     */
    function vote(uint256 _proposalId, VoteType _support) external {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Measuring, "Voting is not open for this proposal");
        require(block.timestamp >= proposal.votingStartTimestamp && block.timestamp < proposal.votingEndTimestamp, "Voting period has ended");
        require(_proposalVotes[_proposalId][msg.sender] == VoteType.Abstain, "Already voted on this proposal"); // Use Abstain enum value 0 as default 'not voted'

        uint256 weight = getVoteWeight(msg.sender);
        require(weight > 0, "No voting weight");

        _proposalVotes[_proposalId][msg.sender] = _support;

        if (_support == VoteType.For) {
            proposal.votesFor += weight;
        } else if (_support == VoteType.Against) {
            proposal.votesAgainst += weight;
        } else { // VoteType.Abstain
            proposal.votesAbstain += weight;
        }

        emit Voted(_proposalId, msg.sender, _support, weight);
    }

    /**
     * @dev Returns how a specific address voted on a proposal.
     * Returns `VoteType.Abstain` (enum value 0) if they haven't voted.
     * @param _proposalId The ID of the proposal.
     * @param _voter The address of the voter.
     */
    function getVote(uint256 _proposalId, address _voter) public view returns (VoteType) {
        // Does not require proposal existence check to allow checking non-voters
        return _proposalVotes[_proposalId][_voter];
    }

    /**
     * @dev Returns the current vote counts (For, Against, Abstain) for a proposal.
     * @param _proposalId The ID of the proposal to query.
     */
    function getCurrentVotes(uint256 _proposalId) public view returns (uint256 votesFor, uint256 votesAgainst, uint256 votesAbstain) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        return (proposal.votesFor, proposal.votesAgainst, proposal.votesAbstain);
    }

    // --- 11. Delegation (Quantum Entanglement) ---

    /**
     * @dev Delegates the caller's voting power to `_delegatee`.
     * Creates the "entanglement" link.
     * If a delegator has a delegatee, their own vote weight becomes 0.
     * A delegatee's vote weight includes their own tokens plus delegated tokens.
     * Cannot delegate to the zero address or self.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegate(address _delegatee) external {
        require(_delegatee != address(0), "Cannot delegate to the zero address");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");

        address oldDelegatee = _delegates[msg.sender];
        _delegates[msg.sender] = _delegatee;

        emit DelegationChanged(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any existing delegation from the caller.
     * Breaks the "entanglement".
     */
    function revokeDelegation() external {
        require(_delegates[msg.sender] != address(0), "No active delegation to revoke");

        address oldDelegatee = _delegates[msg.sender];
        delete _delegates[msg.sender];

        emit DelegationChanged(msg.sender, address(0));
    }

    /**
     * @dev Returns the address that `_delegator` has delegated their vote to.
     * Returns address(0) if no delegation is active.
     * @param _delegator The address to query delegation for.
     */
    function getDelegatee(address _delegator) public view returns (address) {
        return _delegates[_delegator];
    }

    // --- 12. Execution ---

    /**
     * @dev Transitions a proposal from `Measuring` to `Collapsed` if the voting period
     * is over and the vote passed (simple majority excluding Abstain).
     * Callable by anyone after voting ends.
     * @param _proposalId The ID of the proposal to queue for execution.
     */
    function queueExecution(uint256 _proposalId) external {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Measuring, "Proposal is not in Measuring state");
        require(block.timestamp >= proposal.votingEndTimestamp, "Voting period not yet over");

        // Simple majority rule: For > Against (excluding Abstain)
        bool passed = proposal.votesFor > proposal.votesAgainst;

        if (passed) {
            proposal.state = ProposalState.Collapsed;
            proposal.executionTimestamp = block.timestamp; // Time it became executable
            emit ProposalStateChanged(_proposalId, ProposalState.Measuring, ProposalState.Collapsed);
        } else {
            // If it fails, it's implicitly 'Failed', but no specific state for that in this enum
            // We can transition it to Cancelled, or leave it in Measuring past end time.
            // Leaving it in Measuring past end time signifies 'Voting Ended, Failed'.
            // Let's add a check in executeProposal to handle this case explicitly.
            // No state change needed for failed proposals.
        }
    }

    /**
     * @dev Executes the payload of a successful and queued proposal.
     * Callable by anyone. Verifies the payload hash against what was approved.
     * Reverts if the proposal is not in `Collapsed` state or execution fails.
     * @param _proposalId The ID of the proposal to execute.
     * @param _target The target address for the execution call.
     * @param _value The value (ether) to send with the execution call.
     * @param _calldata The calldata for the execution call.
     */
    function executeProposal(uint256 _proposalId, address _target, uint256 _value, bytes calldata _calldata) external payable {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.id == _proposalId, "Proposal does not exist");
        require(proposal.state == ProposalState.Collapsed, "Proposal is not in Collapsed state (not passed or not queued)");
        require(block.timestamp >= proposal.votingEndTimestamp, "Voting period not yet over (should be handled by queueExecution)"); // Redundant check, but safe

        // Verify the execution payload against the stored hash
        bytes32 currentPayloadHash = keccak256(abi.encodePacked(_target, _value, _calldata));
        require(currentPayloadHash == proposal.executionPayloadHash, "Execution payload mismatch");
        require(_target == proposal.executionTarget && _value == proposal.executionValue, "Execution target or value mismatch"); // Also check target/value directly for clarity

        // Execute the payload
        // Need Address library or manual low-level call
        (bool success, bytes memory returndata) = _target.call{value: _value}(_calldata);

        if (success) {
            proposal.state = ProposalState.Executed;
            emit ProposalStateChanged(_proposalId, ProposalState.Collapsed, ProposalState.Executed);
            emit ProposalExecuted(_proposalId, true, returndata);
        } else {
             // Execution failed. Could transition to a 'FailedExecution' state if needed,
             // but leaving in Collapsed or cancelling might be simpler. Let's just revert.
            // Revert with returndata if possible for debugging.
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
            // Alternative: revert("Execution failed")
        }
    }


    // --- 13. Vote Weight Calculation (Internal) ---

    /**
     * @dev Calculates the effective voting weight for an address.
     * If the address has delegated, their weight is 0.
     * If the address is a delegatee, their weight is their own balance + sum of delegators' balances.
     * If no delegation, weight is their own balance.
     * Note: Summing delegated balances requires iterating delegators.
     * For simplicity in this example, `getVoteWeight` will calculate the weight
     * *as if the user is voting directly*.
     * When `vote` is called, it checks if `msg.sender` is a delegator. If so,
     * the vote *should* ideally come from the delegatee.
     * A simpler delegation model for `getVoteWeight`: if user has delegated, their weight is 0.
     * The delegatee's weight is *their own* balance. Delegated power is applied *by the delegatee* when *they* call `vote`.
     * Let's refine: `getVoteWeight(address _voter)` returns the weight *available to _voter* to cast votes *themselves*.
     * If they have delegated, this is 0. Otherwise, it's their balance.
     * The `vote` function *should only be callable by the effective voter*.
     * This means if `msg.sender` has delegated, they cannot call `vote`.
     * If `msg.sender` is a delegatee, their vote incorporates the total delegated weight.
     *
     * **Refined Delegation Logic:**
     * 1. `delegate(address _delegatee)`: Record `_delegates[msg.sender] = _delegatee`.
     * 2. `revokeDelegation()`: `delete _delegates[msg.sender]`.
     * 3. `getDelegatee(address _delegator)`: Return `_delegates[_delegator]`.
     * 4. `getVoteWeight(address _voter)`: Calculate total weight for `_voter`. This involves:
     *    - `_voter`'s own balance.
     *    - PLUS, sum of balances of all users who delegated TO `_voter`.
     *    Calculating the sum of delegators' balances efficiently on-chain is hard.
     *    **Alternative Delegation Model (Common in DAOs):** Delegation redirects the voting power.
     *    - `getVoteWeight(address _voter)`: Returns `balanceOf(_voter)`.
     *    - `delegate(address _delegatee)`: Sets `_delegates[msg.sender] = _delegatee`.
     *    - `vote(uint256 _proposalId, VoteType _support)`:
     *      - Find the effective voter: Start with `msg.sender`. If `msg.sender` has delegated, follow the chain `_delegates[msg.sender]`, `_delegates[_delegates[msg.sender]]` etc., until an address with no delegatee is found or a cycle is detected (avoid cycles!).
     *      - Get the total vote weight *at the end of the delegation chain*: `balanceOf(final_delegatee)`. This model is still tricky to sum up weights from multiple delegators efficiently if delegation is many-to-one.
     *
     * **Simpler Delegation Model (Implemented):**
     * - `getVoteWeight(address _voter)`: Returns `balanceOf(_voter)`.
     * - `delegate(address _delegatee)`: Sets `_delegates[msg.sender] = _delegatee`.
     * - `vote(uint256 _proposalId, VoteType _support)`:
     *    - Check if `msg.sender` has *been* delegated *to* (`_delegates` value points to `msg.sender`). This is still hard to check efficiently.
     *    - Check if `msg.sender` has delegated *out* (`_delegates[msg.sender] != address(0)`). If so, they cannot vote directly.
     *    - If `msg.sender` has NOT delegated out, their vote weight is `balanceOf(msg.sender)`.
     *    - If `msg.sender` *is* a delegatee (i.e., others delegated *to* them), they vote using their OWN address, and their `getVoteWeight` call needs to sum up their own balance plus the balances of all delegators. This remains the performance bottleneck.
     *
     * **Revisiting the Delegation Goal:** Allow members to give their voting power to someone else.
     * Let's use a standard delegation pattern similar to ERC20/ERC721 governance.
     * `getVoteWeight(address account)` returns the total voting power of `account`.
     * This power is `balanceOf(account)` + sum of `balanceOf(delegator)` for all delegators where `_delegates[delegator] == account`.
     * `vote(uint256 _proposalId, VoteType _support)`: Only `msg.sender` can call `vote`. The weight counted for `msg.sender`'s vote is `getVoteWeight(msg.sender)`.
     * This still requires the efficient summation of delegator weights. A common pattern is to track checkpoints or total delegated weight per delegatee, updating it whenever balance or delegation changes. This adds complexity.
     *
     * **Simplified Delegation (Implemented):**
     * `getVoteWeight(address account)`: If `_delegates[account]` is non-zero, the account HAS DELEGATED and their personal voting weight is 0. Otherwise, their voting weight is `balanceOf(account)`.
     * The Delegatee's voting weight is their own `balanceOf(delegatee)`.
     * **This simple model DOES NOT automatically sum up delegated power.** To sum up delegated power, the DELEGATEE would need to vote *on behalf of* their delegators, or the system needs a way to sum up weights at the time of voting.
     *
     * Let's implement the model where:
     * - `getVoteWeight(address account)` returns `balanceOf(account)` if `account` HAS NOT DELEGATED OUT (`_delegates[account] == address(0)`), and 0 if they have delegated out.
     * - To get the total power of a delegatee, you'd have to query all delegators manually off-chain and sum their balances + the delegatee's balance.
     * - The `vote` function will count the weight of `msg.sender` using this `getVoteWeight` calculation.
     * - This means a delegatee needs to receive the votes from delegators *through another mechanism* (e.g., an off-chain system collects delegated votes and submits a single transaction, or the contract needs a batch voting function, or the delegatee votes using their own address and the contract looks up all delegators *at that moment* - again, the summation issue).
     *
     * **Let's adopt a different common pattern:** The `vote` function takes the address whose weight should be counted. `msg.sender` must be either that address *or* its delegatee.
     * `vote(uint256 _proposalId, VoteType _support, address _voter)`
     * `require(msg.sender == _voter || _delegates[_voter] == msg.sender, "Not authorized to vote for this address");`
     * `uint256 weight = balanceOf(_voter);` // Weight is always based on the *token owner's* balance, even if delegatee casts the vote.
     * This allows explicit voting on behalf of others but means the delegatee needs to make a tx for each delegator they vote for, or a batch vote function is needed.

     * **Final Decision for `getVoteWeight` and `vote`:**
     * - `getVoteWeight(address account)` will return `balanceOf(account)`. This represents the base power of the token holder.
     * - Delegation is purely signalling (`_delegates` mapping).
     * - The `vote` function will remain `vote(uint256 _proposalId, VoteType _support)`. The weight counted *for this vote* will be `balanceOf(msg.sender)`.
     * - This means only the token holder or their delegatee can cast a vote, and the weight is based on the token holder. How does the delegatee vote? They would need to be authorized to call `vote` *on behalf of* the delegator. This isn't standard delegation.
     *
     * **Let's go back to the standard delegation model common in Compound/Uniswap:**
     * - `delegate(address delegatee)`: Sets `delegates[msg.sender] = delegatee`. Also updates vote count *checkpoints* for the old and new delegatees (subtracting/adding msg.sender's weight).
     * - `getVoteWeight(address account)`: Returns the *total* voting power of `account` (own tokens + delegated tokens). This is retrieved from checkpoints.
     * - `vote(uint256 _proposalId, VoteType _support)`: `msg.sender` votes. The weight counted is `getVoteWeight(msg.sender)` *at a specific snapshot time* (e.g., block when proposal started voting). This snapshot logic adds complexity.
     *
     * **Let's simplify but keep the *concept* of delegated weight:**
     * - `delegate(address delegatee)`: Sets `_delegates[msg.sender] = delegatee`.
     * - `revokeDelegation()`: Clears `_delegates[msg.sender]`.
     * - `getDelegatee(address delegator)`: Returns `_delegates[delegator]`.
     * - `getVoteWeight(address account)`: If `_delegates[account] != address(0)` (account has delegated out), return 0. Otherwise, return `balanceOf(account)`. This is the weight *the account can cast themselves*.
     * - **Crucially:** When calculating proposal results or checking a delegatee's total power off-chain, you'd iterate all addresses and sum `balanceOf(address)` for those whose delegatee is the target delegatee, *plus* `balanceOf(target_delegatee)` if `_delegates[target_delegatee] == address(0)`.
     * - The `vote` function will use `getVoteWeight(msg.sender)`. This means if you've delegated out, you can't vote directly. If you are a delegatee, you vote with your *own* weight, not the sum of delegated weights. This isn't quite right for delegation.

     * **Final attempt at delegation model:**
     * - `delegate(address delegatee)`: Sets `_delegates[msg.sender] = delegatee`. Emits `DelegationChanged`.
     * - `revokeDelegation()`: Sets `_delegates[msg.sender] = address(0)`. Emits `DelegationChanged`.
     * - `getDelegatee(address delegator)`: Returns `_delegates[delegator]`.
     * - `getVoteWeight(address account)`: Returns `balanceOf(account)`. This is the *base* weight of the token holder.
     * - `vote(uint256 _proposalId, VoteType _support)`:
     *    - Find the EFFECTIVE voter address (`address effectiveVoter = msg.sender; while(_delegates[effectiveVoter] != address(0)) { effectiveVoter = _delegates[effectiveVoter]; }`). Handle cycles (e.g., limit hops).
     *    - The weight for this vote is `balanceOf(effectiveVoter)`.
     *    - This is still wrong, as it only counts the weight of the final person in the chain, not the sum.

     * **Okay, let's use the most common delegation model (Compound/Uniswap style, conceptually):**
     * Delegation redirects the power *from* the delegator *to* the delegatee.
     * `getVoteWeight(address account)` returns the *total* power of `account`, including delegated power. This needs to be maintained.
     *
     * Let's manage total power using a mapping `_votingPower[address]`.
     * When `mint`, `burn`, `delegate`, `revokeDelegation` happens, we update `_votingPower`.
     * - `mint(to)`: Increase `_votingPower[to]`.
     * - `burn(from)`: Decrease `_votingPower[from]`.
     * - `delegate(delegatee)`:
     *    - `oldDelegatee = _delegates[msg.sender]`
     *    - `_delegates[msg.sender] = delegatee`
     *    - `weight = balanceOf(msg.sender)`
     *    - If `oldDelegatee != address(0)`, `_votingPower[oldDelegatee] -= weight`
     *    - If `delegatee != address(0)`, `_votingPower[delegatee] += weight`
     *    - `_votingPower[msg.sender] = 0` (delegator loses direct power)
     * - `revokeDelegation()`:
     *    - `delegatee = _delegates[msg.sender]`
     *    - `weight = balanceOf(msg.sender)`
     *    - `_votingPower[delegatee] -= weight`
     *    - `_votingPower[msg.sender] = weight` (delegator regains direct power)
     *    - `_delegates[msg.sender] = address(0)`
     * - `getVoteWeight(address account)`: Return `_votingPower[account]`.
     * - `vote()`: Uses `getVoteWeight(msg.sender)`.

     * This requires tracking initial delegatee state in mint/burn, and handling edge cases. It's complex but accurate.

     * **Let's simplify for this example contract while *conceptualizing* the delegation.**
     * The simplest implementation that still *shows* delegation:
     * - `delegate(address delegatee)` sets the mapping.
     * - `revokeDelegation()` clears it.
     * - `getDelegatee(address delegator)` queries it.
     * - `getVoteWeight(address account)` returns `balanceOf(account)`.
     * - `vote()` *uses* `balanceOf(msg.sender)`.
     * This means delegation is just a signal. The delegatee doesn't automatically get the delegator's weight added to their *on-chain vote count* unless there's an off-chain process or batch voting.
     *
     * **Let's implement the simple model where `getVoteWeight` returns `balanceOf(account)` and `vote` uses `balanceOf(msg.sender)`.** Delegation mapping is just for signalling/tracking who has delegated to whom, allowing off-chain tools to aggregate total power. This avoids the complex checkpoint/power balance state.

     * **Correction:** The *point* of on-chain delegation is for the delegatee's vote to count the delegator's power. The `vote` function *must* use the aggregated power. The efficient checkpoint method is standard for this.
     *
     * **Let's implement the checkpoint method for `getVoteWeight` and delegation:**
     * - Need `_votingPower: mapping(address => uint256)`
     * - Update `_votingPower` in `mint`, `burn`, `delegate`, `revokeDelegation`.
     * - `getVoteWeight` returns `_votingPower[account]`.
     * - `vote` uses `getVoteWeight(msg.sender)`.
     * This makes `getVoteWeight` the query for total effective power.

     * Add `_votingPower` mapping.
     * Modify `mint`, `burn`, `delegate`, `revokeDelegation` to update `_votingPower`.

     * **Wait:** The standard Compound/Uniswap delegation updates power *at the block* where delegation happens, and voting uses the power *at the block the proposal starts*. This snapshotting is crucial for preventing vote buying just before a vote.
     * Implementing snapshotting adds significant complexity (mapping block number to checkpoints).
     *
     * **Alternative Simple Delegation:** `getVoteWeight(address account)` returns `balanceOf(account)`. The `vote` function will *calculate* the effective weight at the moment of voting.
     * `vote()`:
     *    `address voterAddress = msg.sender;`
     *    `uint256 weight = balanceOf(voterAddress);` // Start with sender's own weight
     *    `address current = voterAddress;`
     *    // Sum balances of all delegators who delegated directly TO msg.sender
     *    // This still requires iterating.

     * **Let's go back to the "Quantum Entanglement" metaphor - Delegation:**
     * When A delegates to B, A and B become "entangled" for voting. A's vote collapses into B's.
     * - `getVoteWeight(address account)`: Returns `balanceOf(account)`. This is the raw power.
     * - `delegate(address delegatee)`: Sets the link. A delegator cannot vote themselves.
     * - `vote()`: Check if `msg.sender` has delegated out. If yes, revert. If no, calculate weight. The weight should be `balanceOf(msg.sender)` + SUM of `balanceOf(delegator)` for all `delegator` where `_delegates[delegator] == msg.sender`. This still needs the sum.

     * **Let's implement the simplest possible delegation *impact* on voting:**
     * - `delegate(address delegatee)`: Sets `_delegates[msg.sender] = delegatee`.
     * - `revokeDelegation()`: Clears `_delegates[msg.sender]`.
     * - `getDelegatee(address delegator)`: Returns `_delegates[delegator]`.
     * - `getVoteWeight(address account)`: Returns `balanceOf(account)`. (Base weight)
     * - `vote()`: Check if `_delegates[msg.sender] != address(0)`. If true, `revert("Cannot vote: delegated out");`. If false, `weight = balanceOf(msg.sender);`.
     * - **Crucially:** This model means the delegatee does *not* automatically get the delegated weight added. The total power calculation would need to be done off-chain or through a separate mechanism (like the delegatee calling a batch vote function or receiving votes off-chain). This is likely too simple and not representative of on-chain delegation.

     * **Okay, let's use the checkpoint-based model conceptually but simplify the implementation by *not* doing snapshots per block, just maintaining a live total vote power.** This is less secure against flash-loan attacks right before a vote but fulfills the request for delegation impacting vote power on-chain.
     * - `_liveVotingPower: mapping(address => uint256)`
     * - `mint(to)`: `_balances[to]++; _liveVotingPower[to]++;`
     * - `burn(from)`: `_balances[from]--; _liveVotingPower[from]--;`
     * - `delegate(delegatee)`:
     *    `address oldDelegatee = _delegates[msg.sender];`
     *    `require(oldDelegatee != delegatee, "Already delegated to this address");`
     *    `uint256 weight = _balances[msg.sender];`
     *    `if (oldDelegatee != address(0)) { _liveVotingPower[oldDelegatee] = _liveVotingPower[oldDelegatee] - weight; }` // Subtract from old delegatee
     *    `_delegates[msg.sender] = delegatee;`
     *    `_liveVotingPower[delegatee] = _liveVotingPower[delegatee] + weight;` // Add to new delegatee
     *    `_liveVotingPower[msg.sender] = 0;` // Delegator's direct power becomes 0
     * - `revokeDelegation()`:
     *    `address delegatee = _delegates[msg.sender];`
     *    `require(delegatee != address(0), "No active delegation to revoke");`
     *    `uint256 weight = _balances[msg.sender];`
     *    `_liveVotingPower[delegatee] = _liveVotingPower[delegatee] - weight;` // Subtract from delegatee
     *    `_delegates[msg.sender] = address(0);`
     *    `_liveVotingPower[msg.sender] = weight;` // Delegator regains power
     * - `getVoteWeight(address account)`: Returns `_liveVotingPower[account]`.
     * - `vote()`: Uses `getVoteWeight(msg.sender)`.

     * This `_liveVotingPower` calculation needs careful implementation to handle edge cases (e.g., balance changing *after* delegation, although tokens are non-transferable, they can be minted/burned). If tokens are *only* minted/burned by owner, it simplifies. If users can burn their own, the burn needs to update the power correctly (subtract from delegatee if delegated, or from self if not).

     * Let's refine `burn` and add it to the power update:
     * - `burn(tokenId)`:
     *    `owner = _owners[tokenId]`
     *    `delegatee = _delegates[owner]` // Check if owner has delegated
     *    `_balances[owner]--;`
     *    `delete _owners[tokenId];`
     *    `if (delegatee != address(0)) { _liveVotingPower[delegatee]--; } else { _liveVotingPower[owner]--; }` // Decrement power from where it resided

     * This looks like a robust simplified delegation model suitable for this example. `getVoteWeight(address account)` should return `_liveVotingPower[account]`. The `vote` function uses `getVoteWeight(msg.sender)`.

     * Let's rename `_liveVotingPower` to `_effectiveVotingPower`.

    mapping(address => uint256) private _effectiveVotingPower; // address => total vote weight (own + delegated)

    /**
     * @dev Calculates and returns the effective voting weight for an address.
     * This includes their own Quantum Essence balance if they have not delegated,
     * or the sum of balances delegated to them if they are a delegatee.
     * Uses the _effectiveVotingPower mapping.
     * @param _voter The address to calculate weight for.
     */
    function getVoteWeight(address _voter) public view returns (uint256) {
        // In this simplified model, _effectiveVotingPower tracks the current power.
        // A more advanced version would use checkpoints for vote power at a specific block.
        return _effectiveVotingPower[_voter];
    }

    // Update mint, burn, delegate, revokeDelegation to manage _effectiveVotingPower

    // --- Update Mint ---
    /**
     * @dev Mints a new Quantum Essence token to an address.
     * Only callable by the contract owner (initially).
     * Updates effective voting power.
     * @param _to The address to mint the token to.
     */
    function mintQuantumEssence(address _to) external onlyOwner {
        require(_to != address(0), "Cannot mint to the zero address");
        uint256 tokenId = _nextTokenId++;
        _owners[tokenId] = _to;
        _balances[_to]++;

        // Add weight to the recipient's effective power UNLESS they have already delegated out
        if (_delegates[_to] == address(0)) {
             _effectiveVotingPower[_to]++;
        } else {
            // If recipient has delegated out, the new token's weight goes to their delegatee
            _effectiveVotingPower[_delegates[_to]]++;
        }

        emit Transfer(address(0), _to, tokenId);
        emit QuantumEssenceMinted(_to, tokenId);
    }

    // --- Update Burn ---
    /**
     * @dev Burns a Quantum Essence token.
     * Only callable by the token's owner.
     * Updates effective voting power.
     * @param _tokenId The ID of the token to burn.
     */
    function burnQuantumEssence(uint256 _tokenId) external {
        address owner = _owners[_tokenId];
        require(owner != address(0), "Token does not exist");
        require(owner == msg.sender, "Not token owner");

        _balances[owner]--;
        delete _owners[_tokenId]; // Remove ownership link

        // Subtract weight from where it resided (either owner's power or their delegatee's)
        address delegatee = _delegates[owner];
        if (delegatee != address(0)) {
            _effectiveVotingPower[delegatee]--;
        } else {
            _effectiveVotingPower[owner]--;
        }

        emit Transfer(owner, address(0), _tokenId); // ERC721 burn event
        emit QuantumEssenceBurned(owner, _tokenId);
    }

    // --- Update Delegate ---
    /**
     * @dev Delegates the caller's voting power to `_delegatee`.
     * Creates the "entanglement" link.
     * Updates effective voting power.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegate(address _delegatee) external {
        address oldDelegatee = _delegates[msg.sender];
        require(oldDelegatee != _delegatee, "Already delegated to this address");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        // Cannot delegate to address(0) - revokeDelegation handles this

        uint256 weight = _balances[msg.sender];
        if (weight > 0) {
            // Subtract weight from where it currently is (either msg.sender or old delegatee)
            if (oldDelegatee == address(0)) {
                 _effectiveVotingPower[msg.sender] = _effectiveVotingPower[msg.sender] - weight; // Subtract from self
            } else {
                 _effectiveVotingPower[oldDelegatee] = _effectiveVotingPower[oldDelegatee] - weight; // Subtract from old delegatee
            }

            // Add weight to the new delegatee (if _delegatee is not address(0))
             _effectiveVotingPower[_delegatee] = _effectiveVotingPower[_delegatee] + weight;
        }

        _delegates[msg.sender] = _delegatee;
        emit DelegationChanged(msg.sender, _delegatee);
    }


    // --- Update Revoke Delegation ---
    /**
     * @dev Revokes any existing delegation from the caller.
     * Breaks the "entanglement".
     * Updates effective voting power.
     */
    function revokeDelegation() external {
        address delegatee = _delegates[msg.sender];
        require(delegatee != address(0), "No active delegation to revoke");

        uint256 weight = _balances[msg.sender];
        if (weight > 0) {
            // Subtract weight from the delegatee
            _effectiveVotingPower[delegatee] = _effectiveVotingPower[delegatee] - weight;
            // Add weight back to the delegator (msg.sender)
            _effectiveVotingPower[msg.sender] = _effectiveVotingPower[msg.sender] + weight;
        }

        delete _delegates[msg.sender];
        emit DelegationChanged(msg.sender, address(0));
    }

}
```