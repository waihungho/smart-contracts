```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative AI Model Training
 * @author Gemini AI (Example - Conceptual Contract)
 * @notice This contract outlines a DAO for collaborative AI model training, enabling decentralized participation, governance, and reward distribution.
 * @dev This is a conceptual example and requires further development for production use, including security audits and gas optimization.
 *
 * Function Summary:
 * 1.  joinDAO:              Allows users to join the DAO by staking a certain amount of governance tokens.
 * 2.  leaveDAO:             Allows members to leave the DAO and unstake their governance tokens.
 * 3.  updateProfile:        Allows members to update their profile information (e.g., skills, interests).
 * 4.  createProposal:       Allows members to create proposals for various DAO actions (e.g., funding, model training).
 * 5.  voteOnProposal:       Allows members to vote on active proposals using their governance tokens.
 * 6.  executeProposal:      Executes a proposal if it passes the voting threshold.
 * 7.  cancelProposal:       Allows the proposer to cancel a proposal before voting starts under certain conditions.
 * 8.  uploadDataset:        Allows members to upload datasets for AI model training, earning reputation and potential rewards.
 * 9.  accessDataset:        Allows approved members to access datasets for training purposes.
 * 10. rewardDataContribution: Distributes rewards to data contributors based on dataset usage and quality (governance-determined).
 * 11. registerComputeResource: Allows members to register their compute resources for model training tasks.
 * 12. allocateComputeTask:  Allocates compute tasks to registered compute resources based on availability and performance.
 * 13. rewardComputeContribution: Distributes rewards to compute providers based on task completion and resource utilization.
 * 14. initiateModelTraining: Allows approved members to initiate AI model training runs with specified datasets and configurations.
 * 15. reportTrainingProgress: Allows trainers to report progress on model training tasks.
 * 16. finalizeModelTraining: Finalizes a model training run, making the trained model (or its metadata/NFT) available.
 * 17. mintModelNFT:         Mints an NFT representing a trained AI model, potentially with royalty rights and usage permissions.
 * 18. getModelDetails:      Retrieves details of a trained AI model, including metadata, performance metrics, and NFT information.
 * 19. depositFunds:         Allows members to deposit funds into the DAO treasury for various purposes (e.g., rewards, development).
 * 20. withdrawFunds:        Allows members to withdraw their funds from the DAO treasury (subject to governance or specific conditions).
 * 21. distributeRewards:    Distributes accumulated rewards to eligible members based on their contributions and DAO rules.
 * 22. getTreasuryBalance:   Retrieves the current balance of the DAO treasury.
 * 23. setGovernanceParameters: Allows governors to update key governance parameters (e.g., voting thresholds, reward rates).
 * 24. pauseContract:        Allows governors to pause certain critical functions of the contract in emergency situations.
 * 25. unpauseContract:      Allows governors to unpause the contract after a pause.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AIDao is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    string public daoName;
    IERC20 public governanceToken; // Governance token contract address
    uint256 public stakingAmountToJoin; // Amount of governance tokens to stake to join DAO
    uint256 public votingPeriod; // Default voting period for proposals in blocks
    uint256 public quorumPercentage; // Percentage of total members required for quorum
    uint256 public proposalPassingPercentage; // Percentage of votes needed to pass a proposal
    uint256 public dataRewardPool; // Pool of tokens for rewarding data contributions
    uint256 public computeRewardPool; // Pool of tokens for rewarding compute contributions

    struct Member {
        address walletAddress;
        uint256 stakedTokens;
        string profileInfo; // JSON or similar for profile details
        uint256 reputationScore; // Could be used for voting power or reward multipliers
        bool isActive;
    }

    mapping(address => Member) public members;
    EnumerableSet.AddressSet private memberAddresses;
    Counters.Counter private memberCount;

    enum ProposalState { Pending, Active, Passed, Rejected, Executed, Cancelled }
    enum ProposalType { General, Funding, ModelTraining, GovernanceChange }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string title;
        string description;
        uint256 votingStartTime;
        uint256 votingEndTime;
        ProposalState state;
        uint256 votesFor;
        uint256 votesAgainst;
        bytes dataPayload; // Flexible data for proposal execution
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private proposalCount;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    struct Dataset {
        uint256 datasetId;
        address uploader;
        string datasetName;
        string datasetDescription;
        string datasetCID; // IPFS CID or similar for data location
        uint256 uploadTimestamp;
        uint256 accessCount;
        uint256 qualityScore; // Governance-voted quality score
    }

    mapping(uint256 => Dataset) public datasets;
    Counters.Counter private datasetCount;
    mapping(uint256 => EnumerableSet.AddressSet) public datasetAccessList; // datasetId => Set of addresses with access

    struct ComputeResource {
        address providerAddress;
        string resourceName;
        string resourceDescription;
        uint256 computePower; // e.g., FLOPS, CPU cores, etc.
        bool isAvailable;
        uint256 registrationTimestamp;
    }

    mapping(address => ComputeResource) public computeResources;
    EnumerableSet.AddressSet private computeProviderAddresses;

    struct TrainingRun {
        uint256 trainingRunId;
        address initiator;
        uint256 datasetId;
        string modelConfiguration; // JSON or similar for model parameters
        uint256 startTime;
        uint256 endTime;
        string modelCID; // IPFS CID for trained model weights
        bool isFinalized;
    }

    mapping(uint256 => TrainingRun) public trainingRuns;
    Counters.Counter private trainingRunCount;

    Counters.Counter private modelNftCounter;

    bool public paused;

    // --- Events ---

    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event ProfileUpdated(address memberAddress);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event DatasetUploaded(uint256 datasetId, address uploader);
    event DatasetAccessed(uint256 datasetId, address accessor);
    event ComputeResourceRegistered(address providerAddress);
    event ComputeTaskAllocated(address providerAddress, uint256 trainingRunId);
    event TrainingRunInitiated(uint256 trainingRunId, address initiator);
    event TrainingProgressReported(uint256 trainingRunId, string progressUpdate);
    event TrainingRunFinalized(uint256 trainingRunId, string modelCID);
    event ModelNftMinted(uint256 tokenId, uint256 trainingRunId);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);
    event RewardsDistributed(address recipient, uint256 amount, string reason);
    event GovernanceParametersUpdated(string parameterName, uint256 newValue);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);


    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Not an active DAO member");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == owner(), "Only DAO governor (owner) can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }


    // --- Constructor ---

    constructor(
        string memory _daoName,
        address _governanceTokenAddress,
        uint256 _stakingAmount,
        uint256 _votingPeriodBlocks,
        uint256 _quorumPercentage,
        uint256 _proposalPassingPercentage
    ) ERC721(_daoName + " Model NFTs", "AIDMNFT") {
        daoName = _daoName;
        governanceToken = IERC20(_governanceTokenAddress);
        stakingAmountToJoin = _stakingAmount;
        votingPeriod = _votingPeriodBlocks;
        quorumPercentage = _quorumPercentage;
        proposalPassingPercentage = _proposalPassingPercentage;
        paused = false; // Contract starts unpaused
    }


    // --- Membership Functions ---

    /// @notice Allows users to join the DAO by staking governance tokens.
    function joinDAO(string memory _profileInfo) external whenNotPaused nonReentrant {
        require(!members[msg.sender].isActive, "Already a DAO member");
        require(governanceToken.allowance(msg.sender, address(this)) >= stakingAmountToJoin, "Approve governance tokens first");

        governanceToken.transferFrom(msg.sender, address(this), stakingAmountToJoin);
        members[msg.sender] = Member({
            walletAddress: msg.sender,
            stakedTokens: stakingAmountToJoin,
            profileInfo: _profileInfo,
            reputationScore: 0, // Initial reputation
            isActive: true
        });
        memberAddresses.add(msg.sender);
        memberCount.increment();
        emit MemberJoined(msg.sender);
    }

    /// @notice Allows members to leave the DAO and unstake their governance tokens.
    function leaveDAO() external onlyMember whenNotPaused nonReentrant {
        require(members[msg.sender].isActive, "Not an active DAO member");

        uint256 stakedAmount = members[msg.sender].stakedTokens;
        members[msg.sender].isActive = false;
        memberAddresses.remove(msg.sender);
        memberCount.decrement();
        delete members[msg.sender]; // Clean up member data
        governanceToken.transfer(msg.sender, stakedAmount);
        emit MemberLeft(msg.sender);
    }

    /// @notice Allows members to update their profile information.
    function updateProfile(string memory _newProfileInfo) external onlyMember whenNotPaused {
        members[msg.sender].profileInfo = _newProfileInfo;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Retrieves information about a specific DAO member.
    function getMemberInfo(address _memberAddress) external view returns (Member memory) {
        return members[_memberAddress];
    }

    /// @notice Returns the total count of active DAO members.
    function getMemberCount() external view returns (uint256) {
        return memberCount.current();
    }


    // --- Governance Functions ---

    /// @notice Allows members to create proposals for DAO actions.
    function createProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _dataPayload
    ) external onlyMember whenNotPaused {
        proposalCount.increment();
        uint256 proposalId = proposalCount.current();
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: _proposalType,
            proposer: msg.sender,
            title: _title,
            description: _description,
            votingStartTime: 0, // Set when voting starts
            votingEndTime: 0,
            state: ProposalState.Pending,
            votesFor: 0,
            votesAgainst: 0,
            dataPayload: _dataPayload
        });
        emit ProposalCreated(proposalId, _proposalType, msg.sender);
    }

    /// @notice Starts voting for a specific proposal. Only callable by governor initially, could be changed to DAO-governed start.
    function startProposalVoting(uint256 _proposalId) external onlyGovernor whenNotPaused {
        require(proposals[_proposalId].state == ProposalState.Pending, "Proposal voting already started or not pending");
        proposals[_proposalId].state = ProposalState.Active;
        proposals[_proposalId].votingStartTime = block.number;
        proposals[_proposalId].votingEndTime = block.number + votingPeriod;
    }

    /// @notice Allows members to vote on active proposals.
    function voteOnProposal(uint256 _proposalId, bool _voteFor) external onlyMember whenNotPaused {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active for voting");
        require(block.number <= proposals[_proposalId].votingEndTime, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");

        hasVoted[_proposalId][msg.sender] = true;
        if (_voteFor) {
            proposals[_proposalId].votesFor += 1;
        } else {
            proposals[_proposalId].votesAgainst += 1;
        }
        emit VoteCast(_proposalId, msg.sender, _voteFor);
    }

    /// @notice Executes a proposal if it has passed the voting and quorum requirements.
    function executeProposal(uint256 _proposalId) external onlyGovernor whenNotPaused nonReentrant {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.number > proposals[_proposalId].votingEndTime, "Voting period has not ended");
        require(proposals[_proposalId].state != ProposalState.Executed, "Proposal already executed");

        uint256 totalMembers = memberCount.current();
        uint256 quorum = (totalMembers * quorumPercentage) / 100;
        require(proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst >= quorum, "Quorum not reached");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 passingVotesNeeded = (totalVotes * proposalPassingPercentage) / 100;

        if (proposals[_proposalId].votesFor >= passingVotesNeeded) {
            proposals[_proposalId].state = ProposalState.Executed;
            // TODO: Implement proposal execution logic based on proposalType and dataPayload
            // This is where you would call other contract functions or perform actions
            // based on the approved proposal.
            emit ProposalExecuted(_proposalId);
        } else {
            proposals[_proposalId].state = ProposalState.Rejected;
        }
    }

    /// @notice Allows the proposer to cancel a proposal before voting starts.
    function cancelProposal(uint256 _proposalId) external onlyMember whenNotPaused {
        require(proposals[_proposalId].state == ProposalState.Pending, "Proposal voting already started or not pending");
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can cancel");
        proposals[_proposalId].state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Retrieves details of a specific proposal.
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Gets the current proposal count.
    function getProposalCount() external view returns (uint256) {
        return proposalCount.current();
    }


    // --- Data Management Functions ---

    /// @notice Allows members to upload datasets for AI model training.
    function uploadDataset(
        string memory _datasetName,
        string memory _datasetDescription,
        string memory _datasetCID // IPFS CID or similar
    ) external onlyMember whenNotPaused {
        datasetCount.increment();
        uint256 datasetId = datasetCount.current();
        datasets[datasetId] = Dataset({
            datasetId: datasetId,
            uploader: msg.sender,
            datasetName: _datasetName,
            datasetDescription: _datasetDescription,
            datasetCID: _datasetCID,
            uploadTimestamp: block.timestamp,
            accessCount: 0,
            qualityScore: 0 // Initial quality score, to be voted on later
        });
        emit DatasetUploaded(datasetId, msg.sender);
    }

    /// @notice Allows approved members to access datasets. Access control could be improved with roles or governance.
    function accessDataset(uint256 _datasetId) external onlyMember whenNotPaused {
        require(datasets[_datasetId].datasetId != 0, "Dataset does not exist");
        // Basic access control - for now, any member can access.
        // In a real system, access would be more controlled, possibly through proposals.
        datasets[_datasetId].accessCount++;
        emit DatasetAccessed(_datasetId, msg.sender);
    }

    /// @notice Rewards data contributors based on dataset usage and quality (governance-determined).
    function rewardDataContribution(uint256 _datasetId, uint256 _rewardAmount) external onlyGovernor whenNotPaused {
        require(datasets[_datasetId].datasetId != 0, "Dataset does not exist");
        require(dataRewardPool >= _rewardAmount, "Not enough funds in data reward pool");

        address dataContributor = datasets[_datasetId].uploader;
        dataRewardPool -= _rewardAmount;
        // TODO: Consider more complex reward distribution logic based on quality, access count, etc.
        // For now, simple transfer.
        governanceToken.transfer(dataContributor, _rewardAmount);
        emit RewardsDistributed(dataContributor, _rewardAmount, "Dataset contribution reward");
    }

    /// @notice Retrieves details of a specific dataset.
    function getDatasetDetails(uint256 _datasetId) external view returns (Dataset memory) {
        return datasets[_datasetId];
    }

    /// @notice Gets the current dataset count.
    function getDatasetCount() external view returns (uint256) {
        return datasetCount.current();
    }


    // --- Compute Resource Management Functions ---

    /// @notice Allows members to register their compute resources for model training tasks.
    function registerComputeResource(
        string memory _resourceName,
        string memory _resourceDescription,
        uint256 _computePower
    ) external onlyMember whenNotPaused {
        require(computeResources[msg.sender].providerAddress == address(0), "Compute resource already registered");
        computeResources[msg.sender] = ComputeResource({
            providerAddress: msg.sender,
            resourceName: _resourceName,
            resourceDescription: _resourceDescription,
            computePower: _computePower,
            isAvailable: true,
            registrationTimestamp: block.timestamp
        });
        computeProviderAddresses.add(msg.sender);
        emit ComputeResourceRegistered(msg.sender);
    }

    /// @notice Allocates compute tasks to registered compute resources (basic allocation, could be improved).
    function allocateComputeTask(uint256 _trainingRunId, address _computeProvider) external onlyGovernor whenNotPaused {
        require(computeResources[_computeProvider].providerAddress != address(0), "Compute resource not registered");
        require(computeResources[_computeProvider].isAvailable, "Compute resource is not available");
        require(trainingRuns[_trainingRunId].trainingRunId != 0, "Training run does not exist");

        // Basic allocation - just set resource to unavailable. More sophisticated allocation logic needed in real use.
        computeResources[_computeProvider].isAvailable = false;
        // TODO: Link compute provider to training run and track task assignment.
        emit ComputeTaskAllocated(_computeProvider, _trainingRunId);
    }

    /// @notice Rewards compute providers for their contribution.
    function rewardComputeContribution(address _computeProvider, uint256 _rewardAmount) external onlyGovernor whenNotPaused {
        require(computeResources[_computeProvider].providerAddress != address(0), "Compute resource not registered");
        require(computeRewardPool >= _rewardAmount, "Not enough funds in compute reward pool");

        computeRewardPool -= _rewardAmount;
        computeResources[_computeProvider].isAvailable = true; // Mark resource as available again after reward
        governanceToken.transfer(_computeProvider, _rewardAmount);
        emit RewardsDistributed(_computeProvider, _rewardAmount, "Compute contribution reward");
    }

    /// @notice Retrieves details of a registered compute resource.
    function getComputeResourceDetails(address _providerAddress) external view returns (ComputeResource memory) {
        return computeResources[_providerAddress];
    }

    /// @notice Gets the number of registered compute providers.
    function getComputeProviderCount() external view returns (uint256) {
        return computeProviderAddresses.length();
    }


    // --- Model Training Functions ---

    /// @notice Allows approved members to initiate AI model training runs.
    function initiateModelTraining(uint256 _datasetId, string memory _modelConfiguration) external onlyMember whenNotPaused {
        require(datasets[_datasetId].datasetId != 0, "Dataset does not exist");
        trainingRunCount.increment();
        uint256 trainingRunId = trainingRunCount.current();
        trainingRuns[trainingRunId] = TrainingRun({
            trainingRunId: trainingRunId,
            initiator: msg.sender,
            datasetId: _datasetId,
            modelConfiguration: _modelConfiguration,
            startTime: block.timestamp,
            endTime: 0, // Set when training is finalized
            modelCID: "", // Set when training is finalized
            isFinalized: false
        });
        emit TrainingRunInitiated(trainingRunId, msg.sender);
    }

    /// @notice Allows trainers to report progress on model training tasks.
    function reportTrainingProgress(uint256 _trainingRunId, string memory _progressUpdate) external onlyMember whenNotPaused {
        require(trainingRuns[_trainingRunId].trainingRunId != 0, "Training run does not exist");
        // TODO: Add access control to ensure only assigned trainers can report progress.
        emit TrainingProgressReported(_trainingRunId, _progressUpdate);
    }

    /// @notice Finalizes a model training run, setting the model CID and minting an NFT.
    function finalizeModelTraining(uint256 _trainingRunId, string memory _modelCID) external onlyGovernor whenNotPaused {
        require(trainingRuns[_trainingRunId].trainingRunId != 0, "Training run does not exist");
        require(!trainingRuns[_trainingRunId].isFinalized, "Training run already finalized");

        trainingRuns[_trainingRunId].isFinalized = true;
        trainingRuns[_trainingRunId].endTime = block.timestamp;
        trainingRuns[_trainingRunId].modelCID = _modelCID;

        mintModelNFT(_trainingRunId); // Mint NFT for the trained model
        emit TrainingRunFinalized(_trainingRunId, _modelCID);
    }

    /// @notice Mints an NFT representing a trained AI model.
    function mintModelNFT(uint256 _trainingRunId) private {
        modelNftCounter.increment();
        uint256 tokenId = modelNftCounter.current();
        _mint(address(this), tokenId); // Mint NFT to the contract itself initially. Could be transferred to DAO or trainers.
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", trainingRuns[_trainingRunId].modelCID))); // Set URI to model metadata on IPFS

        emit ModelNftMinted(tokenId, _trainingRunId);
    }

    /// @notice Retrieves details of a trained AI model (training run).
    function getModelDetails(uint256 _trainingRunId) external view returns (TrainingRun memory) {
        return trainingRuns[_trainingRunId];
    }

    /// @notice Gets the current training run count.
    function getTrainingRunCount() external view returns (uint256) {
        return trainingRunCount.current();
    }

    /// @notice Gets the current Model NFT count minted.
    function getModelNftCount() external view returns (uint256) {
        return modelNftCounter.current();
    }


    // --- Treasury & Finance Functions ---

    /// @notice Allows members to deposit funds into the DAO treasury.
    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Allows members to withdraw funds from the DAO treasury (governance-controlled).
    function withdrawFunds(uint256 _amount) external onlyGovernor whenNotPaused nonReentrant {
        require(address(this).balance >= _amount, "Insufficient DAO treasury balance");
        payable(msg.sender).transfer(_amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /// @notice Distributes accumulated rewards to eligible members (governance-driven).
    function distributeRewards(address _recipient, uint256 _amount, string memory _reason) external onlyGovernor whenNotPaused {
        // Example: Distribute rewards from treasury or reward pools.
        require(address(this).balance >= _amount || dataRewardPool >= _amount || computeRewardPool >= _amount, "Insufficient funds for rewards");

        // Determine source of funds (treasury, data pool, compute pool) based on _reason or proposal context.
        // For simplicity, assuming from treasury for now.
        payable(_recipient).transfer(_amount); // Or governanceToken.transfer(_recipient, _amount) if rewarding in governance tokens
        emit RewardsDistributed(_recipient, _amount, _reason);
    }

    /// @notice Retrieves the current balance of the DAO treasury (contract balance).
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Retrieves the current balance of the data reward pool.
    function getDataRewardPoolBalance() external view returns (uint256) {
        return dataRewardPool;
    }

    /// @notice Retrieves the current balance of the compute reward pool.
    function getComputeRewardPoolBalance() external view returns (uint256) {
        return computeRewardPool;
    }


    // --- Governance Parameter Setting Functions ---

    /// @notice Allows governors to update key governance parameters.
    function setGovernanceParameters(
        uint256 _newStakingAmount,
        uint256 _newVotingPeriodBlocks,
        uint256 _newQuorumPercentage,
        uint256 _newProposalPassingPercentage,
        uint256 _newDataRewardPool,
        uint256 _newComputeRewardPool
    ) external onlyGovernor whenNotPaused {
        if (_newStakingAmount > 0) {
            stakingAmountToJoin = _newStakingAmount;
            emit GovernanceParametersUpdated("stakingAmountToJoin", _newStakingAmount);
        }
        if (_newVotingPeriodBlocks > 0) {
            votingPeriod = _newVotingPeriodBlocks;
            emit GovernanceParametersUpdated("votingPeriod", _newVotingPeriodBlocks);
        }
        if (_newQuorumPercentage > 0 && _newQuorumPercentage <= 100) {
            quorumPercentage = _newQuorumPercentage;
            emit GovernanceParametersUpdated("quorumPercentage", _newQuorumPercentage);
        }
        if (_newProposalPassingPercentage > 0 && _newProposalPassingPercentage <= 100) {
            proposalPassingPercentage = _newProposalPassingPercentage;
            emit GovernanceParametersUpdated("proposalPassingPercentage", _newProposalPassingPercentage);
        }
        if (_newDataRewardPool >= 0) {
            dataRewardPool = _newDataRewardPool;
            emit GovernanceParametersUpdated("dataRewardPool", _newDataRewardPool);
        }
        if (_newComputeRewardPool >= 0) {
            computeRewardPool = _newComputeRewardPool;
            emit GovernanceParametersUpdated("computeRewardPool", _newComputeRewardPool);
        }
    }


    // --- Pause & Unpause Functions ---

    /// @notice Pauses the contract, restricting critical functions.
    function pauseContract() external onlyGovernor whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, restoring normal functionality.
    function unpauseContract() external onlyGovernor whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Fallback and Receive (for receiving ETH in treasury) ---

    receive() external payable {}
    fallback() external payable {}
}
```