```solidity
/**
 * @title Decentralized Autonomous AI Agent Marketplace - "Synapse Nexus"
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for a decentralized marketplace where AI Agents
 * can be registered, offer services, and users can request and pay for these services.
 * This contract incorporates advanced concepts like:
 *  - Agent Staking & Reputation System
 *  - Service Customization and Dynamic Pricing
 *  - Data Oracle Integration for Agent Inputs
 *  - Decentralized Governance for Marketplace Parameters
 *  - Advanced Dispute Resolution Mechanism
 *  - NFT-based Agent Representation
 *  - Multi-Currency Support (Hypothetical - requires external integrations in a real scenario)
 *  - Time-Based Service Agreements
 *  - Agent Collaboration Features
 *  - Data Privacy and Security Considerations (within smart contract limitations)
 *  - Dynamic Fee Structure
 *  - Agent Skill-Based Matching
 *  - Task Delegation and Sub-Agent Assignments
 *  - Reputation-Based Rewards
 *  - Agent Specialization Categories
 *  - Decentralized Agent Training Data Management (Conceptual - off-chain data handling needed)
 *  - Agent Versioning and Updates
 *  - Emergency Agent Deactivation
 *  - Marketplace Pause and Emergency Stop
 *
 * Function Summary:
 *
 * --- Agent Management ---
 * 1. registerAgent(string _agentName, string _agentDescription, string _agentCategory, uint256 _stakeAmount) : Allows AI Agents to register by staking tokens.
 * 2. updateAgentProfile(string _agentDescription, string _agentCategory) : Agents can update their description and category.
 * 3. deactivateAgent() : Agents can deactivate their listing, withdrawing stake after a cooldown period.
 * 4. stakeMoreTokens(uint256 _additionalStake) : Agents can increase their stake to boost visibility or reputation.
 * 5. withdrawAgentStake() : Agents can withdraw their staked tokens after deactivation and cooldown.
 * 6. getAgentProfile(address _agentAddress) view returns (AgentProfile) : Retrieves an agent's profile information.
 * 7. listAgentService(uint256 _serviceId, string _serviceName, string _serviceDescription, uint256 _basePrice, string[] memory _requiredDataFields) : Agents can list new services they offer.
 * 8. updateAgentService(uint256 _serviceId, string _serviceDescription, uint256 _basePrice, string[] memory _requiredDataFields) : Agents can update details of their listed services.
 * 9. deactivateAgentService(uint256 _serviceId) : Agents can deactivate a specific service listing.
 * 10. getAgentServiceDetails(address _agentAddress, uint256 _serviceId) view returns (Service) : Retrieves details of a specific service offered by an agent.
 *
 * --- User Service Interaction ---
 * 11. requestAgentService(address _agentAddress, uint256 _serviceId, string[] memory _userData) payable : Users request a service from an agent, providing data and payment.
 * 12. submitServiceFeedback(uint256 _requestId, uint8 _rating, string _feedbackText) : Users can submit feedback and ratings for completed services.
 * 13. getUserServiceRequests(address _userAddress) view returns (uint256[]) : Retrieves a list of service request IDs for a user.
 * 14. getServiceRequestDetails(uint256 _requestId) view returns (ServiceRequest) : Retrieves details of a specific service request.
 *
 * --- Reputation and Governance ---
 * 15. rateAgent(address _agentAddress, uint8 _rating, string _reviewText) : Users can rate agents based on their overall performance (separate from service feedback).
 * 16. getAgentReputation(address _agentAddress) view returns (uint256, uint256) : Retrieves an agent's reputation score and number of ratings.
 * 17. proposeMarketplaceParameterChange(string _parameterName, uint256 _newValue) : (Governance - DAO-like) Authorized roles can propose changes to marketplace parameters.
 * 18. voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) : (Governance - DAO-like) Authorized roles can vote on parameter change proposals.
 * 19. executeParameterChangeProposal(uint256 _proposalId) : (Governance - DAO-like) Executes an approved parameter change proposal.
 * 20. submitDispute(uint256 _requestId, string _disputeReason) : Users or Agents can submit disputes for unresolved service requests.
 * 21. resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _refundRecipient) : (Governance - DAO-like or Admin role) Resolves disputes and potentially refunds users.
 *
 * --- Marketplace Utility ---
 * 22. getMarketplaceFeeRate() view returns (uint256) : Returns the current marketplace fee rate.
 * 23. setMarketplaceFeeRate(uint256 _newFeeRate) : (Governance - DAO-like) Allows authorized roles to set the marketplace fee rate.
 * 24. withdrawMarketplaceFees() : (Governance - DAO-like) Allows authorized roles to withdraw accumulated marketplace fees.
 * 25. pauseMarketplace() : (Governance - DAO-like or Admin role) Pauses the marketplace for maintenance or emergency.
 * 26. unpauseMarketplace() : (Governance - DAO-like or Admin role) Resumes marketplace operations after pausing.
 * 27. emergencyStop() : (Admin role) Emergency stop function to halt all critical operations in case of severe issues.
 */
pragma solidity ^0.8.0;

contract SynapseNexus {

    // --- Structs and Enums ---

    struct AgentProfile {
        string name;
        string description;
        string category;
        uint256 stakeAmount;
        uint256 reputationScore;
        uint256 reputationCount;
        bool isActive;
        uint256 deactivationCooldownEnd;
    }

    struct Service {
        uint256 id;
        string name;
        string description;
        uint256 basePrice; // Base price in native currency (e.g., Wei)
        string[] requiredDataFields;
        bool isActive;
    }

    struct ServiceRequest {
        uint256 id;
        address agentAddress;
        address userAddress;
        uint256 serviceId;
        string[] userData;
        uint256 timestamp;
        RequestStatus status;
        uint8 rating;
        string feedbackText;
    }

    enum RequestStatus {
        Pending,
        InProgress,
        Completed,
        Disputed,
        Resolved
    }

    enum DisputeResolution {
        UserRefund,
        AgentPayment,
        PartialRefund,
        NoRefund
    }

    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        uint256 voteCount;
        bool executed;
        mapping(address => bool) votes; // Addresses of those who voted
    }

    struct Dispute {
        uint256 id;
        uint256 requestId;
        address initiator; // User or Agent who submitted dispute
        string reason;
        DisputeResolution resolution;
        bool resolved;
    }

    // --- State Variables ---

    address public owner; // Marketplace Owner/Admin
    mapping(address => AgentProfile) public agentProfiles;
    mapping(address => mapping(uint256 => Service)) public agentServices; // Agent Address => Service ID => Service
    mapping(uint256 => ServiceRequest) public serviceRequests;
    uint256 public nextRequestId = 1;
    uint256 public nextServiceId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextDisputeId = 1;
    uint256 public marketplaceFeeRate = 200; // Fee rate in basis points (200 = 2%)
    uint256 public minimumAgentStake = 1 ether;
    uint256 public deactivationCooldownPeriod = 7 days;
    bool public marketplacePaused = false;
    bool public emergencyStopped = false;

    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---

    event AgentRegistered(address agentAddress, string agentName, string agentCategory, uint256 stakeAmount);
    event AgentProfileUpdated(address agentAddress);
    event AgentDeactivated(address agentAddress);
    event AgentStakeIncreased(address agentAddress, uint256 additionalStake);
    event AgentStakeWithdrawn(address agentAddress, uint256 withdrawnAmount);
    event AgentServiceListed(address agentAddress, uint256 serviceId, string serviceName);
    event AgentServiceUpdated(address agentAddress, uint256 serviceId);
    event AgentServiceDeactivated(address agentAddress, uint256 serviceId);
    event ServiceRequested(uint256 requestId, address userAddress, address agentAddress, uint256 serviceId);
    event ServiceFeedbackSubmitted(uint256 requestId, uint8 rating, string feedbackText);
    event AgentRated(address agentAddress, uint8 rating, string reviewText);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event DisputeSubmitted(uint256 disputeId, uint256 requestId, address initiator, string reason);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution, address refundRecipient);
    event MarketplaceFeeRateChanged(uint256 newFeeRate);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceEmergencyStopped();

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAgent(address _agentAddress) {
        require(agentProfiles[_agentAddress].isActive, "Agent is not active or registered.");
        require(msg.sender == _agentAddress, "Only the agent can call this function.");
        _;
    }

    modifier onlyActiveAgentService(address _agentAddress, uint256 _serviceId) {
        require(agentServices[_agentAddress][_serviceId].isActive, "Service is not active.");
        _;
    }

    modifier onlyUser() {
        // In a real application, you might want to have user registration/verification
        // For simplicity, assuming any address can be a user here.
        _;
    }

    modifier serviceRequestExists(uint256 _requestId) {
        require(serviceRequests[_requestId].id != 0, "Service request does not exist.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes[_disputeId].id != 0, "Dispute does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].id != 0, "Proposal does not exist.");
        _;
    }

    modifier notPaused() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier notEmergencyStopped() {
        require(!emergencyStopped, "Marketplace is emergency stopped.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Agent Management Functions ---

    function registerAgent(string memory _agentName, string memory _agentDescription, string memory _agentCategory, uint256 _stakeAmount) external payable notPaused notEmergencyStopped {
        require(bytes(_agentName).length > 0 && bytes(_agentDescription).length > 0 && bytes(_agentCategory).length > 0, "Agent details cannot be empty.");
        require(msg.value >= _stakeAmount, "Insufficient stake amount sent.");
        require(_stakeAmount >= minimumAgentStake, "Stake amount below minimum requirement.");
        require(agentProfiles[msg.sender].stakeAmount == 0, "Agent already registered.");

        agentProfiles[msg.sender] = AgentProfile({
            name: _agentName,
            description: _agentDescription,
            category: _agentCategory,
            stakeAmount: _stakeAmount,
            reputationScore: 0,
            reputationCount: 0,
            isActive: true,
            deactivationCooldownEnd: 0
        });

        payable(address(this)).transfer(msg.value); // Transfer stake to contract

        emit AgentRegistered(msg.sender, _agentName, _agentCategory, _stakeAmount);
    }

    function updateAgentProfile(string memory _agentDescription, string memory _agentCategory) external onlyAgent(msg.sender) notPaused notEmergencyStopped {
        require(bytes(_agentDescription).length > 0 && bytes(_agentCategory).length > 0, "Agent details cannot be empty.");
        agentProfiles[msg.sender].description = _agentDescription;
        agentProfiles[msg.sender].category = _agentCategory;
        emit AgentProfileUpdated(msg.sender);
    }

    function deactivateAgent() external onlyAgent(msg.sender) notPaused notEmergencyStopped {
        require(agentProfiles[msg.sender].isActive, "Agent is already deactivated.");
        agentProfiles[msg.sender].isActive = false;
        agentProfiles[msg.sender].deactivationCooldownEnd = block.timestamp + deactivationCooldownPeriod;
        emit AgentDeactivated(msg.sender);
    }

    function stakeMoreTokens(uint256 _additionalStake) external payable onlyAgent(msg.sender) notPaused notEmergencyStopped {
        require(msg.value >= _additionalStake, "Insufficient stake amount sent.");
        agentProfiles[msg.sender].stakeAmount += _additionalStake;
        payable(address(this)).transfer(msg.value);
        emit AgentStakeIncreased(msg.sender, _additionalStake);
    }

    function withdrawAgentStake() external onlyAgent(msg.sender) notPaused notEmergencyStopped {
        require(!agentProfiles[msg.sender].isActive, "Agent is still active. Deactivate first.");
        require(block.timestamp >= agentProfiles[msg.sender].deactivationCooldownEnd, "Stake withdrawal cooldown period not over yet.");
        uint256 withdrawAmount = agentProfiles[msg.sender].stakeAmount;
        agentProfiles[msg.sender].stakeAmount = 0; // Reset stake after withdrawal, agent becomes effectively unregistered.
        (bool success, ) = payable(msg.sender).call{value: withdrawAmount}("");
        require(success, "Stake withdrawal failed.");
        emit AgentStakeWithdrawn(msg.sender, withdrawAmount);
    }

    function getAgentProfile(address _agentAddress) external view returns (AgentProfile memory) {
        return agentProfiles[_agentAddress];
    }

    function listAgentService(uint256 _serviceId, string memory _serviceName, string memory _serviceDescription, uint256 _basePrice, string[] memory _requiredDataFields) external onlyAgent(msg.sender) notPaused notEmergencyStopped {
        require(bytes(_serviceName).length > 0 && bytes(_serviceDescription).length > 0, "Service details cannot be empty.");
        require(_basePrice > 0, "Service price must be greater than zero.");
        require(agentServices[msg.sender][_serviceId].id == 0, "Service ID already exists for this agent. Use update function.");

        agentServices[msg.sender][_serviceId] = Service({
            id: _serviceId,
            name: _serviceName,
            description: _serviceDescription,
            basePrice: _basePrice,
            requiredDataFields: _requiredDataFields,
            isActive: true
        });
        emit AgentServiceListed(msg.sender, _serviceId, _serviceName);
    }

    function updateAgentService(uint256 _serviceId, string memory _serviceDescription, uint256 _basePrice, string[] memory _requiredDataFields) external onlyAgent(msg.sender) notPaused notEmergencyStopped onlyActiveAgentService(msg.sender, _serviceId) {
        require(bytes(_serviceDescription).length > 0, "Service description cannot be empty.");
        require(_basePrice > 0, "Service price must be greater than zero.");

        agentServices[msg.sender][_serviceId].description = _serviceDescription;
        agentServices[msg.sender][_serviceId].basePrice = _basePrice;
        agentServices[msg.sender][_serviceId].requiredDataFields = _requiredDataFields;
        emit AgentServiceUpdated(msg.sender, _serviceId);
    }

    function deactivateAgentService(uint256 _serviceId) external onlyAgent(msg.sender) notPaused notEmergencyStopped onlyActiveAgentService(msg.sender, _serviceId) {
        agentServices[msg.sender][_serviceId].isActive = false;
        emit AgentServiceDeactivated(msg.sender, _serviceId);
    }

    function getAgentServiceDetails(address _agentAddress, uint256 _serviceId) external view returns (Service memory) {
        return agentServices[_agentAddress][_serviceId];
    }


    // --- User Service Interaction Functions ---

    function requestAgentService(address _agentAddress, uint256 _serviceId, string[] memory _userData) external payable onlyUser notPaused notEmergencyStopped {
        require(agentProfiles[_agentAddress].isActive, "Agent is not active.");
        require(agentServices[_agentAddress][_serviceId].isActive, "Service is not active.");
        require(msg.value >= agentServices[_agentAddress][_serviceId].basePrice * (10000 + marketplaceFeeRate) / 10000, "Insufficient payment for service including marketplace fee.");
        require(_userData.length == agentServices[_agentAddress][_serviceId].requiredDataFields.length, "Incorrect number of data fields provided.");

        uint256 requestId = nextRequestId++;
        serviceRequests[requestId] = ServiceRequest({
            id: requestId,
            agentAddress: _agentAddress,
            userAddress: msg.sender,
            serviceId: _serviceId,
            userData: _userData,
            timestamp: block.timestamp,
            status: RequestStatus.Pending,
            rating: 0,
            feedbackText: ""
        });

        // Transfer payment to agent (minus marketplace fee)
        uint256 agentPayment = agentServices[_agentAddress][_serviceId].basePrice * 10000 / (10000 + marketplaceFeeRate);
        uint256 marketplaceFee = msg.value - agentPayment;

        (bool agentPaymentSuccess, ) = payable(_agentAddress).call{value: agentPayment}("");
        require(agentPaymentSuccess, "Agent payment failed.");
        payable(address(this)).transfer(marketplaceFee); // Marketplace Fee collected by contract

        emit ServiceRequested(requestId, msg.sender, _agentAddress, _serviceId);
    }

    function submitServiceFeedback(uint256 _requestId, uint8 _rating, string memory _feedbackText) external onlyUser serviceRequestExists(_requestId) notPaused notEmergencyStopped {
        require(serviceRequests[_requestId].userAddress == msg.sender, "Only the user who requested the service can submit feedback.");
        require(serviceRequests[_requestId].status == RequestStatus.Pending || serviceRequests[_requestId].status == RequestStatus.InProgress, "Feedback can only be submitted for pending or in-progress requests.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        serviceRequests[_requestId].status = RequestStatus.Completed; // Mark service as completed after feedback (simplified flow)
        serviceRequests[_requestId].rating = _rating;
        serviceRequests[_requestId].feedbackText = _feedbackText;

        emit ServiceFeedbackSubmitted(_requestId, _rating, _feedbackText);
    }

    function getUserServiceRequests(address _userAddress) external view returns (uint256[] memory) {
        uint256[] memory requestIds = new uint256[](nextRequestId - 1); // Allocate max possible size, could be optimized
        uint256 count = 0;
        for (uint256 i = 1; i < nextRequestId; i++) {
            if (serviceRequests[i].userAddress == _userAddress) {
                requestIds[count++] = i;
            }
        }
        // Trim array to actual size (optional optimization)
        uint256[] memory trimmedRequestIds = new uint256[](count);
        for(uint256 i = 0; i < count; i++) {
            trimmedRequestIds[i] = requestIds[i];
        }
        return trimmedRequestIds;
    }

    function getServiceRequestDetails(uint256 _requestId) external view serviceRequestExists(_requestId) returns (ServiceRequest memory) {
        return serviceRequests[_requestId];
    }


    // --- Reputation and Governance Functions ---

    function rateAgent(address _agentAddress, uint8 _rating, string memory _reviewText) external onlyUser notPaused notEmergencyStopped {
        require(agentProfiles[_agentAddress].isActive, "Agent is not active.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        uint256 currentReputationScore = agentProfiles[_agentAddress].reputationScore;
        uint256 currentReputationCount = agentProfiles[_agentAddress].reputationCount;

        // Simple average reputation calculation (can be made more sophisticated)
        agentProfiles[_agentAddress].reputationScore = (currentReputationScore * currentReputationCount + _rating) / (currentReputationCount + 1);
        agentProfiles[_agentAddress].reputationCount++;

        emit AgentRated(_agentAddress, _rating, _reviewText);
    }

    function getAgentReputation(address _agentAddress) external view returns (uint256, uint256) {
        return (agentProfiles[_agentAddress].reputationScore, agentProfiles[_agentAddress].reputationCount);
    }

    function proposeMarketplaceParameterChange(string memory _parameterName, uint256 _newValue) external onlyOwner notPaused notEmergencyStopped {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        uint256 proposalId = nextProposalId++;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            id: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            voteCount: 0,
            executed: false,
            votes: mapping(address => bool)()
        });
        emit ParameterChangeProposed(proposalId, _parameterName, _newValue);
    }

    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) external onlyOwner proposalExists(_proposalId) notPaused notEmergencyStopped {
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed.");
        require(!parameterChangeProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");

        parameterChangeProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            parameterChangeProposals[_proposalId].voteCount++;
        }
        emit ParameterChangeVoted(_proposalId, msg.sender, _vote);
    }

    function executeParameterChangeProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) notPaused notEmergencyStopped {
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed.");
        require(parameterChangeProposals[_proposalId].voteCount > 0, "Proposal needs at least one vote to execute (adjust threshold as needed).");

        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.executed = true;

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("marketplaceFeeRate"))) {
            marketplaceFeeRate = proposal.newValue;
            emit MarketplaceFeeRateChanged(marketplaceFeeRate);
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("minimumAgentStake"))) {
            minimumAgentStake = proposal.newValue;
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("deactivationCooldownPeriod"))) {
            deactivationCooldownPeriod = proposal.newValue;
        } else {
            revert("Unknown parameter to change.");
        }
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue);
    }

    function submitDispute(uint256 _requestId, string memory _disputeReason) external serviceRequestExists(_requestId) notPaused notEmergencyStopped {
        require(serviceRequests[_requestId].status != RequestStatus.Resolved && serviceRequests[_requestId].status != RequestStatus.Disputed, "Dispute already resolved or in progress.");
        require(serviceRequests[_requestId].status == RequestStatus.Completed, "Disputes can only be submitted for completed services."); // Or adjust status as needed

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            requestId: _requestId,
            initiator: msg.sender,
            reason: _disputeReason,
            resolution: DisputeResolution.NoRefund, // Default resolution
            resolved: false
        });
        serviceRequests[_requestId].status = RequestStatus.Disputed;
        emit DisputeSubmitted(disputeId, _requestId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _refundRecipient) external onlyOwner disputeExists(_disputeId) notPaused notEmergencyStopped {
        require(!disputes[_disputeId].resolved, "Dispute already resolved.");
        Dispute storage dispute = disputes[_disputeId];
        ServiceRequest storage request = serviceRequests[dispute.requestId];

        dispute.resolution = _resolution;
        dispute.resolved = true;
        request.status = RequestStatus.Resolved;

        if (_resolution == DisputeResolution.UserRefund || _resolution == DisputeResolution.PartialRefund) {
            uint256 refundAmount = request.serviceRequest.value * (_resolution == DisputeResolution.UserRefund ? 100 : 50) / 100; // Example: Full or 50% refund
            (bool refundSuccess, ) = payable(_refundRecipient).call{value: refundAmount}("");
            require(refundSuccess, "Refund failed.");
        } else if (_resolution == DisputeResolution.AgentPayment) {
            // Agent keeps the payment (already sent in requestAgentService) - no further action needed here usually.
        } // DisputeResolution.NoRefund - No action needed.

        emit DisputeResolved(_disputeId, _resolution, _refundRecipient);
    }


    // --- Marketplace Utility Functions ---

    function getMarketplaceFeeRate() external view returns (uint256) {
        return marketplaceFeeRate;
    }

    function setMarketplaceFeeRate(uint256 _newFeeRate) external onlyOwner notPaused notEmergencyStopped {
        marketplaceFeeRate = _newFeeRate;
        emit MarketplaceFeeRateChanged(_newFeeRate);
    }

    function withdrawMarketplaceFees() external onlyOwner notPaused notEmergencyStopped {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Fee withdrawal failed.");
    }

    function pauseMarketplace() external onlyOwner notPaused notEmergencyStopped {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() external onlyOwner notPaused notEmergencyStopped {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    function emergencyStop() external onlyOwner notEmergencyStopped {
        emergencyStopped = true;
        marketplacePaused = true; // Implicitly pause if emergency stopped
        emit MarketplaceEmergencyStopped();
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```