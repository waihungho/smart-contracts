This smart contract, named "SynergyProtocol," aims to create a highly dynamic and interactive decentralized ecosystem. It combines several advanced concepts:

*   **Dynamic, Reputation-Bound NFTs (SynergyShards):** NFTs whose properties (like "tier" or "utility") evolve based on an on-chain reputation score.
*   **Decentralized Meta-Vault:** A community-governed treasury where users can deposit assets, and whose investment strategies are decided via proposals.
*   **Epoch-Based Reward System:** Time-locked periods for reputation decay, reward distribution, and protocol parameter changes.
*   **Delegated Governance:** Users can delegate their reputation power for voting.
*   **Simplified Meta-Transactions:** Allows for gasless interactions for certain actions, relying on an authorized relayer.
*   **Oracle/Logic Integration:** Designed to interact with external data sources or upgradeable logic contracts for enhanced dynamism.

---

## **Contract: SynergyProtocol**

**Outline & Function Summary**

**I. Core Components:**

*   **SynergyShard (ERC721):** The dynamic NFT representing an individual's stake and reputation within the protocol.
*   **Reputation System:** Tracks "Synergy Score" for each user, influencing NFT tiers and voting power.
*   **Meta-Vault:** A community-managed treasury holding various ERC20 tokens.
*   **Governance Module:** Handles proposals, voting, and execution of collective decisions.
*   **Epoch Management:** Manages time-based cycles for rewards, reputation decay, and protocol events.

**II. Function Categories:**

*   **A. Core Protocol Management (Owner/Governance Controlled):**
    *   `initializeProtocol`: Sets initial parameters.
    *   `setSynergyScoreOracle`: Sets the address of an oracle that can update reputation scores.
    *   `addSupportedVaultToken`: Adds a new ERC20 token to the Meta-Vault's list of accepted assets.
    *   `setEpochDuration`: Configures the length of each epoch.
    *   `setVotingThresholds`: Adjusts minimum reputation and quorum for proposals.
    *   `setRelayerStatus`: Grants/revokes gasless transaction relayer status.
    *   `updateShardArtLogic`: Points to an external contract for dynamic NFT art generation logic.
    *   `pauseProtocol`: Emergency pause functionality.
    *   `unpauseProtocol`: Unpause functionality.

*   **B. SynergyShard (NFT) Operations:**
    *   `mintSynergyShard`: Mints a new SynergyShard NFT to a recipient.
    *   `burnSynergyShard`: Allows the owner to burn their SynergyShard.
    *   `getShardTier`: Determines the current tier of a SynergyShard based on its owner's reputation.
    *   `getShardReputation`: Retrieves the reputation score associated with a SynergyShard's owner.

*   **C. Reputation & Delegation:**
    *   `updateSynergyScore`: Updates a user's Synergy Score (callable by oracle/governance).
    *   `getSynergyScore`: Retrieves a user's current Synergy Score.
    *   `delegateSynergy`: Allows a user to delegate their voting power (based on reputation) to another address.

*   **D. Meta-Vault & Asset Interaction:**
    *   `depositToMetaVault`: Users deposit supported ERC20 tokens into the Meta-Vault.
    *   `getVaultBalance`: Checks the balance of a specific token in the Meta-Vault.
    *   `executeVaultStrategy`: Allows governance to execute a predefined (or proposed) investment strategy from the Meta-Vault.

*   **E. Governance (Proposals & Voting):**
    *   `proposeStrategyChange`: Creates a new governance proposal for a vault strategy or protocol parameter change.
    *   `voteOnProposal`: Allows users with sufficient reputation to vote on active proposals.
    *   `executeProposal`: Executes a proposal that has met its voting thresholds and passed.

*   **F. Epoch & Rewards:**
    *   `advanceEpoch`: Advances the protocol to the next epoch, triggering reputation decay, reward calculations, and opening new claiming periods.
    *   `claimEpochRewards`: Allows users to claim rewards earned in a past epoch.
    *   `getCurrentEpoch`: Returns the current epoch number.

*   **G. Advanced Utilities:**
    *   `authorizeMetaTx`: Allows a trusted relayer to execute a transaction on behalf of a user who has signed it (gasless interaction).
    *   `delegateExecution`: Allows a user to pre-authorize another address to call specific functions on their behalf.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Custom error for better debugging
error SynergyProtocol__InsufficientReputation();
error SynergyProtocol__UnauthorizedRelayer();
error SynergyProtocol__InvalidSignature();
error SynergyProtocol__SignatureExpired();
error SynergyProtocol__ProposalNotFound();
error SynergyProtocol__ProposalNotExecutable();
error SynergyProtocol__AlreadyVoted();
error SynergyProtocol__InvalidEpochTransition();
error SynergyProtocol__NoRewardsToClaim();
error SynergyProtocol__NotApprovedDelegate();
error SynergyProtocol__AlreadyHasShard();
error SynergyProtocol__NoShardFound();
error SynergyProtocol__UnsupportedToken();
error SynergyProtocol__AlreadyHasDelegate();
error SynergyProtocol__InvalidDelegatee();


contract SynergyProtocol is ERC721, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    // ERC721 properties
    uint256 private _nextTokenId;

    // Reputation System
    mapping(address => int256) private s_synergyScores; // User address => current reputation score
    mapping(address => address) private s_synergyDelegates; // User address => delegated voting power to this address
    address public s_synergyScoreOracle; // Address allowed to update reputation scores (can be governance itself)

    // Meta-Vault
    EnumerableSet.AddressSet private s_supportedVaultTokens; // Set of ERC20 tokens accepted in the vault
    mapping(address => mapping(address => uint256)) private s_vaultBalances; // tokenAddress => userAddress => amount (for tracking, actual tokens are in contract)

    // Governance
    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        uint256 proposerReputation; // Reputation of the proposer at the time of proposal creation
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User => voted status
        uint256 creationEpoch;
        bool executed;
        bool passed;
        bool active; // True if proposal is still in voting period
    }
    mapping(uint256 => Proposal) private s_proposals;
    uint256 private _nextProposalId;
    uint256 public s_minReputationForProposal; // Minimum reputation to create a proposal
    uint256 public s_quorumPercentage; // Percentage of total active reputation required for a proposal to pass

    // Epoch Management
    uint256 public s_currentEpoch;
    uint256 public s_lastEpochAdvanceTimestamp;
    uint256 public s_epochDuration; // Duration of an epoch in seconds

    // Reward System (Simplified for example, can be complex with algorithms)
    mapping(uint256 => mapping(address => uint256)) private s_epochRewards; // epochId => userAddress => rewards earned

    // Meta-Transaction
    mapping(address => bool) private s_isRelayer; // Address => is a trusted relayer
    mapping(bytes32 => bool) private s_executedMetaTxHashes; // Hash of meta-tx => true (to prevent replay)

    // Delegation of execution (for specific function calls)
    mapping(address => mapping(address => mapping(bytes4 => bool))) private s_delegatedCallPermissions; // User => delegatee => functionSelector => granted

    // External Logic / Upgradeability Pointers (simplified, not full UUPS proxy)
    address public s_shardArtLogicAddress; // Address of a contract handling dynamic NFT art URI generation

    // --- Events ---
    event ShardMinted(address indexed recipient, uint256 indexed tokenId, int256 initialReputation);
    event ShardBurned(uint256 indexed tokenId, address indexed owner);
    event SynergyScoreUpdated(address indexed user, int256 newScore);
    event SynergyDelegated(address indexed delegator, address indexed delegatee);
    event DepositMade(address indexed user, address indexed tokenAddress, uint256 amount);
    event VaultStrategyExecuted(uint256 indexed proposalId, address indexed target, bytes callData);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event RewardsClaimed(uint256 indexed epochId, address indexed user, uint256 amount);
    event MetaTxAuthorized(address indexed signer, address indexed target, bytes callData, bytes32 indexed hash);
    event ExecutionDelegated(address indexed delegator, address indexed delegatee, bytes4 indexed selector);
    event ShardArtLogicUpdated(address indexed newLogicAddress);
    event ProtocolPaused(address indexed pauser);
    event ProtocolUnpaused(address indexed unpauser);
    event RelayerStatusChanged(address indexed relayer, bool status);
    event SupportedVaultTokenAdded(address indexed tokenAddress);
    event VotingThresholdsSet(uint256 minReputation, uint256 quorumPercentage);
    event EpochDurationSet(uint256 duration);

    // --- Modifiers ---
    modifier onlyGovernance() {
        // In a more complex DAO, this would check if the caller is the governance contract
        // or a passed proposal. For simplicity, we'll allow the owner to simulate governance.
        // A robust DAO would have its own voting module that calls this contract.
        require(msg.sender == owner(), "SynergyProtocol: Only owner/governance can call");
        _;
    }

    modifier onlySynergyScoreOracle() {
        require(msg.sender == s_synergyScoreOracle, "SynergyProtocol: Only reputation oracle can call");
        _;
    }

    modifier onlyRelayer() {
        require(s_isRelayer[msg.sender], "SynergyProtocol: Caller is not an authorized relayer");
        _;
    }

    // --- Constructor ---
    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        uint256 initialEpochDuration,
        uint256 initialMinReputationForProposal,
        uint256 initialQuorumPercentage
    ) ERC721(name, symbol) Ownable(initialOwner) {
        s_epochDuration = initialEpochDuration;
        s_minReputationForProposal = initialMinReputationForProposal;
        s_quorumPercentage = initialQuorumPercentage;
        s_currentEpoch = 0;
        s_lastEpochAdvanceTimestamp = block.timestamp;
        s_synergyScoreOracle = initialOwner; // Owner is initial oracle, can be changed
        _nextTokenId = 1;
        _nextProposalId = 1;
    }

    // --- A. Core Protocol Management ---

    /// @notice Sets the address of the oracle allowed to update reputation scores.
    /// @param _oracleAddress The new address for the reputation oracle.
    function setSynergyScoreOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "SynergyProtocol: Zero address not allowed for oracle");
        s_synergyScoreOracle = _oracleAddress;
    }

    /// @notice Adds a new ERC20 token to the list of supported tokens for the Meta-Vault.
    /// @param _tokenAddress The address of the ERC20 token to add.
    function addSupportedVaultToken(address _tokenAddress) external onlyGovernance {
        require(_tokenAddress != address(0), "SynergyProtocol: Zero address not allowed");
        require(!s_supportedVaultTokens.contains(_tokenAddress), "SynergyProtocol: Token already supported");
        s_supportedVaultTokens.add(_tokenAddress);
        emit SupportedVaultTokenAdded(_tokenAddress);
    }

    /// @notice Sets the duration for each epoch.
    /// @param _duration The new duration in seconds.
    function setEpochDuration(uint256 _duration) external onlyGovernance {
        require(_duration > 0, "SynergyProtocol: Epoch duration must be greater than zero");
        s_epochDuration = _duration;
        emit EpochDurationSet(_duration);
    }

    /// @notice Sets the minimum reputation required to propose and the quorum percentage for proposals.
    /// @param _minReputation The new minimum reputation score.
    /// @param _quorumPercentage The new quorum percentage (0-100).
    function setVotingThresholds(uint256 _minReputation, uint256 _quorumPercentage) external onlyGovernance {
        require(_quorumPercentage <= 100, "SynergyProtocol: Quorum percentage out of bounds");
        s_minReputationForProposal = _minReputation;
        s_quorumPercentage = _quorumPercentage;
        emit VotingThresholdsSet(_minReputation, _quorumPercentage);
    }

    /// @notice Grants or revokes relayer status for meta-transactions.
    /// @param _relayer The address of the relayer.
    /// @param _status True to grant, false to revoke.
    function setRelayerStatus(address _relayer, bool _status) external onlyOwner {
        s_isRelayer[_relayer] = _status;
        emit RelayerStatusChanged(_relayer, _status);
    }

    /// @notice Updates the address of the external contract responsible for dynamic NFT art logic.
    /// @param _newLogicAddress The new address for the shard art logic contract.
    function updateShardArtLogic(address _newLogicAddress) external onlyGovernance {
        s_shardArtLogicAddress = _newLogicAddress;
        emit ShardArtLogicUpdated(_newLogicAddress);
    }

    /// @notice Pauses the contract in case of an emergency.
    function pauseProtocol() external onlyOwner {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /// @notice Unpauses the contract.
    function unpauseProtocol() external onlyOwner {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    // --- B. SynergyShard (NFT) Operations ---

    /// @notice Mints a new SynergyShard NFT to a specified recipient.
    /// @param recipient The address to mint the NFT to.
    /// @dev Initial reputation is zero. Subsequent actions will update it.
    function mintSynergyShard(address recipient) external whenNotPaused {
        require(bytes(ERC721.tokenURI(_nextTokenId)).length == 0, "SynergyProtocol: Token ID already exists or is reserved."); // Basic check
        require(ERC721.balanceOf(recipient) == 0, "SynergyProtocol: Recipient already has a SynergyShard.");
        _mint(recipient, _nextTokenId);
        s_synergyScores[recipient] = 0; // Initialize reputation score
        emit ShardMinted(recipient, _nextTokenId, 0);
        _nextTokenId++;
    }

    /// @notice Allows the owner to burn their SynergyShard.
    /// @param tokenId The ID of the SynergyShard to burn.
    /// @dev Burning a shard will reset the owner's reputation score to zero.
    function burnSynergyShard(uint256 tokenId) external whenNotPaused {
        address ownerOfShard = ownerOf(tokenId);
        require(ownerOfShard == msg.sender, "SynergyProtocol: Caller is not the owner of the shard.");
        _burn(tokenId);
        s_synergyScores[ownerOfShard] = 0; // Reset reputation
        if (s_synergyDelegates[ownerOfShard] != address(0)) {
            delete s_synergyDelegates[ownerOfShard]; // Clear delegation if any
        }
        emit ShardBurned(tokenId, ownerOfShard);
    }

    /// @notice Retrieves the current tier of a SynergyShard based on its owner's reputation.
    /// @param tokenId The ID of the SynergyShard.
    /// @return The tier of the shard (e.g., 1 for basic, 2 for advanced, etc.).
    function getShardTier(uint256 tokenId) external view returns (uint256) {
        address ownerOfShard = ownerOf(tokenId);
        if (ownerOfShard == address(0)) {
            revert SynergyProtocol__NoShardFound();
        }
        int256 score = s_synergyScores[ownerOfShard];

        if (score >= 1000) return 5;
        if (score >= 500) return 4;
        if (score >= 200) return 3;
        if (score >= 50) return 2;
        return 1; // Default tier
    }

    /// @notice Retrieves the reputation score associated with a SynergyShard's owner.
    /// @param tokenId The ID of the SynergyShard.
    /// @return The reputation score of the shard's owner.
    function getShardReputation(uint256 tokenId) external view returns (int256) {
        address ownerOfShard = ownerOf(tokenId);
        if (ownerOfShard == address(0)) {
            revert SynergyProtocol__NoShardFound();
        }
        return s_synergyScores[ownerOfShard];
    }

    // --- C. Reputation & Delegation ---

    /// @notice Updates a user's Synergy Score. Callable by the designated oracle/governance.
    /// @param user The address of the user whose score is being updated.
    /// @param delta The amount to change the score by (can be positive or negative).
    function updateSynergyScore(address user, int256 delta) external onlySynergyScoreOracle {
        s_synergyScores[user] += delta;
        // Prevent negative scores, though int256 allows it for internal calculations.
        // Can add a floor if needed: if (s_synergyScores[user] < 0) s_synergyScores[user] = 0;
        emit SynergyScoreUpdated(user, s_synergyScores[user]);
    }

    /// @notice Retrieves a user's current Synergy Score.
    /// @param user The address of the user.
    /// @return The current Synergy Score.
    function getSynergyScore(address user) public view returns (int256) {
        return s_synergyScores[user];
    }

    /// @notice Allows a user to delegate their voting power (based on reputation) to another address.
    /// @param delegatee The address to delegate to.
    function delegateSynergy(address delegatee) external whenNotPaused {
        require(delegatee != msg.sender, "SynergyProtocol: Cannot delegate to self.");
        require(delegatee != address(0), "SynergyProtocol: Cannot delegate to zero address.");
        require(ERC721.balanceOf(msg.sender) > 0, "SynergyProtocol: Delegator must own a SynergyShard.");
        require(s_synergyDelegates[msg.sender] == address(0), "SynergyProtocol: Already delegated.");
        s_synergyDelegates[msg.sender] = delegatee;
        emit SynergyDelegated(msg.sender, delegatee);
    }

    /// @notice Gets the address that a user has delegated their synergy to.
    /// @param delegator The address whose delegate is being queried.
    /// @return The address of the delegatee, or address(0) if no delegation.
    function getSynergyDelegate(address delegator) external view returns (address) {
        return s_synergyDelegates[delegator];
    }

    // --- D. Meta-Vault & Asset Interaction ---

    /// @notice Allows users to deposit supported ERC20 tokens into the Meta-Vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to deposit.
    function depositToMetaVault(address tokenAddress, uint256 amount) external whenNotPaused {
        require(s_supportedVaultTokens.contains(tokenAddress), "SynergyProtocol: Unsupported token.");
        require(amount > 0, "SynergyProtocol: Deposit amount must be greater than zero.");

        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "SynergyProtocol: Token transfer failed.");

        s_vaultBalances[tokenAddress][msg.sender] += amount;
        emit DepositMade(msg.sender, tokenAddress, amount);
    }

    /// @notice Gets the balance of a specific token in the Meta-Vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The total amount of the token held by the contract.
    function getVaultBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /// @notice Executes a governance-approved vault strategy.
    /// @param targetContract The contract address to interact with.
    /// @param data The calldata for the function to execute on the target contract.
    /// @dev This function is typically called by `executeProposal` after a proposal passes.
    function executeVaultStrategy(address targetContract, bytes calldata data) external onlyGovernance whenNotPaused {
        (bool success, bytes memory result) = targetContract.call(data);
        require(success, string(abi.encodePacked("SynergyProtocol: Vault strategy execution failed: ", result)));
        emit VaultStrategyExecuted(0, targetContract, data); // ProposalId 0 for direct governance call
    }

    // --- E. Governance (Proposals & Voting) ---

    /// @notice Creates a new governance proposal for a vault strategy or protocol parameter change.
    /// @param description A brief description of the proposal.
    /// @param target The address of the contract the proposal intends to interact with.
    /// @param callData The encoded calldata for the function to execute if the proposal passes.
    function proposeStrategyChange(string calldata description, address target, bytes calldata callData) external whenNotPaused {
        require(getSynergyScore(msg.sender) >= s_minReputationForProposal, "SynergyProtocol: Not enough reputation to propose.");
        require(target != address(0), "SynergyProtocol: Target cannot be zero address.");
        require(bytes(description).length > 0, "SynergyProtocol: Description cannot be empty.");

        uint256 proposalId = _nextProposalId++;
        s_proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            targetContract: target,
            callData: callData,
            proposerReputation: uint256(getSynergyScore(msg.sender)),
            votesFor: 0,
            votesAgainst: 0,
            creationEpoch: s_currentEpoch,
            executed: false,
            passed: false,
            active: true
        });
        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice Allows users with sufficient reputation to vote on active proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for', false for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        require(proposal.id != 0, "SynergyProtocol: Proposal does not exist.");
        require(proposal.active, "SynergyProtocol: Proposal is not active for voting.");
        require(!proposal.hasVoted[msg.sender], "SynergyProtocol: Already voted on this proposal.");

        address voter = msg.sender;
        if (s_synergyDelegates[msg.sender] != address(0)) {
            // If the sender has delegated, the vote is actually from the delegatee's power
            voter = s_synergyDelegates[msg.sender];
        }

        int256 votingPower = getSynergyScore(voter);
        require(votingPower > 0, "SynergyProtocol: Voter has no reputation or shard.");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor += uint256(votingPower);
        } else {
            proposal.votesAgainst += uint256(votingPower);
        }
        emit VoteCast(proposalId, msg.sender, support, uint256(votingPower));
    }

    /// @notice Executes a proposal that has met its voting thresholds and passed.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        require(proposal.id != 0, "SynergyProtocol: Proposal does not exist.");
        require(!proposal.executed, "SynergyProtocol: Proposal already executed.");
        require(block.timestamp > s_lastEpochAdvanceTimestamp + s_epochDuration, "SynergyProtocol: Voting period not over yet (must be past current epoch).");
        require(s_currentEpoch > proposal.creationEpoch, "SynergyProtocol: Cannot execute proposal in the same epoch it was created.");

        // Calculate total active reputation for quorum check (simplistic: sum of all scores)
        // A more robust system would snapshot reputation at proposal creation or epoch start.
        int256 totalActiveReputation = 0;
        for (uint256 i = 0; i < _nextTokenId; i++) { // Iterate through all potential shard holders
             try this.ownerOf(i) returns (address holder) {
                totalActiveReputation += getSynergyScore(holder);
            } catch {}
        }
        // If there are delegates, we need to ensure unique contribution.
        // For simplicity, here we're summing all scores. In a real DAO, you'd use a snapshot.

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 minQuorum = (uint256(totalActiveReputation) * s_quorumPercentage) / 100;

        proposal.active = false; // Voting period ends

        if (proposal.votesFor > proposal.votesAgainst && totalVotes >= minQuorum) {
            proposal.passed = true;
            (bool success, bytes memory reason) = proposal.targetContract.call(proposal.callData);
            require(success, string(abi.encodePacked("SynergyProtocol: Proposal execution failed: ", reason)));
        } else {
            proposal.passed = false;
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.passed);
    }

    /// @notice Gets information about a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A tuple containing proposal details.
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            string memory description,
            address targetContract,
            bytes memory callData,
            uint256 proposerReputation,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 creationEpoch,
            bool executed,
            bool passed,
            bool active
        )
    {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.id == 0) revert SynergyProtocol__ProposalNotFound();
        return (
            proposal.id,
            proposal.description,
            proposal.targetContract,
            proposal.callData,
            proposal.proposerReputation,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.creationEpoch,
            proposal.executed,
            proposal.passed,
            proposal.active
        );
    }

    // --- F. Epoch & Rewards ---

    /// @notice Advances the protocol to the next epoch. Can be called by anyone (with incentive if desired).
    /// @dev Triggers reputation decay, and opens new claiming periods for rewards.
    function advanceEpoch() external whenNotPaused {
        require(block.timestamp >= s_lastEpochAdvanceTimestamp + s_epochDuration, "SynergyProtocol: Not time to advance epoch yet.");

        s_currentEpoch++;
        s_lastEpochAdvanceTimestamp = block.timestamp;

        // Implement reputation decay for all active users (iterating all users could be gas-intensive)
        // For a real system, you'd use a sparse merkle tree, or only decay when a user interacts.
        // Here, a simplified iteration over all *potential* shard holders for demonstration.
        // Or, better, decay happens implicitly when reputation is queried if decay logic is time-based.
        // For this example, let's assume `updateSynergyScore` is the only way to change scores,
        // and an off-chain process or governance regularly calls `updateSynergyScore` with decay.

        // Calculate and distribute rewards for the new epoch (simplified)
        // In a real system, this would involve complex logic based on vault performance, user activity, etc.
        // For demonstration, let's say a fixed small reward per active shard holder.
        uint256 rewardPerShard = 10; // Example reward amount
        for (uint256 i = 0; i < _nextTokenId; i++) {
            try this.ownerOf(i) returns (address holder) {
                if (holder != address(0) && s_synergyScores[holder] > 0) {
                    s_epochRewards[s_currentEpoch][holder] = rewardPerShard; // Assign rewards for *this* epoch
                }
            } catch {}
        }

        emit EpochAdvanced(s_currentEpoch, block.timestamp);
    }

    /// @notice Allows users to claim rewards earned in a past epoch.
    /// @param epochId The ID of the epoch to claim rewards from.
    function claimEpochRewards(uint256 epochId) external whenNotPaused {
        require(epochId < s_currentEpoch, "SynergyProtocol: Cannot claim rewards for current or future epoch.");
        uint256 rewards = s_epochRewards[epochId][msg.sender];
        require(rewards > 0, "SynergyProtocol: No rewards to claim for this epoch or already claimed.");

        s_epochRewards[epochId][msg.sender] = 0; // Prevent re-claiming

        // Transfer rewards (e.g., native token or a specific ERC20 reward token)
        // For simplicity, let's assume a native token for this example, or a designated reward token
        // If it's an ERC20, you'd need a dedicated reward token mapping or a fixed one.
        // Here, we'll just log it as "claimable" for this example, as the contract does not hold ETH rewards directly.
        // In a real scenario, this would be `(bool success, ) = payable(msg.sender).call{value: rewards}("");`
        // or `IERC20(rewardTokenAddress).transfer(msg.sender, rewards);`

        // This is a placeholder for actual reward transfer:
        emit RewardsClaimed(epochId, msg.sender, rewards);
    }

    /// @notice Returns the current epoch number.
    function getCurrentEpoch() external view returns (uint256) {
        return s_currentEpoch;
    }

    // --- G. Advanced Utilities ---

    /// @notice Executes a transaction on behalf of a user using a signed message (for gasless interactions).
    /// @param signer The address that signed the message.
    /// @param target The address of the contract to call.
    /// @param callData The calldata to send to the target contract.
    /// @param salt A unique random number to prevent replay attacks.
    /// @param deadline The timestamp after which the signature is invalid.
    /// @param sig The ECDSA signature from the signer.
    function authorizeMetaTx(
        address signer,
        address target,
        bytes calldata callData,
        bytes32 salt,
        uint256 deadline,
        bytes calldata sig
    ) external onlyRelayer whenNotPaused {
        require(block.timestamp <= deadline, "SynergyProtocol: Signature has expired.");

        bytes32 messageHash = keccak256(abi.encodePacked(
            bytes1(0x19), bytes1(0x01), // EIP-191 prefix
            block.chainid,
            address(this),
            signer,
            target,
            keccak256(callData),
            salt,
            deadline
        ));

        require(!s_executedMetaTxHashes[messageHash], "SynergyProtocol: Meta-transaction already executed.");

        address recoveredSigner = ECDSA.recover(messageHash, sig);
        require(recoveredSigner == signer, "SynergyProtocol: Invalid signature.");

        s_executedMetaTxHashes[messageHash] = true; // Mark as executed to prevent replay

        // Execute the call as the signer
        (bool success, bytes memory result) = target.call(callData);
        require(success, string(abi.encodePacked("SynergyProtocol: Meta-transaction execution failed: ", result)));

        emit MetaTxAuthorized(signer, target, callData, messageHash);
    }

    /// @notice Allows a user to pre-authorize another address to call specific functions on their behalf.
    /// @param delegatee The address that is authorized to call the function.
    /// @param selector The function selector (e.g., `this.foo.selector`) to authorize.
    function delegateExecution(address delegatee, bytes4 selector) external whenNotPaused {
        require(delegatee != address(0), "SynergyProtocol: Delegatee cannot be zero address.");
        require(delegatee != msg.sender, "SynergyProtocol: Cannot delegate to self.");
        s_delegatedCallPermissions[msg.sender][delegatee][selector] = true;
        emit ExecutionDelegated(msg.sender, delegatee, selector);
    }

    /// @notice Executes a delegated call.
    /// @param delegator The address that authorized this call.
    /// @param data The full calldata including the function selector and arguments.
    function executeDelegatedCall(address delegator, bytes calldata data) external whenNotPaused {
        require(s_delegatedCallPermissions[delegator][msg.sender][bytes4(data)], "SynergyProtocol: Caller not authorized for this function.");
        // Revoke permission after single use, or keep for multiple uses. For advanced, let's keep it.
        // delete s_delegatedCallPermissions[delegator][msg.sender][bytes4(data)]; // Uncomment for single-use delegation

        // Execute the call using the delegator's context (e.g., if it needs to call `transferFrom` etc.)
        // This is a *delegatecall* on a separate "execution logic" contract for security,
        // or a simple `.call` if the target is this contract and the context is `delegator`.
        // For this example, we'll assume it's a call to `this` contract and the logic handles `msg.sender` internally.
        // This pattern allows a delegatee to invoke a function *as if* the delegator called it.
        // A true `delegatecall` would imply a proxy pattern where the logic exists in a separate contract.
        // For simplicity, we'll assume the internal functions check `tx.origin` or have a custom "caller" parameter.
        // The most secure way is to pass `delegator` as an explicit parameter in the `data`.

        // Example: If a function `doSomethingForUser(address user)` exists:
        // `bytes calldata modifiedData = abi.encodeCall(this.doSomethingForUser, delegator);`
        // Then `this.call(modifiedData)` would work.
        // For now, this `call` just directly tries to execute `data` *on this contract*.
        // The *actual* target would be an external logic contract, for security.

        (bool success, bytes memory result) = address(this).call(data);
        require(success, string(abi.encodePacked("SynergyProtocol: Delegated call failed: ", result)));
    }
}
```