```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Governance & Reputation Oracle Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract showcasing advanced concepts like dynamic governance, reputation-based influence,
 *      parameterized actions, and a decentralized oracle mechanism, all within a single contract.
 *      This contract is designed to be a creative example and should not be used in production without thorough security audits.
 *
 * **Contract Outline & Function Summary:**
 *
 * **I.  Membership & Role Management:**
 *     1. `joinDAO()`: Allows users to become members of the DAO.
 *     2. `leaveDAO()`: Allows members to leave the DAO.
 *     3. `isMember(address _user)`: Checks if an address is a member.
 *     4. `setModerator(address _moderator)`: Sets the moderator address (admin role).
 *     5. `isModerator(address _user)`: Checks if an address is a moderator.
 *
 * **II. Reputation System:**
 *     6. `increaseReputation(address _user, uint256 _amount)`: Increases a member's reputation.
 *     7. `decreaseReputation(address _user, uint256 _amount)`: Decreases a member's reputation.
 *     8. `getReputation(address _user)`: Retrieves a member's reputation score.
 *     9. `setReputationThreshold(uint256 _threshold)`: Sets the reputation threshold for certain actions.
 *
 * **III. Dynamic Governance & Proposals:**
 *     10. `createProposal(string memory _description, bytes memory _payload, uint256 _executionTimestamp)`: Creates a new governance proposal.
 *     11. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote on a proposal (weighted by reputation).
 *     12. `getProposalState(uint256 _proposalId)`: Retrieves the current state of a proposal (Pending, Active, Passed, Rejected, Executed).
 *     13. `executeProposal(uint256 _proposalId)`: Executes a passed proposal after the execution timestamp.
 *     14. `cancelProposal(uint256 _proposalId)`: Allows the moderator to cancel a proposal before execution.
 *     15. `setVotingDuration(uint256 _durationInSeconds)`: Sets the voting duration for proposals.
 *     16. `setVotingQuorum(uint256 _quorumPercentage)`: Sets the required quorum for proposal approval (percentage).
 *
 * **IV.  Parameterized Actions & Oracle Mechanism:**
 *     17. `requestOracleData(string memory _query)`: Allows members to request data from a hypothetical decentralized oracle network.
 *     18. `fulfillOracleData(bytes32 _requestId, bytes memory _data)`: (Oracle function) Allows the designated oracle to fulfill a data request.
 *     19. `getParameter(string memory _paramName)`: Retrieves a dynamic contract parameter.
 *     20. `setParameter(string memory _paramName, uint256 _paramValue)`: (Governance function) Allows governance to dynamically set contract parameters.
 *
 * **V. Utility & View Functions:**
 *     21. `getTotalMembers()`: Returns the total number of DAO members.
 *     22. `getProposalCount()`: Returns the total number of proposals created.
 *
 */

contract DynamicGovernanceReputationOracle {

    // ---------- STATE VARIABLES ----------

    address public moderator; // Address of the contract moderator (admin)
    mapping(address => bool) public members; // Mapping of members to their membership status
    mapping(address => uint256) public reputation; // Mapping of members to their reputation score
    uint256 public reputationThreshold = 100; // Reputation threshold for certain actions

    uint256 public votingDuration = 7 days; // Default voting duration for proposals
    uint256 public votingQuorumPercentage = 50; // Default quorum percentage for proposals

    struct Proposal {
        string description;
        bytes payload; // Encoded data for contract interaction upon execution
        uint256 executionTimestamp;
        uint256 votingEndTime;
        uint256 positiveVotes;
        uint256 negativeVotes;
        mapping(address => bool) votes; // Track members who have voted
        ProposalState state;
    }

    enum ProposalState { Pending, Active, Passed, Rejected, Executed, Cancelled }
    Proposal[] public proposals; // Array to store proposals

    mapping(bytes32 => bytes) public oracleDataResponses; // Mapping to store oracle data responses
    uint256 public proposalCounter; // Counter for proposal IDs
    mapping(string => uint256) public contractParameters; // Dynamic contract parameters

    // ---------- EVENTS ----------

    event MemberJoined(address indexed member);
    event MemberLeft(address indexed member);
    event ReputationIncreased(address indexed member, uint256 amount);
    event ReputationDecreased(address indexed member, uint256 amount);
    event ReputationThresholdSet(uint256 threshold);
    event ModeratorSet(address indexed moderator);
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event VoteCast(uint256 indexed proposalId, address voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event VotingDurationSet(uint256 durationInSeconds);
    event VotingQuorumSet(uint256 quorumPercentage);
    event OracleDataRequested(bytes32 requestId, string query, uint256 proposalId);
    event OracleDataFulfilled(bytes32 requestId, bytes data);
    event ParameterSet(string paramName, uint256 paramValue);

    // ---------- MODIFIERS ----------

    modifier onlyModerator() {
        require(msg.sender == moderator, "Only moderator can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId < proposals.length, "Invalid proposal ID.");
        _;
    }

    modifier onlyProposalState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }

    modifier notVotedYet(uint256 _proposalId) {
        require(!proposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(block.timestamp <= proposals[_proposalId].votingEndTime, "Voting period has ended.");
        _;
    }

    modifier executionTimeReached(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].executionTimestamp, "Execution time not reached yet.");
        _;
    }

    // ---------- CONSTRUCTOR ----------

    constructor() {
        moderator = msg.sender; // Set the deployer as the initial moderator
        emit ModeratorSet(moderator);
    }

    // ---------- I. MEMBERSHIP & ROLE MANAGEMENT ----------

    /**
     * @dev Allows users to join the DAO as members.
     */
    function joinDAO() external {
        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        emit MemberJoined(msg.sender);
    }

    /**
     * @dev Allows members to leave the DAO.
     */
    function leaveDAO() external onlyMember {
        delete members[msg.sender];
        delete reputation[msg.sender]; // Optionally remove reputation upon leaving
        emit MemberLeft(msg.sender);
    }

    /**
     * @dev Checks if an address is a member of the DAO.
     * @param _user The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    /**
     * @dev Sets the moderator address. Only the current moderator can call this function.
     * @param _moderator The address of the new moderator.
     */
    function setModerator(address _moderator) external onlyModerator {
        require(_moderator != address(0), "Invalid moderator address.");
        moderator = _moderator;
        emit ModeratorSet(_moderator);
    }

    /**
     * @dev Checks if an address is the current moderator.
     * @param _user The address to check.
     * @return True if the address is the moderator, false otherwise.
     */
    function isModerator(address _user) external view returns (bool) {
        return _user == moderator;
    }

    // ---------- II. REPUTATION SYSTEM ----------

    /**
     * @dev Increases a member's reputation. Only the moderator can call this function.
     * @param _user The address of the member.
     * @param _amount The amount to increase reputation by.
     */
    function increaseReputation(address _user, uint256 _amount) external onlyModerator {
        require(members[_user], "User is not a member.");
        reputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount);
    }

    /**
     * @dev Decreases a member's reputation. Only the moderator can call this function.
     * @param _user The address of the member.
     * @param _amount The amount to decrease reputation by.
     */
    function decreaseReputation(address _user, uint256 _amount) external onlyModerator {
        require(members[_user], "User is not a member.");
        require(reputation[_user] >= _amount, "Reputation cannot be negative.");
        reputation[_user] -= _amount;
        emit ReputationDecreased(_user, _amount);
    }

    /**
     * @dev Retrieves a member's reputation score.
     * @param _user The address of the member.
     * @return The reputation score of the member.
     */
    function getReputation(address _user) external view returns (uint256) {
        return reputation[_user];
    }

    /**
     * @dev Sets the reputation threshold for certain actions (e.g., proposal creation).
     * Only the moderator can call this function.
     * @param _threshold The new reputation threshold.
     */
    function setReputationThreshold(uint256 _threshold) external onlyModerator {
        reputationThreshold = _threshold;
        emit ReputationThresholdSet(_threshold);
    }

    // ---------- III. DYNAMIC GOVERNANCE & PROPOSALS ----------

    /**
     * @dev Creates a new governance proposal. Members with sufficient reputation can create proposals.
     * @param _description A description of the proposal.
     * @param _payload Encoded data to be executed if the proposal passes.
     * @param _executionTimestamp Unix timestamp for proposal execution.
     */
    function createProposal(string memory _description, bytes memory _payload, uint256 _executionTimestamp) external onlyMember {
        require(reputation[msg.sender] >= reputationThreshold, "Insufficient reputation to create proposals.");
        require(_executionTimestamp > block.timestamp, "Execution timestamp must be in the future.");

        proposals.push(Proposal({
            description: _description,
            payload: _payload,
            executionTimestamp: _executionTimestamp,
            votingEndTime: block.timestamp + votingDuration,
            positiveVotes: 0,
            negativeVotes: 0,
            state: ProposalState.Pending
        }));
        uint256 proposalId = proposals.length - 1;
        proposals[proposalId].state = ProposalState.Active; // Immediately set to active
        proposalCounter++;
        emit ProposalCreated(proposalId, msg.sender, _description);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

    /**
     * @dev Allows members to vote on an active proposal. Voting power is weighted by reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to support the proposal, false to oppose.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyMember
        validProposalId(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Active)
        votingActive(_proposalId)
        notVotedYet(_proposalId)
    {
        proposals[_proposalId].votes[msg.sender] = true; // Mark voter as voted
        uint256 votingWeight = getVotingWeight(msg.sender); // Reputation-based voting weight

        if (_support) {
            proposals[_proposalId].positiveVotes += votingWeight;
        } else {
            proposals[_proposalId].negativeVotes += votingWeight;
        }
        emit VoteCast(_proposalId, msg.sender, _support);

        // Check if voting period ended and update proposal state
        if (block.timestamp > proposals[_proposalId].votingEndTime) {
            _finalizeProposal(_proposalId);
        }
    }

    /**
     * @dev Internal function to finalize a proposal after the voting period ends.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function _finalizeProposal(uint256 _proposalId) internal validProposalId(_proposalId) onlyProposalState(_proposalId, ProposalState.Active) {
        if (proposals[_proposalId].state != ProposalState.Active) return; // Prevent re-entry

        uint256 totalVotes = proposals[_proposalId].positiveVotes + proposals[_proposalId].negativeVotes;
        uint256 quorum = (totalVotes * 100) / getTotalVotingWeight(); // Calculate quorum based on total voting weight

        if (quorum >= votingQuorumPercentage && proposals[_proposalId].positiveVotes > proposals[_proposalId].negativeVotes) {
            proposals[_proposalId].state = ProposalState.Passed;
            emit ProposalStateChanged(_proposalId, ProposalState.Passed);
        } else {
            proposals[_proposalId].state = ProposalState.Rejected;
            emit ProposalStateChanged(_proposalId, ProposalState.Rejected);
        }
    }


    /**
     * @dev Retrieves the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The ProposalState enum value representing the proposal's state.
     */
    function getProposalState(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /**
     * @dev Executes a passed proposal after the execution timestamp.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        external
        onlyModerator // For security, execution can be initiated by moderator, or can be made permissionless after review
        validProposalId(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Passed)
        executionTimeReached(_proposalId)
    {
        proposals[_proposalId].state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);

        // Execute the payload (Example - In real world, handle potential reverts and security carefully)
        (bool success, ) = address(this).delegatecall(proposals[_proposalId].payload);
        require(success, "Proposal execution failed."); // Handle failure appropriately in production
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows the moderator to cancel a proposal before execution.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId)
        external
        onlyModerator
        validProposalId(_proposalId)
        onlyProposalState(_proposalId, ProposalState.Active) // Can only cancel active or pending proposals
    {
        proposals[_proposalId].state = ProposalState.Cancelled;
        emit ProposalStateChanged(_proposalId, ProposalState.Cancelled);
        emit ProposalCancelled(_proposalId);
    }

    /**
     * @dev Sets the voting duration for new proposals. Only the moderator can call this function.
     * @param _durationInSeconds The voting duration in seconds.
     */
    function setVotingDuration(uint256 _durationInSeconds) external onlyModerator {
        votingDuration = _durationInSeconds;
        emit VotingDurationSet(_durationInSeconds);
    }

    /**
     * @dev Sets the voting quorum percentage for new proposals. Only the moderator can call this function.
     * @param _quorumPercentage The required quorum percentage (0-100).
     */
    function setVotingQuorum(uint256 _quorumPercentage) external onlyModerator {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        votingQuorumPercentage = _quorumPercentage;
        emit VotingQuorumSet(_quorumPercentage);
    }

    // ---------- IV. PARAMETERIZED ACTIONS & ORACLE MECHANISM ----------

    /**
     * @dev Allows members to request data from a hypothetical decentralized oracle network.
     *      This is a simplified example and would require integration with a real oracle service.
     * @param _query The query string to send to the oracle.
     */
    function requestOracleData(string memory _query) external onlyMember {
        bytes32 requestId = keccak256(abi.encodePacked(_query, msg.sender, block.timestamp)); // Generate a unique request ID
        // In a real oracle integration, you would emit an event that an oracle listener picks up
        // and then calls `fulfillOracleData` with the response.
        emit OracleDataRequested(requestId, _query, proposalCounter); // Using proposalCounter as an example, could link to a proposal

        // For demonstration purposes, we'll simulate a delayed response after a few blocks
        // In a real scenario, the oracle would call `fulfillOracleData` externally.
        // (This simulation part is for demonstration ONLY and not part of the 20 functions)
        //  _simulateOracleResponse(requestId, _query); // Simulate oracle response (REMOVE in production)
    }

    // ---  SIMULATED ORACLE RESPONSE (FOR DEMO ONLY, REMOVE IN PRODUCTION) ---
    // function _simulateOracleResponse(bytes32 _requestId, string memory _query) private {
    //     // Simulate a delay (e.g., wait for a few blocks)
    //     // In a real scenario, the oracle would call fulfillOracleData from an external source.
    //     uint256 delayBlocks = 5;
    //     uint256 targetBlock = block.number + delayBlocks;

    //     // You'd typically use a more robust way to schedule tasks in a real contract
    //     // For this example, we'll just check block number repeatedly (inefficient, but illustrative)
    //     // In a real contract, you'd have an oracle service listen for OracleDataRequested events
    //     // and call fulfillOracleData based on external data retrieval.

    //     // WARNING: This is a SIMULATION and will consume gas continuously until the condition is met.
    //     // DO NOT USE THIS IN PRODUCTION.
    //     while (block.number < targetBlock) {
    //         continue; // Wait for blocks to pass (inefficient simulation)
    //     }

    //     // Simulate oracle data based on the query (very basic example)
    //     bytes memory simulatedData;
    //     if (keccak256(bytes(_query)) == keccak256(bytes("getPrice:ETHUSD"))) {
    //         simulatedData = abi.encode(uint256(1800 * 10**8)); // Example ETH/USD price in 8 decimals
    //     } else {
    //         simulatedData = bytes("Unknown Query");
    //     }

    //     fulfillOracleData(_requestId, simulatedData); // Call fulfillOracleData with simulated data
    // }
    // --- END SIMULATED ORACLE RESPONSE ---


    /**
     * @dev (Oracle function) Allows the designated oracle to fulfill a data request.
     *      In a real system, this would be called by an oracle service (external account).
     * @param _requestId The ID of the oracle data request.
     * @param _data The data provided by the oracle in bytes format.
     */
    function fulfillOracleData(bytes32 _requestId, bytes memory _data) external {
        // In a real oracle integration, you would have access control to ensure only authorized oracles can call this.
        // For simplicity, we're skipping that in this example.
        oracleDataResponses[_requestId] = _data;
        emit OracleDataFulfilled(_requestId, _data);
    }

    /**
     * @dev Retrieves a dynamic contract parameter.
     * @param _paramName The name of the parameter.
     * @return The value of the parameter.
     */
    function getParameter(string memory _paramName) external view returns (uint256) {
        return contractParameters[_paramName];
    }

    /**
     * @dev (Governance function) Allows governance to dynamically set contract parameters.
     *      Requires a passed proposal to execute this function.
     * @param _paramName The name of the parameter to set.
     * @param _paramValue The new value of the parameter.
     */
    function setParameter(string memory _paramName, uint256 _paramValue) external {
        // This function should ideally be called via proposal execution.
        // For direct testing, we can allow moderator to call it directly, but in real governance, this would be proposal-based.
        require(msg.sender == moderator, "setParameter can only be called via proposal execution (or by moderator for testing)."); // Remove in real governance
        contractParameters[_paramName] = _paramValue;
        emit ParameterSet(_paramName, _paramValue);
    }


    // ---------- V. UTILITY & VIEW FUNCTIONS ----------

    /**
     * @dev Returns the total number of DAO members.
     * @return The total number of DAO members.
     */
    function getTotalMembers() external view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = getMembers();
        for(uint i=0; i < allMembers.length; i++){
            if(members[allMembers[i]]) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Returns the total number of proposals created.
     * @return The total number of proposals created.
     */
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @dev Internal helper function to calculate voting weight based on reputation.
     * @param _user The address of the member.
     * @return The voting weight of the member (currently reputation, can be adjusted).
     */
    function getVotingWeight(address _user) internal view returns (uint256) {
        return reputation[_user] > 0 ? reputation[_user] : 1; // Base weight of 1 even with 0 reputation.
    }

    /**
     * @dev Internal helper function to calculate total voting weight of all members.
     * @return Total voting weight of all members.
     */
    function getTotalVotingWeight() internal view returns (uint256) {
        uint256 totalWeight = 0;
        address[] memory allMembers = getMembers();
        for(uint i=0; i < allMembers.length; i++){
            if(members[allMembers[i]]) {
                totalWeight += getVotingWeight(allMembers[i]);
            }
        }
        return totalWeight;
    }

    /**
     * @dev Utility function to get all member addresses. (For iteration, not efficient for very large memberships)
     * @return Array of member addresses.
     */
     function getMembers() public view returns (address[] memory) {
        address[] memory memberList = new address[](getTotalMembers());
        uint256 index = 0;
        for (uint256 i = 0; i < proposals.length + 100; i++) { // Iterate through a reasonable range to find members - not scalable for very large membership
             address addr = address(uint160(uint256(keccak256(abi.encodePacked(i))))); // Generate potential addresses (very simplified and not robust for large scale)
             if (members[addr]) {
                 memberList[index] = addr;
                 index++;
                 if (index >= memberList.length) break; // Stop when memberList is full
             }
        }
        return memberList;
    }
}
```