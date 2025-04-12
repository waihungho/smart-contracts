```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Adaptive Modular DAO - A Smart Contract for Decentralized Autonomous Organizations
 * @author Bard (Example - Not for Production Use)
 * @dev This contract implements an advanced DAO with modularity, reputation-based governance,
 *      dynamic parameters, and on-chain resource management. It's designed to be flexible and
 *      adaptable to evolving community needs.
 *
 * **Outline and Function Summary:**
 *
 * **Governance & Proposals:**
 * 1. `proposeModule(address _moduleAddress, string memory _moduleName, string memory _moduleDescription)`: Allows members to propose new modules to enhance DAO functionality.
 * 2. `voteOnModule(uint256 _proposalId, bool _support)`: Members vote on module proposals using their voting power.
 * 3. `executeModuleProposal(uint256 _proposalId)`: Executes a successfully passed module proposal, installing the new module.
 * 4. `proposeParameterChange(string memory _parameterName, uint256 _newValue)`: Allows members to propose changes to core DAO parameters (e.g., voting periods, quorum).
 * 5. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Members vote on parameter change proposals.
 * 6. `executeParameterChangeProposal(uint256 _proposalId)`: Executes a successfully passed parameter change proposal.
 * 7. `delegateVote(address _delegatee)`: Allows members to delegate their voting power to another member.
 * 8. `undelegateVote()`: Cancels vote delegation.
 * 9. `setQuorum(uint256 _newQuorum)`: Owner function to initially set or adjust the quorum for proposals (can be made governable later).
 * 10. `setVotingPeriod(uint256 _newVotingPeriod)`: Owner function to initially set or adjust the voting period (can be made governable later).
 * 11. `emergencyPauseGovernance()`: Owner function to pause governance actions in case of critical issues.
 * 12. `resumeGovernance()`: Owner function to resume governance actions after emergency pause.
 *
 * **Module Management:**
 * 13. `installModule(address _moduleAddress, string memory _moduleName, string memory _moduleDescription)`: Owner function to manually install a module (for initial setup or bypassing proposal process in specific cases - use with caution).
 * 14. `uninstallModule(address _moduleAddress)`: Owner/Governance function to uninstall a module.
 * 15. `getModuleAddress(string memory _moduleName)`: Retrieves the address of an installed module by its name.
 * 16. `getModuleInfo(string memory _moduleName)`: Retrieves information (name, description) about an installed module.
 * 17. `isModuleInstalled(address _moduleAddress)`: Checks if a module is currently installed.
 *
 * **Reputation & Contribution (Advanced Concept - Can be further refined with a separate Reputation Token/NFT):**
 * 18. `contribute(string memory _contributionDescription)`: Members can register contributions they make to the DAO (e.g., code, documentation, community work).
 * 19. `awardReputation(address _member, uint256 _reputationPoints, string memory _reason)`: Owner/Governance function to award reputation points to members for valuable contributions.
 * 20. `burnReputation(address _member, uint256 _reputationPoints, string memory _reason)`: Owner/Governance function to burn reputation points from members for negative actions (governance needed for fair process).
 * 21. `getReputation(address _member)`: Retrieves the reputation points of a member.
 * 22. `setReputationThresholdForProposal(uint256 _threshold)`: Owner function to set a reputation threshold required to create proposals (can be made governable).
 *
 * **Treasury & Resource Management (Illustrative - Real-world Treasury Management needs more complexity):**
 * 23. `deposit()`: Allows members to deposit Ether into the DAO treasury.
 * 24. `withdraw(uint256 _amount)`: Owner/Governance function to withdraw Ether from the treasury (governance needed for spending proposals).
 * 25. `moduleDeposit(address _moduleAddress)`: Allows depositing Ether specifically to a module's balance within the DAO.
 * 26. `moduleWithdraw(address _moduleAddress, uint256 _amount)`: Module function (or governance-controlled) to withdraw Ether from its module balance.
 * 27. `getTreasuryBalance()`: Retrieves the total Ether balance of the DAO treasury.
 * 28. `getModuleBalance(address _moduleAddress)`: Retrieves the Ether balance associated with a specific module.
 *
 * **Events:**
 *  - Events are emitted for key actions like proposal creation, voting, module installation, parameter changes, reputation updates, and treasury actions for transparency.
 */
contract AdaptiveModularDAO {
    // --- State Variables ---

    address public owner;
    uint256 public quorum; // Minimum percentage of votes needed for proposal to pass (e.g., 51 for 51%)
    uint256 public votingPeriod; // Duration of voting period in blocks
    bool public governancePaused;

    struct Module {
        address moduleAddress;
        string moduleName;
        string moduleDescription;
        bool installed;
    }
    mapping(string => Module) public modules; // Module name to Module struct
    address[] public moduleAddresses; // List of installed module addresses for iteration

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalState state;
        bytes data; // Generic data field to accommodate different proposal types
    }

    enum ProposalType {
        MODULE_INSTALL,
        MODULE_UNINSTALL,
        PARAMETER_CHANGE,
        GENERIC // For future extensibility
    }

    enum ProposalState {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        EXECUTED,
        CANCELLED
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    mapping(address => uint256) public reputationPoints; // Member reputation points
    uint256 public reputationThresholdForProposal; // Minimum reputation to create proposals

    mapping(address => address) public voteDelegations; // Member -> Delegatee mapping

    // --- Events ---
    event ModuleProposed(uint256 proposalId, address moduleAddress, string moduleName, string description, address proposer);
    event ModuleVoteCast(uint256 proposalId, address voter, bool support, uint256 votingPower);
    event ModuleProposalExecuted(uint256 proposalId, address moduleAddress);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeVoteCast(uint256 proposalId, address voter, bool support, uint256 votingPower);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event VoteDelegated(address delegator, address delegatee);
    event VoteUndelegated(address delegator);
    event ModuleInstalled(address moduleAddress, string moduleName, string description, address installer);
    event ModuleUninstalled(address moduleAddress, address uninstaller);
    event ReputationAwarded(address member, uint256 points, string reason, address granter);
    event ReputationBurned(address member, uint256 points, string reason, address burner);
    event ContributionRegistered(address contributor, string description);
    event Deposit(address depositor, uint256 amount);
    event Withdrawal(address recipient, uint256 amount);
    event ModuleDeposit(address moduleAddress, address depositor, uint256 amount);
    event ModuleWithdrawal(address moduleAddress, address recipient, uint256 amount);
    event GovernancePaused(address pauser);
    event GovernanceResumed(address resumer);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier governanceActive() {
        require(!governancePaused, "Governance is currently paused.");
        _;
    }

    modifier onlyModule(address _moduleAddress) {
        require(isModuleInstalled(_moduleAddress), "Module not installed.");
        // Consider adding more robust module authentication if needed
        // For simplicity, address check is sufficient for this example.
        _;
    }

    modifier hasReputationThreshold() {
        require(reputationPoints[msg.sender] >= reputationThresholdForProposal, "Insufficient reputation to create proposal.");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _initialQuorum, uint256 _initialVotingPeriod, uint256 _initialReputationThreshold) {
        owner = msg.sender;
        quorum = _initialQuorum;
        votingPeriod = _initialVotingPeriod;
        reputationThresholdForProposal = _initialReputationThreshold;
        governancePaused = false;
    }

    // --- Governance & Proposals ---

    function proposeModule(address _moduleAddress, string memory _moduleName, string memory _moduleDescription)
        external
        governanceActive
        hasReputationThreshold
    {
        require(_moduleAddress != address(0), "Invalid module address.");
        require(bytes(_moduleName).length > 0 && bytes(_moduleDescription).length > 0, "Module name and description required.");
        require(!isModuleInstalled(_moduleAddress), "Module already installed.");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.proposalType = ProposalType.MODULE_INSTALL;
        newProposal.description = string(abi.encodePacked("Install Module: ", _moduleName));
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingPeriod;
        newProposal.state = ProposalState.ACTIVE;
        newProposal.data = abi.encode(_moduleAddress, _moduleName, _moduleDescription); // Store module details in data

        emit ModuleProposed(proposalCount, _moduleAddress, _moduleName, _moduleDescription, msg.sender);
    }

    function voteOnModule(uint256 _proposalId, bool _support) external governanceActive {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.ACTIVE, "Proposal is not active.");
        require(block.number <= proposal.endTime, "Voting period has ended.");

        uint256 votingPower = getVotingPower(msg.sender); // Implement voting power logic (e.g., based on token holdings, reputation, etc.)

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit ModuleVoteCast(_proposalId, msg.sender, _support, votingPower);

        if (block.number == proposal.endTime) {
            _evaluateProposal(_proposalId);
        }
    }

    function executeModuleProposal(uint256 _proposalId) external governanceActive {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.PASSED, "Proposal must be passed to execute.");
        require(!proposal.executed, "Proposal already executed.");

        (address moduleAddress, string memory moduleName, string memory moduleDescription) = abi.decode(proposal.data, (address, string, string));

        _installModuleInternal(moduleAddress, moduleName, moduleDescription, proposal.proposer); // Internal install function

        proposal.state = ProposalState.EXECUTED;
        proposal.executed = true;
        emit ModuleProposalExecuted(_proposalId, moduleAddress);
    }

    function proposeParameterChange(string memory _parameterName, uint256 _newValue)
        external
        governanceActive
        hasReputationThreshold
    {
        require(bytes(_parameterName).length > 0, "Parameter name required.");
        // Add validation for parameter name and newValue if needed (e.g., restrict allowed parameters)

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.proposalType = ProposalType.PARAMETER_CHANGE;
        newProposal.description = string(abi.encodePacked("Change Parameter: ", _parameterName));
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingPeriod;
        newProposal.state = ProposalState.ACTIVE;
        newProposal.data = abi.encode(_parameterName, _newValue); // Store parameter name and new value

        emit ParameterChangeProposed(proposalCount, _parameterName, _newValue, msg.sender);
    }

    function voteOnParameterChange(uint256 _proposalId, bool _support) external governanceActive {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.ACTIVE, "Proposal is not active.");
        require(block.number <= proposal.endTime, "Voting period has ended.");

        uint256 votingPower = getVotingPower(msg.sender);

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit ParameterChangeVoteCast(_proposalId, msg.sender, _support, votingPower);

        if (block.number == proposal.endTime) {
            _evaluateProposal(_proposalId);
        }
    }

    function executeParameterChangeProposal(uint256 _proposalId) external governanceActive {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.PASSED, "Proposal must be passed to execute.");
        require(!proposal.executed, "Proposal already executed.");

        (string memory parameterName, uint256 newValue) = abi.decode(proposal.data, (string, uint256));

        if (keccak256(bytes(parameterName)) == keccak256(bytes("quorum"))) {
            quorum = newValue;
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("votingPeriod"))) {
            votingPeriod = newValue;
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("reputationThresholdForProposal"))) {
            reputationThresholdForProposal = newValue;
        } else {
            revert("Invalid parameter name for change."); // Or handle unknown parameters differently
        }

        proposal.state = ProposalState.EXECUTED;
        proposal.executed = true;
        emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
    }

    function delegateVote(address _delegatee) external governanceActive {
        require(_delegatee != address(0) && _delegatee != msg.sender, "Invalid delegatee address.");
        voteDelegations[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    function undelegateVote() external governanceActive {
        delete voteDelegations[msg.sender];
        emit VoteUndelegated(msg.sender);
    }

    function setQuorum(uint256 _newQuorum) external onlyOwner {
        quorum = _newQuorum;
    }

    function setVotingPeriod(uint256 _newVotingPeriod) external onlyOwner {
        votingPeriod = _newVotingPeriod;
    }

    function emergencyPauseGovernance() external onlyOwner {
        governancePaused = true;
        emit GovernancePaused(msg.sender);
    }

    function resumeGovernance() external onlyOwner {
        governancePaused = false;
        emit GovernanceResumed(msg.sender);
    }

    // --- Module Management ---

    function installModule(address _moduleAddress, string memory _moduleName, string memory _moduleDescription) external onlyOwner {
        _installModuleInternal(_moduleAddress, _moduleName, _moduleDescription, msg.sender);
    }

    function _installModuleInternal(address _moduleAddress, string memory _moduleName, string memory _moduleDescription, address _installer) internal {
        require(_moduleAddress != address(0), "Invalid module address.");
        require(bytes(_moduleName).length > 0 && bytes(_moduleDescription).length > 0, "Module name and description required.");
        require(!isModuleInstalled(_moduleAddress), "Module already installed.");

        modules[_moduleName] = Module({
            moduleAddress: _moduleAddress,
            moduleName: _moduleName,
            moduleDescription: _moduleDescription,
            installed: true
        });
        moduleAddresses.push(_moduleAddress);

        emit ModuleInstalled(_moduleAddress, _moduleName, _moduleDescription, _installer);
    }


    function uninstallModule(address _moduleAddress) external governanceActive onlyOwner { // Or make governable
        require(isModuleInstalled(_moduleAddress), "Module not installed.");

        string memory moduleNameToUninstall;
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
            if (moduleAddresses[i] == _moduleAddress) {
                moduleNameToUninstall = modules[getModuleNameByAddress(_moduleAddress)].moduleName; // Find module name
                moduleAddresses[i] = moduleAddresses[moduleAddresses.length - 1]; // Replace with last element
                moduleAddresses.pop(); // Remove last element (effectively removing _moduleAddress)
                break;
            }
        }
        delete modules[moduleNameToUninstall]; // Remove from modules mapping

        emit ModuleUninstalled(_moduleAddress, msg.sender);
    }

    function getModuleAddress(string memory _moduleName) external view returns (address) {
        return modules[_moduleName].moduleAddress;
    }

    function getModuleInfo(string memory _moduleName) external view returns (string memory moduleName, string memory description, bool installed) {
        Module storage module = modules[_moduleName];
        return (module.moduleName, module.moduleDescription, module.installed);
    }

    function isModuleInstalled(address _moduleAddress) public view returns (bool) {
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
            if (moduleAddresses[i] == _moduleAddress) {
                return true;
            }
        }
        return false;
    }

    function getModuleNameByAddress(address _moduleAddress) public view returns (string memory) {
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
            if (moduleAddresses[i] == _moduleAddress) {
                for (uint256 j=0; j < moduleAddresses.length; j++) {
                    string memory currentModuleName = modules[getModuleNameByAddress(moduleAddresses[j])].moduleName;
                     if (modules[currentModuleName].moduleAddress == _moduleAddress) {
                        return currentModuleName;
                    }
                }
            }
        }
        return ""; // Return empty string if not found (shouldn't happen if isModuleInstalled is used correctly)
    }


    // --- Reputation & Contribution ---

    function contribute(string memory _contributionDescription) external governanceActive {
        require(bytes(_contributionDescription).length > 0, "Contribution description required.");
        // Consider adding more structured contribution types and verification mechanisms in a real-world scenario.
        emit ContributionRegistered(msg.sender, _contributionDescription);
    }

    function awardReputation(address _member, uint256 _reputationPoints, string memory _reason) external onlyOwner governanceActive { // Make governable for decentralization
        require(_member != address(0), "Invalid member address.");
        require(_reputationPoints > 0, "Reputation points must be positive.");
        reputationPoints[_member] += _reputationPoints;
        emit ReputationAwarded(_member, _reputationPoints, _reason, msg.sender);
    }

    function burnReputation(address _member, uint256 _reputationPoints, string memory _reason) external onlyOwner governanceActive { // Make governable for decentralization
        require(_member != address(0), "Invalid member address.");
        require(_reputationPoints > 0, "Reputation points must be positive.");
        require(reputationPoints[_member] >= _reputationPoints, "Not enough reputation points to burn.");
        reputationPoints[_member] -= _reputationPoints;
        emit ReputationBurned(_member, _reputationPoints, _reason, msg.sender);
    }

    function getReputation(address _member) external view returns (uint256) {
        return reputationPoints[_member];
    }

    function setReputationThresholdForProposal(uint256 _threshold) external onlyOwner {
        reputationThresholdForProposal = _threshold;
    }

    // --- Treasury & Resource Management ---

    function deposit() external payable governanceActive {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external onlyOwner governanceActive { // Make governable for decentralization
        require(address(this).balance >= _amount, "Insufficient DAO treasury balance.");
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    function moduleDeposit(address _moduleAddress) external payable governanceActive onlyModule(_moduleAddress) {
        // In a real system, modules might have their own more complex deposit/withdrawal logic.
        // This is a simplified example for illustrating module-specific treasury.
        payable(_moduleAddress).transfer(msg.value); // Directly transfer to module contract
        emit ModuleDeposit(_moduleAddress, msg.sender, msg.value);
    }

    function moduleWithdraw(address _moduleAddress, uint256 _amount) external governanceActive onlyModule(_moduleAddress) {
        // Module needs to have logic to prevent unauthorized withdrawals.
        // This is a simplified example and assumes module has internal checks.
        require(address(_moduleAddress).balance >= _amount, "Insufficient module balance.");
        payable(msg.sender).transfer(_amount);
        emit ModuleWithdrawal(_moduleAddress, msg.sender, _amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getModuleBalance(address _moduleAddress) external view onlyModule(_moduleAddress) returns (uint256) {
        return address(_moduleAddress).balance;
    }

    // --- Internal Helper Functions ---

    function _evaluateProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.ACTIVE) return; // Prevent re-evaluation

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumVotesNeeded = (totalVotingPower() * quorum) / 100; // Calculate quorum based on total voting power

        if (proposal.votesFor >= quorumVotesNeeded && proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.PASSED;
        } else {
            proposal.state = ProposalState.REJECTED;
        }
    }

    function getVotingPower(address _voter) public view returns (uint256) {
        address delegatee = voteDelegations[_voter];
        if (delegatee != address(0)) {
            return getVotingPower(delegatee); // Recursive delegation (limit recursion depth in real implementation)
        }
        // In a real DAO, voting power would likely be based on token holdings, reputation, or other factors.
        // For this example, we'll simply return 1 as a basic representation of voting power per member.
        return 1;
    }

    function totalVotingPower() public view returns (uint256) {
        // In a real DAO, this would be a more complex calculation based on token supply, etc.
        // For this example, we'll return a placeholder value.
        // Consider tracking active DAO members or token holders to calculate total voting power.
        return 100; // Placeholder total voting power - needs to be dynamically calculated in a real DAO
    }
}
```