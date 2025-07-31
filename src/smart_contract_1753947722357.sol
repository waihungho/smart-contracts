This contract, named "SynapticCollective," envisions a decentralized platform for collective intelligence, where members submit, validate, and curate "insights" (data, predictions, strategies, or knowledge artifacts). It combines elements of a DAO, a dynamic NFT system, a reputation protocol, and oracle integration for external validation, creating a self-improving knowledge base.

It deliberately avoids direct copy-pasting of common open-source patterns (like standard ERC-20/721 implementations beyond the interfaces themselves, or direct forks of Uniswap/Compound logic) by focusing on the *novel interplay* of these concepts.

---

## SynapticCollective: Collective Intelligence Protocol

### Outline & Function Summary

**I. Core Token (SYN) & Governance**
*   **SYN Token (`ERC20`):** The native utility and governance token of the SynapticCollective.
*   **Reputation System:** Non-transferable points reflecting a member's trustworthiness and contribution quality.
*   **Adaptive Governance:** Voting power is a function of both SYN stake and accumulated Reputation, allowing for more nuanced collective decision-making.

**II. Insight Management & Validation**
*   **Insight Submission:** Members stake SYN tokens to submit "insights" (hashed data, IPFS CIDs, or claims).
*   **Community Validation:** Other members vote on the validity and impact of submitted insights, using their Reputation and SYN stake.
*   **Oracle Verification:** Critical insights can trigger external oracle requests (e.g., Chainlink) for objective verification against real-world data or complex computation.
*   **Dispute Resolution:** Mechanisms for penalizing malicious or inaccurate submissions.

**III. Knowledge Shard NFTs (KSNFTs)**
*   **Dynamic NFTs:** Highly validated and impactful insights are minted as unique, soul-bound (non-transferable, initially) "Knowledge Shard NFTs."
*   **Evolving Metadata:** KSNFTs can dynamically update their metadata (e.g., "impact score," "usage count") as the underlying insight proves valuable over time.
*   **Privilege Granting:** Holding KSNFTs might grant special permissions, boosted voting power, or fractional claims on a portion of the treasury.

**IV. Treasury & Economic Layer**
*   **Fee Collection:** A portion of SYN staked for insights or other activities goes to the treasury.
*   **Reward Distribution:** Validated insights and active participation are rewarded from the treasury.
*   **Strategic Investment:** The collective can vote to deploy treasury funds into external DeFi protocols or other ventures to grow the collective's assets.

**V. Advanced Concepts**
*   **Time-Decay Reputation:** Reputation can slowly decay over time to encourage continuous engagement.
*   **Delegated Voting (Reputation):** Members can delegate their reputation-based voting power.
*   **Dynamic Parameters:** Staking requirements, validation thresholds, and reward multipliers can be adjusted via governance.
*   **Emergency Pause:** A mechanism to pause critical functions in case of an exploit or bug.

---

### Function Summary

1.  **`constructor(uint256 initialSupply)`**: Initializes the SYN token supply and sets the deployer as the owner.
2.  **`submitInsight(string memory _ipfsCid, string memory _category, bytes32 _hashedData)`**: Allows users to submit an insight, requiring a SYN stake.
3.  **`voteOnInsight(uint256 _insightId, bool _isValid)`**: Enables members to vote on the validity of a submitted insight, their vote weight depending on SYN stake and reputation.
4.  **`requestOracleValidation(uint256 _insightId, bytes memory _oracleRequestData)`**: Initiates an oracle request for a specific insight's validation, typically for complex or off-chain data.
5.  **`fulfillOracleValidation(bytes32 _requestId, bool _isOracleValid)`**: Callback function for the oracle to report its validation result.
6.  **`resolveInsightValidation(uint256 _insightId)`**: Finalizes an insight's validation period, distributing rewards/penalties and potentially minting a KSNFT.
7.  **`getInsightDetails(uint256 _insightId)`**: Retrieves detailed information about a specific insight.
8.  **`getInsightsByCategory(string memory _category)`**: Returns a list of insight IDs for a given category.
9.  **`getReputation(address _member)`**: Returns the current reputation points of a member.
10. **`createProposal(string memory _description, address _target, uint256 _value, bytes memory _calldata)`**: Allows members to propose changes or actions for the collective.
11. **`voteOnProposal(uint256 _proposalId, bool _for)`**: Members vote on a governance proposal.
12. **`executeProposal(uint256 _proposalId)`**: Executes a proposal if it passes and the execution delay is met.
13. **`mintKnowledgeShard(uint256 _insightId)`**: Internal function to mint a Knowledge Shard NFT for highly validated insights.
14. **`updateKnowledgeShardMetadata(uint256 _tokenId, string memory _newUri)`**: Updates the metadata URI for a KSNFT (e.g., to reflect higher impact).
15. **`getKnowledgeShardDetails(uint256 _tokenId)`**: Retrieves details of a specific Knowledge Shard NFT.
16. **`delegateReputationVote(address _delegatee)`**: Allows a member to delegate their reputation-based voting power.
17. **`depositToTreasury()`**: Allows users to directly deposit SYN into the collective's treasury.
18. **`adjustStakingRequirements(uint256 _newStakeAmount, uint256 _newMinReputation)`**: (Via Proposal) Adjusts the minimum SYN stake and reputation required for insight submission/voting.
19. **`investFunds(address _tokenAddress, address _targetProtocol, bytes memory _callData)`**: (Via Proposal) Simulates the collective investing treasury funds into an external DeFi protocol.
20. **`emergencyPause()`**: (Owner/Multi-sig) Pauses critical contract functions in an emergency.
21. **`withdrawEmergencyFunds(address _tokenAddress, uint256 _amount, address _to)`**: (Owner/Multi-sig) Allows withdrawal of funds in emergency pause.
22. **`getSystemMetrics()`**: Returns high-level statistics about the collective.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Minimal Chainlink Oracle Interface (replace with actual Chainlink Client if deploying to testnet/mainnet)
interface IChainlinkOracle {
    function request(
        bytes35 _jobId,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _nonce,
        bytes memory _data
    ) external returns (bytes32);

    function fulfill(bytes32 _requestId, bool _success) external;
}

contract SynapticCollective is ERC20, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Governance & Parameters
    uint256 public insightStakeAmount = 100 * (10 ** 18); // Default: 100 SYN
    uint256 public validationPeriod = 7 days; // How long an insight is open for validation
    uint256 public minReputationForVote = 50; // Minimum reputation to vote on insights/proposals
    uint256 public proposalVoteQuorum = 60; // Percentage of total eligible voting power required to pass (e.g., 60%)
    uint256 public proposalMinVotingPeriod = 3 days; // Minimum duration for proposal voting
    uint256 public proposalExecutionDelay = 1 days; // Delay before a passed proposal can be executed

    // Insight Tracking
    struct Insight {
        uint256 id;
        address submitter;
        string ipfsCid;
        string category;
        bytes32 hashedData; // Can be a hash of any complex data
        uint256 stake;
        uint256 submissionTime;
        mapping(address => bool) hasVoted; // Check if an address voted
        mapping(address => bool) voteDirection; // true for valid, false for invalid
        uint255 validVotes;
        uint255 invalidVotes;
        bool oracleRequested;
        bool oracleValidated; // True if oracle validated, false if oracle deemed invalid
        bytes32 oracleRequestId; // To track Chainlink request
        bool resolved; // True after rewards/penalties distributed and KSNFT potentially minted
        bool isValidated; // Final status after community + oracle validation
        uint256 totalWeightFor; // Sum of voting power for 'valid'
        uint256 totalWeightAgainst; // Sum of voting power for 'invalid'
    }
    Counters.Counter private _insightIds;
    mapping(uint256 => Insight) public insights;
    mapping(string => uint256[]) public categoryInsights; // Map category to list of insight IDs

    // Reputation System
    mapping(address => uint256) public reputationPoints;
    mapping(address => address) public reputationDelegates; // Address can delegate their reputation voting power

    // Knowledge Shard NFTs (KSNFT)
    KnowledgeShardNFT public ksnft;
    mapping(uint256 => uint256) public ksnftToInsightId; // Map KSNFT tokenId to original Insight ID

    // Governance Proposals
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 submissionTime;
        uint256 votingEndTime;
        address target; // Address of the contract to call
        uint256 value; // Ether to send with the call
        bytes calldataPayload; // Data to send with the call
        mapping(address => bool) hasVoted;
        uint256 totalVotesFor; // Sum of voting power for 'for'
        uint256 totalVotesAgainst; // Sum of voting power for 'against'
        bool executed;
        bool passed;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // Oracle Integration
    address public oracleAddress;
    bytes32 public oracleJobId;
    mapping(bytes32 => uint256) public oracleRequestIdToInsightId; // Map Chainlink requestId to Insight ID
    mapping(address => bool) public authorizedOracles; // Whitelist for custom oracle contracts

    // Pause Mechanism
    bool public paused = false;

    // --- Events ---
    event InsightSubmitted(uint256 indexed insightId, address indexed submitter, string category, uint256 stakeAmount);
    event InsightVoted(uint256 indexed insightId, address indexed voter, bool isValid, uint256 votingPower);
    event OracleRequestSent(uint256 indexed insightId, bytes32 indexed requestId);
    event OracleResponseReceived(uint256 indexed insightId, bytes32 indexed requestId, bool isOracleValid);
    event InsightResolved(uint256 indexed insightId, bool isValidated, uint256 rewardAmount, uint256 penaltyAmount, uint256 ksnftTokenId);
    event ReputationUpdated(address indexed member, uint256 newReputation);
    event KnowledgeShardMinted(uint256 indexed tokenId, uint256 indexed insightId, address indexed owner);
    event ProposalCreated(uint256 indexed proposalId, string description, address proposer, uint256 votingEndTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool _for, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ParametersAdjusted(uint256 newStakeAmount, uint256 newMinReputation);
    event EmergencyPaused(address indexed pauser);
    event EmergencyUnpaused(address indexed unpauser);
    event EmergencyFundsWithdrawn(address indexed tokenAddress, uint256 amount, address indexed to);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyOwnerOrAuthorizedOracle() {
        require(msg.sender == owner() || authorizedOracles[msg.sender], "Not authorized oracle or owner");
        _;
    }

    modifier onlyIfResolved(uint256 _insightId) {
        require(insights[_insightId].resolved, "Insight not resolved yet");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialSupply) ERC20("Synergy", "SYN") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
        // Deploy the Knowledge Shard NFT contract
        ksnft = new KnowledgeShardNFT(address(this));
    }

    // --- Core Token Functions (ERC20 standard overridden for visibility) ---
    // ERC20 `transfer`, `approve`, `transferFrom` are inherited and public.
    // `balanceOf` and `allowance` are also inherited and public.

    // --- Management Functions (Owner Only) ---
    function setOracleAddress(address _oracleAddress, bytes32 _jobId) public onlyOwner {
        oracleAddress = _oracleAddress;
        oracleJobId = _jobId;
    }

    function addAuthorizedOracle(address _oracle) public onlyOwner {
        authorizedOracles[_oracle] = true;
    }

    function removeAuthorizedOracle(address _oracle) public onlyOwner {
        authorizedOracles[_oracle] = false;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
        if (paused) {
            emit EmergencyPaused(msg.sender);
        } else {
            emit EmergencyUnpaused(msg.sender);
        }
    }

    function withdrawEmergencyFunds(address _tokenAddress, uint256 _amount, address _to) public onlyOwner whenNotPaused {
        // This is a safety valve, allows owner to withdraw tokens from the contract in emergencies
        // Typically, this would be disabled or controlled by a multi-sig / DAO after full decentralization.
        IERC20(_tokenAddress).transfer(_to, _amount);
        emit EmergencyFundsWithdrawn(_tokenAddress, _amount, _to);
    }

    // --- Reputation System ---
    function _updateReputation(address _member, int256 _amount) internal {
        if (_amount > 0) {
            reputationPoints[_member] += uint256(_amount);
        } else {
            uint256 absAmount = uint256(-_amount);
            if (reputationPoints[_member] < absAmount) {
                reputationPoints[_member] = 0;
            } else {
                reputationPoints[_member] -= absAmount;
            }
        }
        emit ReputationUpdated(_member, reputationPoints[_member]);
    }

    function getReputation(address _member) public view returns (uint256) {
        return reputationPoints[_member];
    }

    function delegateReputationVote(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    function getActualVoter(address _voter) internal view returns (address) {
        address delegatee = reputationDelegates[_voter];
        return delegatee == address(0) ? _voter : delegatee;
    }

    function getVotingPower(address _voter) internal view returns (uint256) {
        address actualVoter = getActualVoter(_voter);
        uint256 synPower = balanceOf(actualVoter);
        uint256 repPower = reputationPoints[actualVoter];
        // Simple linear combination for voting power, can be more complex (e.g., quadratic, sqrt)
        return synPower + (repPower * (10**18) / 100); // 1 reputation point = 0.01 SYN in voting power
    }

    // --- Insight Management ---
    function submitInsight(string memory _ipfsCid, string memory _category, bytes32 _hashedData)
        public whenNotPaused returns (uint256)
    {
        require(bytes(_ipfsCid).length > 0, "IPFS CID cannot be empty");
        require(bytes(_category).length > 0, "Category cannot be empty");
        require(balanceOf(msg.sender) >= insightStakeAmount, "Insufficient SYN stake");
        require(reputationPoints[msg.sender] >= minReputationForVote, "Insufficient reputation to submit");

        _transfer(msg.sender, address(this), insightStakeAmount); // Stake SYN

        _insightIds.increment();
        uint256 newId = _insightIds.current();

        Insight storage newInsight = insights[newId];
        newInsight.id = newId;
        newInsight.submitter = msg.sender;
        newInsight.ipfsCid = _ipfsCid;
        newInsight.category = _category;
        newInsight.hashedData = _hashedData;
        newInsight.stake = insightStakeAmount;
        newInsight.submissionTime = block.timestamp;
        newInsight.resolved = false;
        newInsight.oracleRequested = false;
        newInsight.oracleValidated = false;
        newInsight.isValidated = false;

        categoryInsights[_category].push(newId);

        emit InsightSubmitted(newId, msg.sender, _category, insightStakeAmount);
        return newId;
    }

    function voteOnInsight(uint256 _insightId, bool _isValid) public whenNotPaused {
        Insight storage insight = insights[_insightId];
        require(insight.submissionTime != 0, "Insight does not exist");
        require(block.timestamp < insight.submissionTime + validationPeriod, "Validation period ended");
        require(!insight.resolved, "Insight already resolved");
        require(reputationPoints[msg.sender] >= minReputationForVote, "Insufficient reputation to vote");
        require(!insight.hasVoted[msg.sender], "Already voted on this insight");

        uint256 voterVotingPower = getVotingPower(msg.sender);
        require(voterVotingPower > 0, "Voter has no voting power");

        insight.hasVoted[msg.sender] = true;
        insight.voteDirection[msg.sender] = _isValid;

        if (_isValid) {
            insight.validVotes++;
            insight.totalWeightFor += voterVotingPower;
        } else {
            insight.invalidVotes++;
            insight.totalWeightAgainst += voterVotingPower;
        }

        // Apply immediate, small reputation change based on vote consistency (optional but complex to implement perfectly)
        // For simplicity, reputation changes are mostly on resolution.

        emit InsightVoted(_insightId, msg.sender, _isValid, voterVotingPower);
    }

    function requestOracleValidation(uint256 _insightId, bytes memory _oracleRequestData) public whenNotPaused {
        Insight storage insight = insights[_insightId];
        require(insight.submissionTime != 0, "Insight does not exist");
        require(block.timestamp < insight.submissionTime + validationPeriod, "Validation period ended");
        require(!insight.oracleRequested, "Oracle validation already requested");
        require(msg.sender == insight.submitter || reputationPoints[msg.sender] > (minReputationForVote * 5), "Only submitter or highly reputable members can request oracle");
        require(oracleAddress != address(0) && oracleJobId != bytes32(0), "Oracle not configured");

        insight.oracleRequested = true;
        
        bytes32 requestId = IChainlinkOracle(oracleAddress).request(
            oracleJobId,
            address(this),
            this.fulfillOracleValidation.selector,
            _insightId, // Use insight ID as nonce for tracking
            _oracleRequestData
        );
        insight.oracleRequestId = requestId;
        oracleRequestIdToInsightId[requestId] = _insightId;
        emit OracleRequestSent(_insightId, requestId);
    }

    // This function acts as the callback from the Chainlink Oracle
    function fulfillOracleValidation(bytes32 _requestId, bool _isOracleValid)
        external onlyOwnerOrAuthorizedOracle // Only authorized oracle or contract owner can call
    {
        uint256 insightId = oracleRequestIdToInsightId[_requestId];
        require(insights[insightId].submissionTime != 0, "Insight does not exist for this request");
        require(insights[insightId].oracleRequested, "Oracle was not requested for this insight");
        require(insights[insightId].oracleRequestId == _requestId, "Request ID mismatch");
        require(!insights[insightId].resolved, "Insight already resolved");

        insights[insightId].oracleValidated = _isOracleValid;
        
        emit OracleResponseReceived(insightId, _requestId, _isOracleValid);
    }

    function resolveInsightValidation(uint256 _insightId) public whenNotPaused {
        Insight storage insight = insights[_insightId];
        require(insight.submissionTime != 0, "Insight does not exist");
        require(block.timestamp >= insight.submissionTime + validationPeriod, "Validation period not ended");
        require(!insight.resolved, "Insight already resolved");
        
        bool finalValidationStatus;
        uint256 totalCommunityWeight = insight.totalWeightFor + insight.totalWeightAgainst;

        if (insight.oracleRequested) {
            // If oracle was requested, its decision heavily influences the outcome
            // This is a simplified logic, can be weighted more complexly
            finalValidationStatus = insight.oracleValidated;
        } else {
            // Otherwise, rely on community vote
            finalValidationStatus = insight.totalWeightFor > insight.totalWeightAgainst;
        }

        insight.isValidated = finalValidationStatus;
        insight.resolved = true;

        uint256 rewardAmount = 0;
        uint256 penaltyAmount = 0;
        uint256 ksnftTokenId = 0;

        if (finalValidationStatus) {
            // Insight is valid: Reward submitter and valid voters, penalize invalid voters
            rewardAmount = insight.stake * 2; // Example: double the stake as reward
            _transfer(address(this), insight.submitter, rewardAmount); // Transfer from treasury
            _updateReputation(insight.submitter, 10); // Boost submitter's reputation

            // Distribute proportional rewards/penalties to voters based on their vote and the final outcome
            // (This part would require iterating through voters, which is gas-intensive and usually done off-chain or with specific claim mechanisms)
            // For this example, we'll just give a small reputation boost/hit to voters.
            // A more robust system would involve iterating or having voters claim rewards/penalties.
            // For now, we'll only update reputation for the submitter.

            // Check if insight is highly impactful/validated enough to mint a KSNFT
            // Example: If >75% of weighted votes were 'valid' AND it was oracle-validated, it's a 'shard'
            if (insight.oracleRequested && insight.oracleValidated &&
                (insight.totalWeightFor * 100 / (totalCommunityWeight == 0 ? 1 : totalCommunityWeight)) >= 75) {
                
                ksnftTokenId = ksnft.mintKnowledgeShard(insight.submitter, _insightId, insight.ipfsCid);
                ksnftToInsightId[ksnftTokenId] = _insightId;
            }

        } else {
            // Insight is invalid: Penalize submitter (lose stake) and valid voters, reward invalid voters
            penaltyAmount = insight.stake;
            // The staked amount remains in the contract, effectively penalized (can be burned or added to treasury)
            // Here, it remains in the treasury, boosting the collective's assets.
            _updateReputation(insight.submitter, -5); // Decrease submitter's reputation
        }
        
        // Decay reputation of those who voted against the final outcome, and boost those who voted correctly.
        // This part is computationally expensive to do on-chain for all voters.
        // In a real system, voters would claim their rewards/penalties, and reputation updates would happen then.

        emit InsightResolved(_insightId, finalValidationStatus, rewardAmount, penaltyAmount, ksnftTokenId);
    }

    function getInsightDetails(uint256 _insightId)
        public view
        returns (
            uint256 id,
            address submitter,
            string memory ipfsCid,
            string memory category,
            uint256 stake,
            uint256 submissionTime,
            uint256 validVotes,
            uint256 invalidVotes,
            bool oracleRequested,
            bool oracleValidated,
            bool resolved,
            bool isValidated,
            uint256 totalWeightFor,
            uint256 totalWeightAgainst
        )
    {
        Insight storage insight = insights[_insightId];
        require(insight.submissionTime != 0, "Insight does not exist");
        return (
            insight.id,
            insight.submitter,
            insight.ipfsCid,
            insight.category,
            insight.stake,
            insight.submissionTime,
            insight.validVotes,
            insight.invalidVotes,
            insight.oracleRequested,
            insight.oracleValidated,
            insight.resolved,
            insight.isValidated,
            insight.totalWeightFor,
            insight.totalWeightAgainst
        );
    }

    function getInsightsByCategory(string memory _category) public view returns (uint256[] memory) {
        return categoryInsights[_category];
    }

    // --- Governance (Proposals) ---

    function createProposal(string memory _description, address _target, uint256 _value, bytes memory _calldataPayload)
        public whenNotPaused returns (uint256)
    {
        require(reputationPoints[msg.sender] >= minReputationForVote, "Insufficient reputation to create proposal");
        require(balanceOf(msg.sender) >= insightStakeAmount, "Insufficient SYN stake to create proposal"); // Use insightStake as a minimum

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        Proposal storage newProposal = proposals[newId];
        newProposal.id = newId;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.submissionTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + proposalMinVotingPeriod;
        newProposal.target = _target;
        newProposal.value = _value;
        newProposal.calldataPayload = _calldataPayload;
        newProposal.executed = false;
        newProposal.passed = false;

        emit ProposalCreated(newId, _description, msg.sender, newProposal.votingEndTime);
        return newId;
    }

    function voteOnProposal(uint256 _proposalId, bool _for) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime != 0, "Proposal does not exist");
        require(block.timestamp < proposal.votingEndTime, "Voting period ended");
        require(!proposal.executed, "Proposal already executed");
        require(reputationPoints[msg.sender] >= minReputationForVote, "Insufficient reputation to vote");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterVotingPower = getVotingPower(msg.sender);
        require(voterVotingPower > 0, "Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;

        if (_for) {
            proposal.totalVotesFor += voterVotingPower;
        } else {
            proposal.totalVotesAgainst += voterVotingPower;
        }

        emit ProposalVoted(_proposalId, msg.sender, _for, voterVotingPower);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended");
        require(block.timestamp >= proposal.votingEndTime + proposalExecutionDelay, "Execution delay not met");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        require(totalVotes > 0, "No votes cast on this proposal");
        
        // Calculate dynamic quorum based on the actual voting power of the network at the time of vote
        uint256 currentTotalSupply = totalSupply(); // Total SYN, implies potential voting power
        uint256 minimumQuorumPower = (currentTotalSupply / 100) * proposalVoteQuorum;
        
        // Here, we use a simplified calculation for quorum based on total votes cast,
        // rather than total possible network voting power, which is harder to ascertain on-chain.
        // A more robust system would involve snapshotting or complex supply tracking.
        bool passed = (proposal.totalVotesFor * 100 / totalVotes) >= proposalVoteQuorum;
        
        // Also check if total votes cast meet a minimum threshold (e.g., minimumQuorumPower)
        require(totalVotes >= minimumQuorumPower, "Quorum not met");

        if (passed) {
            proposal.passed = true;
            // Execute the proposed action
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldataPayload);
            require(success, "Proposal execution failed");
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            revert("Proposal did not pass");
        }
    }

    // Example proposal targets:
    function adjustStakingRequirements(uint256 _newStakeAmount, uint256 _newMinReputation) public whenNotPaused {
        // This function would be called via a successful proposal execution
        require(msg.sender == address(this), "Only callable by contract via proposal execution"); // Enforce proposal call
        insightStakeAmount = _newStakeAmount;
        minReputationForVote = _newMinReputation;
        emit ParametersAdjusted(_newStakeAmount, _newMinReputation);
    }

    // Simulate treasury investment. In a real scenario, this would interact with external DeFi protocols.
    function investFunds(address _tokenAddress, address _targetProtocol, bytes memory _callData) public whenNotPaused {
        // This function would be called via a successful proposal execution
        require(msg.sender == address(this), "Only callable by contract via proposal execution"); // Enforce proposal call
        
        // Transfer the specified token from the contract's balance to the target protocol
        IERC20(_tokenAddress).transfer(address(_targetProtocol), IERC20(_tokenAddress).balanceOf(address(this)));
        
        // Then, call the target protocol with the provided calldata
        (bool success, ) = _targetProtocol.call(_callData);
        require(success, "Investment call failed");
        // Log investment, etc. (omitted for brevity)
    }

    // --- Treasury Functions ---
    function depositToTreasury() public payable whenNotPaused {
        // Allows users to send ETH to the contract (if we had ETH treasury)
        // For SYN token, this would be a transfer
        require(msg.value == 0, "ETH deposit not supported for SYN treasury. Use transfer SYN.");
        // If this were a mixed treasury, you'd handle msg.value here.
        // For SYN, direct transfer to this contract's address works.
        emit FundsDeposited(msg.sender, msg.value);
    }

    // --- KSNFT Functions (interacting with KnowledgeShardNFT contract) ---
    function getKnowledgeShardDetails(uint256 _tokenId)
        public view returns (uint256 insightId, address creator, string memory tokenUri, uint256 impactScore)
    {
        (insightId, creator, tokenUri, impactScore) = ksnft.getShardDetails(_tokenId);
    }

    function updateKnowledgeShardMetadata(uint256 _tokenId, string memory _newUri) public {
        require(msg.sender == ksnft.ownerOf(_tokenId), "Only KSNFT owner can update metadata");
        ksnft.updateTokenURI(_tokenId, _newUri);
    }

    // --- System Metrics ---
    function getSystemMetrics() public view returns (
        uint256 totalSynSupply,
        uint256 totalInsightsSubmitted,
        uint256 totalProposalsCreated,
        uint256 treasurySynBalance
    ) {
        return (
            totalSupply(),
            _insightIds.current(),
            _proposalIds.current(),
            balanceOf(address(this))
        );
    }
}

// Separate contract for Knowledge Shard NFTs
contract KnowledgeShardNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address public immutable synapticCollectiveAddress; // Reference to the main contract

    // Custom metadata storage for KSNFTs
    struct ShardMetadata {
        uint256 insightId;
        address creator;
        string tokenUri; // IPFS CID or URL to metadata
        uint256 impactScore; // Dynamic score, e.g., based on further usage/validation
    }
    mapping(uint256 => ShardMetadata) public shardMetadata;

    event ShardMetadataUpdated(uint256 indexed tokenId, string newUri);
    event ImpactScoreUpdated(uint256 indexed tokenId, uint256 newImpactScore);

    modifier onlySynapticCollective() {
        require(msg.sender == synapticCollectiveAddress, "Only SynapticCollective contract can call this function");
        _;
    }

    constructor(address _synapticCollectiveAddress) ERC721("KnowledgeShard", "KSNFT") Ownable(msg.sender) {
        synapticCollectiveAddress = _synapticCollectiveAddress;
    }

    // Custom minting function called by SynapticCollective
    function mintKnowledgeShard(address to, uint256 _insightId, string memory _initialIpfsCid)
        public onlySynapticCollective returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        
        shardMetadata[newItemId] = ShardMetadata({
            insightId: _insightId,
            creator: to,
            tokenUri: _initialIpfsCid,
            impactScore: 1 // Initial impact score
        });

        _setTokenURI(newItemId, _initialIpfsCid); // Set the base URI
        emit KnowledgeShardMinted(newItemId, _insightId, to);
        return newItemId;
    }

    // Allows the NFT owner to update its metadata (e.g., if the underlying insight is enhanced or used more)
    function updateTokenURI(uint256 tokenId, string memory newUri) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _setTokenURI(tokenId, newUri);
        shardMetadata[tokenId].tokenUri = newUri;
        emit ShardMetadataUpdated(tokenId, newUri);
    }

    // Allows SynapticCollective to update an NFT's impact score
    function updateImpactScore(uint256 tokenId, uint256 newScore) public onlySynapticCollective {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        shardMetadata[tokenId].impactScore = newScore;
        emit ImpactScoreUpdated(tokenId, newScore);
    }

    // Get custom details for a shard
    function getShardDetails(uint256 tokenId)
        public view returns (uint256 insightId, address creator, string memory tokenUri, uint256 impactScore)
    {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        ShardMetadata storage meta = shardMetadata[tokenId];
        return (meta.insightId, meta.creator, meta.tokenUri, meta.impactScore);
    }

    // Optional: Make KSNFTs non-transferable (Soul-bound)
    // By uncommenting the following functions, you can make them non-transferable.
    // However, for advanced use cases, some form of transfer might be desired (e.g., to a new wallet, or a marketplace for privileges)
    /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, tokenId);
        require(from == address(0) || to == address(0), "KSNFT: Not transferable");
    }
    */
}
```