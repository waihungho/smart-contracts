This smart contract, `NeuroNexusProtocol`, envisions a decentralized ecosystem for collaborative AI model training and data synthesis. It's designed to be a unique blend of DAO governance, dynamic incentives, and on-chain representation of off-chain AI assets. The goal is to facilitate the creation and validation of AI models and datasets in a transparent, community-driven manner, moving beyond standard open-source patterns by integrating a multi-layered, adaptive system.

---

## NeuroNexusProtocol: Decentralized AI Model & Data Synthesis Network

### Contract Outline

*   **Name:** `NeuroNexusProtocol`
*   **Purpose:** A decentralized platform for collaborative AI model training and data synthesis, governed by a DAO. It uses custom ERC-20 (NNT) and ERC-721 (DataNFT, ModelNFT) tokens, a reputation system, and dynamic protocol parameters.
*   **Key Concepts & Advanced Features:**
    *   **Decentralized AI Lifecycle Management:** On-chain orchestration of data contribution, model architecture proposal, training funding, compute resource signaling, and validated model deployment.
    *   **Dynamic Adaptation:** Core protocol parameters (e.g., fee tiers, staking yield factors, epoch durations) are designed to be adjusted via DAO proposals and execution, allowing the protocol to evolve and adapt to network needs and market conditions.
    *   **Reputation & Incentive Alignment:** A sophisticated system involving NNT staking, reputation scores, and targeted rewards/penalties to align incentives, encourage honest participation, and penalize malicious actors (e.g., for submitting faulty data or models).
    *   **Epoch-based Operations:** The entire network operates in distinct epochs, providing structured cycles for training, validation, reward distribution, and protocol evolution. This allows for predictable and measurable progress.
    *   **Dual-NFT System:** Utilizes two distinct ERC-721 tokens: `DataNFTs` to represent validated, quality-controlled datasets and `ModelNFTs` to represent trained, verified AI models. This separates the provenance of data from the intellectual property of the derived model.
    *   **Simulated Off-chain Compute & Proofs:** Acknowledges that heavy AI computation occurs off-chain. The contract focuses on on-chain governance, funding, and verification mechanisms (e.g., hash submissions, DAO reviews) to ensure the integrity and provenance of these off-chain processes.
    *   **Gas Efficiency & Scalability Considerations:** While the full AI training is off-chain, the on-chain logic is designed to be as efficient as possible for critical governance and asset management tasks.
*   **Core Components:**
    *   `NNT (NeuroNexusToken)`: An ERC-20 utility and governance token used for staking, funding, rewards, and voting.
    *   `DataNFT`: An ERC-721 token representing a unique, validated dataset available for AI training.
    *   `ModelNFT`: An ERC-721 token representing a unique, validated AI model, trained using approved data.
    *   `AccessControl`: A robust role-based permission system to manage various participants (Admin, DataProvider, ModelProposer, ComputeStaker, DAOExecutor).
    *   `EpochManager`: Manages the progression of network epochs, triggering epoch-based events.
    *   `ReputationRegistry`: Tracks and updates the reputation scores of network contributors.
    *   `GovernanceModule`: Manages DAO proposals, voting, and execution of protocol changes.

### Function Summary (25 Functions)

**I. Core Infrastructure & Access Control:**
1.  `constructor()`: Initializes the contract, sets up roles, mints the NNT token, and deploys NFT contracts.
2.  `grantRole(bytes32 role, address account)`: Grants a specified role (e.g., `ADMIN_ROLE`, `DATA_PROVIDER_ROLE`) to an address.
3.  `revokeRole(bytes32 role, address account)`: Revokes a specified role from an address.
4.  `setEpochTransitionPause(bool _paused)`: Allows an admin to pause or unpause the automatic advancement of epochs for maintenance.

**II. NNT & Staking Operations:**
5.  `stakeNNT(uint256 amount)`: Allows users to stake `NNT` tokens to participate in the network, gain reputation, and qualify for roles.
6.  `unstakeNNT(uint256 amount)`: Allows users to unstake `NNT` tokens, potentially after a cooldown period.
7.  `getAvailableStakingYield(address staker)`: View function to calculate the accrued NNT yield for a specific staker based on their stake and current yield factor.
8.  `claimStakingYield()`: Allows stakers to claim their accumulated NNT staking rewards.

**III. DataNFT Lifecycle Management:**
9.  `proposeDataset(string calldata metadataURI, bytes32 contentHash)`: A `DataProvider` proposes a new dataset by providing its metadata URI and a content hash for validation.
10. `voteOnDatasetProposal(uint256 proposalId, bool approved)`: DAO members vote on the quality, legality, and suitability of a proposed dataset.
11. `mintValidatedDataNFT(uint256 proposalId)`: If a dataset proposal is approved by the DAO, an `DAO_EXECUTOR_ROLE` member can mint the corresponding `DataNFT`.
12. `challengeDataNFTIntegrity(uint256 dataNftId, string calldata reasonURI)`: Allows any participant to challenge the integrity or quality of an already minted `DataNFT`, initiating a DAO dispute resolution process.

**IV. ModelNFT Lifecycle Management:**
13. `proposeModelArchitecture(string calldata metadataURI, uint256[] calldata requiredDataNFTs)`: A `ModelProposer` suggests a new AI model architecture, specifying metadata and the `DataNFTs` required for its training.
14. `allocateTrainingFunds(uint256 modelProposalId, uint256 nntAmount)`: Users or the DAO fund a specific model's training epoch by allocating `NNT` tokens, which are then distributed as rewards to `ComputeStakers`.
15. `signalComputeCapacity(uint256 minimumStake)`: `ComputeStakers` indicate their readiness to perform off-chain AI training by locking a `minimumStake` of `NNT`.
16. `submitTrainedModelProof(uint256 modelProposalId, bytes32 trainedModelHash, uint256[] calldata dataNFTsUsed)`: A `ComputeStaker` submits the cryptographic hash of a trained AI model, along with references to the `DataNFTs` used for training.
17. `verifyAndMintModelNFT(uint256 modelProposalId, bytes32 submittedHash)`: An `DAO_EXECUTOR_ROLE` member verifies the submitted model proof (off-chain) and, upon confirmation, mints the `ModelNFT` to the `ModelProposer`.

**V. DAO Governance & Protocol Adaptation:**
18. `proposeGovernanceParameterChange(string calldata parameterName, uint256 newValue)`: DAO members can propose changes to core protocol parameters (e.g., epoch duration, minimum stake, fee percentages).
19. `voteOnGovernanceProposal(uint256 proposalId, bool approved)`: DAO members vote on proposed parameter changes.
20. `executeApprovedGovernanceProposal(uint256 proposalId)`: An `DAO_EXECUTOR_ROLE` member executes a governance proposal once it has passed voting.
21. `updateDynamicFeeTier(uint8 newTier)`: Allows the DAO (via an executed proposal) to select from predefined fee tiers for network services, adapting to economic conditions.

**VI. Reputation & Epoch Management:**
22. `advanceEpoch()`: An `ADMIN_ROLE` or `DAO_EXECUTOR_ROLE` member triggers the transition to the next epoch, initiating reward distribution and resetting epoch-specific states.
23. `awardReputation(address contributor, uint256 amount)`: An `ADMIN_ROLE` or `DAO_EXECUTOR_ROLE` member can award reputation points to contributors for positive actions.
24. `slashReputation(address contributor, uint256 amount)`: An `ADMIN_ROLE` or `DAO_EXECUTOR_ROLE` member can deduct reputation points from contributors for malicious or non-compliant behavior.
25. `distributeModelTrainingRewards(uint256 modelProposalId)`: Distributes `NNT` rewards to the `ModelProposer` and `ComputeStakers` who successfully contributed to a validated and minted `ModelNFT`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For utility functions, if needed, though not strictly for this contract's core logic.

// --- Custom ERC20 Token for NeuroNexus ---
contract NeuroNexusToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("NeuroNexus Token", "NNT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); // Initially, deployer is minter
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

// --- Custom ERC721 for Data Assets ---
contract DataNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("DATA_MINTER_ROLE");

    constructor() ERC721("NeuroNexus Data Asset", "NN_DATA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); // Initially, deployer is minter
    }

    function mint(address to, uint256 tokenId, string calldata uri) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Override to ensure only permitted roles can transfer if desired, or leave as default ERC721
    // function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
    //     // Custom transfer logic if needed, e.g., restricting transfers based on certain conditions
    //     super._transfer(from, to, tokenId);
    // }
}

// --- Custom ERC721 for Model Assets ---
contract ModelNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MODEL_MINTER_ROLE");

    constructor() ERC721("NeuroNexus Model Asset", "NN_MODEL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); // Initially, deployer is minter
    }

    function mint(address to, uint256 tokenId, string calldata uri) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}

contract NeuroNexusProtocol is Context, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // For protocol maintenance, critical parameter changes
    bytes32 public constant DATA_PROVIDER_ROLE = keccak256("DATA_PROVIDER_ROLE"); // Can propose datasets
    bytes32 public constant MODEL_PROPOSER_ROLE = keccak256("MODEL_PROPOSER_ROLE"); // Can propose model architectures
    bytes32 public constant COMPUTE_STAKER_ROLE = keccak256("COMPUTE_STAKER_ROLE"); // Can signal compute capacity and submit trained models
    bytes32 public constant DAO_EXECUTOR_ROLE = keccak256("DAO_EXECUTOR_ROLE"); // Can execute approved DAO proposals (e.g., mint NFTs, update params)

    // --- Tokens & Contracts ---
    NeuroNexusToken public nntToken;
    DataNFT public dataNFT;
    ModelNFT public modelNFT;

    // --- Epoch Management ---
    uint256 public currentEpoch;
    uint256 public epochDuration; // In seconds
    uint256 public lastEpochAdvanceTime;
    bool public epochTransitionsPaused;

    // --- Staking & Reputation ---
    mapping(address => uint256) public stakedNNT;
    mapping(address => uint256) public lastStakeUpdateTime; // To calculate yield
    mapping(address => uint256) public reputationScores;
    uint256 public stakingYieldFactor; // Basis points, e.g., 100 = 1% per epoch

    // --- Dataset Proposals ---
    struct DatasetProposal {
        address proposer;
        string metadataURI;
        bytes32 contentHash;
        uint256 proposalTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool approved;
        bool minted;
        bool challenged;
        uint256 dataNftId; // If minted
    }
    uint256 public nextDatasetProposalId;
    mapping(uint256 => DatasetProposal) public datasetProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnDataset;

    // --- Model Architecture Proposals ---
    struct ModelProposal {
        address proposer;
        string metadataURI;
        uint256[] requiredDataNFTs;
        uint256 proposalTime;
        uint256 allocatedNNTFunds;
        bytes32 trainedModelHash; // Hash of the final trained model from a ComputeStaker
        uint256[] dataNFTsUsedForTraining; // Actual DataNFTs used by the ComputeStaker
        address computeStakerWhoTrained;
        bool submittedProof;
        bool verified;
        bool minted;
        uint256 modelNftId; // If minted
    }
    uint256 public nextModelProposalId;
    mapping(uint256 => ModelProposal) public modelProposals;

    // --- Compute Stakers (Signaling off-chain compute) ---
    mapping(address => bool) public isComputeStakerAvailable; // True if staker has signaled availability
    mapping(address => uint256) public computeStakerMinStake; // Minimum NNT stake required for compute stakers

    // --- DAO Governance Proposals ---
    struct GovernanceProposal {
        address proposer;
        string description;
        bytes32 paramKey; // Key for the parameter to change
        uint256 newValue; // New value for the parameter
        uint256 proposalTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
    }
    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnGovernance;

    // --- Dynamic Fee Tiers ---
    uint256[] public feeTiers; // e.g., [0, 100, 200] for 0%, 1%, 2% fees
    uint8 public currentFeeTierIndex;

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpochId, uint256 timestamp);
    event NNTStaked(address indexed staker, uint256 amount);
    event NNTUnstaked(address indexed staker, uint256 amount);
    event StakingYieldClaimed(address indexed staker, uint256 amount);

    event DatasetProposed(uint256 indexed proposalId, address indexed proposer, string metadataURI, bytes32 contentHash);
    event DatasetVote(uint256 indexed proposalId, address indexed voter, bool approved);
    event DataNFTMinted(uint256 indexed proposalId, uint256 indexed dataNftId, address indexed recipient);
    event DataNFTIntegrityChallenged(uint256 indexed dataNftId, address indexed challenger, string reasonURI);

    event ModelArchitectureProposed(uint256 indexed proposalId, address indexed proposer, string metadataURI);
    event TrainingFundsAllocated(uint256 indexed modelProposalId, address indexed funder, uint256 amount);
    event ComputeCapacitySignaled(address indexed staker, uint256 minimumStake);
    event TrainedModelProofSubmitted(uint256 indexed modelProposalId, address indexed computeStaker, bytes32 trainedModelHash);
    event ModelNFTMinted(uint256 indexed modelProposalId, uint256 indexed modelNftId, address indexed recipient);
    event ModelTrainingRewardsDistributed(uint256 indexed modelProposalId, uint256 totalRewards, address indexed proposer, address indexed computeStaker);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, bytes32 paramKey, uint256 newValue);
    event GovernanceVote(uint256 indexed proposalId, address indexed voter, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event FeeTierUpdated(uint8 indexed newTierIndex, uint256 newFeePercentage);

    event ReputationAwarded(address indexed contributor, uint256 amount);
    event ReputationSlashed(address indexed contributor, uint256 amount);

    // --- Constructor ---
    constructor(
        uint256 _initialEpochDuration,
        uint256 _initialStakingYieldFactor,
        uint256[] memory _initialFeeTiers // e.g., [0, 50, 100] for 0%, 0.5%, 1%
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is default admin
        _grantRole(ADMIN_ROLE, msg.sender); // Deployer is also a specific protocol admin

        nntToken = new NeuroNexusToken();
        dataNFT = new DataNFT();
        modelNFT = new ModelNFT();

        // Grant NNT minter role to this protocol contract, so it can mint rewards
        nntToken.grantRole(nntToken.MINTER_ROLE(), address(this));
        dataNFT.grantRole(dataNFT.MINTER_ROLE(), address(this));
        modelNFT.grantRole(modelNFT.MINTER_ROLE(), address(this));

        currentEpoch = 1;
        epochDuration = _initialEpochDuration; // e.g., 7 days in seconds
        lastEpochAdvanceTime = block.timestamp;
        epochTransitionsPaused = false;

        stakingYieldFactor = _initialStakingYieldFactor; // e.g., 100 for 1% per epoch

        nextDatasetProposalId = 1;
        nextModelProposalId = 1;
        nextGovernanceProposalId = 1;

        require(_initialFeeTiers.length > 0, "Fee tiers cannot be empty");
        feeTiers = _initialFeeTiers;
        currentFeeTierIndex = 0; // Default to the first (often 0%) fee tier

        // Example: Initial NNT supply for DAO treasury or early adopters
        // nntToken.mint(msg.sender, 100_000_000 * 10**18);
    }

    // --- Modifiers ---
    modifier onlyAfterEpochDuration() {
        require(block.timestamp >= lastEpochAdvanceTime + epochDuration, "Epoch duration not yet passed.");
        _;
    }

    modifier notPausedEpochTransitions() {
        require(!epochTransitionsPaused, "Epoch transitions are paused.");
        _;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @notice Grants a specified role to an account. Only callable by an account with the DEFAULT_ADMIN_ROLE.
     * @param role The role to grant (e.g., ADMIN_ROLE, DATA_PROVIDER_ROLE).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes a specified role from an account. Only callable by an account with the DEFAULT_ADMIN_ROLE.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @notice Pauses or unpauses epoch transitions. Only callable by ADMIN_ROLE.
     * This is a critical function for maintenance or emergency situations.
     * @param _paused True to pause, false to unpause.
     */
    function setEpochTransitionPause(bool _paused) public onlyRole(ADMIN_ROLE) {
        epochTransitionsPaused = _paused;
    }

    // --- II. NNT & Staking Operations ---

    /**
     * @notice Allows users to stake NNT tokens to participate in the network, gain reputation, and qualify for roles.
     * @param amount The amount of NNT to stake.
     */
    function stakeNNT(uint256 amount) public nonReentrant {
        require(amount > 0, "Cannot stake 0 NNT.");
        require(nntToken.transferFrom(_msgSender(), address(this), amount), "NNT transfer failed.");

        _updateStakingYield(_msgSender()); // Update yield before new stake
        stakedNNT[_msgSender()] = stakedNNT[_msgSender()].add(amount);
        lastStakeUpdateTime[_msgSender()] = block.timestamp;

        emit NNTStaked(_msgSender(), amount);
    }

    /**
     * @notice Allows users to unstake NNT tokens. May involve a cooldown.
     * @param amount The amount of NNT to unstake.
     */
    function unstakeNNT(uint256 amount) public nonReentrant {
        require(stakedNNT[_msgSender()] >= amount, "Insufficient staked NNT.");
        require(amount > 0, "Cannot unstake 0 NNT.");

        // Implement cooldown logic here if desired (e.g., mapping last unstake time and epoch cooldown)
        // For simplicity, direct unstake for now.

        _updateStakingYield(_msgSender()); // Update yield before unstake
        stakedNNT[_msgSender()] = stakedNNT[_msgSender()].sub(amount);
        lastStakeUpdateTime[_msgSender()] = block.timestamp;

        require(nntToken.transfer(_msgSender(), amount), "NNT transfer failed.");

        emit NNTUnstaked(_msgSender(), amount);
    }

    /**
     * @notice Calculates the available NNT yield for a specific staker based on their stake and yield factor.
     * @param staker The address of the staker.
     * @return The amount of NNT yield available.
     */
    function getAvailableStakingYield(address staker) public view returns (uint256) {
        if (stakedNNT[staker] == 0 || lastStakeUpdateTime[staker] >= block.timestamp) {
            return 0;
        }

        uint256 elapsedDuration = block.timestamp.sub(lastStakeUpdateTime[staker]);
        uint256 epochsPassed = elapsedDuration.div(epochDuration);

        // This is a simplified calculation. For more precision, consider per-block or per-second accumulation.
        return stakedNNT[staker].mul(stakingYieldFactor).mul(epochsPassed).div(10_000); // 10,000 for basis points
    }

    /**
     * @notice Allows stakers to claim their accumulated NNT staking rewards.
     */
    function claimStakingYield() public nonReentrant {
        uint256 yieldAmount = getAvailableStakingYield(_msgSender());
        require(yieldAmount > 0, "No yield available to claim.");

        _updateStakingYield(_msgSender()); // Update to reset lastStakeUpdateTime

        // Mint new NNT for the yield, as it's a reward
        nntToken.mint(_msgSender(), yieldAmount);

        emit StakingYieldClaimed(_msgSender(), yieldAmount);
    }

    /**
     * @dev Internal helper to update a staker's yield and reset their last update time.
     * This is called before any stake/unstake/claim operation to ensure accurate calculations.
     */
    function _updateStakingYield(address staker) internal {
        uint256 yieldToClaim = getAvailableStakingYield(staker);
        if (yieldToClaim > 0) {
            // In a real system, you might accumulate this into a pending_yield mapping
            // For this example, we just update the timestamp as if it was claimed
            // or implicitly handled by the next claim.
        }
        lastStakeUpdateTime[staker] = block.timestamp;
    }

    // --- III. DataNFT Lifecycle Management ---

    /**
     * @notice A DataProvider proposes a new dataset for community review and potential minting as a DataNFT.
     * @param metadataURI The URI pointing to the dataset's metadata (e.g., IPFS link).
     * @param contentHash A cryptographic hash of the dataset's content for integrity verification.
     */
    function proposeDataset(string calldata metadataURI, bytes32 contentHash) public onlyRole(DATA_PROVIDER_ROLE) {
        uint256 proposalId = nextDatasetProposalId++;
        datasetProposals[proposalId] = DatasetProposal({
            proposer: _msgSender(),
            metadataURI: metadataURI,
            contentHash: contentHash,
            proposalTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            approved: false,
            minted: false,
            challenged: false,
            dataNftId: 0
        });

        emit DatasetProposed(proposalId, _msgSender(), metadataURI, contentHash);
    }

    /**
     * @notice DAO members vote on the quality and validity of a proposed dataset.
     * Only addresses with staked NNT can vote (implied by NNT balance or reputation).
     * @param proposalId The ID of the dataset proposal.
     * @param approved True for approval, false for disapproval.
     */
    function voteOnDatasetProposal(uint256 proposalId, bool approved) public nonReentrant {
        DatasetProposal storage proposal = datasetProposals[proposalId];
        require(proposal.proposer != address(0), "Dataset proposal does not exist.");
        require(!proposal.approved, "Dataset proposal already approved.");
        require(!hasVotedOnDataset[proposalId][_msgSender()], "Already voted on this proposal.");
        require(stakedNNT[_msgSender()] > 0, "Must have staked NNT to vote."); // Simple voting power based on stake

        hasVotedOnDataset[proposalId][_msgSender()] = true;
        if (approved) {
            proposal.votesFor = proposal.votesFor.add(stakedNNT[_msgSender()]); // Vote weight by stake
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(stakedNNT[_msgSender()]);
        }

        emit DatasetVote(proposalId, _msgSender(), approved);
    }

    /**
     * @notice If a dataset proposal is approved by the DAO, an DAO_EXECUTOR_ROLE member can mint the corresponding DataNFT.
     * @param proposalId The ID of the dataset proposal to mint.
     */
    function mintValidatedDataNFT(uint256 proposalId) public onlyRole(DAO_EXECUTOR_ROLE) nonReentrant {
        DatasetProposal storage proposal = datasetProposals[proposalId];
        require(proposal.proposer != address(0), "Dataset proposal does not exist.");
        require(!proposal.minted, "DataNFT already minted for this proposal.");
        require(proposal.votesFor > proposal.votesAgainst, "Dataset proposal not approved by majority vote.");
        
        proposal.approved = true; // Mark as approved after successful voting
        uint256 dataNftId = dataNFT.totalSupply().add(1); // Simple sequential ID
        dataNFT.mint(proposal.proposer, dataNftId, proposal.metadataURI);
        
        proposal.minted = true;
        proposal.dataNftId = dataNftId;

        // Award reputation to the proposer
        awardReputation(proposal.proposer, 50); // Example reputation award

        emit DataNFTMinted(proposalId, dataNftId, proposal.proposer);
    }

    /**
     * @notice Allows any participant to challenge the integrity or quality of an already minted DataNFT,
     * initiating a DAO dispute resolution process.
     * @param dataNftId The ID of the DataNFT to challenge.
     * @param reasonURI The URI pointing to the detailed reason for the challenge.
     */
    function challengeDataNFTIntegrity(uint256 dataNftId, string calldata reasonURI) public nonReentrant {
        // Find the proposal corresponding to the DataNFT
        uint256 proposalId = 0;
        for (uint256 i = 1; i < nextDatasetProposalId; i++) {
            if (datasetProposals[i].dataNftId == dataNftId) {
                proposalId = i;
                break;
            }
        }
        require(proposalId != 0, "DataNFT not found or not associated with a proposal.");
        DatasetProposal storage proposal = datasetProposals[proposalId];
        require(proposal.minted, "DataNFT not yet minted.");
        require(!proposal.challenged, "DataNFT already under challenge.");

        proposal.challenged = true;
        // In a real system, this would trigger a new governance proposal for dispute resolution.
        // For simplicity, marking it as challenged is the on-chain representation.

        emit DataNFTIntegrityChallenged(dataNftId, _msgSender(), reasonURI);
    }


    // --- IV. ModelNFT Lifecycle Management ---

    /**
     * @notice A ModelProposer suggests a new AI model architecture, specifying metadata and required DataNFTs.
     * @param metadataURI The URI pointing to the model's architecture metadata.
     * @param requiredDataNFTs An array of DataNFT IDs required for training this model.
     */
    function proposeModelArchitecture(string calldata metadataURI, uint256[] calldata requiredDataNFTs) public onlyRole(MODEL_PROPOSER_ROLE) {
        // Basic check for required DataNFTs existence and validity
        for (uint256 i = 0; i < requiredDataNFTs.length; i++) {
            require(dataNFT.ownerOf(requiredDataNFTs[i]) != address(0), "Required DataNFT does not exist.");
            // Further checks could involve: is DataNFT challenged? is it compatible?
        }

        uint256 proposalId = nextModelProposalId++;
        modelProposals[proposalId] = ModelProposal({
            proposer: _msgSender(),
            metadataURI: metadataURI,
            requiredDataNFTs: requiredDataNFTs,
            proposalTime: block.timestamp,
            allocatedNNTFunds: 0,
            trainedModelHash: 0,
            dataNFTsUsedForTraining: new uint256[](0),
            computeStakerWhoTrained: address(0),
            submittedProof: false,
            verified: false,
            minted: false,
            modelNftId: 0
        });

        emit ModelArchitectureProposed(proposalId, _msgSender(), metadataURI);
    }

    /**
     * @notice Users or the DAO fund a specific model's training by allocating NNT tokens.
     * These funds are later distributed as rewards to successful ComputeStakers.
     * @param modelProposalId The ID of the model proposal to fund.
     * @param nntAmount The amount of NNT tokens to allocate.
     */
    function allocateTrainingFunds(uint256 modelProposalId, uint256 nntAmount) public nonReentrant {
        ModelProposal storage proposal = modelProposals[modelProposalId];
        require(proposal.proposer != address(0), "Model proposal does not exist.");
        require(!proposal.submittedProof, "Model training proof already submitted.");
        require(nntAmount > 0, "Cannot allocate 0 NNT.");

        require(nntToken.transferFrom(_msgSender(), address(this), nntAmount), "NNT transfer failed.");
        proposal.allocatedNNTFunds = proposal.allocatedNNTFunds.add(nntAmount);

        emit TrainingFundsAllocated(modelProposalId, _msgSender(), nntAmount);
    }

    /**
     * @notice ComputeStakers indicate their readiness to perform off-chain AI training by locking a minimum NNT stake.
     * @param minimumStake The minimum NNT amount the staker is willing to commit for compute capacity.
     */
    function signalComputeCapacity(uint256 minimumStake) public onlyRole(COMPUTE_STAKER_ROLE) {
        require(stakedNNT[_msgSender()] >= minimumStake, "Staked NNT below minimum required for signaling.");
        isComputeStakerAvailable[_msgSender()] = true;
        computeStakerMinStake[_msgSender()] = minimumStake; // Can be used for matching
        // In a more advanced system, this could involve registering compute capabilities off-chain.

        emit ComputeCapacitySignaled(_msgSender(), minimumStake);
    }

    /**
     * @notice A ComputeStaker submits the cryptographic hash of a trained AI model,
     * along with references to the DataNFTs actually used for training.
     * This is the on-chain proof of off-chain work.
     * @param modelProposalId The ID of the model proposal this trained model corresponds to.
     * @param trainedModelHash The cryptographic hash of the trained model file/artifact.
     * @param dataNFTsUsed The actual DataNFT IDs utilized in training.
     */
    function submitTrainedModelProof(uint256 modelProposalId, bytes32 trainedModelHash, uint256[] calldata dataNFTsUsed) public onlyRole(COMPUTE_STAKER_ROLE) nonReentrant {
        ModelProposal storage proposal = modelProposals[modelProposalId];
        require(proposal.proposer != address(0), "Model proposal does not exist.");
        require(!proposal.submittedProof, "Training proof already submitted for this model.");
        require(isComputeStakerAvailable[_msgSender()], "Compute staker not available or not signaled capacity.");
        // Additional checks: ensure `dataNFTsUsed` are a subset of `requiredDataNFTs`
        // For simplicity, we assume the compute staker used valid data.
        // A robust system would require more sophisticated validation.

        proposal.trainedModelHash = trainedModelHash;
        proposal.dataNFTsUsedForTraining = dataNFTsUsed;
        proposal.computeStakerWhoTrained = _msgSender();
        proposal.submittedProof = true;

        emit TrainedModelProofSubmitted(modelProposalId, _msgSender(), trainedModelHash);
    }

    /**
     * @notice An DAO_EXECUTOR_ROLE member verifies the submitted model proof (off-chain)
     * and, upon confirmation, mints the ModelNFT to the ModelProposer.
     * @param modelProposalId The ID of the model proposal to verify and mint.
     * @param submittedHash The hash that was submitted by the compute staker. Used for double-check.
     */
    function verifyAndMintModelNFT(uint256 modelProposalId, bytes32 submittedHash) public onlyRole(DAO_EXECUTOR_ROLE) nonReentrant {
        ModelProposal storage proposal = modelProposals[modelProposalId];
        require(proposal.proposer != address(0), "Model proposal does not exist.");
        require(proposal.submittedProof, "No training proof submitted for this model.");
        require(!proposal.minted, "ModelNFT already minted for this proposal.");
        require(proposal.trainedModelHash == submittedHash, "Submitted hash mismatch."); // Verify correctness

        // The actual verification of the AI model's quality and functionality
        // is assumed to happen off-chain (e.g., by a decentralized oracle network or manual DAO review).
        // This function acts as the on-chain trigger based on that off-chain verification.

        proposal.verified = true;
        uint256 modelNftId = modelNFT.totalSupply().add(1); // Simple sequential ID
        modelNFT.mint(proposal.proposer, modelNftId, proposal.metadataURI); // Mints to the ModelProposer

        proposal.minted = true;
        proposal.modelNftId = modelNftId;

        // Distribute rewards upon successful minting
        distributeModelTrainingRewards(modelProposalId);

        emit ModelNFTMinted(modelProposalId, modelNftId, proposal.proposer);
    }

    // --- V. DAO Governance & Protocol Adaptation ---

    /**
     * @notice DAO members can propose changes to core protocol parameters.
     * @param parameterName A string identifier for the parameter (e.g., "epochDuration", "stakingYieldFactor").
     * @param newValue The new value for the parameter.
     */
    function proposeGovernanceParameterChange(string calldata parameterName, uint256 newValue) public {
        // Implement checks to ensure parameterName is valid and can be changed via governance
        // For simplicity, any string can be proposed, but execution will validate.
        require(stakedNNT[_msgSender()] > 0, "Must have staked NNT to propose governance change.");

        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposer: _msgSender(),
            description: string(abi.encodePacked("Change ", parameterName, " to ", Strings.toString(newValue))),
            paramKey: keccak256(abi.encodePacked(parameterName)),
            newValue: newValue,
            proposalTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit GovernanceProposalCreated(proposalId, _msgSender(), governanceProposals[proposalId].description, keccak256(abi.encodePacked(parameterName)), newValue);
    }

    /**
     * @notice DAO members vote on proposed protocol parameter changes.
     * Voting power typically tied to staked NNT or reputation.
     * @param proposalId The ID of the governance proposal.
     * @param approved True for approval, false for disapproval.
     */
    function voteOnGovernanceProposal(uint256 proposalId, bool approved) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposer != address(0), "Governance proposal does not exist.");
        require(!proposal.executed, "Governance proposal already executed.");
        require(!hasVotedOnGovernance[proposalId][_msgSender()], "Already voted on this proposal.");
        require(stakedNNT[_msgSender()] > 0, "Must have staked NNT to vote."); // Voting power by stake

        hasVotedOnGovernance[proposalId][_msgSender()] = true;
        if (approved) {
            proposal.votesFor = proposal.votesFor.add(stakedNNT[_msgSender()]);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(stakedNNT[_msgSender()]);
        }

        emit GovernanceVote(proposalId, _msgSender(), approved);
    }

    /**
     * @notice An DAO_EXECUTOR_ROLE member executes a governance proposal once it has passed voting.
     * @param proposalId The ID of the governance proposal to execute.
     */
    function executeApprovedGovernanceProposal(uint256 proposalId) public onlyRole(DAO_EXECUTOR_ROLE) nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposer != address(0), "Governance proposal does not exist.");
        require(!proposal.executed, "Governance proposal already executed.");
        require(proposal.votesFor > proposal.votesAgainst, "Governance proposal not approved by majority vote.");

        proposal.passed = true;
        proposal.executed = true;

        // Apply the parameter change based on paramKey
        if (proposal.paramKey == keccak256(abi.encodePacked("epochDuration"))) {
            epochDuration = proposal.newValue;
        } else if (proposal.paramKey == keccak256(abi.encodePacked("stakingYieldFactor"))) {
            stakingYieldFactor = proposal.newValue;
        } else if (proposal.paramKey == keccak256(abi.encodePacked("currentFeeTierIndex"))) {
            // Special handling for fee tier index, requires an existing tier
            require(proposal.newValue < feeTiers.length, "Invalid fee tier index.");
            currentFeeTierIndex = uint8(proposal.newValue);
            emit FeeTierUpdated(currentFeeTierIndex, feeTiers[currentFeeTierIndex]);
        } else {
            revert("Unknown or unauthorized parameter for direct governance execution.");
        }

        emit GovernanceProposalExecuted(proposalId, proposal.paramKey, proposal.newValue);
    }

    /**
     * @notice Allows the DAO (via an executed proposal) to select a new fee tier, adapting to economic conditions.
     * This is typically called by `executeApprovedGovernanceProposal`.
     * @param newTierIndex The index of the new fee tier to activate.
     */
    function updateDynamicFeeTier(uint8 newTierIndex) public onlyRole(DAO_EXECUTOR_ROLE) {
        require(newTierIndex < feeTiers.length, "Invalid fee tier index.");
        currentFeeTierIndex = newTierIndex;
        emit FeeTierUpdated(currentFeeTierIndex, feeTiers[currentFeeTierIndex]);
    }

    // --- VI. Reputation & Epoch Management ---

    /**
     * @notice An ADMIN_ROLE or DAO_EXECUTOR_ROLE member triggers the transition to the next epoch.
     * This initiates reward distribution, resets epoch-specific states, and allows for new cycles.
     */
    function advanceEpoch() public onlyRole(DAO_EXECUTOR_ROLE) notPausedEpochTransitions onlyAfterEpochDuration nonReentrant {
        currentEpoch = currentEpoch.add(1);
        lastEpochAdvanceTime = block.timestamp;

        // Distribute staking yields (could be done implicitly by `claimStakingYield` or explicitly here)
        // For simplicity in this example, `claimStakingYield` is explicit.

        // Reset epoch-specific states (e.g., vote counts if proposals are epoch-limited)
        // This example does not reset proposal votes across epochs, but it's a design choice.

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /**
     * @notice An ADMIN_ROLE or DAO_EXECUTOR_ROLE member can award reputation points to contributors for positive actions.
     * @param contributor The address of the contributor to award reputation to.
     * @param amount The amount of reputation points to award.
     */
    function awardReputation(address contributor, uint256 amount) public onlyRole(DAO_EXECUTOR_ROLE) {
        reputationScores[contributor] = reputationScores[contributor].add(amount);
        emit ReputationAwarded(contributor, amount);
    }

    /**
     * @notice An ADMIN_ROLE or DAO_EXECUTOR_ROLE member can deduct reputation points from contributors
     * for malicious or non-compliant behavior.
     * @param contributor The address of the contributor to slash reputation from.
     * @param amount The amount of reputation points to deduct.
     */
    function slashReputation(address contributor, uint256 amount) public onlyRole(DAO_EXECUTOR_ROLE) {
        reputationScores[contributor] = reputationScores[contributor].sub(amount);
        emit ReputationSlashed(contributor, amount);
    }

    /**
     * @notice Distributes NNT rewards to the ModelProposer and ComputeStakers
     * who successfully contributed to a validated and minted ModelNFT.
     * Called automatically upon `verifyAndMintModelNFT`.
     * @param modelProposalId The ID of the model proposal.
     */
    function distributeModelTrainingRewards(uint256 modelProposalId) internal nonReentrant {
        ModelProposal storage proposal = modelProposals[modelProposalId];
        require(proposal.verified, "Model not yet verified.");
        require(proposal.allocatedNNTFunds > 0, "No funds allocated for this model's training.");

        // Calculate distribution: e.g., 70% to ComputeStaker, 30% to ModelProposer
        uint256 computeStakerShare = proposal.allocatedNNTFunds.mul(70).div(100);
        uint256 proposerShare = proposal.allocatedNNTFunds.sub(computeStakerShare);

        // Mint and transfer NNT rewards
        nntToken.mint(proposal.computeStakerWhoTrained, computeStakerShare);
        nntToken.mint(proposal.proposer, proposerShare);

        // Award reputation to both parties for successful collaboration
        awardReputation(proposal.computeStakerWhoTrained, 100);
        awardReputation(proposal.proposer, 150);

        // Reset allocated funds for this proposal to prevent double distribution
        proposal.allocatedNNTFunds = 0;

        emit ModelTrainingRewardsDistributed(modelProposalId, computeStakerShare.add(proposerShare), proposal.proposer, proposal.computeStakerWhoTrained);
    }

    // --- View Functions (Additional) ---

    function getCurrentFeePercentage() public view returns (uint256) {
        return feeTiers[currentFeeTierIndex];
    }
}
```