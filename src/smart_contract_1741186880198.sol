```solidity
/**
 * @title Decentralized Dynamic Governance DAO with Reputation System
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a Decentralized Autonomous Organization (DAO)
 * with dynamic governance based on a reputation system. This DAO allows for various
 * proposal types, reputation-based voting power, and dynamic parameter adjustments.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinDAO()`: Allows a user to become a member of the DAO.
 *    - `leaveDAO()`: Allows a member to leave the DAO.
 *    - `isMember(address _account)`: Checks if an address is a member.
 *    - `getMemberCount()`: Returns the current number of members.
 *
 * **2. Reputation System:**
 *    - `getReputation(address _member)`: Retrieves the reputation score of a member.
 *    - `awardReputation(address _member, uint256 _amount)`: Awards reputation points to a member (Admin/Governance function).
 *    - `penalizeReputation(address _member, uint256 _amount)`: Penalizes reputation points from a member (Admin/Governance function).
 *    - `transferReputation(address _from, address _to, uint256 _amount)`: Allows reputation transfer between members (optional, based on governance).
 *
 * **3. Proposal System:**
 *    - `createProposal(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _data)`: Creates a new proposal.
 *    - `getProposal(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *    - `getProposalStatus(uint256 _proposalId)`: Gets the current status of a proposal.
 *    - `getProposalCount()`: Returns the total number of proposals created.
 *    - `getProposalsByType(ProposalType _proposalType)`: Returns a list of proposal IDs of a specific type.
 *
 * **4. Voting System:**
 *    - `castVote(uint256 _proposalId, VoteOption _vote)`: Allows members to cast their vote on a proposal.
 *    - `getVoteCount(uint256 _proposalId, VoteOption _option)`: Gets the vote count for a specific option on a proposal.
 *    - `hasVoted(uint256 _proposalId, address _voter)`: Checks if a member has already voted on a proposal.
 *    - `getVotingPower(address _member)`: Calculates the voting power of a member based on their reputation (dynamic).
 *
 * **5. Parameterized Governance:**
 *    - `setParameter(string memory _paramName, uint256 _paramValue)`: Allows governance to change DAO parameters (e.g., voting quorum, proposal duration).
 *    - `getParameter(string memory _paramName)`: Retrieves the current value of a DAO parameter.
 *    - `listParameters()`: Lists all configurable parameters and their current values.
 *
 * **6. Treasury Management (Simple Example):**
 *    - `deposit(uint256 _amount)`: Allows members or anyone to deposit funds into the DAO treasury.
 *    - `withdraw(address _recipient, uint256 _amount)`: Allows governance to withdraw funds from the treasury (e.g., based on treasury spending proposals).
 *    - `getTreasuryBalance()`: Retrieves the current balance of the DAO treasury.
 */
pragma solidity ^0.8.0;

contract DynamicGovernanceDAO {
    // --- Enums and Structs ---

    enum ProposalType {
        PARAMETER_CHANGE,
        TREASURY_SPENDING,
        MEMBER_REMOVAL,
        REPUTATION_TRANSFER,
        CUSTOM_ACTION // Example: Execute arbitrary contract call
    }

    enum VoteOption {
        AGAINST,
        FOR,
        ABSTAIN
    }

    struct Proposal {
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        bytes data; // Data field for specific proposal types
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        bool executed;
        bool passed;
    }

    // --- State Variables ---

    mapping(address => bool) public members;
    uint256 public memberCount;

    mapping(address => uint256) public reputation; // Member Reputation Scores

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(ProposalType => uint256[]) public proposalsByType; // Track proposals by type

    mapping(uint256 => mapping(address => VoteOption)) public votes; // proposalId => voter => voteOption

    mapping(string => uint256) public parameters; // Configurable DAO Parameters

    uint256 public treasuryBalance;

    address public governanceAdmin; // Address authorized to make governance changes

    // --- Events ---

    event MemberJoined(address indexed member);
    event MemberLeft(address indexed member);
    event ReputationAwarded(address indexed member, uint256 amount);
    event ReputationPenalized(address indexed member, uint256 amount);
    event ReputationTransferred(address indexed from, address indexed to, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteOption vote);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event ParameterChanged(string paramName, uint256 newValue);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount, address indexed admin);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender], "Not a DAO member");
        _;
    }

    modifier onlyGovernanceAdmin() {
        require(msg.sender == governanceAdmin, "Not a governance admin");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Proposal not currently active");
        _;
    }


    // --- Constructor ---

    constructor() {
        governanceAdmin = msg.sender; // Deployer is initial governance admin
        parameters["VOTING_DURATION"] = 7 days; // Default voting duration
        parameters["VOTING_QUORUM_PERCENT"] = 50; // Default voting quorum percentage
        parameters["MIN_REPUTATION_TO_PROPOSE"] = 10; // Minimum reputation to create proposals
        parameters["DEFAULT_REPUTATION"] = 1; // Default reputation for new members
    }

    // --- 1. Membership Management ---

    function joinDAO() external {
        require(!members[msg.sender], "Already a member");
        members[msg.sender] = true;
        memberCount++;
        reputation[msg.sender] = parameters["DEFAULT_REPUTATION"]; // Initial reputation
        emit MemberJoined(msg.sender);
    }

    function leaveDAO() external onlyMember {
        members[msg.sender] = false;
        memberCount--;
        delete reputation[msg.sender]; // Optionally remove reputation upon leaving
        emit MemberLeft(msg.sender);
    }

    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    // --- 2. Reputation System ---

    function getReputation(address _member) external view returns (uint256) {
        return reputation[_member];
    }

    function awardReputation(address _member, uint256 _amount) external onlyGovernanceAdmin {
        reputation[_member] += _amount;
        emit ReputationAwarded(_member, _amount);
    }

    function penalizeReputation(address _member, uint256 _amount) external onlyGovernanceAdmin {
        require(reputation[_member] >= _amount, "Reputation cannot be negative");
        reputation[_member] -= _amount;
        emit ReputationPenalized(_member, _amount);
    }

    function transferReputation(address _from, address _to, uint256 _amount) external onlyMember {
        require(msg.sender == _from, "Sender must be the reputation owner");
        require(members[_to], "Recipient must be a member");
        require(reputation[_from] >= _amount, "Insufficient reputation to transfer");
        reputation[_from] -= _amount;
        reputation[_to] += _amount;
        emit ReputationTransferred(_from, _to, _amount);
    }


    // --- 3. Proposal System ---

    function createProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _data
    ) external onlyMember {
        require(reputation[msg.sender] >= parameters["MIN_REPUTATION_TO_PROPOSE"], "Insufficient reputation to create proposal");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalType = _proposalType;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + parameters["VOTING_DURATION"];
        newProposal.data = _data;

        proposalsByType[_proposalType].push(proposalCount); // Add to type-specific list

        emit ProposalCreated(proposalCount, _proposalType, msg.sender);
    }

    function getProposal(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalStatus(uint256 _proposalId) external view validProposal(_proposalId) returns (string memory) {
        Proposal memory prop = proposals[_proposalId];
        if (prop.executed) {
            return prop.passed ? "Executed - Passed" : "Executed - Failed";
        } else if (block.timestamp > prop.endTime) {
            return "Voting Ended";
        } else if (block.timestamp < prop.startTime) {
            return "Voting Pending";
        } else {
            return "Voting Active";
        }
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

    function getProposalsByType(ProposalType _proposalType) external view returns (uint256[] memory) {
        return proposalsByType[_proposalType];
    }


    // --- 4. Voting System ---

    function castVote(uint256 _proposalId, VoteOption _vote)
        external
        onlyMember
        validProposal(_proposalId)
        proposalActive(_proposalId)
        proposalNotExecuted(_proposalId)
    {
        require(votes[_proposalId][msg.sender] == VoteOption.ABSTAIN, "Already voted"); // Default abstain value is used as "not voted" marker.

        votes[_proposalId][msg.sender] = _vote;
        uint256 votingPower = getVotingPower(msg.sender);

        if (_vote == VoteOption.FOR) {
            proposals[_proposalId].votesFor += votingPower;
        } else if (_vote == VoteOption.AGAINST) {
            proposals[_proposalId].votesAgainst += votingPower;
        } else if (_vote == VoteOption.ABSTAIN) {
            proposals[_proposalId].votesAbstain += votingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function getVoteCount(uint256 _proposalId, VoteOption _option) external view validProposal(_proposalId) returns (uint256) {
        if (_option == VoteOption.FOR) {
            return proposals[_proposalId].votesFor;
        } else if (_option == VoteOption.AGAINST) {
            return proposals[_proposalId].votesAgainst;
        } else if (_option == VoteOption.ABSTAIN) {
            return proposals[_proposalId].votesAbstain;
        }
        return 0; // Should not reach here, but for safety
    }

    function hasVoted(uint256 _proposalId, address _voter) external view validProposal(_proposalId) returns (bool) {
        return votes[_proposalId][_voter] != VoteOption.ABSTAIN;
    }

    function getVotingPower(address _member) public view returns (uint256) {
        // Example: Voting power is directly proportional to reputation
        return reputation[_member];
        // In a more advanced system, voting power could be a more complex function of reputation
        // e.g., logarithmic, tiered, or influenced by other factors.
    }

    function executeProposal(uint256 _proposalId)
        external
        validProposal(_proposalId)
        proposalNotExecuted(_proposalId)
    {
        require(block.timestamp > proposals[_proposalId].endTime, "Voting not yet ended");

        uint256 totalVotingPower = 0;
        for (uint256 i = 1; i <= proposalCount; i++) { // Inefficient, consider better way to track total voting power if scalability is critical
            if(members(proposals[i].proposer)){ // only count voting power of current members
                totalVotingPower += getVotingPower(proposals[i].proposer);
            }
        }
        uint256 quorumPercentage = parameters["VOTING_QUORUM_PERCENT"];
        uint256 quorumNeeded = (totalVotingPower * quorumPercentage) / 100;

        bool passed = proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst && (proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst + proposals[_proposalId].votesAbstain) >= quorumNeeded;

        proposals[_proposalId].executed = true;
        proposals[_proposalId].passed = passed;

        if (passed) {
            _executeProposalAction(_proposalId); // Execute proposal specific action
        }

        emit ProposalExecuted(_proposalId, passed);
    }

    function _executeProposalAction(uint256 _proposalId) internal {
        Proposal storage prop = proposals[_proposalId];
        if (prop.proposalType == ProposalType.PARAMETER_CHANGE) {
            // Decode data to get parameter name and value
            (string memory paramName, uint256 paramValue) = abi.decode(prop.data, (string, uint256));
            setParameter(paramName, paramValue);
        } else if (prop.proposalType == ProposalType.TREASURY_SPENDING) {
            // Decode data to get recipient and amount
            (address recipient, uint256 amount) = abi.decode(prop.data, (address, uint256));
            withdraw(recipient, amount);
        } else if (prop.proposalType == ProposalType.MEMBER_REMOVAL) {
            // Decode data to get address to remove
            address memberToRemove = abi.decode(prop.data, (address));
            leaveDAOMember(memberToRemove); // Internal function for controlled removal
        } else if (prop.proposalType == ProposalType.REPUTATION_TRANSFER) {
            // Decode data for reputation transfer proposal
            (address from, address to, uint256 amount) = abi.decode(prop.data, (address, address, uint256));
            transferReputation(from, to, amount); // Use existing function
        } else if (prop.proposalType == ProposalType.CUSTOM_ACTION) {
            // Example: Assume data is an ABI encoded call to another contract.
            (address targetContract, bytes memory callData) = abi.decode(prop.data, (address, bytes));
            (bool success, ) = targetContract.call(callData);
            require(success, "Custom action execution failed");
        }
        // Add more proposal type execution logic here as needed
    }

    function leaveDAOMember(address _member) internal onlyGovernanceAdmin { // Internal for controlled removal
        members[_member] = false;
        memberCount--;
        delete reputation[_member];
        emit MemberLeft(_member);
    }


    // --- 5. Parameterized Governance ---

    function setParameter(string memory _paramName, uint256 _paramValue) public onlyGovernanceAdmin {
        parameters[_paramName] = _paramValue;
        emit ParameterChanged(_paramName, _paramValue);
    }

    function getParameter(string memory _paramName) external view returns (uint256) {
        return parameters[_paramName];
    }

    function listParameters() external view returns (string[] memory, uint256[] memory) {
        string[] memory paramNames = new string[](3); // Adjust size if you add more parameters
        uint256[] memory paramValues = new uint256[](3); // Adjust size accordingly

        paramNames[0] = "VOTING_DURATION";
        paramValues[0] = parameters["VOTING_DURATION"];

        paramNames[1] = "VOTING_QUORUM_PERCENT";
        paramValues[1] = parameters["VOTING_QUORUM_PERCENT"];

        paramNames[2] = "MIN_REPUTATION_TO_PROPOSE";
        paramValues[2] = parameters["MIN_REPUTATION_TO_PROPOSE"];

        return (paramNames, paramValues);
    }


    // --- 6. Treasury Management (Simple Example) ---

    function deposit(uint256 _amount) external payable {
        treasuryBalance += _amount;
        emit TreasuryDeposit(msg.sender, _amount);
    }

    function withdraw(address _recipient, uint256 _amount) public onlyGovernanceAdmin {
        require(treasuryBalance >= _amount, "Insufficient treasury balance");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryWithdrawal(_recipient, _amount, msg.sender);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    // --- Admin Functions ---
    function setGovernanceAdmin(address _newAdmin) external onlyGovernanceAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        governanceAdmin = _newAdmin;
    }

    function getGovernanceAdmin() external view returns (address) {
        return governanceAdmin;
    }

    // Fallback function to receive Ether in case of direct transfer to contract address
    receive() external payable {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Governance with Parameters:** The DAO's behavior is not hardcoded but is governed by parameters that can be changed through proposals. This allows the DAO to adapt and evolve over time. Examples include:
    *   `VOTING_DURATION`:  Adjust how long voting periods last.
    *   `VOTING_QUORUM_PERCENT`: Change the percentage of voting power needed for a proposal to pass.
    *   `MIN_REPUTATION_TO_PROPOSE`: Set the minimum reputation required to create proposals, controlling proposal spam and ensuring more engaged members initiate changes.

2.  **Reputation-Based Voting Power:** Voting power isn't just based on token holdings (as in many simpler DAOs). It's tied to a reputation system. This allows for a more nuanced governance model where members who contribute more, are more active, or are deemed more valuable can have a greater say.  In this basic example, it's a 1:1 mapping, but you could make it more complex (e.g., logarithmic, tiered reputation levels).

3.  **Multiple Proposal Types:** The contract supports different types of proposals, making the DAO more versatile:
    *   `PARAMETER_CHANGE`:  For modifying governance parameters.
    *   `TREASURY_SPENDING`:  For managing the DAO's funds.
    *   `MEMBER_REMOVAL`:  To remove members (potentially for malicious behavior, though this should be used cautiously in a decentralized setting).
    *   `REPUTATION_TRANSFER`:  For reputation adjustments based on community decisions (could be used for rewarding contributions, etc.).
    *   `CUSTOM_ACTION`:  A powerful type that allows the DAO to execute arbitrary actions, like calling functions on other smart contracts. This opens up possibilities for complex integrations and functionalities controlled by the DAO.

4.  **Custom Action Proposals:** The `CUSTOM_ACTION` proposal type is particularly interesting. It allows the DAO to interact with other smart contracts in a decentralized manner.  Imagine a DAO that wants to:
    *   Update its profile on a decentralized social media protocol.
    *   Vote on a proposal in another DAO.
    *   Trigger a function in a DeFi protocol.
    *   Manage assets in a complex multi-signature wallet.
    The `CUSTOM_ACTION` type provides a framework for this, making the DAO more than just an internal governance system; it can be an active agent in the broader blockchain ecosystem.

5.  **Event Emission:**  The contract emits events for almost every significant action (member changes, reputation changes, proposals, votes, parameter changes, treasury actions). This is crucial for off-chain monitoring and building user interfaces that can track the DAO's activity in real-time.

6.  **Modular Design (to some extent):**  The contract is structured into logical sections (Membership, Reputation, Proposals, Voting, Parameters, Treasury), making it more readable and maintainable. While it's a single contract, this organization is a step towards modularity. In a real-world complex DAO, you might break these into separate contracts for better management and upgradeability.

7.  **Reputation Transfer (Optional Feature):** The `transferReputation` function adds another layer of dynamism. It could be used for:
    *   Member-to-member recognition and rewards.
    *   Creating a reputation market (if governance decides to allow it).
    *   Delegating reputation to other members for specific tasks or voting.

**Important Notes & Disclaimer:**

*   **Security Audit Needed:** This is a conceptual example. For any real-world deployment, a thorough security audit is absolutely essential. DAOs manage funds and governance, so vulnerabilities can have significant consequences.
*   **Gas Optimization:** This contract prioritizes functionality and clarity over extreme gas optimization. In a production setting, you would need to analyze gas costs and optimize code for efficiency.
*   **Scalability Considerations:** For a DAO with a very large number of members and proposals, you might need to consider more advanced data structures and patterns for scalability (e.g., efficient iteration over members, proposal indexing, etc.).
*   **Governance and Admin Roles:** The `governanceAdmin` role is a starting point.  In a truly decentralized DAO, you would likely want to transition control away from a single admin address and towards more decentralized governance mechanisms (e.g., a multisig or a DAO-controlled admin role).
*   **Error Handling and Edge Cases:**  While `require` statements are used for basic error handling, a production-ready contract would need more robust error handling and consideration of various edge cases.
*   **Upgradeability:**  This contract, as written, is not easily upgradeable. For a long-lived DAO, you would need to implement upgradeability patterns (e.g., proxy contracts) to allow for future improvements and bug fixes without redeploying the entire system.

This example is intended to be a creative and advanced starting point. You can expand upon these concepts and add even more features to create a truly unique and powerful decentralized autonomous organization.