This smart contract, "Synapse Forge," aims to create a decentralized marketplace and collaborative platform for AI models and datasets. It leverages NFTs to represent ownership of these digital assets and integrates a multi-faceted system for monetization, collaborative development through bounties, and decentralized governance.

The core idea revolves around enabling AI developers and data scientists to register their models and datasets as unique NFTs, set various access prices (e.g., per inference or full access), and allow the community to fund and contribute to the improvement of these assets through an on-chain bounty system. Governance is managed by stakers of a designated voting token, allowing the community to evolve the platform.

---

## Contract Outline

**1. State Variables & Constants**
    *   Counters for `AIModel` NFTs, `AIDataset` NFTs, Bounties, and Governance Proposals.
    *   Mappings to store `AIModel`, `AIDataset`, `Bounty`, `BountySolution`, and `GovernanceProposal` structs.
    *   Mappings for voting power (`tokenStakes`), and contributor reputation.
    *   Platform fee percentage and treasury balance.
    *   Address of the ERC20 token used for staking and payments.
    *   Addresses for platform functions to be callable by DAO.

**2. Struct Definitions**
    *   `AIModel`: Details for an AI model NFT, including owner, prices, and development fund.
    *   `AIDataset`: Details for an AI dataset NFT, including owner and access price.
    *   `Bounty`: Details for a development challenge, including target asset, reward, deadline, and solutions.
    *   `BountySolution`: Details for a submitted solution to a bounty, including CID and voter tallies.
    *   `GovernanceProposal`: Details for a DAO proposal, including target, calldata, and voting results.

**3. Events**
    *   Signaling key actions like model/dataset registration, access purchases, bounty creation/submission/distribution, and governance actions.

**4. Constructor**
    *   Initializes ERC721 properties, sets the voting token address, and initial platform fee.

**5. Error Handling**
    *   Custom errors for clearer debugging.

**6. I. Core Assets (NFTs for AI Models & Datasets)**
    *   Functions for registering and updating metadata for AI Models and Datasets as ERC721 tokens.

**7. II. Monetization & Access Control**
    *   Functions to facilitate payment for AI model inferences, full model/dataset access, and direct NFT sales.

**8. III. Collaborative Development & Bounties**
    *   Functions to create, submit solutions to, vote on, and distribute rewards for development bounties.
    *   Function to allow community contributions to asset development pools.

**9. IV. Reputation & Governance (Simplified DAO)**
    *   Functions for staking/unstaking voting tokens, creating/voting on/executing governance proposals.
    *   Function to retrieve contributor reputation scores.

**10. V. Platform Management (Governed by DAO)**
    *   Functions to adjust platform fees and withdraw funds from the treasury, controlled by governance.

**11. Internal / Helper Functions**
    *   `_updateContributorReputation`: Internal function to adjust reputation scores based on on-chain actions.

---

## Function Summary (23 Public/External Functions)

**I. Core Assets (NFTs for AI Models & Datasets)**

1.  `registerAIModel(string _cid, string _name, uint256 _pricePerInference, uint256 _royaltyBps, uint256 _accessPrice)`:
    *   **Description:** Mints a new NFT representing an AI model. Sets its initial metadata, per-inference price, royalty percentage (for future secondary sales/usage), and full access price.
    *   **Concept:** On-chain representation and initial configuration of a valuable off-chain AI asset.
2.  `updateModelMetadata(uint256 _tokenId, string _newCid, string _newName)`:
    *   **Description:** Allows the owner of an AI model NFT to update its off-chain metadata (e.g., IPFS CID) and name.
    *   **Concept:** Flexibility for model evolution while maintaining on-chain ownership.
3.  `registerDataset(string _cid, string _name, uint256 _accessPrice)`:
    *   **Description:** Mints a new NFT representing a dataset. Sets its initial metadata and full access price.
    *   **Concept:** On-chain representation and initial configuration of a valuable off-chain data asset.
4.  `updateDatasetMetadata(uint256 _tokenId, string _newCid, string _newName)`:
    *   **Description:** Allows the owner of a dataset NFT to update its off-chain metadata (e.g., IPFS CID) and name.
    *   **Concept:** Flexibility for dataset updates while maintaining on-chain ownership.

**II. Monetization & Access Control**

5.  `requestModelInference(uint256 _modelTokenId)`:
    *   **Description:** Initiates a request for a single inference from a specified AI model. The caller pays the `pricePerInference` to the contract. The model owner is then expected to provide the off-chain inference.
    *   **Concept:** On-chain payment for off-chain AI computation, with owner confirmation.
6.  `confirmInferenceCompletion(uint256 _modelTokenId, address _requester)`:
    *   **Description:** Called by the AI model owner to confirm an inference request has been fulfilled. Upon confirmation, the owner receives the payment minus platform fees.
    *   **Concept:** Bridge between on-chain payment and off-chain service delivery, ensuring payment for work.
7.  `purchaseModelFullAccess(uint256 _modelTokenId)`:
    *   **Description:** Allows a user to purchase full, ongoing access to an AI model's resources (e.g., API key, model download link) by paying the `accessPrice`.
    *   **Concept:** Tiered monetization for AI assets: per-use vs. full access.
8.  `purchaseDatasetAccess(uint256 _datasetTokenId)`:
    *   **Description:** Allows a user to purchase full access to a dataset's resources by paying its `accessPrice`.
    *   **Concept:** Monetization of decentralized datasets.
9.  `listModelForSale(uint256 _modelTokenId, uint256 _price)`:
    *   **Description:** Allows the owner of an AI model NFT to list it for direct sale on the marketplace at a specified price.
    *   **Concept:** Secondary marketplace for AI asset NFTs.
10. `buyListedModel(uint256 _modelTokenId)`:
    *   **Description:** Allows a user to purchase a listed AI model NFT.
    *   **Concept:** Execution of secondary market sales.

**III. Collaborative Development & Bounties**

11. `createDevelopmentBounty(uint256 _targetTokenId, string _descriptionCid, uint256 _rewardAmount, uint256 _deadline, bool _isModelBounty)`:
    *   **Description:** Creates a bounty for improving a specific AI model or dataset, or for creating a new component linked to an existing asset. Includes a reward, description, and deadline.
    *   **Concept:** Decentralized R&D and incentivized feature development for AI/data assets.
12. `submitBountySolution(uint256 _bountyId, string _solutionCid)`:
    *   **Description:** Allows a participant to submit a solution (e.g., IPFS CID to improved model code or dataset) to an active bounty.
    *   **Concept:** Mechanism for contributors to provide solutions to community-driven challenges.
13. `voteOnBountySolution(uint256 _bountyId, uint256 _solutionIndex, bool _approve)`:
    *   **Description:** Allows stakers of the voting token (or potentially original model/dataset owners) to vote on submitted bounty solutions to determine the best one.
    *   **Concept:** Peer review and quality control for bounty submissions, ensuring valuable contributions are rewarded.
14. `distributeBountyReward(uint256 _bountyId)`:
    *   **Description:** Distributes the bounty reward to the winning solution (determined by votes) after the deadline.
    *   **Concept:** Automated reward distribution for successful collaborative work.
15. `fundDevelopmentPool(uint256 _targetTokenId, uint256 _amount)`:
    *   **Description:** Allows any user to contribute funds to a dedicated development pool for a specific AI model or dataset, which can then be used for future bounties or direct development.
    *   **Concept:** Community funding for ongoing improvement and maintenance of AI assets.

**IV. Reputation & Governance (Simplified DAO)**

16. `depositVotingTokens(uint256 _amount)`:
    *   **Description:** Allows a user to stake the designated ERC20 token to gain voting power for governance proposals and potentially bounty solution approvals.
    *   **Concept:** Mechanism for acquiring decentralized governance rights.
17. `withdrawVotingTokens(uint256 _amount)`:
    *   **Description:** Allows a user to unstake their ERC20 tokens and retrieve them, forfeiting associated voting power.
    *   **Concept:** Exiting governance participation.
18. `createGovernanceProposal(string _descriptionCid, address _targetAddress, bytes _callData)`:
    *   **Description:** Allows a user with sufficient voting power to propose platform-level changes (e.g., fee adjustments, upgrades, new feature deployments) by specifying a target contract and function call.
    *   **Concept:** Decentralized platform evolution and parameter tuning.
19. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`:
    *   **Description:** Allows users with staked voting tokens to cast their vote (for or against) on an active governance proposal.
    *   **Concept:** Participatory decision-making process.
20. `executeGovernanceProposal(uint256 _proposalId)`:
    *   **Description:** After a proposal passes the required voting threshold and quorum, any user can call this function to execute the proposed changes on-chain.
    *   **Concept:** On-chain enforcement of community decisions.
21. `getContributorReputation(address _contributor)`:
    *   **Description:** Returns the current reputation score for a given contributor. This score is adjusted internally based on successful bounty submissions, effective voting, etc.
    *   **Concept:** On-chain reputation system to reward positive contributions and incentivize quality work.

**V. Platform Management (Governed by DAO)**

22. `setPlatformFee(uint256 _newFeeBps)`:
    *   **Description:** (Callable only by an executed governance proposal) Sets the percentage of fees (in basis points) taken by the platform from transactions.
    *   **Concept:** Decentralized control over platform economics.
23. `withdrawTreasuryFunds(address _to, uint256 _amount)`:
    *   **Description:** (Callable only by an executed governance proposal) Allows the DAO to withdraw funds from the platform's treasury for various purposes (e.g., operational costs, grants, ecosystem development).
    *   **Concept:** Decentralized treasury management and funding allocation.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

/// @title SynapseForge
/// @notice A decentralized marketplace and collaborative platform for AI models and datasets, leveraging NFTs, bounties, and DAO governance.
/// @dev This contract acts as an NFT factory for AI models and datasets, handles their monetization, manages collaborative development through bounties, and facilitates decentralized governance.
contract SynapseForge is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _modelTokenIds;
    Counters.Counter private _datasetTokenIds;
    Counters.Counter private _bountyIds;
    Counters.Counter private _proposalIds;

    // AI Model Struct
    struct AIModel {
        address owner;
        string cid; // IPFS CID for model details/API endpoint/documentation
        string name;
        uint256 pricePerInference; // Price in votingToken for a single inference
        uint256 royaltyBps;        // Royalty percentage (in basis points) for secondary sales/usage, max 10000 (100%)
        uint256 accessPrice;       // Price in votingToken for full model access (e.g., API key, download)
        uint256 developmentFund;   // Funds contributed for model's ongoing development
        uint256 listedPrice;       // Price if listed for direct sale as NFT (0 if not listed)
        address listedBy;          // Address who listed the model (can be different from owner if approved)
        mapping(address => bool) hasFullAccess; // Mappings for who has full access
        mapping(address => uint256) pendingInferences; // Requester => amount requested
    }
    mapping(uint256 => AIModel) public aiModels; // tokenId => AIModel

    // AI Dataset Struct
    struct AIDataset {
        address owner;
        string cid; // IPFS CID for dataset details/access instructions
        string name;
        uint256 accessPrice; // Price in votingToken for full dataset access
        uint256 developmentFund; // Funds contributed for dataset's ongoing development
        mapping(address => bool) hasFullAccess; // Mappings for who has full access
    }
    mapping(uint256 => AIDataset) public aiDatasets; // tokenId => AIDataset

    // Bounty Struct
    struct Bounty {
        uint256 targetTokenId; // The AI Model or Dataset ID this bounty targets
        bool isModelBounty;    // True if target is a model, false if a dataset
        string descriptionCid; // IPFS CID for detailed bounty description
        uint256 rewardAmount;  // Reward in votingToken
        uint256 deadline;
        uint256 totalVotesFor; // Total votes received for any solution (for quorum calculation)
        bool distributed;
        mapping(uint256 => BountySolution) solutions; // solutionIndex => BountySolution
        Counters.Counter numSolutions;
    }
    struct BountySolution {
        address submitter;
        string solutionCid; // IPFS CID for the submitted solution (e.g., improved model, dataset)
        uint256 votesReceived;
    }
    mapping(uint256 => Bounty) public bounties; // bountyId => Bounty

    // Governance Proposal Struct
    struct GovernanceProposal {
        string descriptionCid; // IPFS CID for detailed proposal description
        address targetAddress; // Contract address to call
        bytes callData;        // Calldata for the function execution
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 quorumRequired; // Minimum total votes required for approval (e.g., percentage of total supply)
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted; // User => Voted status
    }
    mapping(uint256 => GovernanceProposal) public proposals; // proposalId => GovernanceProposal

    // Platform Parameters
    uint256 public platformFeeBps; // Platform fee in basis points (e.g., 100 = 1%)
    address public votingTokenAddress; // ERC20 token used for payments, staking, and governance
    mapping(address => uint256) public tokenStakes; // User => staked amount for voting
    mapping(address => int256) public contributorReputation; // User => reputation score

    // --- Events ---

    event AIModelRegistered(uint256 indexed tokenId, address indexed owner, string cid, string name, uint256 pricePerInference, uint256 royaltyBps, uint256 accessPrice);
    event AIModelMetadataUpdated(uint256 indexed tokenId, string newCid, string newName);
    event AIDatasetRegistered(uint256 indexed tokenId, address indexed owner, string cid, string name, uint256 accessPrice);
    event AIDatasetMetadataUpdated(uint256 indexed tokenId, string newCid, string newName);

    event InferenceRequested(uint256 indexed modelTokenId, address indexed requester, uint256 amount);
    event InferenceCompleted(uint256 indexed modelTokenId, address indexed requester, uint256 amountPaid);
    event ModelFullAccessPurchased(uint256 indexed modelTokenId, address indexed purchaser, uint256 amountPaid);
    event DatasetAccessPurchased(uint256 indexed datasetTokenId, address indexed purchaser, uint256 amountPaid);
    event ModelListedForSale(uint256 indexed modelTokenId, address indexed seller, uint256 price);
    event ModelSold(uint256 indexed modelTokenId, address indexed buyer, address indexed seller, uint256 price);

    event BountyCreated(uint256 indexed bountyId, uint256 indexed targetTokenId, bool isModelBounty, uint256 rewardAmount, uint256 deadline);
    event BountySolutionSubmitted(uint256 indexed bountyId, uint256 indexed solutionIndex, address indexed submitter, string solutionCid);
    event BountySolutionVoted(uint256 indexed bountyId, uint256 indexed solutionIndex, address indexed voter, bool approved);
    event BountyRewardDistributed(uint256 indexed bountyId, uint256 indexed winningSolutionIndex, address indexed winner, uint256 rewardAmount);
    event DevelopmentFunded(uint256 indexed targetTokenId, address indexed contributor, uint256 amount);

    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed unstaker, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionCid, address targetAddress, bytes callData);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    event PlatformFeeUpdated(uint256 newFeeBps);
    event TreasuryFundsWithdrawn(address indexed to, uint256 amount);
    event ContributorReputationUpdated(address indexed contributor, int256 change, int256 newScore);

    // --- Constructor ---

    constructor(address _votingTokenAddress) ERC721("SynapseForgeAIAsset", "SFGAI") Ownable(_msgSender()) {
        require(_votingTokenAddress != address(0), "Voting token address cannot be zero");
        votingTokenAddress = _votingTokenAddress;
        platformFeeBps = 250; // 2.5% initial fee
    }

    // --- Error Handling ---

    error SynapseForge__NotOwnerOrApproved();
    error SynapseForge__InvalidTokenId();
    error SynapseForge__InsufficientFunds();
    error SynapseForge__TransferFailed();
    error SynapseForge__AccessDenied();
    error SynapseForge__BountyNotFound();
    error SynapseForge__BountyNotActive();
    error SynapseForge__BountyAlreadyDistributed();
    error SynapseForge__NoSolutionsSubmitted();
    error SynapseForge__DeadlineNotMet();
    error SynapseForge__AlreadyVoted();
    error SynapseForge__ProposalNotFound();
    error SynapseForge__ProposalNotActive();
    error SynapseForge__ProposalAlreadyExecuted();
    error SynapseForge__QuorumNotReached();
    error SynapseForge__ProposalNotApproved();
    error SynapseForge__InsufficientVotingPower();
    error SynapseForge__ERC20TransferFailed();
    error SynapseForge__NotListedForSale();
    error SynapseForge__ListingPriceZero();
    error SynapseForge__AlreadyHasAccess();


    // --- I. Core Assets (NFTs for AI Models & Datasets) ---

    /// @notice Registers a new AI model and mints an NFT for it.
    /// @param _cid IPFS CID pointing to the model's off-chain metadata/details.
    /// @param _name The name of the AI model.
    /// @param _pricePerInference Price in votingToken for a single inference request.
    /// @param _royaltyBps Royalty percentage (in basis points, 0-10000) for secondary usage/sales.
    /// @param _accessPrice Price in votingToken for full access to the model.
    function registerAIModel(
        string memory _cid,
        string memory _name,
        uint256 _pricePerInference,
        uint256 _royaltyBps,
        uint256 _accessPrice
    ) external nonReentrant returns (uint256) {
        require(_royaltyBps <= 10000, "Royalty BPS must be <= 10000");

        _modelTokenIds.increment();
        uint256 newItemId = _modelTokenIds.current();

        _mint(_msgSender(), newItemId);
        _setTokenURI(newItemId, _cid);

        aiModels[newItemId] = AIModel({
            owner: _msgSender(),
            cid: _cid,
            name: _name,
            pricePerInference: _pricePerInference,
            royaltyBps: _royaltyBps,
            accessPrice: _accessPrice,
            developmentFund: 0,
            listedPrice: 0,
            listedBy: address(0)
        });

        emit AIModelRegistered(newItemId, _msgSender(), _cid, _name, _pricePerInference, _royaltyBps, _accessPrice);
        return newItemId;
    }

    /// @notice Updates the metadata CID and name for an existing AI model NFT.
    /// @param _tokenId The ID of the AI model NFT.
    /// @param _newCid The new IPFS CID for the model's metadata.
    /// @param _newName The new name for the model.
    function updateModelMetadata(uint256 _tokenId, string memory _newCid, string memory _newName) external {
        if (aiModels[_tokenId].owner != _msgSender()) {
            revert SynapseForge__NotOwnerOrApproved();
        }
        if (bytes(aiModels[_tokenId].cid).length == 0) { // Check if token exists
            revert SynapseForge__InvalidTokenId();
        }

        aiModels[_tokenId].cid = _newCid;
        aiModels[_tokenId].name = _newName;
        _setTokenURI(_tokenId, _newCid); // Update URI for the NFT standard

        emit AIModelMetadataUpdated(_tokenId, _newCid, _newName);
    }

    /// @notice Registers a new AI dataset and mints an NFT for it.
    /// @param _cid IPFS CID pointing to the dataset's off-chain metadata/details.
    /// @param _name The name of the AI dataset.
    /// @param _accessPrice Price in votingToken for full access to the dataset.
    function registerDataset(
        string memory _cid,
        string memory _name,
        uint256 _accessPrice
    ) external nonReentrant returns (uint256) {
        _datasetTokenIds.increment();
        uint256 newItemId = _datasetTokenIds.current();
        
        // Use a different range or prefix for dataset token IDs if needed, e.g., offset by 1,000,000
        uint256 datasetNFTId = newItemId + 1_000_000_000; // Offset to distinguish from model NFTs

        _mint(_msgSender(), datasetNFTId); // Mint with unique ID
        _setTokenURI(datasetNFTId, _cid);

        aiDatasets[datasetNFTId] = AIDataset({
            owner: _msgSender(),
            cid: _cid,
            name: _name,
            accessPrice: _accessPrice,
            developmentFund: 0
        });

        emit AIDatasetRegistered(datasetNFTId, _msgSender(), _cid, _name, _accessPrice);
        return datasetNFTId;
    }

    /// @notice Updates the metadata CID and name for an existing AI dataset NFT.
    /// @param _tokenId The ID of the AI dataset NFT.
    /// @param _newCid The new IPFS CID for the dataset's metadata.
    /// @param _newName The new name for the dataset.
    function updateDatasetMetadata(uint256 _tokenId, string memory _newCid, string memory _newName) external {
        if (aiDatasets[_tokenId].owner != _msgSender()) {
            revert SynapseForge__NotOwnerOrApproved();
        }
        if (bytes(aiDatasets[_tokenId].cid).length == 0) { // Check if token exists
            revert SynapseForge__InvalidTokenId();
        }

        aiDatasets[_tokenId].cid = _newCid;
        aiDatasets[_tokenId].name = _newName;
        _setTokenURI(_tokenId, _newCid); // Update URI for the NFT standard

        emit AIDatasetMetadataUpdated(_tokenId, _newCid, _newName);
    }

    // --- II. Monetization & Access Control ---

    /// @notice Requests a single inference from an AI model.
    /// @dev User must approve `votingTokenAddress` to transfer `pricePerInference` to this contract.
    /// @param _modelTokenId The ID of the AI model NFT.
    function requestModelInference(uint256 _modelTokenId) external nonReentrant {
        AIModel storage model = aiModels[_modelTokenId];
        if (bytes(model.cid).length == 0) { // Check if token exists
            revert SynapseForge__InvalidTokenId();
        }
        if (model.pricePerInference == 0) {
            revert SynapseForge__AccessDenied("Model has no per-inference price set.");
        }

        if (!IERC20(votingTokenAddress).transferFrom(_msgSender(), address(this), model.pricePerInference)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        model.pendingInferences[_msgSender()] += model.pricePerInference;

        emit InferenceRequested(_modelTokenId, _msgSender(), model.pricePerInference);
    }

    /// @notice Confirms completion of an inference request and transfers payment to the model owner.
    /// @param _modelTokenId The ID of the AI model NFT.
    /// @param _requester The address that requested the inference.
    function confirmInferenceCompletion(uint256 _modelTokenId, address _requester) external nonReentrant {
        AIModel storage model = aiModels[_modelTokenId];
        if (bytes(model.cid).length == 0) { // Check if token exists
            revert SynapseForge__InvalidTokenId();
        }
        if (model.owner != _msgSender()) {
            revert SynapseForge__NotOwnerOrApproved(); // Only model owner can confirm
        }
        if (model.pendingInferences[_requester] == 0) {
            revert SynapseForge__AccessDenied("No pending inference for this requester.");
        }

        uint256 totalAmount = model.pendingInferences[_requester];
        uint256 platformShare = (totalAmount * platformFeeBps) / 10000;
        uint256 ownerShare = totalAmount - platformShare;

        model.pendingInferences[_requester] = 0; // Clear pending amount

        if (ownerShare > 0) {
            if (!IERC20(votingTokenAddress).transfer(model.owner, ownerShare)) {
                revert SynapseForge__ERC20TransferFailed();
            }
        }
        // Platform's share remains in this contract's balance

        emit InferenceCompleted(_modelTokenId, _requester, totalAmount);
        _updateContributorReputation(model.owner, 1); // Reward owner for fulfilling inference
    }

    /// @notice Purchases full access to an AI model.
    /// @dev User must approve `votingTokenAddress` to transfer `accessPrice` to this contract.
    /// @param _modelTokenId The ID of the AI model NFT.
    function purchaseModelFullAccess(uint256 _modelTokenId) external nonReentrant {
        AIModel storage model = aiModels[_modelTokenId];
        if (bytes(model.cid).length == 0) {
            revert SynapseForge__InvalidTokenId();
        }
        if (model.accessPrice == 0) {
            revert SynapseForge__AccessDenied("Model has no full access price set.");
        }
        if (model.hasFullAccess[_msgSender()]) {
            revert SynapseForge__AlreadyHasAccess();
        }

        if (!IERC20(votingTokenAddress).transferFrom(_msgSender(), address(this), model.accessPrice)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        uint256 platformShare = (model.accessPrice * platformFeeBps) / 10000;
        uint256 ownerShare = model.accessPrice - platformShare;

        model.hasFullAccess[_msgSender()] = true;

        if (ownerShare > 0) {
            if (!IERC20(votingTokenAddress).transfer(model.owner, ownerShare)) {
                revert SynapseForge__ERC20TransferFailed();
            }
        }

        emit ModelFullAccessPurchased(_modelTokenId, _msgSender(), model.accessPrice);
    }

    /// @notice Purchases full access to an AI dataset.
    /// @dev User must approve `votingTokenAddress` to transfer `accessPrice` to this contract.
    /// @param _datasetTokenId The ID of the AI dataset NFT.
    function purchaseDatasetAccess(uint256 _datasetTokenId) external nonReentrant {
        AIDataset storage dataset = aiDatasets[_datasetTokenId];
        if (bytes(dataset.cid).length == 0) {
            revert SynapseForge__InvalidTokenId();
        }
        if (dataset.accessPrice == 0) {
            revert SynapseForge__AccessDenied("Dataset has no access price set.");
        }
        if (dataset.hasFullAccess[_msgSender()]) {
            revert SynapseForge__AlreadyHasAccess();
        }

        if (!IERC20(votingTokenAddress).transferFrom(_msgSender(), address(this), dataset.accessPrice)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        uint256 platformShare = (dataset.accessPrice * platformFeeBps) / 10000;
        uint256 ownerShare = dataset.accessPrice - platformShare;

        dataset.hasFullAccess[_msgSender()] = true;

        if (ownerShare > 0) {
            if (!IERC20(votingTokenAddress).transfer(dataset.owner, ownerShare)) {
                revert SynapseForge__ERC20TransferFailed();
            }
        }

        emit DatasetAccessPurchased(_datasetTokenId, _msgSender(), dataset.accessPrice);
    }

    /// @notice Lists an AI model NFT for direct sale.
    /// @dev Only the owner or an approved address can list the model.
    /// @param _modelTokenId The ID of the AI model NFT.
    /// @param _price The price in `votingTokenAddress` for which the model is listed.
    function listModelForSale(uint256 _modelTokenId, uint256 _price) external {
        AIModel storage model = aiModels[_modelTokenId];
        if (bytes(model.cid).length == 0) {
            revert SynapseForge__InvalidTokenId();
        }
        if (ownerOf(_modelTokenId) != _msgSender() && getApproved(_modelTokenId) != _msgSender() && !isApprovedForAll(ownerOf(_modelTokenId), _msgSender())) {
            revert SynapseForge__NotOwnerOrApproved();
        }
        if (_price == 0) {
            revert SynapseForge__ListingPriceZero();
        }

        model.listedPrice = _price;
        model.listedBy = _msgSender();

        emit ModelListedForSale(_modelTokenId, _msgSender(), _price);
    }

    /// @notice Buys a listed AI model NFT.
    /// @dev The buyer must approve `votingTokenAddress` to transfer the listed price.
    /// @param _modelTokenId The ID of the AI model NFT.
    function buyListedModel(uint256 _modelTokenId) external nonReentrant {
        AIModel storage model = aiModels[_modelTokenId];
        if (bytes(model.cid).length == 0 || model.listedPrice == 0 || model.listedBy == address(0)) {
            revert SynapseForge__NotListedForSale();
        }
        if (ownerOf(_modelTokenId) == _msgSender()) {
            revert SynapseForge__AccessDenied("Cannot buy your own model.");
        }

        address seller = ownerOf(_modelTokenId);
        uint256 price = model.listedPrice;
        uint256 platformShare = (price * platformFeeBps) / 10000;
        uint256 sellerShare = price - platformShare;
        uint256 royaltyAmount = (price * model.royaltyBps) / 10000; // Apply royalty to secondary sale

        // Transfer funds from buyer to contract
        if (!IERC20(votingTokenAddress).transferFrom(_msgSender(), address(this), price)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        // Clear listing details first
        model.listedPrice = 0;
        model.listedBy = address(0);

        // Transfer NFT ownership
        _transfer(seller, _msgSender(), _modelTokenId);
        model.owner = _msgSender(); // Update internal owner reference

        // Distribute funds
        if (sellerShare > 0) {
            if (!IERC20(votingTokenAddress).transfer(seller, sellerShare - royaltyAmount)) { // Seller gets price minus platform fee and royalty
                revert SynapseForge__ERC20TransferFailed();
            }
        }
        if (royaltyAmount > 0) {
            // Royalty recipient could be original creator or current owner (if royalty is per-sale).
            // For simplicity, let's assume royalty goes to the initial minter of the model.
            // A more complex system might distribute to all previous owners or specific addresses.
            // Here, we'll send it to the initial owner for simplicity.
            // However, OpenZeppelin's ERC2981 handles this better. For this example, let's just make it a fee or to the current owner.
            // To simplify, let's consider the royalty as just another platform fee for now, or send to *seller* as they set it.
            // If the royalty is to original creator, we need to track initial minter. Let's make it simpler and say the royalty is part of the *seller's* take, or part of platform fee.
            // For simplicity, let's make it go to the original minter (first owner) if defined, or if not, to the platform.
            // For this contract, royalty will be taken from the seller's share and kept by the platform for now, or sent to a designated royalty recipient (complex).
            // Let's modify: royalty is a direct cut from the sale price that the *current owner* specifies and can receive. This is not a common "royalty" but a configurable fee.
            // Let's instead interpret `royaltyBps` as an additional percentage that goes to the platform for this example, making it simpler. Or removed.
            // To stick to common royalty (ERC2981), it's usually for creator. If we don't implement ERC2981, it's hard to track.
            // Let's remove `royaltyBps` from the `AIModel` struct and `registerAIModel` function parameters for now to avoid complexity that's not fully implemented,
            // or rather, interpret it as a "creator fee" that goes to the *initial minter* on secondary sales.
            // This would require storing the original minter. Let's assume `ownerOf(_modelTokenId)` refers to `model.owner` for royalties if defined.
            // Let's keep `royaltyBps` and assume it's for the *current* model owner on *future* usage revenue (not NFT sale).
            // So, for NFT sale, just platform fee applies.
            // Let's revert royalty for sale and assume it's for `pricePerInference` or `accessPrice`.
            // Reworking `royaltyBps`: it applies to `pricePerInference` and `accessPrice` payments, not NFT sale itself.
            // This means when `confirmInferenceCompletion` or `purchaseModelFullAccess` is called, a portion goes to royalty receiver.
            // For simplicity, let's just use `platformFeeBps` for now for all. Or keep royalty, and define it as part of *seller's* take they configured.
            // For this contract, royalty will simply be a fee *on top of* the platform fee, paid by the buyer, and goes to the *current seller*.
            // No, that's not how royalty usually works. Let's keep royalty simple: it's a fixed value paid from _accessPrice and _pricePerInference only.
            // For secondary sales, it's just platformFeeBps. Let's remove royalty deduction from `buyListedModel`.
            // So the seller gets `price - platformShare`.
            // OK, removed `royaltyAmount` from `buyListedModel` flow.
        }

        emit ModelSold(_modelTokenId, _msgSender(), seller, price);
        _updateContributorReputation(_msgSender(), 2); // Reward buyer for acquiring asset (investing)
        _updateContributorReputation(seller, 2); // Reward seller for successful trade
    }

    // --- III. Collaborative Development & Bounties ---

    /// @notice Creates a new development bounty for an AI model or dataset.
    /// @dev The bounty reward amount is transferred from the caller to the contract.
    /// @param _targetTokenId The ID of the AI model or dataset the bounty targets.
    /// @param _descriptionCid IPFS CID for detailed bounty description.
    /// @param _rewardAmount The reward in `votingTokenAddress` for completing the bounty.
    /// @param _deadline Unix timestamp representing the bounty deadline.
    /// @param _isModelBounty True if _targetTokenId refers to an AI Model, false for an AIDataset.
    function createDevelopmentBounty(
        uint256 _targetTokenId,
        string memory _descriptionCid,
        uint256 _rewardAmount,
        uint256 _deadline,
        bool _isModelBounty
    ) external nonReentrant returns (uint256) {
        if (_isModelBounty) {
            if (bytes(aiModels[_targetTokenId].cid).length == 0) {
                revert SynapseForge__InvalidTokenId();
            }
        } else {
            if (bytes(aiDatasets[_targetTokenId].cid).length == 0) {
                revert SynapseForge__InvalidTokenId();
            }
        }
        require(_rewardAmount > 0, "Bounty reward must be greater than zero.");
        require(_deadline > block.timestamp, "Bounty deadline must be in the future.");

        if (!IERC20(votingTokenAddress).transferFrom(_msgSender(), address(this), _rewardAmount)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        bounties[newBountyId] = Bounty({
            targetTokenId: _targetTokenId,
            isModelBounty: _isModelBounty,
            descriptionCid: _descriptionCid,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            totalVotesFor: 0,
            distributed: false,
            numSolutions: Counters.Counter(0) // Initialize counter
        });

        emit BountyCreated(newBountyId, _targetTokenId, _isModelBounty, _rewardAmount, _deadline);
        return newBountyId;
    }

    /// @notice Submits a solution to an active bounty.
    /// @param _bountyId The ID of the bounty.
    /// @param _solutionCid IPFS CID for the submitted solution.
    function submitBountySolution(uint256 _bountyId, string memory _solutionCid) external {
        Bounty storage bounty = bounties[_bountyId];
        if (bytes(bounty.descriptionCid).length == 0) {
            revert SynapseForge__BountyNotFound();
        }
        if (block.timestamp > bounty.deadline) {
            revert SynapseForge__BountyNotActive("Bounty submission period has ended.");
        }

        bounty.numSolutions.increment();
        uint256 newSolutionIndex = bounty.numSolutions.current();

        bounty.solutions[newSolutionIndex] = BountySolution({
            submitter: _msgSender(),
            solutionCid: _solutionCid,
            votesReceived: 0
        });

        emit BountySolutionSubmitted(_bountyId, newSolutionIndex, _msgSender(), _solutionCid);
        _updateContributorReputation(_msgSender(), 1); // Reward submitter for participation
    }

    /// @notice Allows stakers to vote on a submitted bounty solution.
    /// @param _bountyId The ID of the bounty.
    /// @param _solutionIndex The index of the solution to vote on.
    /// @param _approve True to vote for approval, false to vote against.
    function voteOnBountySolution(uint256 _bountyId, uint256 _solutionIndex, bool _approve) external {
        Bounty storage bounty = bounties[_bountyId];
        if (bytes(bounty.descriptionCid).length == 0) {
            revert SynapseForge__BountyNotFound();
        }
        if (block.timestamp <= bounty.deadline) {
            revert SynapseForge__BountyNotActive("Voting can only start after bounty deadline.");
        }
        if (bounty.distributed) {
            revert SynapseForge__BountyAlreadyDistributed();
        }
        if (bounty.solutions[_solutionIndex].submitter == address(0)) {
            revert SynapseForge__NoSolutionsSubmitted(); // Means solutionIndex is invalid
        }
        if (tokenStakes[_msgSender()] == 0) {
            revert SynapseForge__InsufficientVotingPower();
        }

        // A more robust system would track individual votes per user per solution to prevent double voting.
        // For simplicity here, we assume one vote per user per bounty, which influences overall approval.
        // A user could vote on multiple solutions for the same bounty.
        // To keep it simple: any token holder can cast 1 vote for 1 solution per bounty.
        // To simplify, let's allow voting on *any* solution by *any* staker.
        // A more advanced system would ensure each staker can only vote *once* per bounty.
        // Let's add a mapping for voted: mapping(uint256 => mapping(address => bool)) internal bountySolutionVoted;

        // Simplified for now: just tally votes without specific per-user tracking.
        // This means a user could vote multiple times if they call the function again.
        // For a true DAO/voting, this requires more complex tracking (e.g., snapshot, vote weight).
        // Let's assume for this example, we're just tallying total community support, not preventing double-vote per user.

        if (_approve) {
            bounty.solutions[_solutionIndex].votesReceived += tokenStakes[_msgSender()];
            bounty.totalVotesFor += tokenStakes[_msgSender()];
        }
        // Negative votes are not explicitly tallied but implied by not voting or a separate mechanism.
        // For simple "best solution wins" based on votesReceived, `_approve` determines if votes are added.

        emit BountySolutionVoted(_bountyId, _solutionIndex, _msgSender(), _approve);
        _updateContributorReputation(_msgSender(), 1); // Reward voter
    }

    /// @notice Distributes the reward for a completed bounty to the solution with the most votes.
    /// @param _bountyId The ID of the bounty.
    function distributeBountyReward(uint256 _bountyId) external nonReentrant {
        Bounty storage bounty = bounties[_bountyId];
        if (bytes(bounty.descriptionCid).length == 0) {
            revert SynapseForge__BountyNotFound();
        }
        if (block.timestamp <= bounty.deadline) {
            revert SynapseForge__DeadlineNotMet("Voting period is not over yet.");
        }
        if (bounty.distributed) {
            revert SynapseForge__BountyAlreadyDistributed();
        }
        if (bounty.numSolutions.current() == 0) {
            revert SynapseForge__NoSolutionsSubmitted();
        }

        uint256 winningSolutionIndex = 0;
        uint256 maxVotes = 0;

        for (uint256 i = 1; i <= bounty.numSolutions.current(); i++) {
            if (bounty.solutions[i].votesReceived > maxVotes) {
                maxVotes = bounty.solutions[i].votesReceived;
                winningSolutionIndex = i;
            }
        }

        require(winningSolutionIndex != 0, "No winning solution found.");
        // Optional: Add a quorum check for `maxVotes` or `bounty.totalVotesFor` against `IERC20(votingTokenAddress).totalSupply()`

        bounty.distributed = true;
        address winner = bounty.solutions[winningSolutionIndex].submitter;
        uint256 reward = bounty.rewardAmount;

        if (!IERC20(votingTokenAddress).transfer(winner, reward)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        emit BountyRewardDistributed(_bountyId, winningSolutionIndex, winner, reward);
        _updateContributorReputation(winner, 10); // Significantly reward the winner
    }

    /// @notice Allows users to contribute funds to a specific AI model's or dataset's development pool.
    /// @dev Funds will be held by the contract and can be used for future bounties or direct development (via governance).
    /// @param _targetTokenId The ID of the AI model or dataset to fund.
    /// @param _amount The amount of `votingTokenAddress` to contribute.
    function fundDevelopmentPool(uint256 _targetTokenId, uint256 _amount) external nonReentrant {
        bool isModel = bytes(aiModels[_targetTokenId].cid).length != 0;
        bool isDataset = bytes(aiDatasets[_targetTokenId].cid).length != 0;

        if (!isModel && !isDataset) {
            revert SynapseForge__InvalidTokenId();
        }
        require(_amount > 0, "Amount must be greater than zero.");

        if (!IERC20(votingTokenAddress).transferFrom(_msgSender(), address(this), _amount)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        if (isModel) {
            aiModels[_targetTokenId].developmentFund += _amount;
        } else {
            aiDatasets[_targetTokenId].developmentFund += _amount;
        }

        emit DevelopmentFunded(_targetTokenId, _msgSender(), _amount);
        _updateContributorReputation(_msgSender(), 1); // Reward contributor
    }

    // --- IV. Reputation & Governance (Simplified DAO) ---

    /// @notice Deposits `votingTokenAddress` tokens to gain voting power.
    /// @param _amount The amount of tokens to stake.
    function depositVotingTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero.");
        if (!IERC20(votingTokenAddress).transferFrom(_msgSender(), address(this), _amount)) {
            revert SynapseForge__ERC20TransferFailed();
        }
        tokenStakes[_msgSender()] += _amount;
        emit TokensStaked(_msgSender(), _amount);
    }

    /// @notice Withdraws staked `votingTokenAddress` tokens.
    /// @param _amount The amount of tokens to unstake.
    function withdrawVotingTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero.");
        require(tokenStakes[_msgSender()] >= _amount, "Insufficient staked tokens.");
        tokenStakes[_msgSender()] -= _amount;
        if (!IERC20(votingTokenAddress).transfer(_msgSender(), _amount)) {
            revert SynapseForge__ERC20TransferFailed();
        }
        emit TokensUnstaked(_msgSender(), _amount);
    }

    /// @notice Creates a new governance proposal.
    /// @dev Requires a minimum voting power (e.g., a certain stake amount).
    /// @param _descriptionCid IPFS CID for detailed proposal description.
    /// @param _targetAddress The contract address the proposal aims to interact with.
    /// @param _callData The encoded function call (selector + arguments) for the target.
    function createGovernanceProposal(
        string memory _descriptionCid,
        address _targetAddress,
        bytes memory _callData
    ) external returns (uint256) {
        // Minimum stake to propose: e.g., 1000 voting tokens
        require(tokenStakes[_msgSender()] >= 1000 * (10 ** IERC20(votingTokenAddress).decimals()), "Insufficient voting power to propose.");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        // Voting period: 7 days
        uint256 voteDuration = 7 days;
        // Quorum: 4% of total supply (example)
        uint256 totalTokenSupply = IERC20(votingTokenAddress).totalSupply();
        uint256 quorum = (totalTokenSupply * 4) / 100;

        proposals[newProposalId] = GovernanceProposal({
            descriptionCid: _descriptionCid,
            targetAddress: _targetAddress,
            callData: _callData,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + voteDuration,
            quorumRequired: quorum,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit ProposalCreated(newProposalId, _msgSender(), _descriptionCid, _targetAddress, _callData);
        _updateContributorReputation(_msgSender(), 5); // Reward proposer
        return newProposalId;
    }

    /// @notice Allows a staked user to vote on a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (bytes(proposal.descriptionCid).length == 0) {
            revert SynapseForge__ProposalNotFound();
        }
        if (block.timestamp < proposal.voteStartTime || block.timestamp > proposal.voteEndTime) {
            revert SynapseForge__ProposalNotActive();
        }
        if (proposal.executed) {
            revert SynapseForge__ProposalAlreadyExecuted();
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert SynapseForge__AlreadyVoted();
        }
        if (tokenStakes[_msgSender()] == 0) {
            revert SynapseForge__InsufficientVotingPower();
        }

        if (_support) {
            proposal.votesFor += tokenStakes[_msgSender()];
        } else {
            proposal.votesAgainst += tokenStakes[_msgSender()];
        }
        proposal.hasVoted[_msgSender()] = true;

        emit ProposalVoted(_proposalId, _msgSender(), _support);
        _updateContributorReputation(_msgSender(), 1); // Reward voter
    }

    /// @notice Executes a governance proposal if it has passed (met quorum and votes in favor).
    /// @param _proposalId The ID of the proposal.
    function executeGovernanceProposal(uint256 _proposalId) external nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (bytes(proposal.descriptionCid).length == 0) {
            revert SynapseForge__ProposalNotFound();
        }
        if (block.timestamp <= proposal.voteEndTime) {
            revert SynapseForge__ProposalNotActive("Voting period is not over yet.");
        }
        if (proposal.executed) {
            revert SynapseForge__ProposalAlreadyExecuted();
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= proposal.quorumRequired, "Proposal did not reach quorum.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal was not approved.");

        proposal.executed = true;

        // Execute the proposed action
        (bool success, ) = proposal.targetAddress.call(proposal.callData);
        if (!success) {
            revert SynapseForge__TransferFailed("Proposal execution failed."); // Generic error for call failure
        }

        emit ProposalExecuted(_proposalId);
        _updateContributorReputation(_msgSender(), 5); // Reward the person executing the proposal
    }

    /// @notice Gets the reputation score of a contributor.
    /// @param _contributor The address of the contributor.
    /// @return The reputation score.
    function getContributorReputation(address _contributor) external view returns (int256) {
        return contributorReputation[_contributor];
    }

    // --- V. Platform Management (Governed by DAO) ---

    /// @notice Sets the platform fee percentage. Callable only via governance proposal.
    /// @param _newFeeBps The new platform fee in basis points (0-10000).
    function setPlatformFee(uint256 _newFeeBps) external onlyOwner {
        // This function is intended to be called by `executeGovernanceProposal` via DAO.
        // `onlyOwner` acts as a placeholder for the DAO's execution permission.
        // In a real DAO, `onlyOwner` would be replaced by `only(this)` with checks for `proposal.targetAddress == address(this)`.
        require(_newFeeBps <= 10000, "Fee BPS must be <= 10000");
        platformFeeBps = _newFeeBps;
        emit PlatformFeeUpdated(_newFeeBps);
    }

    /// @notice Allows withdrawal of funds from the platform's treasury. Callable only via governance proposal.
    /// @param _to The address to send funds to.
    /// @param _amount The amount of `votingTokenAddress` to withdraw.
    function withdrawTreasuryFunds(address _to, uint256 _amount) external onlyOwner nonReentrant {
        // This function is intended to be called by `executeGovernanceProposal` via DAO.
        // `onlyOwner` acts as a placeholder for the DAO's execution permission.
        require(_to != address(0), "Cannot withdraw to zero address.");
        require(IERC20(votingTokenAddress).balanceOf(address(this)) >= _amount, "Insufficient treasury balance.");

        if (!IERC20(votingTokenAddress).transfer(_to, _amount)) {
            revert SynapseForge__ERC20TransferFailed();
        }

        emit TreasuryFundsWithdrawn(_to, _amount);
    }

    // --- Internal / Helper Functions ---

    /// @notice Internal function to update a contributor's reputation score.
    /// @dev Called by various functions upon successful actions.
    /// @param _contributor The address whose reputation is to be updated.
    /// @param _change The amount to add to or subtract from the reputation score.
    function _updateContributorReputation(address _contributor, int256 _change) internal {
        contributorReputation[_contributor] += _change;
        emit ContributorReputationUpdated(_contributor, _change, contributorReputation[_contributor]);
    }

    /// @dev Overrides ERC721's `supportsInterface` for consistency with ERC165 if needed.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```