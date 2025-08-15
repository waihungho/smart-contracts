The **Cognitive Nexus Protocol (CNP)** is a self-evolving, decentralized protocol designed for collective intelligence and adaptive resource allocation. It moves beyond traditional DAOs by integrating AI-driven reputation, dynamic NFTs, and a novel mechanism for the protocol to suggest and vote on its own parameter adjustments.

This contract aims to create a "living" organization that learns and optimizes based on contributor behavior, external data (via oracles), and community proposals. It mints "Thought Fragments" (dynamic NFTs) as rewards and utilizes a "Wisdom Score" (reputation) for enhanced governance weight and resource access.

---

### Outline and Function Summary:

**I. Core Infrastructure & Access Control**
1.  **`constructor(address initialOracleAddress_)`**: Initializes the contract owner and sets the trusted AI oracle address.
2.  **`updateOracleAddress(address newOracleAddress_)`**: Allows the owner to update the trusted AI oracle address.
3.  **`pauseProtocol()`**: Emergency function by owner to pause critical operations.
4.  **`unpauseProtocol()`**: Owner function to unpause the protocol.
5.  **`withdrawFunds(address recipient_, uint256 amount_)`**: Allows the owner to withdraw excess funds from the protocol's treasury (e.g., from fees, donations).
6.  **`setProtocolParameters(uint256 minWisdomScoreForProposal_, uint256 proposalVoteThreshold_, uint256 proposalVotingPeriod_, uint256 contributionGracePeriod_)`**: Sets various global operational parameters for the protocol.

**II. Wisdom Score (Reputation) Management**
7.  **`registerContributor()`**: Allows any address to register as a contributor to the protocol.
8.  **`submitContributionEvidence(string calldata evidenceURI_)`**: Contributors submit a URI (e.g., IPFS hash) of their work/contribution for AI analysis.
9.  **`processAIAnalysisReport(address contributor_, uint256 contributionId_, int256 scoreImpact_, string calldata impactReason_)`**: Called by the trusted AI oracle to report analysis results, updating a contributor's Wisdom Score. This is a core AI-driven feature.
10. **`delegateWisdomScore(address delegatee_)`**: Allows a contributor to delegate their voting power (Wisdom Score) to another address, enabling liquid democracy.
11. **`revokeWisdomScoreDelegation()`**: Revokes any active Wisdom Score delegation.
12. **`getContributorWisdomScore(address contributor_)`**: Public view function to retrieve a contributor's current Wisdom Score.

**III. Thought Fragment (Dynamic NFT) Management**
13. **`mintThoughtFragment(address recipient_, string calldata initialMetadataURI_)`**: Mints a new dynamic NFT ("Thought Fragment") to a recipient, typically as a reward for significant contributions.
14. **`updateThoughtFragmentMetadata(uint256 tokenId_, string calldata newMetadataURI_)`**: Allows for dynamic updates to a Thought Fragment's metadata URI, reflecting changes in contributor status, Wisdom Score, or impact.
15. **`burnThoughtFragment(uint256 tokenId_)`**: Allows for the burning of a Thought Fragment, potentially due to inactivity, negative impact, or governance decision.
16. **`getThoughtFragmentDetails(uint256 tokenId_)`**: Public view function to retrieve metadata URI of a Thought Fragment.

**IV. Collective Intelligence & Resource Allocation**
17. **`submitProposal(string calldata proposalURI_, ProposalType proposalType_)`**: Contributors submit proposals for protocol changes, resource allocations, or new initiatives. Requires a minimum Wisdom Score.
18. **`voteOnProposal(uint256 proposalId_, bool support_)`**: Allows contributors to vote on open proposals, with their effective Wisdom Score determining their vote weight.
19. **`executeProposal(uint256 proposalId_)`**: Executes a proposal if it has passed the voting threshold and grace period.
20. **`requestResourceAllocation(string calldata requestDetailsURI_, uint256 requestedAmount_)`**: Contributors can formally request resources from the protocol's treasury, which automatically creates a proposal for community review.

**V. Protocol Self-Evolution / Adaptive Mechanisms**
21. **`triggerParameterRecalibration(string calldata recalibrationRationaleURI_, uint256 newMinWisdomScoreForProposal_, uint256 newProposalVoteThreshold_, uint256 newContributionGracePeriod_)`**: A unique mechanism, callable by the AI oracle, to propose new protocol parameters based on observed data/trends. This then becomes a special type of proposal for governance.
22. **`acceptParameterRecalibration(uint256 proposalId_)`**: Special function to execute a passed recalibration proposal, applying the new protocol parameters for self-evolution.

**VI. Treasury Management**
23. **`receive()`**: Fallback function allowing any user to deposit ETH into the protocol's treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline and Function Summary:
// This contract, "CognitiveNexusProtocol", is a self-evolving, decentralized protocol
// designed for collective intelligence and adaptive resource allocation. It goes beyond
// traditional DAOs by integrating AI-driven reputation, dynamic NFTs, and a mechanism
// for the protocol to suggest and vote on its own parameter adjustments.

// I. Core Infrastructure & Access Control
// 1. constructor(address initialOracleAddress_): Initializes the contract owner and sets the trusted AI oracle address.
// 2. updateOracleAddress(address newOracleAddress_): Allows the owner to update the trusted AI oracle address.
// 3. pauseProtocol(): Emergency function by owner to pause critical operations.
// 4. unpauseProtocol(): Owner function to unpause the protocol.
// 5. withdrawFunds(address recipient_, uint256 amount_): Allows the owner to withdraw excess funds from the protocol's treasury.
// 6. setProtocolParameters(uint256 minWisdomScoreForProposal_, uint256 proposalVoteThreshold_, uint256 proposalVotingPeriod_, uint256 contributionGracePeriod_):
//    Sets various global operational parameters for the protocol.

// II. Wisdom Score (Reputation) Management
// 7. registerContributor(): Allows any address to register as a contributor to the protocol.
// 8. submitContributionEvidence(string calldata evidenceURI_): Contributors submit a URI (e.g., IPFS hash)
//    of their work/contribution for AI analysis.
// 9. processAIAnalysisReport(address contributor_, uint256 contributionId_, int256 scoreImpact_, string calldata impactReason_):
//    Called by the trusted AI oracle to report analysis results, updating a contributor's Wisdom Score.
// 10. delegateWisdomScore(address delegatee_): Allows a contributor to delegate their voting power (Wisdom Score)
//     to another address.
// 11. revokeWisdomScoreDelegation(): Revokes any active Wisdom Score delegation.
// 12. getContributorWisdomScore(address contributor_): Public view function to retrieve a contributor's current Wisdom Score.

// III. Thought Fragment (Dynamic NFT) Management
// 13. mintThoughtFragment(address recipient_, string calldata initialMetadataURI_): Mints a new dynamic NFT
//     ("Thought Fragment") to a recipient, typically as a reward for significant contributions.
// 14. updateThoughtFragmentMetadata(uint256 tokenId_, string calldata newMetadataURI_): Allows for dynamic updates
//     to a Thought Fragment's metadata URI, reflecting changes in contributor status or impact.
// 15. burnThoughtFragment(uint256 tokenId_): Allows for the burning of a Thought Fragment, potentially due
//     to inactivity, negative impact, or owner's decision.
// 16. getThoughtFragmentDetails(uint256 tokenId_): Public view function to retrieve metadata URI of a Thought Fragment.

// IV. Collective Intelligence & Resource Allocation
// 17. submitProposal(string calldata proposalURI_, ProposalType proposalType_): Contributors submit proposals for protocol
//     changes, resource allocations, or new initiatives. Requires a minimum Wisdom Score.
// 18. voteOnProposal(uint256 proposalId_, bool support_): Allows contributors to vote on open proposals, with their
//     Wisdom Score determining their vote weight.
// 19. executeProposal(uint256 proposalId_): Executes a proposal if it has passed the voting threshold and grace period.
// 20. requestResourceAllocation(string calldata requestDetailsURI_, uint256 requestedAmount_): Contributors can formally
//     request resources from the protocol's treasury, which may initiate a proposal.

// V. Protocol Self-Evolution / Adaptive Mechanisms
// 21. triggerParameterRecalibration(string calldata recalibrationRationaleURI_, uint256 newMinWisdomScoreForProposal_,
//     uint256 newProposalVoteThreshold_, uint256 newContributionGracePeriod_): A mechanism, callable by the oracle,
//     to propose new protocol parameters based on observed data/trends. This then becomes a proposal for governance.
// 22. acceptParameterRecalibration(uint256 proposalId_): Special function to execute a passed recalibration proposal,
//     applying the new protocol parameters.

// VI. Treasury Management
// 23. receive(): Allows any user to deposit ETH into the protocol's treasury.

contract CognitiveNexusProtocol is Ownable, ERC721URIStorage, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    address private _aiOracleAddress; // Trusted oracle for AI analysis reports

    // Contributor data
    struct Contributor {
        bool isRegistered;
        int256 wisdomScore; // Can be negative for detrimental actions
        uint256 lastContributionTimestamp;
        address delegatedTo; // Address to which wisdom score is delegated
    }
    mapping(address => Contributor) public contributors;

    // Contributions submitted for analysis
    struct Contribution {
        address contributor;
        string evidenceURI; // IPFS/Arweave hash for the actual contribution
        bool processedByAI;
        int256 aiScoreImpact; // Score impact reported by AI
        uint256 submissionTimestamp;
    }
    Counters.Counter private _contributionIds;
    mapping(uint256 => Contribution) public contributions;

    // Thought Fragments (Dynamic NFTs)
    Counters.Counter private _thoughtFragmentIds;
    // ERC721URIStorage handles token URI. We'll link token IDs to contributor addresses.
    mapping(uint256 => address) public thoughtFragmentOwnerMapping; // Map tokenId to original contributor

    // Proposals for governance and resource allocation
    enum ProposalType { ProtocolParameterChange, ResourceAllocation, GeneralInitiative, ParameterRecalibration }

    struct Proposal {
        address proposer;
        string proposalURI; // IPFS/Arweave hash for proposal details
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        uint256 totalVotesFor; // Sum of wisdom scores for 'yes'
        uint256 totalVotesAgainst; // Sum of wisdom scores for 'no'
        bool executed;
        bool passed; // Whether it passed its vote threshold
        mapping(address => bool) hasVoted; // Prevents double voting
        ProposalType proposalType;
        // Specific fields for ParameterRecalibration proposal type
        uint256 newMinWisdomScoreForProposal;
        uint256 newProposalVoteThreshold; // Percentage * 100 (e.g., 5100 for 51%)
        uint256 newContributionGracePeriod; // In seconds
        // Specific fields for ResourceAllocation proposal type
        uint256 requestedAmount;
        address requestRecipient;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // Protocol Parameters (can be changed via governance)
    uint256 public minWisdomScoreForProposal; // Minimum score to submit a proposal
    uint256 public proposalVoteThreshold;     // Percentage * 100 (e.g., 5100 for 51%)
    uint256 public proposalVotingPeriod;      // In seconds
    uint256 public contributionGracePeriod;   // In seconds, for AI analysis

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracleAddress);
    event ContributorRegistered(address indexed contributor);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed contributor, string evidenceURI);
    event AIAnalysisReported(uint256 indexed contributionId, address indexed contributor, int256 scoreImpact);
    event WisdomScoreUpdated(address indexed contributor, int256 newScore, int256 scoreChange);
    event WisdomScoreDelegated(address indexed delegator, address indexed delegatee);
    event WisdomScoreDelegationRevoked(address indexed delegator);
    event ThoughtFragmentMinted(uint256 indexed tokenId, address indexed recipient, string initialMetadataURI);
    event ThoughtFragmentMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event ThoughtFragmentBurned(uint256 indexed tokenId);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI, ProposalType proposalType);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, int256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event ParametersRecalibrated(uint256 newMinWisdomScoreForProposal, uint256 newProposalVoteThreshold, uint256 newContributionGracePeriod);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ResourceAllocationRequested(address indexed requester, uint256 requestedAmount, string requestDetailsURI);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == _aiOracleAddress, "CNP: Caller is not the AI oracle");
        _;
    }

    modifier onlyRegisteredContributor(address _contributor) {
        require(contributors[_contributor].isRegistered, "CNP: Not a registered contributor");
        _;
    }

    // --- Constructor ---
    constructor(address initialOracleAddress_) ERC721("ThoughtFragment", "TF") Ownable(msg.sender) {
        require(initialOracleAddress_ != address(0), "CNP: Initial oracle address cannot be zero");
        _aiOracleAddress = initialOracleAddress_;

        // Set initial protocol parameters
        minWisdomScoreForProposal = 100;    // Example: needs 100 wisdom score to propose
        proposalVoteThreshold = 5100;       // Example: 51% of total weighted votes (51 * 100)
        proposalVotingPeriod = 5 days;      // Example: 5 days for voting
        contributionGracePeriod = 3 days;   // Example: 3 days for AI analysis
    }

    // I. Core Infrastructure & Access Control

    // 2. updateOracleAddress: Allows the owner to update the trusted AI oracle address.
    function updateOracleAddress(address newOracleAddress_) public onlyOwner {
        require(newOracleAddress_ != address(0), "CNP: New oracle address cannot be zero");
        _aiOracleAddress = newOracleAddress_;
        emit OracleAddressUpdated(newOracleAddress_);
    }

    // 3. pauseProtocol: Emergency function by owner to pause critical operations.
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    // 4. unpauseProtocol: Owner function to unpause the protocol.
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    // 5. withdrawFunds: Allows the owner to withdraw excess funds from the protocol's treasury.
    function withdrawFunds(address recipient_, uint256 amount_) public onlyOwner nonReentrant {
        require(recipient_ != address(0), "CNP: Recipient cannot be zero address");
        require(amount_ > 0, "CNP: Amount must be greater than zero");
        require(address(this).balance >= amount_, "CNP: Insufficient contract balance");

        (bool success,) = recipient_.call{value: amount_}("");
        require(success, "CNP: Failed to withdraw funds");
        emit FundsWithdrawn(recipient_, amount_);
    }

    // 6. setProtocolParameters: Sets various global operational parameters for the protocol.
    // Can also be updated via successful governance proposals.
    function setProtocolParameters(
        uint256 _minWisdomScoreForProposal,
        uint256 _proposalVoteThreshold,
        uint256 _proposalVotingPeriod,
        uint256 _contributionGracePeriod
    ) public onlyOwner { // This can also be called by a successful ParameterRecalibration proposal
        require(_proposalVoteThreshold <= 10000, "CNP: Vote threshold cannot exceed 100%"); // 10000 = 100%
        minWisdomScoreForProposal = _minWisdomScoreForProposal;
        proposalVoteThreshold = _proposalVoteThreshold;
        proposalVotingPeriod = _proposalVotingPeriod;
        contributionGracePeriod = _contributionGracePeriod;
        emit ParametersRecalibrated(_minWisdomScoreForProposal, _proposalVoteThreshold, _contributionGracePeriod);
    }

    // II. Wisdom Score (Reputation) Management

    // 7. registerContributor: Allows any address to register as a contributor.
    function registerContributor() public whenNotPaused {
        require(!contributors[msg.sender].isRegistered, "CNP: Already a registered contributor");
        contributors[msg.sender].isRegistered = true;
        contributors[msg.sender].wisdomScore = 0; // Start with a neutral score
        contributors[msg.sender].lastContributionTimestamp = block.timestamp; // Initialize activity timestamp
        emit ContributorRegistered(msg.sender);
    }

    // 8. submitContributionEvidence: Contributors submit a URI (e.g., IPFS hash) of their work/contribution for AI analysis.
    function submitContributionEvidence(string calldata evidenceURI_) public whenNotPaused onlyRegisteredContributor(msg.sender) {
        _contributionIds.increment();
        uint256 newId = _contributionIds.current();
        contributions[newId] = Contribution({
            contributor: msg.sender,
            evidenceURI: evidenceURI_,
            processedByAI: false,
            aiScoreImpact: 0,
            submissionTimestamp: block.timestamp
        });
        contributors[msg.sender].lastContributionTimestamp = block.timestamp; // Update activity
        emit ContributionSubmitted(newId, msg.sender, evidenceURI_);
    }

    // 9. processAIAnalysisReport: Called by the trusted AI oracle to report analysis results, updating a contributor's Wisdom Score.
    function processAIAnalysisReport(
        address contributor_,
        uint256 contributionId_,
        int256 scoreImpact_,
        string calldata impactReason_ // Reason can be stored off-chain or logged for context
    ) public onlyOracle whenNotPaused {
        require(contributions[contributionId_].contributor == contributor_, "CNP: Contributor mismatch for contribution ID");
        require(!contributions[contributionId_].processedByAI, "CNP: Contribution already processed by AI");
        require(block.timestamp <= contributions[contributionId_].submissionTimestamp + contributionGracePeriod, "CNP: AI processing grace period expired");

        contributions[contributionId_].processedByAI = true;
        contributions[contributionId_].aiScoreImpact = scoreImpact_;

        int256 oldScore = contributors[contributor_].wisdomScore;
        contributors[contributor_].wisdomScore += scoreImpact_;

        emit AIAnalysisReported(contributionId_, contributor_, scoreImpact_);
        emit WisdomScoreUpdated(contributor_, contributors[contributor_].wisdomScore, scoreImpact_);
    }

    // 10. delegateWisdomScore: Allows a contributor to delegate their voting power (Wisdom Score) to another address.
    function delegateWisdomScore(address delegatee_) public whenNotPaused onlyRegisteredContributor(msg.sender) {
        require(msg.sender != delegatee_, "CNP: Cannot delegate to self");
        require(contributors[delegatee_].isRegistered, "CNP: Delegatee must be a registered contributor");
        contributors[msg.sender].delegatedTo = delegatee_;
        emit WisdomScoreDelegated(msg.sender, delegatee_);
    }

    // 11. revokeWisdomScoreDelegation: Revokes any active Wisdom Score delegation.
    function revokeWisdomScoreDelegation() public whenNotPaused onlyRegisteredContributor(msg.sender) {
        require(contributors[msg.sender].delegatedTo != address(0), "CNP: No active delegation to revoke");
        contributors[msg.sender].delegatedTo = address(0); // Set to zero address to revoke
        emit WisdomScoreDelegationRevoked(msg.sender);
    }

    // 12. getContributorWisdomScore: Public view function to retrieve a contributor's current Wisdom Score.
    function getContributorWisdomScore(address contributor_) public view returns (int256) {
        return contributors[contributor_].wisdomScore;
    }

    // Internal function to get the effective wisdom score (considering delegation) for voting
    function _getEffectiveWisdomScore(address voter_) internal view returns (int256) {
        address currentVoter = voter_;
        // Follow delegation chain (simple one-level for now to avoid complexity)
        if (contributors[currentVoter].delegatedTo != address(0)) {
            currentVoter = contributors[currentVoter].delegatedTo;
        }
        return contributors[currentVoter].wisdomScore;
    }

    // III. Thought Fragment (Dynamic NFT) Management

    // 13. mintThoughtFragment: Mints a new dynamic NFT ("Thought Fragment") to a recipient, typically as a reward.
    function mintThoughtFragment(address recipient_, string calldata initialMetadataURI_) public whenNotPaused {
        // Can be called by owner or by the protocol itself upon a passed proposal/event
        require(recipient_ != address(0), "CNP: Recipient cannot be zero address");
        require(bytes(initialMetadataURI_).length > 0, "CNP: Metadata URI cannot be empty");

        _thoughtFragmentIds.increment();
        uint256 newId = _thoughtFragmentIds.current();
        _safeMint(recipient_, newId);
        _setTokenURI(newId, initialMetadataURI_);
        thoughtFragmentOwnerMapping[newId] = recipient_; // Keep track of original owner/contributor
        emit ThoughtFragmentMinted(newId, recipient_, initialMetadataURI_);
    }

    // 14. updateThoughtFragmentMetadata: Allows for dynamic updates to a Thought Fragment's metadata URI.
    // This could be triggered by AI analysis, wisdom score changes, or successful contributions.
    // For simplicity, allows owner to trigger, but in an advanced system, could be automated or proposal-driven.
    function updateThoughtFragmentMetadata(uint256 tokenId_, string calldata newMetadataURI_) public onlyOwner {
        require(_exists(tokenId_), "CNP: Token does not exist");
        _setTokenURI(tokenId_, newMetadataURI_);
        emit ThoughtFragmentMetadataUpdated(tokenId_, newMetadataURI_);
    }

    // 15. burnThoughtFragment: Allows for the burning of a Thought Fragment.
    // Could be triggered by governance, inactivity, or negative wisdom score.
    function burnThoughtFragment(uint256 tokenId_) public onlyOwner { // Simplified to owner, but could be governance-driven
        require(_exists(tokenId_), "CNP: Token does not exist");
        _burn(tokenId_);
        delete thoughtFragmentOwnerMapping[tokenId_];
        emit ThoughtFragmentBurned(tokenId_);
    }

    // 16. getThoughtFragmentDetails: Public view function to retrieve metadata URI of a Thought Fragment.
    function getThoughtFragmentDetails(uint256 tokenId_) public view returns (string memory) {
        return tokenURI(tokenId_);
    }

    // IV. Collective Intelligence & Resource Allocation

    // 17. submitProposal: Contributors submit proposals for protocol changes, resource allocations, or new initiatives.
    function submitProposal(string calldata proposalURI_, ProposalType proposalType_) public whenNotPaused onlyRegisteredContributor(msg.sender) {
        require(contributors[msg.sender].wisdomScore >= int256(minWisdomScoreForProposal), "CNP: Insufficient wisdom score to submit proposal");
        require(bytes(proposalURI_).length > 0, "CNP: Proposal URI cannot be empty");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        proposals[newId].proposer = msg.sender;
        proposals[newId].proposalURI = proposalURI_;
        proposals[newId].creationTimestamp = block.timestamp;
        proposals[newId].expirationTimestamp = block.timestamp + proposalVotingPeriod;
        proposals[newId].executed = false;
        proposals[newId].passed = false;
        proposals[newId].proposalType = proposalType_;
        // Initialize specific fields for resource allocation if applicable, otherwise they remain 0/address(0)
        proposals[newId].requestedAmount = 0;
        proposals[newId].requestRecipient = address(0);

        emit ProposalSubmitted(newId, msg.sender, proposalURI_, proposalType_);
    }

    // 18. voteOnProposal: Allows contributors to vote on open proposals, with their Wisdom Score determining their vote weight.
    function voteOnProposal(uint256 proposalId_, bool support_) public whenNotPaused onlyRegisteredContributor(msg.sender) {
        Proposal storage proposal = proposals[proposalId_];
        require(proposal.proposer != address(0), "CNP: Proposal does not exist"); // Check if proposal exists
        require(block.timestamp < proposal.expirationTimestamp, "CNP: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "CNP: Already voted on this proposal");

        int256 effectiveScore = _getEffectiveWisdomScore(msg.sender);
        require(effectiveScore > 0, "CNP: Cannot vote with zero or negative effective wisdom score"); // Only positive wisdom scores can vote

        proposal.hasVoted[msg.sender] = true;
        if (support_) {
            proposal.totalVotesFor += uint256(effectiveScore);
        } else {
            proposal.totalVotesAgainst += uint256(effectiveScore);
        }

        emit VoteCast(proposalId_, msg.sender, support_, effectiveScore);
    }

    // 19. executeProposal: Executes a proposal if it has passed.
    function executeProposal(uint256 proposalId_) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId_];
        require(proposal.proposer != address(0), "CNP: Proposal does not exist");
        require(block.timestamp >= proposal.expirationTimestamp, "CNP: Voting period has not ended");
        require(!proposal.executed, "CNP: Proposal already executed");

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        bool passed = false;

        // Prevent division by zero if no votes were cast
        if (totalVotes > 0) {
            passed = (proposal.totalVotesFor * 10000) / totalVotes >= proposalVoteThreshold; // Multiply by 10000 for percentage calculation
        } else {
            // If no votes, it cannot pass
            passed = false;
        }

        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            if (proposal.proposalType == ProposalType.ResourceAllocation) {
                require(address(this).balance >= proposal.requestedAmount, "CNP: Insufficient funds for allocation");
                require(proposal.requestRecipient != address(0), "CNP: Resource recipient not set for allocation proposal");
                (bool success,) = proposal.requestRecipient.call{value: proposal.requestedAmount}("");
                require(success, "CNP: Failed to allocate resources");
            }
            // For ProtocolParameterChange and ParameterRecalibration, actual parameter updates
            // are handled by `setProtocolParameters` and `acceptParameterRecalibration` respectively,
            // or require explicit owner action after the proposal passes.
            // Other GeneralInitiative proposals might simply mark as executed, with off-chain actions.
        }
        emit ProposalExecuted(proposalId_, passed);
    }

    // 20. requestResourceAllocation: Contributors can formally request resources from the protocol's treasury.
    function requestResourceAllocation(string calldata requestDetailsURI_, uint256 requestedAmount_) public whenNotPaused onlyRegisteredContributor(msg.sender) {
        require(requestedAmount_ > 0, "CNP: Requested amount must be greater than zero");
        require(bytes(requestDetailsURI_).length > 0, "CNP: Request details URI cannot be empty");
        // This function will automatically submit a proposal for review
        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        proposals[newId].proposer = msg.sender;
        proposals[newId].proposalURI = requestDetailsURI_;
        proposals[newId].creationTimestamp = block.timestamp;
        proposals[newId].expirationTimestamp = block.timestamp + proposalVotingPeriod;
        proposals[newId].executed = false;
        proposals[newId].passed = false;
        proposals[newId].proposalType = ProposalType.ResourceAllocation;
        proposals[newId].requestedAmount = requestedAmount_;
        proposals[newId].requestRecipient = msg.sender; // Requesting for self, recipient can be changed in proposal

        emit ResourceAllocationRequested(msg.sender, requestedAmount_, requestDetailsURI_);
        emit ProposalSubmitted(newId, msg.sender, requestDetailsURI_, ProposalType.ResourceAllocation);
    }

    // V. Protocol Self-Evolution / Adaptive Mechanisms

    // 21. triggerParameterRecalibration: A mechanism, callable by the oracle (simulating an AI/data analysis system),
    // to propose new protocol parameters based on observed data/trends. This then becomes a proposal for governance.
    function triggerParameterRecalibration(
        string calldata recalibrationRationaleURI_,
        uint256 newMinWisdomScoreForProposal_,
        uint256 newProposalVoteThreshold_,
        uint256 newContributionGracePeriod_
    ) public onlyOracle whenNotPaused {
        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        Proposal storage p = proposals[newId];
        p.proposer = _aiOracleAddress; // Oracle acts as proposer for this type
        p.proposalURI = recalibrationRationaleURI_;
        p.creationTimestamp = block.timestamp;
        p.expirationTimestamp = block.timestamp + proposalVotingPeriod;
        p.executed = false;
        p.passed = false;
        p.proposalType = ProposalType.ParameterRecalibration;
        p.newMinWisdomScoreForProposal = newMinWisdomScoreForProposal_;
        p.newProposalVoteThreshold = newProposalVoteThreshold_;
        p.newContributionGracePeriod = newContributionGracePeriod_;

        emit ProposalSubmitted(newId, _aiOracleAddress, recalibrationRationaleURI_, ProposalType.ParameterRecalibration);
    }

    // 22. acceptParameterRecalibration: Special function to execute a passed recalibration proposal, applying the new protocol parameters.
    // This allows the protocol to "self-evolve" by updating its own rules based on AI-driven insights and community consensus.
    function acceptParameterRecalibration(uint256 proposalId_) public onlyOwner { // Owner executes AFTER voting passes
        Proposal storage proposal = proposals[proposalId_];
        require(proposal.proposer != address(0), "CNP: Proposal does not exist");
        require(block.timestamp >= proposal.expirationTimestamp, "CNP: Voting period has not ended");
        require(!proposal.executed, "CNP: Proposal already executed");
        require(proposal.proposalType == ProposalType.ParameterRecalibration, "CNP: Not a parameter recalibration proposal");

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        bool passed = false;

        if (totalVotes > 0) {
            passed = (proposal.totalVotesFor * 10000) / totalVotes >= proposalVoteThreshold;
        } else {
            passed = false;
        }

        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            // Apply the new parameters as proposed by the oracle and accepted by governance
            setProtocolParameters(
                proposal.newMinWisdomScoreForProposal,
                proposal.newProposalVoteThreshold,
                proposalVotingPeriod, // Keep current voting period or add it to proposal as well if desired
                proposal.newContributionGracePeriod
            );
            // setProtocolParameters emits ParametersRecalibrated event
        }
        emit ProposalExecuted(proposalId_, passed);
    }

    // VI. Treasury Management

    // 23. receive: Allows any user to deposit ETH into the protocol's treasury.
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```