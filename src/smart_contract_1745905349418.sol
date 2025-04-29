Okay, here is a Solidity smart contract for a "Decentralized AI Model and Dataset Marketplace" featuring various advanced and creative concepts. It uses NFTs for licensing, incorporates a rating system, includes a basic decentralized governance/moderation mechanism, and handles marketplace fees and payments.

It aims to be creative by combining:
1.  **AI/ML Asset Management:** Selling/licensing models and datasets represented by on-chain structs and off-chain data (IPFS).
2.  **NFTs for Licensing:** Using ERC-721 tokens to represent the *rights* or *licenses* to use a model/dataset after purchase. This adds tradability and clear ownership tracking of licenses.
3.  **Decentralized Evaluation:** A simple on-chain rating system for users to provide feedback on models/datasets.
4.  **Parametric Governance/Moderation:** A basic system allowing designated governors to propose and approve changes (like fees) and moderate content (like flagged models).

It avoids direct duplication of standard OpenZeppelin contracts by implementing custom (albeit simpler for demonstration) access control (`Ownable`, `Governors`), pausable, and proposal/approval logic tailored to this marketplace. It doesn't implement ERC-721 itself but interacts with an external mock/interface.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A marketplace for buying, selling, and licensing AI models and datasets.
 *      Uses NFTs to represent licenses, incorporates a rating system, and includes
 *      a basic governor-based moderation and parameter change system.
 */

/*
Outline:
1.  Contract Description & Overview
2.  State Variables
3.  Events
4.  Error Handling
5.  Modifiers (Access Control, Pausability)
6.  Structs (Model, Dataset, Proposal, Approval)
7.  Core Marketplace Logic (Upload, Update, List, Delist, Buy)
8.  Licensing Integration (NFTs)
9.  Rating and Evaluation System
10. Governance and Moderation System (Governors, Proposals, Approvals, Flagging)
11. Admin and Utility Functions (Fees, Pause, Governor Management, Getters)

Function Summary:
-   **Core Marketplace (Upload, List, Buy):**
    -   `uploadModel`: Add a new AI model to the marketplace registry.
    -   `updateModel`: Owner updates details of an existing model.
    -   `listModelForSale`: Owner puts a model up for sale/licensing.
    -   `delistModel`: Owner removes a model from sale.
    -   `buyModel`: Purchase a model license/ownership (payable). Triggers NFT minting.
    -   `uploadDataset`: Add a new dataset.
    -   `updateDataset`: Owner updates dataset details.
    -   `listDatasetForSale`: Owner puts a dataset up for sale.
    -   `delistDataset`: Owner removes a dataset from sale.
    -   `buyDataset`: Purchase a dataset license/ownership (payable). Triggers NFT minting.
-   **Licensing (NFTs):**
    -   `setLicenseNFTContract`: Admin/Governor sets the ERC721 contract address used for issuing licenses.
    -   `_mintLicenseNFT`: Internal helper to interact with the NFT contract upon purchase. (Counts as a core feature function)
-   **Rating and Evaluation:**
    -   `rateModel`: Users rate a specific model.
    -   `rateDataset`: Users rate a specific dataset.
    -   `getModelAverageRating`: View function to get a model's average rating.
    -   `getDatasetAverageRating`: View function to get a dataset's average rating.
-   **Governance and Moderation:**
    -   `addGovernor`: Admin adds a new governor.
    -   `removeGovernor`: Admin removes a governor.
    -   `proposeParameterChange`: Governor proposes changing a marketplace parameter (e.g., fee).
    -   `approveParameterChange`: Governor approves a pending parameter change proposal (multi-sig like).
    -   `flagContent`: Any user can flag a model or dataset for review.
    -   `moderateContent`: Governor can delist flagged content based on review.
-   **Admin and Utility:**
    -   `setMarketplaceFee`: Governor executes an approved fee change proposal.
    -   `withdrawMarketplaceFees`: Admin/Governor withdraws accumulated marketplace fees.
    -   `pause`: Admin/Governor pauses core marketplace functions.
    -   `unpause`: Admin/Governor unpauses core marketplace functions.
-   **View Functions (Getters):**
    -   `getModelDetails`: Get comprehensive details of a model.
    -   `getDatasetDetails`: Get comprehensive details of a dataset.
    -   `getListedModels`: Get a list of IDs of all currently listed models.
    -   `getListedDatasets`: Get a list of IDs of all currently listed datasets.
    -   `getUserRatingForModel`: Get a specific user's rating for a model.
    -   `getUserRatingForDataset`: Get a specific user's rating for a dataset.
    -   `isGovernor`: Check if an address is a governor.
    -   `getProposalDetails`: Get details of a governance proposal.
    -   `getProposalApprovalCount`: Get the number of approvals for a proposal.
    -   `getRequiredApprovalsForProposal`: Get the threshold needed for a proposal.
*/

// --- Mock ERC721 Interface (for demonstration) ---
// In a real scenario, you'd import @openzeppelin/contracts/token/ERC721/IERC721.sol
interface IMockLicenseNFT {
    function safeMint(address to, uint256 tokenId) external;
    // Add other functions the marketplace might need, e.g., burn, transferFrom (less likely)
    // function supportsInterface(bytes4 interfaceId) external view returns (bool); // If needed for ERC721 compliance check
}

// --- Contract Definition ---
contract DecentralizedAIModelMarketplace {

    address public owner; // Contract deployer / primary admin

    // --- State Variables ---
    uint256 private _modelCounter;
    uint256 private _datasetCounter;
    uint256 private _proposalCounter;

    struct Model {
        uint256 id;
        address owner; // Current owner of the model (can change upon purchase)
        string name;
        string description;
        string ipfsHash; // Hash pointing to model files/metadata off-chain
        uint256 uploadTimestamp;
        bool isListed;
        uint256 price; // In wei
        mapping(address => uint8) ratings; // User address => rating (1-5)
        uint256 totalRatingSum; // Sum of all ratings
        uint256 ratingCount; // Number of ratings
        uint8 averageRating; // Calculated average (scaled, e.g., out of 100 or 10)
        bool isFlagged; // Flagged for moderation
        bool isDeleted; // Soft delete flag (moderated out or delisted permanently)
    }

    struct Dataset {
        uint256 id;
        address owner; // Current owner of the dataset (can change upon purchase)
        string name;
        string description;
        string ipfsHash; // Hash pointing to dataset files/metadata off-chain
        uint256 uploadTimestamp;
        bool isListed;
        uint256 price; // In wei
        mapping(address => uint8) ratings; // User address => rating (1-5)
        uint256 totalRatingSum;
        uint256 ratingCount;
        uint8 averageRating;
        bool isFlagged;
        bool isDeleted;
    }

    // Simple struct for governance proposals
    enum ProposalType { ChangeFee, ChangeRequiredApprovals }
    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        uint256 proposedValue; // New value for the parameter (e.g., new fee percentage)
        address proposer;
        uint256 creationTimestamp;
        uint256 approvalThreshold; // Number of governor approvals needed
        mapping(address => bool) approvals; // Governor address => has approved?
        uint256 currentApprovals;
        bool executed;
        bool cancelled;
    }

    mapping(uint256 => Model) public models;
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => Proposal) public proposals;

    // Store lists of listed item IDs (can be gas intensive for large lists)
    uint256[] public listedModelIds;
    mapping(uint256 => uint256) private _listedModelIdIndex; // To quickly remove
    uint256[] public listedDatasetIds;
    mapping(uint256 => uint256) private _listedDatasetIdIndex; // To quickly remove

    mapping(address => bool) public governors;
    uint256 public governorCount;
    uint256 public requiredApprovalsForProposal; // Threshold for proposals

    uint256 public marketplaceFeePercentage = 5; // 5% fee, stored as integer (5)
    uint256 public totalMarketplaceFees; // Accumulated fees

    bool public paused = false; // Pausability state

    // Address of the ERC721 contract used for issuing licenses
    IMockLicenseNFT public licenseNFTContract;
    uint256 public nextLicenseTokenId = 1; // Counter for unique license token IDs

    // --- Events ---
    event ModelUploaded(uint256 indexed modelId, address indexed owner, string name, string ipfsHash, uint256 price);
    event ModelUpdated(uint256 indexed modelId, string name, string ipfsHash, uint256 price);
    event ModelListed(uint256 indexed modelId, uint256 price);
    event ModelDelisted(uint256 indexed modelId);
    event ModelPurchased(uint256 indexed modelId, address indexed buyer, address indexed seller, uint256 pricePaid, uint256 feeAmount, uint256 licenseTokenId);
    event ModelRated(uint256 indexed modelId, address indexed user, uint8 rating, uint8 newAverageRating);
    event ModelFlagged(uint256 indexed modelId, address indexed flagger);
    event ModelModerated(uint256 indexed modelId, address indexed moderator, string reason); // Reason could be a code or IPFS hash

    event DatasetUploaded(uint256 indexed datasetId, address indexed owner, string name, string ipfsHash, uint256 price);
    event DatasetUpdated(uint256 indexed datasetId, string name, string ipfsHash, uint256 price);
    event DatasetListed(uint256 indexed datasetId, uint256 price);
    event DatasetDelisted(uint256 indexed datasetId);
    event DatasetPurchased(uint256 indexed datasetId, address indexed buyer, address indexed seller, uint256 pricePaid, uint256 feeAmount, uint256 licenseTokenId);
    event DatasetRated(uint256 indexed datasetId, address indexed user, uint8 rating, uint8 newAverageRating);
    event DatasetFlagged(uint256 indexed datasetId, address indexed flagger);
    event DatasetModerated(uint256 indexed datasetId, address indexed moderator, string reason);

    event LicenseNFTContractSet(address indexed contractAddress);
    event MarketplaceFeeSet(uint256 indexed newFeePercentage);
    event FeesWithdrawn(address indexed receiver, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event GovernorAdded(address indexed governor);
    event GovernorRemoved(address indexed governor);
    event ParameterChangeProposed(uint256 indexed proposalId, ProposalType indexed proposalType, uint256 proposedValue, address indexed proposer);
    event ProposalApproved(uint256 indexed proposalId, address indexed approver, uint256 currentApprovals);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);


    // --- Error Handling ---
    error OnlyOwner();
    error OnlyGovernor();
    error PausedState();
    error NotPausedState();
    error ModelNotFound();
    error DatasetNotFound();
    error NotModelOwner();
    error NotDatasetOwner();
    error ModelNotListed();
    error DatasetNotListed();
    error InvalidRating();
    error AlreadyRated();
    error PurchaseAmountMismatch();
    error SelfPurchaseForbidden();
    error LicenseNFTContractNotSet();
    error GovernorAlreadyExists();
    error GovernorNotFound();
    error NotEnoughGovernorsForThreshold();
    error ProposalNotFound();
    error ProposalAlreadyApproved();
    error ProposalNotApprovedYet();
    error ProposalAlreadyExecutedOrCancelled();
    error ProposalValueInvalid();
    error ContentAlreadyFlagged();
    error ContentNotFlagged();
    error ContentAlreadyModerated();


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyGovernor() {
        if (!governors[msg.sender]) revert OnlyGovernor();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert PausedState();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPausedState();
        _;
    }

    // --- Constructor ---
    constructor(address _initialGovernor, uint256 _requiredApprovalsForProposal) {
        owner = msg.sender;
        addGovernor(_initialGovernor); // Add the deployer or a specified initial governor
        requiredApprovalsForProposal = _requiredApprovalsForProposal;
        if (governorCount < requiredApprovalsForProposal) revert NotEnoughGovernorsForThreshold();
    }

    // --- Admin & Governor Management ---

    /**
     * @dev Adds a new address as a governor. Only callable by the owner.
     * @param _governor Address to add.
     */
    function addGovernor(address _governor) public onlyOwner {
        if (governors[_governor]) revert GovernorAlreadyExists();
        governors[_governor] = true;
        governorCount++;
        emit GovernorAdded(_governor);
    }

    /**
     * @dev Removes an address as a governor. Only callable by the owner.
     * @param _governor Address to remove.
     */
    function removeGovernor(address _governor) public onlyOwner {
        if (!governors[_governor]) revert GovernorNotFound();
        if (governorCount == requiredApprovalsForProposal) revert NotEnoughGovernorsForThreshold(); // Prevent removing last governor if threshold is 1
        governors[_governor] = false;
        governorCount--;
        emit GovernorRemoved(_governor);
    }

    /**
     * @dev Sets the required number of governor approvals for proposals.
     *      This is a critical parameter and should ideally be changed via a proposal itself.
     *      Leaving it direct for simplicity, but note the circular dependency potential.
     * @param _requiredApprovals The new threshold.
     */
    function setRequiredApprovalsForProposal(uint256 _requiredApprovals) public onlyOwner {
        if (_requiredApprovals == 0 || _requiredApprovals > governorCount) revert ProposalValueInvalid(); // Simple validation
        requiredApprovalsForProposal = _requiredApprovals;
        // No specific event for this direct change, can add if needed.
    }


    // --- Pausability ---

    /**
     * @dev Pauses the contract, preventing core marketplace actions.
     *      Callable by admin or governors.
     */
    function pause() public onlyGovernor whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing core marketplace actions.
     *      Callable by admin or governors.
     */
    function unpause() public onlyGovernor whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is paused.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }


    // --- Licensing NFT Integration ---

    /**
     * @dev Sets the address of the ERC721 contract used to mint licenses.
     *      Callable by admin or governors.
     * @param _contractAddress The address of the deployed ERC721 License NFT contract.
     */
    function setLicenseNFTContract(address _contractAddress) public onlyGovernor {
        // Basic check if address is not zero. More robust check might involve
        // calling supportsInterface(0x80ac58cd) if the mock interface had it.
        if (_contractAddress == address(0)) revert LicenseNFTContractNotSet();
        licenseNFTContract = IMockLicenseNFT(_contractAddress);
        emit LicenseNFTContractSet(_contractAddress);
    }

    /**
     * @dev Internal function to mint a license NFT upon successful purchase.
     * @param _to The recipient of the NFT.
     * @param _itemId The ID of the model or dataset being licensed.
     * @param _isModel True if licensing a model, false if a dataset.
     * @return The ID of the newly minted license token.
     */
    function _mintLicenseNFT(address _to, uint256 _itemId, bool _isModel) internal returns (uint256) {
        if (address(licenseNFTContract) == address(0)) revert LicenseNFTContractNotSet();

        // Generate a unique token ID. Could encode item ID and type, or just use a counter.
        // Simple counter approach:
        uint256 tokenId = nextLicenseTokenId++;
        // A more complex approach could encode type and item ID:
        // uint256 tokenId = (_isModel ? (1 << 255) : 0) | _itemId; // Using high bit for type

        licenseNFTContract.safeMint(_to, tokenId); // Assume safeMint handles existence checks in NFT contract

        // Future improvement: Store mapping between license token ID and the model/dataset ID
        // This would require a state variable like: mapping(uint256 => uint256) public licenseTokenToItemId;
        // and possibly mapping(uint256 => bool) public licenseTokenIsModel;

        return tokenId;
    }


    // --- Core Marketplace Functions (Models) ---

    /**
     * @dev Uploads a new AI model to the marketplace registry.
     * @param _name Name of the model.
     * @param _description Description of the model.
     * @param _ipfsHash IPFS hash pointing to the model files/metadata.
     */
    function uploadModel(string memory _name, string memory _description, string memory _ipfsHash) public whenNotPaused {
        _modelCounter++;
        uint256 modelId = _modelCounter;

        models[modelId] = Model({
            id: modelId,
            owner: msg.sender,
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            uploadTimestamp: block.timestamp,
            isListed: false,
            price: 0, // Price is set when listed
            totalRatingSum: 0,
            ratingCount: 0,
            averageRating: 0,
            isFlagged: false,
            isDeleted: false // Soft delete
        });

        emit ModelUploaded(modelId, msg.sender, _name, _ipfsHash, 0);
    }

    /**
     * @dev Updates the details of an existing model. Only the owner can update.
     *      Cannot update if listed, flagged, or deleted. Owner must delist first.
     * @param _modelId The ID of the model to update.
     * @param _name New name (can be empty string to not change).
     * @param _description New description (can be empty string to not change).
     * @param _ipfsHash New IPFS hash (can be empty string to not change).
     */
    function updateModel(uint256 _modelId, string memory _name, string memory _description, string memory _ipfsHash) public whenNotPaused {
        Model storage model = models[_modelId];
        if (model.owner == address(0) || model.isDeleted) revert ModelNotFound();
        if (model.owner != msg.sender) revert NotModelOwner();
        if (model.isListed) revert ModelListed(); // Must delist to update
        if (model.isFlagged) revert ContentAlreadyFlagged(); // Cannot update flagged content

        if (bytes(_name).length > 0) model.name = _name;
        if (bytes(_description).length > 0) model.description = _description;
        if (bytes(_ipfsHash).length > 0) model.ipfsHash = _ipfsHash;

        // Don't change timestamp for updates, only original upload
        // model.uploadTimestamp = block.timestamp;

        emit ModelUpdated(_modelId, model.name, model.ipfsHash, model.price);
    }

    /**
     * @dev Lists a model for sale/licensing on the marketplace.
     *      Callable only by the model owner if not already listed, flagged, or deleted.
     * @param _modelId The ID of the model to list.
     * @param _price The price in wei. Must be greater than 0.
     */
    function listModelForSale(uint256 _modelId, uint256 _price) public whenNotPaused {
        Model storage model = models[_modelId];
        if (model.owner == address(0) || model.isDeleted) revert ModelNotFound();
        if (model.owner != msg.sender) revert NotModelOwner();
        if (model.isListed) revert ModelListed(); // Already listed
        if (model.isFlagged) revert ContentAlreadyFlagged(); // Cannot list flagged content
        if (_price == 0) revert ProposalValueInvalid(); // Price must be > 0

        model.isListed = true;
        model.price = _price;

        _listedModelIdIndex[_modelId] = listedModelIds.length;
        listedModelIds.push(_modelId);

        emit ModelListed(_modelId, _price);
    }

    /**
     * @dev Delists a model from the marketplace.
     *      Callable only by the model owner if currently listed.
     * @param _modelId The ID of the model to delist.
     */
    function delistModel(uint256 _modelId) public whenNotPaused {
        Model storage model = models[_modelId];
        if (model.owner == address(0) || model.isDeleted) revert ModelNotFound();
        if (model.owner != msg.sender) revert NotModelOwner();
        if (!model.isListed) revert ModelNotListed(); // Not listed

        model.isListed = false;
        model.price = 0; // Reset price

        // Remove from listedModelIds array
        uint256 index = _listedModelIdIndex[_modelId];
        uint256 lastIndex = listedModelIds.length - 1;
        if (index != lastIndex) {
            uint256 lastModelId = listedModelIds[lastIndex];
            listedModelIds[index] = lastModelId;
            _listedModelIdIndex[lastModelId] = index;
        }
        listedModelIds.pop();
        delete _listedModelIdIndex[_modelId]; // Clean up index mapping

        emit ModelDelisted(_modelId);
    }

    /**
     * @dev Purchases a license/ownership for a listed model.
     *      Transfers required ETH to the seller (minus fee) and mints a License NFT to the buyer.
     * @param _modelId The ID of the model to purchase.
     */
    function buyModel(uint256 _modelId) public payable whenNotPaused {
        Model storage model = models[_modelId];
        if (model.owner == address(0) || model.isDeleted) revert ModelNotFound();
        if (!model.isListed) revert ModelNotListed();
        if (model.owner == msg.sender) revert SelfPurchaseForbidden(); // Cannot buy your own model
        if (msg.value < model.price) revert PurchaseAmountMismatch(); // Sent less than price

        uint256 price = model.price;
        uint256 feeAmount = (price * marketplaceFeePercentage) / 100;
        uint256 amountToSeller = price - feeAmount;

        address payable seller = payable(model.owner);
        address payable buyer = payable(msg.sender);

        // Effects & State Updates first (Checks-Effects-Interactions pattern)
        model.isListed = false; // Delist upon purchase
        model.price = 0; // Reset price

        // Remove from listedModelIds array
        uint256 index = _listedModelIdIndex[_modelId];
        uint256 lastIndex = listedModelIds.length - 1;
        if (index != lastIndex) {
            uint256 lastModelId = listedModelIds[lastIndex];
            listedModelIds[index] = lastModelId;
            _listedModelIdIndex[lastModelId] = index;
        }
        listedModelIds.pop();
        delete _listedModelIdIndex[_modelId];

        // The 'owner' field in the Model struct could represent outright ownership transfer
        // or simply track who is the *current* lister.
        // For a *licensing* model, the original uploader remains the primary 'owner' of the IP,
        // and the NFT represents the purchased *license*. Let's stick with this licensing model.
        // If it was an ownership transfer marketplace, we'd set `model.owner = msg.sender;` here.

        totalMarketplaceFees += feeAmount;

        // Interaction: Mint License NFT
        uint256 licenseTokenId = _mintLicenseNFT(buyer, _modelId, true);

        // Interaction: Transfer ETH
        // Use call for safer transfer
        (bool successSeller, ) = seller.call{value: amountToSeller}("");
        require(successSeller, "ETH transfer to seller failed");

        // Any excess ETH is returned to the buyer automatically by the payable function

        emit ModelPurchased(_modelId, buyer, seller, price, feeAmount, licenseTokenId);
    }


    // --- Core Marketplace Functions (Datasets) ---
    // These mirror the model functions

    /**
     * @dev Uploads a new dataset to the marketplace registry.
     * @param _name Name of the dataset.
     * @param _description Description of the dataset.
     * @param _ipfsHash IPFS hash pointing to the dataset files/metadata.
     */
    function uploadDataset(string memory _name, string memory _description, string memory _ipfsHash) public whenNotPaused {
        _datasetCounter++;
        uint256 datasetId = _datasetCounter;

        datasets[datasetId] = Dataset({
            id: datasetId,
            owner: msg.sender,
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            uploadTimestamp: block.timestamp,
            isListed: false,
            price: 0, // Price is set when listed
            totalRatingSum: 0,
            ratingCount: 0,
            averageRating: 0,
            isFlagged: false,
            isDeleted: false
        });

        emit DatasetUploaded(datasetId, msg.sender, _name, _ipfsHash, 0);
    }

    /**
     * @dev Updates the details of an existing dataset. Only the owner can update.
     * @param _datasetId The ID of the dataset to update.
     * @param _name New name.
     * @param _description New description.
     * @param _ipfsHash New IPFS hash.
     */
    function updateDataset(uint256 _datasetId, string memory _name, string memory _description, string memory _ipfsHash) public whenNotPaused {
         Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0) || dataset.isDeleted) revert DatasetNotFound();
        if (dataset.owner != msg.sender) revert NotDatasetOwner();
        if (dataset.isListed) revert DatasetListed(); // Must delist to update
        if (dataset.isFlagged) revert ContentAlreadyFlagged(); // Cannot update flagged content

        if (bytes(_name).length > 0) dataset.name = _name;
        if (bytes(_description).length > 0) dataset.description = _description;
        if (bytes(_ipfsHash).length > 0) dataset.ipfsHash = _ipfsHash;

        emit DatasetUpdated(_datasetId, dataset.name, dataset.ipfsHash, dataset.price);
    }

    /**
     * @dev Lists a dataset for sale/licensing. Callable only by owner.
     * @param _datasetId The ID of the dataset to list.
     * @param _price The price in wei. Must be greater than 0.
     */
    function listDatasetForSale(uint256 _datasetId, uint256 _price) public whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0) || dataset.isDeleted) revert DatasetNotFound();
        if (dataset.owner != msg.sender) revert NotDatasetOwner();
        if (dataset.isListed) revert DatasetListed(); // Already listed
         if (dataset.isFlagged) revert ContentAlreadyFlagged(); // Cannot list flagged content
        if (_price == 0) revert ProposalValueInvalid(); // Price must be > 0

        dataset.isListed = true;
        dataset.price = _price;

        _listedDatasetIdIndex[_datasetId] = listedDatasetIds.length;
        listedDatasetIds.push(_datasetId);

        emit DatasetListed(_datasetId, _price);
    }

    /**
     * @dev Delists a dataset from the marketplace. Callable only by owner.
     * @param _datasetId The ID of the dataset to delist.
     */
    function delistDataset(uint256 _datasetId) public whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0) || dataset.isDeleted) revert DatasetNotFound();
        if (dataset.owner != msg.sender) revert NotDatasetOwner();
        if (!dataset.isListed) revert DatasetNotListed(); // Not listed

        dataset.isListed = false;
        dataset.price = 0; // Reset price

        // Remove from listedDatasetIds array
        uint256 index = _listedDatasetIdIndex[_datasetId];
        uint256 lastIndex = listedDatasetIds.length - 1;
        if (index != lastIndex) {
            uint256 lastDatasetId = listedDatasetIds[lastIndex];
            listedDatasetIds[index] = lastDatasetId;
            _listedDatasetIdIndex[lastDatasetId] = index;
        }
        listedDatasetIds.pop();
        delete _listedDatasetIdIndex[_datasetId];

        emit DatasetDelisted(_datasetId);
    }

    /**
     * @dev Purchases a license/ownership for a listed dataset.
     * @param _datasetId The ID of the dataset to purchase.
     */
    function buyDataset(uint256 _datasetId) public payable whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0) || dataset.isDeleted) revert DatasetNotFound();
        if (!dataset.isListed) revert DatasetNotListed();
        if (dataset.owner == msg.sender) revert SelfPurchaseForbidden(); // Cannot buy your own dataset
        if (msg.value < dataset.price) revert PurchaseAmountMismatch(); // Sent less than price

        uint256 price = dataset.price;
        uint256 feeAmount = (price * marketplaceFeePercentage) / 100;
        uint256 amountToSeller = price - feeAmount;

        address payable seller = payable(dataset.owner);
        address payable buyer = payable(msg.sender);

        // Effects & State Updates first
        dataset.isListed = false; // Delist upon purchase
        dataset.price = 0; // Reset price

        // Remove from listedDatasetIds array
        uint256 index = _listedDatasetIdIndex[_datasetId];
        uint256 lastIndex = listedDatasetIds.length - 1;
        if (index != lastIndex) {
            uint256 lastDatasetId = listedDatasetIds[lastIndex];
            listedDatasetIds[index] = lastDatasetId;
            _listedDatasetIdIndex[lastDatasetId] = index;
        }
        listedDatasetIds.pop();
        delete _listedDatasetIdIndex[_datasetId];

        // As with models, assuming licensing model. Dataset owner retains IP, NFT grants license.

        totalMarketplaceFees += feeAmount;

        // Interaction: Mint License NFT
        uint256 licenseTokenId = _mintLicenseNFT(buyer, _datasetId, false);

        // Interaction: Transfer ETH
        (bool successSeller, ) = seller.call{value: amountToSeller}("");
        require(successSeller, "ETH transfer to seller failed");

        // Any excess ETH is returned to the buyer automatically

        emit DatasetPurchased(_datasetId, buyer, seller, price, feeAmount, licenseTokenId);
    }


    // --- Rating and Evaluation ---

    /**
     * @dev Allows a user to rate a model. Ratings are 1-5.
     *      Users can only rate a model once.
     * @param _modelId The ID of the model to rate.
     * @param _rating The rating (1-5).
     */
    function rateModel(uint256 _modelId, uint8 _rating) public whenNotPaused {
        Model storage model = models[_modelId];
         if (model.owner == address(0) || model.isDeleted) revert ModelNotFound();
         if (_rating < 1 || _rating > 5) revert InvalidRating();
         if (model.ratings[msg.sender] != 0) revert AlreadyRated(); // 0 means not rated yet

         model.ratings[msg.sender] = _rating;
         model.totalRatingSum += _rating;
         model.ratingCount++;
         model.averageRating = uint8(model.totalRatingSum / model.ratingCount); // Simple integer average

         emit ModelRated(_modelId, msg.sender, _rating, model.averageRating);
    }

     /**
     * @dev Allows a user to rate a dataset. Ratings are 1-5.
     *      Users can only rate a dataset once.
     * @param _datasetId The ID of the dataset to rate.
     * @param _rating The rating (1-5).
     */
     function rateDataset(uint256 _datasetId, uint8 _rating) public whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
         if (dataset.owner == address(0) || dataset.isDeleted) revert DatasetNotFound();
         if (_rating < 1 || _rating > 5) revert InvalidRating();
         if (dataset.ratings[msg.sender] != 0) revert AlreadyRated(); // 0 means not rated yet

         dataset.ratings[msg.sender] = _rating;
         dataset.totalRatingSum += _rating;
         dataset.ratingCount++;
         dataset.averageRating = uint8(dataset.totalRatingSum / dataset.ratingCount); // Simple integer average

         emit DatasetRated(_datasetId, msg.sender, _rating, dataset.averageRating);
    }


    // --- Governance & Moderation ---

    /**
     * @dev Governors can propose changes to marketplace parameters.
     * @param _type The type of proposal (e.g., ChangeFee).
     * @param _value The proposed new value.
     * @return The ID of the created proposal.
     */
    function proposeParameterChange(ProposalType _type, uint256 _value) public onlyGovernor whenNotPaused returns (uint256) {
        // Basic validation based on type
        if (_type == ProposalType.ChangeFee && (_value > 100 || _value < 0)) revert ProposalValueInvalid(); // Fee % 0-100
        // Add more type-specific validation here if needed

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposalType = _type;
        proposal.proposedValue = _value;
        proposal.proposer = msg.sender;
        proposal.creationTimestamp = block.timestamp;
        proposal.approvalThreshold = requiredApprovalsForProposal;
        // Proposer automatically approves
        proposal.approvals[msg.sender] = true;
        proposal.currentApprovals = 1;
        proposal.executed = false;
        proposal.cancelled = false;

        emit ParameterChangeProposed(proposalId, _type, _value, msg.sender);
        // If threshold is 1 and proposer is a governor, it's approved immediately
        if (requiredApprovalsForProposal == 1) {
             _executeProposal(proposalId, proposal); // Pass struct by reference
        }

        return proposalId;
    }

    /**
     * @dev Governors approve a pending proposal. Requires `requiredApprovalsForProposal` governors to approve.
     * @param _proposalId The ID of the proposal to approve.
     */
    function approveParameterChange(uint256 _proposalId) public onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(); // Check if proposal exists
        if (proposal.executed || proposal.cancelled) revert ProposalAlreadyExecutedOrCancelled();
        if (proposal.approvals[msg.sender]) revert ProposalAlreadyApproved();

        proposal.approvals[msg.sender] = true;
        proposal.currentApprovals++;

        emit ProposalApproved(_proposalId, msg.sender, proposal.currentApprovals);

        if (proposal.currentApprovals >= proposal.approvalThreshold) {
            _executeProposal(_proposalId, proposal); // Pass struct by reference
        }
    }

    /**
     * @dev Internal function to execute an approved proposal.
     * @param _proposalId The ID of the proposal.
     * @param _proposal The proposal struct (passed by reference).
     */
    function _executeProposal(uint256 _proposalId, Proposal storage _proposal) internal {
        if (_proposal.executed || _proposal.cancelled) revert ProposalAlreadyExecutedOrCancelled();
        // Should also check if currentApprovals >= approvalThreshold before calling this internally
        // Adding an external execute function might add complexity for 'anyone can execute after threshold'
        // But for this demo, it's internal, called once threshold is met.

        _proposal.executed = true;

        if (_proposal.proposalType == ProposalType.ChangeFee) {
             marketplaceFeePercentage = _proposal.proposedValue;
             emit MarketplaceFeeSet(_proposal.proposedValue);
        }
        // Add other proposal types here

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows any user to flag a model or dataset for review by governors.
     * @param _modelId The ID of the model to flag (use 0 if flagging a dataset).
     * @param _datasetId The ID of the dataset to flag (use 0 if flagging a model).
     * @param _reasonIpfsHash IPFS hash pointing to details about the reason for flagging.
     */
    function flagContent(uint256 _modelId, uint256 _datasetId, string memory _reasonIpfsHash) public whenNotPaused {
        bool isModel = _modelId != 0;
        bool isDataset = _datasetId != 0;

        if ((isModel && isDataset) || (!isModel && !isDataset)) {
             revert ProposalValueInvalid(); // Must flag exactly one item
        }

        if (isModel) {
            Model storage model = models[_modelId];
            if (model.owner == address(0) || model.isDeleted) revert ModelNotFound();
            if (model.isFlagged) revert ContentAlreadyFlagged();
            model.isFlagged = true;
            // Optionally store reason: mapping(uint256 => string) public modelFlagReasons; modelFlagReasons[_modelId] = _reasonIpfsHash;
            emit ModelFlagged(_modelId, msg.sender);
        } else { // isDataset
            Dataset storage dataset = datasets[_datasetId];
            if (dataset.owner == address(0) || dataset.isDeleted) revert DatasetNotFound();
            if (dataset.isFlagged) revert ContentAlreadyFlagged();
            dataset.isFlagged = true;
             // Optionally store reason: mapping(uint256 => string) public datasetFlagReasons; datasetFlagReasons[_datasetId] = _reasonIpfsHash;
            emit DatasetFlagged(_datasetId, msg.sender);
        }
        // Note: Storing IPFS hashes for flag reasons on-chain costs gas. Better to just emit event
        // and have off-chain systems monitor events and retrieve reasons from off-chain storage.
    }

     /**
     * @dev Allows governors to moderate flagged content. This action soft-deletes the item.
     *      It removes the item from listings and prevents further updates/ratings/purchases.
     * @param _modelId The ID of the model to moderate (use 0 if moderating a dataset).
     * @param _datasetId The ID of the dataset to moderate (use 0 if moderating a model).
     * @param _reasonIpfsHash IPFS hash linking to the moderation decision/reason.
     */
     function moderateContent(uint256 _modelId, uint256 _datasetId, string memory _reasonIpfsHash) public onlyGovernor whenNotPaused {
        bool isModel = _modelId != 0;
        bool isDataset = _datasetId != 0;

        if ((isModel && isDataset) || (!isModel && !isDataset)) {
             revert ProposalValueInvalid(); // Must moderate exactly one item
        }

        if (isModel) {
            Model storage model = models[_modelId];
            if (model.owner == address(0) || model.isDeleted) revert ModelNotFound();
            if (!model.isFlagged) revert ContentNotFlagged(); // Can only moderate flagged content
            if (model.isDeleted) revert ContentAlreadyModerated(); // Already moderated

            model.isDeleted = true; // Soft delete
            model.isListed = false; // Ensure it's not listed
            model.isFlagged = false; // Remove flag

             // Clean up from listed arrays if it was listed
             // Check if it was listed before attempting to remove from array
             if (_listedModelIdIndex[_modelId] != 0 || (listedModelIds.length > 0 && listedModelIds[0] == _modelId)) {
                 uint256 index = _listedModelIdIndex[_modelId];
                 uint256 lastIndex = listedModelIds.length - 1;
                 if (index < listedModelIds.length) { // Basic bounds check
                    if (index != lastIndex) {
                        uint256 lastModelId = listedModelIds[lastIndex];
                        listedModelIds[index] = lastModelId;
                        _listedModelIdIndex[lastModelId] = index;
                    }
                    listedModelIds.pop();
                    delete _listedModelIdIndex[_modelId];
                 }
             }


            emit ModelModerated(_modelId, msg.sender, _reasonIpfsHash);

        } else { // isDataset
            Dataset storage dataset = datasets[_datasetId];
            if (dataset.owner == address(0) || dataset.isDeleted) revert DatasetNotFound();
            if (!dataset.isFlagged) revert ContentNotFlagged(); // Can only moderate flagged content
             if (dataset.isDeleted) revert ContentAlreadyModerated(); // Already moderated

            dataset.isDeleted = true; // Soft delete
            dataset.isListed = false; // Ensure it's not listed
            dataset.isFlagged = false; // Remove flag

             // Clean up from listed arrays if it was listed
             // Check if it was listed before attempting to remove from array
             if (_listedDatasetIdIndex[_datasetId] != 0 || (listedDatasetIds.length > 0 && listedDatasetIds[0] == _datasetId)) {
                 uint256 index = _listedDatasetIdIndex[_datasetId];
                 uint256 lastIndex = listedDatasetIds.length - 1;
                 if (index < listedDatasetIds.length) { // Basic bounds check
                    if (index != lastIndex) {
                        uint256 lastDatasetId = listedDatasetIds[lastIndex];
                        listedDatasetIds[index] = lastDatasetId;
                        _listedDatasetIdIndex[lastDatasetId] = index;
                    }
                    listedDatasetIds.pop();
                    delete _listedDatasetIdIndex[_datasetId];
                 }
             }

            emit DatasetModerated(_datasetId, msg.sender, _reasonIpfsHash);
        }
    }


    // --- Admin & Fee Management ---

    /**
     * @dev Withdraws accumulated marketplace fees to a specified address.
     *      Callable by admin or governors.
     * @param _to The address to send the fees to.
     */
    function withdrawMarketplaceFees(address payable _to) public onlyGovernor {
        uint256 amount = totalMarketplaceFees;
        if (amount == 0) return;

        totalMarketplaceFees = 0; // Reset before sending

        (bool success, ) = _to.call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(_to, amount);
    }

     /**
     * @dev Executes an approved proposal to set the new marketplace fee percentage.
     *      Internal function, called by _executeProposal.
     *      (This specific function is now conceptually part of _executeProposal for simplicity
     *       in this example, but kept in summary for clarity of purpose).
     */
    // function setMarketplaceFee(uint256 _newFeePercentage) public onlyGovernor { ... handled by _executeProposal }


    // --- View Functions (Getters) ---

    /**
     * @dev Gets the details of a specific model.
     * @param _modelId The ID of the model.
     * @return Model details.
     */
    function getModelDetails(uint256 _modelId) public view returns (
        uint256 id,
        address owner,
        string memory name,
        string memory description,
        string memory ipfsHash,
        uint256 uploadTimestamp,
        bool isListed,
        uint256 price,
        uint8 averageRating,
        bool isFlagged,
        bool isDeleted
    ) {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(); // Basic existence check

        return (
            model.id,
            model.owner,
            model.name,
            model.description,
            model.ipfsHash,
            model.uploadTimestamp,
            model.isListed,
            model.price,
            model.averageRating,
            model.isFlagged,
            model.isDeleted
        );
    }

     /**
     * @dev Gets the details of a specific dataset.
     * @param _datasetId The ID of the dataset.
     * @return Dataset details.
     */
    function getDatasetDetails(uint256 _datasetId) public view returns (
        uint256 id,
        address owner,
        string memory name,
        string memory description,
        string memory ipfsHash,
        uint256 uploadTimestamp,
        bool isListed,
        uint256 price,
        uint8 averageRating,
        bool isFlagged,
        bool isDeleted
    ) {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0)) revert DatasetNotFound(); // Basic existence check

        return (
            dataset.id,
            dataset.owner,
            dataset.name,
            dataset.description,
            dataset.ipfsHash,
            dataset.uploadTimestamp,
            dataset.isListed,
            dataset.price,
            dataset.averageRating,
            dataset.isFlagged,
            dataset.isDeleted
        );
    }

    /**
     * @dev Gets a list of IDs of all currently listed models.
     *      NOTE: This can be gas intensive if the list is very large.
     * @return An array of listed model IDs.
     */
    function getListedModels() public view returns (uint256[] memory) {
        // Return a copy of the array
        return listedModelIds;
    }

     /**
     * @dev Gets a list of IDs of all currently listed datasets.
     *      NOTE: This can be gas intensive if the list is very large.
     * @return An array of listed dataset IDs.
     */
    function getListedDatasets() public view returns (uint256[] memory) {
        // Return a copy of the array
        return listedDatasetIds;
    }


    /**
     * @dev Gets the average rating for a specific model.
     * @param _modelId The ID of the model.
     * @return The average rating (0-5).
     */
    function getModelAverageRating(uint256 _modelId) public view returns (uint8) {
        Model storage model = models[_modelId];
         if (model.owner == address(0)) revert ModelNotFound();
         return model.averageRating;
    }

     /**
     * @dev Gets the average rating for a specific dataset.
     * @param _datasetId The ID of the dataset.
     * @return The average rating (0-5).
     */
    function getDatasetAverageRating(uint256 _datasetId) public view returns (uint8) {
        Dataset storage dataset = datasets[_datasetId];
         if (dataset.owner == address(0)) revert DatasetNotFound();
         return dataset.averageRating;
    }

    /**
     * @dev Gets a specific user's rating for a model.
     * @param _modelId The ID of the model.
     * @param _user The address of the user.
     * @return The user's rating (0 if not rated, 1-5 otherwise).
     */
    function getUserRatingForModel(uint256 _modelId, address _user) public view returns (uint8) {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound();
        return model.ratings[_user];
    }

    /**
     * @dev Gets a specific user's rating for a dataset.
     * @param _datasetId The ID of the dataset.
     * @param _user The address of the user.
     * @return The user's rating (0 if not rated, 1-5 otherwise).
     */
    function getUserRatingForDataset(uint256 _datasetId, address _user) public view returns (uint8) {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0)) revert DatasetNotFound();
        return dataset.ratings[_user];
    }


    /**
     * @dev Checks if an address is a governor.
     * @param _address The address to check.
     * @return True if the address is a governor, false otherwise.
     */
    function isGovernor(address _address) public view returns (bool) {
        return governors[_address];
    }

    /**
     * @dev Gets the details of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        ProposalType proposalType,
        uint256 proposedValue,
        address proposer,
        uint256 creationTimestamp,
        uint256 approvalThreshold,
        uint256 currentApprovals,
        bool executed,
        bool cancelled
    ) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(); // Check if proposal exists

        return (
            proposal.id,
            proposal.proposalType,
            proposal.proposedValue,
            proposal.proposer,
            proposal.creationTimestamp,
            proposal.approvalThreshold,
            proposal.currentApprovals,
            proposal.executed,
            proposal.cancelled
        );
    }

     /**
     * @dev Gets the current number of approvals for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The number of approvals.
     */
    function getProposalApprovalCount(uint256 _proposalId) public view returns (uint256) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        return proposal.currentApprovals;
    }

    /**
     * @dev Gets the required number of governor approvals for proposals.
     * @return The required approval threshold.
     */
    function getRequiredApprovalsForProposal() public view returns (uint256) {
        return requiredApprovalsForProposal;
    }
}
```