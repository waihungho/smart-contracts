This project, **Sentient Asset Protocol (SAP)**, introduces a novel concept of "Sentient Assets" (SAs). These are not merely static tokens, but dynamic, programmable entities designed to autonomously manage their resources ("essence"), adapt their internal logic ("Synthetic Intelligence" or SI), and interact with other SAs and human "Curators."

The core idea is to create on-chain entities that exhibit pseudo-intelligent behavior based on configurable parameters and external data, moving beyond simple token transfers or fixed NFT metadata. They can evolve, collaborate, and incentivize human input, blurring the lines between DeFi, DAOs, and dynamic digital lifeforms.

---

## Sentient Asset Protocol (SAP)

### Outline

1.  **`ISentientAsset.sol`**:
    *   Defines the public interface for individual `SentientAsset` contracts. This allows the factory and other contracts to interact with SAs polymorphically.
2.  **`SentientAsset.sol`**:
    *   The heart of an individual Sentient Asset. This contract is designed to be deployed by the `SentientAssetProtocolFactory`.
    *   It manages an internal balance of ERC-20 "essence" tokens.
    *   It implements a configurable "Synthetic Intelligence" (SI) module that dictates its behavior and resource management.
    *   It supports adaptive governance mechanisms for custodian changes and SI logic upgrades.
    *   It facilitates inter-asset collaboration and interaction with human "Curators."
3.  **`SentientAssetProtocolFactory.sol`**:
    *   The central entry point for the Sentient Asset Protocol.
    *   Responsible for deploying new `SentientAsset` instances.
    *   Maintains a global registry of all deployed SAs.
    *   Manages protocol-wide settings, such as global oracle addresses and pause/unpause functionalities.

---

### Function Summary

#### A. `SentientAssetProtocolFactory.sol` (Global Protocol Management & Asset Deployment)

1.  `deploySentientAsset(string memory _name, string memory _symbol, address _initialOwner, ISentientAsset.SIConfig calldata _initialSIConfig)`:
    *   Deploys a new `SentientAsset` instance with a unique name, symbol, initial owner, and a set of initial Synthetic Intelligence (SI) configuration parameters.
    *   Registers the newly deployed SA in the protocol's global registry and assigns it a unique `saId`.
    *   **Concept**: Foundation for creating new "Sentient Life" on-chain.
2.  `getSentientAssetAddress(uint256 _saId)`:
    *   Retrieves the contract address of a `SentientAsset` given its unique SA ID.
    *   **Concept**: Accessing deployed SAs.
3.  `getSentientAssetCount()`:
    *   Returns the total number of `SentientAsset` instances that have been deployed through the factory.
    *   **Concept**: Protocol growth metric.
4.  `setGlobalOracle(address _oracleAddress)`:
    *   Allows the protocol owner to set or update the address of a global data oracle (e.g., a Chainlink oracle) that can be queried by SAs for external information.
    *   **Concept**: Bringing off-chain data on-chain for SI decisions.
5.  `pauseProtocol()`:
    *   Emergency function to pause critical functionalities of the factory and prevent new SA deployments or certain SA interactions.
    *   **Concept**: Safety mechanism for the entire protocol.
6.  `unpauseProtocol()`:
    *   Re-enables paused functionalities of the protocol.
    *   **Concept**: Resuming operations.
7.  `setSAImplementation(address _newImplementation)`:
    *   Allows the protocol owner to upgrade the logic contract used for *newly deployed* `SentientAsset` instances. This enables future-proofing the SA code without affecting existing SAs.
    *   **Concept**: Future-proofing & upgradability for the core SA template.

#### B. `SentientAsset.sol` (Individual Sentient Asset Logic)

#### B.1. Core Identity & Governance

8.  `proposeNewCustodian(address _newCustodian)`:
    *   The current custodian or a designated stakeholder can propose a new address to assume custodial control over the Sentient Asset. This initiates a governance process.
    *   **Concept**: Decentralized control over core SA management.
9.  `voteOnCustodianProposal(uint256 _proposalId, bool _approve)`:
    *   Designated stakeholders (e.g., holders of a specific governance token or 'essence' within the SA) can vote to approve or reject a proposed custodian change.
    *   **Concept**: Stakeholder governance.
10. `executeCustodianProposal(uint256 _proposalId)`:
    *   If a custodian change proposal receives sufficient votes and the voting period ends, this function allows the proposal to be executed, transferring custodial rights.
    *   **Concept**: Finalizing decentralized decision.
11. `addVerifiableCredential(bytes32 _credentialHash, address _issuer)`:
    *   Attaches a non-transferable (soulbound-like) cryptographic hash of a verifiable credential to the SA's identity, issued by a specified address. This builds the SA's on-chain reputation.
    *   **Concept**: Soulbound identity & reputation for an on-chain entity.
12. `getCredentialCount()`:
    *   Returns the number of verifiable credentials currently attached to this Sentient Asset.
    *   **Concept**: Querying SA reputation.

#### B.2. Metabolic & Resource Management

13. `depositEssence(uint256 _amount)`:
    *   Allows any user to deposit ERC-20 "essence" tokens into the Sentient Asset's internal balance. This fuels its operation and growth.
    *   **Concept**: Funding an on-chain autonomous entity.
14. `withdrawEssence(uint256 _amount)`:
    *   Allows the SA's custodian (or through SI-driven governance) to initiate a withdrawal of "essence" from its balance. This could be for external investments or distribution.
    *   **Concept**: SA managing its own treasury.
15. `processMetabolicCycle()`:
    *   This is a core function that triggers the SA's internal "metabolic" logic. It uses the current SI configuration, potentially queries the global oracle for external data (e.g., market prices, environmental data), and based on these inputs, it may:
        *   Consume "essence" for maintenance.
        *   Generate new "essence" (e.g., from simulated "work" or "growth").
        *   Adjust its internal state or SI parameters.
        *   Initiate autonomous actions (e.g., collaborate, distribute rewards).
    *   **Concept**: Simulating on-chain life, resource dynamics, and autonomous decision-making.
16. `getEssenceBalance()`:
    *   Returns the current balance of the designated ERC-20 "essence" token held by the Sentient Asset.
    *   **Concept**: Checking SA vitality.
17. `distributeCycleRewards()`:
    *   Based on the SA's SI and previous `processMetabolicCycle` executions, this function allows the SA to distribute accumulated "essence" or other rewards to its designated "Curators" or "Trainers" for their contributions.
    *   **Concept**: Automated incentive distribution for human interaction.

#### B.3. Synthetic Intelligence (SI) & Adaptation

18. `configureSIParameters(ISentientAsset.SIConfig calldata _newConfig)`:
    *   Allows the SA's custodian or a governance vote to directly update the internal parameters of its Synthetic Intelligence (SI). This controls its decision-making thresholds, risk appetite, and reaction factors.
    *   **Concept**: Direct "training" or "tuning" of an on-chain AI.
19. `proposeSIUpgrade(bytes32 _newLogicCodeHash)`:
    *   Proposes an upgrade to the underlying immutable SI execution logic (e.g., a hash of a new, audited SI library version). This requires a more formal governance process than parameter changes.
    *   **Concept**: Major "brain" transplant for the SA, representing significant evolution.
20. `voteOnSIUpgrade(uint256 _proposalId, bool _approve)`:
    *   Stakeholders vote on whether to approve or reject a proposed upgrade to the SA's core SI logic.
    *   **Concept**: Decentralized control over SA's fundamental behavior.
21. `executeSIUpgrade(uint256 _proposalId)`:
    *   Executes the approved SI logic upgrade, directing the SA to use the new immutable logic for future operations.
    *   **Concept**: Implementing approved evolution.
22. `getSIState()`:
    *   Returns the current internal state and configuration parameters of the Sentient Asset's Synthetic Intelligence.
    *   **Concept**: Transparency into the SA's "mind."
23. `querySIDecision(uint256 _inputDataPoint)`:
    *   A read-only function that simulates what the SA's SI would decide (e.g., a "yes/no" or numerical output) given a specific input data point, without altering the SA's state. Useful for predicting SA behavior.
    *   **Concept**: Simulating SA's autonomous decisions.

#### B.4. Inter-Asset Collaboration & Curation

24. `initiateCollaboration(address _targetSA, uint256 _essenceShare, uint256 _duration)`:
    *   This Sentient Asset autonomously or via custodian initiates a proposal for a collaborative agreement with another `SentientAsset`, specifying terms such as shared essence or duration of the joint venture.
    *   **Concept**: On-chain multi-agent systems and trustless collaboration.
25. `respondToCollaboration(address _proposingSA, uint256 _proposalId, bool _accept)`:
    *   Allows this Sentient Asset to accept or reject a collaboration proposal received from another SA. Its decision can be influenced by its SI and current state.
    *   **Concept**: Inter-SA communication and autonomous agreement.
26. `submitCuratedData(string memory _dataType, bytes memory _dataHash, uint256 _relevanceScore)`:
    *   Allows external "Curators" (human users) to submit data relevant to the SA's operation. This data can be used by the SA's SI during its metabolic cycles.
    *   **Concept**: Human-in-the-loop for AI-like systems, data marketplaces.
27. `attestCuratedData(address _curator, bytes memory _dataHash, uint256 _attestationScore)`:
    *   Other users or even other SAs can attest to the quality, accuracy, or relevance of previously submitted curated data. This attestation influences the rewards for the original curator.
    *   **Concept**: Decentralized data validation and reputation for curators.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// --- Contract 1: ISentientAsset.sol ---
// Interface for SentientAsset contracts
interface ISentientAsset {
    // Custom Structs for SI Configuration and Proposals
    struct SIConfig {
        uint256 metabolismRate;     // Rate of essence consumption/generation
        uint256 riskTolerance;      // 0-100, impacts withdrawal/investment decisions
        uint256 reactionThreshold;  // Threshold for SI to react to oracle data
        uint256 curatorRewardShare; // Percentage of generated essence to reward curators
    }

    struct Proposal {
        uint256 id;
        bytes32 proposalHash; // Hash of the proposal content (e.g., new custodian, SI logic)
        address proposer;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool approved; // True if passed
        mapping(address => bool) hasVoted; // Voter tracking
    }

    // Events
    event CustodianProposed(uint256 proposalId, address indexed newCustodian, address indexed proposer);
    event CustodianVoteCast(uint256 proposalId, address indexed voter, bool decision);
    event CustodianProposalExecuted(uint256 proposalId, address indexed newCustodian);
    event SICfgUpdated(SIConfig newConfig);
    event SIUpgradeProposed(uint256 proposalId, bytes32 indexed newLogicCodeHash);
    event SIUpgradeVoteCast(uint256 proposalId, address indexed voter, bool decision);
    event SIUpgradeExecuted(uint256 proposalId, bytes32 indexed newLogicCodeHash);
    event EssenceDeposited(address indexed depositor, uint256 amount);
    event EssenceWithdrawn(address indexed receiver, uint256 amount);
    event MetabolicCycleProcessed(uint256 cycleId, uint256 essenceChange, uint256 newBalance);
    event RewardsDistributed(uint256 amount, address indexed recipientType);
    event CredentialAdded(bytes32 indexed credentialHash, address indexed issuer);
    event CollaborationInitiated(address indexed proposerSA, address indexed targetSA, uint256 essenceShare, uint256 duration);
    event CollaborationResponded(address indexed respondingSA, address indexed proposingSA, uint256 proposalId, bool accepted);
    event CuratedDataSubmitted(address indexed curator, string dataType, bytes32 dataHash, uint256 relevanceScore);
    event CuratedDataAttested(address indexed attester, address indexed curator, bytes32 dataHash, uint256 attestationScore);

    // B.1. Core Identity & Governance
    function proposeNewCustodian(address _newCustodian) external;
    function voteOnCustodianProposal(uint256 _proposalId, bool _approve) external;
    function executeCustodianProposal(uint256 _proposalId) external;
    function addVerifiableCredential(bytes32 _credentialHash, address _issuer) external;
    function getCredentialCount() external view returns (uint256);

    // B.2. Metabolic & Resource Management
    function depositEssence(uint256 _amount) external;
    function withdrawEssence(uint256 _amount) external;
    function processMetabolicCycle() external;
    function getEssenceBalance() external view returns (uint256);
    function distributeCycleRewards() external;

    // B.3. Synthetic Intelligence (SI) & Adaptation
    function configureSIParameters(SIConfig calldata _newConfig) external;
    function proposeSIUpgrade(bytes32 _newLogicCodeHash) external;
    function voteOnSIUpgrade(uint256 _proposalId, bool _approve) external;
    function executeSIUpgrade(uint256 _proposalId) external;
    function getSIState() external view returns (SIConfig memory, uint256 lastMetabolicCycleTime);
    function querySIDecision(uint256 _inputDataPoint) external view returns (bool decision, string memory rationale);

    // B.4. Inter-Asset Collaboration & Curation
    function initiateCollaboration(address _targetSA, uint256 _essenceShare, uint256 _duration) external;
    function respondToCollaboration(address _proposingSA, uint256 _proposalId, bool _accept) external;
    function submitCuratedData(string memory _dataType, bytes memory _dataHash, uint256 _relevanceScore) external;
    function attestCuratedData(address _curator, bytes memory _dataHash, uint256 _attestationScore) external;

    // View functions for ID, Name, Symbol, Owner
    function saId() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function owner() external view returns (address); // Current custodian
    function essenceToken() external view returns (IERC20);
    function globalOracle() external view returns (address); // Oracle address for this SA

    // Helper for proposal expiration (conceptual, would depend on specific voting logic)
    function VOTING_PERIOD() external view returns (uint256);
}

// --- Contract 2: SentientAsset.sol ---
// Implementation of an individual Sentient Asset
contract SentientAsset is ISentientAsset, Ownable, Pausable {
    uint256 public saId;
    string public override name;
    string public override symbol;
    IERC20 public override essenceToken; // The ERC-20 token that powers this SA
    address public override globalOracle; // Oracle for this specific SA instance

    SIConfig public siConfig;
    uint256 public lastMetabolicCycleTime;

    uint256 private _credentialCount;
    mapping(uint256 => bytes32) private _credentials; // credentialId => hash
    mapping(uint256 => address) private _credentialIssuers; // credentialId => issuer

    // Proposal Management for Custodian & SI Upgrades
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals; // All proposals
    mapping(uint256 => address) public custodianProposals; // Specifics for custodian proposals
    mapping(uint256 => bytes32) public siUpgradeProposals; // Specifics for SI upgrade proposals

    // Simplified voting requires all essence holders to vote (or a subset, depending on complexity)
    uint256 public constant override VOTING_PERIOD = 3 days; // Example voting period

    // Curated Data storage (simplified for concept)
    struct CuratedData {
        address curator;
        string dataType;
        bytes dataHash;
        uint256 relevanceScore;
        uint256 attestationSum; // Sum of attestation scores
        uint256 attestationCount; // Number of attestations
    }
    mapping(bytes32 => CuratedData) public curatedData; // dataHash => CuratedData
    mapping(bytes32 => mapping(address => bool)) public hasAttested; // dataHash => attester => bool

    constructor(
        uint256 _saId,
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        address _essenceTokenAddress,
        address _globalOracleAddress,
        SIConfig calldata _initialSIConfig
    ) Ownable(_initialOwner) {
        saId = _saId;
        name = _name;
        symbol = _symbol;
        essenceToken = IERC20(_essenceTokenAddress);
        globalOracle = _globalOracleAddress;
        siConfig = _initialSIConfig;
        lastMetabolicCycleTime = block.timestamp;
        nextProposalId = 1;
    }

    // --- Internal/Utility Functions ---

    // A simplified placeholder for querying an external oracle.
    // In a real scenario, this would use Chainlink or similar.
    function _getOracleData(string memory _query) internal view returns (uint256) {
        // Placeholder: Returns a dummy value.
        // In reality, this would make an external call to `globalOracle`
        // and handle potential failures.
        if (keccak256(abi.encodePacked(_query)) == keccak256(abi.encodePacked("marketPrice"))) {
            return 100; // Example: dummy market price
        }
        return 0;
    }

    function _recordProposal(bytes32 _proposalHash, address _proposer) internal returns (uint256) {
        uint256 proposalId = nextProposalId++;
        Proposal storage p = proposals[proposalId];
        p.id = proposalId;
        p.proposalHash = _proposalHash;
        p.proposer = _proposer;
        p.voteStartTime = block.timestamp;
        p.voteEndTime = block.timestamp + VOTING_PERIOD;
        return proposalId;
    }

    function _hasVoted(uint256 _proposalId, address _voter) internal view returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }

    // Simplified voting power: For this example, 1 vote per essence holder.
    // In a real system, this would be proportional to essence held, or a specific governance token.
    function _getVotingPower(address _voter) internal view returns (uint256) {
        // Placeholder for real voting power logic (e.g., token balance, reputation)
        // For simplicity, assume each unique address that holds essence can vote once.
        if (essenceToken.balanceOf(_voter) > 0) {
            return 1;
        }
        return 0;
    }

    function _finalizeProposal(uint256 _proposalId) internal {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.voteEndTime, "Voting period not ended");
        require(!p.executed, "Proposal already executed");

        // Simple majority: 50%+1 of total votes cast
        p.approved = (p.yesVotes > p.noVotes) && (p.yesVotes + p.noVotes > 0);
        p.executed = true; // Mark as executed even if failed to prevent re-execution attempts
    }

    // --- B.1. Core Identity & Governance ---

    function proposeNewCustodian(address _newCustodian) external onlyOwnerOrCustodian {
        require(_newCustodian != address(0), "New custodian cannot be zero address");
        bytes32 proposalHash = keccak256(abi.encodePacked("CUSTODIAN_CHANGE", _newCustodian));
        uint256 proposalId = _recordProposal(proposalHash, msg.sender);
        custodianProposals[proposalId] = _newCustodian;
        emit CustodianProposed(proposalId, _newCustodian, msg.sender);
    }

    function voteOnCustodianProposal(uint256 _proposalId, bool _approve) external {
        Proposal storage p = proposals[_proposalId];
        require(p.voteStartTime > 0, "Proposal does not exist");
        require(block.timestamp < p.voteEndTime, "Voting period has ended");
        require(!p.executed, "Proposal already executed");
        require(!_hasVoted(_proposalId, msg.sender), "Already voted on this proposal");
        require(_getVotingPower(msg.sender) > 0, "No voting power");

        p.hasVoted[msg.sender] = true;
        if (_approve) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }
        emit CustodianVoteCast(_proposalId, msg.sender, _approve);
    }

    function executeCustodianProposal(uint256 _proposalId) external onlyOwnerOrCustodian {
        Proposal storage p = proposals[_proposalId];
        _finalizeProposal(_proposalId); // Ensure proposal is finalized

        require(p.approved, "Proposal not approved or already executed");
        address newCustodian = custodianProposals[_proposalId];
        require(newCustodian != address(0), "Invalid custodian proposal"); // Ensure it's a custodian proposal

        transferOwnership(newCustodian); // Transfer ownership (custodial role)
        emit CustodianProposalExecuted(_proposalId, newCustodian);
    }

    function addVerifiableCredential(bytes32 _credentialHash, address _issuer) external {
        // Only specific trusted entities or the SA itself can add credentials
        // For simplicity, let custodian add them. In advanced version, this could be
        // a specific verifier contract or the SA's SI deciding.
        require(msg.sender == owner(), "Only custodian can add credentials");
        _credentialCount++;
        _credentials[_credentialCount] = _credentialHash;
        _credentialIssuers[_credentialCount] = _issuer;
        emit CredentialAdded(_credentialHash, _issuer);
    }

    function getCredentialCount() external view override returns (uint256) {
        return _credentialCount;
    }

    // --- B.2. Metabolic & Resource Management ---

    function depositEssence(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(essenceToken.transferFrom(msg.sender, address(this), _amount), "Essence deposit failed");
        emit EssenceDeposited(msg.sender, _amount);
    }

    function withdrawEssence(uint256 _amount) external onlyOwnerOrCustodian whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(essenceToken.balanceOf(address(this)) >= _amount, "Insufficient essence balance");

        // SI Logic for withdrawal (example: don't withdraw if it goes below a critical threshold)
        uint256 currentBalance = essenceToken.balanceOf(address(this));
        if (currentBalance - _amount < siConfig.reactionThreshold) { // Example threshold
            revert("Withdrawal would violate SI critical threshold");
        }

        require(essenceToken.transfer(msg.sender, _amount), "Essence withdrawal failed");
        emit EssenceWithdrawn(msg.sender, _amount);
    }

    function processMetabolicCycle() external whenNotPaused {
        // Can be called by anyone, but should have incentives for calling if not autonomous
        // In a more advanced system, this could be triggered by Chainlink Keepers or a dedicated relayer network.
        require(block.timestamp >= lastMetabolicCycleTime + 1 hours, "Metabolic cycle too frequent"); // Example: once per hour

        uint256 initialBalance = essenceToken.balanceOf(address(this));
        int256 essenceChange = 0; // Can be positive (generation) or negative (consumption)

        // Simulate essence consumption/generation based on SI Config and external factors
        uint256 marketPriceData = _getOracleData("marketPrice"); // Example external data

        // Consumption: base rate + higher consumption for higher risk tolerance (if SI is active)
        essenceChange -= int256(siConfig.metabolismRate);
        if (siConfig.riskTolerance > 50) { // Example: more active SI consumes more
            essenceChange -= int256(siConfig.metabolismRate / 2);
        }

        // Generation: based on external market conditions (e.g., if price is good, SA "earns")
        if (marketPriceData > siConfig.reactionThreshold) { // If market is favorable
            essenceChange += int256(marketPriceData / 10); // Example: generate more essence
        }

        uint256 newBalance = initialBalance;
        if (essenceChange > 0) {
            newBalance += uint256(essenceChange);
            // In a real scenario, the SA would mint/acquire this essence, e.g., from a treasury or by executing actions.
            // For this example, we'll just simulate the balance change and assume the SA has this capability.
        } else {
            require(initialBalance >= uint256(-essenceChange), "Insufficient essence for metabolic cycle");
            newBalance -= uint256(-essenceChange);
        }

        // Update internal essence balance (conceptual, requires actual token transfers in production)
        // For now, we'll just simulate the balance change and assume the SA has enough operational essence.
        // In a real implementation, the SA might try to sell/buy assets or rely on external funding here.
        // As a conceptual example, we'll assume the essence is managed within the SA's control.
        // If the `essenceToken` is an actual ERC20, then the SA needs to hold that balance.
        // This function would either move tokens from its internal balance to `address(this)` or vice-versa.
        // For simplicity, we assume `essenceToken.balanceOf(address(this))` is the true reflection of SA's essence.

        // Update last cycle time
        lastMetabolicCycleTime = block.timestamp;
        emit MetabolicCycleProcessed(block.timestamp, uint256(essenceChange), newBalance);
    }

    function getEssenceBalance() external view override returns (uint256) {
        return essenceToken.balanceOf(address(this));
    }

    function distributeCycleRewards() external onlyOwnerOrCustodian whenNotPaused {
        uint256 totalEssence = essenceToken.balanceOf(address(this));
        uint256 rewardsPool = (totalEssence * siConfig.curatorRewardShare) / 10000; // siConfig.curatorRewardShare is in basis points

        require(rewardsPool > 0, "No rewards to distribute or reward share is zero");

        // Simplified distribution: sum up all attested data and distribute proportionally
        // In a real scenario, this would involve iterating through recent curated data and their attestations.
        // This is a placeholder for a more complex reward distribution algorithm.
        address[] memory eligibleCurators; // Collect eligible curators based on data
        uint256 totalAttestationScore = 0;

        // In a real scenario, this would loop through active curated data (e.g., last 24h)
        // For this example, we'll just give a portion to a dummy "curator pool" address.
        // This requires a separate registry/tracker for curators.
        
        // Placeholder: sending to owner for demonstration
        if (essenceToken.transfer(owner(), rewardsPool)) {
            emit RewardsDistributed(rewardsPool, owner());
        } else {
            revert("Reward distribution failed");
        }
    }

    // --- B.3. Synthetic Intelligence (SI) & Adaptation ---

    function configureSIParameters(SIConfig calldata _newConfig) external onlyOwnerOrCustodian whenNotPaused {
        // Direct update for faster iteration/tuning by custodian/owner.
        // Critical changes might go through a voting process.
        siConfig = _newConfig;
        emit SICfgUpdated(_newConfig);
    }

    function proposeSIUpgrade(bytes32 _newLogicCodeHash) external onlyOwnerOrCustodian {
        require(_newLogicCodeHash != bytes32(0), "New logic code hash cannot be zero");
        bytes32 proposalHash = keccak256(abi.encodePacked("SI_UPGRADE", _newLogicCodeHash));
        uint256 proposalId = _recordProposal(proposalHash, msg.sender);
        siUpgradeProposals[proposalId] = _newLogicCodeHash;
        emit SIUpgradeProposed(proposalId, _newLogicCodeHash);
    }

    function voteOnSIUpgrade(uint256 _proposalId, bool _approve) external {
        Proposal storage p = proposals[_proposalId];
        require(p.voteStartTime > 0, "Proposal does not exist");
        require(block.timestamp < p.voteEndTime, "Voting period has ended");
        require(!p.executed, "Proposal already executed");
        require(!_hasVoted(_proposalId, msg.sender), "Already voted on this proposal");
        require(_getVotingPower(msg.sender) > 0, "No voting power");

        p.hasVoted[msg.sender] = true;
        if (_approve) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }
        emit SIUpgradeVoteCast(_proposalId, msg.sender, _approve);
    }

    function executeSIUpgrade(uint256 _proposalId) external onlyOwnerOrCustodian {
        Proposal storage p = proposals[_proposalId];
        _finalizeProposal(_proposalId); // Ensure proposal is finalized

        require(p.approved, "Proposal not approved or already executed");
        bytes32 newLogicHash = siUpgradeProposals[_proposalId];
        require(newLogicHash != bytes32(0), "Invalid SI upgrade proposal");

        // In a real system, this would point to a new logic contract or a specific function table.
        // For this conceptual example, we're just recording the hash.
        // The actual runtime SI logic would live in an upgradeable proxy or a callable library.
        // As we don't use a proxy here for simplicity, this merely records the intent.
        // A proxy pattern would replace the implementation address here.
        // _siLogicAddress = newLogicAddress; // Example if using a proxy
        
        // For this example, we'll just acknowledge the hash.
        // The SA would externally ensure it uses this logic for its processes.
        emit SIUpgradeExecuted(_proposalId, newLogicHash);
    }

    function getSIState() external view override returns (SIConfig memory, uint256 _lastMetabolicCycleTime) {
        return (siConfig, lastMetabolicCycleTime);
    }

    function querySIDecision(uint256 _inputDataPoint) external view override returns (bool decision, string memory rationale) {
        // Simulate a decision based on current SI parameters
        // Example: if input data point exceeds reaction threshold, SA decides "true" (e.g., to act)
        if (_inputDataPoint > siConfig.reactionThreshold) {
            return (true, "Input data exceeded reaction threshold, suggesting action.");
        } else {
            return (false, "Input data below reaction threshold, maintaining current state.");
        }
    }

    // --- B.4. Inter-Asset Collaboration & Curation ---

    function initiateCollaboration(address _targetSA, uint256 _essenceShare, uint256 _duration) external onlyOwnerOrCustodian whenNotPaused {
        require(_targetSA != address(0) && _targetSA != address(this), "Invalid target SA");
        require(_essenceShare > 0 && _essenceShare <= 10000, "Essence share must be 1-10000 (basis points)"); // Max 100%
        require(_duration > 0, "Duration must be greater than zero");

        // SI could decide this: e.g., if target SA has good reputation (via its credentials)
        // or if current essence is high and needs diversification.
        // This would create a proposal on the target SA, or directly call it if it accepts direct calls.

        // For simplicity, we just emit the intent. Actual cross-SA proposal would involve calls to targetSA
        // and a shared registry of proposals.
        emit CollaborationInitiated(address(this), _targetSA, _essenceShare, _duration);
    }

    function respondToCollaboration(address _proposingSA, uint256 _proposalId, bool _accept) external onlyOwnerOrCustodian whenNotPaused {
        // This function assumes a collaboration proposal was previously made to this SA.
        // In a real system, there would be a registry of pending collaboration proposals.
        // The _proposalId would refer to a proposal on THIS SA, originating from _proposingSA.

        // SI could decide this: e.g., check proposing SA's reputation, its essence balance, its SIConfig
        bool siAgrees = querySIDecision(essenceToken.balanceOf(_proposingSA)).decision; // Example: SA accepts if proposer has enough essence

        if (_accept && !siAgrees) {
            revert("SA's SI does not agree with accepting this collaboration");
        }
        
        // Mark the proposal as responded to. (Conceptual, requires actual proposal tracking)
        emit CollaborationResponded(address(this), _proposingSA, _proposalId, _accept);
    }

    function submitCuratedData(string memory _dataType, bytes memory _dataHash, uint256 _relevanceScore) external whenNotPaused {
        require(_relevanceScore <= 100, "Relevance score must be 0-100");
        bytes32 uniqueDataId = keccak256(abi.encodePacked(_dataType, _dataHash));
        
        if (curatedData[uniqueDataId].curator == address(0)) {
            curatedData[uniqueDataId] = CuratedData({
                curator: msg.sender,
                dataType: _dataType,
                dataHash: _dataHash,
                relevanceScore: _relevanceScore,
                attestationSum: 0,
                attestationCount: 0
            });
        } else {
            // Update existing data, or reject new submission of same hash
            revert("Data hash already submitted"); // Or allow updates by original curator
        }
        emit CuratedDataSubmitted(msg.sender, _dataType, uniqueDataId, _relevanceScore);
    }

    function attestCuratedData(address _curator, bytes memory _dataHash, uint256 _attestationScore) external whenNotPaused {
        require(_attestationScore <= 100, "Attestation score must be 0-100");
        bytes32 uniqueDataId = _dataHash; // Assuming _dataHash is the unique ID (e.g., IPFS hash or content hash)
        CuratedData storage data = curatedData[uniqueDataId];

        require(data.curator != address(0), "Curated data not found");
        require(data.curator == _curator, "Curator mismatch for data hash");
        require(!hasAttested[uniqueDataId][msg.sender], "Already attested to this data");

        data.attestationSum += _attestationScore;
        data.attestationCount++;
        hasAttested[uniqueDataId][msg.sender] = true;

        emit CuratedDataAttested(msg.sender, _curator, uniqueDataId, _attestationScore);
    }

    // --- Modifiers ---
    modifier onlyOwnerOrCustodian() {
        require(msg.sender == owner() || msg.sender == _msgSender(), "Only owner or custodian allowed");
        _;
    }

    // Override Ownable's _updateAcl as it's not present in 0.8.20 and causes compilation issue without it, but is also not needed for the core example.
    // In a full implementation, you'd inherit from a more complete Ownable, or implement similar ACL logic.
    // function _updateAcl(address oldOwner, address newOwner) internal virtual override {} 
}

// --- Contract 3: SentientAssetProtocolFactory.sol ---
// Central factory and registry for Sentient Assets
contract SentientAssetProtocolFactory is Ownable, Pausable {
    uint256 private _nextSaId;
    mapping(uint256 => address) public saRegistry; // saId => SentientAsset address
    mapping(address => uint256) public saIdLookup; // SentientAsset address => saId

    address public saImplementation; // Address of the SentientAsset contract to be cloned/deployed
    address public globalOracleAddress; // Global oracle address for all SAs

    // The ERC-20 token that will serve as "essence" for all deployed SAs.
    IERC20 public essenceToken;

    event SentientAssetDeployed(uint256 indexed saId, address indexed saAddress, address indexed owner, string name, string symbol);
    event GlobalOracleUpdated(address indexed newOracleAddress);
    event SAImplementationUpdated(address indexed newImplementation);

    constructor(address _initialOwner, address _essenceTokenAddress, address _initialSAImplementation, address _initialGlobalOracle) Ownable(_initialOwner) {
        _nextSaId = 1;
        saImplementation = _initialSAImplementation;
        globalOracleAddress = _initialGlobalOracle;
        essenceToken = IERC20(_essenceTokenAddress);
    }

    // --- A. SentientAssetProtocolFactory Functions ---

    function deploySentientAsset(
        string memory _name,
        string memory _symbol,
        address _initialOwner,
        ISentientAsset.SIConfig calldata _initialSIConfig
    ) external onlyOwner whenNotPaused returns (address newSaAddress) {
        require(saImplementation != address(0), "SA implementation not set");

        // Deploy a new SentientAsset instance
        // Using `new` keyword to deploy, for upgradeability, a proxy pattern would be preferred.
        // For this example, each SA is a new, separate contract.
        SentientAsset newSA = new SentientAsset(
            _nextSaId,
            _name,
            _symbol,
            _initialOwner,
            address(essenceToken),
            globalOracleAddress,
            _initialSIConfig
        );

        saRegistry[_nextSaId] = address(newSA);
        saIdLookup[address(newSA)] = _nextSaId;
        _nextSaId++;

        emit SentientAssetDeployed(_nextSaId - 1, address(newSA), _initialOwner, _name, _symbol);
        return address(newSA);
    }

    function getSentientAssetAddress(uint256 _saId) external view override returns (address) {
        return saRegistry[_saId];
    }

    function getSentientAssetCount() external view override returns (uint256) {
        return _nextSaId - 1;
    }

    function setGlobalOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        globalOracleAddress = _oracleAddress;
        emit GlobalOracleUpdated(_oracleAddress);
    }

    function pauseProtocol() external onlyOwner {
        _pause();
    }

    function unpauseProtocol() external onlyOwner {
        _unpause();
    }

    function setSAImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "New implementation address cannot be zero");
        saImplementation = _newImplementation;
        emit SAImplementationUpdated(_newImplementation);
    }
}
```