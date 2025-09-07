This smart contract, **AxiomNexus**, presents a decentralized autonomous agent (DAA) system designed for collective intelligence and evolving governance. It combines several advanced concepts: a dynamic, on-chain reputation system ("Wisdom Stream"), a sophisticated proposal and voting mechanism weighted by reputation, and a unique "Dynamic Blueprint NFT" that visually represents the DAA's collective wisdom and progress. The goal is to create a self-governing entity that improves its decision-making over time through community contributions and verifiable knowledge.

---

### **AxiomNexus: Contract Outline & Function Summary**

**Contract Name:** `AxiomNexus`

**Description:**
`AxiomNexus` is a sophisticated decentralized autonomous agent (DAA) system where participants, called "Agents," collaborate to govern the DAA's operations. Agents stake tokens to participate, contribute "knowledge" to a "Wisdom Stream," and vote on proposals. Their reputation, a non-transferable on-chain score, dynamically adjusts based on the accuracy and validity of their contributions and significantly influences their voting power. The DAA's evolution and collective achievements are visually represented by a unique "Dynamic Blueprint NFT," whose metadata updates based on the DAA's progress, successful proposals, and accumulated wisdom.

**Key Concepts:**

*   **Autonomous Agent Pool:** Users stake a specified ERC-20 token to become active "Agents" within the AxiomNexus DAA, gaining the ability to contribute and participate in governance.
*   **Wisdom Stream:** A mechanism for Agents to submit verifiable "knowledge contributions" (represented by a hash) related to specific epochs. These contributions are then validated, forming the basis for reputation adjustments.
*   **Reputation System:** A dynamic, on-chain, non-transferable score for each Agent. Reputation is earned for accurate knowledge contributions and lost for inaccurate or malicious ones, directly impacting voting power and potential rewards.
*   **Decentralized Governance:** Agents propose and vote on actions for the DAA, ranging from internal parameter adjustments to external contract calls, with voting power proportional to their reputation.
*   **Dynamic Blueprint NFT:** A unique ERC-721 token representing the AxiomNexus DAA itself. Its metadata URI (and thus its visual representation via off-chain services) is dynamically updated by successful governance proposals or DAA milestones, reflecting its evolving state, wisdom, and achievements.
*   **Epoch-based Mechanics:** The system operates in discrete time periods (epochs). Reputation calculations, proposal voting periods, and reward distributions are tied to these epochs, ensuring periodic and structured evolution.
*   **Slashing & Rewards:** Mechanisms to penalize Agents for malicious behavior or consistently inaccurate contributions (slashing) and reward them for valuable, validated knowledge.

---

**Function Summary (25 Functions):**

**I. Agent & Staking Management:**
1.  `stakeTokensForAgent(uint256 amount)`: Allows a user to stake `amount` of the designated `stakingToken` to become an active Agent.
2.  `unstakeTokensFromAgent(uint256 amount)`: Initiates the unstaking process for `amount` of tokens. Tokens are locked for a cooldown period before withdrawal.
3.  `claimUnstakedTokens()`: Finalizes the unstaking process, allowing the Agent to withdraw their unstaked tokens after the cooldown period.
4.  `updateAgentProfile(string calldata profileURI)`: Agents can update a URI pointing to their public profile metadata.
5.  `getAgentReputation(address agent)`: Returns the current reputation score of a specific `agent`.

**II. Wisdom Stream & Reputation System:**
6.  `submitKnowledgeContribution(bytes32 contributionHash, uint256 epochId)`: An Agent submits a `contributionHash` representing off-chain knowledge for a specific `epochId` to the Wisdom Stream.
7.  `validateKnowledgeContribution(address contributor, bytes32 contributionHash, bool isValid)`: A designated validator (or high-reputation Agent) confirms (`isValid = true`) or disputes (`isValid = false`) a knowledge contribution, influencing the contributor's reputation.
8.  `penalizeKnowledgeContribution(address contributor, bytes32 contributionHash, uint256 penaltyAmount)`: Allows governance to slash an Agent's reputation and/or stake for proven malicious or significantly incorrect contributions.
9.  `claimReputationReward(address contributor, bytes32 contributionHash)`: Agents claim reputation rewards for their successfully validated knowledge contributions.
10. `setValidationThreshold(uint256 newThreshold)`: Governance function to set the minimum number of 'validations' (positive confirmations) required for a knowledge contribution to be considered valid and earn reputation.
11. `getContributionStatus(bytes32 contributionHash)`: Retrieves the current validation status (number of validations/disputes) of a specific knowledge contribution.

**III. DAA Governance & Proposals:**
12. `createProposal(bytes32 proposalHash, address targetContract, bytes calldata callData, uint256 votingDurationEpochs)`: An Agent creates a new proposal, including a hash for off-chain details, a target contract for execution, and encoded call data.
13. `voteOnProposal(uint256 proposalId, bool support)`: Agents cast their vote (for or against) on an active proposal, with their vote weight proportional to their current reputation.
14. `delegateVotingPower(address delegatee)`: Allows an Agent to delegate their reputation-based voting power to another Agent.
15. `revokeDelegation()`: An Agent revokes any existing delegation of their voting power.
16. `executeProposal(uint256 proposalId)`: Executes a proposal that has passed its voting period, met quorum, and achieved a majority vote.
17. `getProposalState(uint256 proposalId)`: Retrieves the current status, vote counts, and other details for a given proposal.

**IV. Dynamic Blueprint NFT:**
18. `mintBlueprintNFT(address to, uint256 tokenId, string calldata initialURI)`: Mints the initial AxiomNexus Blueprint NFT to a specified address, setting its first metadata URI. (Typically called once during deployment or initial setup).
19. `updateBlueprintMetadata(uint256 tokenId, string calldata newURI)`: Allows governance (via proposal) to update the metadata URI of the Blueprint NFT, reflecting DAA evolution or milestones.
20. `transferBlueprintOwnership(address newOwner)`: Allows the DAA (via proposal) to transfer ownership of the Blueprint NFT to a new address, such as a DAO treasury.

**V. Epoch & System Parameters:**
21. `advanceEpoch()`: A permissioned or time-locked function to transition the system to the next epoch, triggering reputation recalculations, proposal expirations, and other time-based logic.
22. `setGlobalParameter(bytes32 paramKey, uint256 paramValue)`: A governance function to adjust critical system-wide parameters (e.g., staking minimum, unstaking cooldown, epoch duration).
23. `retrieveTreasuryFunds(address recipient, uint256 amount)`: Allows the DAA (via proposal) to withdraw funds from its internal treasury to a specified recipient.

**VI. System Control & Information:**
24. `pauseSystem()`: An emergency function (callable by the initial owner or governance) to pause critical contract operations in case of vulnerabilities.
25. `unpauseSystem()`: Resumes operations after the system has been paused.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title AxiomNexus: Decentralized Autonomous Agent (DAA) System
 * @author YourName (GPT-4)
 * @notice AxiomNexus is a sophisticated DAA system combining a dynamic on-chain reputation mechanism
 *         (the "Wisdom Stream"), a reputation-weighted governance model, and a unique "Dynamic
 *         Blueprint NFT" that visually represents the DAA's collective wisdom and progress.
 *         Agents stake tokens, contribute verifiable knowledge, and vote on proposals. Their
 *         reputation, a non-transferable score, dynamically adjusts based on the accuracy of
 *         contributions, influencing voting power and eligibility.
 *
 * Outline:
 * - Contract Name: AxiomNexus
 * - Description: A decentralized autonomous agent (DAA) system leveraging an on-chain
 *   reputation mechanism ("Wisdom Stream") to govern its operations and evolve a unique
 *   "Dynamic Blueprint NFT." Agents stake tokens to participate, contribute knowledge,
 *   vote on proposals, and earn reputation. The Blueprint NFT visually represents the
 *   DAA's collective wisdom and progress.
 * - Key Concepts: Autonomous Agent Pool, Wisdom Stream, Reputation System,
 *   Decentralized Governance, Dynamic Blueprint NFT, Epoch-based Mechanics, Slashing.
 *
 * Function Summary:
 * I. Agent & Staking Management:
 * 1. stakeTokensForAgent(uint256 amount): Stake collateral to become an Agent.
 * 2. unstakeTokensFromAgent(uint256 amount): Initiate unstaking, lose agent status after cooldown.
 * 3. claimUnstakedTokens(): Finalize unstaking and withdraw collateral.
 * 4. updateAgentProfile(string calldata profileURI): Agents update their on-chain profile metadata.
 * 5. getAgentReputation(address agent): Retrieve the current reputation score of an Agent.
 *
 * II. Wisdom Stream & Reputation System:
 * 6. submitKnowledgeContribution(bytes32 contributionHash, uint256 epochId): Agent submits a hash representing knowledge.
 * 7. validateKnowledgeContribution(address contributor, bytes32 contributionHash, bool isValid): Designated validators confirm/reject knowledge.
 * 8. penalizeKnowledgeContribution(address contributor, bytes32 contributionHash, uint256 penaltyAmount): Slash reputation/stake for incorrect contributions.
 * 9. claimReputationReward(address contributor, bytes32 contributionHash): Agents claim reputation rewards.
 * 10. setValidationThreshold(uint256 newThreshold): Governance function to set validation threshold.
 * 11. getContributionStatus(bytes32 contributionHash): Check contribution validation status.
 *
 * III. DAA Governance & Proposals:
 * 12. createProposal(bytes32 proposalHash, address targetContract, bytes calldata callData, uint256 votingDurationEpochs): Agents propose actions.
 * 13. voteOnProposal(uint256 proposalId, bool support): Agents cast their vote, weighted by reputation.
 * 14. delegateVotingPower(address delegatee): Delegate reputation-based voting power.
 * 15. revokeDelegation(): Revoke voting power delegation.
 * 16. executeProposal(uint256 proposalId): Execute a successful proposal.
 * 17. getProposalState(uint256 proposalId): Query proposal state.
 *
 * IV. Dynamic Blueprint NFT:
 * 18. mintBlueprintNFT(address to, uint256 tokenId, string calldata initialURI): Mints the initial DAA Blueprint NFT.
 * 19. updateBlueprintMetadata(uint256 tokenId, string calldata newURI): Updates Blueprint NFT metadata URI.
 * 20. transferBlueprintOwnership(address newOwner): Transfers Blueprint NFT ownership.
 *
 * V. Epoch & System Parameters:
 * 21. advanceEpoch(): Advance system to the next epoch.
 * 22. setGlobalParameter(bytes32 paramKey, uint256 paramValue): Governance function to adjust system parameters.
 * 23. retrieveTreasuryFunds(address recipient, uint256 amount): DAA (via proposal) withdraws funds from treasury.
 *
 * VI. System Control & Information:
 * 24. pauseSystem(): Emergency pause.
 * 25. unpauseSystem(): Unpause system.
 */
contract AxiomNexus is Context, Ownable, Pausable, ReentrancyGuard, ERC721 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Events ---
    event AgentStaked(address indexed agent, uint256 amount, uint256 currentStake);
    event AgentUnstakeInitiated(address indexed agent, uint256 amount, uint256 withdrawableEpoch);
    event AgentUnstakeClaimed(address indexed agent, uint256 amount);
    event AgentProfileUpdated(address indexed agent, string profileURI);
    event ReputationUpdated(address indexed agent, int256 change, uint256 newReputation);

    event KnowledgeContributionSubmitted(address indexed contributor, bytes32 contributionHash, uint256 epochId);
    event KnowledgeContributionValidated(address indexed contributor, bytes32 contributionHash, bool isValid, address indexed validator);
    event KnowledgeContributionPenalized(address indexed contributor, bytes32 contributionHash, uint256 penaltyAmount);

    event ProposalCreated(uint256 indexed proposalId, address indexed creator, bytes32 proposalHash, uint256 votingEndsEpoch);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 votingPower);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event DelegationRevoked(address indexed delegator);
    event ProposalExecuted(uint256 indexed proposalId);

    event BlueprintMetadataUpdated(uint256 indexed tokenId, string newURI);
    event BlueprintOwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    event EpochAdvanced(uint256 indexed newEpochId);
    event GlobalParameterSet(bytes32 indexed paramKey, uint256 paramValue);
    event TreasuryFundsRetrieved(address indexed recipient, uint256 amount);

    // --- State Variables ---

    // Core DAA parameters
    IERC20 public immutable stakingToken;
    uint256 public minStakingAmount;
    uint256 public unstakeCooldownEpochs;
    uint256 public epochDurationSeconds; // Duration of an epoch in seconds
    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTimestamp;

    // Agent management
    mapping(address => uint256) public agentStakes;
    mapping(address => uint256) public agentReputation; // Non-transferable reputation score
    mapping(address => string) public agentProfiles;
    mapping(address => uint256) public pendingUnstakes; // Agent => amount
    mapping(address => uint256) public unstakeAvailableEpoch; // Agent => epoch when tokens can be claimed

    EnumerableSet.AddressSet private _activeAgents; // Set of currently active agents

    // Reputation & Wisdom Stream
    uint256 public reputationRewardPerValidation;
    uint256 public reputationPenaltyPerDispute;
    uint256 public validationThreshold; // Min positive validations needed for a contribution to be valid

    struct Contribution {
        address contributor;
        uint256 epochId;
        uint256 positiveValidations;
        uint256 negativeValidations;
        bool isProcessed; // True if reputation/rewards have been applied
        bool isValidated; // True if passed threshold
    }
    mapping(bytes32 => Contribution) public knowledgeContributions;
    mapping(bytes32 => EnumerableSet.AddressSet) private _contributionValidators; // contributionHash => Set of validators

    // DAA Governance & Proposals
    uint256 public nextProposalId;
    uint256 public proposalQuorumPercentage; // e.g., 20 for 20% of total reputation
    uint256 public proposalMajorityPercentage; // e.g., 51 for 51% of votes

    struct Proposal {
        address creator;
        bytes32 proposalHash; // Hash of off-chain details
        address targetContract;
        bytes callData;
        uint256 startEpoch;
        uint256 endEpoch; // Epoch when voting ends
        uint256 forVotes; // Total reputation voting for
        uint256 againstVotes; // Total reputation voting against
        bool executed;
        mapping(address => bool) hasVoted; // Agent => has voted
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public delegates; // Delegator => Delegatee

    // Dynamic Blueprint NFT (ERC-721)
    uint256 public blueprintTokenId; // Fixed tokenId for the DAA's blueprint NFT
    bool public blueprintMinted;

    // --- Modifiers ---
    modifier onlyAgent() {
        require(_activeAgents.contains(_msgSender()), "AxiomNexus: Caller is not an active agent.");
        _;
    }

    modifier onlyBlueprintOwner() {
        require(ERC721.ownerOf(blueprintTokenId) == _msgSender(), "AxiomNexus: Caller is not blueprint owner.");
        _;
    }

    modifier onlyGovernance() {
        // For functions that can only be called if a proposal passes
        // In this simplified example, initially, it's owner or blueprint owner.
        // In a full DAA, this would check if a proposal passed to call this function.
        // For now, let's treat the owner as having this power, or the Blueprint owner
        // if transferred.
        require(ERC721.ownerOf(blueprintTokenId) == _msgSender() || _owner == _msgSender(), "AxiomNexus: Caller not authorized for governance.");
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakingTokenAddress,
        string memory _blueprintName,
        string memory _blueprintSymbol,
        uint256 _minStakingAmount,
        uint256 _unstakeCooldownEpochs,
        uint256 _epochDurationSeconds,
        uint256 _reputationRewardPerValidation,
        uint256 _reputationPenaltyPerDispute,
        uint256 _validationThreshold,
        uint256 _proposalQuorumPercentage,
        uint256 _proposalMajorityPercentage
    ) ERC721(_blueprintName, _blueprintSymbol) {
        require(_stakingTokenAddress != address(0), "AxiomNexus: Invalid staking token address");
        stakingToken = IERC20(_stakingTokenAddress);

        minStakingAmount = _minStakingAmount;
        unstakeCooldownEpochs = _unstakeCooldownEpochs;
        epochDurationSeconds = _epochDurationSeconds;
        reputationRewardPerValidation = _reputationRewardPerValidation;
        reputationPenaltyPerDispute = _reputationPenaltyPerDispute;
        validationThreshold = _validationThreshold;
        proposalQuorumPercentage = _proposalQuorumPercentage;
        proposalMajorityPercentage = _proposalMajorityPercentage;

        currentEpoch = 1;
        lastEpochAdvanceTimestamp = block.timestamp;
        nextProposalId = 1;
    }

    // --- I. Agent & Staking Management ---

    /**
     * @notice Stakes tokens to become an active Agent in AxiomNexus.
     * @param amount The amount of stakingToken to stake.
     */
    function stakeTokensForAgent(uint256 amount) external payable nonReentrant whenNotPaused {
        require(amount >= minStakingAmount, "AxiomNexus: Stake amount too low.");
        require(stakingToken.transferFrom(_msgSender(), address(this), amount), "AxiomNexus: Staking token transfer failed.");

        agentStakes[_msgSender()] += amount;
        _activeAgents.add(_msgSender()); // Add to active agents if not already present

        emit AgentStaked(_msgSender(), amount, agentStakes[_msgSender()]);
    }

    /**
     * @notice Initiates the unstaking process for a specified amount of tokens.
     *         Tokens become available for withdrawal after `unstakeCooldownEpochs`.
     * @param amount The amount of stakingToken to unstake.
     */
    function unstakeTokensFromAgent(uint256 amount) external nonReentrant whenNotPaused onlyAgent {
        require(agentStakes[_msgSender()] >= amount, "AxiomNexus: Insufficient staked amount.");

        agentStakes[_msgSender()] -= amount;
        pendingUnstakes[_msgSender()] += amount;
        unstakeAvailableEpoch[_msgSender()] = currentEpoch + unstakeCooldownEpochs;

        if (agentStakes[_msgSender()] < minStakingAmount) {
            _activeAgents.remove(_msgSender()); // Remove from active agents if stake falls below minimum
        }

        emit AgentUnstakeInitiated(_msgSender(), amount, unstakeAvailableEpoch[_msgSender()]);
    }

    /**
     * @notice Claims tokens that have passed their unstaking cooldown period.
     */
    function claimUnstakedTokens() external nonReentrant whenNotPaused {
        uint256 amount = pendingUnstakes[_msgSender()];
        require(amount > 0, "AxiomNexus: No pending unstakes.");
        require(currentEpoch >= unstakeAvailableEpoch[_msgSender()], "AxiomNexus: Unstake cooldown not over.");

        pendingUnstakes[_msgSender()] = 0;
        unstakeAvailableEpoch[_msgSender()] = 0; // Reset for next unstake

        require(stakingToken.transfer(_msgSender(), amount), "AxiomNexus: Token withdrawal failed.");

        emit AgentUnstakeClaimed(_msgSender(), amount);
    }

    /**
     * @notice Allows agents to update a URI pointing to their public profile metadata.
     * @param profileURI The new URI for the agent's profile.
     */
    function updateAgentProfile(string calldata profileURI) external whenNotPaused onlyAgent {
        agentProfiles[_msgSender()] = profileURI;
        emit AgentProfileUpdated(_msgSender(), profileURI);
    }

    /**
     * @notice Returns the current reputation score of a specific agent.
     * @param agent The address of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(address agent) public view returns (uint256) {
        return agentReputation[agent];
    }

    // --- II. Wisdom Stream & Reputation System ---

    /**
     * @notice An Agent submits a hash representing off-chain knowledge for a specific epoch.
     * @param contributionHash A unique hash identifying the knowledge contribution.
     * @param epochId The epoch for which this knowledge is relevant.
     */
    function submitKnowledgeContribution(bytes32 contributionHash, uint256 epochId) external whenNotPaused onlyAgent {
        require(knowledgeContributions[contributionHash].contributor == address(0), "AxiomNexus: Contribution already exists.");
        require(epochId <= currentEpoch, "AxiomNexus: Cannot submit for future epochs.");

        knowledgeContributions[contributionHash] = Contribution({
            contributor: _msgSender(),
            epochId: epochId,
            positiveValidations: 0,
            negativeValidations: 0,
            isProcessed: false,
            isValidated: false
        });

        emit KnowledgeContributionSubmitted(_msgSender(), contributionHash, epochId);
    }

    /**
     * @notice Designated validators (or high-reputation Agents) confirm or dispute a knowledge contribution.
     * @param contributor The address of the agent who made the contribution.
     * @param contributionHash The hash of the knowledge contribution.
     * @param isValid True if the validator confirms the contribution, false to dispute it.
     */
    function validateKnowledgeContribution(address contributor, bytes32 contributionHash, bool isValid) external whenNotPaused onlyAgent {
        Contribution storage c = knowledgeContributions[contributionHash];
        require(c.contributor == contributor, "AxiomNexus: Contributor mismatch.");
        require(c.contributor != address(0), "AxiomNexus: Contribution does not exist.");
        require(c.epochId < currentEpoch, "AxiomNexus: Cannot validate current or future epoch contributions.");
        require(!c.isProcessed, "AxiomNexus: Contribution already processed.");
        require(!_contributionValidators[contributionHash].contains(_msgSender()), "AxiomNexus: Already validated this contribution.");

        _contributionValidators[contributionHash].add(_msgSender());

        if (isValid) {
            c.positiveValidations++;
        } else {
            c.negativeValidations++;
        }

        emit KnowledgeContributionValidated(contributor, contributionHash, isValid, _msgSender());
    }

    /**
     * @notice Allows governance to slash an Agent's reputation and/or stake for proven malicious or significantly incorrect contributions.
     * @param contributor The address of the agent to penalize.
     * @param contributionHash The hash of the contribution that led to the penalty.
     * @param penaltyAmount The amount of reputation to deduct.
     */
    function penalizeKnowledgeContribution(address contributor, bytes32 contributionHash, uint256 penaltyAmount) external onlyGovernance whenNotPaused {
        Contribution storage c = knowledgeContributions[contributionHash];
        require(c.contributor == contributor, "AxiomNexus: Contributor mismatch.");
        require(c.contributor != address(0), "AxiomNexus: Contribution does not exist.");
        require(!c.isProcessed, "AxiomNexus: Contribution already processed.");
        
        // Ensure penalty does not underflow reputation
        if (agentReputation[contributor] > penaltyAmount) {
            agentReputation[contributor] -= penaltyAmount;
        } else {
            agentReputation[contributor] = 0;
        }

        // Optionally, could also slash staked tokens here via stakingToken.transfer(governance_treasury, stakePenaltyAmount)
        c.isProcessed = true; // Mark as processed to prevent double penalties/rewards
        
        emit KnowledgeContributionPenalized(contributor, contributionHash, penaltyAmount);
        emit ReputationUpdated(contributor, -int256(penaltyAmount), agentReputation[contributor]);
    }


    /**
     * @notice Agents claim reputation rewards for their successfully validated knowledge contributions.
     *         Can only be called after the epoch has advanced and contribution passed validation threshold.
     * @param contributor The address of the agent who made the contribution.
     * @param contributionHash The hash of the knowledge contribution.
     */
    function claimReputationReward(address contributor, bytes32 contributionHash) external whenNotPaused {
        Contribution storage c = knowledgeContributions[contributionHash];
        require(c.contributor == contributor, "AxiomNexus: Contributor mismatch.");
        require(c.contributor != address(0), "AxiomNexus: Contribution does not exist.");
        require(c.epochId < currentEpoch, "AxiomNexus: Cannot claim for current or future epoch.");
        require(!c.isProcessed, "AxiomNexus: Contribution already processed.");

        if (c.positiveValidations >= validationThreshold && c.positiveValidations > c.negativeValidations) {
            agentReputation[contributor] += reputationRewardPerValidation;
            c.isValidated = true;
            emit ReputationUpdated(contributor, int224(reputationRewardPerValidation), agentReputation[contributor]);
        }
        c.isProcessed = true; // Mark as processed regardless of outcome to prevent re-claiming

        // If contribution did not pass validation, it effectively gets 0 reward and is marked processed.
        // Penalty logic is separate via penalizeKnowledgeContribution.
    }

    /**
     * @notice Governance function to set the minimum number of 'validations' required
     *         for a knowledge contribution to be considered valid and earn reputation.
     * @param newThreshold The new validation threshold.
     */
    function setValidationThreshold(uint256 newThreshold) external onlyGovernance whenNotPaused {
        validationThreshold = newThreshold;
        emit GlobalParameterSet(bytes32("ValidationThreshold"), newThreshold);
    }

    /**
     * @notice Retrieves the current validation status of a specific knowledge contribution.
     * @param contributionHash The hash of the knowledge contribution.
     * @return contributor The address of the contributor.
     * @return epochId The epoch of the contribution.
     * @return positiveValidations The count of positive validations.
     * @return negativeValidations The count of negative validations.
     * @return isProcessed True if the contribution has been processed for reputation.
     * @return isValidated True if the contribution met the validation criteria.
     */
    function getContributionStatus(bytes32 contributionHash)
        external
        view
        returns (
            address contributor,
            uint256 epochId,
            uint256 positiveValidations,
            uint256 negativeValidations,
            bool isProcessed,
            bool isValidated
        )
    {
        Contribution storage c = knowledgeContributions[contributionHash];
        return (c.contributor, c.epochId, c.positiveValidations, c.negativeValidations, c.isProcessed, c.isValidated);
    }

    // --- III. DAA Governance & Proposals ---

    /**
     * @notice An Agent creates a new proposal for the DAA to consider.
     * @param proposalHash A hash representing off-chain details of the proposal.
     * @param targetContract The address of the contract to call if the proposal passes.
     * @param callData The encoded function call data for the target contract.
     * @param votingDurationEpochs The number of epochs for which voting will be open.
     */
    function createProposal(
        bytes32 proposalHash,
        address targetContract,
        bytes calldata callData,
        uint256 votingDurationEpochs
    ) external whenNotPaused onlyAgent returns (uint256) {
        require(votingDurationEpochs > 0, "AxiomNexus: Voting duration must be at least 1 epoch.");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId].creator = _msgSender();
        proposals[proposalId].proposalHash = proposalHash;
        proposals[proposalId].targetContract = targetContract;
        proposals[proposalId].callData = callData;
        proposals[proposalId].startEpoch = currentEpoch;
        proposals[proposalId].endEpoch = currentEpoch + votingDurationEpochs;
        proposals[proposalId].executed = false;

        emit ProposalCreated(proposalId, _msgSender(), proposalHash, proposals[proposalId].endEpoch);
        return proposalId;
    }

    /**
     * @notice Agents cast their vote (for or against) on an active proposal.
     *         Voting power is determined by their current reputation or delegated power.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote 'for', false to vote 'against'.
     */
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused onlyAgent {
        Proposal storage p = proposals[proposalId];
        require(p.creator != address(0), "AxiomNexus: Proposal does not exist.");
        require(currentEpoch >= p.startEpoch && currentEpoch < p.endEpoch, "AxiomNexus: Voting is not open.");

        address voter = delegates[_msgSender()] != address(0) ? delegates[_msgSender()] : _msgSender();
        require(!p.hasVoted[voter], "AxiomNexus: Already voted on this proposal.");

        uint256 votingPower = agentReputation[voter];
        require(votingPower > 0, "AxiomNexus: Voter has no reputation to cast a vote.");

        p.hasVoted[voter] = true;
        if (support) {
            p.forVotes += votingPower;
        } else {
            p.againstVotes += votingPower;
        }

        emit VoteCast(voter, proposalId, support, votingPower);
    }

    /**
     * @notice Allows an Agent to delegate their reputation-based voting power to another Agent.
     * @param delegatee The address of the agent to delegate voting power to.
     */
    function delegateVotingPower(address delegatee) external whenNotPaused onlyAgent {
        require(delegatee != address(0), "AxiomNexus: Cannot delegate to zero address.");
        require(delegatee != _msgSender(), "AxiomNexus: Cannot delegate to self.");
        require(_activeAgents.contains(delegatee), "AxiomNexus: Delegatee is not an active agent.");

        delegates[_msgSender()] = delegatee;
        emit VotingPowerDelegated(_msgSender(), delegatee);
    }

    /**
     * @notice An Agent revokes any existing delegation of their voting power.
     */
    function revokeDelegation() external whenNotPaused {
        require(delegates[_msgSender()] != address(0), "AxiomNexus: No active delegation to revoke.");
        
        delete delegates[_msgSender()];
        emit DelegationRevoked(_msgSender());
    }

    /**
     * @notice Executes a proposal that has passed its voting period, met quorum, and achieved a majority vote.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external nonReentrant whenNotPaused {
        Proposal storage p = proposals[proposalId];
        require(p.creator != address(0), "AxiomNexus: Proposal does not exist.");
        require(currentEpoch >= p.endEpoch, "AxiomNexus: Voting period not over.");
        require(!p.executed, "AxiomNexus: Proposal already executed.");

        uint256 totalReputation = _getTotalActiveReputation(); // Sum of reputation of all active agents
        require(totalReputation > 0, "AxiomNexus: No active reputation to form quorum.");

        uint256 totalVotesCast = p.forVotes + p.againstVotes;
        require(totalVotesCast * 100 >= totalReputation * proposalQuorumPercentage, "AxiomNexus: Quorum not met.");
        require(p.forVotes * 100 >= totalVotesCast * proposalMajorityPercentage, "AxiomNexus: Majority not met.");

        p.executed = true;

        // Execute the proposal's action
        (bool success, ) = p.targetContract.call(p.callData);
        require(success, "AxiomNexus: Proposal execution failed.");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Returns the total reputation of all active agents.
     * @dev Used for quorum calculation.
     */
    function _getTotalActiveReputation() private view returns (uint256) {
        uint256 totalRep = 0;
        for (uint256 i = 0; i < _activeAgents.length(); i++) {
            address agent = _activeAgents.at(i);
            totalRep += agentReputation[agent];
        }
        return totalRep;
    }

    /**
     * @notice Retrieves the current state, vote counts, and other details for a given proposal.
     * @param proposalId The ID of the proposal.
     * @return creator The address of the proposal creator.
     * @return proposalHash The hash of off-chain details.
     * @return targetContract The target contract for execution.
     * @return callData The encoded call data.
     * @return startEpoch The epoch when voting started.
     * @return endEpoch The epoch when voting ends.
     * @return forVotes Total reputation voting for.
     * @return againstVotes Total reputation voting against.
     * @return executed True if the proposal has been executed.
     * @return votingOpen True if the voting period is currently active.
     */
    function getProposalState(uint256 proposalId)
        external
        view
        returns (
            address creator,
            bytes32 proposalHash,
            address targetContract,
            bytes memory callData,
            uint256 startEpoch,
            uint256 endEpoch,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed,
            bool votingOpen
        )
    {
        Proposal storage p = proposals[proposalId];
        require(p.creator != address(0), "AxiomNexus: Proposal does not exist.");

        votingOpen = (currentEpoch >= p.startEpoch && currentEpoch < p.endEpoch);

        return (
            p.creator,
            p.proposalHash,
            p.targetContract,
            p.callData,
            p.startEpoch,
            p.endEpoch,
            p.forVotes,
            p.againstVotes,
            p.executed,
            votingOpen
        );
    }

    // --- IV. Dynamic Blueprint NFT ---

    /**
     * @notice Mints the initial AxiomNexus Blueprint NFT. Can only be called once.
     * @param to The address to mint the NFT to.
     * @param tokenId The unique ID for the Blueprint NFT (expected to be 1).
     * @param initialURI The initial metadata URI for the Blueprint NFT.
     */
    function mintBlueprintNFT(address to, uint256 tokenId, string calldata initialURI) external onlyOwner whenNotPaused {
        require(!blueprintMinted, "AxiomNexus: Blueprint NFT already minted.");
        _mint(to, tokenId);
        _setTokenURI(tokenId, initialURI);
        blueprintTokenId = tokenId;
        blueprintMinted = true;
    }

    /**
     * @notice Allows governance (via proposal) to update the metadata URI of the Blueprint NFT.
     * @param tokenId The ID of the Blueprint NFT.
     * @param newURI The new metadata URI.
     */
    function updateBlueprintMetadata(uint256 tokenId, string calldata newURI) external onlyBlueprintOwner whenNotPaused {
        require(tokenId == blueprintTokenId, "AxiomNexus: Invalid Blueprint Token ID.");
        _setTokenURI(tokenId, newURI);
        emit BlueprintMetadataUpdated(tokenId, newURI);
    }

    /**
     * @notice Allows the DAA (via proposal) to transfer ownership of the Blueprint NFT to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferBlueprintOwnership(address newOwner) external onlyBlueprintOwner whenNotPaused {
        address oldOwner = ERC721.ownerOf(blueprintTokenId);
        _transfer(oldOwner, newOwner, blueprintTokenId);
        emit BlueprintOwnershipTransferred(oldOwner, newOwner);
    }

    // --- V. Epoch & System Parameters ---

    /**
     * @notice Advances the system to the next epoch. Can be called by anyone but only if `epochDurationSeconds` has passed.
     *         Triggers reputation updates and other time-based logic.
     */
    function advanceEpoch() external whenNotPaused {
        require(block.timestamp >= lastEpochAdvanceTimestamp + epochDurationSeconds, "AxiomNexus: Epoch duration not yet passed.");

        currentEpoch++;
        lastEpochAdvanceTimestamp = block.timestamp;

        // Future: Add logic here to:
        // 1. Process all pending reputation changes for the *previous* epoch if any specific deferred processing is needed
        //    (currently handled by claimReputationReward and penalizeKnowledgeContribution which can be called after epoch advance)
        // 2. Clear old temporary data structures if any
        // 3. Update DAA-wide statistics that might influence Blueprint NFT metadata if not updated via proposal.

        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @notice Governance function to adjust critical system-wide parameters.
     * @param paramKey A bytes32 identifier for the parameter (e.g., "MinStakingAmount").
     * @param paramValue The new value for the parameter.
     */
    function setGlobalParameter(bytes32 paramKey, uint256 paramValue) external onlyGovernance whenNotPaused {
        if (paramKey == bytes32("MinStakingAmount")) {
            minStakingAmount = paramValue;
        } else if (paramKey == bytes32("UnstakeCooldownEpochs")) {
            unstakeCooldownEpochs = paramValue;
        } else if (paramKey == bytes32("EpochDurationSeconds")) {
            epochDurationSeconds = paramValue;
        } else if (paramKey == bytes32("ReputationRewardPerValidation")) {
            reputationRewardPerValidation = paramValue;
        } else if (paramKey == bytes32("ReputationPenaltyPerDispute")) {
            reputationPenaltyPerDispute = paramValue;
        } else if (paramKey == bytes32("ValidationThreshold")) {
            validationThreshold = paramValue;
        } else if (paramKey == bytes32("ProposalQuorumPercentage")) {
            require(paramValue <= 100, "AxiomNexus: Percentage must be <= 100.");
            proposalQuorumPercentage = paramValue;
        } else if (paramKey == bytes32("ProposalMajorityPercentage")) {
            require(paramValue <= 100, "AxiomNexus: Percentage must be <= 100.");
            proposalMajorityPercentage = paramValue;
        } else {
            revert("AxiomNexus: Unknown parameter key.");
        }
        emit GlobalParameterSet(paramKey, paramValue);
    }

    /**
     * @notice Allows the DAA (via proposal) to withdraw funds from its internal treasury.
     * @param recipient The address to send the funds to.
     * @param amount The amount of stakingToken to withdraw.
     */
    function retrieveTreasuryFunds(address recipient, uint256 amount) external onlyGovernance whenNotPaused nonReentrant {
        require(recipient != address(0), "AxiomNexus: Invalid recipient address.");
        require(stakingToken.balanceOf(address(this)) >= amount, "AxiomNexus: Insufficient treasury funds.");
        
        require(stakingToken.transfer(recipient, amount), "AxiomNexus: Treasury withdrawal failed.");
        emit TreasuryFundsRetrieved(recipient, amount);
    }

    // --- VI. System Control & Information ---

    /**
     * @notice Emergency function to pause critical contract operations.
     *         Can only be called by the initial owner or Blueprint NFT owner if transferred.
     */
    function pauseSystem() external onlyBlueprintOwner {
        _pause();
    }

    /**
     * @notice Resumes operations after the system has been paused.
     *         Can only be called by the initial owner or Blueprint NFT owner if transferred.
     */
    function unpauseSystem() external onlyBlueprintOwner {
        _unpause();
    }

    // Fallback function to receive ETH (if any governance proposals need to handle ETH)
    receive() external payable {}
}
```