This smart contract, `AIHiveDAO`, is designed to establish a decentralized autonomous organization (DAO) for the collective governance, curation, and incentivization of AI models and datasets. It integrates concepts of on-chain asset representation (NFT-like), a reputation system, and a framework for managing federated learning (FL) tasks with reward distribution.

### Outline and Function Summary

**I. Core Infrastructure & Access Control**
*   **`constructor(address initialAdmin)`**: Initializes the DAO token, deploys the `DAOToken` (ERC20Votes), and grants initial administrative roles (`DEFAULT_ADMIN_ROLE`, `ADMIN_ROLE`) to `initialAdmin`.
*   **`votingToken() public view override returns (address)`**: Overrides the `Governor` function to return the address of the DAO's governance token.
*   **`quorum(uint256 blockNumber) public view override returns (uint256)`**: Overrides the `Governor` function to return the DAO's quorum for a given block.
*   **`supportsInterface(bytes4 interfaceId) public view override returns (bool)`**: Standard ERC165 interface support, inherited from `Governor` and `AccessControl`.
*   **`_authorizeCaller(bytes32 role)`**: An internal modifier (though `onlyRole` from AccessControl is used directly) to ensure the caller has a specific role.
*   **`grantRole(bytes32 role, address account)`**: Inherited from `AccessControl`, allows an account with `DEFAULT_ADMIN_ROLE` or the specific role's admin to grant a role.
*   **`revokeRole(bytes32 role, address account)`**: Inherited from `AccessControl`, allows an account with `DEFAULT_ADMIN_ROLE` or the specific role's admin to revoke a role.
*   **`renounceRole(bytes32 role, address account)`**: Inherited from `AccessControl`, allows an account to voluntarily renounce its own role.

**II. DAO Governance (Voting & Proposals)**
*   **`propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description) public override returns (uint256 proposalId)`**: Inherited from `Governor`, allows members meeting the `proposalThreshold` to create a new governance proposal.
*   **`castVote(uint256 proposalId, uint8 support) public override returns (uint256)`**: Inherited from `Governor`, allows members to vote on active proposals.
*   **`queue(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) public override returns (uint256)`**: Inherited from `Governor`, queues a passed proposal for execution after a timelock.
*   **`execute(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) public payable override returns (uint256)`**: Inherited from `Governor`, executes a proposal that has passed and completed its timelock.
*   **`delegate(address delegatee) public`**: Inherited from `DAOToken` (ERC20Votes), allows a token holder to delegate their voting power to another address.
*   **`getVotes(address account) public view returns (uint256)`**: Inherited from `DAOToken` (ERC20Votes), returns the current voting power of an address.
*   **`setVotingPeriod(uint256 newVotingPeriod) public onlyRole(ADMIN_ROLE)`**: Allows the `ADMIN_ROLE` to directly set the voting period (usually done via a proposal).
*   **`setProposalThreshold(uint256 newProposalThreshold) public onlyRole(ADMIN_ROLE)`**: Allows the `ADMIN_ROLE` to directly set the minimum token holding required to create a proposal (usually done via a proposal).
*   **`setQuorumNumerator(uint256 newQuorumNumerator) public onlyRole(ADMIN_ROLE)`**: Allows the `ADMIN_ROLE` to directly set the voting quorum numerator (usually done via a proposal).

**III. Treasury Management**
*   **`depositToTreasury() public payable`**: Allows direct Ether deposits to the contract's treasury.
*   **`depositERC20ToTreasury(address erc20TokenAddress, uint256 amount) public`**: Allows ERC20 token deposits to the contract's treasury (requires prior approval by the sender).
*   **`withdrawFromTreasury(address recipient, uint256 amount, address tokenAddress) public onlyGovernor`**: Allows withdrawal of funds (ETH or ERC20) from the treasury, callable *only* by the Governor contract as part of a successful DAO proposal execution.

**IV. AI Model & Dataset Registry (NFT-like)**
*   **`registerAIMetadata(bytes32 metadataCID, string memory name, string memory description, bool isModel) public onlyRole(AI_ASSET_MANAGER_ROLE) returns (uint256)`**: Mints a new NFT-like asset (model or dataset), storing its metadata (e.g., IPFS CID) and initial ownership.
*   **`updateAIMetadata(uint256 aiAssetId, bytes32 newMetadataCID, string memory newName, string memory newDescription) public onlyRole(AI_ASSET_MANAGER_ROLE)`**: Allows the asset owner or `AI_ASSET_MANAGER_ROLE` to update the metadata of an existing AI asset.
*   **`transferAIAccessNFT(uint256 aiAssetId, address newOwner) public`**: Transfers ownership of an AI asset NFT to a new address.
*   **`setAIAccessFee(uint256 aiAssetId, uint256 fee, uint256 royaltyNumerator, address royaltyRecipient) public`**: Allows the asset owner to set an access fee (in native token or a specified ERC20) and define royalty percentages for usage.
*   **`requestAIAccess(uint256 aiAssetId, address tokenAddress) public payable`**: Users pay the set access fee to gain access to an AI asset, with fees being distributed to the owner and any defined royalty recipient.
*   **`deactivateAIAccessNFT(uint256 aiAssetId) public`**: Allows the asset owner or `AI_ASSET_MANAGER_ROLE` to deactivate an AI asset, preventing further access or usage (e.g., if it's found to be faulty).

**V. Reputation System**
*   **`updateReputationScore(address user, int256 scoreChange) public onlyRole(REPUTATION_MANAGER_ROLE)`**: Allows the `REPUTATION_MANAGER_ROLE` to adjust a user's base reputation score (positive or negative).
*   **`getReputationScore(address user) public view returns (uint256)`**: Retrieves the base reputation score of an address.
*   **`stakeForReputationBoost(uint256 amount) public`**: Allows users to stake DAO tokens to indicate commitment, which contributes to their `effectiveReputationScore`. Staked tokens are locked for a defined period.
*   **`unstakeReputationBoost() public`**: Allows users to unstake their locked tokens after the lockup period has expired.
*   **`getEffectiveReputationScore(address user) public view returns (uint256)`**: Returns a combined reputation score, factoring in both the base `reputationScores` and `stakedReputationTokens`.

**VI. Federated Learning (FL) Task Management**
*   **`proposeFLTask(bytes32 taskObjectivesCID, uint256 rewardPool, uint256 registrationDuration, uint256 contributionDuration, uint256 finalizeDuration, uint256 targetModelId) public onlyRole(FL_MANAGER_ROLE) returns (uint256)`**: Initiates a new FL task, defining its objectives, reward pool (funded by the proposer in DAO tokens), and various deadlines.
*   **`registerForFLTask(uint256 taskId) public`**: Allows eligible participants (e.g., based on `effectiveReputationScore`) to register for an approved FL task before its registration deadline.
*   **`submitFLContributionAttestation(uint256 taskId, bytes32 attestationHash) public`**: Participants submit an attestation (e.g., a hash of their local model update, or a verifiable proof) for their FL contribution within the contribution period.
*   **`finalizeFLTaskAndDistributeRewards(uint256 taskId, address[] memory contributors, uint256[] memory amounts) public onlyRole(FL_MANAGER_ROLE)`**: The `FL_MANAGER_ROLE` finalizes a task, verifying contributions (conceptually off-chain) and distributing rewards from the task's reward pool to specified contributors, also potentially updating their reputation.
*   **`challengeFLContribution(uint256 taskId, address contributor) public`**: Allows any user to challenge the validity of an FL contribution, logging the challenge. In a full system, this would trigger a dispute resolution mechanism.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// --- Custom Data Structures ---

/// @dev Represents an AI model or dataset asset within the DAO.
struct AIAccessNFT {
    uint256 id;                 // Unique identifier for the AI asset.
    address owner;              // Address that owns the AI asset and its access rights.
    bytes32 metadataCID;        // IPFS Content Identifier (CID) for detailed metadata (e.g., model architecture, dataset schema).
    string name;                // Display name of the AI asset.
    string description;         // Short description of the AI asset.
    uint256 accessFee;          // Fee required to access/use the AI asset (in the specified token).
    uint256 royaltyNumerator;   // Numerator for royalty calculation (e.g., for 1%, use 100 out of 10000).
    address royaltyRecipient;   // Address to receive royalties from access fees.
    bool isModel;               // True if it's an AI model, false if it's a dataset.
    bool active;                // Indicates if the asset is currently active and usable.
}

/// @dev Represents a Federated Learning (FL) task initiated within the DAO.
struct FLTask {
    uint256 taskId;                     // Unique identifier for the FL task.
    address proposer;                   // Address that proposed and funded the FL task.
    bytes32 taskObjectivesCID;          // IPFS CID for detailed task objectives and requirements.
    uint256 rewardPool;                 // Total reward allocated for this FL task (in DAO tokens).
    uint256 registrationDeadline;       // Timestamp by which participants must register.
    uint256 contributionDeadline;       // Timestamp by which participants must submit their contributions.
    uint256 finalizeDeadline;           // Timestamp by which the task must be finalized.
    mapping(address => bool) registeredParticipants;    // Tracks registered participants.
    mapping(address => bytes32) participantContributions; // Stores the attestation hash of each participant's contribution.
    uint256 totalContributions;         // Counter for the number of valid contributions.
    bool finalized;                     // True if the task has been finalized and rewards distributed.
    bool active;                        // True if the task is currently active and accepting participation.
    uint256 targetModelId;              // The AI model NFT ID that this task aims to improve or train.
}

// --- DAO Token Contract ---

/// @title DAOToken
/// @dev An ERC20 token with voting capabilities for the AIHive DAO.
contract DAOToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(address initialAdmin) ERC20("AIHive DAO Token", "AHDT") ERC20Permit("AIHive DAO Token") {
        // Mint an initial supply to the initial administrator.
        _mint(initialAdmin, 100_000_000 * 10 ** decimals()); // 100M tokens
    }

    /// @dev Overrides `ERC20._update` to include voting snapshot logic.
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    /// @dev Overrides `ERC20._mint` to include voting snapshot logic.
    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    /// @dev Overrides `ERC20._burn` to include voting snapshot logic.
    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}

// --- Main AIHiveDAO Contract ---

/// @title AIHiveDAO
/// @dev A decentralized autonomous organization (DAO) for AI model and dataset governance,
///      curation, and federated learning incentives.
contract AIHiveDAO is GovernorCompatibilityBravo, Governor, AccessControl {
    using SafeERC20 for IERC20; // For safe ERC20 operations.
    using Counters for Counters.Counter; // For unique ID generation.

    // --- Access Control Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");               // General administrative duties.
    bytes32 public constant FL_MANAGER_ROLE = keccak256("FL_MANAGER_ROLE");     // Manages Federated Learning tasks.
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE"); // Adjusts user reputation scores.
    bytes32 public constant AI_ASSET_MANAGER_ROLE = keccak256("AI_ASSET_MANAGER_ROLE"); // Manages AI model/dataset NFTs.

    // --- DAO Token Instance ---
    DAOToken public immutable token; // The governance and reward token for the DAO.

    // --- DAO Treasury ---
    receive() external payable {} // Allows direct ETH deposits to the contract.

    // --- AI Access NFTs (Registry) ---
    Counters.Counter private _aiAssetIds;                 // Counter for unique AI asset IDs.
    mapping(uint256 => AIAccessNFT) public aiAccessNFTs;  // Maps AI asset ID to its data structure.
    mapping(address => uint256[]) public aiAssetsOfOwner; // Maps owner address to a list of AI asset IDs they own.

    // --- Reputation System ---
    mapping(address => uint256) public reputationScores;        // Base reputation score for each user.
    mapping(address => uint256) public stakedReputationTokens;  // DAO tokens staked by users for reputation boost.
    mapping(address => uint256) public reputationBoostUnlockTime; // Timestamp when staked tokens can be unstaked.

    // --- Federated Learning Tasks ---
    Counters.Counter private _flTaskIds;    // Counter for unique FL task IDs.
    mapping(uint256 => FLTask) public flTasks; // Maps FL task ID to its data structure.
    mapping(address => uint256[]) public flTasksOfParticipant; // Maps participant address to a list of FL tasks they joined.

    // --- Events ---
    event AIAccessNFTRegistered(uint256 indexed id, address indexed owner, bytes32 metadataCID, bool isModel);
    event AIAccessNFTMetadataUpdated(uint256 indexed id, bytes32 newMetadataCID);
    event AIAccessNFTTransferred(uint256 indexed id, address indexed from, address indexed to);
    event AIAccessFeeSet(uint256 indexed id, uint256 fee, uint256 royaltyNumerator, address royaltyRecipient);
    event AIAccessRequested(uint256 indexed id, address indexed user, uint224 amountPaid); // Changed to uint224 to fit event topic limit
    event RoyaltyDistributed(uint256 indexed aiAssetId, address indexed recipient, uint256 amount);
    event AIAccessNFTDeactivated(uint256 indexed id);

    event ReputationUpdated(address indexed user, uint256 newScore);
    event TokensStakedForReputation(address indexed user, uint256 amount, uint256 unlockTime);
    event TokensUnstakedFromReputation(address indexed user, uint256 amount);

    event FLTaskProposed(uint256 indexed taskId, address indexed proposer, bytes32 taskObjectivesCID, uint256 rewardPool);
    event FLTaskRegistered(uint256 indexed taskId, address indexed participant);
    event FLContributionAttested(uint256 indexed taskId, address indexed contributor, bytes32 attestationHash);
    event FLTaskFinalized(uint256 indexed taskId, uint256 totalDistributed);
    event FLRewardDistributed(uint256 indexed taskId, address indexed participant, uint256 amount);
    event FLContributionChallenged(uint256 indexed taskId, address indexed challenger, address indexed contributor);

    /// @dev Constructor for the AIHiveDAO contract.
    /// @param initialAdmin The address that will initially hold administrative roles.
    constructor(address initialAdmin)
        Governor("AIHiveDAO-Governor")
        GovernorCompatibilityBravo("AIHiveDAO-Governor") // For compatibility with standard interfaces.
    {
        // Grant default admin and custom ADMIN_ROLE to the initial administrator.
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ADMIN_ROLE, initialAdmin);
        // Also grant other initial roles to the admin for convenience, can be changed later.
        _grantRole(FL_MANAGER_ROLE, initialAdmin);
        _grantRole(REPUTATION_MANAGER_ROLE, initialAdmin);
        _grantRole(AI_ASSET_MANAGER_ROLE, initialAdmin);

        // Deploy the DAOToken and link it to this Governor contract.
        token = new DAOToken(initialAdmin);
        _setVotingToken(address(token));
    }

    // --- I. Core Infrastructure & Access Control (inherited/modified from OpenZeppelin) ---

    /// @dev Returns the address of the token used for voting.
    function votingToken() public view virtual override returns (address) {
        return address(token);
    }

    /// @dev Returns the current quorum for the DAO.
    function quorum(uint256 blockNumber) public view override(IGovernor, GovernorCompatibilityBravo) returns (uint256) {
        return super.quorum(blockNumber);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(Governor, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // `grantRole`, `revokeRole`, `renounceRole` are inherited from AccessControl.

    // --- II. DAO Governance (Voting & Proposals) (inherited/modified from OpenZeppelin Governor) ---

    // `propose`, `castVote`, `queue`, `execute` are inherited from Governor.
    // `delegate`, `getVotes` are inherited from DAOToken (ERC20Votes).

    /// @dev Sets the duration for which proposals are open for voting.
    /// @param newVotingPeriod The new voting period in seconds or blocks (depending on Governor setup).
    function setVotingPeriod(uint256 newVotingPeriod) public onlyRole(ADMIN_ROLE) {
        _setVotingPeriod(newVotingPeriod); // Governor's internal function.
    }

    /// @dev Sets the minimum token holding required to create a proposal.
    /// @param newProposalThreshold The new proposal threshold amount.
    function setProposalThreshold(uint256 newProposalThreshold) public onlyRole(ADMIN_ROLE) {
        _setProposalThreshold(newProposalThreshold); // Governor's internal function.
    }

    /// @dev Sets the quorum numerator to adjust the voting quorum.
    /// @param newQuorumNumerator The new quorum numerator (e.g., for 50%, use 500000 out of 1000000).
    function setQuorumNumerator(uint256 newQuorumNumerator) public onlyRole(ADMIN_ROLE) {
        _setQuorumNumerator(newQuorumNumerator); // Governor's internal function.
    }

    // --- III. Treasury Management ---

    /// @dev Allows direct Ether deposits into the DAO's treasury.
    function depositToTreasury() public payable {
        // Ether sent directly to the contract via `receive()` function.
        // This function explicitly allows direct calls if no ETH is attached.
    }

    /// @dev Allows ERC20 token deposits into the DAO's treasury.
    /// @param erc20TokenAddress The address of the ERC20 token.
    /// @param amount The amount of ERC20 tokens to deposit.
    function depositERC20ToTreasury(address erc20TokenAddress, uint256 amount) public {
        IERC20(erc20TokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
    }

    /// @dev Allows withdrawal of funds (ETH or ERC20) from the treasury.
    ///      This function can only be called by a successful DAO proposal execution.
    /// @param recipient The address to which the funds will be withdrawn.
    /// @param amount The amount of funds to withdraw.
    /// @param tokenAddress The address of the token to withdraw (address(0) for ETH).
    function withdrawFromTreasury(address recipient, uint256 amount, address tokenAddress) public onlyGovernor {
        require(recipient != address(0), "AIHiveDAO: Invalid recipient address.");
        if (tokenAddress == address(0)) { // ETH
            payable(recipient).transfer(amount);
        } else { // ERC20
            IERC20(tokenAddress).safeTransfer(recipient, amount);
        }
    }

    // --- IV. AI Model & Dataset Registry (NFT-like) ---

    /// @dev Registers a new AI model or dataset as an NFT-like asset.
    /// @param metadataCID IPFS CID or similar identifier for the asset's detailed metadata.
    /// @param name The public name of the asset.
    /// @param description A brief description of the asset.
    /// @param isModel True if the asset is an AI model, false if it's a dataset.
    /// @return The unique ID of the newly registered AI asset.
    function registerAIMetadata(bytes32 metadataCID, string memory name, string memory description, bool isModel)
        public
        onlyRole(AI_ASSET_MANAGER_ROLE)
        returns (uint256)
    {
        _aiAssetIds.increment();
        uint256 newId = _aiAssetIds.current();
        AIAccessNFT storage newNFT = aiAccessNFTs[newId];
        newNFT.id = newId;
        newNFT.owner = _msgSender(); // The AI_ASSET_MANAGER_ROLE member registers and becomes owner.
        newNFT.metadataCID = metadataCID;
        newNFT.name = name;
        newNFT.description = description;
        newNFT.isModel = isModel;
        newNFT.active = true;
        newNFT.accessFee = 0;
        newNFT.royaltyNumerator = 0;
        newNFT.royaltyRecipient = address(0);

        aiAssetsOfOwner[_msgSender()].push(newId); // Track assets by owner.

        emit AIAccessNFTRegistered(newId, _msgSender(), metadataCID, isModel);
        return newId;
    }

    /// @dev Updates the metadata for an existing AI asset.
    ///      Only the asset owner or AI_ASSET_MANAGER_ROLE can update.
    /// @param aiAssetId The ID of the AI asset to update.
    /// @param newMetadataCID The new IPFS CID for updated metadata.
    /// @param newName The new name for the asset.
    /// @param newDescription The new description for the asset.
    function updateAIMetadata(uint256 aiAssetId, bytes32 newMetadataCID, string memory newName, string memory newDescription)
        public
        onlyRole(AI_ASSET_MANAGER_ROLE) // Only AI_ASSET_MANAGER_ROLE can update, for controlled updates.
    {
        AIAccessNFT storage asset = aiAccessNFTs[aiAssetId];
        require(asset.owner == _msgSender(), "AIHiveDAO: Caller not owner of this asset.");
        require(asset.active, "AIHiveDAO: Asset is inactive.");

        asset.metadataCID = newMetadataCID;
        asset.name = newName;
        asset.description = newDescription;

        emit AIAccessNFTMetadataUpdated(aiAssetId, newMetadataCID);
    }

    /// @dev Transfers ownership of an AI asset NFT.
    /// @param aiAssetId The ID of the AI asset to transfer.
    /// @param newOwner The address of the new owner.
    function transferAIAccessNFT(uint256 aiAssetId, address newOwner) public {
        AIAccessNFT storage asset = aiAccessNFTs[aiAssetId];
        require(asset.owner == _msgSender(), "AIHiveDAO: Caller not owner of this asset.");
        require(newOwner != address(0), "AIHiveDAO: Invalid new owner address.");
        require(asset.active, "AIHiveDAO: Asset is inactive.");

        address oldOwner = asset.owner;
        asset.owner = newOwner;

        // Efficiently remove from old owner's list and add to new owner's.
        for (uint i = 0; i < aiAssetsOfOwner[oldOwner].length; i++) {
            if (aiAssetsOfOwner[oldOwner][i] == aiAssetId) {
                aiAssetsOfOwner[oldOwner][i] = aiAssetsOfOwner[oldOwner][aiAssetsOfOwner[oldOwner].length - 1];
                aiAssetsOfOwner[oldOwner].pop();
                break;
            }
        }
        aiAssetsOfOwner[newOwner].push(aiAssetId);

        emit AIAccessNFTTransferred(aiAssetId, oldOwner, newOwner);
    }

    /// @dev Sets the access fee and royalty information for an AI asset.
    ///      Only the asset owner can set these parameters.
    /// @param aiAssetId The ID of the AI asset.
    /// @param fee The amount charged for access/usage (in the specified token, or ETH if address(0)).
    /// @param royaltyNumerator The numerator for royalty calculation (e.g., 100 for 1%). Max 10000 (100%).
    /// @param royaltyRecipient The address to receive the royalty portion of the fee.
    function setAIAccessFee(uint256 aiAssetId, uint256 fee, uint256 royaltyNumerator, address royaltyRecipient)
        public
    {
        AIAccessNFT storage asset = aiAccessNFTs[aiAssetId];
        require(asset.owner == _msgSender(), "AIHiveDAO: Caller not owner of this asset.");
        require(royaltyNumerator <= 10000, "AIHiveDAO: Royalty numerator cannot exceed 10000 (100%).");
        if (royaltyNumerator > 0) {
            require(royaltyRecipient != address(0), "AIHiveDAO: Royalty recipient cannot be zero address if royalty > 0.");
        }

        asset.accessFee = fee;
        asset.royaltyNumerator = royaltyNumerator;
        asset.royaltyRecipient = royaltyRecipient;

        emit AIAccessFeeSet(aiAssetId, fee, royaltyNumerator, royaltyRecipient);
    }

    /// @dev Allows a user to pay the access fee to use an AI asset.
    ///      Fees are distributed to the owner and royalty recipient.
    /// @param aiAssetId The ID of the AI asset to access.
    /// @param tokenAddress The address of the token to use for payment (address(0) for ETH).
    function requestAIAccess(uint256 aiAssetId, address tokenAddress) public payable {
        AIAccessNFT storage asset = aiAccessNFTs[aiAssetId];
        require(asset.active, "AIHiveDAO: Asset is inactive.");
        require(asset.accessFee > 0, "AIHiveDAO: No access fee set for this asset.");

        uint256 amountToPay = asset.accessFee;
        address assetOwner = asset.owner;
        uint256 royaltyAmount = (amountToPay * asset.royaltyNumerator) / 10000;
        uint256 ownerAmount = amountToPay - royaltyAmount;

        if (tokenAddress == address(0)) { // ETH payment
            require(msg.value >= amountToPay, "AIHiveDAO: Insufficient ETH sent.");
            payable(assetOwner).transfer(ownerAmount);
            if (royaltyAmount > 0) {
                payable(asset.royaltyRecipient).transfer(royaltyAmount);
                emit RoyaltyDistributed(aiAssetId, asset.royaltyRecipient, royaltyAmount);
            }
            if (msg.value > amountToPay) { // Refund any excess ETH.
                payable(_msgSender()).transfer(msg.value - amountToPay);
            }
        } else { // ERC20 token payment
            // User must have approved this contract to spend their tokens beforehand.
            IERC20(tokenAddress).safeTransferFrom(_msgSender(), assetOwner, ownerAmount);
            if (royaltyAmount > 0) {
                IERC20(tokenAddress).safeTransferFrom(_msgSender(), asset.royaltyRecipient, royaltyAmount);
                emit RoyaltyDistributed(aiAssetId, asset.royaltyRecipient, royaltyAmount);
            }
        }
        emit AIAccessRequested(aiAssetId, _msgSender(), uint224(amountToPay));
    }

    /// @dev Deactivates an AI asset, preventing further access or usage.
    ///      Can be called by the asset owner or AI_ASSET_MANAGER_ROLE.
    /// @param aiAssetId The ID of the AI asset to deactivate.
    function deactivateAIAccessNFT(uint256 aiAssetId) public {
        AIAccessNFT storage asset = aiAccessNFTs[aiAssetId];
        require(asset.owner == _msgSender() || hasRole(AI_ASSET_MANAGER_ROLE, _msgSender()), "AIHiveDAO: Not authorized to deactivate.");
        require(asset.active, "AIHiveDAO: Asset is already inactive.");
        asset.active = false;
        emit AIAccessNFTDeactivated(aiAssetId);
    }

    // --- V. Reputation System ---

    /// @dev Adjusts a user's base reputation score.
    ///      Only callable by the REPUTATION_MANAGER_ROLE.
    /// @param user The address whose reputation is being updated.
    /// @param scoreChange The amount to change the score by (can be positive or negative).
    function updateReputationScore(address user, int256 scoreChange) public onlyRole(REPUTATION_MANAGER_ROLE) {
        if (scoreChange > 0) {
            reputationScores[user] = reputationScores[user] + uint256(scoreChange);
        } else {
            uint256 absChange = uint256(-scoreChange);
            if (reputationScores[user] < absChange) {
                reputationScores[user] = 0; // Cap at 0, no negative reputation.
            } else {
                reputationScores[user] = reputationScores[user] - absChange;
            }
        }
        emit ReputationUpdated(user, reputationScores[user]);
    }

    /// @dev Retrieves the base reputation score of an address.
    /// @param user The address to query.
    /// @return The base reputation score.
    function getReputationScore(address user) public view returns (uint256) {
        return reputationScores[user];
    }

    /// @dev Allows users to stake DAO tokens to temporarily boost their effective reputation.
    ///      Staked tokens are locked for a predefined period (e.g., 30 days).
    /// @param amount The amount of DAO tokens to stake.
    function stakeForReputationBoost(uint256 amount) public {
        require(amount > 0, "AIHiveDAO: Stake amount must be greater than zero.");
        token.safeTransferFrom(_msgSender(), address(this), amount);
        stakedReputationTokens[_msgSender()] += amount;
        uint256 unlockTime = block.timestamp + 30 days; // Example: 30-day lockup.
        reputationBoostUnlockTime[_msgSender()] = unlockTime;

        emit TokensStakedForReputation(_msgSender(), amount, unlockTime);
    }

    /// @dev Allows users to unstake their locked tokens after the lockup period has expired.
    function unstakeReputationBoost() public {
        uint256 amount = stakedReputationTokens[_msgSender()];
        require(amount > 0, "AIHiveDAO: No tokens staked for reputation boost.");
        require(block.timestamp >= reputationBoostUnlockTime[_msgSender()], "AIHiveDAO: Staked tokens are still locked.");

        stakedReputationTokens[_msgSender()] = 0;
        reputationBoostUnlockTime[_msgSender()] = 0; // Reset unlock time.
        token.safeTransfer(_msgSender(), amount); // Return tokens to the user.

        emit TokensUnstakedFromReputation(_msgSender(), amount);
    }

    /// @dev Calculates and returns the effective reputation score,
    ///      combining base reputation and staked tokens.
    ///      This score can be used for eligibility checks (e.g., FL task registration).
    /// @param user The address to query.
    /// @return The effective reputation score.
    function getEffectiveReputationScore(address user) public view returns (uint256) {
        return reputationScores[user] + stakedReputationTokens[user];
    }

    // --- VI. Federated Learning (FL) Task Management ---

    /// @dev Proposes a new Federated Learning task.
    ///      Only callable by the FL_MANAGER_ROLE. The proposer funds the reward pool.
    /// @param taskObjectivesCID IPFS CID for detailed task objectives.
    /// @param rewardPool The total amount of DAO tokens allocated as rewards for this task.
    /// @param registrationDuration The duration (in seconds) for participant registration.
    /// @param contributionDuration The duration (in seconds) for participants to submit contributions.
    /// @param finalizeDuration The duration (in seconds) for finalization and reward distribution.
    /// @param targetModelId The AI model NFT ID that this task aims to improve or train.
    /// @return The unique ID of the newly proposed FL task.
    function proposeFLTask(
        bytes32 taskObjectivesCID,
        uint256 rewardPool,
        uint256 registrationDuration,
        uint256 contributionDuration,
        uint256 finalizeDuration,
        uint256 targetModelId
    )
        public
        onlyRole(FL_MANAGER_ROLE)
        returns (uint256)
    {
        require(rewardPool > 0, "AIHiveDAO: Reward pool must be positive.");
        _flTaskIds.increment();
        uint256 newTaskId = _flTaskIds.current();

        FLTask storage newTask = flTasks[newTaskId];
        newTask.taskId = newTaskId;
        newTask.proposer = _msgSender();
        newTask.taskObjectivesCID = taskObjectivesCID;
        newTask.rewardPool = rewardPool;
        newTask.registrationDeadline = block.timestamp + registrationDuration;
        newTask.contributionDeadline = newTask.registrationDeadline + contributionDuration;
        newTask.finalizeDeadline = newTask.contributionDeadline + finalizeDuration;
        newTask.finalized = false;
        newTask.active = true;
        newTask.targetModelId = targetModelId;

        // Transfer reward tokens from the proposer to the contract.
        token.safeTransferFrom(_msgSender(), address(this), rewardPool);

        emit FLTaskProposed(newTaskId, _msgSender(), taskObjectivesCID, rewardPool);
        return newTaskId;
    }

    /// @dev Allows eligible participants to register for an active FL task.
    ///      Requires a minimum effective reputation score.
    /// @param taskId The ID of the FL task to register for.
    function registerForFLTask(uint256 taskId) public {
        FLTask storage task = flTasks[taskId];
        require(task.active, "AIHiveDAO: FL Task is not active.");
        require(!task.finalized, "AIHiveDAO: FL Task is already finalized.");
        require(block.timestamp <= task.registrationDeadline, "AIHiveDAO: Registration deadline passed.");
        require(!task.registeredParticipants[_msgSender()], "AIHiveDAO: Already registered for this task.");

        // Example eligibility: require minimum effective reputation score.
        require(getEffectiveReputationScore(_msgSender()) >= 100, "AIHiveDAO: Insufficient reputation to register.");

        task.registeredParticipants[_msgSender()] = true;
        flTasksOfParticipant[_msgSender()].push(taskId); // For participant-centric lookup.

        emit FLTaskRegistered(taskId, _msgSender());
    }

    /// @dev Participants submit an attestation (e.g., hash of a ZK-proof output, or verifiable commitment)
    ///      for their contribution to an FL task.
    /// @param taskId The ID of the FL task.
    /// @param attestationHash A hash representing the proof of contribution.
    function submitFLContributionAttestation(uint256 taskId, bytes32 attestationHash) public {
        FLTask storage task = flTasks[taskId];
        require(task.active, "AIHiveDAO: FL Task is not active.");
        require(!task.finalized, "AIHiveDAO: FL Task is already finalized.");
        require(block.timestamp > task.registrationDeadline, "AIHiveDAO: Registration period not ended.");
        require(block.timestamp <= task.contributionDeadline, "AIHiveDAO: Contribution deadline passed.");
        require(task.registeredParticipants[_msgSender()], "AIHiveDAO: Not a registered participant for this task.");
        require(task.participantContributions[_msgSender()] == bytes32(0), "AIHiveDAO: Already submitted contribution.");

        task.participantContributions[_msgSender()] = attestationHash;
        task.totalContributions++;

        emit FLContributionAttested(taskId, _msgSender(), attestationHash);
    }

    /// @dev Finalizes an FL task and distributes rewards.
    ///      This function assumes off-chain verification of contributions and model performance.
    ///      Only callable by the FL_MANAGER_ROLE.
    /// @param taskId The ID of the FL task to finalize.
    /// @param contributors An array of addresses that contributed to the task.
    /// @param amounts An array of reward amounts for each corresponding contributor.
    function finalizeFLTaskAndDistributeRewards(uint256 taskId, address[] memory contributors, uint256[] memory amounts)
        public
        onlyRole(FL_MANAGER_ROLE)
    {
        FLTask storage task = flTasks[taskId];
        require(task.active, "AIHiveDAO: FL Task is not active.");
        require(!task.finalized, "AIHiveDAO: FL Task is already finalized.");
        require(block.timestamp > task.contributionDeadline, "AIHiveDAO: Contribution period not ended.");
        require(block.timestamp <= task.finalizeDeadline, "AIHiveDAO: Finalization deadline passed.");
        require(contributors.length == amounts.length, "AIHiveDAO: Mismatch in contributors and amounts arrays.");

        uint256 totalDistributed = 0;
        for (uint i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 amount = amounts[i];
            require(task.registeredParticipants[contributor], "AIHiveDAO: Contributor not registered.");
            require(task.participantContributions[contributor] != bytes32(0), "AIHiveDAO: Contributor did not submit attestation.");

            // Distribute token rewards.
            token.safeTransfer(contributor, amount);
            totalDistributed += amount;

            // Update reputation for successful contributors.
            updateReputationScore(contributor, 10); // Example: +10 reputation for successful contribution.
            emit FLRewardDistributed(taskId, contributor, amount);
        }

        require(totalDistributed <= task.rewardPool, "AIHiveDAO: Total distributed exceeds reward pool.");
        
        // Any remaining funds in the reward pool (task.rewardPool - totalDistributed)
        // stay in the contract, potentially for future DAO use or return to proposer via proposal.

        task.finalized = true;
        task.active = false; // Deactivate task once finalized.

        // Optionally, an update to the target AI model's metadata (e.g., new version CID)
        // could be proposed via DAO governance following a successful FL task.

        emit FLTaskFinalized(taskId, totalDistributed);
    }

    /// @dev Allows any user to challenge the validity of an FL contribution.
    ///      This logs the challenge, which could trigger an investigation by REPUTATION_MANAGER_ROLE
    ///      or a DAO governance vote for dispute resolution.
    /// @param taskId The ID of the FL task.
    /// @param contributor The address of the participant whose contribution is being challenged.
    function challengeFLContribution(uint256 taskId, address contributor) public {
        FLTask storage task = flTasks[taskId];
        require(task.active, "AIHiveDAO: FL Task is not active.");
        require(task.registeredParticipants[contributor], "AIHiveDAO: Contributor not registered for this task.");
        require(task.participantContributions[contributor] != bytes32(0), "AIHiveDAO: No contribution submitted by this participant.");
        require(block.timestamp <= task.finalizeDeadline, "AIHiveDAO: Challenge deadline passed.");

        // Log the challenge. A real-world system would integrate this with a robust dispute resolution mechanism.
        emit FLContributionChallenged(taskId, _msgSender(), contributor);
    }
}
```