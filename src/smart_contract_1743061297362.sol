```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 *  Decentralized AI Model Marketplace - Outline and Function Summary
 *
 *  Contract Name: DecentralizedAIMarketplace
 *
 *  Description:
 *  This smart contract implements a decentralized marketplace for AI models.
 *  It allows AI model creators to register their models, set access conditions (e.g., pricing, subscription, free),
 *  and enables users to discover, access, and utilize these AI models through the contract.
 *  The contract incorporates advanced concepts such as on-chain model metadata storage,
 *  access control mechanisms, reputation/rating system, revenue sharing, and basic governance for platform parameters.
 *  It aims to foster a transparent and decentralized ecosystem for AI model sharing and utilization.
 *
 *  Function Summary:
 *
 *  [Model Registration and Management]
 *  1. registerModel(string _modelName, string _modelDescription, string _modelMetadataURI, uint256 _pricePerUse, ModelAccessType _accessType)
 *     - Allows AI model creators to register their models on the marketplace.
 *     - Stores model metadata, access type, and pricing on-chain.
 *
 *  2. updateModelMetadata(uint256 _modelId, string _newModelName, string _newModelDescription, string _newModelMetadataURI)
 *     - Allows model creators to update the metadata of their registered models.
 *
 *  3. setModelPrice(uint256 _modelId, uint256 _newPricePerUse)
 *     - Allows model creators to change the price per use of their models.
 *
 *  4. setModelAccessType(uint256 _modelId, ModelAccessType _newAccessType)
 *     - Allows model creators to change the access type (e.g., pay-per-use, free) of their models.
 *
 *  5. revokeModel(uint256 _modelId)
 *     - Allows model creators to revoke their model from the marketplace, preventing further access.
 *
 *  [Model Discovery and Access]
 *  6. getModelDetails(uint256 _modelId) view returns (Model)
 *     - Allows users to retrieve detailed information about a specific model using its ID.
 *
 *  7. getAllModelIds() view returns (uint256[])
 *     - Returns a list of all registered model IDs for discovery and listing.
 *
 *  8. requestModelAccess(uint256 _modelId) payable
 *     - Allows users to request access to a model.
 *     - Handles payment processing based on the model's access type and price.
 *
 *  9. checkModelAccess(uint256 _modelId, address _user) view returns (bool)
 *     - Allows users or other contracts to check if a specific user has access to a model.
 *
 *  [Reputation and Rating System]
 *  10. submitModelReview(uint256 _modelId, uint8 _rating, string _reviewText)
 *      - Allows users who have used a model to submit a review and rating.
 *
 *  11. getAverageModelRating(uint256 _modelId) view returns (uint8)
 *      - Calculates and returns the average rating for a specific model.
 *
 *  12. getModelReviews(uint256 _modelId) view returns (Review[])
 *      - Returns a list of reviews submitted for a specific model.
 *
 *  [Revenue and Payout Management]
 *  13. withdrawCreatorEarnings()
 *      - Allows model creators to withdraw their accumulated earnings from model usage.
 *
 *  14. getCreatorEarnings(address _creator) view returns (uint256)
 *      - Allows users to view the current earnings balance for a model creator.
 *
 *  15. setPlatformFee(uint256 _feePercentage) onlyOwner
 *      - Allows the contract owner to set a platform fee percentage on model usage payments.
 *
 *  16. getPlatformFee() view onlyOwner returns (uint256)
 *      - Allows the contract owner to view the current platform fee percentage.
 *
 *  [Governance and Platform Parameters (Basic)]
 *  17. proposeParameterChange(string _parameterName, uint256 _newValue)
 *      - Allows platform users to propose changes to certain platform parameters.
 *
 *  18. voteOnProposal(uint256 _proposalId, bool _vote)
 *      - Allows platform users to vote on active parameter change proposals.
 *
 *  19. executeProposal(uint256 _proposalId) onlyOwner
 *      - Allows the contract owner to execute a passed parameter change proposal.
 *
 *  [Utility and Admin Functions]
 *  20. pauseContract() onlyOwner
 *      - Allows the contract owner to pause the contract, preventing most state-changing functions.
 *
 *  21. unpauseContract() onlyOwner
 *      - Allows the contract owner to unpause the contract, resuming normal operations.
 *
 *  22. emergencyWithdraw(address _recipient) onlyOwner
 *      - Allows the contract owner to withdraw any accidentally sent Ether to the contract.
 */

contract DecentralizedAIMarketplace {
    // --- Data Structures ---
    enum ModelAccessType { PayPerUse, Free }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    struct Model {
        uint256 id;
        address creator;
        string name;
        string description;
        string metadataURI; // URI pointing to detailed model metadata (off-chain or IPFS)
        uint256 pricePerUse;
        ModelAccessType accessType;
        bool isActive;
        uint8 ratingCount;
        uint8 totalRatingValue;
    }

    struct Review {
        uint256 modelId;
        address reviewer;
        uint8 rating; // 1 to 5 stars
        string reviewText;
        uint256 timestamp;
    }

    struct ParameterProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        uint256 voteCount;
        uint256 deadline;
        ProposalStatus status;
    }

    // --- State Variables ---
    mapping(uint256 => Model) public models; // Model ID => Model struct
    mapping(uint256 => Review[]) public modelReviews; // Model ID => Array of Reviews
    mapping(uint256 => ParameterProposal) public parameterProposals; // Proposal ID => Proposal struct
    mapping(address => uint256) public creatorEarnings; // Creator Address => Earnings Balance

    uint256 public modelCount;
    uint256 public proposalCount;
    uint256 public platformFeePercentage = 5; // Default platform fee percentage (5%)
    address public owner;
    bool public paused;

    // --- Events ---
    event ModelRegistered(uint256 modelId, address creator, string modelName);
    event ModelMetadataUpdated(uint256 modelId, string newModelName);
    event ModelPriceUpdated(uint256 modelId, uint256 newPrice);
    event ModelAccessTypeUpdated(uint256 modelId, ModelAccessType newAccessType);
    event ModelRevoked(uint256 modelId);
    event ModelAccessRequested(uint256 modelId, address user, uint256 payment);
    event ModelReviewSubmitted(uint256 modelId, address reviewer, uint8 rating);
    event EarningsWithdrawn(address creator, uint256 amount);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event EmergencyWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(models[_modelId].id != 0, "Model does not exist.");
        _;
    }

    modifier modelActive(uint256 _modelId) {
        require(models[_modelId].isActive, "Model is not active.");
        _;
    }

    modifier creatorOnly(uint256 _modelId) {
        require(models[_modelId].creator == msg.sender, "Only model creator can call this function.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        modelCount = 0;
        proposalCount = 0;
        paused = false;
    }

    // --- Model Registration and Management Functions ---
    function registerModel(
        string memory _modelName,
        string memory _modelDescription,
        string memory _modelMetadataURI,
        uint256 _pricePerUse,
        ModelAccessType _accessType
    ) external whenNotPaused {
        require(bytes(_modelName).length > 0 && bytes(_modelName).length <= 100, "Model name too long or empty.");
        require(bytes(_modelDescription).length <= 500, "Model description too long.");
        require(bytes(_modelMetadataURI).length <= 200, "Metadata URI too long.");
        require(_accessType == ModelAccessType.PayPerUse ? _pricePerUse > 0 : true, "Price must be positive for PayPerUse access.");

        modelCount++;
        models[modelCount] = Model({
            id: modelCount,
            creator: msg.sender,
            name: _modelName,
            description: _modelDescription,
            metadataURI: _modelMetadataURI,
            pricePerUse: _pricePerUse,
            accessType: _accessType,
            isActive: true,
            ratingCount: 0,
            totalRatingValue: 0
        });

        emit ModelRegistered(modelCount, msg.sender, _modelName);
    }

    function updateModelMetadata(
        uint256 _modelId,
        string memory _newModelName,
        string memory _newModelDescription,
        string memory _newModelMetadataURI
    ) external whenNotPaused modelExists(_modelId) modelActive(_modelId) creatorOnly(_modelId) {
        require(bytes(_newModelName).length > 0 && bytes(_newModelName).length <= 100, "New model name too long or empty.");
        require(bytes(_newModelDescription).length <= 500, "New model description too long.");
        require(bytes(_newModelMetadataURI).length <= 200, "New metadata URI too long.");

        models[_modelId].name = _newModelName;
        models[_modelId].description = _newModelDescription;
        models[_modelId].metadataURI = _newModelMetadataURI;

        emit ModelMetadataUpdated(_modelId, _newModelName);
    }

    function setModelPrice(uint256 _modelId, uint256 _newPricePerUse)
        external
        whenNotPaused
        modelExists(_modelId)
        modelActive(_modelId)
        creatorOnly(_modelId)
    {
        require(models[_modelId].accessType == ModelAccessType.PayPerUse, "Price can only be set for PayPerUse models.");
        require(_newPricePerUse > 0, "Price must be positive.");
        models[_modelId].pricePerUse = _newPricePerUse;
        emit ModelPriceUpdated(_modelId, _newPricePerUse);
    }

    function setModelAccessType(uint256 _modelId, ModelAccessType _newAccessType)
        external
        whenNotPaused
        modelExists(_modelId)
        modelActive(_modelId)
        creatorOnly(_modelId)
    {
        models[_modelId].accessType = _newAccessType;
        emit ModelAccessTypeUpdated(_modelId, _newAccessType);
    }

    function revokeModel(uint256 _modelId)
        external
        whenNotPaused
        modelExists(_modelId)
        modelActive(_modelId)
        creatorOnly(_modelId)
    {
        models[_modelId].isActive = false;
        emit ModelRevoked(_modelId);
    }

    // --- Model Discovery and Access Functions ---
    function getModelDetails(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (Model memory)
    {
        return models[_modelId];
    }

    function getAllModelIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](modelCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= modelCount; i++) {
            if (models[i].id != 0) { // Check if model exists (in case of deletions in future - though not implemented here)
                ids[index] = i;
                index++;
            }
        }
        // Resize array to actual number of models
        assembly {
            mstore(ids, index) // Update the length of the dynamic array
        }
        return ids;
    }


    function requestModelAccess(uint256 _modelId)
        external
        payable
        whenNotPaused
        modelExists(_modelId)
        modelActive(_modelId)
    {
        Model storage model = models[_modelId];
        if (model.accessType == ModelAccessType.PayPerUse) {
            require(msg.value >= model.pricePerUse, "Insufficient payment for model access.");
            uint256 platformFee = (model.pricePerUse * platformFeePercentage) / 100;
            uint256 creatorShare = model.pricePerUse - platformFee;
            creatorEarnings[model.creator] += creatorShare;
            payable(owner).transfer(platformFee); // Platform fee goes to contract owner
            emit ModelAccessRequested(_modelId, msg.sender, model.pricePerUse);
        } else if (model.accessType == ModelAccessType.Free) {
            emit ModelAccessRequested(_modelId, msg.sender, 0); // No payment for free access
        } else {
            revert("Invalid Model Access Type."); // Should not reach here, but for safety
        }
    }

    function checkModelAccess(uint256 _modelId, address _user)
        external
        view
        modelExists(_modelId)
        modelActive(_modelId)
        returns (bool)
    {
        // In a real-world scenario, access control might be more complex (e.g., subscriptions, whitelists).
        // For this example, access is granted upon successful payment for PayPerUse or always for Free access.
        // This function currently just returns true if the model is active and exists,
        // assuming access is granted upon requestModelAccess and this function is called after that.
        // More sophisticated access control logic could be added here (e.g., track user access per model).
        return true; // Simplified access check.  In a real application, track user access.
    }


    // --- Reputation and Rating System Functions ---
    function submitModelReview(uint256 _modelId, uint8 _rating, string memory _reviewText)
        external
        whenNotPaused
        modelExists(_modelId)
        modelActive(_modelId)
    {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(_reviewText).length <= 200, "Review text too long.");

        modelReviews[_modelId].push(Review({
            modelId: _modelId,
            reviewer: msg.sender,
            rating: _rating,
            reviewText: _reviewText,
            timestamp: block.timestamp
        }));

        models[_modelId].totalRatingValue += _rating;
        models[_modelId].ratingCount++;

        emit ModelReviewSubmitted(_modelId, msg.sender, _rating);
    }

    function getAverageModelRating(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (uint8)
    {
        if (models[_modelId].ratingCount == 0) {
            return 0; // No ratings yet
        }
        return uint8(models[_modelId].totalRatingValue / models[_modelId].ratingCount);
    }

    function getModelReviews(uint256 _modelId)
        external
        view
        modelExists(_modelId)
        returns (Review[] memory)
    {
        return modelReviews[_modelId];
    }

    // --- Revenue and Payout Management Functions ---
    function withdrawCreatorEarnings() external whenNotPaused {
        uint256 earnings = creatorEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        creatorEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(earnings);
        emit EarningsWithdrawn(msg.sender, earnings);
    }

    function getCreatorEarnings(address _creator) external view returns (uint256) {
        return creatorEarnings[_creator];
    }

    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 20, "Platform fee percentage cannot exceed 20%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    function getPlatformFee() external view onlyOwner returns (uint256) {
        return platformFeePercentage;
    }

    // --- Governance and Platform Parameter Change Functions ---
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external whenNotPaused {
        require(bytes(_parameterName).length > 0 && bytes(_parameterName).length <= 50, "Parameter name invalid.");
        proposalCount++;
        parameterProposals[proposalCount] = ParameterProposal({
            id: proposalCount,
            parameterName: _parameterName,
            newValue: _newValue,
            voteCount: 0,
            deadline: block.timestamp + 7 days, // Proposal deadline in 7 days
            status: ProposalStatus.Pending
        });
        emit ParameterProposalCreated(proposalCount, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(parameterProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.timestamp < parameterProposals[_proposalId].deadline, "Voting deadline passed.");

        // In a real governance system, you would likely track individual votes to prevent double voting
        // and potentially implement voting power based on token holdings or reputation.
        // For simplicity, here we just increment a vote count.
        if (_vote) {
            parameterProposals[_proposalId].voteCount++;
        } else {
            // Optionally track negative votes if needed. For now, just positive votes needed to pass.
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(parameterProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.timestamp >= parameterProposals[_proposalId].deadline, "Voting deadline not reached.");

        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (proposal.voteCount > 0) { // Simple majority for approval (adjust logic as needed)
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("platformFeePercentage"))) {
                setPlatformFee(uint256(proposal.newValue)); // Example: Only parameter changeable via governance for now
            } else {
                revert("Unknown parameter for governance.");
            }
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    // --- Utility and Admin Functions ---
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function emergencyWithdraw(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address.");
        uint256 balance = address(this).balance;
        payable(_recipient).transfer(balance);
        emit EmergencyWithdrawal(_recipient, balance);
    }

    // Fallback function to prevent accidental Ether sent to contract from being stuck
    receive() external payable {}
}
```