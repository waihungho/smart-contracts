Okay, let's design a complex, multi-faceted smart contract that combines elements of decentralized governance, dynamic tokenomics, reputation, and NFT utility, aiming for advanced concepts beyond standard patterns.

We'll call this contract `QuantumQuorum`.

**Core Concepts:**

1.  **Dynamic Voting Power:** Voting power isn't just based on token balance, but also on a "Resonance Score" and ownership of special "Amplifier" NFTs.
2.  **Resonance Score:** A non-transferable, internal score reflecting participation and positive contributions (e.g., voting, proposing). It decays over time if inactive.
3.  **Amplifier NFTs:** ERC-721 NFTs that provide a configurable boost to a user's Resonance Score and/or Voting Power. They are transferable.
4.  **Tiered Governance:** Proposals can be simple text, parameter changes, treasury disbursements, or external contract calls. Success requires reaching both a dynamic Quorum and a majority threshold, calculated using the dynamic voting power.
5.  **Challenge Mechanism:** A passed proposal can be challenged within a certain window, forcing a second, potentially higher-stake vote to confirm or reject the initial outcome.
6.  **Managed Parameters:** Many system parameters (voting periods, required stakes, decay rates, quorum percentage) are not hardcoded but are stored and mutable *only* via successful governance proposals.
7.  **Whitelisted External Calls:** Governance can propose calls to specific functions on pre-approved (whitelisted) external contracts, enabling interaction with other DeFi protocols or on-chain services.
8.  **Treasury Management:** The contract holds ETH/other tokens (conceptually, we'll focus on ETH) that can be disbursed via governance proposals.
9.  **Delegation:** Users can delegate their voting power (QBIT + Resonance + Amplifier) to another address.

Let's structure the code with an outline and function summary first.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // For initial setup, governance takes over later
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // If we want to receive NFTs

// Outline:
// 1. State Variables, Enums, Structs: Define core data structures and contract state.
// 2. Events: Define events emitted on state changes.
// 3. Modifiers: Define custom access control or state check modifiers.
// 4. Constructor: Initialize contract state and parameters.
// 5. Quantum Quorum Token (QBIT) - Simplified Internal ERC20-like: Implement basic QBIT token functionality.
// 6. Resonance Score & Decay: Manage user participation scores.
// 7. Amplifier NFTs (ERC721 + Utility): Implement ERC721 behavior and the utility logic.
// 8. Voting Power Calculation: Combine QBIT, Resonance, and Amplifiers for voting power.
// 9. Governance Proposals & Voting: Handle proposal submission, voting, and state transitions.
// 10. Proposal Execution: Execute passed proposals based on type (Parameter Change, Treasury, External Call).
// 11. Challenge Mechanism: Allow challenging proposal results and resolving challenges.
// 12. Delegation: Allow users to delegate their voting power.
// 13. Treasury Management: Handle ETH deposits and withdrawals via governance.
// 14. Parameter Management: Get/set various system parameters (only via governance execution).
// 15. External Contract Whitelisting: Manage which external contracts governance can interact with.
// 16. View Functions: Provide read-only access to contract state.
// 17. Maintenance/Keeper Functions: Functions requiring specific permissions or timing (e.g., decay trigger).

// Function Summary:
// (QBIT Token)
// 1. mintQBIT(address to, uint256 amount): Mints QBIT tokens to an address (initially owner, later governance).
// 2. burnQBIT(uint256 amount): Burns QBIT tokens from the caller's balance.
// 3. transferQBIT(address to, uint256 amount): Transfers QBIT tokens.
// 4. transferFromQBIT(address from, address to, uint256 amount): Transfers QBIT tokens using allowance.
// 5. approveQBIT(address spender, uint256 amount): Grants allowance for QBIT transfer.
// 6. allowanceQBIT(address owner, address spender): Returns QBIT allowance. (View)
// 7. balanceOfQBIT(address account): Returns QBIT balance. (View)
// (Resonance Score)
// 8. getResonanceScore(address account): Returns the current Resonance Score. (View)
// 9. triggerResonanceDecay(address[] accounts): Applies time-based decay to Resonance Scores (permissioned).
// (Amplifier NFTs)
// 10. mintAmplifier(address to, string calldata uri): Mints a new Amplifier NFT (permissioned).
// 11. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): ERC721 Standard - Transfer NFT.
// 12. safeTransferFrom(address from, address to, uint256 tokenId): ERC721 Standard - Transfer NFT.
// 13. transferFrom(address from, address to, uint256 tokenId): ERC721 Standard - Transfer NFT.
// 14. approve(address to, uint256 tokenId): ERC721 Standard - Approve NFT transfer.
// 15. setApprovalForAll(address operator, bool approved): ERC721 Standard - Set operator approval.
// 16. getApproved(uint256 tokenId): ERC721 Standard - Get approved address for NFT. (View)
// 17. isApprovedForAll(address owner, address operator): ERC721 Standard - Check operator approval. (View)
// 18. ownerOf(uint256 tokenId): ERC721 Standard - Get NFT owner. (View)
// 19. balanceOf(address owner): ERC721 Standard - Get NFT count for owner. (View)
// 20. tokenURI(uint256 tokenId): ERC721 Standard - Get NFT metadata URI. (View)
// 21. getAmplifierBoost(uint256 tokenId): Returns the boost value of an Amplifier. (View)
// 22. setAmplifierBoost(uint256 tokenId, uint256 boostValue): Sets boost value for an Amplifier (permissioned).
// 23. listOwnedAmplifiers(address owner): Returns array of Amplifier token IDs owned. (View)
// (Voting Power)
// 24. calculateVotingPower(address account): Calculates effective voting power including QBIT, Resonance, and Amplifiers. (Pure/View)
// (Governance)
// 25. submitProposal(uint8 proposalType, bytes calldata proposalData, string calldata description): Submits a new governance proposal.
// 26. vote(uint256 proposalId, bool support): Casts a vote (Yes/No) on a proposal.
// 27. executeProposal(uint256 proposalId): Executes a successfully passed and unchallenged proposal.
// 28. challengeProposalResult(uint256 proposalId): Challenges the result of a recently passed proposal.
// 29. withdrawProposalStake(uint256 proposalId): Withdraws the stake locked when submitting a proposal (if successful/failed without challenge).
// 30. delegateVote(address delegatee): Delegates voting power to another address.
// 31. removeDelegatee(): Removes delegation.
// (Treasury)
// 32. depositETH(): Allows anyone to send ETH to the contract treasury. (Payable)
// (Parameters & Whitelisting)
// 33. setParameter(bytes32 paramName, uint256 paramValue): Sets a system parameter (internal, only via governance execution).
// 34. addWhitelistedContract(address contractAddress): Adds an address to the whitelisted contracts list (internal, only via governance execution).
// 35. removeWhitelistedContract(address contractAddress): Removes an address from the whitelisted contracts list (internal, only via governance execution).
// (View & Helper)
// 36. getProposalDetails(uint256 proposalId): Returns details of a proposal. (View)
// 37. getProposalState(uint256 proposalId): Returns the current state of a proposal. (View)
// 38. getProposalVoteCounts(uint256 proposalId): Returns current vote counts for a proposal. (View)
// 39. getDelegatee(address account): Returns the address an account has delegated to. (View)
// 40. getParameter(bytes32 paramName): Returns the value of a system parameter. (View)
// 41. isWhitelistedContract(address contractAddress): Checks if an address is whitelisted. (View)
// 42. getChallengeDetails(uint256 proposalId): Returns details of a challenge against a proposal. (View)
// 43. getProposalCount(): Returns the total number of proposals submitted. (View)
// 44. getOwnedNFTsEnumerable(address owner): Helper for listing NFTs (if not using Enumerable extension). (View) - *Note: ERC721Enumerable is standard, but listing manually shows the concept.* Let's include a manual list helper to show the logic if Enumerable isn't used.
// 45. onERC721Received(...) : Standard ERC721Receiver function - allows contract to receive NFTs.

contract QuantumQuorum is Ownable, ReentrancyGuard, ERC721URIStorage, IERC721Receiver {

    // --- 1. State Variables, Enums, Structs ---

    // QBIT Token State (Simplified)
    mapping(address => uint256) private _qbitBalances;
    mapping(address => mapping(address => uint256)) private _qbitAllowances;
    uint256 private _totalQBITSupply;

    // Resonance Score State
    mapping(address => uint256) public resonanceScores;
    mapping(address => uint48) public lastResonanceUpdate; // Using uint48 for timestamp

    // Amplifier NFT State (ERC721 is handled by inheritance)
    // Additional storage for Amplifier utility
    mapping(uint256 => uint256) public amplifierBoosts;
    // Manual list of owned NFTs for listOwnedAmplifiers (alternative to ERC721Enumerable)
    mapping(address => uint256[] private _ownedAmplifiersList);
    mapping(uint256 => uint256) private _ownedAmplifiersIndex; // Index for quick removal

    // Governance State
    enum ProposalType { Text, ParameterChange, TreasuryDisbursement, ExternalCall }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Challenged, ChallengeResolvedSucceeded, ChallengeResolvedFailed }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        bytes proposalData; // Encoded data for parameter changes, treasury, external calls
        string description;
        uint48 submissionTimestamp;
        uint48 votingDeadline;
        uint48 challengeDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotingPowerAtStart; // Snapshot of total possible voting power
        mapping(address => bool) voted; // Who has voted
        ProposalState state;
        uint256 proposalStake;
        bool stakeWithdrawn;
    }

    struct Challenge {
        uint256 proposalId;
        address challenger;
        uint48 challengeTimestamp;
        uint48 challengeVotingDeadline; // A new voting period just for the challenge
        uint256 challengeStake; // Stake required to challenge
        uint256 yesVotesOnChallenge; // Votes to UPHOLD the initial result (i.e., vote YES on the challenge means YES, the proposal passed)
        uint256 noVotesOnChallenge; // Votes to OVERTURN the initial result (i.e., vote NO on the challenge means NO, the proposal failed)
        mapping(address => bool) votedOnChallenge;
        bool resolved;
        bool challengerStakeWithdrawn;
    }

    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Challenge) public challenges; // Stores challenge details keyed by the proposalId being challenged

    // Delegation State
    mapping(address => address) public delegates; // delegator => delegatee

    // Parameter Management State
    mapping(bytes32 => uint256) public parameters;

    // External Contract Whitelisting State
    mapping(address => bool) public whitelistedContracts;

    // --- 2. Events ---

    event QBITMinted(address indexed account, uint256 amount);
    event QBITBurned(address indexed account, uint256 amount);
    event QBITTransfer(address indexed from, address indexed to, uint256 value);
    event QBITApproval(address indexed owner, address indexed spender, uint256 value);

    event ResonanceScoreUpdated(address indexed account, uint256 newScore);
    event ResonanceDecayTriggered(uint256 timestamp, uint256 decayedCount);

    event AmplifierMinted(address indexed to, uint256 indexed tokenId);
    event AmplifierBoostUpdated(uint256 indexed tokenId, uint256 boostValue);
    event AmplifierTransferred(address indexed from, address indexed to, uint256 indexed tokenId);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, uint48 votingDeadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);

    event ProposalChallengeStarted(uint256 indexed proposalId, address indexed challenger, uint48 challengeVotingDeadline);
    event VoteCastOnChallenge(uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool support);
    event ChallengeResolved(uint256 indexed proposalId, bool initialResultUpheld);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event ETHDeposited(address indexed depositor, uint256 amount);
    event ETHWithdrawn(address indexed recipient, uint256 amount);

    event ParameterChanged(bytes32 indexed paramName, uint256 newValue);
    event ContractWhitelisted(address indexed contractAddress);
    event ContractUnwhitelisted(address indexed contractAddress);

    // --- 3. Modifiers ---

    modifier onlyGovernance() {
        // This modifier will be used internally for functions that can ONLY be called
        // as a result of a successful proposal execution.
        // Initially, it could be restricted to Ownable, but in a real DAO, the executeProposal
        // function would have sole permission to call these internal helpers.
        // For this example, we'll leave it open or restricted to owner for demonstration,
        // but note the *intent* is for it to be callable ONLY by executeProposal.
        require(msg.sender == address(this), "Not called by governance execution");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID");
        _;
    }

    modifier proposalStateIs(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal not in required state");
        _;
    }

    // --- 4. Constructor ---

    constructor(string memory name, string memory symbol, uint256 initialQBITSupply, uint256 initialProposalStake)
        ERC721(name, symbol) // Name and Symbol for Amplifiers
        ERC721URIStorage()
        Ownable(msg.sender) // Initial owner
    {
        // Mint initial QBIT supply to the owner or a treasury address
        _mintQBIT(owner(), initialQBITSupply);

        // Set initial parameters
        parameters[keccak256("ProposalStake")] = initialProposalStake;
        parameters[keccak256("VotingPeriod")] = 7 days; // Example: 7 days for voting
        parameters[keccak256("ChallengePeriod")] = 2 days; // Example: 2 days to challenge after success
        parameters[keccak256("ChallengeStakeMultiplier")] = 2; // Challenge stake is multiplier * ProposalStake
        parameters[keccak256("ChallengeVotingPeriod")] = 3 days; // Example: 3 days for challenge vote
        parameters[keccak256("QuorumNumerator")] = 10; // 10%
        parameters[keccak256("QuorumDenominator")] = 100; // of totalVotingPowerAtStart
        parameters[keccak256("ResonanceDecayRate")] = 1; // Example: 1 unit of score decay per day
        parameters[keccak256("ResonanceDecayPeriod")] = 1 days; // How often decay is applied
        parameters[keccak256("MinResonanceScoreForProposal")] = 10; // Example: Minimum score to propose

        // In a real system, Ownership would likely be transferred to the DAO contract itself or a governance-controlled multisig
        // transferOwnership(address(this)); // Example: transfer to contract for full DAO control
    }

    // --- 5. Quantum Quorum Token (QBIT) - Simplified Internal ERC20-like ---

    // Note: Implementing basic ERC20 functions manually for demonstration.
    // A real implementation might inherit ERC20 or use a separate contract.

    function _mintQBIT(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        _totalQBITSupply += amount;
        _qbitBalances[account] += amount;
        emit QBITMinted(account, amount);
    }

    function mintQBIT(address account, uint256 amount) public onlyOwner { // Initially onlyOwner, later governance
        _mintQBIT(account, amount);
    }

    function burnQBIT(uint256 amount) public {
        _burnQBIT(msg.sender, amount);
    }

    function _burnQBIT(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        uint256 accountBalance = _qbitBalances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _qbitBalances[account] = accountBalance - amount;
        }
        _totalQBITSupply -= amount;
        emit QBITBurned(account, amount);
    }

    function transferQBIT(address to, uint256 amount) public returns (bool) {
        _transferQBIT(msg.sender, to, amount);
        return true;
    }

    function _transferQBIT(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(_qbitBalances[from] >= amount, "Transfer amount exceeds balance");

        unchecked {
            _qbitBalances[from] = _qbitBalances[from] - amount;
        }
        _qbitBalances[to] += amount;

        emit QBITTransfer(from, to, amount);
    }

    function transferFromQBIT(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _qbitAllowances[from][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        unchecked {
            _approveQBIT(from, msg.sender, currentAllowance - amount);
        }
        _transferQBIT(from, to, amount);
        return true;
    }

    function approveQBIT(address spender, uint256 amount) public returns (bool) {
        _approveQBIT(msg.sender, spender, amount);
        return true;
    }

    function _approveQBIT(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _qbitAllowances[owner][spender] = amount;
        emit QBITApproval(owner, spender, amount);
    }

    function allowanceQBIT(address owner, address spender) public view returns (uint256) {
        return _qbitAllowances[owner][spender];
    }

    function balanceOfQBIT(address account) public view returns (uint256) {
        return _qbitBalances[account];
    }

    function totalQBITSupply() public view returns (uint256) {
        return _totalQBITSupply;
    }

    // --- 6. Resonance Score & Decay ---

    function getResonanceScore(address account) public view returns (uint256) {
        return resonanceScores[account];
    }

    // Internal helper to update score and last update time
    function _updateResonanceScore(address account, int256 change) internal {
        uint256 currentScore = resonanceScores[account];
        uint256 newScore;
        if (change > 0) {
            newScore = currentScore + uint256(change);
        } else {
            uint256 decrease = uint256(-change);
            newScore = currentScore >= decrease ? currentScore - decrease : 0;
        }
        resonanceScores[account] = newScore;
        lastResonanceUpdate[account] = uint48(block.timestamp);
        emit ResonanceScoreUpdated(account, newScore);
    }

    // Applies decay based on time elapsed since last update
    function _applyResonanceDecay(address account) internal {
        uint48 lastUpdate = lastResonanceUpdate[account];
        if (lastUpdate == 0) {
            // Never updated, no decay needed or score is 0
            return;
        }
        uint256 decayPeriod = parameters[keccak256("ResonanceDecayPeriod")];
        uint256 decayRate = parameters[keccak256("ResonanceDecayRate")]; // score units per decay period

        if (decayPeriod == 0 || decayRate == 0) return; // Decay disabled

        uint256 timeElapsed = block.timestamp - lastUpdate;
        uint256 periodsElapsed = timeElapsed / decayPeriod;

        if (periodsElapsed > 0) {
            uint256 decayAmount = periodsElapsed * decayRate;
            uint256 currentScore = resonanceScores[account];
            uint256 newScore = currentScore >= decayAmount ? currentScore - decayAmount : 0;

            if (newScore != currentScore) {
                resonanceScores[account] = newScore;
                // Only update timestamp if decay was applied
                lastResonanceUpdate[account] = uint48(block.timestamp);
                emit ResonanceScoreUpdated(account, newScore);
            }
        }
    }

    // Permissioned function to trigger decay for multiple accounts
    // Could be called by a trusted keeper bot or governance itself
    function triggerResonanceDecay(address[] memory accounts) public onlyOwner { // Replace onlyOwner with keeper logic later
        uint256 decayedCount = 0;
        for (uint i = 0; i < accounts.length; i++) {
            uint256 oldScore = resonanceScores[accounts[i]];
            _applyResonanceDecay(accounts[i]);
            if (resonanceScores[accounts[i]] < oldScore) {
                 decayedCount++;
            }
        }
        emit ResonanceDecayTriggered(block.timestamp, decayedCount);
    }

    // --- 7. Amplifier NFTs (ERC721 + Utility) ---

    // Override ERC721 transfer functions to update internal list
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) {
            // Minting
            _addOwnedAmplifier(to, tokenId);
        } else if (to == address(0)) {
            // Burning
            _removeOwnedAmplifier(from, tokenId);
        } else {
            // Transferring
            _removeOwnedAmplifier(from, tokenId);
            _addOwnedAmplifier(to, tokenId);
        }
        // No batch handling needed for single token transfers
    }

    // Manual tracking helper functions
    function _addOwnedAmplifier(address to, uint256 tokenId) internal {
        _ownedAmplifiersList[to].push(tokenId);
        _ownedAmplifiersIndex[tokenId] = _ownedAmplifiersList[to].length - 1;
    }

     function _removeOwnedAmplifier(address from, uint256 tokenId) internal {
        uint256 lastIndex = _ownedAmplifiersList[from].length - 1;
        uint256 tokenIndex = _ownedAmplifiersIndex[tokenId];

        // If the token is not the last one in the list, swap it with the last one
        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = _ownedAmplifiersList[from][lastIndex];
            _ownedAmplifiersList[from][tokenIndex] = lastTokenId;
            _ownedAmplifiersIndex[lastTokenId] = tokenIndex;
        }

        // Remove the last element
        _ownedAmplifiersList[from].pop();
        // Remove the index mapping for the token being removed
        delete _ownedAmplifiersIndex[tokenId];
    }

    // Public helper to list owned NFTs (alternative to ERC721Enumerable)
    function listOwnedAmplifiers(address owner) public view returns (uint256[] memory) {
        return _ownedAmplifiersList[owner];
    }

    // Minting Amplifiers (Permissioned - e.g., by governance)
    function mintAmplifier(address to, string calldata uri, uint256 boostValue) public onlyOwner { // Replace onlyOwner with governance check
        uint256 newTokenId = _totalAmplifiers() + 1; // Simple ID generation
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, uri);
        amplifierBoosts[newTokenId] = boostValue;
        emit AmplifierMinted(to, newTokenId);
        emit AmplifierBoostUpdated(newTokenId, boostValue);
    }

    // Get/Set Amplifier boost value
    function getAmplifierBoost(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Amplifier does not exist");
        return amplifierBoosts[tokenId];
    }

    function setAmplifierBoost(uint256 tokenId, uint256 boostValue) public onlyOwner { // Replace onlyOwner with governance check
         require(_exists(tokenId), "Amplifier does not exist");
         amplifierBoosts[tokenId] = boostValue;
         emit AmplifierBoostUpdated(tokenId, boostValue);
    }

    // Override supportsInterface to include IERC721Receiver if implemented
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    // Implement onERC721Received to allow receiving other NFTs (optional advanced feature)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual override returns (bytes4) {
        // Decide what happens when this contract receives an ERC721.
        // By default, accept it. Add logic here if only specific NFTs are allowed or actions should be triggered.
        return this.onERC721Received.selector;
    }

    // --- 8. Voting Power Calculation ---

    function calculateVotingPower(address account) public view returns (uint256) {
        address currentHolder = delegates[account] == address(0) ? account : delegates[account];

        // Apply decay before calculating
        // Note: This is a simplified approach. In a high-frequency system, decay might need off-chain triggering
        // or be factored differently. For this example, we calculate based on current state *as if* decay was applied.
        // A more precise system would require on-chain decay application or a snapshot mechanism.
        // For now, we'll just use the current score assuming decay is handled by `triggerResonanceDecay`.
        uint256 resonance = resonanceScores[currentHolder];
        uint256 qbit = balanceOfQBIT(currentHolder);

        // Calculate Amplifier boost
        uint256 totalAmplifierBoost = 0;
        uint256[] memory ownedAmpIds = listOwnedAmplifiers(currentHolder); // Use our helper
        for(uint i = 0; i < ownedAmpIds.length; i++) {
            totalAmplifierBoost += getAmplifierBoost(ownedAmpIds[i]);
        }

        // Example Formula: Voting Power = QBIT Balance + Resonance Score + Total Amplifier Boost
        // This formula can be a parameter subject to governance change.
        // For simplicity, using a fixed formula here.
        uint256 votingPower = qbit + resonance + totalAmplifierBoost;

        return votingPower;
    }

    // --- 9. Governance Proposals & Voting ---

    function submitProposal(
        uint8 proposalType,
        bytes calldata proposalData,
        string calldata description
    ) external nonReentrant returns (uint256) {
        // Check minimum requirements to propose (e.g., stake, resonance score)
        uint256 requiredStake = parameters[keccak256("ProposalStake")];
        uint256 minResonance = parameters[keccak256("MinResonanceScoreForProposal")];
        require(balanceOfQBIT(msg.sender) >= requiredStake, "Insufficient QBIT stake");
        require(resonanceScores[msg.sender] >= minResonance, "Insufficient Resonance Score to propose");

        // Lock proposal stake
        _transferQBIT(msg.sender, address(this), requiredStake);

        uint256 proposalId = nextProposalId++;
        uint48 submissionTime = uint48(block.timestamp);
        uint48 votingEnd = submissionTime + uint48(parameters[keccak256("VotingPeriod")]);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: ProposalType(proposalType),
            proposalData: proposalData,
            description: description,
            submissionTimestamp: submissionTime,
            votingDeadline: votingEnd,
            challengeDeadline: 0, // Set after success
            yesVotes: 0,
            noVotes: 0,
            totalVotingPowerAtStart: calculateVotingPower(address(0)), // Snapshot of total possible power (simple sum, could be complex)
            voted: new mapping(address => bool),
            state: ProposalState.Active,
            proposalStake: requiredStake,
            stakeWithdrawn: false
        });

        emit ProposalSubmitted(proposalId, msg.sender, ProposalType(proposalType), votingEnd);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external nonReentrant proposalExists(proposalId) proposalStateIs(proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        // Calculate voting power at the time of voting
        uint256 voterPower = calculateVotingPower(msg.sender);
        require(voterPower > 0, "Voter has no power");

        // Record vote
        proposal.voted[msg.sender] = true;
        if (support) {
            proposal.yesVotes += voterPower;
             _updateResonanceScore(msg.sender, 1); // Reward for positive participation
        } else {
            proposal.noVotes += voterPower;
             _updateResonanceScore(msg.sender, 1); // Reward for participation
        }

        emit VoteCast(proposalId, msg.sender, voterPower, support);

        // Check if voting period ended after this vote (unlikely to change state here directly, handled by execute/view)
        // but could potentially transition state immediately for simple cases.
    }

    function getProposalDetails(uint256 proposalId) public view proposalExists(proposalId) returns (
        uint256 id,
        address proposer,
        ProposalType proposalType,
        bytes memory proposalData,
        string memory description,
        uint48 submissionTimestamp,
        uint48 votingDeadline,
        uint48 challengeDeadline,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 totalVotingPowerAtStart,
        ProposalState state,
        uint256 proposalStake,
        bool stakeWithdrawn
    ) {
        Proposal storage p = proposals[proposalId];
        return (
            p.id,
            p.proposer,
            p.proposalType,
            p.proposalData,
            p.description,
            p.submissionTimestamp,
            p.votingDeadline,
            p.challengeDeadline,
            p.yesVotes,
            p.noVotes,
            p.totalVotingPowerAtStart,
            p.state,
            p.proposalStake,
            p.stakeWithdrawn
        );
    }

    function getProposalState(uint256 proposalId) public view proposalExists(proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
            // Voting period ended, determine preliminary outcome
            uint256 quorumThreshold = (proposal.totalVotingPowerAtStart * parameters[keccak256("QuorumNumerator")]) / parameters[keccak256("QuorumDenominator")];
            if (proposal.yesVotes + proposal.noVotes >= quorumThreshold && proposal.yesVotes > proposal.noVotes) {
                 // Passed, now in challenge period
                 if (challenges[proposalId].challengeTimestamp == 0) { // Only if not already challenged
                     return ProposalState.Succeeded; // Ready to be challenged
                 } else {
                     // Challenged, state determined by challenge outcome
                     return ProposalState.Challenged;
                 }
            } else {
                return ProposalState.Failed;
            }
        } else if (proposal.state == ProposalState.Succeeded && challenges[proposalId].challengeTimestamp > 0 && block.timestamp > challenges[proposalId].challengeVotingDeadline) {
             // Challenge voting period ended, determine final outcome
             Challenge storage challenge = challenges[proposalId];
             // Challenge succeeds if NO votes (overturn original) > YES votes (uphold original)
             if (challenge.noVotesOnChallenge > challenge.yesVotesOnChallenge) {
                 return ProposalState.ChallengeResolvedFailed; // Original proposal overturned
             } else {
                 return ProposalState.ChallengeResolvedSucceeded; // Original proposal upheld
             }
        }
         else if (proposal.state == ProposalState.Challenged && challenges[proposalId].challengeTimestamp > 0 && block.timestamp <= challenges[proposalId].challengeVotingDeadline) {
             return ProposalState.Challenged; // Still in challenge voting period
         }


        // Return current state if no transition happened
        return proposal.state;
    }

     function getProposalVoteCounts(uint256 proposalId) public view proposalExists(proposalId) returns (uint256 yesVotes, uint256 noVotes) {
        Proposal storage p = proposals[proposalId];
        return (p.yesVotes, p.noVotes);
    }


    // --- 10. Proposal Execution ---

    function executeProposal(uint256 proposalId) public nonReentrant proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(block.timestamp > proposal.votingDeadline, "Voting period not ended"); // Ensure voting period is over

        ProposalState currentState = getProposalState(proposalId); // Get updated state considering challenge

        // Only execute if state is Succeeded AND not challenged within the window OR ChallengeResolvedSucceeded
        require(
            (currentState == ProposalState.Succeeded && challenges[proposalId].challengeTimestamp == 0 && block.timestamp > proposal.votingDeadline + parameters[keccak256("ChallengePeriod")]) ||
            currentState == ProposalState.ChallengeResolvedSucceeded,
            "Proposal not in executable state"
        );

        // Set state to Executed immediately to prevent re-execution
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        // Execute based on type
        bytes memory data = proposal.proposalData;
        if (proposal.proposalType == ProposalType.ParameterChange) {
            // Data is bytes32 paramName, uint256 paramValue
            require(data.length == 32 + 32, "Invalid data for ParameterChange");
            bytes32 paramName;
            uint256 paramValue;
            assembly {
                paramName := mload(add(data, 32))
                paramValue := mload(add(data, 64))
            }
            _setParameter(paramName, paramValue);

        } else if (proposal.proposalType == ProposalType.TreasuryDisbursement) {
            // Data is address recipient, uint256 amount
            require(data.length == 32 + 32, "Invalid data for TreasuryDisbursement");
            address recipient;
            uint256 amount;
             assembly {
                recipient := mload(add(data, 32))
                amount := mload(add(data, 64))
            }
            _sendETH(recipient, amount);

        } else if (proposal.proposalType == ProposalType.ExternalCall) {
            // Data is address targetContract, bytes callData
            require(data.length >= 32 + 32, "Invalid data for ExternalCall"); // Need at least target address and data length
            address targetContract;
            bytes memory callData;
             assembly {
                targetContract := mload(add(data, 32))
                let dataPtr := add(data, 64)
                let dataLen := mload(dataPtr)
                callData := mload(add(dataPtr, 32)) // Pointer to dynamic data
             }
            // Need to copy dynamic bytes properly - example needs refinement or helper
            // For simplicity, assume data is address + abi.encodePacked(calldata)
            // A robust implementation would use abi.decode

            // Let's refine data structure for external call: `abi.encode(targetAddress, callData)`
            (address targetContractAddress, bytes memory externalCallData) = abi.decode(data, (address, bytes));
            _callExternalContract(targetContractAddress, externalCallData);

        } else if (proposal.proposalType == ProposalType.Text) {
            // No action needed for Text proposals
            // Optionally, update resonance score for proposer/voters? Done in vote.
        }

        emit ProposalExecuted(proposalId);

        // Stake is withdrawn only after execution or final failure/success resolve
        // Stake withdrawal is a separate function
    }

    // --- 11. Challenge Mechanism ---

    function challengeProposalResult(uint256 proposalId) external nonReentrant proposalExists(proposalId) proposalStateIs(proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.votingDeadline, "Voting period not ended");
        require(block.timestamp <= proposal.votingDeadline + parameters[keccak256("ChallengePeriod")], "Challenge period has ended");
        require(challenges[proposalId].challengeTimestamp == 0, "Proposal already challenged");

        uint256 challengeStake = parameters[keccak256("ProposalStake")] * parameters[keccak256("ChallengeStakeMultiplier")];
        require(balanceOfQBIT(msg.sender) >= challengeStake, "Insufficient QBIT stake to challenge");

        // Lock challenge stake
        _transferQBIT(msg.sender, address(this), challengeStake);

        uint48 challengeVotingEnd = uint48(block.timestamp) + uint48(parameters[keccak256("ChallengeVotingPeriod")]);

        challenges[proposalId] = Challenge({
            proposalId: proposalId,
            challenger: msg.sender,
            challengeTimestamp: uint48(block.timestamp),
            challengeVotingDeadline: challengeVotingEnd,
            challengeStake: challengeStake,
            yesVotesOnChallenge: 0, // Votes to UPHOLD original result
            noVotesOnChallenge: 0,  // Votes to OVERTURN original result
            votedOnChallenge: new mapping(address => bool),
            resolved: false,
            challengerStakeWithdrawn: false
        });

        // Update proposal state to Challenged
        proposal.state = ProposalState.Challenged;
        emit ProposalStateChanged(proposalId, ProposalState.Challenged);
        emit ProposalChallengeStarted(proposalId, msg.sender, challengeVotingEnd);
    }

    // Voting on a challenge (part of the main vote function logic, slightly adapted)
    // Users vote on the *challenge*, not the original proposal again.
    // support = true means support the challenge (i.e., overturn the original proposal result)
    // support = false means oppose the challenge (i.e., uphold the original proposal result)
    // Let's integrate this into a separate function for clarity: voteOnChallenge
    function voteOnChallenge(uint256 proposalId, bool support) external nonReentrant proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Challenged, "Proposal is not in a challenged state");

        Challenge storage challenge = challenges[proposalId];
        require(block.timestamp <= challenge.challengeVotingDeadline, "Challenge voting period has ended");
        require(!challenge.votedOnChallenge[msg.sender], "Already voted on this challenge");

        uint256 voterPower = calculateVotingPower(msg.sender);
        require(voterPower > 0, "Voter has no power");

        challenge.votedOnChallenge[msg.sender] = true;
        if (support) { // Voting YES on the challenge means OVERTURN the original result
            challenge.noVotesOnChallenge += voterPower;
             _updateResonanceScore(msg.sender, 2); // Higher reward for challenge participation?
        } else { // Voting NO on the challenge means UPHOLD the original result
            challenge.yesVotesOnChallenge += voterPower;
             _updateResonanceScore(msg.sender, 2); // Higher reward for challenge participation?
        }

        emit VoteCastOnChallenge(proposalId, msg.sender, voterPower, support);

        // The challenge is resolved either by someone calling executeProposal (which checks state)
        // or a specific resolveChallenge function. Let's add a explicit resolve function.
    }

    // Function to finalize a challenge after its voting period ends
    function resolveChallenge(uint256 proposalId) external nonReentrant proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Challenged, "Proposal is not in a challenged state");

        Challenge storage challenge = challenges[proposalId];
        require(block.timestamp > challenge.challengeVotingDeadline, "Challenge voting period not ended");
        require(!challenge.resolved, "Challenge already resolved");

        challenge.resolved = true; // Mark challenge as resolved

        // Challenge succeeds if NO votes (overturn original) > YES votes (uphold original)
        bool challengeSucceeded = challenge.noVotesOnChallenge > challenge.yesVotesOnChallenge;

        if (challengeSucceeded) {
            // Original proposal is overturned (failed)
            proposal.state = ProposalState.ChallengeResolvedFailed;
            // Return challenger stake
             _transferQBIT(address(this), challenge.challenger, challenge.challengeStake);
             challenge.challengerStakeWithdrawn = true;
             // Proposer stake is lost (can be burned or sent somewhere else)
             _burnQBIT(address(this), proposal.proposalStake); // Burn proposer stake
        } else {
            // Original proposal is upheld (succeeded)
            proposal.state = ProposalState.ChallengeResolvedSucceeded;
            // Challenger stake is lost
            _burnQBIT(address(this), challenge.challengeStake); // Burn challenger stake
            // Proposer stake can be withdrawn
        }

        emit ProposalStateChanged(proposalId, proposal.state);
        emit ChallengeResolved(proposalId, !challengeSucceeded); // Emit if original result was upheld
    }


     function getChallengeDetails(uint256 proposalId) public view returns (
         bool isActive,
         address challenger,
         uint48 challengeTimestamp,
         uint48 challengeVotingDeadline,
         uint256 challengeStake,
         uint256 yesVotesOnChallenge,
         uint256 noVotesOnChallenge,
         bool resolved,
         bool challengerStakeWithdrawn
     ) {
         Challenge storage c = challenges[proposalId];
         // Check if a challenge exists for this proposal
         if (c.challengeTimestamp == 0) {
             return (false, address(0), 0, 0, 0, 0, 0, false, false);
         }
         return (
             !c.resolved && block.timestamp <= c.challengeVotingDeadline, // isActive
             c.challenger,
             c.challengeTimestamp,
             c.challengeVotingDeadline,
             c.challengeStake,
             c.yesVotesOnChallenge,
             c.noVotesOnChallenge,
             c.resolved,
             c.challengerStakeWithdrawn
         );
     }

    // --- 12. Delegation ---

    function delegateVote(address delegatee) external {
        require(delegatee != msg.sender, "Cannot delegate to yourself");
        address currentDelegatee = delegates[msg.sender];
        delegates[msg.sender] = delegatee;
        emit DelegateChanged(msg.sender, currentDelegatee, delegatee);
    }

    function removeDelegatee() external {
         address currentDelegatee = delegates[msg.sender];
         require(currentDelegatee != address(0), "No delegate set");
         delete delegates[msg.sender];
         emit DelegateChanged(msg.sender, currentDelegatee, address(0));
    }

    function getDelegatee(address account) public view returns (address) {
        return delegates[account];
    }


    // --- 13. Treasury Management ---

    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    function depositETH() external payable {
        // Handled by receive function
    }

    function getTreasuryBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    // Internal function called by governance execution
    function _sendETH(address payable recipient, uint256 amount) internal onlyGovernance nonReentrant {
        require(address(this).balance >= amount, "Insufficient treasury balance");
        // Using call for robustness
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
        emit ETHWithdrawn(recipient, amount);
    }

    // --- 14. Parameter Management ---

    // Internal function called by governance execution
    function _setParameter(bytes32 paramName, uint256 paramValue) internal onlyGovernance {
        parameters[paramName] = paramValue;
        emit ParameterChanged(paramName, paramValue);
    }

    function getParameter(bytes32 paramName) public view returns (uint256) {
        return parameters[paramName];
    }

    // --- 15. External Contract Whitelisting ---

     // Internal functions called by governance execution
    function _addWhitelistedContract(address contractAddress) internal onlyGovernance {
        require(contractAddress != address(0), "Cannot whitelist zero address");
        whitelistedContracts[contractAddress] = true;
        emit ContractWhitelisted(contractAddress);
    }

     function _removeWhitelistedContract(address contractAddress) internal onlyGovernance {
        whitelistedContracts[contractAddress] = false;
        emit ContractUnwhitelisted(contractAddress);
    }

    // Internal function called by governance execution
    function _callExternalContract(address target, bytes memory data) internal onlyGovernance nonReentrant {
        require(whitelistedContracts[target], "Target contract not whitelisted");
        require(target != address(this), "Cannot call self via external call type"); // Prevent re-entrancy/abuse

        (bool success, bytes memory returnData) = target.call(data);
        // Decide how to handle failure. Reverting here means the governance proposal fails if the call fails.
        require(success, string(abi.encodePacked("External call failed: ", returnData)));
        // Optionally log returnData
    }

     function isWhitelistedContract(address contractAddress) public view returns (bool) {
        return whitelistedContracts[contractAddress];
    }


    // --- 16. View Functions ---

    // Most view functions are already implemented above near their relevant state.
    // Adding a few more general ones.

    function getProposalCount() public view returns (uint256) {
        return nextProposalId - 1;
    }

    // --- 17. Maintenance/Keeper Functions ---

    // triggerResonanceDecay is listed here. Could be called by Owner or a specific role/keeper contract.


    // Function to withdraw proposal stake after conclusion
    function withdrawProposalStake(uint256 proposalId) external nonReentrant proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.stakeWithdrawn, "Stake already withdrawn");

        ProposalState state = getProposalState(proposalId); // Get current state

        // Allowed states for withdrawal: Failed, Executed, ChallengeResolvedSucceeded
        bool canWithdraw = (state == ProposalState.Failed || state == ProposalState.Executed || state == ProposalState.ChallengeResolvedSucceeded);

        require(canWithdraw, "Proposal not in a state allowing stake withdrawal");
        // Ensure challenge is resolved if it existed
        if (challenges[proposalId].challengeTimestamp > 0) {
             require(challenges[proposalId].resolved, "Challenge not yet resolved");
        }


        // Proposer stake is ONLY returned if proposal succeeds (initially or after challenge) AND the challenge, if any, also resulted in uphold.
        bool returnStake = (state == ProposalState.Executed || state == ProposalState.ChallengeResolvedSucceeded);


        if (returnStake) {
            _transferQBIT(address(this), proposal.proposer, proposal.proposalStake);
        } else {
            // Stake is burned if the proposal ultimately fails or is overturned by a challenge
            _burnQBIT(address(this), proposal.proposalStake);
        }

        proposal.stakeWithdrawn = true;

        // Also allow challenger to withdraw stake if challenge succeeded (overturned original)
        Challenge storage challenge = challenges[proposalId];
        if (challenge.challengeTimestamp > 0 && challenge.resolved && !challenge.challengerStakeWithdrawn) {
             // Challenge succeeded if NO votes (overturn original) > YES votes (uphold original)
             bool challengeSucceeded = challenge.noVotesOnChallenge > challenge.yesVotesOnChallenge;
             if (challengeSucceeded) {
                  _transferQBIT(address(this), challenge.challenger, challenge.challengeStake);
             } else {
                  _burnQBIT(address(this), challenge.challengeStake);
             }
             challenge.challengerStakeWithdrawn = true;
        }


    }
}
```

**Explanation of Advanced Concepts & Functions:**

1.  **Dynamic Voting Power (`calculateVotingPower`):** This goes beyond simple token weighting by incorporating `resonanceScores` and `amplifierBoosts`. This creates a more complex game theory landscape where participation and specific NFTs contribute to influence, not just holding the base token. The formula could be made even more complex and itself governed by parameters.
2.  **Resonance Score (`resonanceScores`, `getResonanceScore`, `_updateResonanceScore`, `_applyResonanceDecay`, `triggerResonanceDecay`):** This introduces a non-transferable reputation/activity metric. The decay mechanism encourages continuous engagement. `triggerResonanceDecay` is designed as a permissioned function, implying the need for an off-chain keeper or specific role to maintain the scores, which is a common pattern in gas-intensive maintenance tasks.
3.  **Amplifier NFTs (`amplifierBoosts`, `mintAmplifier`, `getAmplifierBoost`, `setAmplifierBoost`, `listOwnedAmplifiers`, overridden ERC721 transfers):** These aren't just collectibles. They have a direct, configurable utility within the governance system by boosting voting power. The manual listing helper (`listOwnedAmplifiers`) demonstrates how to track owned tokens if not using the `Enumerable` extension, which can be gas-intensive. `setAmplifierBoost` is permissioned, likely meant to be callable *only* via governance.
4.  **Tiered/Parameterizable Governance (`ProposalType`, `Proposal`, `parameters`, `submitProposal`, `vote`, `executeProposal`, `setParameter`):** The contract defines different proposal types with varied execution logic. Crucially, many system variables are stored in a `parameters` mapping and can only be changed by governance itself executing a `ParameterChange` proposal calling the internal `_setParameter`. This makes the DAO adaptable without needing contract upgrades for parameter tweaks.
5.  **Challenge Mechanism (`Challenge`, `challengeProposalResult`, `voteOnChallenge`, `resolveChallenge`, `getChallengeDetails`):** This adds a layer of checks and balances. A successful initial vote isn't final if challenged. The challenge requires a stake and triggers a *new* voting period specifically to decide the challenge's outcome. This is more complex than simple timelocks and can prevent malicious proposals that pass quickly.
6.  **Whitelisted External Calls (`whitelistedContracts`, `_addWhitelistedContract`, `_removeWhitelistedContract`, `_callExternalContract`, `isWhitelistedContract`):** Enables the DAO to interact with other smart contracts on-chain. This is a powerful feature for a DAO treasury to invest in DeFi, interact with protocols, etc. The whitelisting prevents arbitrary calls, reducing risk. The execution happens via the internal `_callExternalContract`, only callable by a successful `executeProposal` for an `ExternalCall` type.
7.  **Delegation (`delegates`, `delegateVote`, `removeDelegatee`, `getDelegatee`):** A standard but essential feature for scale, allowing users to participate in governance indirectly by assigning their voting power.
8.  **Non-Standard Token (`_qbitBalances`, etc.):** While the functions mimic ERC-20, the state is kept internal. This allows for custom behaviors (like potential hooks into Resonance Score on transfer, though not implemented here) and signifies that the QBIT is tightly coupled to this contract's logic, not necessarily a general-purpose liquid token (though it could be). Stake locking/burning directly manipulates these internal balances.
9.  **Internal vs. External Functions:** Key governance actions (like setting parameters, sending ETH, calling external contracts) are implemented as *internal* functions (`_setParameter`, `_sendETH`, `_callExternalContract`) that can *only* be called by the trusted `executeProposal` function (protected by the `onlyGovernance` intent, which in a full DAO would mean `msg.sender` must be `address(this)` when called from `executeProposal`). This is a common pattern for ensuring governance control.
10. **State Management Complexity:** The contract manages multiple interconnected states: QBIT balances, Resonance scores, NFT ownership and boosts, Proposal details, Challenge details, Delegation links, Parameters, and Whitelisted contracts. Transitions between these states (e.g., voting updating Resonance, execution changing parameters or sending funds, challenges altering proposal state) are carefully managed.

This contract provides a blueprint for a sophisticated decentralized organization with dynamic influence mechanisms and the ability to manage assets and interact with the broader blockchain ecosystem through a controlled governance process. It far exceeds the complexity of basic DAO or token examples.