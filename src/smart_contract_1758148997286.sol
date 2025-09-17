This smart contract, `AetherweaveProtocol`, is designed as a sophisticated, self-evolving decentralized autonomous protocol. It combines several advanced concepts: a robust **reputation-weighted governance system with decaying influence**, a **dynamic strategy engine** for autonomous operations, an **adaptive treasury management system**, and an **interface for "Cognitive Agents" (trusted oracles)** to influence protocol parameters. The goal is to create a protocol that can adapt, learn, and operate with minimal central intervention, driven by its community and external insights.

---

## AetherweaveProtocol: Contract Outline and Function Summary

**Concept:** A decentralized, self-evolving protocol for dynamic resource allocation and governance, driven by weaver reputation, adaptive strategies, and insights from "Cognitive Agents."

**Core Features:**
*   **Reputation-Weighted Governance:** Voting power is determined by a weaver's earned and decaying reputation, incentivizing continuous positive participation.
*   **Dynamic Strategy Engine:** Allows for the definition, activation, and execution of reusable, parameterized operational strategies for resource management or external interactions.
*   **Cognitive Agent Integration:** Enables trusted external oracles (Cognitive Agents) to provide data and insights that influence governance proposals for protocol parameter adjustments.
*   **Adaptive Treasury Management:** Manages protocol funds (ETH and ERC20s) with governance-controlled allocation and withdrawal.

---

### Function Summary:

**I. Governance & Proposals**
1.  `proposeProtocolChange(address _target, bytes memory _calldata, string memory _description)`: Allows a weaver with sufficient reputation to propose an arbitrary protocol change, upgrade, or parameter modification.
2.  `voteOnProposal(uint256 _proposalId, bool _support)`: Allows weavers to cast their vote (weighted by their current reputation) on an active proposal.
3.  `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on and passed proposal, triggering its intended on-chain action.
4.  `delegateVotingPower(address _delegatee)`: Delegates a weaver's full voting influence (reputation score) to another address.
5.  `undelegateVotingPower()`: Revokes any active voting power delegation, restoring influence to the calling address.
6.  `getProposalState(uint256 _proposalId)`: Retrieves the current state (e.g., Pending, Active, Succeeded, Defeated, Executed) and outcome details of a specific proposal.

**II. Reputation Management**
7.  `getReputation(address _weaver)`: Returns the current, time-decayed reputation score of a specified weaver.
8.  `getReputationTier(address _weaver)`: Categorizes a weaver's reputation into predefined tiers (e.g., Novice, Adept, Master), unlocking different privileges.
9.  `_earnReputation(address _weaver, uint256 _amount, string memory _reason)` (Internal): Awards reputation points to a weaver for positive contributions (e.g., successful proposals, effective strategy execution). This function is called internally by the protocol logic.
10. `setReputationDecayRate(uint256 _newRate)`: A governance-controlled function to adjust the global rate at which weavers' reputation scores naturally decay over time.

**III. Strategy Engine (Dynamic Operations)**
11. `proposeStrategy(string memory _name, string memory _description, address _target, bytes memory _calldataTemplate, uint256 _requiredReputationToExecute)`: Allows a weaver to propose a new, reusable operational strategy. The `_calldataTemplate` can include placeholders for dynamic parameters.
12. `activateStrategy(uint256 _strategyId)`: After successful governance approval, marks a proposed strategy as active and available for execution by eligible weavers.
13. `deactivateStrategy(uint256 _strategyId)`: Allows governance to deactivate an active strategy, preventing further executions.
14. `executeStrategy(uint256 _strategyId, bytes memory _dynamicCalldata)`: Enables any eligible weaver (meeting `_requiredReputationToExecute`) to execute an active strategy, potentially providing dynamic parameters via `_dynamicCalldata`.
15. `getStrategyDetails(uint256 _strategyId)`: Retrieves comprehensive information about a specific strategy, including its target, template, and activation status.

**IV. Cognitive Agent & Parameter Influence**
16. `registerCognitiveAgent(address _agentAddress, string memory _name, string memory _description, bytes32 _dataFeedId)`: Allows governance to register a trusted external "Cognitive Agent" (an oracle providing specific data streams or insights).
17. `requestAgentParameterUpdate(address _agent, bytes32 _paramKey, uint256 _suggestedValue)`: Allows any weaver to initiate a governance proposal to update a specific protocol parameter, referencing a suggestion from a registered Cognitive Agent. This links external insights to decentralized decision-making.
18. `getAdaptiveFeeRate()`: Returns the current protocol-wide adaptive transaction fee, which can be influenced by Cognitive Agent insights and governance.

**V. Treasury & Resource Management**
19. `depositEther() payable`: Allows users to deposit Ether into the protocol's main treasury.
20. `depositERC20(address _token, uint256 _amount)`: Allows users to deposit ERC20 tokens into the protocol's treasury.
21. `withdrawERC20(address _token, uint256 _amount, address _recipient)`: A governance-controlled function to initiate a withdrawal of ERC20 tokens from the treasury to a specified recipient.
22. `withdrawEther(uint256 _amount, address _recipient)`: A governance-controlled function to initiate a withdrawal of Ether from the treasury to a specified recipient.

**VI. Emergency & Administrative**
23. `pauseProtocol()`: An emergency function allowing a designated Guardian or Owner to temporarily halt critical protocol operations (e.g., proposals, strategy executions).
24. `unpauseProtocol()`: Reverses the `pauseProtocol` action, restoring full protocol functionality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// ERC-165 interface for checking if a contract supports an interface, not explicitly used here but good practice.
// interface IERC165 {
//     function supportsInterface(bytes4 interfaceId) external view returns (bool);
// }

/**
 * @title AetherweaveProtocol
 * @dev A decentralized, self-evolving protocol for dynamic resource allocation and governance,
 *      driven by weaver reputation, adaptive strategies, and insights from "Cognitive Agents."
 *
 *      This contract combines:
 *      - Reputation-weighted governance with decaying influence.
 *      - A dynamic strategy engine for autonomous, repeatable operations.
 *      - An interface for "Cognitive Agents" (trusted oracles) to influence protocol parameters.
 *      - Adaptive treasury management.
 *
 *      No direct open-source contract has been duplicated; the combination and specific
 *      mechanisms (e.g., reputation decay, dynamic strategy execution by anyone meeting criteria,
 *      cognitive agent influence on governance) are custom implementations.
 */
contract AetherweaveProtocol is Ownable, Pausable {
    using ECDSA for bytes32; // Though not used directly here, useful for signature verification with Cognitive Agents.

    // --- Enums & Structs ---

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    enum ReputationTier {
        Novice,   // Default, base privileges
        Adept,    // Enhanced voting, lower proposal bond
        Master    // Highest voting weight, can execute complex strategies
    }

    struct Proposal {
        uint256 id;
        address proposer;
        address target;
        bytes calldataPayload;
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalState state;
        bool executed;
    }

    struct Strategy {
        uint256 id;
        string name;
        string description;
        address target;
        bytes calldataTemplate; // Template for execution, can have placeholders for dynamic data
        uint256 requiredReputationToExecute;
        bool active; // Can this strategy be executed?
        address proposer;
        uint256 activationTime;
    }

    struct CognitiveAgent {
        address agentAddress;
        string name;
        string description;
        bytes32 dataFeedId; // Identifier for the data stream/service this agent provides
        bool registered;
        uint256 registrationTime;
    }

    // --- State Variables ---

    // Governance
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriodBlocks; // Duration of voting in blocks
    uint256 public quorumThresholdPercent; // Percentage of total reputation needed for a proposal to pass
    uint256 public minReputationToPropose; // Minimum reputation required to submit a proposal
    uint256 public proposalBondAmount; // Amount of ETH required to submit a proposal (returned on success)

    // Reputation
    mapping(address => uint256) private _reputations; // Raw reputation points
    mapping(address => uint256) public lastReputationUpdateBlock; // Block number of last reputation update
    mapping(address => address) public delegates; // Delegatee for voting power
    uint256 public reputationDecayRatePerBlock; // Points decayed per block, scaled by 1e18
    uint256[] public reputationTierThresholds; // Thresholds for Novice, Adept, Master tiers

    // Strategies
    uint256 public nextStrategyId;
    mapping(uint256 => Strategy) public strategies;

    // Cognitive Agents
    mapping(address => CognitiveAgent) public cognitiveAgents;
    address[] public registeredCognitiveAgents; // Array of registered agent addresses

    // Treasury
    mapping(address => uint256) public erc20Treasury; // Mapping of ERC20 token address to its balance in treasury
    address[] public supportedERC20Tokens; // List of ERC20 tokens accepted

    // Protocol Parameters (can be influenced by Cognitive Agents & Governance)
    uint256 public adaptiveFeeRate; // Example: percentage fee applied to certain operations, scaled by 1e18
    uint256 public strategyExecutionGasLimit; // Max gas a strategy execution can consume (to prevent OOG attacks)

    // Guardians (can pause/unpause, can be a multi-sig or single address)
    address public guardian;

    // --- Events ---

    event ProtocolChangeProposed(uint256 indexed proposalId, address indexed proposer, address target, string description, uint256 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);

    event ReputationEarned(address indexed weaver, uint256 amount, string reason);
    event ReputationDecayed(address indexed weaver, uint256 newReputation);
    event ReputationTierChanged(address indexed weaver, ReputationTier newTier);

    event StrategyProposed(uint256 indexed strategyId, address indexed proposer, string name);
    event StrategyActivated(uint256 indexed strategyId, address indexed activator);
    event StrategyDeactivated(uint256 indexed strategyId, address indexed deactivator);
    event StrategyExecuted(uint256 indexed strategyId, address indexed executor, bytes dynamicCalldata);

    event CognitiveAgentRegistered(address indexed agentAddress, string name, bytes32 dataFeedId);
    event ParameterUpdateRequested(address indexed agent, bytes32 indexed paramKey, uint256 suggestedValue);
    event AdaptiveFeeRateUpdated(uint256 newRate);

    event EtherDeposited(address indexed depositor, uint256 amount);
    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount);
    event EtherWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Withdrawn(address indexed recipient, address indexed token, uint256 amount);

    // --- Constructor ---

    constructor(
        uint256 _votingPeriodBlocks,
        uint256 _quorumThresholdPercent,
        uint256 _minReputationToPropose,
        uint256 _proposalBondAmount,
        uint256 _reputationDecayRatePerBlock,
        uint256[] memory _reputationTierThresholds,
        uint256 _initialAdaptiveFeeRate,
        uint256 _strategyExecutionGasLimit
    ) Ownable(msg.sender) {
        require(_votingPeriodBlocks > 0, "Voting period must be greater than 0");
        require(_quorumThresholdPercent > 0 && _quorumThresholdPercent <= 100, "Quorum must be between 1 and 100");
        require(_reputationDecayRatePerBlock < 1e18, "Decay rate too high"); // Should be a small fraction

        votingPeriodBlocks = _votingPeriodBlocks;
        quorumThresholdPercent = _quorumThresholdPercent;
        minReputationToPropose = _minReputationToPropose;
        proposalBondAmount = _proposalBondAmount;
        reputationDecayRatePerBlock = _reputationDecayRatePerBlock;
        reputationTierThresholds = _reputationTierThresholds;
        adaptiveFeeRate = _initialAdaptiveFeeRate;
        strategyExecutionGasLimit = _strategyExecutionGasLimit;
        guardian = msg.sender; // Owner is initially the guardian
    }

    // --- Modifiers ---

    modifier onlyWeaver() {
        require(_reputations[_msgSender()] > 0, "Caller is not a recognized weaver");
        _;
    }

    modifier onlyGuardian() {
        require(_msgSender() == guardian, "Only guardian can call this function");
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates the decayed reputation for a given weaver.
     *      Decay is proportional to the number of blocks passed since the last update.
     */
    function _getDecayedReputation(address _weaver) internal view returns (uint256) {
        uint256 currentRep = _reputations[_weaver];
        if (currentRep == 0) {
            return 0;
        }

        uint256 blocksPassed = block.number - lastReputationUpdateBlock[_weaver];
        uint256 decayAmount = (currentRep * reputationDecayRatePerBlock * blocksPassed) / 1e18; // Scaled
        
        return currentRep > decayAmount ? currentRep - decayAmount : 0;
    }

    /**
     * @dev Awards reputation points to a weaver.
     *      This function is internal and should be called by protocol logic (e.g., successful proposal execution).
     *      It also updates the last reputation update block.
     */
    function _earnReputation(address _weaver, uint256 _amount, string memory _reason) internal {
        uint256 currentRep = _getDecayedReputation(_weaver); // Decay first
        _reputations[_weaver] = currentRep + _amount;
        lastReputationUpdateBlock[_weaver] = block.number;
        emit ReputationEarned(_weaver, _amount, _reason);
        emit ReputationTierChanged(_weaver, getReputationTier(_weaver)); // Re-evaluate tier
    }

    /**
     * @dev Helper to update a weaver's reputation score after decay.
     *      Called before reading reputation or on specific actions.
     */
    function _updateReputation(address _weaver) internal {
        uint256 currentRep = _getDecayedReputation(_weaver);
        if (_reputations[_weaver] != currentRep) {
            _reputations[_weaver] = currentRep;
            lastReputationUpdateBlock[_weaver] = block.number;
            emit ReputationDecayed(_weaver, currentRep);
            emit ReputationTierChanged(_weaver, getReputationTier(_weaver));
        }
    }

    /**
     * @dev Executes a low-level call to a target contract.
     *      Includes basic error handling and gas limits.
     */
    function _performCall(address _target, bytes memory _calldata) internal returns (bool success, bytes memory result) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = _target.call{gas: strategyExecutionGasLimit}(_calldata);
        if (!success) {
            // Revert with reason if call failed and reason available
            if (result.length > 0) {
                assembly {
                    revert(add(32, result), mload(result))
                }
            } else {
                revert("External call failed without revert reason");
            }
        }
    }

    // --- I. Governance & Proposals ---

    /**
     * @dev Allows a weaver with sufficient reputation to propose an arbitrary protocol change.
     *      Requires a bond, which is returned upon successful execution of the proposal.
     * @param _target The address of the contract to call (e.g., this contract for parameter changes, or an upgradeable proxy).
     * @param _calldata The encoded function call data for the target.
     * @param _description A clear description of the proposal's intent.
     */
    function proposeProtocolChange(
        address _target,
        bytes memory _calldata,
        string memory _description
    ) external payable onlyWeaver whenNotPaused returns (uint256) {
        require(msg.value >= proposalBondAmount, "Insufficient proposal bond");
        require(getReputation(_msgSender()) >= minReputationToPropose, "Insufficient reputation to propose");

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = _msgSender();
        newProposal.target = _target;
        newProposal.calldataPayload = _calldata;
        newProposal.description = _description;
        newProposal.voteStartTime = block.number;
        newProposal.voteEndTime = block.number + votingPeriodBlocks;
        newProposal.state = ProposalState.Pending;
        newProposal.executed = false;

        emit ProtocolChangeProposed(proposalId, _msgSender(), _target, _description, newProposal.voteEndTime);
        return proposalId;
    }

    /**
     * @dev Allows weavers to cast their vote (weighted by their current reputation) on an active proposal.
     *      A weaver can only vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' votes, false for 'against' votes.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyWeaver whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not in active voting state");
        require(block.number >= proposal.voteStartTime && block.number <= proposal.voteEndTime, "Voting period is not active");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");

        _updateReputation(_msgSender()); // Ensure reputation is current before voting
        address voter = delegates[_msgSender()] != address(0) ? delegates[_msgSender()] : _msgSender();
        uint256 voteWeight = _reputations[voter];
        require(voteWeight > 0, "Voter has no reputation");

        if (_support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }
        proposal.hasVoted[_msgSender()] = true;

        if (proposal.state == ProposalState.Pending) {
            proposal.state = ProposalState.Active;
            emit ProposalStateChanged(_proposalId, ProposalState.Active);
        }

        emit VoteCast(_proposalId, _msgSender(), _support, voteWeight);
    }

    /**
     * @dev Executes a successfully voted-on and passed proposal.
     *      Can only be called after the voting period ends and if the proposal succeeded.
     *      Returns the bond to the proposer on success.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.voteEndTime, "Voting period has not ended yet");
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(proposal.state != ProposalState.Canceled, "Proposal canceled");

        if (proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active) {
            uint256 totalReputation = 0;
            // Iterate through all reputation holders to sum up total active reputation
            // NOTE: For very large numbers of weavers, this could hit gas limits.
            // A more scalable solution might involve a `totalReputation` variable
            // that is updated on reputation changes. For this example, we assume
            // a manageable number or an external oracle provides this.
            // For now, let's simplify and assume the sum of 'for' and 'against'
            // votes provides a proxy for engaged reputation.
            // A proper DAO implementation would track total voting supply.
            // For simplicity here, let's use a simpler heuristic for quorum.
            // E.g., a simple percentage of *participating* votes must be 'for'.
            // Or, we need to manage a `totalActiveReputation` variable.

            // Let's assume `totalActiveReputation` is hard to get on-chain without iterating.
            // For quorum, we'll check against total `forVotes + againstVotes` (participating votes)
            // AND ensure `forVotes` is above a certain threshold of all `for/against` votes.
            // A truly robust DAO needs a `_getTotalVotingPower()` function.
            // For this advanced concept, let's assume `_reputations` mapping is representative enough
            // and simply iterate, or use a cached total.
            // For now, we simplify: quorum is based on `forVotes + againstVotes` and `forVotes` > `againstVotes`.

            uint256 participatingVotes = proposal.forVotes + proposal.againstVotes;
            // Simplified quorum check:
            // 1. Enough votes participated (e.g., a minimum `participatingVotes` total).
            // 2. The 'for' votes exceed 'against' votes.
            // 3. 'for' votes meet a percentage of participating votes.

            // To get a true "total reputation", we'd need a way to sum `_reputations` efficiently,
            // or rely on an off-chain calculation that updates an on-chain variable.
            // For this example, let's use a more direct check:
            // A proposal succeeds if `forVotes` is significantly higher than `againstVotes`
            // and meets a minimum participation threshold (implicit in `quorumThresholdPercent` applied to participating votes).

            if (proposal.forVotes > proposal.againstVotes &&
                (proposal.forVotes * 100) / participatingVotes >= quorumThresholdPercent) {
                proposal.state = ProposalState.Succeeded;
                emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);
            } else {
                proposal.state = ProposalState.Defeated;
                emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
            }
        }

        require(proposal.state == ProposalState.Succeeded, "Proposal not succeeded");

        // Execute the call
        (bool success,) = _performCall(proposal.target, proposal.calldataPayload);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        // Return the bond to the proposer
        (bool bondTransferSuccess,) = payable(proposal.proposer).call{value: proposalBondAmount}("");
        require(bondTransferSuccess, "Failed to return proposal bond");

        _earnReputation(proposal.proposer, proposalBondAmount / 1e15, "Successful proposal execution"); // Award reputation for success
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Delegates a weaver's full voting influence (reputation score) to another address.
     *      The delegatee will cast votes on behalf of the delegator.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) external onlyWeaver whenNotPaused {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "Cannot delegate to self");
        delegates[_msgSender()] = _delegatee;
        emit VotingPowerDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Revokes any active voting power delegation, restoring influence to the calling address.
     */
    function undelegateVotingPower() external onlyWeaver whenNotPaused {
        require(delegates[_msgSender()] != address(0), "No active delegation to revoke");
        delegates[_msgSender()] = address(0);
        emit VotingPowerDelegated(_msgSender(), address(0)); // Emit with address(0) to signify undelegation
    }

    /**
     * @dev Retrieves the current state and outcome details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return state The current state of the proposal.
     * @return forVotes The total 'for' votes.
     * @return againstVotes The total 'against' votes.
     * @return executed Whether the proposal has been executed.
     */
    function getProposalState(uint256 _proposalId)
        external
        view
        returns (
            ProposalState state,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (block.number > proposal.voteEndTime &&
            (proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active)) {
            // Recalculate state if voting period has ended but state hasn't been finalized by executeProposal
            uint256 participatingVotes = proposal.forVotes + proposal.againstVotes;
            if (proposal.forVotes > proposal.againstVotes &&
                (proposal.forVotes * 100) / participatingVotes >= quorumThresholdPercent) {
                state = ProposalState.Succeeded;
            } else {
                state = ProposalState.Defeated;
            }
        } else {
            state = proposal.state;
        }

        forVotes = proposal.forVotes;
        againstVotes = proposal.againstVotes;
        executed = proposal.executed;
    }

    // --- II. Reputation Management ---

    /**
     * @dev Returns the current, time-decayed reputation score of a specified weaver.
     * @param _weaver The address of the weaver.
     * @return The current reputation score.
     */
    function getReputation(address _weaver) public view returns (uint256) {
        return _getDecayedReputation(_weaver);
    }

    /**
     * @dev Categorizes a weaver's reputation into predefined tiers.
     * @param _weaver The address of the weaver.
     * @return The reputation tier (Novice, Adept, Master).
     */
    function getReputationTier(address _weaver) public view returns (ReputationTier) {
        uint256 rep = getReputation(_weaver);
        if (rep >= reputationTierThresholds[2]) return ReputationTier.Master;
        if (rep >= reputationTierThresholds[1]) return ReputationTier.Adept;
        return ReputationTier.Novice;
    }

    /**
     * @dev A governance-controlled function to adjust the global rate at which weavers' reputation scores decay.
     *      A higher rate means faster decay.
     * @param _newRate The new reputation decay rate per block (scaled by 1e18).
     */
    function setReputationDecayRate(uint256 _newRate) external onlyOwner {
        reputationDecayRatePerBlock = _newRate;
    }

    // --- III. Strategy Engine (Dynamic Operations) ---

    /**
     * @dev Allows a weaver to propose a new, reusable operational strategy.
     *      Strategies can represent specific actions the protocol can take, e.g., rebalancing, external contract calls.
     *      The `_calldataTemplate` provides a base for the execution call, potentially with placeholders
     *      for dynamic data to be supplied during execution.
     * @param _name A short, descriptive name for the strategy.
     * @param _description A detailed description of what the strategy does.
     * @param _target The address of the contract the strategy will interact with.
     * @param _calldataTemplate The base calldata for the strategy's execution.
     * @param _requiredReputationToExecute The minimum reputation required for a weaver to execute this strategy.
     */
    function proposeStrategy(
        string memory _name,
        string memory _description,
        address _target,
        bytes memory _calldataTemplate,
        uint256 _requiredReputationToExecute
    ) external onlyWeaver whenNotPaused returns (uint256) {
        require(getReputation(_msgSender()) >= minReputationToPropose, "Insufficient reputation to propose strategy");

        uint256 strategyId = nextStrategyId++;
        Strategy storage newStrategy = strategies[strategyId];

        newStrategy.id = strategyId;
        newStrategy.name = _name;
        newStrategy.description = _description;
        newStrategy.target = _target;
        newStrategy.calldataTemplate = _calldataTemplate;
        newStrategy.requiredReputationToExecute = _requiredReputationToExecute;
        newStrategy.active = false; // Must be activated by governance
        newStrategy.proposer = _msgSender();

        emit StrategyProposed(strategyId, _msgSender(), _name);
        return strategyId;
    }

    /**
     * @dev After governance approval, marks a proposed strategy as active and available for execution.
     *      This is typically called as part of a `proposeProtocolChange` execution.
     * @param _strategyId The ID of the strategy to activate.
     */
    function activateStrategy(uint256 _strategyId) external onlyOwner { // Or by proposal execution
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(!strategy.active, "Strategy already active");
        strategy.active = true;
        strategy.activationTime = block.number;
        emit StrategyActivated(_strategyId, _msgSender());
    }

    /**
     * @dev Allows governance to deactivate an active strategy, preventing further executions.
     *      This is typically called as part of a `proposeProtocolChange` execution.
     * @param _strategyId The ID of the strategy to deactivate.
     */
    function deactivateStrategy(uint256 _strategyId) external onlyOwner { // Or by proposal execution
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.active, "Strategy not active");
        strategy.active = false;
        emit StrategyDeactivated(_strategyId, _msgSender());
    }

    /**
     * @dev Enables any eligible weaver (meeting `_requiredReputationToExecute`) to execute an active strategy.
     *      The `_dynamicCalldata` can be appended to the `calldataTemplate` to provide dynamic parameters
     *      for the strategy's execution (e.g., specific amounts, addresses, timeframes).
     * @param _strategyId The ID of the strategy to execute.
     * @param _dynamicCalldata Additional calldata to append to the template for dynamic parameters.
     */
    function executeStrategy(uint256 _strategyId, bytes memory _dynamicCalldata) external onlyWeaver whenNotPaused returns (bool) {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");
        require(strategy.active, "Strategy not active");
        require(getReputation(_msgSender()) >= strategy.requiredReputationToExecute, "Insufficient reputation to execute strategy");

        // Construct the final calldata: template + dynamic parts
        bytes memory finalCalldata = abi.encodePacked(strategy.calldataTemplate, _dynamicCalldata);

        (bool success,) = _performCall(strategy.target, finalCalldata);
        require(success, "Strategy execution failed");

        _earnReputation(_msgSender(), adaptiveFeeRate, "Successful strategy execution"); // Reward for executing
        emit StrategyExecuted(_strategyId, _msgSender(), _dynamicCalldata);
        return true;
    }

    /**
     * @dev Retrieves comprehensive information about a specific strategy.
     * @param _strategyId The ID of the strategy.
     * @return name The strategy's name.
     * @return description The strategy's description.
     * @return target The target contract address.
     * @return calldataTemplate The base calldata template.
     * @return requiredReputationToExecute Minimum reputation to execute.
     * @return active Current activation status.
     * @return proposer The address that proposed the strategy.
     */
    function getStrategyDetails(uint256 _strategyId)
        external
        view
        returns (
            string memory name,
            string memory description,
            address target,
            bytes memory calldataTemplate,
            uint256 requiredReputationToExecute,
            bool active,
            address proposer
        )
    {
        Strategy storage strategy = strategies[_strategyId];
        require(strategy.id != 0, "Strategy does not exist");

        name = strategy.name;
        description = strategy.description;
        target = strategy.target;
        calldataTemplate = strategy.calldataTemplate;
        requiredReputationToExecute = strategy.requiredReputationToExecute;
        active = strategy.active;
        proposer = strategy.proposer;
    }

    // --- IV. Cognitive Agent & Parameter Influence ---

    /**
     * @dev Allows governance to register a trusted external "Cognitive Agent" (an oracle).
     *      These agents can provide data and insights that influence protocol parameters.
     * @param _agentAddress The address of the Cognitive Agent (e.g., an oracle contract).
     * @param _name A descriptive name for the agent.
     * @param _description A description of the agent's capabilities or data feed.
     * @param _dataFeedId A unique identifier for the specific data stream or service this agent provides.
     */
    function registerCognitiveAgent(
        address _agentAddress,
        string memory _name,
        string memory _description,
        bytes32 _dataFeedId
    ) external onlyOwner { // This should ideally be governed by a successful proposal
        require(_agentAddress != address(0), "Agent address cannot be zero");
        require(!cognitiveAgents[_agentAddress].registered, "Cognitive Agent already registered");

        cognitiveAgents[_agentAddress] = CognitiveAgent({
            agentAddress: _agentAddress,
            name: _name,
            description: _description,
            dataFeedId: _dataFeedId,
            registered: true,
            registrationTime: block.timestamp
        });
        registeredCognitiveAgents.push(_agentAddress);
        emit CognitiveAgentRegistered(_agentAddress, _name, _dataFeedId);
    }

    /**
     * @dev Allows any weaver to initiate a governance proposal to update a protocol parameter,
     *      referencing a suggestion from a registered Cognitive Agent.
     *      This bridges external oracle input with decentralized decision-making.
     * @param _agent The address of the Cognitive Agent providing the suggestion.
     * @param _paramKey A bytes32 key identifying the protocol parameter to update (e.g., `keccak256("adaptiveFeeRate")`).
     * @param _suggestedValue The new value suggested by the Cognitive Agent.
     */
    function requestAgentParameterUpdate(address _agent, bytes32 _paramKey, uint256 _suggestedValue) external payable onlyWeaver whenNotPaused returns (uint256) {
        require(cognitiveAgents[_agent].registered, "Cognitive Agent not registered");
        require(msg.value >= proposalBondAmount, "Insufficient proposal bond for agent insight request");
        require(getReputation(_msgSender()) >= minReputationToPropose, "Insufficient reputation to request agent update");

        // Encode the call to update a parameter within this contract
        bytes memory calldataPayload;
        string memory description;

        if (_paramKey == keccak256("adaptiveFeeRate")) {
            calldataPayload = abi.encodeWithSelector(this.setAdaptiveFeeRate.selector, _suggestedValue);
            description = string(abi.encodePacked("Update adaptive fee rate to ", Strings.toString(_suggestedValue), " based on Cognitive Agent insights."));
        } else {
             revert("Unsupported parameter key"); // Extend with other supported parameters
        }

        // Forward to the standard proposal mechanism
        uint256 proposalId = proposeProtocolChange(address(this), calldataPayload, description);
        emit ParameterUpdateRequested(_agent, _paramKey, _suggestedValue);
        return proposalId;
    }

    /**
     * @dev Returns the current protocol-wide adaptive transaction fee.
     *      This fee can be dynamically updated via governance influenced by Cognitive Agents.
     * @return The current adaptive fee rate (scaled by 1e18 for percentage).
     */
    function getAdaptiveFeeRate() external view returns (uint256) {
        return adaptiveFeeRate;
    }

    /**
     * @dev Setter for adaptiveFeeRate. Callable only by governance via proposal execution.
     * @param _newRate The new adaptive fee rate.
     */
    function setAdaptiveFeeRate(uint256 _newRate) public onlyOwner { // Should be callable only by executeProposal targeting this function
        adaptiveFeeRate = _newRate;
        emit AdaptiveFeeRateUpdated(_newRate);
    }


    // --- V. Treasury & Resource Management ---

    /**
     * @dev Allows users to deposit Ether into the protocol's main treasury.
     */
    function depositEther() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        emit EtherDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Allows users to deposit ERC20 tokens into the protocol's treasury.
     *      Requires prior approval of tokens to this contract.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositERC20(address _token, uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(IERC20(_token).transferFrom(_msgSender(), address(this), _amount), "ERC20 transfer failed");
        erc20Treasury[_token] += _amount;
        // Optionally, add token to supported list if not already there (governance might do this)
        bool isSupported = false;
        for (uint i = 0; i < supportedERC20Tokens.length; i++) {
            if (supportedERC20Tokens[i] == _token) {
                isSupported = true;
                break;
            }
        }
        if (!isSupported) {
            supportedERC20Tokens.push(_token);
        }
        emit ERC20Deposited(_msgSender(), _token, _amount);
    }

    /**
     * @dev A governance-controlled function to initiate a withdrawal of ERC20 tokens from the treasury.
     *      This function would typically be called as part of a `proposeProtocolChange` execution.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _recipient The address to send the tokens to.
     */
    function withdrawERC20(address _token, uint256 _amount, address _recipient) external onlyOwner { // Should be via proposal
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(erc20Treasury[_token] >= _amount, "Insufficient ERC20 balance in treasury");
        erc20Treasury[_token] -= _amount;
        require(IERC20(_token).transfer(_recipient, _amount), "ERC20 withdrawal failed");
        emit ERC20Withdrawn(_recipient, _token, _amount);
    }

    /**
     * @dev A governance-controlled function to initiate a withdrawal of Ether from the treasury.
     *      This function would typically be called as part of a `proposeProtocolChange` execution.
     * @param _amount The amount of Ether to withdraw.
     * @param _recipient The address to send the Ether to.
     */
    function withdrawEther(uint256 _amount, address _recipient) external onlyOwner { // Should be via proposal
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient Ether balance in treasury");
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Ether withdrawal failed");
        emit EtherWithdrawn(_recipient, _amount);
    }

    // --- VI. Emergency & Administrative ---

    /**
     * @dev An emergency function allowing a designated Guardian or Owner to temporarily halt critical protocol operations.
     */
    function pauseProtocol() external onlyGuardian {
        _pause();
    }

    /**
     * @dev Reverses the `pauseProtocol` action, restoring full protocol functionality.
     */
    function unpauseProtocol() external onlyGuardian {
        _unpause();
    }

    /**
     * @dev Sets the guardian address. Can only be called by the current owner.
     * @param _newGuardian The address of the new guardian.
     */
    function setGuardian(address _newGuardian) external onlyOwner {
        require(_newGuardian != address(0), "New guardian cannot be the zero address");
        guardian = _newGuardian;
    }

    /**
     * @dev Fallback function to accept ETH deposits.
     */
    receive() external payable {
        depositEther();
    }

    // --- View Functions for Parameters (for UI/external systems) ---

    function getReputationThresholds() external view returns (uint256[] memory) {
        return reputationTierThresholds;
    }

    function getRegisteredCognitiveAgents() external view returns (address[] memory) {
        return registeredCognitiveAgents;
    }

    function getSupportedERC20Tokens() external view returns (address[] memory) {
        return supportedERC20Tokens;
    }
}

// Minimal String conversion for event logging
library Strings {
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
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```