Okay, let's create a smart contract for a Decentralized Autonomous Research Organization (DARO). This DARO will focus on funding and validating scientific research, using novel concepts like:

1.  **Reputation/Role-Based System:** Instead of simple token holding, eligibility and voting power are based on acquiring non-transferable Soulbound Tokens (SBTs) representing different roles (Researcher, Reviewer, Validator, Governance).
2.  **Milestone-Based Funding:** Research proposals are funded incrementally based on completing predefined milestones, requiring validation.
3.  **Decentralized Review & Validation:** Milestone completion requires attestation/approval from designated Reviewers (holding specific SBTs).
4.  **Tokenized IP (Optional but included):** Successful, completed research projects can have their Intellectual Property (IP) registered and potentially tokenized as NFTs managed by the DAO.
5.  **Configurable Governance:** Core parameters can be changed via DAO voting using SBT weights.
6.  **Off-chain Data Integration:** Uses IPFS hashes (`bytes32`) to reference detailed proposals, results, and milestone evidence stored off-chain.

This structure combines elements of DAOs, DeSci, and SBTs in a specific workflow designed for managing research projects.

---

**DARO (Decentralized Autonomous Research Organization) Smart Contract**

**Outline:**

1.  **State Variables:** Define core data structures like proposals, votes, parameters, and addresses of linked contracts (SBT, IP NFT).
2.  **Enums:** Define states for proposals, votes, and potentially SBT types.
3.  **Structs:** Define structures for `Proposal`, `Milestone`, `GovernanceVote`.
4.  **Events:** Emit events for key actions (proposal submission, funding, voting, milestone completion, etc.).
5.  **Modifiers:** Access control modifiers (e.g., `onlyGovernance`, `onlySBT`).
6.  **Interfaces:** Define interfaces for interacting with external SBT and IP NFT contracts.
7.  **Core Functions:** Implement functions for proposal lifecycle, funding, voting, milestone management, reputation/SBT interaction, IP management, and treasury management.
8.  **View Functions:** Provide read-only access to contract state.

**Function Summary:**

1.  `constructor`: Initializes the contract with essential parameters and linked contract addresses.
2.  `setGovernanceParameters`: Allows governance to update DAO parameters (voting period, quorum, etc.).
3.  `submitResearchProposal`: Allows an address holding the `ResearcherSBT` to submit a proposal.
4.  `fundProposal`: Allows anyone to contribute funds to a specific proposal.
5.  `createGovernanceVote`: Initiates a governance vote on a proposal (approval, funding) or parameter change. Requires `GovernanceSBT`.
6.  `voteOnGovernanceVote`: Allows addresses holding relevant SBTs (based on vote type) to cast their vote, weighted by their SBT holdings.
7.  `executeGovernanceVote`: Executes the outcome of a successfully passed governance vote.
8.  `delegateSBTVote`: Allows users to delegate their SBT voting power to another address (requires interaction with SBT contract).
9.  `awardSBT`: Protocol/Governance function to mint/award specific SBTs to addresses based on contributions.
10. `revokeSBT`: Governance function to revoke specific SBTs (e.g., for malicious activity).
11. `submitMilestoneCompletion`: Allows the original proposer to claim a milestone is complete and provide evidence hash.
12. `addReviewerToMilestone`: Allows an address holding the `ReviewerSBT` to volunteer to review a specific milestone.
13. `approveMilestoneCompletion`: Allows a designated reviewer (holding `ReviewerSBT` and added to milestone) to approve milestone completion. Requires a threshold of approvals.
14. `releaseMilestoneFunds`: Releases funds allocated to a completed and approved milestone.
15. `registerProjectIP`: Allows the proposer of a completed & funded project to register the project's final IP hash.
16. `mintIPNFT`: Allows governance to mint an NFT representing the registered IP, potentially transferring it to the project team or DAO treasury. Requires interaction with IP NFT contract.
17. `depositTreasury`: Allows anyone to donate funds directly to the main DAO treasury.
18. `withdrawTreasury`: Allows withdrawal of treasury funds based on a successful governance vote.
19. `getProposal`: View function to retrieve details of a specific proposal.
20. `listProposals`: View function to list all proposal IDs or details (potentially paginated in a real-world scenario).
21. `getGovernanceVoteState`: View function to retrieve the current state and results of a governance vote.
22. `getGovernanceParameters`: View function to retrieve current DAO governance parameters.
23. `getSBTBalance`: View function to check the balance/holding of a specific SBT type for an address (calls SBT contract).
24. `isHoldingSBT`: View function to check if an address holds at least one of a specific SBT type (calls SBT contract).
25. `getProjectIPHash`: View function to get the registered IP hash for a completed project.
26. `getMilestoneState`: View function to get the state of a specific milestone within a proposal.
27. `getMilestoneReviewers`: View function to list addresses reviewing a specific milestone.
28. `getMilestoneApprovals`: View function to count approvals for a specific milestone.
29. `getTotalFundsRaisedForProposal`: View function for total funds received by a proposal.
30. `getFundsReleasedForProposal`: View function for total funds released to a proposal based on completed milestones.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal Interfaces for external contracts
interface IReputationSBT {
    // Emitted when SBTs are awarded or revoked
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721 like transfer (0x0 -> recipient for mint, holder -> 0x0 for burn)

    // Check if an address holds an SBT of a specific type (token ID represents type)
    function balanceOf(address owner, uint256 sbtType) external view returns (uint256);

    // Mint a specific type of SBT to an address
    // sbtType represents the type (e.g., 1 for Researcher, 2 for Reviewer, etc.)
    // amount is typically 1 for non-transferable tokens representing roles
    function mint(address to, uint256 sbtType, uint256 amount) external;

    // Burn/Revoke a specific type of SBT from an address
    function burn(address from, uint256 sbtType, uint256 amount) external;

    // Check if delegation is supported and get delegated address
    function getDelegate(address holder, uint256 sbtType) external view returns (address);

    // Delegate voting power for a specific SBT type
    function delegate(uint256 sbtType, address delegatee) external;
}

interface IIPNFT {
    // Emitted when an IP NFT is minted
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721 Transfer

    // Mint a new IP NFT, linking it to an IPFS hash
    // ipHash: bytes32 representing the IPFS hash or other identifier
    // recipient: address to receive the NFT
    // projectId: Optional link back to the project in DARO
    function mint(address recipient, bytes32 ipHash, uint256 projectId) external returns (uint256 tokenId);
}


contract DecentralizedAutonomousResearchOrganization {
    // --- Enums ---
    enum ProposalState { Draft, Active, Funded, Completed, Rejected, Cancelled }
    enum GovernanceVoteState { Pending, Active, Succeeded, Failed, Executed, Cancelled }
    enum GovernanceVoteType { ProposeFunding, ChangeParameter, AwardSBT, RevokeSBT, WithdrawTreasury, Other }
    enum SBTType { None, Researcher, Reviewer, Validator, Governance } // Corresponding token IDs in IReputationSBT

    // --- Structs ---
    struct Milestone {
        bytes32 evidenceHash; // IPFS hash or identifier for completion evidence
        uint256 percentageOfFunding; // Percentage of total proposal funding for this milestone
        bool completed; // Whether milestone is marked complete by proposer
        mapping(address => bool) approvals; // Addresses (Reviewers) who approved completion
        uint256 approvalCount; // Number of approvals received
        bool fundsReleased; // Whether funds for this milestone have been released
        address[] currentReviewers; // Addresses currently reviewing this milestone
    }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 descriptionHash; // IPFS hash for detailed proposal description
        uint256 fundingGoal; // Total ETH required for the project
        uint256 totalFunded; // Total ETH received so far
        uint256 totalReleased; // Total ETH released for completed milestones
        ProposalState state;
        Milestone[] milestones;
        bytes32 finalIPHash; // IPFS hash for final research results/IP
        uint256 createdTimestamp;
    }

    struct GovernanceVote {
        uint256 id;
        GovernanceVoteType voteType;
        address proposer;
        bytes32 descriptionHash; // IPFS hash for detailed vote description
        uint256 proposalId; // Relevant proposal ID for ProposeFunding votes
        bytes data; // Arbitrary data for parameter changes or complex actions
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 totalSBTWeight; // Total voting weight (based on relevant SBTs) at vote creation
        mapping(address => uint256) votes; // Voter address => SBT weight voted (can be 0 for abstention, >0 for yes, <0 for no?) Let's simplify: mapping address => bool (true for Yes, false for No)
        mapping(address => bool) voted; // Keep track of who voted to prevent double voting
        uint256 yesVotesWeight; // Total weight of 'Yes' votes
        uint256 noVotesWeight; // Total weight of 'No' votes
        GovernanceVoteState state;
        bool executed;
    }


    // --- State Variables ---
    address public owner; // Initial owner, can be set to governance later
    uint256 public nextProposalId = 1;
    uint256 public nextGovernanceVoteId = 1;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => GovernanceVote) public governanceVotes;

    address public treasury; // Address holding pooled funds

    // Governance Parameters (can be changed by successful governance votes)
    struct GovernanceParameters {
        uint256 minProposalFundingGoal;
        uint256 maxProposalFundingGoal;
        uint256 proposalVotingPeriod; // Duration of governance votes in seconds
        uint256 proposalVoteQuorumNumerator; // Numerator for quorum calculation (quorum = totalSBTWeight * numerator / denominator)
        uint256 proposalVoteQuorumDenominator; // Denominator for quorum calculation
        uint256 milestoneReviewApprovalThresholdNumerator; // e.g., 50 for 50%
        uint256 milestoneReviewApprovalThresholdDenominator; // e.g., 100 for 50%
        uint256 milestoneReviewPeriod; // Time limit for reviewers to approve
        uint256 voteExecutionDelay; // Time delay after vote success before execution is possible
        uint256 sbtVoteWeightMultiplier; // Multiplier for calculating vote weight from SBT balance
    }
    GovernanceParameters public govParams;

    // Linked external contracts
    IReputationSBT public reputationSBT;
    IIPNFT public ipNFT;

    // --- Events ---
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 descriptionHash, uint256 fundingGoal, uint256 milestoneCount, uint256 timestamp);
    event ProposalFunded(uint256 indexed proposalId, address indexed funder, uint256 amount, uint256 totalFunded, uint256 timestamp);
    event GovernanceVoteCreated(uint256 indexed voteId, GovernanceVoteType indexed voteType, address indexed proposer, uint256 proposalId, uint256 startTimestamp, uint256 endTimestamp);
    event GovernanceVoteCast(uint256 indexed voteId, address indexed voter, bool support, uint256 weight, uint256 timestamp);
    event GovernanceVoteExecuted(uint256 indexed voteId, GovernanceVoteState finalState, uint256 timestamp);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState, uint256 timestamp);
    event MilestoneSubmitted(uint256 indexed proposalId, uint256 indexed milestoneIndex, bytes32 evidenceHash, uint256 timestamp);
    event MilestoneReviewerAdded(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed reviewer, uint259 timestamp);
    event MilestoneApproved(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed approver, uint256 currentApprovalCount, uint256 timestamp);
    event MilestoneFundsReleased(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount, uint256 timestamp);
    event IPRegistered(uint256 indexed proposalId, bytes32 ipHash, uint256 timestamp);
    event IPNFTMinted(uint256 indexed proposalId, uint256 indexed nftTokenId, address indexed recipient, bytes32 ipHash, uint256 timestamp);
    event TreasuryDeposited(address indexed funder, uint256 amount, uint256 timestamp);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount, uint256 timestamp);
    event GovernanceParametersUpdated(uint256 timestamp);
    event SBTawarded(address indexed recipient, uint256 indexed sbtType, uint256 amount, uint256 timestamp);
    event SBTrevoked(address indexed holder, uint256 indexed sbtType, uint256 amount, uint256 timestamp);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyGovernance() {
        // In a mature DAO, this would check if the call is originating from a successful governance vote execution.
        // For simplicity here, let's say the 'owner' (which can be set to a governance contract address) or
        // an address holding a specific GovernanceSBT can call these directly for demonstration,
        // but ideally, these are only callable via the executeGovernanceVote function.
         require(msg.sender == owner || isHoldingSBT(msg.sender, uint256(SBTType.Governance)), "Not authorized by Governance");
        _;
    }

    modifier onlyResearcherSBT() {
        require(isHoldingSBT(msg.sender, uint256(SBTType.Researcher)), "Requires Researcher SBT");
        _;
    }

    modifier onlyReviewerSBT() {
        require(isHoldingSBT(msg.sender, uint256(SBTType.Reviewer)), "Requires Reviewer SBT");
        _;
    }

    modifier onlyProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == msg.sender, "Not the proposal proposer");
        _;
    }


    // --- Constructor ---
    constructor(address _treasuryAddress, address _reputationSBTAddress, address _ipNFTAddress) {
        owner = msg.sender; // Initial owner
        treasury = _treasuryAddress; // Could also be 'address(this)'
        reputationSBT = IReputationSBT(_reputationSBTAddress);
        ipNFT = IIPNFT(_ipNFTAddress);

        // Set initial, sensible governance parameters
        govParams = GovernanceParameters({
            minProposalFundingGoal: 1 ether, // Example: minimum 1 ETH
            maxProposalFundingGoal: 100 ether, // Example: maximum 100 ETH
            proposalVotingPeriod: 3 days, // Example: votes last 3 days
            proposalVoteQuorumNumerator: 3, // Example: 3/10 = 30% quorum
            proposalVoteQuorumDenominator: 10,
            milestoneReviewApprovalThresholdNumerator: 60, // Example: 60% approval needed
            milestoneReviewApprovalThresholdDenominator: 100,
            milestoneReviewPeriod: 7 days, // Example: Reviewers have 7 days
            voteExecutionDelay: 1 days, // Example: 1 day delay after success
            sbtVoteWeightMultiplier: 1 // Example: 1 SBT = 1 vote weight (can be adjusted for quadratic voting etc.)
        });
    }

    // --- Core Functions ---

    /// @notice Allows governance to update DAO parameters.
    /// @param _params The new set of governance parameters.
    function setGovernanceParameters(GovernanceParameters memory _params) external onlyGovernance {
        govParams = _params;
        emit GovernanceParametersUpdated(block.timestamp);
    }

    /// @notice Allows a Researcher SBT holder to submit a research proposal.
    /// @param _descriptionHash IPFS hash of the detailed proposal description.
    /// @param _fundingGoal Total ETH requested for the project.
    /// @param _milestonePercentages Array of percentages for each milestone's funding share. Must sum to 100.
    function submitResearchProposal(
        bytes32 _descriptionHash,
        uint256 _fundingGoal,
        uint256[] memory _milestonePercentages
    ) external onlyResearcherSBT {
        require(_fundingGoal >= govParams.minProposalFundingGoal, "Funding goal too low");
        require(_fundingGoal <= govParams.maxProposalFundingGoal, "Funding goal too high");
        require(_milestonePercentages.length > 0, "Must have at least one milestone");

        uint256 totalPercentage;
        Milestone[] memory newMilestones = new Milestone[](_milestonePercentages.length);
        for (uint i = 0; i < _milestonePercentages.length; i++) {
            require(_milestonePercentages[i] > 0, "Milestone percentage must be positive");
            totalPercentage += _milestonePercentages[i];
            newMilestones[i].percentageOfFunding = _milestonePercentages[i];
            newMilestones[i].completed = false;
            newMilestones[i].fundsReleased = false;
            // evidenceHash, approvalCount, currentReviewers are default initialized
        }
        require(totalPercentage == 100, "Milestone percentages must sum to 100");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            fundingGoal: _fundingGoal,
            totalFunded: 0,
            totalReleased: 0,
            state: ProposalState.Draft, // Starts as Draft, needs governance approval to become Active
            milestones: newMilestones,
            finalIPHash: bytes32(0),
            createdTimestamp: block.timestamp
        });

        emit ProposalSubmitted(proposalId, msg.sender, _descriptionHash, _fundingGoal, _milestonesPercentages.length, block.timestamp);
    }

    /// @notice Allows anyone to fund a proposal.
    /// @param _proposalId The ID of the proposal to fund.
    function fundProposal(uint256 _proposalId) external payable {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.Funded, "Proposal not accepting funds");
        require(msg.value > 0, "Must send non-zero ETH");

        proposal.totalFunded += msg.value;

        if (proposal.state == ProposalState.Active && proposal.totalFunded >= proposal.fundingGoal) {
            proposal.state = ProposalState.Funded;
            emit ProposalStateChanged(proposalId, ProposalState.Funded, block.timestamp);
        }

        // Funds are held in the contract balance until milestones are completed
        // or transferred to a dedicated treasury if architected that way.
        // Simple approach: funds stay in this contract's balance, tracked per proposal.

        emit ProposalFunded(_proposalId, msg.sender, msg.value, proposal.totalFunded, block.timestamp);
    }

    /// @notice Creates a governance vote. Requires GovernanceSBT.
    /// @param _voteType The type of governance vote.
    /// @param _descriptionHash IPFS hash for vote details.
    /// @param _proposalId Relevant proposal ID (if applicable).
    /// @param _data Arbitrary data for complex votes (e.g., encoded parameter changes).
    function createGovernanceVote(
        GovernanceVoteType _voteType,
        bytes32 _descriptionHash,
        uint256 _proposalId,
        bytes memory _data
    ) external onlyGovernance {
         if (_voteType == GovernanceVoteType.ProposeFunding) {
            require(proposals[_proposalId].id != 0, "Proposal does not exist");
            require(proposals[_proposalId].state == ProposalState.Draft, "Proposal must be in Draft state to propose funding");
        }
        // Add other type-specific checks here

        uint256 voteId = nextGovernanceVoteId++;
        uint256 start = block.timestamp;
        uint256 end = start + govParams.proposalVotingPeriod;

        // Calculate total weight of relevant SBTs at vote creation time.
        // For simplicity, let's assume Governance votes require GovernanceSBT holders.
        // A more complex system could use different SBT types for different vote types.
        // Getting *total* supply of an SBT type requires a function on the SBT contract.
        // Let's assume IReputationSBT has a `totalSupply(uint256 sbtType)` function.
        uint256 totalPossibleWeight = reputationSBT.balanceOf(address(0), uint256(SBTType.Governance)) * govParams.sbtVoteWeightMultiplier; // Placeholder - requires SBT contract support for total supply check or snapshotting

        // A more robust DAO would snapshot voting power or use a token balance check
        // against a block number to prevent manipulating balance just before voting.
        // For this example, we'll rely on the `isHoldingSBT` check during voting,
        // and `totalSBTWeight` is a simplification/placeholder.

        governanceVotes[voteId] = GovernanceVote({
            id: voteId,
            voteType: _voteType,
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            proposalId: _proposalId,
            data: _data,
            startTimestamp: start,
            endTimestamp: end,
            totalSBTWeight: totalPossibleWeight, // Simplified placeholder
            votes: new mapping(address => bool)(), // Yes/No mapping
            voted: new mapping(address => bool)(), // Voted status
            yesVotesWeight: 0,
            noVotesWeight: 0,
            state: GovernanceVoteState.Active,
            executed: false
        });

        emit GovernanceVoteCreated(voteId, _voteType, msg.sender, _proposalId, start, end);
    }

    /// @notice Casts a vote on an active governance vote. Requires holding the relevant SBT.
    /// @param _voteId The ID of the vote.
    /// @param _support True for 'Yes', False for 'No'.
    function voteOnGovernanceVote(uint256 _voteId, bool _support) external {
        GovernanceVote storage vote = governanceVotes[_voteId];
        require(vote.id != 0, "Vote does not exist");
        require(vote.state == GovernanceVoteState.Active, "Vote is not active");
        require(block.timestamp >= vote.startTimestamp && block.timestamp <= vote.endTimestamp, "Vote is not open");
        require(!vote.voted[msg.sender], "Already voted");

        // Check and get voting weight based on SBT holdings
        // Let's assume Governance votes use GovernanceSBT weight
        uint256 voterWeight = reputationSBT.balanceOf(msg.sender, uint256(SBTType.Governance)) * govParams.sbtVoteWeightMultiplier;

        // Check if delegation is used. If delegated, the delegatee votes, not the holder.
        // This requires checking if the caller *is* a delegatee for someone.
        // A simpler approach is to check if the caller holds the SBT themselves OR is a delegatee.
        // For now, let's keep it simple and require the caller to hold the SBT directly.
        // A full delegation system requires checking `reputationSBT.getDelegate(msg.sender, sbtType)`
        // and potentially getting delegated weight.
        require(voterWeight > 0, "Must hold relevant SBT to vote");


        vote.voted[msg.sender] = true;
        vote.votes[msg.sender] = _support; // Record vote choice

        if (_support) {
            vote.yesVotesWeight += voterWeight;
        } else {
            vote.noVotesWeight += voterWeight;
        }

        // Check if quorum and majority are met immediately (fast-track) or if vote period is over.
        // For simplicity, we'll check resolution only after the voting period ends or during execution.

        emit GovernanceVoteCast(_voteId, msg.sender, _support, voterWeight, block.timestamp);
    }

    /// @notice Executes the outcome of a successfully passed governance vote after the delay period.
    /// @param _voteId The ID of the vote to execute.
    function executeGovernanceVote(uint256 _voteId) external {
        GovernanceVote storage vote = governanceVotes[_voteId];
        require(vote.id != 0, "Vote does not exist");
        require(vote.state == GovernanceVoteState.Active || vote.state == GovernanceVoteState.Succeeded || vote.state == GovernanceVoteState.Failed, "Vote not in executable state");
        require(!vote.executed, "Vote already executed");
        require(block.timestamp > vote.endTimestamp, "Voting period not ended");

        // Calculate vote outcome *after* the voting period ends
        uint256 totalVotesWeight = vote.yesVotesWeight + vote.noVotesWeight;

        // Check quorum: Total votes cast must be >= Quorum threshold
        uint256 requiredQuorumWeight = (vote.totalSBTWeight * govParams.proposalVoteQuorumNumerator) / govParams.proposalVoteQuorumDenominator;
        bool quorumReached = totalVotesWeight >= requiredQuorumWeight;

        // Check majority: Yes votes > No votes AND Yes votes > 0
        bool majorityReached = vote.yesVotesWeight > vote.noVotesWeight; // Simple majority
        // A more complex majority could be required, e.g., 50% of *cast* votes + 1 or 60% of total possible weight.

        if (quorumReached && majorityReached) {
             vote.state = GovernanceVoteState.Succeeded;
             // Check execution delay
             require(block.timestamp >= vote.endTimestamp + govParams.voteExecutionDelay, "Execution delay period active");

             // Execute the vote action based on vote type
             _executeVoteAction(_voteId);

             vote.executed = true;
             emit GovernanceVoteExecuted(_voteId, GovernanceVoteState.Executed, block.timestamp);

        } else {
            vote.state = GovernanceVoteState.Failed;
             vote.executed = true; // Mark as executed even if failed to prevent re-execution attempts
            emit GovernanceVoteExecuted(_voteId, GovernanceVoteState.Failed, block.timestamp);
        }
    }

    // Internal function to handle vote execution logic
    function _executeVoteAction(uint256 _voteId) internal {
        GovernanceVote storage vote = governanceVotes[_voteId];
        require(vote.state == GovernanceVoteState.Succeeded && !vote.executed, "Vote not successful or already executed");

        if (vote.voteType == GovernanceVoteType.ProposeFunding) {
            Proposal storage proposal = proposals[vote.proposalId];
            require(proposal.state == ProposalState.Draft, "Proposal must be in Draft state for funding approval");
            proposal.state = ProposalState.Active; // Move from Draft to Active (now accepts funds)
            emit ProposalStateChanged(vote.proposalId, ProposalState.Active, block.timestamp);

        } else if (vote.voteType == GovernanceVoteType.ChangeParameter) {
            // Assuming `vote.data` contains the encoded call to `setGovernanceParameters`
            // This requires a more sophisticated governance module that can call arbitrary functions.
            // For this example, let's assume `data` encodes which parameter to change and its new value.
            // A safer approach would be dedicated vote types for specific parameter changes or
            // using a proxy pattern with an upgradeable governance contract.
             revert("ChangeParameter execution not fully implemented in this example");
             // Example (requires careful encoding/decoding):
             // (uint8 paramIndex, uint256 newValue) = abi.decode(vote.data, (uint8, uint256));
             // if (paramIndex == 0) govParams.minProposalFundingGoal = newValue;
             // ... etc ...
             // emit GovernanceParametersUpdated(block.timestamp);

        } else if (vote.voteType == GovernanceVoteType.AwardSBT) {
             // Assuming `vote.data` contains the encoded recipient address and SBT type/amount
              (address recipient, uint256 sbtType, uint256 amount) = abi.decode(vote.data, (address, uint256, uint256));
              awardSBT(recipient, sbtType, amount); // Call the internal awardSBT function
        } else if (vote.voteType == GovernanceVoteType.RevokeSBT) {
              (address holder, uint256 sbtType, uint256 amount) = abi.decode(vote.data, (address, uint256, uint256));
              revokeSBT(holder, sbtType, amount); // Call the internal revokeSBT function
        } else if (vote.voteType == GovernanceVoteType.WithdrawTreasury) {
             (address recipient, uint256 amount) = abi.decode(vote.data, (address, uint256));
             withdrawTreasury(recipient, amount); // Call the internal withdrawTreasury function
        }
        // Add more vote types as needed (e.g., MilestoneApproval votes could be a type here instead of separate flow)
    }


    /// @notice Allows addresses holding relevant SBTs to delegate their voting power.
    /// @param _sbtType The type of SBT to delegate.
    /// @param _delegatee The address to delegate voting power to.
    function delegateSBTVote(uint256 _sbtType, address _delegatee) external {
        // This calls the external SBT contract's delegation function
        reputationSBT.delegate(_sbtType, _delegatee);
        // Event is emitted by the SBT contract
    }

    /// @notice Awards a specific type of SBT to an address. Callable by Governance.
    /// @param _recipient The address to award the SBT to.
    /// @param _sbtType The type of SBT to award (from SBTType enum).
    /// @param _amount The number of SBTs to award (usually 1 for roles).
    function awardSBT(address _recipient, uint256 _sbtType, uint256 _amount) public onlyGovernance {
        require(_recipient != address(0), "Recipient cannot be zero address");
        // Validate _sbtType against expected values (e.g., > 0 and <= max defined type)
        require(_sbtType > 0 && _sbtType <= uint256(SBTType.Governance), "Invalid SBT type");

        // Call the external SBT contract's mint function
        reputationSBT.mint(_recipient, _sbtType, _amount);

        emit SBTawarded(_recipient, _sbtType, _amount, block.timestamp);
    }

     /// @notice Revokes a specific type of SBT from an address. Callable by Governance.
    /// @param _holder The address to revoke the SBT from.
    /// @param _sbtType The type of SBT to revoke.
    /// @param _amount The number of SBTs to revoke (usually 1).
    function revokeSBT(address _holder, uint256 _sbtType, uint256 _amount) public onlyGovernance {
        require(_holder != address(0), "Holder cannot be zero address");
        require(_sbtType > 0 && _sbtType <= uint256(SBTType.Governance), "Invalid SBT type");
        require(reputationSBT.balanceOf(_holder, _sbtType) >= _amount, "Holder does not have enough SBTs");

        // Call the external SBT contract's burn function
        reputationSBT.burn(_holder, _sbtType, _amount);

        emit SBTrevoked(_holder, _sbtType, _amount, block.timestamp);
    }


    /// @notice Allows the proposer to submit evidence for a completed milestone.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone (0-based).
    /// @param _evidenceHash IPFS hash of the milestone completion evidence.
    function submitMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, bytes32 _evidenceHash) external onlyProposer(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Funded, "Proposal not funded");
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        require(!proposal.milestones[_milestoneIndex].completed, "Milestone already marked complete");
        require(_evidenceHash != bytes32(0), "Evidence hash cannot be empty");

        proposal.milestones[_milestoneIndex].evidenceHash = _evidenceHash;
        proposal.milestones[_milestoneIndex].completed = true; // Marked by proposer
        // Reset approvals for this round of review
        delete proposal.milestones[_milestoneIndex].approvals;
        delete proposal.milestones[_milestoneIndex].currentReviewers; // Clear previous reviewers list
        proposal.milestones[_milestoneIndex].approvalCount = 0;

        // Start review period implicitly from now

        emit MilestoneSubmitted(_proposalId, _milestoneIndex, _evidenceHash, block.timestamp);
    }

     /// @notice Allows a Reviewer SBT holder to volunteer to review a specific milestone.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    function addReviewerToMilestone(uint256 _proposalId, uint256 _milestoneIndex) external onlyReviewerSBT {
         Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Funded, "Proposal not funded");
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        require(proposal.milestones[_milestoneIndex].completed, "Milestone not marked complete for review");

        // Check if sender is already reviewing
        bool isAlreadyReviewer = false;
        for(uint i = 0; i < proposal.milestones[_milestoneIndex].currentReviewers.length; i++) {
            if (proposal.milestones[_milestoneIndex].currentReviewers[i] == msg.sender) {
                isAlreadyReviewer = true;
                break;
            }
        }
        require(!isAlreadyReviewer, "Already reviewing this milestone");

        proposal.milestones[_milestoneIndex].currentReviewers.push(msg.sender);

        emit MilestoneReviewerAdded(_proposalId, _milestoneIndex, msg.sender, block.timestamp);
    }


    /// @notice Allows a designated reviewer to approve a milestone completion.
    /// Requires holding the ReviewerSBT and having added themselves to the milestone's reviewer list.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    function approveMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex) external onlyReviewerSBT {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Funded, "Proposal not funded");
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        require(proposal.milestones[_milestoneIndex].completed, "Milestone not marked complete for review");
        require(!proposal.milestones[_milestoneIndex].fundsReleased, "Milestone funds already released");

        // Check if sender is in the current reviewers list for this milestone
         bool isDesignatedReviewer = false;
        for(uint i = 0; i < proposal.milestones[_milestoneIndex].currentReviewers.length; i++) {
            if (proposal.milestones[_milestoneIndex].currentReviewers[i] == msg.sender) {
                isDesignatedReviewer = true;
                break;
            }
        }
        require(isDesignatedReviewer, "Not a designated reviewer for this milestone");


        require(!proposal.milestones[_milestoneIndex].approvals[msg.sender], "Already approved this milestone");

        proposal.milestones[_milestoneIndex].approvals[msg.sender] = true;
        proposal.milestones[_milestoneIndex].approvalCount++;

        // Check if approval threshold is met
        // Threshold is percentage of *current reviewers* who have approved
        uint256 totalReviewers = proposal.milestones[_milestoneIndex].currentReviewers.length;
        if (totalReviewers > 0) {
            uint256 requiredApprovals = (totalReviewers * govParams.milestoneReviewApprovalThresholdNumerator) / govParams.milestoneReviewApprovalThresholdDenominator;
            if (proposal.milestones[_milestoneIndex].approvalCount >= requiredApprovals) {
                 // Milestone is considered validated and ready for fund release
                 // We don't set a flag here, fund release function checks the count directly.
                 // This also allows adding more reviewers/approvals even after the threshold is met.
            }
        }


        emit MilestoneApproved(_proposalId, _milestoneIndex, msg.sender, proposal.milestones[_milestoneIndex].approvalCount, block.timestamp);
    }


    /// @notice Releases funds for a milestone that has been completed and approved by reviewers.
    /// Can be called by anyone after the approval threshold is met and review period (optional check) is over.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    function releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Funded, "Proposal not in Funded state");
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        require(milestone.completed, "Milestone not marked complete");
        require(!milestone.fundsReleased, "Milestone funds already released");

        // Check approval threshold against current reviewers
        uint256 totalReviewers = milestone.currentReviewers.length;
        require(totalReviewers > 0, "No reviewers added to this milestone"); // Need at least one reviewer
        uint256 requiredApprovals = (totalReviewers * govParams.milestoneReviewApprovalThresholdNumerator) / govParams.milestoneReviewApprovalThresholdDenominator;
        require(milestone.approvalCount >= requiredApprovals, "Milestone approval threshold not met");

        // Optionally check if review period has passed (implies reviewers had enough time)
        // This requires tracking when the proposer submitted evidence.
        // For simplicity, let's rely just on the approval threshold for now.

        // Calculate amount to release
        uint256 amountToRelease = (proposal.fundingGoal * milestone.percentageOfFunding) / 100;
        // Ensure we don't overspend if total funded is less than goal (partial funding scenario)
        // This requires careful handling. Let's assume full funding for simplicity in calculations,
        // but in reality, distribution would need to be proportional to `totalFunded`.
        // Simple approach: if totalFunded < fundingGoal, scale the amount proportionally.
        if (proposal.totalFunded < proposal.fundingGoal) {
             amountToRelease = (proposal.totalFunded * milestone.percentageOfFunding) / 100;
        }
         // Ensure enough balance in the contract to cover this payment for this proposal
        // A dedicated balance tracker per proposal is needed, or funds must stay in a single treasury.
        // Let's assume funds are managed within this contract's balance, tracked per proposal.
        // This requires a mapping like `mapping(uint256 => uint256) proposalBalances;`
        // and updating it in `fundProposal`.
        // For this simplified example, let's assume the contract has the total `proposal.totalFunded` balance.
        // A check would be `address(this).balance >= amountToRelease` IF funds were pooled.
        // If funds are earmarked per proposal conceptually, this check is trickier.
        // Revert to the simpler model: funds are in the contract balance, tracked conceptually per proposal.
        // We need to ensure we don't release more than funded *in total* for the proposal.
        uint256 maxReleasePossible = proposal.totalFunded - proposal.totalReleased;
        amountToRelease = Math.min(amountToRelease, maxReleasePossible); // Prevent over-releasing

        require(amountToRelease > 0, "No funds to release for this milestone");


        milestone.fundsReleased = true;
        proposal.totalReleased += amountToRelease;

        // Transfer funds to the proposer
        (bool success, ) = payable(proposal.proposer).call{value: amountToRelease}("");
        require(success, "Transfer failed");

        // If all milestones are completed and funds released, mark proposal as Completed
        bool allMilestonesCompleted = true;
        for(uint i = 0; i < proposal.milestones.length; i++) {
            if (!proposal.milestones[i].fundsReleased) {
                allMilestonesCompleted = false;
                break;
            }
        }
        if (allMilestonesCompleted) {
            proposal.state = ProposalState.Completed;
            emit ProposalStateChanged(_proposalId, ProposalState.Completed, block.timestamp);
        }


        emit MilestoneFundsReleased(_proposalId, _milestoneIndex, amountToRelease, block.timestamp);
    }

    /// @notice Allows the proposer of a completed/funded project to register the final IP hash.
    /// @param _proposalId The ID of the proposal.
    /// @param _ipHash The IPFS hash of the final results/IP.
    function registerProjectIP(uint256 _proposalId, bytes32 _ipHash) external onlyProposer(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Completed, "Proposal must be in Completed state");
        require(proposal.finalIPHash == bytes32(0), "IP already registered");
        require(_ipHash != bytes32(0), "IP hash cannot be empty");

        proposal.finalIPHash = _ipHash;

        emit IPRegistered(_proposalId, _ipHash, block.timestamp);
    }

     /// @notice Allows governance to mint an IP NFT for a project with registered IP.
     /// Requires interaction with an external IIPNFT contract.
    /// @param _proposalId The ID of the proposal.
    /// @param _recipient The address to receive the IP NFT.
    function mintIPNFT(uint256 _proposalId, address _recipient) external onlyGovernance {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Completed, "Proposal must be in Completed state");
        require(proposal.finalIPHash != bytes32(0), "IP not registered for this project");
        require(_recipient != address(0), "Recipient cannot be zero address");

        // Call the external IP NFT contract to mint the NFT
        uint256 tokenId = ipNFT.mint(_recipient, proposal.finalIPHash, _proposalId);

        // Optional: Mark the proposal as having had its IP tokenized to prevent double minting
        // This might require adding a flag to the Proposal struct.

        emit IPNFTMinted(_proposalId, tokenId, _recipient, proposal.finalIPHash, block.timestamp);
    }

    /// @notice Allows anyone to deposit ETH into the main DAO treasury.
    function depositTreasury() external payable {
        require(msg.value > 0, "Must send non-zero ETH");
        // Funds are sent directly to the treasury address set in the constructor
        (bool success, ) = payable(treasury).call{value: msg.value}("");
        require(success, "Treasury deposit failed"); // Should not fail if treasury is a standard address

        emit TreasuryDeposited(msg.sender, msg.value, block.timestamp);
    }

     /// @notice Allows withdrawal from the main DAO treasury based on a successful governance vote.
     /// Note: This function is marked public, but should ideally only be called by `_executeVoteAction`
     /// after a `WithdrawTreasury` vote passes. Making it public for demonstration under `onlyGovernance`.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawTreasury(address _recipient, uint256 _amount) public onlyGovernance {
        require(_recipient != address(0), "Recipient cannot be zero address");
        // If treasury is THIS contract, use address(this).balance
        // If treasury is an external address, this function needs permission/role on that external contract.
        // Assuming treasury is THIS contract's balance for simplicity:
        require(address(this).balance >= _amount, "Insufficient treasury balance");

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Treasury withdrawal failed");

        emit TreasuryWithdrawn(_recipient, _amount, block.timestamp);
    }


    // --- View Functions ---

    /// @notice Gets details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The Proposal struct details.
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        return proposals[_proposalId];
    }

    /// @notice Lists all proposal IDs. (Simple version, pagination needed for many proposals)
    /// @return An array of all proposal IDs.
    function listProposals() external view returns (uint256[] memory) {
        uint256 count = nextProposalId - 1;
        uint256[] memory proposalIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            proposalIds[i] = i + 1;
        }
        return proposalIds;
    }

    /// @notice Gets the state and results of a specific governance vote.
    /// @param _voteId The ID of the vote.
    /// @return voteState, yesVotesWeight, noVotesWeight, totalSBTWeight, startTimestamp, endTimestamp, executed
    function getGovernanceVoteState(uint256 _voteId) external view returns (
        GovernanceVoteState voteState,
        uint256 yesVotesWeight,
        uint256 noVotesWeight,
        uint256 totalSBTWeight,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool executed
    ) {
        GovernanceVote storage vote = governanceVotes[_voteId];
        require(vote.id != 0, "Vote does not exist");
        return (
            vote.state,
            vote.yesVotesWeight,
            vote.noVotesWeight,
            vote.totalSBTWeight,
            vote.startTimestamp,
            vote.endTimestamp,
            vote.executed
        );
    }

    /// @notice Gets the current governance parameters.
    /// @return The GovernanceParameters struct.
    function getGovernanceParameters() external view returns (GovernanceParameters memory) {
        return govParams;
    }

    /// @notice Checks the balance/holding of a specific SBT type for an address.
    /// @param _holder The address to check.
    /// @param _sbtType The type of SBT (from SBTType enum).
    /// @return The balance of the specified SBT type for the holder.
    function getSBTBalance(address _holder, uint256 _sbtType) external view returns (uint256) {
        require(_holder != address(0), "Holder cannot be zero address");
         require(_sbtType > 0 && _sbtType <= uint256(SBTType.Governance), "Invalid SBT type");
        return reputationSBT.balanceOf(_holder, _sbtType);
    }

     /// @notice Checks if an address holds at least one of a specific SBT type.
    /// @param _holder The address to check.
    /// @param _sbtType The type of SBT (from SBTType enum).
    /// @return True if the holder has at least one SBT of the specified type, false otherwise.
    function isHoldingSBT(address _holder, uint256 _sbtType) public view returns (bool) {
         require(_holder != address(0), "Holder cannot be zero address");
         require(_sbtType > 0 && _sbtType <= uint256(SBTType.Governance), "Invalid SBT type");
        return reputationSBT.balanceOf(_holder, _sbtType) > 0;
    }


    /// @notice Gets the registered IP hash for a completed project.
    /// @param _proposalId The ID of the proposal.
    /// @return The IPFS hash. Returns bytes32(0) if not registered.
    function getProjectIPHash(uint256 _proposalId) external view returns (bytes32) {
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        return proposals[_proposalId].finalIPHash;
    }

    /// @notice Gets the state details of a specific milestone within a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    /// @return evidenceHash, completed, approvalCount, fundsReleased
    function getMilestoneState(uint256 _proposalId, uint256 _milestoneIndex) external view returns (
        bytes32 evidenceHash,
        bool completed,
        uint256 approvalCount,
        bool fundsReleased
    ) {
         Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        return (
            milestone.evidenceHash,
            milestone.completed,
            milestone.approvalCount,
            milestone.fundsReleased
        );
    }

     /// @notice Gets the list of addresses currently reviewing a specific milestone.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    /// @return An array of reviewer addresses.
    function getMilestoneReviewers(uint256 _proposalId, uint256 _milestoneIndex) external view returns (address[] memory) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        return proposal.milestones[_milestoneIndex].currentReviewers;
    }

    /// @notice Gets the number of approvals for a specific milestone.
    /// @param _proposalId The ID of the proposal.
    /// @param _milestoneIndex The index of the milestone.
    /// @return The current approval count.
    function getMilestoneApprovals(uint256 _proposalId, uint256 _milestoneIndex) external view returns (uint256) {
         Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(_milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        return proposal.milestones[_milestoneIndex].approvalCount;
    }

    /// @notice Gets the total funds raised for a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The total amount funded.
    function getTotalFundsRaisedForProposal(uint256 _proposalId) external view returns (uint256) {
         require(proposals[_proposalId].id != 0, "Proposal does not exist");
        return proposals[_proposalId].totalFunded;
    }

     /// @notice Gets the total funds released for a proposal based on completed milestones.
    /// @param _proposalId The ID of the proposal.
    /// @return The total amount released.
    function getFundsReleasedForProposal(uint256 _proposalId) external view returns (uint256) {
         require(proposals[_proposalId].id != 0, "Proposal does not exist");
        return proposals[_proposalId].totalReleased;
    }

    // --- Helper Libraries ---
    // Using OpenZeppelin's Math library for min/max if needed, or implement simply.
    // Add using statements if importing external libraries like SafeMath or Math.
    // For simplicity, implementing Math.min directly here.
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
    using Math for uint256;

    // Fallback function to accept ETH for treasury deposit
    receive() external payable {
        depositTreasury();
    }
}
```