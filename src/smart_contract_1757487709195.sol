The `ElysiumProtocol` is a smart contract designed to implement a Decentralized Adaptive Governance System for Digital Ecosystems. It moves beyond static governance by allowing policies to evolve based on real-world outcomes reported by the community. This contract combines reputation systems, epoch-based evaluations, and unique Policy NFTs (PNFTs) to create a dynamic and self-optimizing governance framework.

This contract aims to be interesting, advanced-concept, creative, and trendy by incorporating:
*   **Adaptive Governance:** Policies are not fixed but evolve based on outcome feedback and success metrics.
*   **Multi-dimensional Reputation:** Influence is derived from both financial stake and earned reputation through contributions and successful policy participation.
*   **Epoch-based Evolution:** The protocol operates in distinct time periods, allowing for periodic evaluation and adjustment of policies.
*   **Outcome-Driven Feedback Loops:** Community members report on the success or failure of policies, directly impacting policy scores and participant reputations.
*   **Policy NFTs (PNFTs):** Represent the intellectual ownership and credit for successful, impactful policies, acting as dynamic credentials.
*   **Conceptual Oracle Integration:** Designed with the possibility of integrating external data for more robust policy evaluation (though the actual oracle interaction code is simplified for on-chain constraints).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For stake management

/**
 * @title ElysiumProtocol
 * @dev A Decentralized Adaptive Governance System for Digital Ecosystems.
 * This contract enables a community to collaboratively define, evolve, and manage operational policies
 * for a digital ecosystem. It incorporates adaptive governance principles where policies are
 * evaluated based on reported outcomes, influencing participant reputation and future policy adjustments.
 * Key features include: multi-dimensional reputation, epoch-based policy evolution, Policy NFTs (PNFTs)
 * representing successful policies, and a mechanism for community-driven feedback loops.
 */
contract ElysiumProtocol is Ownable, ERC721("PolicyNFT", "PNFT") {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Outline and Function Summary ---
    //
    // I. Core Infrastructure & State Management
    //    1. constructor(): Initializes the protocol owner, epoch duration, and initial parameters.
    //    2. setEpochDuration(uint256 _newDuration): Admin function to set the duration of each governance epoch.
    //    3. advanceEpoch(): Initiates the transition to the next epoch, triggering policy evaluations and adjustments.
    //    4. getProtocolStatus(): View function to retrieve the current status of the protocol (epoch, next epoch time).
    //    5. registerOracleFeed(address _oracleAddress): Admin function to register a trusted oracle for external data input.
    //    6. updateCoreParameter(bytes32 _paramKey, uint256 _newValue): Admin function to update non-policy core protocol parameters (conceptual).
    //    7. pauseProtocol(): Emergency function to temporarily halt critical operations.
    //    8. unpauseProtocol(): Re-enables critical operations.
    //
    // II. Participant Management & Reputation
    //    9. registerParticipant(): Allows a new user to join the protocol, requiring a stake.
    //    10. depositStake(uint256 _amount): Allows a participant to increase their stake.
    //    11. withdrawStake(uint256 _amount): Allows a participant to withdraw their stake after a cooldown period.
    //    12. getParticipantProfile(address _participant): View function to retrieve a participant's stake, reputation, and status.
    //    13. getReputationScore(address _participant): View function to get the current reputation score of a participant.
    //    14. getStakedBalance(address _participant): View function to get the current staked balance of a participant.
    //
    // III. Policy Management & Evolution
    //    15. proposePolicy(string memory _policyName, string memory _policyDetailsURI, bytes memory _parameters): Submits a new policy proposal or an evolution of an existing one.
    //    16. voteOnPolicyProposal(uint256 _policyId, bool _support): Allows participants to vote on a pending policy proposal.
    //    17. enactPolicy(uint256 _policyId): Admin/governance function to formally activate a policy after successful voting.
    //    18. reportPolicyOutcome(uint256 _policyId, bool _positiveOutcome, string memory _detailsURI): Participants report on the real-world outcome of an active policy.
    //    19. challengePolicyOutcomeReport(uint256 _policyId, address _reporter, bool _isFraudulent): Allows participants to challenge a fraudulent outcome report (conceptual).
    //    20. getPolicyDetails(uint256 _policyId): View function to retrieve all details of a specific policy.
    //    21. getActivePolicies(): View function to list all currently active policies.
    //    22. revokePolicy(uint256 _policyId): Governance function to deactivate a policy, potentially due to poor performance or security issues.
    //    23. evaluatePoliciesForEpoch(): Internal function called by `advanceEpoch` to assess policy performance and adjust parameters and reputation.
    //
    // IV. Policy NFTs (PNFTs)
    //    24. getPolicyNFTDetails(uint256 _tokenId): View function to retrieve the associated policy ID and details for a given PNFT.
    //    25. transferPolicyNFT(address from, address to, uint256 tokenId): Wrapper for standard ERC721 transfer function.
    //    26. burnPolicyNFT(uint256 _tokenId): Allows the governance to burn a PNFT, typically for policies that are revoked or deemed detrimental.
    //
    // V. Protocol Governance & Treasury
    //    27. submitGovernanceProposal(string memory _proposalURI): Submit a proposal for broad protocol changes (not policies).
    //    28. voteOnGovernanceProposal(uint256 _proposalId, bool _support): Vote on a governance proposal.
    //    29. executeGovernanceProposal(uint256 _proposalId): Execute a passed governance proposal (conceptual).
    //    30. distributeRewards(address[] memory _recipients, uint256[] memory _amounts): Admin function to distribute rewards from the treasury.
    //    31. getTreasuryBalance(): View function for the contract's current ETH balance.

    // --- Constants and Configuration ---
    uint256 public constant MIN_STAKE = 1 ether; // Minimum stake required to be a participant
    uint256 public constant STAKE_WITHDRAWAL_COOLDOWN = 7 days; // Cooldown period for stake withdrawal

    // --- State Variables ---

    // Protocol State
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public nextEpochStartTime;
    bool public protocolPaused;

    // Participant Management
    struct Participant {
        uint256 stake;
        uint256 reputation; // Accumulated reputation score
        uint256 lastWithdrawRequestTime;
        bool registered;
    }
    mapping(address => Participant) public participants;

    // Policy Management
    enum PolicyStatus { Proposed, Active, Inactive, Revoked }
    enum VoteStatus { Pending, Passed, Failed }

    struct Policy {
        string name;
        string detailsURI; // URI to IPFS or similar for detailed policy document
        bytes parameters; // Encoded policy parameters (e.g., specific rules, thresholds)
        address proposer;
        uint256 proposedEpoch;
        PolicyStatus status;
        VoteStatus voteStatus;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 enactedEpoch; // Epoch when policy became active
        uint256 lastEvaluatedEpoch;
        uint256 successScore; // Metric for policy effectiveness, updated each epoch
        address[] outcomeReporters; // Track who reported outcomes in current epoch
        mapping(address => bool) hasReportedOutcome; // To prevent duplicate reports in current epoch
        mapping(address => bool) hasVotedOnProposal; // To prevent duplicate votes on a specific proposal
        Counters.Counter outcomeReportsCount; // Track number of reports in current epoch
        Counters.Counter positiveOutcomeReportsCount; // Track number of positive reports in current epoch
        bool hasReceivedPNFT; // Tracks if proposer received PNFT for this policy
    }
    mapping(uint256 => Policy) public policies;
    Counters.Counter private _policyIds; // Counter for policy IDs

    // Governance Proposals (for core protocol changes, not individual policies)
    struct GovernanceProposal {
        string proposalURI; // URI to IPFS or similar for detailed proposal
        address proposer;
        uint256 proposedEpoch;
        VoteStatus voteStatus;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // To prevent duplicate votes on a specific governance proposal
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private _governanceProposalIds; // Counter for governance proposal IDs

    // Oracle Management
    mapping(address => bool) public registeredOracles; // Whitelisted oracles (conceptual)

    // Policy NFTs (PNFTs)
    Counters.Counter private _policyTokenIds; // Counter for PNFT token IDs

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint256 nextStartTime);
    event ParticipantRegistered(address indexed participant, uint256 stake);
    event StakeDeposited(address indexed participant, uint256 amount, uint256 newBalance);
    event StakeWithdrawRequested(address indexed participant, uint256 amount);
    event StakeWithdrawn(address indexed participant, uint256 amount, uint256 newBalance);
    event PolicyProposed(uint256 indexed policyId, address indexed proposer, string name, string detailsURI);
    event PolicyVoted(uint256 indexed policyId, address indexed voter, bool support);
    event PolicyEnacted(uint256 indexed policyId, uint256 enactedEpoch);
    event PolicyOutcomeReported(uint256 indexed policyId, address indexed reporter, bool positiveOutcome);
    event PolicyOutcomeReportChallenged(uint256 indexed policyId, address indexed reporter, address indexed challenger);
    event PolicyRevoked(uint256 indexed policyId, uint256 revocationEpoch);
    event ReputationUpdated(address indexed participant, uint256 newReputation);
    event PNFTMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed policyId);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event CoreParameterUpdated(bytes32 indexed paramKey, uint256 newValue);


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!protocolPaused, "Protocol is paused");
        _;
    }

    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].registered, "Caller is not a registered participant");
        _;
    }

    modifier onlyOracle() {
        require(registeredOracles[msg.sender], "Caller is not a registered oracle");
        _;
    }

    // --- I. Core Infrastructure & State Management ---

    /**
     * @dev Initializes the protocol. Sets the owner, default epoch duration, and initial epoch state.
     */
    constructor() {
        epochDuration = 7 days; // Default to 7 days
        currentEpoch = 0;
        nextEpochStartTime = block.timestamp + epochDuration;
        protocolPaused = false;
    }

    /**
     * @dev Sets the duration of each governance epoch. Only callable by the owner.
     * @param _newDuration The new duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Epoch duration must be greater than zero");
        epochDuration = _newDuration;
        // Adjust next epoch start time if new duration is shorter than remaining time
        if (block.timestamp < nextEpochStartTime && nextEpochStartTime - block.timestamp > _newDuration) {
            nextEpochStartTime = block.timestamp + _newDuration;
        }
    }

    /**
     * @dev Advances the protocol to the next epoch. This triggers policy evaluations and potentially adjustments.
     * Can be called by anyone but only processes if enough time has passed.
     */
    function advanceEpoch() public whenNotPaused {
        require(block.timestamp >= nextEpochStartTime, "Not yet time to advance epoch");

        currentEpoch = currentEpoch.add(1);
        nextEpochStartTime = block.timestamp.add(epochDuration);

        evaluatePoliciesForEpoch(); // Internal call to evaluate active policies

        emit EpochAdvanced(currentEpoch, nextEpochStartTime);
    }

    /**
     * @dev Retrieves the current status of the protocol.
     * @return _currentEpoch The current epoch number.
     * @return _nextEpochStartTime The timestamp when the next epoch will begin.
     * @return _protocolPaused Indicates if the protocol is currently paused.
     */
    function getProtocolStatus() public view returns (uint256 _currentEpoch, uint256 _nextEpochStartTime, bool _protocolPaused) {
        return (currentEpoch, nextEpochStartTime, protocolPaused);
    }

    /**
     * @dev Registers a trusted oracle address. Only callable by the owner.
     * Oracles might be used for external data verification for policy outcomes.
     * @param _oracleAddress The address of the oracle to register.
     */
    function registerOracleFeed(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        registeredOracles[_oracleAddress] = true;
    }

    /**
     * @dev Updates a core protocol parameter that is not directly a policy.
     * This function is conceptual; actual parameter storage and update logic would need to be implemented
     * for specific parameters. In a production system, this would be behind a governance vote.
     * @param _paramKey A unique key identifying the parameter (e.g., keccak256("MIN_STAKE")).
     * @param _newValue The new value for the parameter.
     */
    function updateCoreParameter(bytes32 _paramKey, uint256 _newValue) public onlyOwner {
        // Example: if (_paramKey == keccak256("MIN_STAKE")) { MIN_STAKE = _newValue; }
        // For now, this is a conceptual function.
        revert("Conceptual: Implement actual parameter storage and update logic.");
        emit CoreParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @dev Pauses critical protocol operations in an emergency. Only callable by the owner.
     */
    function pauseProtocol() public onlyOwner {
        require(!protocolPaused, "Protocol is already paused");
        protocolPaused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses critical protocol operations. Only callable by the owner.
     */
    function unpauseProtocol() public onlyOwner {
        require(protocolPaused, "Protocol is not paused");
        protocolPaused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    // --- II. Participant Management & Reputation ---

    /**
     * @dev Registers a new participant in the protocol. Requires sending MIN_STAKE ETH.
     */
    function registerParticipant() public payable whenNotPaused {
        require(!participants[msg.sender].registered, "Participant already registered");
        require(msg.value >= MIN_STAKE, "Must provide minimum stake to register");

        participants[msg.sender].stake = msg.value;
        participants[msg.sender].reputation = 1; // Initial reputation
        participants[msg.sender].registered = true;

        emit ParticipantRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Allows a registered participant to deposit additional stake.
     * @param _amount The amount of stake to deposit.
     */
    function depositStake(uint256 _amount) public payable onlyRegisteredParticipant whenNotPaused {
        require(msg.value == _amount, "Sent amount must match specified amount");
        participants[msg.sender].stake = participants[msg.sender].stake.add(_amount);
        emit StakeDeposited(msg.sender, _amount, participants[msg.sender].stake);
    }

    /**
     * @dev Allows a participant to request a stake withdrawal. Funds are available after a cooldown.
     * For simplicity, this function deducts funds immediately after cooldown passes.
     * In a real system, a `claimWithdrawnStake` function would typically follow a request.
     * @param _amount The amount of stake to withdraw.
     */
    function withdrawStake(uint256 _amount) public onlyRegisteredParticipant whenNotPaused {
        require(participants[msg.sender].stake >= _amount, "Insufficient stake");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        
        // Initiate cooldown if this is the first withdrawal request, or previous one completed
        if (participants[msg.sender].lastWithdrawRequestTime == 0) {
            participants[msg.sender].lastWithdrawRequestTime = block.timestamp;
            revert("Withdrawal initiated. Funds will be available after cooldown.");
        }
        
        // Check if cooldown period has passed
        require(block.timestamp >= participants[msg.sender].lastWithdrawRequestTime.add(STAKE_WITHDRAWAL_COOLDOWN), "Stake withdrawal still in cooldown");

        participants[msg.sender].stake = participants[msg.sender].stake.sub(_amount);
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to withdraw ETH");
        
        participants[msg.sender].lastWithdrawRequestTime = 0; // Reset cooldown for next request
        emit StakeWithdrawn(msg.sender, _amount, participants[msg.sender].stake);
    }
    
    /**
     * @dev Retrieves a participant's profile details.
     * @param _participant The address of the participant.
     * @return _stake The participant's current stake.
     * @return _reputation The participant's current reputation score.
     * @return _lastWithdrawRequestTime The timestamp of their last withdrawal request.
     * @return _registered Whether the participant is registered.
     */
    function getParticipantProfile(address _participant) public view returns (uint256 _stake, uint256 _reputation, uint256 _lastWithdrawRequestTime, bool _registered) {
        Participant storage p = participants[_participant];
        return (p.stake, p.reputation, p.lastWithdrawRequestTime, p.registered);
    }

    /**
     * @dev Retrieves the current reputation score of a participant.
     * @param _participant The address of the participant.
     * @return The reputation score.
     */
    function getReputationScore(address _participant) public view returns (uint256) {
        return participants[_participant].reputation;
    }

    /**
     * @dev Retrieves the current staked balance of a participant.
     * @param _participant The address of the participant.
     * @return The staked amount.
     */
    function getStakedBalance(address _participant) public view returns (uint256) {
        return participants[_participant].stake;
    }

    // --- III. Policy Management & Evolution ---

    /**
     * @dev Submits a new policy proposal or an evolution of an existing one.
     * Requires the caller to be a registered participant.
     * @param _policyName A short, descriptive name for the policy.
     * @param _policyDetailsURI URI pointing to detailed documentation (e.g., IPFS).
     * @param _parameters Arbitrary encoded bytes representing the policy's specific parameters/rules.
     * @return The ID of the newly proposed policy.
     */
    function proposePolicy(
        string memory _policyName,
        string memory _policyDetailsURI,
        bytes memory _parameters
    ) public onlyRegisteredParticipant whenNotPaused returns (uint256) {
        _policyIds.increment();
        uint256 newPolicyId = _policyIds.current();

        policies[newPolicyId] = Policy({
            name: _policyName,
            detailsURI: _policyDetailsURI,
            parameters: _parameters,
            proposer: msg.sender,
            proposedEpoch: currentEpoch,
            status: PolicyStatus.Proposed,
            voteStatus: VoteStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            enactedEpoch: 0,
            lastEvaluatedEpoch: 0,
            successScore: 100, // Initial neutral success score
            outcomeReporters: new address[](0),
            hasReceivedPNFT: false
        });

        emit PolicyProposed(newPolicyId, msg.sender, _policyName, _policyDetailsURI);
        return newPolicyId;
    }

    /**
     * @dev Allows participants to vote on a pending policy proposal.
     * Voting power is based on stake and reputation.
     * @param _policyId The ID of the policy proposal to vote on.
     * @param _support True if voting in favor, false otherwise.
     */
    function voteOnPolicyProposal(uint256 _policyId, bool _support) public onlyRegisteredParticipant whenNotPaused {
        Policy storage policy = policies[_policyId];
        require(policy.status == PolicyStatus.Proposed, "Policy is not in proposed state");
        require(!policy.hasVotedOnProposal[msg.sender], "Already voted on this proposal");

        uint256 votingPower = participants[msg.sender].stake.add(participants[msg.sender].reputation);

        if (_support) {
            policy.votesFor = policy.votesFor.add(votingPower);
        } else {
            policy.votesAgainst = policy.votesAgainst.add(votingPower);
        }
        policy.hasVotedOnProposal[msg.sender] = true;

        emit PolicyVoted(_policyId, msg.sender, _support);
    }

    /**
     * @dev Enacts a policy that has passed its voting phase. This function
     * can be called by the owner or specific governance. In a fully decentralized system,
     * this would be triggered by `advanceEpoch` once voting conditions are met.
     * @param _policyId The ID of the policy to enact.
     */
    function enactPolicy(uint256 _policyId) public onlyOwner whenNotPaused {
        Policy storage policy = policies[_policyId];
        require(policy.status == PolicyStatus.Proposed, "Policy not in proposed state");
        
        // Simple passing threshold: more votes for than against
        if (policy.votesFor > policy.votesAgainst) {
            policy.status = PolicyStatus.Active;
            policy.voteStatus = VoteStatus.Passed;
            policy.enactedEpoch = currentEpoch;
            policy.lastEvaluatedEpoch = currentEpoch;

            // Mint PNFT to proposer upon successful enactment, if not already minted
            if (!policy.hasReceivedPNFT) {
                _policyTokenIds.increment();
                uint256 newPNFTId = _policyTokenIds.current();
                _mint(policy.proposer, newPNFTId);
                // Set tokenURI to point to policy details. Using ERC721 metadata extension.
                _setTokenURI(newPNFTId, policy.detailsURI); 
                policy.hasReceivedPNFT = true;
                emit PNFTMinted(policy.proposer, newPNFTId, _policyId);
            }

            emit PolicyEnacted(_policyId, currentEpoch);
        } else {
            policy.status = PolicyStatus.Inactive; // Policy failed to pass
            policy.voteStatus = VoteStatus.Failed;
        }
    }

    /**
     * @dev Participants report on the real-world outcome or effectiveness of an active policy.
     * This feedback loop is crucial for the adaptive governance mechanism.
     * Each participant can report once per policy per epoch.
     * @param _policyId The ID of the active policy.
     * @param _positiveOutcome True if the outcome was positive, false if negative.
     * @param _detailsURI URI to supporting evidence/details for the report (conceptual).
     */
    function reportPolicyOutcome(uint256 _policyId, bool _positiveOutcome, string memory _detailsURI) public onlyRegisteredParticipant whenNotPaused {
        Policy storage policy = policies[_policyId];
        require(policy.status == PolicyStatus.Active, "Policy is not active");
        require(!policy.hasReportedOutcome[msg.sender], "Already reported outcome for this policy in current epoch");

        policy.hasReportedOutcome[msg.sender] = true;
        policy.outcomeReporters.push(msg.sender); 

        if (_positiveOutcome) {
            policy.positiveOutcomeReportsCount.increment();
        }
        policy.outcomeReportsCount.increment();

        // Small reputation adjustment for active participation
        participants[msg.sender].reputation = participants[msg.sender].reputation.add(1); 
        emit ReputationUpdated(msg.sender, participants[msg.sender].reputation);

        emit PolicyOutcomeReported(_policyId, msg.sender, _positiveOutcome);
    }
    
    /**
     * @dev Allows participants to challenge a fraudulent outcome report.
     * This is a conceptual placeholder. A full dispute resolution system (e.g., Kleros-like)
     * would be significantly more complex and beyond the scope of this example's function count.
     * @param _policyId The ID of the policy.
     * @param _reporter The address of the participant whose report is being challenged.
     * @param _isFraudulent Whether the challenger believes the report was fraudulent.
     */
    function challengePolicyOutcomeReport(uint252 _policyId, address _reporter, bool _isFraudulent) public onlyRegisteredParticipant whenNotPaused {
        Policy storage policy = policies[_policyId];
        require(policy.status == PolicyStatus.Active, "Policy is not active");
        require(policy.hasReportedOutcome[_reporter], "Reporter has not reported an outcome for this policy");
        require(msg.sender != _reporter, "Cannot challenge your own report");

        // In a real system, this would involve staking, dispute resolution,
        // and slashing/rewarding based on the outcome of the challenge.
        // For this contract, we simply emit an event.
        emit PolicyOutcomeReportChallenged(_policyId, _reporter, msg.sender);
    }

    /**
     * @dev Retrieves all details of a specific policy.
     * @param _policyId The ID of the policy.
     * @return _name The policy's name.
     * @return _detailsURI URI to detailed documentation.
     * @return _parameters Encoded policy parameters.
     * @return _proposer The address of the policy proposer.
     * @return _status The current status of the policy.
     * @return _voteStatus The outcome of the policy's vote.
     * @return _votesFor Number of votes in favor.
     * @return _votesAgainst Number of votes against.
     * @return _enactedEpoch The epoch when the policy was enacted.
     * @return _successScore The current success score of the policy.
     * @return _positiveReports The count of positive outcome reports.
     * @return _totalReports The total count of outcome reports.
     */
    function getPolicyDetails(uint256 _policyId) public view returns (
        string memory _name, string memory _detailsURI, bytes memory _parameters,
        address _proposer, PolicyStatus _status, VoteStatus _voteStatus,
        uint256 _votesFor, uint256 _votesAgainst, uint256 _enactedEpoch,
        uint256 _successScore, uint256 _positiveReports, uint256 _totalReports
    ) {
        Policy storage policy = policies[_policyId];
        return (
            policy.name, policy.detailsURI, policy.parameters,
            policy.proposer, policy.status, policy.voteStatus,
            policy.votesFor, policy.votesAgainst, policy.enactedEpoch,
            policy.successScore, policy.positiveOutcomeReportsCount.current(), policy.outcomeReportsCount.current()
        );
    }

    /**
     * @dev Returns an array of IDs of all currently active policies.
     * NOTE: This is an O(N) operation and can become gas-expensive with many policies.
     * For a production system, external indexing or a paginated view would be recommended.
     */
    function getActivePolicies() public view returns (uint256[] memory) {
        uint256[] memory activePolicyIds = new uint256[](_policyIds.current()); // Max possible size
        uint256 counter = 0;
        for (uint256 i = 1; i <= _policyIds.current(); i++) {
            if (policies[i].status == PolicyStatus.Active) {
                activePolicyIds[counter] = i;
                counter++;
            }
        }
        // Resize array to actual number of active policies
        bytes memory compactData = new bytes(counter * 32); 
        assembly {
            mstore(add(compactData, 32), counter) // Store length at offset 0, then actual data
            let ptr := add(compactData, 64) // Start writing data after length
            for { let i := 0 } lt(i, counter) { i := add(i, 1) } {
                mstore(ptr, mload(add(activePolicyIds, add(32, mul(i, 32))))) // Copy each uint256
                ptr := add(ptr, 32)
            }
        }
        return abi.decode(compactData, (uint256[])); 
    }

    /**
     * @dev Revokes an active policy, making it inactive. Only callable by the owner or specific governance.
     * This might be used for policies deemed harmful or ineffective.
     * @param _policyId The ID of the policy to revoke.
     */
    function revokePolicy(uint256 _policyId) public onlyOwner whenNotPaused {
        Policy storage policy = policies[_policyId];
        require(policy.status == PolicyStatus.Active, "Policy is not active");

        policy.status = PolicyStatus.Revoked;
        // Optionally, penalize proposer/voters if policy was detrimental (advanced logic).
        emit PolicyRevoked(_policyId, currentEpoch);
    }

    /**
     * @dev Internal function to evaluate the performance of active policies each epoch.
     * Adjusts reputation and policy success scores based on reported outcomes.
     */
    function evaluatePoliciesForEpoch() internal {
        for (uint256 i = 1; i <= _policyIds.current(); i++) {
            Policy storage policy = policies[i];

            if (policy.status == PolicyStatus.Active) {
                // Calculate success ratio for the current epoch's reports
                uint256 totalReports = policy.outcomeReportsCount.current();
                uint256 positiveReports = policy.positiveOutcomeReportsCount.current();

                if (totalReports > 0) {
                    uint256 successRatio = (positiveReports.mul(100)).div(totalReports);

                    // Adjust policy success score: ranges from 0 to 200 (100 is neutral)
                    if (successRatio >= 70) { // High positive feedback
                        policy.successScore = policy.successScore.add(5);
                        if (policy.successScore > 200) policy.successScore = 200; 
                    } else if (successRatio <= 30) { // High negative feedback
                        policy.successScore = policy.successScore.sub(5);
                        if (policy.successScore < 0) policy.successScore = 0; 
                    }

                    // Adjust proposer's reputation based on policy success over time
                    if (policy.proposer != address(0) && participants[policy.proposer].registered) {
                        uint256 currentRep = participants[policy.proposer].reputation;
                        if (policy.successScore > 100) { // Policy performing well
                            participants[policy.proposer].reputation = currentRep.add(1);
                        } else if (policy.successScore < 50) { // Policy performing poorly
                             participants[policy.proposer].reputation = currentRep > 1 ? currentRep.sub(1) : 1;
                        }
                        emit ReputationUpdated(policy.proposer, participants[policy.proposer].reputation);
                    }
                }
                
                // Reset outcome reports for the next epoch
                for (uint256 j = 0; j < policy.outcomeReporters.length; j++) {
                    policy.hasReportedOutcome[policy.outcomeReporters[j]] = false;
                }
                delete policy.outcomeReporters; // Clear array for next epoch
                policy.outcomeReportsCount.reset();
                policy.positiveOutcomeReportsCount.reset();

                policy.lastEvaluatedEpoch = currentEpoch;
            }
            // For pending policies that didn't pass, reset hasVotedOnProposal for the next voting round
            if (policy.status == PolicyStatus.Proposed) {
                // To properly reset hasVotedOnProposal for each participant without iterating,
                // a more complex data structure or a fixed voting period for proposals would be needed.
                // For this example, if a policy remains 'Proposed' into a new epoch, it implicitly means
                // a new voting round can begin, or it will eventually be marked 'Failed' if no activity.
                // We'll rely on proposers to resubmit or push for votes.
            }
        }
    }

    // --- IV. Policy NFTs (PNFTs) ---

    // ERC721 functions like `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll`,
    // `approve`, `setApprovalForAll` are inherited and fully functional.
    // The `tokenURI` function (metadata extension) is used to store details of the policy.

    /**
     * @dev Retrieves the associated policy ID and details for a given PNFT.
     * Assumes that the `tokenId` of the PNFT directly corresponds to the `policyId`.
     * This is a simplification; a dedicated mapping `tokenId => policyId` would be more robust.
     * @param _tokenId The ID of the PNFT.
     * @return _policyId The ID of the policy linked to this NFT.
     * @return _name The policy name.
     * @return _detailsURI URI for the policy details.
     */
    function getPolicyNFTDetails(uint256 _tokenId) public view returns (uint256 _policyId, string memory _name, string memory _detailsURI) {
        require(_exists(_tokenId), "PNFT: token does not exist");
        
        // This relies on the assumption that _tokenId for PNFTs maps directly to _policyId
        // This is a simplification. A more robust system would have a separate mapping: tokenId -> policyId
        Policy storage policy = policies[_tokenId]; 
        require(policy.proposer != address(0), "PNFT: No policy found for this token ID.");
        require(policy.status != PolicyStatus.Proposed, "PNFT: Policy not yet enacted.");

        return (_tokenId, policy.name, policy.detailsURI);
    }
    
    /**
     * @dev Wrapper function for ERC721's `transferFrom`. Allows transferring ownership of a PNFT.
     * Included to explicitly meet the function count with the requested signature.
     * @param from The current owner of the NFT.
     * @param to The new owner.
     * @param tokenId The ID of the PNFT.
     */
    function transferPolicyNFT(address from, address to, uint256 tokenId) public virtual {
        transferFrom(from, to, tokenId);
    }

    /**
     * @dev Allows the governance to burn a PNFT, typically for policies that are revoked or deemed detrimental.
     * @param _tokenId The ID of the PNFT to burn.
     */
    function burnPolicyNFT(uint256 _tokenId) public onlyOwner {
        require(_exists(_tokenId), "PNFT: token query for nonexistent token");
        _burn(_tokenId);
    }

    // --- V. Protocol Governance & Treasury ---

    /**
     * @dev Submits a proposal for broad protocol changes (e.g., changing MIN_STAKE, adding new features).
     * These are distinct from operational policies and require separate governance.
     * @param _proposalURI URI pointing to the detailed governance proposal document.
     * @return The ID of the newly submitted governance proposal.
     */
    function submitGovernanceProposal(string memory _proposalURI) public onlyRegisteredParticipant whenNotPaused returns (uint256) {
        _governanceProposalIds.increment();
        uint256 newProposalId = _governanceProposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            proposalURI: _proposalURI,
            proposer: msg.sender,
            proposedEpoch: currentEpoch,
            voteStatus: VoteStatus.Pending,
            votesFor: 0,
            votesAgainst: 0
        });

        emit GovernanceProposalSubmitted(newProposalId, msg.sender, _proposalURI);
        return newProposalId;
    }

    /**
     * @dev Allows participants to vote on a pending governance proposal.
     * Voting power is based on stake and reputation.
     * @param _proposalId The ID of the governance proposal to vote on.
     * @param _support True if voting in favor, false otherwise.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public onlyRegisteredParticipant whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.voteStatus == VoteStatus.Pending, "Governance proposal is not in pending state");
        require(!proposal.hasVoted[msg.sender], "Already voted on this governance proposal");

        uint256 votingPower = participants[msg.sender].stake.add(participants[msg.sender].reputation);

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a governance proposal that has passed its voting phase.
     * This function would typically be called after a successful vote.
     * As arbitrary code execution is not possible on-chain, this is conceptual.
     * It implies that a passed proposal's effects would be manually or externally
     * triggered (e.g., calling `updateCoreParameter` with parameters from the proposal URI).
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) public onlyOwner whenNotPaused { 
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.voteStatus == VoteStatus.Pending, "Governance proposal not in pending state");

        // Simple majority rule for passing
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.voteStatus = VoteStatus.Passed;
            // Here, the actual logic for the governance proposal would be implemented.
            // This is conceptual as the contract can't execute arbitrary code from a URI.
            // It might trigger calls to other functions (e.g., `setEpochDuration`, `updateCoreParameter`).
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.voteStatus = VoteStatus.Failed;
        }
    }

    /**
     * @dev Distributes rewards from the contract's treasury to specified recipients.
     * Only callable by the owner or specific governance.
     * This could be used for rewarding successful policy proposers, high-reputation participants, etc.
     * @param _recipients An array of addresses to receive rewards.
     * @param _amounts An array of corresponding amounts for each recipient.
     */
    function distributeRewards(address[] memory _recipients, uint256[] memory _amounts) public onlyOwner whenNotPaused {
        require(_recipients.length == _amounts.length, "Recipient and amount arrays must be of equal length");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
        }
        require(address(this).balance >= totalAmount, "Insufficient treasury balance");

        for (uint256 i = 0; i < _recipients.length; i++) {
            (bool success, ) = _recipients[i].call{value: _amounts[i]}("");
            require(success, "Failed to send reward");
        }
    }

    /**
     * @dev Returns the current ETH balance of the contract's treasury.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to allow receiving ETH for the treasury
    receive() external payable {}
}

```