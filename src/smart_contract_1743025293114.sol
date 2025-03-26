```solidity
/**
 * @title Decentralized Dynamic Asset Vault - "Chameleon Vault"
 * @author Gemini AI (Example Smart Contract - Not for Production)
 * @dev A smart contract demonstrating advanced concepts like dynamic asset management,
 *      skill-based access control, decentralized reputation, and on-chain governance
 *      for a fictional "Chameleon Vault" that can adapt to changing conditions.
 *
 * Function Outline and Summary:
 *
 * --- Core Vault Functions ---
 * 1. depositAsset(address _asset, uint256 _amount): Allows users to deposit supported assets into the vault.
 * 2. withdrawAsset(address _asset, uint256 _amount): Allows users to withdraw assets from the vault, subject to conditions.
 * 3. getVaultBalance(address _asset): Returns the current balance of a specific asset in the vault.
 * 4. listSupportedAssets(): Returns a list of addresses of currently supported assets in the vault.
 * 5. setAssetWeight(address _asset, uint256 _weight): (Governance) Sets the weight of an asset in the vault's dynamic strategy.
 * 6. getAssetWeight(address _asset): Returns the current weight of an asset in the vault's strategy.
 * 7. rebalanceVault(): (Skill-Based Access) Triggers a vault rebalancing based on current asset weights.
 *
 * --- Skill-Based Access & Reputation ---
 * 8. registerSkill(string _skillName): Allows users to register their skills on-chain.
 * 9. endorseSkill(address _user, string _skillName): Allows users to endorse another user's skill, building reputation.
 * 10. getUserSkills(address _user): Returns a list of skills registered by a user.
 * 11. getUserSkillEndorsements(address _user, string _skillName): Returns the endorsement count for a specific skill of a user.
 * 12. checkSkillRequirement(address _user, string _skillName, uint256 _minEndorsements): Checks if a user meets a skill endorsement requirement.
 * 13. setRebalanceSkillRequirement(string _skillName, uint256 _minEndorsements): (Governance) Sets the skill and endorsement level required to trigger rebalancing.
 * 14. getRebalanceSkillRequirement(): Returns the currently required skill and endorsement level for rebalancing.
 *
 * --- Dynamic Strategy & Adaptive Fees ---
 * 15. setBaseManagementFee(uint256 _feePercentage): (Governance) Sets the base management fee percentage for the vault.
 * 16. getBaseManagementFee(): Returns the current base management fee percentage.
 * 17. setPerformanceFeeThreshold(uint256 _thresholdPercentage): (Governance) Sets the performance fee activation threshold.
 * 18. getPerformanceFeeThreshold(): Returns the current performance fee threshold.
 * 19. calculateDynamicFee(): Calculates the dynamic management fee based on vault performance and base fee.
 * 20. collectManagementFees(): Collects accrued management fees and distributes them (e.g., to governance or vault operators).
 *
 * --- Governance & Admin ---
 * 21. proposeGovernanceAction(string _description, bytes _calldata): (Governance) Allows governance to propose actions.
 * 22. voteOnGovernanceAction(uint256 _proposalId, bool _support): (Governance) Allows governance to vote on proposals.
 * 23. executeGovernanceAction(uint256 _proposalId): (Governance) Executes a passed governance action.
 * 24. getGovernanceProposalDetails(uint256 _proposalId): Returns details of a specific governance proposal.
 * 25. addSupportedAsset(address _asset): (Admin) Adds a new asset to the list of supported assets.
 * 26. removeSupportedAsset(address _asset): (Admin) Removes an asset from the supported assets list.
 * 27. setGovernanceAddress(address _governanceAddress): (Admin) Sets the address of the governance contract/multisig.
 * 28. getGovernanceAddress(): Returns the currently set governance address.
 * 29. pauseVault(): (Admin) Pauses core vault functionalities.
 * 30. unpauseVault(): (Admin) Resumes core vault functionalities.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ChameleonVault is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    // Supported Assets and Weights
    mapping(address => bool) public supportedAssets; // Mapping to quickly check if an asset is supported
    address[] public supportedAssetList; // List to iterate through supported assets
    mapping(address => uint256) public assetWeights; // Target weights for each asset in the strategy (in percentages, e.g., 50 for 50%)

    // Vault Balances
    mapping(address => uint256) public vaultBalances; // Balances of each asset in the vault

    // Skill-Based Access and Reputation
    mapping(address => string[]) public userSkills; // Skills registered by each user
    mapping(address => mapping(string => uint256)) public skillEndorsements; // Endorsement count for each skill of each user
    string public rebalanceRequiredSkill; // Skill required to trigger rebalancing
    uint256 public rebalanceMinEndorsements; // Minimum endorsements needed for the required skill to trigger rebalancing

    // Dynamic Fee Management
    uint256 public baseManagementFeePercentage; // Base management fee percentage (e.g., 200 for 2%)
    uint256 public performanceFeeThresholdPercentage; // Vault performance threshold to activate performance fee
    uint256 public lastPerformanceCheckTimestamp; // Timestamp of the last performance fee calculation
    uint256 public accruedManagementFees; // Accrued management fees

    // Governance
    address public governanceAddress; // Address of the governance contract or multisig
    uint256 public proposalCounter;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    enum ProposalState { Pending, Active, Passed, Rejected, Executed }
    struct GovernanceProposal {
        string description;
        bytes calldataData;
        ProposalState state;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
    }
    uint256 public governanceVotingPeriod = 7 days; // Default voting period

    // --- Events ---
    event AssetDeposited(address indexed user, address indexed asset, uint256 amount);
    event AssetWithdrawn(address indexed user, address indexed asset, uint256 amount);
    event AssetWeightSet(address indexed asset, uint256 weight);
    event VaultRebalanced(address indexed rebalancer);
    event SkillRegistered(address indexed user, string skillName);
    event SkillEndorsed(address indexed endorser, address indexed endorsedUser, string skillName);
    event RebalanceSkillRequirementSet(string skillName, uint256 minEndorsements);
    event BaseManagementFeeSet(uint256 feePercentage);
    event PerformanceFeeThresholdSet(uint256 thresholdPercentage);
    event ManagementFeesCollected(uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceActionExecuted(uint256 proposalId);
    event VaultPaused();
    event VaultUnpaused();
    event SupportedAssetAdded(address asset);
    event SupportedAssetRemoved(address asset);
    event GovernanceAddressSet(address governanceAddress);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance can call this function");
        _;
    }

    modifier onlySkilledRebalancer() {
        require(checkSkillRequirement(msg.sender, rebalanceRequiredSkill, rebalanceMinEndorsements), "Insufficient skills to rebalance vault");
        _;
    }

    // --- Constructor ---
    constructor(address _governanceAddress) payable {
        governanceAddress = _governanceAddress;
        baseManagementFeePercentage = 100; // Default 1% base fee
        performanceFeeThresholdPercentage = 10500; // Default 105% threshold (5% performance gain)
        rebalanceRequiredSkill = "VaultRebalancing";
        rebalanceMinEndorsements = 5;
    }

    // --- Core Vault Functions ---

    function depositAsset(address _asset, uint256 _amount) external whenNotPaused {
        require(supportedAssets[_asset], "Asset not supported");
        require(_amount > 0, "Deposit amount must be greater than zero");

        IERC20 token = IERC20(_asset);
        token.transferFrom(msg.sender, address(this), _amount); // Pull tokens into the vault
        vaultBalances[_asset] = vaultBalances[_asset].add(_amount);

        emit AssetDeposited(msg.sender, _asset, _amount);
    }

    function withdrawAsset(address _asset, uint256 _amount) external whenNotPaused {
        require(supportedAssets[_asset], "Asset not supported");
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(vaultBalances[_asset] >= _amount, "Insufficient vault balance");

        vaultBalances[_asset] = vaultBalances[_asset].sub(_amount);
        IERC20 token = IERC20(_asset);
        token.transfer(msg.sender, _amount); // Send tokens from the vault

        emit AssetWithdrawn(msg.sender, _asset, _amount);
    }

    function getVaultBalance(address _asset) external view returns (uint256) {
        return vaultBalances[_asset];
    }

    function listSupportedAssets() external view returns (address[] memory) {
        return supportedAssetList;
    }

    function setAssetWeight(address _asset, uint256 _weight) external onlyGovernance {
        require(supportedAssets[_asset], "Asset not supported");
        require(_weight <= 100, "Weight must be between 0 and 100"); // Assuming weights are percentages

        assetWeights[_asset] = _weight;
        emit AssetWeightSet(_asset, _weight);
    }

    function getAssetWeight(address _asset) external view returns (uint256) {
        return assetWeights[_asset];
    }

    function rebalanceVault() external onlySkilledRebalancer whenNotPaused {
        // --- Advanced Logic for Vault Rebalancing would go here ---
        // This is a placeholder for a more complex rebalancing strategy.
        // In a real application, this would involve:
        // 1. Fetching current asset prices (from oracles, etc.)
        // 2. Calculating current portfolio weights
        // 3. Determining necessary trades to reach target weights
        // 4. Executing trades on decentralized exchanges (DEXs)
        // --- Placeholder for now, just for demonstration ---

        // Example: Simple placeholder action - log rebalancing event
        emit VaultRebalanced(msg.sender);
    }

    // --- Skill-Based Access & Reputation ---

    function registerSkill(string memory _skillName) external {
        bool skillExists = false;
        for (uint i = 0; i < userSkills[msg.sender].length; i++) {
            if (keccak256(bytes(userSkills[msg.sender][i])) == keccak256(bytes(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already registered");
        userSkills[msg.sender].push(_skillName);
        emit SkillRegistered(msg.sender, _skillName);
    }

    function endorseSkill(address _user, string memory _skillName) external {
        bool skillRegistered = false;
        for (uint i = 0; i < userSkills[_user].length; i++) {
            if (keccak256(bytes(userSkills[_user][i])) == keccak256(bytes(_skillName))) {
                skillRegistered = true;
                break;
            }
        }
        require(skillRegistered, "Endorsed user has not registered this skill");
        skillEndorsements[_user][_skillName]++;
        emit SkillEndorsed(msg.sender, _user, _skillName);
    }

    function getUserSkills(address _user) external view returns (string[] memory) {
        return userSkills[_user];
    }

    function getUserSkillEndorsements(address _user, string memory _skillName) external view returns (uint256) {
        return skillEndorsements[_user][_skillName];
    }

    function checkSkillRequirement(address _user, string memory _skillName, uint256 _minEndorsements) public view returns (bool) {
        return skillEndorsements[_user][_skillName] >= _minEndorsements;
    }

    function setRebalanceSkillRequirement(string memory _skillName, uint256 _minEndorsements) external onlyGovernance {
        rebalanceRequiredSkill = _skillName;
        rebalanceMinEndorsements = _minEndorsements;
        emit RebalanceSkillRequirementSet(_skillName, _minEndorsements);
    }

    function getRebalanceSkillRequirement() external view returns (string memory skillName, uint256 minEndorsements) {
        return (rebalanceRequiredSkill, rebalanceMinEndorsements);
    }

    // --- Dynamic Strategy & Adaptive Fees ---

    function setBaseManagementFee(uint256 _feePercentage) external onlyGovernance {
        baseManagementFeePercentage = _feePercentage;
        emit BaseManagementFeeSet(_feePercentage);
    }

    function getBaseManagementFee() external view returns (uint256) {
        return baseManagementFeePercentage;
    }

    function setPerformanceFeeThreshold(uint256 _thresholdPercentage) external onlyGovernance {
        performanceFeeThresholdPercentage = _thresholdPercentage;
        emit PerformanceFeeThresholdSet(_thresholdPercentage);
    }

    function getPerformanceFeeThreshold() external view returns (uint256) {
        return performanceFeeThresholdPercentage;
    }

    function calculateDynamicFee() public view returns (uint256 dynamicFeePercentage) {
        // --- Advanced Logic for Dynamic Fee Calculation would go here ---
        // This is a placeholder for a more complex fee calculation strategy.
        // In a real application, this could consider:
        // 1. Vault performance since last calculation (e.g., percentage gain/loss)
        // 2. Market volatility
        // 3. Utilization rate of the vault
        // --- Placeholder for now, simple example based on performance threshold ---

        // Example: Simple dynamic fee - if performance exceeds threshold, increase fee
        uint256 currentPerformancePercentage = 10200; // Placeholder - in real case, calculate vault performance
        if (currentPerformancePercentage >= performanceFeeThresholdPercentage) {
            dynamicFeePercentage = baseManagementFeePercentage.add(50); // Increase fee by 0.5% if performance is good
        } else {
            dynamicFeePercentage = baseManagementFeePercentage; // Otherwise, use base fee
        }
        return dynamicFeePercentage;
    }

    function collectManagementFees() external whenNotPaused {
        // --- Advanced Logic for Fee Collection and Distribution would go here ---
        // This is a placeholder. In a real application, this would:
        // 1. Calculate accrued fees based on vault balances and dynamic fee
        // 2. Transfer fees to a designated address (e.g., governance, vault operators)
        // 3. Potentially distribute fees among stakeholders based on governance rules
        // --- Placeholder for now, simple example of accumulating fees ---

        uint256 currentFeePercentage = calculateDynamicFee();
        uint256 totalVaultValue = 0; // In real case, calculate total value of all assets in the vault
        for (uint i = 0; i < supportedAssetList.length; i++) {
            totalVaultValue = totalVaultValue.add(vaultBalances[supportedAssetList[i]]); // Simplistic - needs price oracle in real case
        }

        uint256 feesToCollect = totalVaultValue.mul(currentFeePercentage).div(10000); // Calculate fees based on total value and percentage (assuming percentage is in basis points - 10000 for 100%)
        accruedManagementFees = accruedManagementFees.add(feesToCollect);

        // In a real implementation, fees would be transferred to a designated address here
        // Example (placeholder - not functional):
        // payable(governanceAddress).transfer(feesToCollect); // Assuming governanceAddress is payable and handles distribution

        emit ManagementFeesCollected(feesToCollect);
    }


    // --- Governance & Admin ---

    function proposeGovernanceAction(string memory _description, bytes memory _calldata) external onlyGovernance whenNotPaused {
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_calldata.length > 0, "Calldata cannot be empty");

        uint256 proposalId = proposalCounter++;
        governanceProposals[proposalId] = GovernanceProposal({
            description: _description,
            calldataData: _calldata,
            state: ProposalState.Pending,
            startTime: 0,
            endTime: 0,
            yesVotes: 0,
            noVotes: 0
        });
        emit GovernanceProposalCreated(proposalId, _description);
    }

    function voteOnGovernanceAction(uint256 _proposalId, bool _support) external onlyGovernance whenNotPaused {
        require(governanceProposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp < governanceProposals[_proposalId].endTime, "Voting period has ended");

        if (_support) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    function executeGovernanceAction(uint256 _proposalId) external onlyGovernance whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Passed, "Proposal not passed");
        require(block.timestamp >= proposal.endTime, "Execution before voting period ends");

        (bool success, ) = address(this).delegatecall(proposal.calldataData); // Use delegatecall for contract state changes
        require(success, "Governance action execution failed");
        proposal.state = ProposalState.Executed;
        emit GovernanceActionExecuted(_proposalId);
    }

    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    function addSupportedAsset(address _asset) external onlyOwner {
        require(_asset != address(0), "Invalid asset address");
        require(!supportedAssets[_asset], "Asset already supported");
        supportedAssets[_asset] = true;
        supportedAssetList.push(_asset);
        emit SupportedAssetAdded(_asset);
    }

    function removeSupportedAsset(address _asset) external onlyOwner {
        require(supportedAssets[_asset], "Asset not supported");
        supportedAssets[_asset] = false;

        // Remove from supportedAssetList (more efficient way to remove from array in Solidity needed for production)
        for (uint i = 0; i < supportedAssetList.length; i++) {
            if (supportedAssetList[i] == _asset) {
                supportedAssetList[i] = supportedAssetList[supportedAssetList.length - 1];
                supportedAssetList.pop();
                break;
            }
        }
        delete assetWeights[_asset]; // Optionally remove asset weight
        emit SupportedAssetRemoved(_asset);
    }

    function setGovernanceAddress(address _governanceAddress) external onlyOwner {
        require(_governanceAddress != address(0), "Invalid governance address");
        governanceAddress = _governanceAddress;
        emit GovernanceAddressSet(_governanceAddress);
    }

    function getGovernanceAddress() external view returns (address) {
        return governanceAddress;
    }

    function pauseVault() external onlyOwner {
        _pause();
        emit VaultPaused();
    }

    function unpauseVault() external onlyOwner {
        _unpause();
        emit VaultUnpaused();
    }

    fallback() external payable {}
    receive() external payable {}
}
```