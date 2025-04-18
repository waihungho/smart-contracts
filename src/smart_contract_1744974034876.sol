```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and Tokenized Reputation
 * @author Gemini AI Assistant
 * @notice A sophisticated DAO contract showcasing dynamic governance, tokenized reputation, and advanced features.
 *
 * Function Summary:
 * -----------------
 * **Core DAO Functions:**
 * 1. `propose(string memory _description, address[] memory _targets, bytes[] memory _calldatas, uint256 _voteEndTime)`:  Submit a new proposal to the DAO.
 * 2. `vote(uint256 _proposalId, uint8 _voteType)`: Cast a vote for or against a proposal (0: Against, 1: For, 2: Abstain).
 * 3. `executeProposal(uint256 _proposalId)`: Execute a passed proposal after the voting period.
 * 4. `cancelProposal(uint256 _proposalId)`: Cancel a proposal before voting ends (governance controlled).
 * 5. `getProposalState(uint256 _proposalId)`: Retrieve the current state of a proposal (Pending, Active, Passed, Failed, Executed, Cancelled).
 * 6. `getProposalVoteCounts(uint256 _proposalId)`: Get the for, against, and abstain vote counts for a proposal.
 * 7. `getMemberReputation(address _member)`: Get the reputation score of a DAO member.
 * 8. `delegateReputation(address _delegatee, uint256 _amount)`: Delegate reputation to another member for voting power.
 * 9. `undelegateReputation(address _delegatee, uint256 _amount)`: Undelegate reputation from another member.
 * 10. `mintReputation(address _member, uint256 _amount)`: (Governance) Mint reputation tokens to a member.
 * 11. `burnReputation(address _member, uint256 _amount)`: (Governance) Burn reputation tokens from a member.
 * 12. `transferReputation(address _recipient, uint256 _amount)`: Transfer reputation tokens to another member (if enabled by governance).
 * 13. `getTotalReputationSupply()`: Get the total supply of reputation tokens.
 *
 * **Dynamic Governance Functions:**
 * 14. `updateVotingPeriod(uint256 _newVotingPeriod)`: (Governance Proposal) Update the default voting period for proposals.
 * 15. `updateQuorumThreshold(uint256 _newQuorumThreshold)`: (Governance Proposal) Update the quorum threshold for proposal passing.
 * 16. `updateProposalThreshold(uint256 _newProposalThreshold)`: (Governance Proposal) Update the reputation threshold required to create a proposal.
 * 17. `updateReputationTransferEnabled(bool _enabled)`: (Governance Proposal) Enable or disable reputation token transfers.
 * 18. `emergencyAction(address[] memory _targets, bytes[] memory _calldatas, string memory _reason)`: (Emergency Governance) Execute critical actions bypassing normal proposal process (highly restricted).
 *
 * **Utility and Information Functions:**
 * 19. `isMember(address _account)`: Check if an address is a member of the DAO.
 * 20. `getGovernanceMembers()`: Get a list of addresses considered as governance members (can be dynamically updated).
 * 21. `getVersion()`: Returns the contract version.
 * 22. `getDaoName()`: Returns the name of the DAO.
 */

contract AdvancedDAO {
    string public constant DAO_NAME = "DynamicGovDAO";
    string public constant VERSION = "1.0.0";

    // --- State Variables ---

    struct Proposal {
        string description;
        address proposer;
        address[] targets;
        bytes[] calldatas;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool cancelled;
        mapping(address => uint8) votes; // Member address => Vote type (0=Against, 1=For, 2=Abstain)
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    mapping(address => uint256) public reputation; // Member address => Reputation Score
    uint256 public totalReputationSupply;

    mapping(address => mapping(address => uint256)) public delegatedReputation; // Delegator => Delegatee => Amount

    address[] public governanceMembers; // Addresses with governance privileges (can be changed via governance)
    address public admin; // Contract administrator, can initialize governance but ideally limited role after setup.

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumThreshold = 50; // Percentage of total reputation required for quorum (e.g., 50 = 50%)
    uint256 public proposalThreshold = 100; // Reputation needed to create a proposal
    bool public reputationTransferEnabled = false; // Initially disabled, can be enabled by governance

    // --- Events ---

    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event VoteCast(uint256 proposalId, address voter, uint8 voteType);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ReputationMinted(address recipient, uint256 amount);
    event ReputationBurned(address burner, uint256 amount);
    event ReputationDelegated(address delegator, address delegatee, uint256 amount);
    event ReputationUndelegated(address delegator, address delegatee, uint256 amount);
    event ReputationTransferred(address sender, address recipient, uint256 amount);
    event VotingPeriodUpdated(uint256 newVotingPeriod);
    event QuorumThresholdUpdated(uint256 newQuorumThreshold);
    event ProposalThresholdUpdated(uint256 newProposalThreshold);
    event ReputationTransferEnabledUpdated(bool enabled);
    event EmergencyActionExecuted(string reason);


    // --- Modifiers ---

    modifier onlyGovernance() {
        bool isGovernance = false;
        for (uint256 i = 0; i < governanceMembers.length; i++) {
            if (governanceMembers[i] == _msgSender()) {
                isGovernance = true;
                break;
            }
        }
        require(isGovernance, "Only governance members can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(reputation[_msgSender()] > 0, "Only DAO members can call this function.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].voteEndTime > block.timestamp && !proposals[_proposalId].executed && !proposals[_proposalId].cancelled, "Proposal is not active.");
        _;
    }

    modifier proposalPassed(uint256 _proposalId) {
        require(getProposalState(_proposalId) == ProposalState.Passed, "Proposal not passed.");
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(getProposalState(_proposalId) == ProposalState.Passed && !proposals[_proposalId].executed && !proposals[_proposalId].cancelled, "Proposal is not executable.");
        _;
    }

    // --- Enums ---

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed,
        Cancelled
    }

    // --- Constructor ---

    constructor(address[] memory _initialGovernanceMembers) payable {
        require(_initialGovernanceMembers.length > 0, "Initial governance members must be provided.");
        governanceMembers = _initialGovernanceMembers;
        admin = _msgSender();

        // Initialize admin with some reputation (optional, governance can manage later)
        reputation[admin] = 1000;
        totalReputationSupply = 1000;
        emit ReputationMinted(admin, 1000);
    }

    // --- Core DAO Functions ---

    /**
     * @notice Submit a new proposal to the DAO.
     * @param _description Description of the proposal.
     * @param _targets Array of contract addresses to call.
     * @param _calldatas Array of encoded function calls for each target.
     * @param _voteEndTime Unix timestamp for the proposal's voting end time.
     */
    function propose(
        string memory _description,
        address[] memory _targets,
        bytes[] memory _calldatas,
        uint256 _voteEndTime
    ) external onlyMember {
        require(reputation[_msgSender()] >= proposalThreshold, "Not enough reputation to create a proposal.");
        require(_targets.length == _calldatas.length && _targets.length > 0, "Targets and calldatas must be non-empty and have the same length.");
        require(_voteEndTime > block.timestamp + 1 hours, "Voting end time must be at least 1 hour in the future."); // Min voting period
        require(_voteEndTime <= block.timestamp + 30 days, "Voting end time cannot exceed 30 days."); // Max voting period

        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            proposer: _msgSender(),
            targets: _targets,
            calldatas: _calldatas,
            voteStartTime: block.timestamp,
            voteEndTime: _voteEndTime,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            cancelled: false,
            votes: mapping(address => uint8)()
        });

        emit ProposalCreated(proposalCount, _msgSender(), _description);
    }

    /**
     * @notice Cast a vote for or against a proposal.
     * @param _proposalId ID of the proposal to vote on.
     * @param _voteType 0 = Against, 1 = For, 2 = Abstain.
     */
    function vote(uint256 _proposalId, uint8 _voteType) external onlyMember validProposal(_proposalId) proposalActive(_proposalId) {
        require(proposals[_proposalId].votes[_msgSender()] == 0, "Member has already voted on this proposal."); // 0 is default value for uint8 in mapping, meaning no vote yet.
        require(_voteType <= 2, "Invalid vote type.");

        uint256 votingPower = getVotingPower(_msgSender());

        if (_voteType == 1) {
            proposals[_proposalId].forVotes += votingPower;
        } else if (_voteType == 0) {
            proposals[_proposalId].againstVotes += votingPower;
        } else if (_voteType == 2) {
            proposals[_proposalId].abstainVotes += votingPower;
        }

        proposals[_proposalId].votes[_msgSender()] = _voteType + 1; // Store vote type + 1 to differentiate from default 0 (no vote).
        emit VoteCast(_proposalId, _msgSender(), _voteType);
    }

    /**
     * @notice Execute a passed proposal after the voting period.
     * @param _proposalId ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external validProposal(_proposalId) proposalExecutable(_proposalId) {
        ProposalState state = getProposalState(_proposalId);
        require(state == ProposalState.Passed, "Proposal must have passed to be executed.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        proposals[_proposalId].executed = true;

        address[] memory targets = proposals[_proposalId].targets;
        bytes[] memory calldatas = proposals[_proposalId].calldatas;

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory returnData) = targets[i].call(calldatas[i]);
            require(success, string(returnData)); // Revert if any call fails, consider more robust error handling in production
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Cancel a proposal before voting ends (governance controlled).
     * @param _proposalId ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external onlyGovernance validProposal(_proposalId) proposalActive(_proposalId) {
        require(!proposals[_proposalId].cancelled, "Proposal already cancelled.");
        proposals[_proposalId].cancelled = true;
        emit ProposalCancelled(_proposalId);
    }

    /**
     * @notice Get the current state of a proposal.
     * @param _proposalId ID of the proposal.
     * @return ProposalState enum representing the state.
     */
    function getProposalState(uint256 _proposalId) public view validProposal(_proposalId) returns (ProposalState) {
        if (proposals[_proposalId].cancelled) {
            return ProposalState.Cancelled;
        } else if (proposals[_proposalId].executed) {
            return ProposalState.Executed;
        } else if (block.timestamp < proposals[_proposalId].voteStartTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposals[_proposalId].voteEndTime) {
            return ProposalState.Active;
        } else {
            uint256 totalVotes = proposals[_proposalId].forVotes + proposals[_proposalId].againstVotes + proposals[_proposalId].abstainVotes;
            uint256 quorum = (totalReputationSupply * quorumThreshold) / 100;
            if (totalVotes >= quorum && proposals[_proposalId].forVotes > proposals[_proposalId].againstVotes) {
                return ProposalState.Passed;
            } else {
                return ProposalState.Failed;
            }
        }
    }

    /**
     * @notice Get the for, against, and abstain vote counts for a proposal.
     * @param _proposalId ID of the proposal.
     * @return forVotes, againstVotes, abstainVotes.
     */
    function getProposalVoteCounts(uint256 _proposalId) public view validProposal(_proposalId) returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        return (proposals[_proposalId].forVotes, proposals[_proposalId].againstVotes, proposals[_proposalId].abstainVotes);
    }

    /**
     * @notice Get the reputation score of a DAO member.
     * @param _member Address of the member.
     * @return Reputation score.
     */
    function getMemberReputation(address _member) external view returns (uint256) {
        return reputation[_member];
    }

    /**
     * @notice Delegate reputation to another member for voting power.
     * @param _delegatee Address to delegate reputation to.
     * @param _amount Amount of reputation to delegate.
     */
    function delegateReputation(address _delegatee, uint256 _amount) external onlyMember {
        require(_delegatee != address(0) && _delegatee != _msgSender(), "Invalid delegatee address.");
        require(_amount > 0 && reputation[_msgSender()] >= _amount, "Invalid delegation amount.");

        reputation[_msgSender()] -= _amount;
        delegatedReputation[_msgSender()][_delegatee] += _amount;

        emit ReputationDelegated(_msgSender(), _delegatee, _amount);
    }

    /**
     * @notice Undelegate reputation from another member.
     * @param _delegatee Address to undelegate reputation from.
     * @param _amount Amount of reputation to undelegate.
     */
    function undelegateReputation(address _delegatee, uint256 _amount) external onlyMember {
        require(_delegatee != address(0) && _delegatee != _msgSender(), "Invalid delegatee address.");
        require(_amount > 0 && delegatedReputation[_msgSender()][_delegatee] >= _amount, "Invalid undelegation amount.");

        reputation[_msgSender()] += _amount;
        delegatedReputation[_msgSender()][_delegatee] -= _amount;

        emit ReputationUndelegated(_msgSender(), _delegatee, _amount);
    }

    /**
     * @notice (Governance) Mint reputation tokens to a member.
     * @param _member Address to receive reputation.
     * @param _amount Amount of reputation to mint.
     */
    function mintReputation(address _member, uint256 _amount) external onlyGovernance {
        require(_member != address(0), "Invalid recipient address.");
        require(_amount > 0, "Mint amount must be positive.");

        reputation[_member] += _amount;
        totalReputationSupply += _amount;
        emit ReputationMinted(_member, _amount);
    }

    /**
     * @notice (Governance) Burn reputation tokens from a member.
     * @param _member Address to burn reputation from.
     * @param _amount Amount of reputation to burn.
     */
    function burnReputation(address _member, uint256 _amount) external onlyGovernance {
        require(_member != address(0), "Invalid burner address.");
        require(_amount > 0 && reputation[_member] >= _amount, "Invalid burn amount or insufficient reputation.");

        reputation[_member] -= _amount;
        totalReputationSupply -= _amount;
        emit ReputationBurned(_member, _amount);
    }

    /**
     * @notice Transfer reputation tokens to another member (governance enabled/disabled).
     * @param _recipient Address to receive reputation.
     * @param _amount Amount of reputation to transfer.
     */
    function transferReputation(address _recipient, uint256 _amount) external onlyMember {
        require(reputationTransferEnabled, "Reputation transfers are currently disabled.");
        require(_recipient != address(0) && _recipient != _msgSender(), "Invalid recipient address.");
        require(_amount > 0 && reputation[_msgSender()] >= _amount, "Invalid transfer amount or insufficient reputation.");

        reputation[_msgSender()] -= _amount;
        reputation[_recipient] += _amount;
        emit ReputationTransferred(_msgSender(), _recipient, _amount);
    }

    /**
     * @notice Get the total supply of reputation tokens.
     * @return Total reputation supply.
     */
    function getTotalReputationSupply() public view returns (uint256) {
        return totalReputationSupply;
    }


    // --- Dynamic Governance Functions ---

    /**
     * @notice (Governance Proposal) Update the default voting period for proposals.
     * @param _newVotingPeriod New voting period in seconds.
     */
    function updateVotingPeriod(uint256 _newVotingPeriod) external onlyGovernance { // Governance members propose and vote on this
        require(_newVotingPeriod > 1 hours && _newVotingPeriod <= 60 days, "Invalid voting period.");
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodUpdated(_newVotingPeriod);
    }

    /**
     * @notice (Governance Proposal) Update the quorum threshold for proposal passing.
     * @param _newQuorumThreshold New quorum threshold percentage (0-100).
     */
    function updateQuorumThreshold(uint256 _newQuorumThreshold) external onlyGovernance { // Governance members propose and vote on this
        require(_newQuorumThreshold <= 100, "Quorum threshold must be between 0 and 100.");
        quorumThreshold = _newQuorumThreshold;
        emit QuorumThresholdUpdated(_newQuorumThreshold);
    }

    /**
     * @notice (Governance Proposal) Update the reputation threshold required to create a proposal.
     * @param _newProposalThreshold New reputation threshold.
     */
    function updateProposalThreshold(uint256 _newProposalThreshold) external onlyGovernance { // Governance members propose and vote on this
        proposalThreshold = _newProposalThreshold;
        emit ProposalThresholdUpdated(_newProposalThreshold);
    }

    /**
     * @notice (Governance Proposal) Enable or disable reputation token transfers.
     * @param _enabled True to enable, false to disable.
     */
    function updateReputationTransferEnabled(bool _enabled) external onlyGovernance { // Governance members propose and vote on this
        reputationTransferEnabled = _enabled;
        emit ReputationTransferEnabledUpdated(_enabled);
    }

    /**
     * @notice (Emergency Governance) Execute critical actions bypassing normal proposal process (highly restricted).
     * @dev  This function should be used VERY sparingly and only for critical situations.  Requires a higher governance threshold or multi-sig in a real-world scenario.
     * @param _targets Array of contract addresses to call.
     * @param _calldatas Array of encoded function calls for each target.
     * @param _reason Reason for emergency action (for transparency).
     */
    function emergencyAction(address[] memory _targets, bytes[] memory _calldatas, string memory _reason) external onlyGovernance { // Needs stronger governance control in real scenario
        require(_targets.length == _calldatas.length && _targets.length > 0, "Targets and calldatas must be non-empty and have the same length.");

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory returnData) = targets[i].call(calldatas[i]);
            require(success, string(returnData)); // Revert if any call fails
        }

        emit EmergencyActionExecuted(_reason);
    }


    // --- Utility and Information Functions ---

    /**
     * @notice Check if an address is a member of the DAO (has reputation).
     * @param _account Address to check.
     * @return True if member, false otherwise.
     */
    function isMember(address _account) public view returns (bool) {
        return reputation[_account] > 0;
    }

    /**
     * @notice Get a list of addresses considered as governance members.
     * @return Array of governance member addresses.
     */
    function getGovernanceMembers() public view returns (address[] memory) {
        return governanceMembers;
    }

    /**
     * @notice Returns the contract version.
     * @return Contract version string.
     */
    function getVersion() public pure returns (string memory) {
        return VERSION;
    }

    /**
     * @notice Returns the name of the DAO.
     * @return DAO name string.
     */
    function getDaoName() public pure returns (string memory) {
        return DAO_NAME;
    }

    /**
     * @dev Internal helper function to get voting power of a member.
     * @param _member Address of the member.
     * @return Voting power (reputation + delegated reputation).
     */
    function getVotingPower(address _member) internal view returns (uint256) {
        uint256 votingPower = reputation[_member];
        // Add delegated reputation INCOMING to this member (members delegating TO _member)
        for (uint256 i = 0; i < governanceMembers.length; i++) { // Inefficient - consider better way to track delegatees if scale is needed
            votingPower += delegatedReputation[governanceMembers[i]][_member]; // Iterate through all potential delegators (governance members for simplicity here)
        }
        return votingPower;
    }

    // --- Fallback and Receive (Optional for complex contracts) ---
    receive() external payable {}
    fallback() external payable {}
}
```