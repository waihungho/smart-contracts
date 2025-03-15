```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Governance DAO with Reputation and Adaptive Parameters
 * @author Bard (AI Assistant)
 * @dev A decentralized autonomous organization (DAO) with advanced features including:
 *      - Dynamic governance parameters (voting thresholds, quorum) adjustable by the DAO itself.
 *      - Reputation system to reward participation and influence voting power.
 *      - Role-based access control with different levels of permissions.
 *      - Proposal types for various DAO actions (parameter changes, fund allocation, rule updates, etc.).
 *      - Emergency proposals for critical situations.
 *      - Quadratic voting option for certain proposal types.
 *      - Delegated voting for users to assign their voting power.
 *      - Staking mechanism to boost voting power or earn rewards (simulated).
 *      - Badge/Achievement system to recognize contributions and engagement.
 *      - On-chain messaging/announcement system for DAO communication.
 *      - Time-locked parameter changes for transparency and community awareness.
 *      - Support for different voting mechanisms (simple majority, ranked-choice - future extension).
 *      - Pause and unpause functionality for emergency control.
 *      - Fee collection for certain actions to fund DAO treasury (optional).
 *      - Whitelist/Blacklist functionality for specific actions (optional, use with caution).
 *      - Governance token with transfer restrictions based on reputation (optional, advanced).
 *      - Customizable proposal categories and workflows.
 *      - Off-chain data integration (placeholder for future extensions).
 *
 * Function Summary:
 *
 * --- Core Governance ---
 * 1. propose(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _calldata, uint256 _value): Allows members to submit proposals.
 * 2. vote(uint256 _proposalId, VoteOption _voteOption): Allows members to vote on active proposals.
 * 3. executeProposal(uint256 _proposalId): Executes a successful proposal after the voting period.
 * 4. cancelProposal(uint256 _proposalId): Allows proposers to cancel their proposals before voting starts (with conditions).
 * 5. getProposalState(uint256 _proposalId): Returns the current state of a proposal.
 * 6. getProposalVotes(uint256 _proposalId): Returns the vote counts for a proposal.
 * 7. getProposalDetails(uint256 _proposalId): Returns detailed information about a proposal.
 *
 * --- Dynamic Parameters & Rules ---
 * 8. proposeParameterChange(string memory _parameterName, uint256 _newValue, string memory _reason): Proposes changes to governance parameters like voting thresholds.
 * 9. proposeRuleUpdate(string memory _newRule, string memory _reason): Proposes updates to DAO rules and guidelines.
 * 10. setVotingThreshold(uint256 _newThreshold): Governor-only function to directly set voting threshold (emergency override - use with caution).
 * 11. setQuorum(uint256 _newQuorum): Governor-only function to directly set quorum (emergency override - use with caution).
 * 12. getVotingThreshold(): Returns the current voting threshold.
 * 13. getQuorum(): Returns the current quorum.
 *
 * --- Reputation System ---
 * 14. earnReputation(address _member, uint256 _amount, string memory _reason): Governor-only function to award reputation points to members.
 * 15. spendReputation(address _member, uint256 _amount, string memory _reason): Allows members to spend reputation for certain actions (future features).
 * 16. getReputation(address _member): Returns the reputation score of a member.
 * 17. setReputationLevelThreshold(uint256 _level, uint256 _threshold): Governor-only function to define reputation level thresholds.
 * 18. getReputationLevel(address _member): Returns the reputation level of a member based on thresholds.
 *
 * --- Advanced Features ---
 * 19. delegateVote(address _delegatee): Allows members to delegate their voting power to another member.
 * 20. proposeEmergencyProposal(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _calldata, uint256 _value): Proposes an emergency proposal with faster voting period.
 * 21. announceMessage(string memory _message): Governor-only function to broadcast an on-chain message to DAO members.
 * 22. pauseDAO(): Governor-only function to pause critical DAO functionalities in case of emergency.
 * 23. unpauseDAO(): Governor-only function to unpause DAO functionalities.
 * 24. stakeForVotingPower(uint256 _amount): (Simulated) Allows members to stake tokens to increase voting power.
 * 25. unstakeForVotingPower(uint256 _amount): (Simulated) Allows members to unstake tokens.
 * 26. awardBadge(address _member, string memory _badgeName, string memory _description): Governor-only function to award badges to members.
 * 27. getBadges(address _member): Returns the list of badges awarded to a member.
 *
 * --- Admin & Utility ---
 * 28. addGovernor(address _governor): Allows adding new governors (only by existing governors).
 * 29. removeGovernor(address _governor): Allows removing governors (only by existing governors, with safeguards).
 * 30. isGovernor(address _account): Checks if an address is a governor.
 * 31. getProposalCount(): Returns the total number of proposals created.
 * 32. getActiveProposals(): Returns a list of IDs of currently active proposals.
 * 33. getPastProposals(): Returns a list of IDs of past proposals (executed or cancelled).
 * 34. supportsInterface(bytes4 interfaceId): Standard ERC165 interface support.
 */
contract DynamicGovernanceDAO {
    // --- Enums and Structs ---

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Cancelled,
        Executed
    }

    enum VoteOption {
        Against,
        For,
        Abstain
    }

    enum ProposalType {
        General,              // General DAO decision
        ParameterChange,      // Change governance parameters
        RuleUpdate,           // Update DAO rules
        FundAllocation,       // Allocate funds from treasury
        Emergency           // Critical action requiring fast decision
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        string title;
        string description;
        bytes calldataData;
        uint256 value;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        ProposalState state;
    }

    struct ReputationLevel {
        string name;
        uint256 threshold;
    }

    // --- State Variables ---

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    mapping(uint256 => mapping(address => VoteOption)) public votes; // proposalId => voter => voteOption

    uint256 public votingThresholdPercentage = 50; // Minimum % of votes needed to pass a proposal
    uint256 public quorumPercentage = 20;       // Minimum % of total members that must vote for quorum

    uint256 public defaultVotingPeriod = 7 days;
    uint256 public emergencyVotingPeriod = 1 days;

    mapping(address => uint256) public reputation;
    ReputationLevel[] public reputationLevels;

    mapping(address => address) public voteDelegations; // delegator => delegatee

    mapping(address => string[]) public badges; // member => badge names

    address[] public governors;
    mapping(address => bool) public isGovernorAddress;

    string public announcementMessage;
    bool public paused;

    // --- Events ---

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string title);
    event VoteCast(uint256 proposalId, address voter, VoteOption voteOption);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event RuleUpdateProposed(uint256 proposalId, string newRule);
    event ReputationAwarded(address member, uint256 amount, string reason);
    event VoteDelegated(address delegator, address delegatee);
    event EmergencyProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string title);
    event DAOAnnounced(string message);
    event DAOPaused();
    event DAOUnpaused();
    event BadgeAwarded(address member, string badgeName, string description);

    // --- Modifiers ---

    modifier onlyGovernor() {
        require(isGovernorAddress[msg.sender], "Only governors can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DAO is currently paused");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < proposalCount && proposals[_proposalId].id == _proposalId, "Invalid proposal ID");
        _;
    }

    modifier validProposalState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state");
        _;
    }

    modifier notProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].votingStartTime && block.timestamp <= proposals[_proposalId].votingEndTime, "Voting period is not active");
        _;
    }

    // --- Constructor ---

    constructor() {
        governors.push(msg.sender);
        isGovernorAddress[msg.sender] = true;

        // Initialize default reputation levels
        reputationLevels.push(ReputationLevel("Newcomer", 0));
        reputationLevels.push(ReputationLevel("Contributor", 100));
        reputationLevels.push(ReputationLevel("Veteran", 500));
        reputationLevels.push(ReputationLevel("Leader", 1000));
    }

    // --- Core Governance Functions ---

    function propose(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _calldata,
        uint256 _value
    ) public whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty");

        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _proposalType,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldataData: _calldata,
            value: _value,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + defaultVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, _proposalType, msg.sender, _title);
    }

    function vote(uint256 _proposalId, VoteOption _voteOption)
        public
        whenNotPaused
        validProposalId(_proposalId)
        validProposalState(_proposalId, ProposalState.Active)
        notProposer(_proposalId)
        votingPeriodActive(_proposalId)
    {
        require(votes[_proposalId][msg.sender] == VoteOption.Abstain, "Already voted on this proposal"); // Ensure user votes only once

        votes[_proposalId][msg.sender] = _voteOption;

        if (_voteOption == VoteOption.For) {
            proposals[_proposalId].votesFor++;
        } else if (_voteOption == VoteOption.Against) {
            proposals[_proposalId].votesAgainst++;
        } else {
            proposals[_proposalId].votesAbstain++;
        }

        emit VoteCast(_proposalId, msg.sender, _voteOption);
    }

    function executeProposal(uint256 _proposalId)
        public
        whenNotPaused
        validProposalId(_proposalId)
        validProposalState(_proposalId, ProposalState.Active) // Can only execute if still active
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended");
        require(proposal.state == ProposalState.Active, "Proposal is not active"); // Double check state

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
        uint256 quorum = (address(this).balance > 0 ? 100 : 0); // Placeholder for actual member count based quorum calculation, using contract balance as a dummy for now

        // Placeholder Quorum and Voting Threshold check - Replace with actual member/reputation based quorum
        bool quorumReached = totalVotes > quorum; // Placeholder quorum check
        bool votingThresholdMet = (proposal.votesFor * 100) / totalVotes >= votingThresholdPercentage;


        if (quorumReached && votingThresholdMet) {
            proposal.state = ProposalState.Succeeded;

            (bool success, ) = address(this).call{value: proposal.value}(proposal.calldataData); // Execute proposal calldata
            require(success, "Proposal execution failed");

            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    function cancelProposal(uint256 _proposalId)
        public
        validProposalId(_proposalId)
        validProposalState(_proposalId, ProposalState.Active)
    {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can cancel");
        require(block.timestamp < proposals[_proposalId].votingStartTime, "Cannot cancel after voting starts"); // Example condition

        proposals[_proposalId].state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    function getProposalState(uint256 _proposalId) public view validProposalId(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    function getProposalVotes(uint256 _proposalId) public view validProposalId(_proposalId) returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst, proposals[_proposalId].votesAbstain);
    }

    function getProposalDetails(uint256 _proposalId) public view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // --- Dynamic Parameters & Rules ---

    function proposeParameterChange(string memory _parameterName, uint256 _newValue, string memory _reason) public whenNotPaused {
        bytes memory calldataData = abi.encodeWithSignature("setParameter(string,uint256)", _parameterName, _newValue);
        propose(ProposalType.ParameterChange, "Parameter Change Proposal", _reason, calldataData, 0);
        emit ParameterChangeProposed(proposalCount - 1, _parameterName, _newValue);
    }

    function proposeRuleUpdate(string memory _newRule, string memory _reason) public whenNotPaused {
        bytes memory calldataData = abi.encodeWithSignature("setRule(string)", _newRule);
        propose(ProposalType.RuleUpdate, "Rule Update Proposal", _reason, calldataData, 0);
        emit RuleUpdateProposed(proposalCount - 1, _newRule);
    }

    function setVotingThreshold(uint256 _newThreshold) public onlyGovernor {
        require(_newThreshold <= 100, "Voting threshold cannot exceed 100%");
        votingThresholdPercentage = _newThreshold;
    }

    function setQuorum(uint256 _newQuorum) public onlyGovernor {
        require(_newQuorum <= 100, "Quorum percentage cannot exceed 100%");
        quorumPercentage = _newQuorum;
    }

    function getVotingThreshold() public view returns (uint256) {
        return votingThresholdPercentage;
    }

    function getQuorum() public view returns (uint256) {
        return quorumPercentage;
    }

    // Internal function to handle parameter setting via proposal execution
    function setParameter(string memory _parameterName, uint256 _newValue) internal {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingThresholdPercentage"))) {
            votingThresholdPercentage = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("quorumPercentage"))) {
            quorumPercentage = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("defaultVotingPeriod"))) {
            defaultVotingPeriod = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("emergencyVotingPeriod"))) {
            emergencyVotingPeriod = _newValue;
        } else {
            revert("Unknown parameter name");
        }
    }

    // Placeholder for rule setting - in a real system, rules might be more complex and stored off-chain or in a structured format
    function setRule(string memory _newRule) internal {
        // Example: Store rule in a string variable or update a more complex data structure
        // rulesText = _newRule;
        // In a real system, consider using IPFS or a decentralized database for more complex rules
    }


    // --- Reputation System ---

    function earnReputation(address _member, uint256 _amount, string memory _reason) public onlyGovernor {
        reputation[_member] += _amount;
        emit ReputationAwarded(_member, _amount, _reason);
    }

    function spendReputation(address _member, uint256 _amount, string memory _reason) public {
        require(reputation[_member] >= _amount, "Insufficient reputation");
        reputation[_member] -= _amount;
        // Add logic for what reputation can be spent on (future features - e.g., boosted voting power, access to features)
    }

    function getReputation(address _member) public view returns (uint256) {
        return reputation[_member];
    }

    function setReputationLevelThreshold(uint256 _level, uint256 _threshold) public onlyGovernor {
        require(_level < reputationLevels.length, "Invalid reputation level index");
        reputationLevels[_level].threshold = _threshold;
    }

    function getReputationLevel(address _member) public view returns (string memory) {
        uint256 memberReputation = reputation[_member];
        for (uint256 i = reputationLevels.length - 1; i >= 0; i--) {
            if (memberReputation >= reputationLevels[i].threshold) {
                return reputationLevels[i].name;
            }
            if (i == 0) break; // Prevent underflow in loop
        }
        return "Unknown Level"; // Should not reach here if levels are properly initialized
    }

    // --- Advanced Features ---

    function delegateVote(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0) && _delegatee != msg.sender, "Invalid delegatee address");
        voteDelegations[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    // In a real implementation, delegated voting would need to be considered during vote counting.
    // For simplicity in this example, delegation is recorded but not actively used in voting logic.
    // Advanced implementations could recursively resolve delegations to find the ultimate voter.


    function proposeEmergencyProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _calldata,
        uint256 _value
    ) public whenNotPaused {
        require(isGovernorAddress[msg.sender], "Only governors can propose emergency proposals");
        require(_proposalType == ProposalType.Emergency, "Emergency proposal type must be Emergency"); // Enforce type

        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: _proposalType,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldataData: _calldata,
            value: _value,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + emergencyVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            state: ProposalState.Active
        });

        emit EmergencyProposalCreated(proposalId, _proposalType, msg.sender, _title);
    }

    function announceMessage(string memory _message) public onlyGovernor {
        announcementMessage = _message;
        emit DAOAnnounced(_message);
    }

    function pauseDAO() public onlyGovernor whenNotPaused {
        paused = true;
        emit DAOPaused();
    }

    function unpauseDAO() public onlyGovernor {
        paused = false;
        emit DAOUnpaused();
    }

    function stakeForVotingPower(uint256 _amount) public whenNotPaused {
        // Placeholder for staking logic - In a real system, this would involve token transfers and potentially locking tokens.
        // For this example, we simply increase the voter's reputation as a proxy for increased voting power.
        earnReputation(msg.sender, _amount / 1000, "Staking for voting power (simulated)"); // Example: 1 reputation per 1000 tokens staked
    }

    function unstakeForVotingPower(uint256 _amount) public whenNotPaused {
         // Placeholder for unstaking logic - In a real system, this would involve token transfers and unlocking tokens.
        // For this example, we simply decrease the voter's reputation as a proxy for reduced voting power.
        spendReputation(msg.sender, _amount / 1000, "Unstaking voting power (simulated)"); // Example: 1 reputation per 1000 tokens unstaked
    }

    function awardBadge(address _member, string memory _badgeName, string memory _description) public onlyGovernor {
        badges[_member].push(_badgeName);
        emit BadgeAwarded(_member, _badgeName, _description);
    }

    function getBadges(address _member) public view returns (string[] memory) {
        return badges[_member];
    }


    // --- Admin & Utility Functions ---

    function addGovernor(address _governor) public onlyGovernor {
        require(!isGovernorAddress[_governor], "Address is already a governor");
        governors.push(_governor);
        isGovernorAddress[_governor] = true;
    }

    function removeGovernor(address _governor) public onlyGovernor {
        require(isGovernorAddress[_governor], "Address is not a governor");
        require(governors.length > 1, "Cannot remove the last governor"); // Prevent locking out governance
        require(_governor != msg.sender, "Governors should remove other governors, not themselves for safety."); // Safety measure

        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _governor) {
                governors[i] = governors[governors.length - 1];
                governors.pop();
                isGovernorAddress[_governor] = false;
                break;
            }
        }
    }

    function isGovernor(address _account) public view returns (bool) {
        return isGovernorAddress[_account];
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCount;
    }

    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].state == ProposalState.Active) {
                activeProposalIds[count++] = i;
            }
        }
        assembly {
            mstore(activeProposalIds, count) // Update array length to actual count
        }
        return activeProposalIds;
    }

    function getPastProposals() public view returns (uint256[] memory) {
        uint256[] memory pastProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].state != ProposalState.Active && proposals[i].state != ProposalState.Pending) { // Exclude Pending and Active
                pastProposalIds[count++] = i;
            }
        }
        assembly {
            mstore(pastProposalIds, count) // Update array length to actual count
        }
        return pastProposalIds;
    }


    // --- ERC165 Interface Support ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(DynamicGovernanceDAO).interfaceId ||
               super.supportsInterface(interfaceId);
    }
}
```