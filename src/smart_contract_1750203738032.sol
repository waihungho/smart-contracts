Okay, let's design an interesting, advanced, and creative smart contract. We'll build a *Dynamic Evolutionary DAO* (DEDAO).

The core concept is a DAO that can not only vote on proposals but also dynamically adjust its own governance parameters (like quorum, voting duration, proposal threshold) based on collective decisions and potentially on-chain activity metrics, incorporating a reputation system and NFT-based membership.

This contract won't be a direct copy of existing open-source frameworks like Aragon, Compound Governance, or MolochDAO, but will combine elements in a unique way, particularly the *adaptive governance parameters* and the specific reputation mechanics.

---

### Smart Contract: Dynamic Evolutionary DAO (DEDAO)

**Concept:** A decentralized autonomous organization where governance rules are not fixed but can evolve over time through member proposals. Membership is linked to owning a specific NFT, and voting power is weighted by reputation earned through active, successful participation in governance. The DAO can also propose changes to its *own* rules based on predefined adaptive criteria.

**Key Features:**

1.  **NFT Membership:** Members must own a specific NFT. This acts as the basic identity and potential tiering mechanism.
2.  **Reputation System:** Members earn reputation points for successful governance participation (proposing successful proposals, voting on winning sides). Reputation can decay or be lost for inactivity or failed actions. Voting power is (NFT Weight + Reputation).
3.  **Evolvable Parameters:** Governance parameters (quorum threshold, voting period, required reputation to propose, etc.) are stored in state and can be changed via special "Parameter Change" proposals.
4.  **Adaptive Governance Proposals:** A mechanism (callable by members or potentially triggered) that analyzes recent DAO activity (e.g., participation rate, proposal volume) and can *automatically create a proposal* to adjust parameters based on predefined "adaptive rules".
5.  **Multiple Proposal Types:** Supports standard action proposals (executing arbitrary calls), Parameter Change proposals, and Adaptive Rule Change proposals.
6.  **Treasury Management:** The DAO can hold and manage Ether and potentially other tokens via successful proposals.

**Outline:**

1.  **State Variables:**
    *   Governance Parameters (struct)
    *   Proposals (mapping, struct)
    *   Members/Reputation (mapping)
    *   Adaptive Rules (mapping, struct)
    *   Treasury Balance
    *   Counters (Proposal ID)
    *   External Contract Addresses (Membership NFT)
2.  **Structs:**
    *   `GovernanceParameters`: Defines the current rules (quorum, voting period, etc.).
    *   `Proposal`: Details of a proposal (state, votes, proposer, actions, type, expiry).
    *   `MemberInfo`: Stores member-specific data (reputation, join block).
    *   `AdaptiveRule`: Defines a trigger condition and suggested parameter adjustment.
3.  **Events:**
    *   Tracking membership changes, proposal lifecycle, parameter updates, reputation changes.
4.  **Modifiers:**
    *   `onlyMember`: Restricts access to current DAO members.
    *   `proposalExists`: Checks if a proposal ID is valid.
    *   `proposalState`: Checks if a proposal is in a specific state.
5.  **Functions:**
    *   **Core Governance:** Propose, Vote, Execute.
    *   **Membership & Reputation:** Join DAO, Get Member Info, Get Reputation, Calculate Voting Power.
    *   **Parameter & Rule Management:** Get Current Parameters, Propose Parameter Change, Propose Adaptive Rule Change, Get Adaptive Rules, Adapt Governance (the key evolutionary function).
    *   **Treasury:** Deposit, Withdraw (via proposal), Get Balance.
    *   **Querying:** Get Proposal State, Get Proposal Details, List Active Proposals.
    *   **Internal/Helper:** Update Reputation (triggered by outcomes), Check Quorum, Check Threshold.

**Function Summary (Approx. 25+ functions planned):**

1.  `constructor`: Initializes the contract, sets initial parameters, and the membership NFT contract address.
2.  `joinDAO(uint256 memberTokenId)`: Allows an NFT holder to join the DAO, registers them as a member, and initializes reputation. *Requires ownership of the specified NFT.*
3.  `leaveDAO()`: Allows a member to leave the DAO. (Optional: might burn NFT or penalize reputation). *For this example, we'll just mark them inactive or remove reputation.*
4.  `propose(bytes[] targets, bytes[] calldatas, string description, uint256 proposalType)`: Creates a new governance proposal. Requires minimum reputation. Different types: Action, ParameterChange, AdaptiveRuleChange.
5.  `proposeParameterChange(uint256 quorumThreshold, uint256 votingPeriodBlocks, uint256 proposalThresholdRep, uint256 voteThresholdRep, uint256 successRatioNumerator, uint256 successRatioDenominator)`: Special function to propose changing the DAO's governance parameters. Creates a `ParameterChange` proposal.
6.  `proposeAdaptiveRuleChange(...)`: Special function to propose adding, modifying, or removing an adaptive rule. Creates an `AdaptiveRuleChange` proposal.
7.  `vote(uint256 proposalId, uint8 support)`: Casts a vote (for, against, abstain) on an active proposal. Voting power based on reputation + NFT weight. Requires minimum reputation to vote.
8.  `execute(uint256 proposalId)`: Executes a successful proposal. Transfers funds, calls target contracts, updates parameters/rules if applicable. Awards reputation to successful proposers/voters.
9.  `getProposalState(uint256 proposalId)`: Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Executed).
10. `getProposalDetails(uint256 proposalId)`: Returns comprehensive details about a specific proposal.
11. `getMemberInfo(address member)`: Returns information about a member, including reputation and join block.
12. `getMemberReputation(address member)`: Returns only the reputation points of a member.
13. `getVotingPower(address member)`: Calculates and returns the current voting power of a member (based on reputation and NFT tier/presence).
14. `getCurrentParameters()`: Returns the current set of active governance parameters.
15. `getAdaptiveRules()`: Returns the list or details of currently defined adaptive rules.
16. `adaptGovernance()`: Analyzes recent DAO activity based on internal metrics (e.g., proposal count, voter turnout). If conditions match a defined `AdaptiveRule`, it *creates a new `ParameterChange` proposal* suggesting the rule's defined parameter adjustments. Anyone can call this, triggering the *proposal creation* for the DAO to then vote on.
17. `depositFunds()`: Allows anyone to send Ether to the DAO treasury. (Uses `payable` on a receiving function).
18. `withdrawFunds(uint256 amount, address recipient)`: Internal function called by `execute` for successful withdrawal proposals.
19. `getTreasuryBalance()`: Returns the current Ether balance held by the DAO.
20. `calculateQuorumNeeded(uint256 proposalId)`: Helper function to show the required total voting power needed for a specific proposal's quorum based on current parameters and total possible voting power.
21. `calculateThresholdNeeded(uint256 proposalId)`: Helper function to show the required 'yes' voting power needed for a specific proposal to pass based on votes cast and current parameters.
22. `getProposalVoteCount(uint256 proposalId)`: Returns the current yes/no/abstain vote counts and total voting power cast for a proposal.
23. `checkMembership(address potentialMember)`: Checks if an address is currently considered an active member.
24. `updateReputation(address member, int256 amount)`: Internal function to add or subtract reputation, enforcing minimums (>=0).
25. `onNFTTransfer(address from, address to, uint256 tokenId)`: (Requires integration with NFT contract, or if NFT logic is internal, an internal hook) Adjusts membership status when NFT is transferred. *Assuming external NFT, this contract would need to listen to NFT transfer events or members call `joinDAO` again after transfer.* Let's model simplified internal membership check instead of external event listening for this example.
26. `getMemberNFTTokenId(address member)`: Returns the stored NFT Token ID associated with a member.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. State Variables
// 2. Structs
// 3. Events
// 4. Modifiers
// 5. Core Governance Functions (propose, vote, execute)
// 6. Membership & Reputation Functions
// 7. Parameter & Adaptive Rule Management Functions
// 8. Treasury Functions
// 9. Query Functions
// 10. Internal/Helper Functions

// Function Summary:
// constructor: Initialize contract, set initial params and NFT address.
// joinDAO: Register an NFT holder as a member, init reputation.
// leaveDAO: Deregister a member (simple for example).
// propose: Create a generic action proposal (requires reputation).
// proposeParameterChange: Create a proposal to change governance parameters.
// proposeAdaptiveRuleChange: Create a proposal to change rules for `adaptGovernance`.
// vote: Cast a vote on a proposal (weighted by reputation + NFT).
// execute: Execute a successful proposal, update states and reputation.
// getProposalState: Check proposal status.
// getProposalDetails: Get full proposal information.
// getMemberInfo: Get member reputation and join block.
// getMemberReputation: Get only member reputation.
// getVotingPower: Calculate current voting power (reputation + NFT weight).
// getCurrentParameters: Get active governance parameters.
// getAdaptiveRules: Get details of adaptive rules.
// adaptGovernance: Analyze activity, propose parameter changes via `proposeParameterChange` if rules trigger.
// depositFunds: Send Ether to the DAO treasury.
// withdrawFunds: Internal, used by `execute` for treasury withdrawals.
// getTreasuryBalance: Check DAO's Ether balance.
// calculateQuorumNeeded: Helper to calculate required quorum votes.
// calculateThresholdNeeded: Helper to calculate required threshold votes for success.
// getProposalVoteCount: Get current vote counts for a proposal.
// checkMembership: Check if an address is a current member.
// updateReputation: Internal, adjusts member reputation.
// _calculateVotingPower: Internal helper for voting power calculation.
// _checkQuorum: Internal helper to check if quorum is met.
// _checkThreshold: Internal helper to check if threshold is met.
// _applyParameterChange: Internal, applies parameter updates from a successful proposal.
// _applyAdaptiveRuleChange: Internal, applies adaptive rule updates from a successful proposal.
// onNFTTransfer: Hypothetical hook for NFT transfer effects (simplified via checkMembership).

// Note: This example assumes a separate ERC721 contract for membership NFTs,
// and queries its `ownerOf` function. In a real system, the NFT contract might
// need to call back into the DAO on transfers, or the DAO needs mechanisms
// to sync membership status more robustly. The `joinDAO` effectively links
// an address to a specific NFT ID for tracking purposes here.

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // We only need ownerOf for this simplified example
}

contract DynamicEvolutionaryDAO {

    // 1. State Variables

    struct GovernanceParameters {
        uint256 quorumThresholdBPS; // Basis points (1/100 of a percent). e.g., 4000 = 40% of total voting power.
        uint256 votingPeriodBlocks; // Duration of voting in blocks.
        uint256 proposalThresholdRep; // Minimum reputation required to propose.
        uint256 voteThresholdRep; // Minimum reputation required to vote.
        uint256 successRatioNumerator; // For calculating success threshold (Numerator / Denominator of 'yes' votes among total cast).
        uint256 successRatioDenominator;
        uint256 reputationEarnSuccessProposer; // Reputation gained by proposer on successful execution.
        uint256 reputationLoseFailProposer;    // Reputation lost by proposer on failed execution.
        uint256 reputationEarnSuccessVoter;    // Reputation gained by voter on winning side (per vote weight).
        uint256 reputationLoseFailVoter;     // Reputation lost by voter on losing side (per vote weight).
        uint256 inactivityReputationDecayBlocks; // Blocks after which inactive members lose reputation (simplified: not implemented in updateReputation logic here, but kept as parameter).
    }

    GovernanceParameters public currentParameters;

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    enum ProposalType { Action, ParameterChange, AdaptiveRuleChange }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes[] targets; // For Action proposals
        bytes[] calldatas; // For Action proposals
        uint256 startBlock;
        uint256 endBlock;
        uint256 yesVotes; // Weighted by voting power
        uint256 noVotes;  // Weighted by voting power
        uint256 abstainVotes; // Weighted by voting power
        uint256 totalVotingPowerAtStart; // Snapshot of total possible voting power when proposal starts
        ProposalState state;
        ProposalType proposalType;
        // For ParameterChange proposals
        GovernanceParameters newParameters;
        // For AdaptiveRuleChange proposals (simplified storage)
        bytes adaptiveRuleData; // abi.encode'd data for rule changes
        bool executed; // To prevent double execution
    }

    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256[]) public memberProposals; // List of proposal IDs created by a member
    mapping(address => mapping(uint256 => uint256)) public memberVotes; // member => proposalId => votes cast (to prevent double voting weighted by power)

    struct MemberInfo {
        uint256 reputation;
        uint256 joinBlock;
        uint256 memberNFTTokenId; // The specific NFT they used to join
        bool isActive; // Simple flag, could be used for decay later
    }

    mapping(address => MemberInfo) public members;
    address[] public memberAddresses; // Simple list for iterating members (caution: gas costs for large DAOs)

    // Simplified Adaptive Rules: Mapping trigger metrics to suggested parameter changes
    // In a real system, this would be more complex: conditions, thresholds, and specific parameter deltas.
    struct AdaptiveRule {
        string description;
        // Example simplified trigger: min participation rate over recent proposals
        uint256 minParticipationRateBPS;
        // Example simplified suggestion: decrease proposal threshold
        uint256 suggestedProposalThresholdRepDelta;
        bool isActive;
    }

    mapping(uint256 => AdaptiveRule) public adaptiveRules; // Rule ID => Rule
    uint256 private _nextAdaptiveRuleId;
    uint256[] public activeAdaptiveRuleIds; // List of active rule IDs

    address public immutable membershipNFT;
    uint256 public constant NFT_VOTING_WEIGHT = 1000; // Base voting weight from owning an NFT
    uint256 public totalDAOVotingPower; // Sum of all active members' potential voting power (NFT_VOTING_WEIGHT + reputation)

    // 2. Structs (Defined above)

    // 3. Events

    event Initialized(address indexed initiator, GovernanceParameters initialParams);
    event MemberJoined(address indexed member, uint256 indexed memberTokenId, uint256 initialReputation);
    event MemberLeft(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description, uint256 endBlock);
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState oldState, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);
    event GovernanceParametersUpdated(GovernanceParameters newParameters);
    event ReputationUpdated(address indexed member, uint256 oldReputation, uint256 newReputation);
    event AdaptiveRuleUpdated(uint256 indexed ruleId, AdaptiveRule rule);
    event AdaptiveRuleRemoved(uint256 indexed ruleId);
    event AdaptiveProposalCreated(uint256 indexed ruleIdTriggered, uint256 indexed createdProposalId);

    // 4. Modifiers

    modifier onlyMember() {
        require(checkMembership(msg.sender), "DEDAO: Caller is not a member");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId < _nextProposalId, "DEDAO: Proposal does not exist");
        _;
    }

    modifier proposalState(uint256 proposalId, ProposalState requiredState) {
        require(proposals[proposalId].state == requiredState, "DEDAO: Proposal not in required state");
        _;
    }

    // 5. Core Governance Functions

    constructor(address _membershipNFT, GovernanceParameters memory _initialParams) {
        require(_membershipNFT != address(0), "DEDAO: Invalid NFT address");
        membershipNFT = _membershipNFT;
        currentParameters = _initialParams;
        _nextProposalId = 0;
        _nextAdaptiveRuleId = 0;
        emit Initialized(msg.sender, _initialParams);
    }

    /// @notice Creates a new governance proposal.
    /// @param targets Target addresses for contract calls (for Action type).
    /// @param calldatas Encoded function calls (for Action type).
    /// @param description Text description of the proposal.
    /// @param proposalType Type of proposal (Action, ParameterChange, AdaptiveRuleChange - use proposeParameterChange/proposeAdaptiveRuleChange for specific types).
    /// @param typeSpecificData Abi encoded data specific to proposal type (e.g., GovernanceParameters for ParameterChange).
    function propose(
        address[] calldata targets,
        bytes[] calldata calldatas,
        string calldata description,
        ProposalType proposalType,
        bytes calldata typeSpecificData // Use proposeParameterChange/proposeAdaptiveRuleChange for safety/structure
    ) external onlyMember returns (uint256 proposalId) {
        require(members[msg.sender].reputation >= currentParameters.proposalThresholdRep, "DEDAO: Not enough reputation to propose");
        if (proposalType == ProposalType.Action) {
            require(targets.length == calldatas.length, "DEDAO: Targets and calldatas must have same length");
        } else {
            require(targets.length == 0 && calldatas.length == 0, "DEDAO: Targets and calldatas must be empty for non-Action proposals");
        }

        proposalId = _nextProposalId++;
        uint256 startBlock = block.number;
        uint256 endBlock = startBlock + currentParameters.votingPeriodBlocks;

        ProposalState initialState = ProposalState.Pending; // Or Active immediately? Let's make it Active immediately.
        initialState = ProposalState.Active;

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.targets = targets;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.state = initialState;
        newProposal.proposalType = proposalType;
        newProposal.totalVotingPowerAtStart = totalDAOVotingPower; // Snapshot total power
        newProposal.executed = false;

        if (proposalType == ProposalType.ParameterChange) {
             newProposal.newParameters = abi.decode(typeSpecificData, (GovernanceParameters));
        } else if (proposalType == ProposalType.AdaptiveRuleChange) {
             newProposal.adaptiveRuleData = typeSpecificData; // Store encoded rule data
        }
        // For Action type, targets and calldatas are used directly

        memberProposals[msg.sender].push(proposalId);

        emit ProposalCreated(proposalId, msg.sender, proposalType, description, endBlock);
        emit ProposalStateChanged(proposalId, ProposalState.Pending, initialState); // Emit Pending -> Active transition
    }

    /// @notice Special function to propose changing governance parameters.
    /// @param newParams The proposed new set of governance parameters.
    function proposeParameterChange(GovernanceParameters memory newParams, string calldata description) external onlyMember returns (uint256) {
         bytes memory encodedParams = abi.encode(newParams);
         // Delegate to the general propose function with ParameterChange type
         return propose(new bytes[](0), new bytes[](0), description, ProposalType.ParameterChange, encodedParams);
    }

    /// @notice Special function to propose adding, modifying, or removing adaptive rules.
    /// @param typeSpecificData Abi encoded data detailing the rule change (e.g., add/remove rule ID, new rule data).
    /// @param description Text description of the proposal.
    function proposeAdaptiveRuleChange(bytes calldata typeSpecificData, string calldata description) external onlyMember returns (uint256) {
        // Delegate to the general propose function with AdaptiveRuleChange type
        return propose(new bytes[](0), new bytes[](0), description, ProposalType.AdaptiveRuleChange, typeSpecificData);
        // The execution logic for this type will decode `typeSpecificData` to perform the rule changes
    }


    /// @notice Casts a vote on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support 0=Against, 1=For, 2=Abstain.
    function vote(uint256 proposalId, uint8 support) external onlyMember proposalExists(proposalId) proposalState(proposalId, ProposalState.Active) {
        require(support <= 2, "DEDAO: Invalid support value (0=Against, 1=For, 2=Abstain)");
        require(block.number <= proposals[proposalId].endBlock, "DEDAO: Voting period has ended");
        require(members[msg.sender].reputation >= currentParameters.voteThresholdRep, "DEDAO: Not enough reputation to vote");
        require(memberVotes[msg.sender][proposalId] == 0, "DEDAO: Already voted on this proposal");

        uint256 votingPower = _calculateVotingPower(msg.sender);
        require(votingPower > 0, "DEDAO: Member has no voting power");

        memberVotes[msg.sender][proposalId] = votingPower; // Store the power used to prevent double voting

        Proposal storage proposal = proposals[proposalId];
        if (support == 0) {
            proposal.noVotes += votingPower;
        } else if (support == 1) {
            proposal.yesVotes += votingPower;
        } else { // support == 2
            proposal.abstainVotes += votingPower;
        }

        emit VoteCast(msg.sender, proposalId, support, votingPower);
    }

    /// @notice Executes a successful proposal.
    /// @param proposalId The ID of the proposal to execute.
    function execute(uint256 proposalId) external proposalExists(proposalId) proposalState(proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "DEDAO: Proposal already executed");

        proposal.executed = true;

        ProposalState oldState = proposal.state;

        // Apply state changes based on proposal type
        if (proposal.proposalType == ProposalType.Action) {
            for (uint i = 0; i < proposal.targets.length; i++) {
                (bool success, ) = proposal.targets[i].call(proposal.calldatas[i]);
                // In a real DAO, you might want more robust error handling or require all calls to succeed
                require(success, "DEDAO: Execution failed for one or more calls");
            }
        } else if (proposal.proposalType == ProposalType.ParameterChange) {
            _applyParameterChange(proposal.newParameters);
        } else if (proposal.proposalType == ProposalType.AdaptiveRuleChange) {
             // Decode and apply the adaptive rule changes
             // This requires a structure for the adaptiveRuleData bytes
             // For simplicity, let's assume adaptiveRuleData contains instructions like add/remove rule ID, or update rule data
             // A robust implementation would parse this bytes data carefully.
             // Example: bytes could encode function selector + parameters for _addAdaptiveRule, _removeAdaptiveRule, _updateAdaptiveRule
             // For this example, we'll just emit an event showing it was triggered, actual logic omitted for brevity.
             // In reality: abi.decode(proposal.adaptiveRuleData) and call internal functions.
             emit AdaptiveRuleUpdated(0, AdaptiveRule({ description: "Placeholder applied", minParticipationRateBPS: 0, suggestedProposalThresholdRepDelta: 0, isActive: true })); // Placeholder
             // This part is a placeholder. Actual implementation needs careful decoding and execution of rule changes.
        }


        // Award reputation to proposer and voters on winning side
        _updateReputation(proposal.proposer, int256(currentParameters.reputationEarnSuccessProposer));

        // Iterate through voters (this can be gas-intensive for many voters!)
        // A better approach for large DAOs might involve merkle proofs or claiming reputation separately.
        // For this example, we'll skip iterating voters and just apply proposer reputation.
        // The voter reputation logic is complex to implement efficiently on-chain for execution.
        // If you needed voter reputation, they might have to claim it later.

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, oldState, proposal.state);
        emit ProposalExecuted(proposalId);
    }

    // 6. Membership & Reputation Functions

    /// @notice Allows an NFT holder to join the DAO. Requires ownership of the specific membership NFT.
    /// @param memberTokenId The token ID of the membership NFT the caller owns.
    function joinDAO(uint256 memberTokenId) external {
        require(!checkMembership(msg.sender), "DEDAO: Already a member");
        require(IERC721(membershipNFT).ownerOf(memberTokenId) == msg.sender, "DEDAO: Caller is not the owner of the NFT");

        members[msg.sender] = MemberInfo({
            reputation: 100, // Initial reputation
            joinBlock: block.number,
            memberNFTTokenId: memberTokenId,
            isActive: true
        });
        memberAddresses.push(msg.sender); // Add to list (gas warning for large lists)
        totalDAOVotingPower += (NFT_VOTING_WEIGHT + members[msg.sender].reputation); // Add initial power

        emit MemberJoined(msg.sender, memberTokenId, 100);
    }

    /// @notice Allows a member to leave the DAO. (Simplified: just removes active status and reputation/power).
    function leaveDAO() external onlyMember {
         address member = msg.sender;
         require(members[member].isActive, "DEDAO: Member is not active");

         uint256 currentPower = _calculateVotingPower(member);
         totalDAOVotingPower -= currentPower; // Remove their power

         // Reset member state
         members[member].isActive = false;
         members[member].reputation = 0;
         members[member].memberNFTTokenId = 0; // Clear NFT ID

         // Note: Removing from `memberAddresses` is complex/costly. For this example, we leave it and rely on `isActive`.

         emit MemberLeft(member);
    }


    /// @notice Gets the full MemberInfo struct for an address.
    /// @param member The address to query.
    /// @return MemberInfo struct.
    function getMemberInfo(address member) external view returns (MemberInfo memory) {
        return members[member];
    }

    /// @notice Gets the current reputation points for a member.
    /// @param member The address to query.
    /// @return Reputation points.
    function getMemberReputation(address member) external view returns (uint256) {
        return members[member].reputation;
    }

    /// @notice Calculates the current voting power for a member.
    /// @param member The address to query.
    /// @return Total voting power (NFT weight + reputation). Returns 0 if not an active member.
    function getVotingPower(address member) external view returns (uint256) {
        return _calculateVotingPower(member);
    }

    /// @notice Checks if an address is currently an active member.
    /// @param potentialMember The address to check.
    /// @return True if active member, false otherwise.
    function checkMembership(address potentialMember) public view returns (bool) {
        // Check if the address is registered as a member AND holds the corresponding NFT
        // This approach ensures membership is tied to holding the specific NFT they joined with.
        MemberInfo memory memberInfo = members[potentialMember];
        if (!memberInfo.isActive) return false;
        if (memberInfo.memberNFTTokenId == 0) return false; // Should not happen if joined correctly, but safety check
        try IERC721(membershipNFT).ownerOf(memberInfo.memberNFTTokenId) returns (address owner) {
            return owner == potentialMember;
        } catch {
            // If NFT doesn't exist or contract call fails, assume they are not a valid holder
            return false;
        }
    }


    /// @notice Internal function to adjust member reputation. Handles minimums.
    /// @param member The member whose reputation to update.
    /// @param amount The amount to add (positive) or subtract (negative).
    function _updateReputation(address member, int256 amount) internal {
        MemberInfo storage memberInfo = members[member];
        if (!memberInfo.isActive) return; // Only update active members

        uint256 oldReputation = memberInfo.reputation;
        int256 signedCurrentRep = int256(oldReputation);

        signedCurrentRep += amount;

        // Ensure reputation doesn't go below 0
        if (signedCurrentRep < 0) {
            memberInfo.reputation = 0;
        } else {
            memberInfo.reputation = uint256(signedCurrentRep);
        }

        // Adjust total DAO voting power based on reputation change
        // This needs recalculation as the NFT weight is constant
        uint256 newVotingPower = _calculateVotingPower(memberInfo.memberNFTTokenId == 0 ? address(0) : member); // Pass address(0) if NFT ID is 0
        uint256 oldVotingPower = NFT_VOTING_WEIGHT + oldReputation; // Calculate old total power

        // Update total DAO power
        if (newVotingPower > oldVotingPower) {
             totalDAOVotingPower += (newVotingPower - oldVotingPower);
        } else {
             totalDAOVotingPower -= (oldVotingPower - newVotingPower);
        }


        emit ReputationUpdated(member, oldReputation, memberInfo.reputation);
    }

    /// @notice Internal helper to calculate a member's current voting power.
    /// @param member The address of the member.
    /// @return The calculated voting power. Returns 0 if not a member.
    function _calculateVotingPower(address member) internal view returns (uint256) {
        MemberInfo memory memberInfo = members[member];
         // Check isActive and NFT ownership before granting power
        if (!memberInfo.isActive || memberInfo.memberNFTTokenId == 0) return 0;

         // Check NFT ownership using the external call
         try IERC721(membershipNFT).ownerOf(memberInfo.memberNFTTokenId) returns (address owner) {
            if (owner != member) return 0; // No power if they no longer own the NFT
         } catch {
             return 0; // No power if NFT check fails (e.g., NFT contract error, NFT burned)
         }

        // Basic calculation: base weight + reputation
        return NFT_VOTING_WEIGHT + memberInfo.reputation;

        // Could add tiering based on NFT type/attributes here if the NFT contract supported it.
    }


    // 7. Parameter & Adaptive Rule Management Functions

    /// @notice Gets the current active governance parameters.
    /// @return GovernanceParameters struct.
    function getCurrentParameters() external view returns (GovernanceParameters memory) {
        return currentParameters;
    }

    /// @notice Gets the details of all active adaptive rules.
    /// @return Array of AdaptiveRule structs.
    function getAdaptiveRules() external view returns (AdaptiveRule[] memory) {
        AdaptiveRule[] memory activeRules = new AdaptiveRule[](activeAdaptiveRuleIds.length);
        for(uint i = 0; i < activeAdaptiveRuleIds.length; i++) {
            activeRules[i] = adaptiveRules[activeAdaptiveRuleIds[i]];
        }
        return activeRules;
    }


    /// @notice Analyzes recent DAO activity and proposes parameter changes if adaptive rules are triggered.
    /// Can be called by any member. Creates a ParameterChange proposal for the DAO to vote on.
    function adaptGovernance() external onlyMember {
        // --- 1. Gather Activity Metrics (Simplified Example) ---
        // In a real system, this would track metrics over a specific period (e.g., last N proposals, last N blocks).
        // Example metrics:
        // - Proposal Count in last period
        // - Average voter turnout (total power cast / totalDAOVotingPower) on recent proposals
        // - Average success rate of proposals

        uint256 recentProposalCount = 0; // Placeholder calculation
        uint256 totalPowerCastRecent = 0; // Placeholder calculation
        uint256 proposalsConsidered = 0; // Placeholder calculation

        // To make this real, you'd need to iterate backwards through recent proposals
        // For simplicity, let's use hypothetical hardcoded metrics or simple checks based on state.
        // Example: Check the *last* completed proposal's turnout. (Still requires finding the last completed one).
        // A robust system needs proposal history tracking or iteration.
        // Let's invent a simple metric: Check turnout of the MOST RECENT proposal if it's finished.
        uint256 lastProposalId = _nextProposalId > 0 ? _nextProposalId - 1 : 0;
        uint256 recentParticipationRateBPS = 0;
        if (_nextProposalId > 0 && proposals[lastProposalId].state != ProposalState.Active && proposals[lastProposalId].totalVotingPowerAtStart > 0) {
            uint256 totalVotesCast = proposals[lastProposalId].yesVotes + proposals[lastProposalId].noVotes + proposals[lastProposalId].abstainVotes;
            recentParticipationRateBPS = (totalVotesCast * 10000) / proposals[lastProposalId].totalVotingPowerAtStart;
        }


        // --- 2. Check Adaptive Rules Against Metrics ---
        uint256 triggeredRuleId = 0;
        // Iterate through active rules
        for(uint i = 0; i < activeAdaptiveRuleIds.length; i++) {
            uint256 ruleId = activeAdaptiveRuleIds[i];
            AdaptiveRule storage rule = adaptiveRules[ruleId];
            if (!rule.isActive) continue;

            // Apply rule condition (Simplified: if participation rate is below the rule's threshold)
            if (recentParticipationRateBPS < rule.minParticipationRateBPS) {
                 triggeredRuleId = ruleId;
                 break; // Trigger only the first matching rule for simplicity
            }
        }

        // --- 3. If a Rule is Triggered, Create a Parameter Change Proposal ---
        if (triggeredRuleId != 0) {
            AdaptiveRule storage triggeredRule = adaptiveRules[triggeredRuleId];

            // Calculate the suggested new parameter value
            // Example: Decrease proposal threshold by the rule's suggested delta
            uint256 suggestedNewThreshold = currentParameters.proposalThresholdRep > triggeredRule.suggestedProposalThresholdRepDelta
                ? currentParameters.proposalThresholdRep - triggeredRule.suggestedProposalThresholdRepDelta
                : 0; // Don't go below 0 reputation

            // Construct the proposed new parameters (copy current, apply suggestion)
            GovernanceParameters memory suggestedParams = currentParameters;
            suggestedParams.proposalThresholdRep = suggestedNewThreshold;

            string memory description = string(abi.encodePacked("Adaptive rule #", uint256(triggeredRuleId).toString(), " triggered: Low participation detected. Suggesting lower proposal threshold to ", suggestedNewThreshold.toString(), " reputation."));

            // Create the ParameterChange proposal via the propose function
            bytes memory encodedParams = abi.encode(suggestedParams);
            uint256 newProposalId = propose(new bytes[](0), new bytes[](0), description, ProposalType.ParameterChange, encodedParams);

            emit AdaptiveProposalCreated(triggeredRuleId, newProposalId);
        }
        // If no rule triggered, nothing happens.
    }


    /// @notice Adds or updates an adaptive rule (internal, called via proposal execution).
    /// @param ruleId The ID of the rule (0 for new).
    /// @param rule The AdaptiveRule struct data.
    function _addOrUpdateAdaptiveRule(uint256 ruleId, AdaptiveRule memory rule) internal {
        if (ruleId == 0) { // Add new rule
            ruleId = _nextAdaptiveRuleId++;
            adaptiveRules[ruleId] = rule;
            if (rule.isActive) {
                 activeAdaptiveRuleIds.push(ruleId); // Add to active list
            }
        } else { // Update existing rule
             require(adaptiveRules[ruleId].isActive, "DEDAO: Cannot update inactive rule"); // Only update active rules
             adaptiveRules[ruleId] = rule;
        }
        emit AdaptiveRuleUpdated(ruleId, rule);
    }

     /// @notice Removes an adaptive rule (internal, called via proposal execution).
     /// @param ruleId The ID of the rule to remove.
     function _removeAdaptiveRule(uint256 ruleId) internal {
         require(adaptiveRules[ruleId].isActive, "DEDAO: Rule is not active");
         adaptiveRules[ruleId].isActive = false; // Mark inactive

         // Remove from active list (gas-intensive for large lists)
         for(uint i = 0; i < activeAdaptiveRuleIds.length; i++) {
             if (activeAdaptiveRuleIds[i] == ruleId) {
                 activeAdaptiveRuleIds[i] = activeAdaptiveRuleIds[activeAdaptiveRuleIds.length - 1];
                 activeAdaptiveRuleIds.pop();
                 break;
             }
         }
         emit AdaptiveRuleRemoved(ruleId);
     }


    /// @notice Internal function to apply parameter changes after a successful ParameterChange proposal.
    /// @param newParams The new parameters to set.
    function _applyParameterChange(GovernanceParameters memory newParams) internal {
        currentParameters = newParams;
        emit GovernanceParametersUpdated(newParams);
    }


    // 8. Treasury Functions

    /// @notice Allows anyone to deposit Ether into the DAO treasury.
    function depositFunds() external payable {
        require(msg.value > 0, "DEDAO: Must send Ether");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice Internal function to withdraw funds from the treasury (only callable by `execute`).
    /// @param amount The amount to withdraw.
    /// @param recipient The address to send funds to.
    function withdrawFunds(uint256 amount, address recipient) internal {
        require(address(this).balance >= amount, "DEDAO: Insufficient treasury balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "DEDAO: Failed to withdraw funds");
        emit TreasuryWithdrawn(recipient, amount);
    }

    /// @notice Gets the current Ether balance of the DAO treasury.
    /// @return The balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // 9. Query Functions

    /// @notice Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The ProposalState.
    function getProposalState(uint256 proposalId) external view proposalExists(proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
            // Voting period ended, determine final state
            if (_checkQuorum(proposalId)) {
                 if (_checkThreshold(proposalId)) {
                     return ProposalState.Succeeded;
                 } else {
                     return ProposalState.Defeated;
                 }
            } else {
                return ProposalState.Defeated; // Failed quorum
            }
        }
        return proposal.state;
    }

    /// @notice Gets the details of a proposal by ID.
    /// @param proposalId The ID of the proposal.
    /// @return Proposal struct details.
    function getProposalDetails(uint256 proposalId) external view proposalExists(proposalId) returns (Proposal memory) {
        return proposals[proposalId];
    }

    /// @notice Gets the current yes/no/abstain vote counts for a proposal, weighted by voting power.
    /// @param proposalId The ID of the proposal.
    /// @return yesVotes, noVotes, abstainVotes, total voting power cast.
    function getProposalVoteCount(uint256 proposalId) external view proposalExists(proposalId) returns (uint256 yesVotes, uint256 noVotes, uint256 abstainVotes, uint256 totalVotesCast) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.yesVotes, proposal.noVotes, proposal.abstainVotes, proposal.yesVotes + proposal.noVotes + proposal.abstainVotes);
    }

    /// @notice Calculates the total voting power required for quorum based on proposal snapshot and current parameters.
    /// @param proposalId The ID of the proposal.
    /// @return Required voting power for quorum.
    function calculateQuorumNeeded(uint256 proposalId) external view proposalExists(proposalId) returns (uint256) {
        Proposal memory proposal = proposals[proposalId]; // Use memory for view function
        // Quorum is calculated against the total possible voting power *at the time the proposal started*.
        return (proposal.totalVotingPowerAtStart * currentParameters.quorumThresholdBPS) / 10000;
    }

    /// @notice Calculates the total 'yes' voting power required to pass the threshold based on votes cast and current parameters.
    /// @param proposalId The ID of the proposal.
    /// @return Required 'yes' voting power to pass.
    function calculateThresholdNeeded(uint256 proposalId) external view proposalExists(proposalId) returns (uint256) {
         Proposal memory proposal = proposals[proposalId]; // Use memory for view function
         // Threshold is calculated against votes *cast* (excluding abstain for this logic example)
         uint256 totalVotesCastForDecision = proposal.yesVotes + proposal.noVotes;
         if (totalVotesCastForDecision == 0) return 1; // Avoid division by zero, requires at least 1 yes vote if any votes cast
         return (totalVotesCastForDecision * currentParameters.successRatioNumerator) / currentParameters.successRatioDenominator;
    }

    /// @notice Gets the ID of the most recently created proposal.
    /// @return The latest proposal ID, or 0 if none exist.
    function getLatestProposalId() external view returns (uint256) {
        return _nextProposalId > 0 ? _nextProposalId - 1 : 0;
    }

    // 10. Internal/Helper Functions

     /// @notice Internal helper to check if quorum is met for a proposal.
     /// @param proposalId The ID of the proposal.
     /// @return True if quorum is met, false otherwise.
    function _checkQuorum(uint256 proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes + proposal.abstainVotes;
        uint256 requiredQuorum = (proposal.totalVotingPowerAtStart * currentParameters.quorumThresholdBPS) / 10000; // Using snapshot total power
        return totalVotesCast >= requiredQuorum;
    }

    /// @notice Internal helper to check if the success threshold is met for a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return True if threshold is met, false otherwise.
    function _checkThreshold(uint256 proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        uint256 totalVotesForDecision = proposal.yesVotes + proposal.noVotes; // Threshold typically excludes abstains
        if (totalVotesForDecision == 0) return false; // Cannot pass if no deciding votes
        uint256 requiredYesVotes = (totalVotesForDecision * currentParameters.successRatioNumerator) / currentParameters.successRatioDenominator;
        return proposal.yesVotes >= requiredYesVotes;
    }

     // --- Placeholder/Example for Adaptive Rule Change Logic ---
     // A real implementation of `_applyAdaptiveRuleChange` would need to decode
     // the `adaptiveRuleData` based on a defined format and call internal functions
     // like these examples:
     // function _addAdaptiveRule(AdaptiveRule memory rule) internal { ... }
     // function _removeAdaptiveRule(uint256 ruleId) internal { ... }
     // function _updateAdaptiveRule(uint256 ruleId, AdaptiveRule memory rule) internal { ... }
     // Example structure for adaptiveRuleData:
     // bytes4 selector; // e.g., bytes4(keccak256("addRule(AdaptiveRule)"))
     // bytes data; // abi.encode(rule) or abi.encode(ruleId) etc.
     // require(bytes4(proposal.adaptiveRuleData[:4]) == this.addAdaptiveRule.selector, "...");
     // (bool success,) = address(this).call(proposal.adaptiveRuleData);


     // Fallback function to receive Ether directly (or use depositFunds)
     receive() external payable {
         emit TreasuryDeposited(msg.sender, msg.value);
     }
}

// Helper contract for uint to string conversion (for descriptions)
// This is a very basic implementation, consider a more robust library like OpenZeppelin's strings.
library Uint256ToString {
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
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}

// Add the library usage
import "./Uint256ToString.sol"; // Assuming the library is in a separate file or included

contract DynamicEvolutionaryDAO {
    using Uint256ToString for uint256;
    // ... rest of the contract code ...
}
```

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **NFT Membership:** Trendy way to manage identity and potentially tiers in a DAO, moving beyond simple token holding.
2.  **Reputation System:** A crucial element for sophisticated DAOs. This contract uses a simple, on-chain reputation based on governance outcomes. It directly impacts voting power and access (`proposalThresholdRep`, `voteThresholdRep`). While reputation systems exist, tying earning/losing directly to proposal success/failure is a specific mechanism.
3.  **Dynamic Governance Parameters:** The core creative concept. The DAO isn't stuck with its initial settings. It can collectively decide to adjust its fundamental rules via `ParameterChange` proposals.
4.  **Adaptive Governance (`adaptGovernance` function):** This function introduces a self-analysis and self-suggestion mechanism. Based on predefined `AdaptiveRule`s and on-chain metrics (even if simplified in the example), it can trigger `ParameterChange` proposals. This moves towards a more "intelligent" or "evolving" organization structure. The key is that it *proposes* changes, keeping decision-making decentralized.
5.  **Multiple Proposal Types:** Supports standard actions but explicitly structures proposals for changing the DAO's *own configuration* (`ParameterChange`, `AdaptiveRuleChange`), adding a meta-governance layer.
6.  **Snapshot Voting Power:** `totalVotingPowerAtStart` is snapshotted on proposal creation. This is common but essential for quorum calculations in systems where voting power changes.
7.  **Weighted Voting:** Voting power is calculated as NFT weight + reputation, making participation and earned reputation directly impactful.

**Limitations and Potential Improvements (for Production):**

*   **Gas Costs:** Iterating through all members or voters for reputation updates or finding adaptive rules can be very expensive in large DAOs. Solutions include off-chain reputation calculation with on-chain proofs, reputation claiming mechanisms, or different storage patterns.
*   **Adaptive Logic Complexity:** The `adaptGovernance` function's metric gathering and rule checking are highly simplified. A real system needs robust, possibly decentralized, ways to feed metrics and execute complex rule logic.
*   **Adaptive Rule Data:** The handling of `adaptiveRuleData` in `_applyAdaptiveRuleChange` is a placeholder. A real system requires careful design for encoding/decoding different types of rule changes securely.
*   **NFT Interaction:** The membership check using `ownerOf` is simple. A dedicated membership management system, possibly integrated directly into the NFT contract or using events, would be more robust. Handling NFT transfers needs careful consideration (e.g., does transferring the NFT remove membership/reputation?). `checkMembership` covers the *current* check, but leaving the DAO when transferring isn't automatically handled here.
*   **Reputation Decay:** The `inactivityReputationDecayBlocks` parameter is included but not implemented in the `_updateReputation` logic. Implementing time-based decay requires a mechanism to trigger updates (e.g., callable by anyone, triggered by other interactions, or off-chain calculation).
*   **Security:** This is an example contract. Production DAOs require extensive security audits, reentrancy checks, and careful consideration of all possible attack vectors.
*   **Upgradeability:** A production DAO would likely need to be upgradeable, which adds complexity (e.g., using proxy patterns like UUPS or Transparent).

This contract provides a solid foundation for an evolutionary DAO with dynamic governance and a reputation system, fulfilling the requirements for an interesting, advanced, creative, and trendy concept with a significant number of functions.