This smart contract, named **DAICAMS (Decentralized Autonomous AI Model Curation System)**, introduces a novel ecosystem for the community-driven curation, governance, and monetization of AI models and datasets. It leverages Solidity's capabilities to manage off-chain AI resources through on-chain tokens and governance.

**Core Concepts & Innovations:**

1.  **Dual Token Economy:**
    *   **DAICAMSToken (ERC-20):** A utility and governance token used for staking, voting, paying for access, and bounty rewards.
    *   **AIModelNFT (ERC-721):** A dynamic NFT representing a unique, curated AI model. Its metadata can be updated on-chain to reflect performance changes, versioning, or community feedback, linking directly to off-chain model pointers (e.g., IPFS hashes for weights, training code, or prompt sets).

2.  **Decentralized AI Model Curation:**
    *   Users propose new AI models or datasets, which are then subject to DAO governance.
    *   Curators (stakeholders) vote on proposals, and successful proposals lead to the minting of an `AIModelNFT`.

3.  **Reputation System for Curators:** Staking DAICAMSTokens grants curator status. Success in voting on beneficial proposals and challenging malicious ones could influence a curator's reputation. (Simplified in this example, but extensible).

4.  **Simplified Quadratic Voting:** To mitigate whale dominance, the voting power calculation incorporates a square root of staked tokens, giving smaller stakers proportionally more influence.

5.  **Dynamic NFT Metadata for AI Models:** An `AIModelNFT`'s metadata URI can be updated by an authorized oracle (simulating off-chain AI performance monitoring), allowing the on-chain representation to evolve with the AI model's actual performance or development.

6.  **Tiered & One-Time Access Control:** Users can subscribe to different access tiers or pay a one-time fee using DAICAMSTokens to gain access to the pointers/details of curated AI models.

7.  **AI Improvement Bounty System:** The DAO can create bounties for enhancing existing AI models, incentivizing community contributions.

8.  **Oracle Integration (Simulated):** The contract includes functions where an `oracleAddress` (a trusted external entity) reports on AI model performance, triggering on-chain updates.

**Outline and Function Summary:**

The `DAICAMS` contract inherits from OpenZeppelin's `ERC20`, `ERC721`, `Ownable`, `Pausable`, and uses `ReentrancyGuard` and `SafeERC20`. This approach uses standard, audited building blocks while implementing novel logic on top.

**I. Core Setup & Administration (Inherited `Ownable`, `Pausable`)**
*   **`constructor(...)`**: Initializes the contract, mints initial DAICAMSTokens, and sets up the NFT collection.
*   **`setOracleAddress(address _newOracle)`**: Sets/updates the address of the trusted oracle. (Admin-only)
*   **`setCuratorMinStake(uint256 _newMinStake)`**: Sets the minimum DAICAMSToken amount required to be considered a curator. (Admin-only)
*   **`setProposalConfig(...)`**: Configures proposal parameters (voting period, quorum, quadratic voting divisor). (Admin-only)
*   **`pause()` / `unpause()`**: Emergency pause/unpause functionality. (Admin-only)

**II. DAICAMSToken (ERC-20) & Staking (Inherited `ERC20`)**
*   **`stakeDAICAMS(uint256 _amount)`**: Users stake DAICAMSTokens to participate in governance and become curators.
*   **`unstakeDAICAMS(uint256 _amount)`**: Users unstake their DAICAMSTokens.
*   **`getDAICAMSBalance(address _account)` (View)**: Returns an account's DAICAMSToken balance.
*   **`getTotalStaked(address _account)` (View)**: Returns the total DAICAMSTokens staked by an account.

**III. AIModelNFT (ERC-721) & Model Management (Inherited `ERC721`)**
*   **`submitModelProposal(...)`**: Users propose a new AI model with its details, IPFS hashes for model weights/data, access fee, and initial NFT metadata.
*   **`updateAIModelMetadataURI(uint256 _modelId, string memory _newMetadataURI)`**: An authorized oracle updates the metadata URI of an `AIModelNFT` to reflect new performance or versions.
*   **`linkAdditionalDatasetToModel(uint256 _modelId, string memory _datasetIPFSHash)`**: Links an additional dataset to an existing curated AI model.
*   **`getAIModelDetails(uint256 _modelId)` (View)**: Retrieves comprehensive details about a specific AI model NFT.
*   **`getAIModelNFTURI(uint256 _modelId)` (View)**: Returns the current metadata URI for an `AIModelNFT`.

**IV. DAO Governance & Voting**
*   **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows staked users (curators) to vote on proposals, utilizing simplified quadratic voting.
*   **`executeProposal(uint256 _proposalId)`**: Executes a successfully passed proposal (e.g., mints an `AIModelNFT`, distributes rewards).
*   **`getProposalDetails(uint256 _proposalId)` (View)**: Retrieves all data related to a specific proposal.
*   **`getVotePower(address _voter)` (View)**: Calculates a user's current voting power based on their staked tokens and quadratic weighting.

**V. Curator & Reputation System**
*   **`getCuratorReputation(address _curator)` (View)**: Returns the reputation score of a curator.
*   **`_adjustCuratorReputation(address _curator, int256 _delta)` (Internal)**: Adjusts a curator's reputation based on outcomes of proposals/challenges.
*   **`isCurator(address _account)` (View)**: Checks if an address meets the minimum staking requirement to be a curator.

**VI. Access Control & Monetization**
*   **`subscribeToTieredAccess(uint256 _tierId, uint256 _durationInDays)`**: Users pay DAICAMSTokens for time-based access to categories of models or premium features.
*   **`payForOneTimeModelAccess(uint256 _modelId)`**: Users pay a one-time fee in DAICAMSTokens for access to a specific AI model.
*   **`checkUserAccess(address _user, uint256 _modelId)` (View)**: Checks if a user has active access to a given model (via subscription or one-time payment).
*   **`getTierAccessDuration(address _user, uint256 _tierId)` (View)**: Returns the remaining access time for a specific tier for a user.

**VII. AI Improvement Bounty System**
*   **`createAIImprovementBounty(string memory _description, uint256 _rewardAmountDAICAMS, uint256 _deadline, uint256 _targetModelId)`**: Creates a bounty for enhancing an existing `AIModelNFT`, funded by DAICAMSTokens.
*   **`submitBountySolution(uint256 _bountyId, string memory _solutionHash)`**: Users submit a hash representing their off-chain solution to a bounty.
*   **`resolveBounty(uint256 _bountyId, address _winnerAddress)`**: The DAO (or admin, based on implementation) resolves a bounty, distributing rewards to the winner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Pausable.sol";

/**
 * @title DAICAMS (Decentralized Autonomous AI Model Curation System)
 * @author YourName (This can be you!)
 * @notice A smart contract for decentralized curation, governance, and monetization of AI models and datasets.
 *         It combines ERC-20 for utility/governance and ERC-721 for dynamic AI model representation.
 *
 * This contract uses OpenZeppelin libraries for standard ERC-20, ERC-721, Ownable, Pausable, and security features.
 * The core DAO logic, dynamic NFT metadata updates, quadratic voting mechanism, access control, and bounty system
 * are custom implementations designed to be novel and avoid direct duplication of existing open-source *projects*.
 *
 * Outline and Function Summary:
 *
 * I. Core Setup & Administration (Inherited `Ownable`, `Pausable`)
 *    1. `constructor(...)`: Initializes the contract, mints initial DAICAMSTokens, sets up NFT collection.
 *    2. `setOracleAddress(address _newOracle)`: Sets/updates the address of the trusted oracle. (Admin-only)
 *    3. `setCuratorMinStake(uint256 _newMinStake)`: Sets minimum DAICAMSToken stake for curators. (Admin-only)
 *    4. `setProposalConfig(...)`: Configures proposal parameters (voting period, quorum, quadratic voting divisor). (Admin-only)
 *    5. `pause()`: Pauses certain functionalities in emergencies. (Admin-only)
 *    6. `unpause()`: Unpauses functionalities. (Admin-only)
 *
 * II. DAICAMSToken (ERC-20) & Staking (Inherited `ERC20`)
 *    7. `stakeDAICAMS(uint256 _amount)`: Stakes DAICAMSTokens for governance/curator role.
 *    8. `unstakeDAICAMS(uint256 _amount)`: Unstakes DAICAMSTokens.
 *    9. `getDAICAMSBalance(address _account)` (View): Returns an account's DAICAMSToken balance.
 *    10. `getTotalStaked(address _account)` (View): Returns total DAICAMSTokens staked by an account.
 *
 * III. AIModelNFT (ERC-721) & Model Management (Inherited `ERC721`)
 *    11. `submitModelProposal(...)`: Users propose a new AI model for DAO review.
 *    12. `updateAIModelMetadataURI(uint256 _modelId, string memory _newMetadataURI)`: Authorized oracle updates an AI Model NFT's metadata (e.g., performance).
 *    13. `linkAdditionalDatasetToModel(uint256 _modelId, string memory _datasetIPFSHash)`: Links more datasets to an existing curated model.
 *    14. `getAIModelDetails(uint256 _modelId)` (View): Retrieves all details about a specific AI model NFT.
 *    15. `getAIModelNFTURI(uint256 _modelId)` (View): Get current metadata URI of an AI Model NFT.
 *
 * IV. DAO Governance & Voting
 *    16. `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a vote on a proposal, implementing simplified quadratic voting.
 *    17. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal (e.g., mints AI Model NFT).
 *    18. `getProposalDetails(uint256 _proposalId)` (View): Retrieves comprehensive details about a specific proposal.
 *    19. `getVotePower(address _voter)` (View): Calculates a user's current voting power based on staked tokens and quadratic weighting.
 *
 * V. Curator & Reputation System
 *    20. `getCuratorReputation(address _curator)` (View): Returns the reputation score of a curator.
 *    21. `_adjustCuratorReputation(address _curator, int256 _delta)` (Internal): Adjusts reputation based on outcomes.
 *    22. `isCurator(address _account)` (View): Checks if an address is currently a curator.
 *
 * VI. Access Control & Monetization
 *    23. `subscribeToTieredAccess(uint256 _tierId, uint256 _durationInDays)`: Pay DAICAMSTokens for time-based access to model categories.
 *    24. `payForOneTimeModelAccess(uint256 _modelId)`: Pay a one-time fee for specific AI model's details/pointers.
 *    25. `checkUserAccess(address _user, uint256 _modelId)` (View): Checks if a user has active access to a given model.
 *    26. `getTierAccessDuration(address _user, uint256 _tierId)` (View): Gets remaining access time for a specific tier.
 *
 * VII. AI Improvement Bounty System
 *    27. `createAIImprovementBounty(...)`: Creates a bounty for model improvements.
 *    28. `submitBountySolution(uint256 _bountyId, string memory _solutionHash)`: Submit a hash of an off-chain solution to a bounty.
 *    29. `resolveBounty(uint256 _bountyId, address _winnerAddress)`: Owner/Admin/DAO vote resolves a bounty, distributing reward.
 */
contract DAICAMS is ERC20, ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20; // For future external token interactions if needed.

    // --- Custom Errors ---
    error InvalidAmount();
    error NotEnoughStaked();
    error AlreadyStaked();
    error NotCurator();
    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error ProposalVotingPeriodEnded();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error NotOracle();
    error ModelNotFound();
    error AccessAlreadyActive();
    error AccessExpired();
    error AccessNotActive();
    error InsufficientPayment();
    error BountyNotFound();
    error BountyNotActive();
    error BountyAlreadyResolved();
    error BountyDeadlineNotReached();
    error BountyDeadlinePassed();
    error NotPermitted();


    // --- State Variables ---

    // Governance & Staking
    mapping(address => uint256) private _stakedBalances;
    mapping(address => mapping(uint256 => bool)) private _hasVoted; // proposalId => bool
    uint256 public minCuratorStake;
    address public oracleAddress;

    // Proposal Configuration
    uint256 public votingPeriod; // in seconds
    uint256 public quorumPercentage; // e.g., 50 for 50%
    uint256 public quadraticVoteWeightDivisor; // Divisor for quadratic voting, higher means less quadratic impact

    // AI Model NFTs (inherited ERC721)
    Counters.Counter private _aiModelTokenIds;

    struct AIModel {
        uint256 modelId;
        string name;
        string ipfsHash; // Hash of the model weights/code/config
        string datasetIPFSHash; // Primary dataset hash
        uint256 accessFeeDAICAMS; // Fee to access model details/pointers
        address proposer;
        uint256 creationTimestamp;
        string[] linkedDatasetIPFSHashes; // Additional datasets
        uint256 currentPerformanceScore; // From oracle
        bool retired;
    }
    mapping(uint256 => AIModel) public aiModels; // modelId => AIModel struct

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct Proposal {
        uint256 id;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        address proposer;
        ProposalState state;
        bytes callData; // Encoded function call for execution (e.g., mint NFT)
        uint256 targetModelId; // If proposal is for existing model
        // Parameters for new model proposals
        string newModelName;
        string newModelIPFSHash;
        string newDatasetIPFSHash;
        uint256 newAccessFeeDAICAMS;
        string newInitialMetadataURI;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // Curator Reputation (simplified)
    mapping(address => int256) public curatorReputation; // Can be negative for bad actors

    // Access Control & Monetization
    struct TierAccess {
        uint256 lastPaymentTimestamp;
        uint256 durationInDays; // Remaining duration
        uint256 tierId;
    }
    mapping(address => mapping(uint256 => TierAccess)) public userTierAccess; // user => tierId => TierAccess
    mapping(address => mapping(uint256 => uint256)) public oneTimeModelAccessExpiry; // user => modelId => expiryTimestamp

    // Bounty System
    enum BountyState { Active, Resolved, Canceled }
    struct Bounty {
        uint256 id;
        string description;
        uint256 rewardAmountDAICAMS;
        uint256 deadline;
        uint256 targetModelId; // Which AI model this bounty aims to improve
        address creator;
        string solutionHash; // Hash of the winning solution, set after resolution
        address winner;
        BountyState state;
    }
    Counters.Counter private _bountyIds;
    mapping(uint256 => Bounty) public bounties;


    // --- Events ---
    event DAICAMSStaked(address indexed user, uint256 amount);
    event DAICAMSUnstaked(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIModelNFTMinted(uint256 indexed modelId, address indexed owner, string modelName, string ipfsHash);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newURI);
    event ModelPerformanceReported(uint256 indexed modelId, uint256 performanceScore, string newMetadataURI);
    event AccessSubscribed(address indexed user, uint256 indexed tierId, uint256 durationInDays, uint256 expiry);
    event OneTimeAccessGranted(address indexed user, uint256 indexed modelId, uint256 expiry);
    event BountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, uint256 deadline, uint256 targetModelId);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed submitter, string solutionHash);
    event BountyResolved(uint256 indexed bountyId, address indexed winner, uint256 rewardAmount);

    /**
     * @dev Constructor for the DAICAMS contract.
     * @param _tokenName The name for the DAICAMSToken (ERC-20).
     * @param _tokenSymbol The symbol for the DAICAMSToken (ERC-20).
     * @param _nftName The name for the AIModelNFT (ERC-721).
     * @param _nftSymbol The symbol for the AIModelNFT (ERC-721).
     * @param _initialSupply Initial supply of DAICAMSTokens to mint to the deployer.
     * @param _minCuratorStake Minimum stake required to be a curator.
     * @param _oracleAddress Address of the trusted oracle for AI model performance updates.
     * @param _votingPeriodSeconds Duration of voting period in seconds.
     * @param _quorumPercent Quorum percentage (e.g., 50 for 50%).
     * @param _quadraticDivisor Divisor for quadratic voting to control influence.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _nftName,
        string memory _nftSymbol,
        uint256 _initialSupply,
        uint256 _minCuratorStake,
        address _oracleAddress,
        uint256 _votingPeriodSeconds,
        uint256 _quorumPercent,
        uint256 _quadraticDivisor
    ) ERC20(_tokenName, _tokenSymbol) ERC721(_nftName, _nftSymbol) Ownable(msg.sender) Pausable() {
        _mint(msg.sender, _initialSupply); // Mint initial supply to deployer
        minCuratorStake = _minCuratorStake;
        oracleAddress = _oracleAddress;
        votingPeriod = _votingPeriodSeconds;
        quorumPercentage = _quorumPercent;
        quadraticVoteWeightDivisor = _quadraticDivisor;
        if (_quadraticDivisor == 0) {
            revert InvalidAmount(); // Prevent division by zero
        }
    }

    // --- I. Core Setup & Administration ---

    /**
     * @dev Sets the address of the trusted oracle. Only owner can call.
     * @param _newOracle The new address for the oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        oracleAddress = _newOracle;
    }

    /**
     * @dev Sets the minimum DAICAMSToken amount required to be a curator. Only owner can call.
     * @param _newMinStake The new minimum stake amount.
     */
    function setCuratorMinStake(uint256 _newMinStake) external onlyOwner {
        minCuratorStake = _newMinStake;
    }

    /**
     * @dev Configures proposal parameters. Only owner can call.
     * @param _votingPeriodSeconds Duration of voting period in seconds.
     * @param _quorumPercent Quorum percentage (e.g., 50 for 50%).
     * @param _quadraticDivisor Divisor for quadratic voting to control influence.
     */
    function setProposalConfig(uint256 _votingPeriodSeconds, uint256 _quorumPercent, uint256 _quadraticDivisor) external onlyOwner {
        if (_quadraticDivisor == 0) {
            revert InvalidAmount();
        }
        votingPeriod = _votingPeriodSeconds;
        quorumPercentage = _quorumPercent;
        quadraticVoteWeightDivisor = _quadraticDivisor;
    }

    // `pause()` and `unpause()` are inherited from OpenZeppelin's Pausable and are onlyOwner.


    // --- II. DAICAMSToken (ERC-20) & Staking ---

    /**
     * @dev Allows a user to stake DAICAMSTokens for governance participation and curator status.
     * @param _amount The amount of DAICAMSTokens to stake.
     */
    function stakeDAICAMS(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        // Ensure the contract can pull the tokens
        require(allowance(msg.sender, address(this)) >= _amount, "Allowance too low for staking");
        
        _transfer(msg.sender, address(this), _amount); // Transfer tokens to the contract
        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].add(_amount);
        emit DAICAMSStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to unstake DAICAMSTokens.
     * @param _amount The amount of DAICAMSTokens to unstake.
     */
    function unstakeDAICAMS(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        if (_stakedBalances[msg.sender] < _amount) {
            revert NotEnoughStaked();
        }
        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].sub(_amount);
        _transfer(address(this), msg.sender, _amount); // Transfer tokens back
        emit DAICAMSUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Returns the DAICAMSToken balance of an account.
     * @param _account The address to query.
     * @return The balance of DAICAMSTokens.
     */
    function getDAICAMSBalance(address _account) external view returns (uint256) {
        return balanceOf(_account);
    }

    /**
     * @dev Returns the total amount of DAICAMSTokens staked by an account.
     * @param _account The address to query.
     * @return The total staked amount.
     */
    function getTotalStaked(address _account) external view returns (uint256) {
        return _stakedBalances[_account];
    }

    // --- III. AIModelNFT (ERC-721) & Model Management ---

    /**
     * @dev Allows a user to submit a proposal for a new AI model to be curated by the DAO.
     * This creates a proposal that needs to be voted on.
     * @param _modelName The name of the AI model.
     * @param _modelIPFSHash IPFS hash pointing to the AI model's resources (weights, code, etc.).
     * @param _datasetIPFSHash IPFS hash pointing to the primary dataset used by the model.
     * @param _accessFeeDAICAMS The DAICAMSToken fee required for one-time access to this model.
     * @param _initialMetadataURI Initial metadata URI for the AIModelNFT.
     */
    function submitModelProposal(
        string memory _modelName,
        string memory _modelIPFSHash,
        string memory _datasetIPFSHash,
        uint256 _accessFeeDAICAMS,
        string memory _initialMetadataURI
    ) external whenNotPaused returns (uint256) {
        if (!isCurator(msg.sender)) {
            revert NotCurator();
        }
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: string(abi.encodePacked("New AI Model Proposal: ", _modelName)),
            startBlock: block.number,
            endBlock: block.number.add(votingPeriod.div(block.chainid == 1 ? 13 : 1)), // Approximation: 13s per block on mainnet, or 1s for testing
            forVotes: 0,
            againstVotes: 0,
            proposer: msg.sender,
            state: ProposalState.Pending, // Will become Active upon first vote
            callData: "", // No specific callData for a new model proposal initially, execution will mint NFT
            targetModelId: 0, // Not targeting an existing model
            newModelName: _modelName,
            newModelIPFSHash: _modelIPFSHash,
            newDatasetIPFSHash: _datasetIPFSHash,
            newAccessFeeDAICAMS: _accessFeeDAICAMS,
            newInitialMetadataURI: _initialMetadataURI
        });

        emit ProposalCreated(proposalId, msg.sender, proposals[proposalId].description, proposals[proposalId].endBlock);
        return proposalId;
    }

    /**
     * @dev Allows an authorized oracle to update the metadata URI of an existing AIModelNFT.
     * This can reflect performance updates, version changes, etc.
     * @param _modelId The ID of the AIModelNFT to update.
     * @param _newMetadataURI The new metadata URI (e.g., pointing to an updated JSON on IPFS).
     */
    function updateAIModelMetadataURI(uint256 _modelId, string memory _newMetadataURI) external whenNotPaused {
        if (msg.sender != oracleAddress) {
            revert NotOracle();
        }
        if (aiModels[_modelId].modelId == 0) {
            revert ModelNotFound();
        }
        _setTokenURI(_modelId, _newMetadataURI); // ERC721 internal function
        emit AIModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @dev An authorized oracle reports on an AI model's performance and potentially updates its NFT metadata.
     * @param _modelId The ID of the AI model.
     * @param _performanceScore The reported performance score.
     * @param _newMetadataURI Optional: new metadata URI reflecting the updated performance.
     */
    function reportModelPerformance(uint256 _modelId, uint256 _performanceScore, string memory _newMetadataURI) external whenNotPaused {
        if (msg.sender != oracleAddress) {
            revert NotOracle();
        }
        AIModel storage model = aiModels[_modelId];
        if (model.modelId == 0) {
            revert ModelNotFound();
        }

        model.currentPerformanceScore = _performanceScore;
        if (bytes(_newMetadataURI).length > 0) {
            _setTokenURI(_modelId, _newMetadataURI); // Update NFT URI
            emit AIModelMetadataUpdated(_modelId, _newMetadataURI);
        }
        emit ModelPerformanceReported(_modelId, _performanceScore, _newMetadataURI);
    }

    /**
     * @dev Links an additional dataset's IPFS hash to an existing AI model.
     * This function could be proposed via governance or performed by a designated role.
     * For simplicity, let's allow curators to propose this.
     * @param _modelId The ID of the AI model.
     * @param _datasetIPFSHash The IPFS hash of the additional dataset.
     */
    function linkAdditionalDatasetToModel(uint256 _modelId, string memory _datasetIPFSHash) external whenNotPaused {
        if (!isCurator(msg.sender)) {
            revert NotCurator();
        }
        AIModel storage model = aiModels[_modelId];
        if (model.modelId == 0 || model.retired) {
            revert ModelNotFound();
        }
        // This could also be a governance proposal for more decentralization
        model.linkedDatasetIPFSHashes.push(_datasetIPFSHash);
    }

    /**
     * @dev Retrieves all details about a specific AIModelNFT.
     * @param _modelId The ID of the AI model.
     * @return AIModel struct containing all details.
     */
    function getAIModelDetails(uint256 _modelId) external view returns (AIModel memory) {
        if (aiModels[_modelId].modelId == 0) {
            revert ModelNotFound();
        }
        return aiModels[_modelId];
    }

    /**
     * @dev Returns the current metadata URI for a specific AIModelNFT.
     * @param _modelId The ID of the AI model.
     * @return The metadata URI.
     */
    function getAIModelNFTURI(uint256 _modelId) external view returns (string memory) {
        return tokenURI(_modelId);
    }


    // --- IV. DAO Governance & Voting ---

    /**
     * @dev Allows a curator to vote on an active proposal.
     * Implements a simplified quadratic voting mechanism: vote power = sqrt(stakedAmount / quadraticVoteWeightDivisor).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) {
            revert ProposalNotFound();
        }
        if (_hasVoted[msg.sender][_proposalId]) {
            revert ProposalAlreadyVoted();
        }
        if (block.number > p.endBlock) {
            revert ProposalVotingPeriodEnded();
        }
        if (!isCurator(msg.sender)) {
            revert NotCurator();
        }

        uint256 stakedAmount = _stakedBalances[msg.sender];
        uint256 votePower = getVotePower(msg.sender);

        if (_support) {
            p.forVotes = p.forVotes.add(votePower);
        } else {
            p.againstVotes = p.againstVotes.add(votePower);
        }

        _hasVoted[msg.sender][_proposalId] = true;
        // Automatically set to active if it's pending
        if (p.state == ProposalState.Pending) {
            p.state = ProposalState.Active;
        }

        emit VoteCast(_proposalId, msg.sender, _support, votePower);
    }

    /**
     * @dev Executes a successfully passed proposal.
     * Checks if quorum is met and 'for' votes exceed 'against' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage p = proposals[_proposalId];
        if (p.id == 0) {
            revert ProposalNotFound();
        }
        if (block.number <= p.endBlock) {
            revert ProposalVotingPeriodEnded();
        }
        if (p.state == ProposalState.Executed) {
            revert ProposalAlreadyExecuted();
        }

        uint256 totalVotes = p.forVotes.add(p.againstVotes);
        uint256 totalStakedForQuorum = ERC20.totalSupply(); // Total supply as proxy for total potential staked for quorum check
        uint256 quorumThreshold = totalStakedForQuorum.mul(quorumPercentage).div(100);

        // Check for quorum and majority
        if (totalVotes < quorumThreshold || p.forVotes <= p.againstVotes) {
            p.state = ProposalState.Failed;
            revert ProposalNotExecutable();
        }

        // --- Execute Proposal Logic ---
        // For new model proposals: mint a new AIModelNFT
        if (p.targetModelId == 0 && bytes(p.newModelIPFSHash).length > 0) { // It's a new model proposal
            _aiModelTokenIds.increment();
            uint256 newModelId = _aiModelTokenIds.current();

            _safeMint(p.proposer, newModelId, p.newInitialMetadataURI); // Mint NFT to proposer or a DAO treasury
            _setTokenURI(newModelId, p.newInitialMetadataURI); // Set initial URI

            aiModels[newModelId] = AIModel({
                modelId: newModelId,
                name: p.newModelName,
                ipfsHash: p.newModelIPFSHash,
                datasetIPFSHash: p.newDatasetIPFSHash,
                accessFeeDAICAMS: p.newAccessFeeDAICAMS,
                proposer: p.proposer,
                creationTimestamp: block.timestamp,
                linkedDatasetIPFSHashes: new string[](0), // Initialize empty
                currentPerformanceScore: 0, // Initial score
                retired: false
            });

            emit AIModelNFTMinted(newModelId, p.proposer, p.newModelName, p.newModelIPFSHash);
        } else if (p.targetModelId != 0 && bytes(p.callData).length > 0) {
            // For proposals targeting existing models, execute the encoded callData
            (bool success, ) = address(this).call(p.callData);
            require(success, "Proposal execution failed");
        }
        // else: other types of proposals (e.g., changing parameters, not covered by explicit callData here)

        p.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves comprehensive details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing all details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        if (proposals[_proposalId].id == 0) {
            revert ProposalNotFound();
        }
        return proposals[_proposalId];
    }

    /**
     * @dev Calculates a user's current voting power based on their staked tokens,
     * using a simplified quadratic voting mechanism.
     * @param _voter The address of the voter.
     * @return The calculated voting power.
     */
    function getVotePower(address _voter) public view returns (uint256) {
        uint256 staked = _stakedBalances[_voter];
        if (staked == 0) {
            return 0;
        }
        // Simplified quadratic voting: sqrt(staked amount / divisor)
        // This gives less power to large stakers proportionally
        return sqrt(staked.div(quadraticVoteWeightDivisor));
    }

    // Simple square root function for quadratic voting
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // --- V. Curator & Reputation System ---

    /**
     * @dev Returns the reputation score of a curator.
     * @param _curator The address of the curator.
     * @return The reputation score.
     */
    function getCuratorReputation(address _curator) external view returns (int256) {
        return curatorReputation[_curator];
    }

    /**
     * @dev Internal function to adjust a curator's reputation score.
     * This would typically be called after successful/failed proposals or challenges.
     * @param _curator The address of the curator.
     * @param _delta The amount to adjust the reputation by (can be negative).
     */
    function _adjustCuratorReputation(address _curator, int256 _delta) internal {
        // Prevent overflow/underflow if reputation goes too high/low, can add caps.
        curatorReputation[_curator] = curatorReputation[_curator] + _delta;
    }

    /**
     * @dev Checks if an address is currently a curator (has staked at least `minCuratorStake`).
     * @param _account The address to check.
     * @return True if the account is a curator, false otherwise.
     */
    function isCurator(address _account) public view returns (bool) {
        return _stakedBalances[_account] >= minCuratorStake;
    }

    // --- VI. Access Control & Monetization ---

    /**
     * @dev Allows a user to subscribe to a tiered access level for a specified duration.
     * @param _tierId The ID of the access tier.
     * @param _durationInDays The duration of the subscription in days.
     * (Fee calculation would be based on tierId, hardcoded here for simplicity)
     */
    function subscribeToTieredAccess(uint256 _tierId, uint256 _durationInDays) external whenNotPaused nonReentrant {
        uint256 fee = 100 * (10 ** decimals()); // Example: 100 DAICAMSTokens per tier per duration
        if (_tierId == 2) fee = 200 * (10 ** decimals()); // Tier 2 is more expensive

        _transfer(msg.sender, address(this), fee); // Pay fee to contract

        uint256 expiry = block.timestamp.add(_durationInDays.mul(1 days));
        userTierAccess[msg.sender][_tierId] = TierAccess({
            lastPaymentTimestamp: block.timestamp,
            durationInDays: _durationInDays,
            tierId: _tierId
        });
        
        emit AccessSubscribed(msg.sender, _tierId, _durationInDays, expiry);
    }

    /**
     * @dev Allows a user to pay a one-time fee to gain access to a specific AI model's details/pointers.
     * @param _modelId The ID of the AI model to access.
     */
    function payForOneTimeModelAccess(uint256 _modelId) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        if (model.modelId == 0 || model.retired) {
            revert ModelNotFound();
        }
        if (model.accessFeeDAICAMS == 0) {
            revert InvalidAmount(); // Model has no access fee
        }

        // Check if user already has active access (e.g., from subscription)
        if (checkUserAccess(msg.sender, _modelId)) {
            revert AccessAlreadyActive();
        }

        _transfer(msg.sender, address(this), model.accessFeeDAICAMS); // Pay fee to contract

        oneTimeModelAccessExpiry[msg.sender][_modelId] = block.timestamp.add(30 days); // 30 days access
        emit OneTimeAccessGranted(msg.sender, _modelId, oneTimeModelAccessExpiry[msg.sender][_modelId]);
    }

    /**
     * @dev Checks if a user has active access to a given AI model.
     * This considers both tiered subscriptions and one-time payments.
     * @param _user The address of the user.
     * @param _modelId The ID of the AI model.
     * @return True if the user has access, false otherwise.
     */
    function checkUserAccess(address _user, uint256 _modelId) public view returns (bool) {
        AIModel storage model = aiModels[_modelId];
        if (model.modelId == 0 || model.retired) {
            return false; // Model not found or retired
        }

        // Check one-time access
        if (oneTimeModelAccessExpiry[_user][_modelId] > block.timestamp) {
            return true;
        }

        // Check tiered access (simplified: tier 1 can access all)
        // In a real system, you'd map models to specific tiers
        TierAccess storage tier1Access = userTierAccess[_user][1]; // Example for Tier 1
        if (tier1Access.lastPaymentTimestamp > 0 && tier1Access.lastPaymentTimestamp.add(tier1Access.durationInDays.mul(1 days)) > block.timestamp) {
            return true;
        }

        return false;
    }

    /**
     * @dev Gets the remaining access duration for a specific tier for a user.
     * @param _user The address of the user.
     * @param _tierId The ID of the access tier.
     * @return The remaining duration in seconds.
     */
    function getTierAccessDuration(address _user, uint256 _tierId) external view returns (uint256) {
        TierAccess storage access = userTierAccess[_user][_tierId];
        if (access.lastPaymentTimestamp == 0) {
            return 0; // Never subscribed
        }
        uint256 expiry = access.lastPaymentTimestamp.add(access.durationInDays.mul(1 days));
        if (expiry > block.timestamp) {
            return expiry.sub(block.timestamp);
        }
        return 0; // Expired
    }

    // --- VII. AI Improvement Bounty System ---

    /**
     * @dev Creates a bounty for improving an existing AI model, funded by DAICAMSTokens.
     * The reward amount is sent to the contract and will be distributed upon bounty resolution.
     * @param _description A description of the bounty challenge.
     * @param _rewardAmountDAICAMS The amount of DAICAMSTokens offered as a reward.
     * @param _deadline The timestamp by which solutions must be submitted.
     * @param _targetModelId The ID of the AI model this bounty aims to improve.
     */
    function createAIImprovementBounty(
        string memory _description,
        uint256 _rewardAmountDAICAMS,
        uint256 _deadline,
        uint256 _targetModelId
    ) external whenNotPaused nonReentrant {
        if (!isCurator(msg.sender)) { // Only curators can create bounties
            revert NotCurator();
        }
        if (_rewardAmountDAICAMS == 0 || _deadline <= block.timestamp) {
            revert InvalidAmount();
        }
        if (aiModels[_targetModelId].modelId == 0) {
            revert ModelNotFound();
        }

        // Transfer bounty reward to the contract
        require(allowance(msg.sender, address(this)) >= _rewardAmountDAICAMS, "Allowance too low for bounty reward");
        _transfer(msg.sender, address(this), _rewardAmountDAICAMS);

        _bountyIds.increment();
        uint256 bountyId = _bountyIds.current();

        bounties[bountyId] = Bounty({
            id: bountyId,
            description: _description,
            rewardAmountDAICAMS: _rewardAmountDAICAMS,
            deadline: _deadline,
            targetModelId: _targetModelId,
            creator: msg.sender,
            solutionHash: "",
            winner: address(0),
            state: BountyState.Active
        });

        emit BountyCreated(bountyId, msg.sender, _rewardAmountDAICAMS, _deadline, _targetModelId);
    }

    /**
     * @dev Allows users to submit a hash representing their off-chain solution to an active bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionHash A hash (e.g., IPFS hash) pointing to the submitted solution.
     */
    function submitBountySolution(uint256 _bountyId, string memory _solutionHash) external whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        if (bounty.id == 0) {
            revert BountyNotFound();
        }
        if (bounty.state != BountyState.Active) {
            revert BountyNotActive();
        }
        if (block.timestamp > bounty.deadline) {
            revert BountyDeadlinePassed();
        }
        // For simplicity, we just store the hash.
        // A more advanced system would involve multiple submissions, peer review, or oracle validation.
        // Here, we can overwrite previous submissions, or make it unique per sender.
        // For now, let's assume multiple submissions are allowed, and a single winner is picked later.
        // This function doesn't store sender specific solution hash to simplify
        // a real implementation would have a mapping for multiple submissions per bounty
        // For this exercise, we just log that a solution was submitted.

        emit BountySolutionSubmitted(_bountyId, msg.sender, _solutionHash);
    }

    /**
     * @dev Resolves a bounty, selecting a winner and distributing the reward.
     * This action would typically be driven by a governance vote or by the bounty creator (if trusted).
     * For this example, let's allow the owner or a curator to propose resolution.
     * A more robust system would involve DAO vote to decide winner.
     * For now, let's assume `owner` is the resolver.
     * @param _bountyId The ID of the bounty to resolve.
     * @param _winnerAddress The address of the winning contributor.
     */
    function resolveBounty(uint256 _bountyId, address _winnerAddress) external onlyOwner whenNotPaused nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        if (bounty.id == 0) {
            revert BountyNotFound();
        }
        if (bounty.state != BountyState.Active) {
            revert BountyNotActive();
        }
        if (bounty.deadline > block.timestamp) { // Deadline must be passed to resolve
            revert BountyDeadlineNotReached();
        }

        bounty.winner = _winnerAddress;
        bounty.state = BountyState.Resolved;
        
        _transfer(address(this), _winnerAddress, bounty.rewardAmountDAICAMS); // Transfer reward

        emit BountyResolved(_bountyId, _winnerAddress, bounty.rewardAmountDAICAMS);
    }
}
```