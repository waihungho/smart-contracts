This smart contract, named **Aethelgard**, is a decentralized, intergenerational stewardship protocol. Its core purpose is to safeguard valuable knowledge, digital assets, and critical decisions for future generations. It leverages concepts like time-locked release, conditional access, and a unique "Generational Wisdom" system where current participants contribute insights intended to guide future stewards.

### Outline and Function Summary

**I. Core Protocol Management (Epochs & State)**
*   **`constructor()`**: Initializes the contract with an owner and sets the first epoch.
*   **`advanceEpoch()`**: Moves the protocol to the next predefined epoch if the minimum duration has passed.
*   **`getCurrentEpoch()`**: Returns the current active epoch's ID.
*   **`getEpochParameters(uint256 _epochId)`**: Retrieves the parameters for a specific epoch.
*   **`setEpochParameters(uint256 _epochId, EpochParams calldata _params)`**: Sets or updates specific parameters for a future epoch (e.g., minimum duration, governance multipliers).

**II. Asset Stewardship (ERC-20 & ERC-721)**
*   **`depositERC20(address _token, uint256 _amount, uint256 _releaseEpoch)`**: Deposits ERC-20 tokens into stewardship, specifying the epoch when they become releasable.
*   **`getDepositorERC20Claim(address _token, address _depositor, uint256 _releaseEpoch)`**: Retrieves the amount of ERC-20 tokens a specific depositor has claimed for a given release epoch.
*   **`releaseEpochERC20(address _token, address _recipient, uint256 _releaseEpoch)`**: Allows the release of ERC-20 tokens to a recipient once their designated release epoch has been reached or passed.
*   **`depositERC721(address _nftContract, uint256 _tokenId, uint256 _releaseEpoch)`**: Deposits an ERC-721 NFT into stewardship, specifying the epoch when it becomes releasable.
*   **`getDepositedERC721Details(address _nftContract, uint256 _tokenId)`**: Retrieves the details (depositor, release epoch) of a stewarded ERC-721 NFT.
*   **`releaseEpochERC721(address _nftContract, uint256 _tokenId, address _recipient)`**: Allows the release of an ERC-721 NFT to a recipient once its designated release epoch has been reached or passed.
*   **`emergencyAssetRecovery(address _token, address _recipient, uint256 _amount)`**: A sentinel-only function for critical asset recovery in emergencies (e.g., bug, forgotten keys).

**III. Knowledge & Insight Management (IPFS/Data Hashes)**
*   **`submitGenerationalInsight(bytes32 _ipfsHash, string calldata _description, uint256 _targetEpoch)`**: Submits an insight (represented by an IPFS hash) intended for a future generation/epoch.
*   **`curateInsight(bytes32 _ipfsHash, bool _isValid)`**: Sentinels can validate or invalidate submitted insights, contributing to their `validationScore`.
*   **`getInsightDetails(bytes32 _ipfsHash)`**: Retrieves all details of a submitted insight.
*   **`requestInsightAccess(bytes32 _ipfsHash, uint256 _accessEpoch)`**: A placeholder for a more complex future access control mechanism (not fully implemented, demonstrating concept).

**IV. Generational Governance & Succession**
*   **`proposeEpochShiftPolicy(bytes32 _policyHash, string calldata _description)`**: Allows an `ActiveSteward` to propose a policy change related to epoch advancement or parameters.
*   **`voteOnPolicy(bytes32 _policyHash, bool _support)`**: Allows `ActiveStewards` to vote on proposed policies. Their vote weight is influenced by `generationalWeights` and current epoch parameters.
*   **`executePolicy(bytes32 _policyHash)`**: Executes an approved policy, applying its changes to the protocol state. (Logic for applying policy changes would be external to this function, or use a call/delegatecall pattern if the policy changes specific contract states, for simplicity, it's just a state change in the Policy struct for this example).
*   **`designateSuccessor(address _heir, uint256 _claimEpoch, bytes32 _proofHash)`**: Designates an address as a successor for a future epoch, requiring an off-chain proof hash for claiming.
*   **`claimSuccession(bytes32 _proofHash)`**: Allows a designated successor to claim their succession rights upon reaching the claim epoch and providing the correct proof hash.
*   **`revokeSuccessor(address _heir)`**: Allows the original designator to revoke a previously designated successor.

**V. Protocol Roles & Parameters**
*   **`setSentinel(address _sentinel, bool _isActivated)`**: Assigns or revokes the `Sentinel` role.
*   **`setActiveSteward(address _steward, bool _isActivated)`**: Assigns or revokes the `ActiveSteward` role.
*   **`updateMinimumEpochDuration(uint256 _newDuration)`**: Updates the global minimum time required between epochs.
*   **`updateInsightValidationThreshold(uint256 _newThreshold)`**: Adjusts the global number of sentinels required to validate an insight.
*   **`updateMinPolicyApprovalRatio(uint256 _newRatio)`**: Adjusts the minimum percentage of 'yes' votes required for a policy to pass.
*   **`updateGenerationalWeight(address _member, uint256 _weight)`**: Adjusts an `ActiveSteward`'s influence in generational governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Interfaces for external contracts
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title Aethelgard
 * @dev A decentralized, intergenerational stewardship protocol designed to safeguard valuable knowledge,
 *      digital assets, and critical decisions for future generations. It leverages time-locked release,
 *      conditional access, and a unique "Generational Wisdom" system where current participants contribute
 *      insights intended to guide future stewards.
 *
 * Outline & Function Summary:
 *
 * I. Core Protocol Management (Epochs & State)
 *    - constructor(): Initializes the contract with an owner and sets the first epoch.
 *    - advanceEpoch(): Moves the protocol to the next predefined epoch if conditions are met.
 *    - getCurrentEpoch(): Returns the current active epoch's ID.
 *    - getEpochParameters(uint256 _epochId): Retrieves the parameters for a specific epoch.
 *    - setEpochParameters(uint256 _epochId, EpochParams calldata _params): Sets or updates specific parameters for a future epoch.
 *
 * II. Asset Stewardship (ERC-20 & ERC-721)
 *    - depositERC20(address _token, uint256 _amount, uint256 _releaseEpoch): Deposits ERC-20 tokens for future release.
 *    - getDepositorERC20Claim(address _token, address _depositor, uint256 _releaseEpoch): Retrieves ERC-20 claims.
 *    - releaseEpochERC20(address _token, address _recipient, uint256 _releaseEpoch): Releases ERC-20 tokens that have reached their epoch.
 *    - depositERC721(address _nftContract, uint256 _tokenId, uint256 _releaseEpoch): Deposits an ERC-721 NFT for future release.
 *    - getDepositedERC721Details(address _nftContract, uint256 _tokenId): Retrieves ERC-721 deposit details.
 *    - releaseEpochERC721(address _nftContract, uint256 _tokenId, address _recipient): Releases an ERC-721 NFT that has reached its epoch.
 *    - emergencyAssetRecovery(address _token, address _recipient, uint256 _amount): Sentinel-only asset recovery.
 *
 * III. Knowledge & Insight Management (IPFS/Data Hashes)
 *    - submitGenerationalInsight(bytes32 _ipfsHash, string calldata _description, uint256 _targetEpoch): Submits insights for future generations.
 *    - curateInsight(bytes32 _ipfsHash, bool _isValid): Sentinels validate/invalidate insights.
 *    - getInsightDetails(bytes32 _ipfsHash): Retrieves details of a submitted insight.
 *    - requestInsightAccess(bytes32 _ipfsHash, uint256 _accessEpoch): Requests access to a time-locked insight (conceptual).
 *
 * IV. Generational Governance & Succession
 *    - proposeEpochShiftPolicy(bytes32 _policyHash, string calldata _description): Proposes policy changes.
 *    - voteOnPolicy(bytes32 _policyHash, bool _support): Allows stewards to vote on policies.
 *    - executePolicy(bytes32 _policyHash): Executes an approved policy.
 *    - designateSuccessor(address _heir, uint256 _claimEpoch, bytes32 _proofHash): Designates an heir for future claims.
 *    - claimSuccession(bytes32 _proofHash): Allows an heir to claim succession.
 *    - revokeSuccessor(address _heir): Revokes a succession designation.
 *
 * V. Protocol Roles & Parameters
 *    - setSentinel(address _sentinel, bool _isActivated): Assigns/revokes Sentinel roles.
 *    - setActiveSteward(address _steward, bool _isActivated): Assigns/revokes ActiveSteward roles.
 *    - updateMinimumEpochDuration(uint256 _newDuration): Updates global minimum epoch duration.
 *    - updateInsightValidationThreshold(uint256 _newThreshold): Updates global insight validation threshold.
 *    - updateMinPolicyApprovalRatio(uint256 _newRatio): Updates minimum policy approval percentage.
 *    - updateGenerationalWeight(address _member, uint256 _weight): Adjusts steward voting power.
 */
contract Aethelgard is Ownable, IERC721Receiver {
    // --- Structs ---

    struct EpochParams {
        uint256 minDurationUntilNextEpoch; // Minimum time duration (in seconds) before the next epoch can be initiated
        uint256 insightValidationThresholdOverride; // Specific threshold for this epoch, if 0, uses global
        uint256 governanceWeightMultiplier; // Multiplier for voting power during this epoch
        bool isActive; // If false, epoch parameters haven't been set yet
    }

    struct DepositedERC721 {
        address depositor;
        uint256 releaseEpoch;
        bool isReleased; // To prevent double release
    }

    struct Insight {
        bytes32 ipfsHash;
        address submitter;
        uint256 targetEpoch; // The epoch for which this insight is intended
        uint256 validationScore; // Number of sentinels who validated it
        bool isInvalidated; // If it was explicitly marked invalid by sentinels
        string description;
        uint256 submissionTime;
    }

    struct Policy {
        bytes32 policyHash; // Hash of the proposed policy details (e.g., IPFS hash to a document describing the policy)
        address proposer;
        uint256 creationEpoch;
        mapping(address => bool) hasVoted; // Tracks if a steward has voted on this policy
        uint256 yesVotes;
        uint256 noVotes;
        bool isApproved; // Whether the policy passed the voting
        bool isExecuted; // Whether the policy changes have been applied (conceptual for this example)
        string description;
    }

    struct SuccessorDesignation {
        address heir;
        uint256 claimEpoch; // The epoch when the heir can claim
        bytes32 proofHash; // Hash of off-chain proof, heir needs to provide to claim
        address designator;
        bool isActive; // Can be revoked by the designator
    }

    // --- State Variables ---

    uint256 public currentEpochId;
    uint256 public lastEpochAdvanceTime; // Timestamp of the last epoch advancement

    // Roles
    mapping(address => bool) public isSentinel; // Sentinels have specific administrative rights (e.g., emergency recovery, insight curation)
    mapping(address => bool) public isActiveSteward; // Active Stewards can propose and vote on policies, contribute insights

    // Global Protocol Parameters
    uint256 public minimumEpochDuration; // Global minimum duration (in seconds) between epochs (e.g., 1 year = 31536000)
    uint256 public insightValidationThreshold; // Global number of sentinels needed to validate an insight
    uint256 public minPolicyApprovalRatio; // Minimum percentage of 'yes' votes (e.g., 51 for 51%)

    // Mappings for data storage
    mapping(uint256 => EpochParams) private _epochParameters; // epochId => EpochParams
    
    // ERC-20 Stewardship: tokenAddress => depositorAddress => releaseEpoch => amount
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _depositorERC20Claims;
    // Total pooled ERC-20 assets held by the contract for stewardship
    mapping(address => uint256) public totalStewardshipERC20Balances;

    // ERC-721 Stewardship: nftContractAddress => tokenId => DepositedERC721
    mapping(address => mapping(uint256 => DepositedERC721)) private _depositedERC721s;

    // Knowledge & Insight: ipfsHash => Insight
    mapping(bytes32 => Insight) private _generationalInsights;

    // Generational Governance: policyHash => Policy
    mapping(bytes32 => Policy) private _epochShiftPolicies;

    // Succession: designatorAddress => heirAddress => SuccessorDesignation
    mapping(address => mapping(address => SuccessorDesignation)) private _successorDesignations;
    
    // Voting power
    mapping(address => uint256) public generationalWeights; // Weight of an active steward in governance
    uint256 public totalActiveStewardWeight; // Sum of all active stewards' weights

    // --- Events ---

    event EpochAdvanced(uint256 indexed newEpochId, uint256 timestamp);
    event ERC20Deposited(address indexed token, address indexed depositor, uint256 amount, uint256 releaseEpoch);
    event ERC20Released(address indexed token, address indexed recipient, uint256 amount, uint256 releaseEpoch);
    event ERC721Deposited(address indexed nftContract, uint256 indexed tokenId, address indexed depositor, uint256 releaseEpoch);
    event ERC721Released(address indexed nftContract, uint256 indexed tokenId, address indexed recipient, uint256 releaseEpoch);
    event EmergencyAssetRecovered(address indexed token, address indexed recipient, uint256 amount, address indexed sentinel);
    event GenerationalInsightSubmitted(bytes32 indexed ipfsHash, address indexed submitter, uint256 targetEpoch);
    event InsightCurated(bytes32 indexed ipfsHash, address indexed curator, bool isValidated, uint256 newValidationScore);
    event InsightAccessRequested(bytes32 indexed ipfsHash, address indexed requester, uint256 accessEpoch);
    event EpochShiftPolicyProposed(bytes32 indexed policyHash, address indexed proposer, uint256 creationEpoch);
    event PolicyVoted(bytes32 indexed policyHash, address indexed voter, bool support, uint256 currentEpoch);
    event PolicyApproved(bytes32 indexed policyHash);
    event PolicyExecuted(bytes32 indexed policyHash);
    event SuccessorDesignated(address indexed designator, address indexed heir, uint256 claimEpoch);
    event SuccessionClaimed(address indexed heir, uint256 claimEpoch);
    event SuccessorRevoked(address indexed designator, address indexed heir);
    event SentinelRoleUpdated(address indexed sentinel, bool isActivated);
    event ActiveStewardRoleUpdated(address indexed steward, bool isActivated);
    event MinimumEpochDurationUpdated(uint256 newDuration);
    event InsightValidationThresholdUpdated(uint256 newThreshold);
    event GenerationalWeightUpdated(address indexed steward, uint256 oldWeight, uint256 newWeight);
    event EpochParametersUpdated(uint256 indexed epochId, uint256 minDuration, uint256 insightThreshold, uint256 weightMultiplier);

    // --- Modifiers ---

    modifier onlySentinel() {
        require(isSentinel[_msgSender()], "Aethelgard: Caller is not a sentinel");
        _;
    }

    modifier onlyActiveSteward() {
        require(isActiveSteward[_msgSender()], "Aethelgard: Caller is not an active steward");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(_msgSender()) {
        currentEpochId = 1;
        lastEpochAdvanceTime = block.timestamp;
        minimumEpochDuration = 31536000; // Default: 1 year in seconds
        insightValidationThreshold = 3; // Default: 3 sentinels for validation
        minPolicyApprovalRatio = 51; // Default: 51% approval

        // Initialize parameters for the first epoch
        _epochParameters[currentEpochId] = EpochParams({
            minDurationUntilNextEpoch: minimumEpochDuration,
            insightValidationThresholdOverride: 0, // Use global
            governanceWeightMultiplier: 1,
            isActive: true
        });

        // The owner is also an initial active steward with a base weight
        isActiveSteward[_msgSender()] = true;
        generationalWeights[_msgSender()] = 100;
        totalActiveStewardWeight = 100;

        emit EpochAdvanced(currentEpochId, block.timestamp);
    }

    // --- Core Protocol Management (Epochs & State) ---

    /**
     * @dev Advances the protocol to the next epoch.
     *      Can be called by anyone, but must respect the minimum epoch duration.
     */
    function advanceEpoch() public {
        EpochParams storage currentEpochParams = _epochParameters[currentEpochId];
        uint256 effectiveMinDuration = currentEpochParams.isActive && currentEpochParams.minDurationUntilNextEpoch > 0
                                     ? currentEpochParams.minDurationUntilNextEpoch
                                     : minimumEpochDuration;

        require(block.timestamp >= lastEpochAdvanceTime + effectiveMinDuration, "Aethelgard: Not enough time has passed for next epoch");

        currentEpochId++;
        lastEpochAdvanceTime = block.timestamp;

        // If parameters for the new epoch haven't been set, initialize with current global defaults
        if (!_epochParameters[currentEpochId].isActive) {
            _epochParameters[currentEpochId] = EpochParams({
                minDurationUntilNextEpoch: minimumEpochDuration,
                insightValidationThresholdOverride: 0,
                governanceWeightMultiplier: 1,
                isActive: true
            });
        }

        emit EpochAdvanced(currentEpochId, block.timestamp);
    }

    /**
     * @dev Returns the current active epoch's ID.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpochId;
    }

    /**
     * @dev Retrieves the parameters for a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return EpochParams struct containing the parameters.
     */
    function getEpochParameters(uint256 _epochId) public view returns (EpochParams memory) {
        return _epochParameters[_epochId];
    }

    /**
     * @dev Sets or updates specific parameters for a future epoch. Only callable by the owner.
     *      This allows long-term planning for how future epochs should behave.
     * @param _epochId The ID of the epoch to set parameters for (must be greater than current).
     * @param _params The new EpochParams struct.
     */
    function setEpochParameters(uint256 _epochId, EpochParams calldata _params) public onlyOwner {
        require(_epochId > currentEpochId, "Aethelgard: Cannot set parameters for current or past epochs directly via this function.");
        _epochParameters[_epochId] = _params;
        _epochParameters[_epochId].isActive = true; // Mark as explicitly set

        emit EpochParametersUpdated(
            _epochId,
            _params.minDurationUntilNextEpoch,
            _params.insightValidationThresholdOverride,
            _params.governanceWeightMultiplier
        );
    }

    // --- Asset Stewardship (ERC-20 & ERC-721) ---

    /**
     * @dev Deposits ERC-20 tokens into stewardship, specifying the epoch when they become releasable.
     *      Tokens are transferred to the contract, and a claim is recorded for the depositor.
     * @param _token The address of the ERC-20 token.
     * @param _amount The amount of tokens to deposit.
     * @param _releaseEpoch The epoch ID when these tokens can be released.
     */
    function depositERC20(address _token, uint256 _amount, uint256 _releaseEpoch) public {
        require(_amount > 0, "Aethelgard: Deposit amount must be greater than zero.");
        require(_releaseEpoch > currentEpochId, "Aethelgard: Release epoch must be in the future.");

        IERC20 token = IERC20(_token);
        require(token.transferFrom(_msgSender(), address(this), _amount), "Aethelgard: ERC20 transfer failed.");

        _depositorERC20Claims[_token][_msgSender()][_releaseEpoch] += _amount;
        totalStewardshipERC20Balances[_token] += _amount;

        emit ERC20Deposited(_token, _msgSender(), _amount, _releaseEpoch);
    }

    /**
     * @dev Retrieves the amount of ERC-20 tokens a specific depositor has claimed for a given release epoch.
     * @param _token The address of the ERC-20 token.
     * @param _depositor The address of the original depositor.
     * @param _releaseEpoch The designated release epoch.
     * @return The amount of tokens claimed.
     */
    function getDepositorERC20Claim(address _token, address _depositor, uint256 _releaseEpoch) public view returns (uint256) {
        return _depositorERC20Claims[_token][_depositor][_releaseEpoch];
    }

    /**
     * @dev Allows the release of ERC-20 tokens to a recipient once their designated release epoch has been reached or passed.
     *      Anyone can call this to trigger the release for a specified recipient and epoch.
     * @param _token The address of the ERC-20 token.
     * @param _recipient The address to send the released tokens to.
     * @param _releaseEpoch The epoch ID for which to release tokens.
     */
    function releaseEpochERC20(address _token, address _recipient, uint256 _releaseEpoch) public {
        require(currentEpochId >= _releaseEpoch, "Aethelgard: Release epoch not yet reached.");
        require(_recipient != address(0), "Aethelgard: Recipient cannot be zero address.");

        uint256 amountToRelease = _depositorERC20Claims[_token][_recipient][_releaseEpoch];
        require(amountToRelease > 0, "Aethelgard: No claims found for this recipient at this epoch.");

        _depositorERC20Claims[_token][_recipient][_releaseEpoch] = 0; // Clear the claim
        totalStewardshipERC20Balances[_token] -= amountToRelease;

        IERC20 token = IERC20(_token);
        require(token.transfer(_recipient, amountToRelease), "Aethelgard: ERC20 transfer to recipient failed.");

        emit ERC20Released(_token, _recipient, amountToRelease, _releaseEpoch);
    }

    /**
     * @dev Deposits an ERC-721 NFT into stewardship, specifying the epoch when it becomes releasable.
     *      The NFT is transferred to the contract.
     * @param _nftContract The address of the ERC-721 contract.
     * @param _tokenId The ID of the NFT to deposit.
     * @param _releaseEpoch The epoch ID when this NFT can be released.
     */
    function depositERC721(address _nftContract, uint256 _tokenId, uint256 _releaseEpoch) public {
        require(_releaseEpoch > currentEpochId, "Aethelgard: Release epoch must be in the future.");
        require(_depositedERC721s[_nftContract][_tokenId].depositor == address(0), "Aethelgard: NFT already stewarded or invalid ID.");

        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == _msgSender(), "Aethelgard: Caller is not the owner of the NFT.");
        nft.transferFrom(_msgSender(), address(this), _tokenId);

        _depositedERC721s[_nftContract][_tokenId] = DepositedERC721({
            depositor: _msgSender(),
            releaseEpoch: _releaseEpoch,
            isReleased: false
        });

        emit ERC721Deposited(_nftContract, _tokenId, _msgSender(), _releaseEpoch);
    }

    /**
     * @dev Retrieves the details (depositor, release epoch) of a stewarded ERC-721 NFT.
     * @param _nftContract The address of the ERC-721 contract.
     * @param _tokenId The ID of the NFT.
     * @return DepositedERC721 struct.
     */
    function getDepositedERC721Details(address _nftContract, uint256 _tokenId) public view returns (DepositedERC721 memory) {
        return _depositedERC721s[_nftContract][_tokenId];
    }

    /**
     * @dev Allows the release of an ERC-721 NFT to a recipient once its designated release epoch has been reached or passed.
     *      Anyone can call this to trigger the release for a specified recipient and epoch.
     * @param _nftContract The address of the ERC-721 contract.
     * @param _tokenId The ID of the NFT to release.
     * @param _recipient The address to send the released NFT to.
     */
    function releaseEpochERC721(address _nftContract, uint256 _tokenId, address _recipient) public {
        DepositedERC721 storage nftDetails = _depositedERC721s[_nftContract][_tokenId];
        
        require(nftDetails.depositor != address(0), "Aethelgard: NFT not stewarded.");
        require(!nftDetails.isReleased, "Aethelgard: NFT already released.");
        require(currentEpochId >= nftDetails.releaseEpoch, "Aethelgard: Release epoch not yet reached.");
        require(_recipient != address(0), "Aethelgard: Recipient cannot be zero address.");

        nftDetails.isReleased = true; // Mark as released

        IERC721 nft = IERC721(_nftContract);
        nft.transferFrom(address(this), _recipient, _tokenId);

        emit ERC721Released(_nftContract, _tokenId, _recipient, nftDetails.releaseEpoch);
    }

    /**
     * @dev Sentinel-only function for emergency asset recovery (e.g., in case of a bug, forgotten keys for a token, etc.).
     *      This is a powerful function and should be used with extreme caution and multisig if possible.
     * @param _token The address of the ERC-20 token to recover.
     * @param _recipient The address to send the recovered tokens to.
     * @param _amount The amount to recover.
     */
    function emergencyAssetRecovery(address _token, address _recipient, uint256 _amount) public onlySentinel {
        require(_token != address(0), "Aethelgard: Token address cannot be zero.");
        require(_recipient != address(0), "Aethelgard: Recipient address cannot be zero.");
        require(_amount > 0, "Aethelgard: Amount must be greater than zero.");

        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Aethelgard: Not enough balance for recovery.");
        require(token.transfer(_recipient, _amount), "Aethelgard: Emergency ERC20 transfer failed.");

        // Note: This does not adjust _depositorERC20Claims, as it's an emergency bypass.
        // It's assumed such a scenario would have off-chain consensus/recovery plan.
        totalStewardshipERC20Balances[_token] -= _amount;

        emit EmergencyAssetRecovered(_token, _recipient, _amount, _msgSender());
    }

    // --- Knowledge & Insight Management (IPFS/Data Hashes) ---

    /**
     * @dev Submits an insight (represented by an IPFS hash) intended for a future generation/epoch.
     *      Only Active Stewards can submit insights.
     * @param _ipfsHash The IPFS hash pointing to the content of the insight.
     * @param _description A brief description of the insight.
     * @param _targetEpoch The epoch for which this insight is specifically relevant or intended.
     */
    function submitGenerationalInsight(bytes32 _ipfsHash, string calldata _description, uint256 _targetEpoch) public onlyActiveSteward {
        require(_ipfsHash != 0, "Aethelgard: IPFS hash cannot be zero.");
        require(_generationalInsights[_ipfsHash].submitter == address(0), "Aethelgard: Insight already submitted.");
        require(_targetEpoch > currentEpochId, "Aethelgard: Target epoch must be in the future.");

        _generationalInsights[_ipfsHash] = Insight({
            ipfsHash: _ipfsHash,
            submitter: _msgSender(),
            targetEpoch: _targetEpoch,
            validationScore: 0,
            isInvalidated: false,
            description: _description,
            submissionTime: block.timestamp
        });

        emit GenerationalInsightSubmitted(_ipfsHash, _msgSender(), _targetEpoch);
    }

    /**
     * @dev Sentinels can validate or invalidate submitted insights, contributing to their `validationScore`.
     *      Multiple sentinels can validate the same insight.
     * @param _ipfsHash The IPFS hash of the insight to curate.
     * @param _isValid True to validate, false to mark as invalid.
     */
    function curateInsight(bytes32 _ipfsHash, bool _isValid) public onlySentinel {
        Insight storage insight = _generationalInsights[_ipfsHash];
        require(insight.submitter != address(0), "Aethelgard: Insight does not exist.");
        require(!insight.isInvalidated, "Aethelgard: Insight has already been invalidated.");

        // A sentinel can only validate/invalidate once. This is a simplified check.
        // A more advanced system would track individual sentinel votes.
        if (_isValid) {
            insight.validationScore++;
            // Check if validation threshold is met, potentially triggering an event or state change
            uint256 effectiveThreshold = _epochParameters[currentEpochId].insightValidationThresholdOverride > 0
                                       ? _epochParameters[currentEpochId].insightValidationThresholdOverride
                                       : insightValidationThreshold;
            if (insight.validationScore >= effectiveThreshold) {
                // Potentially trigger something when an insight is "officially" validated
            }
        } else {
            insight.isInvalidated = true; // One sentinel can invalidate (stronger action)
        }

        emit InsightCurated(_ipfsHash, _msgSender(), _isValid, insight.validationScore);
    }

    /**
     * @dev Retrieves all details of a submitted insight.
     * @param _ipfsHash The IPFS hash of the insight.
     * @return Insight struct.
     */
    function getInsightDetails(bytes32 _ipfsHash) public view returns (Insight memory) {
        return _generationalInsights[_ipfsHash];
    }

    /**
     * @dev Requests access to an insight for a specific future epoch. (Conceptual function)
     *      This would ideally involve some approval mechanism, stake, or payment in a real DApp.
     *      For this example, it's a simple event emission to show the intent.
     * @param _ipfsHash The IPFS hash of the insight.
     * @param _accessEpoch The epoch for which access is requested.
     */
    function requestInsightAccess(bytes32 _ipfsHash, uint256 _accessEpoch) public {
        require(_generationalInsights[_ipfsHash].submitter != address(0), "Aethelgard: Insight does not exist.");
        require(currentEpochId < _accessEpoch, "Aethelgard: Access epoch must be in the future.");
        // Additional complex logic for conditional access (e.g., stake, governance vote, special role) would go here.
        emit InsightAccessRequested(_ipfsHash, _msgSender(), _accessEpoch);
    }

    // --- Generational Governance & Succession ---

    /**
     * @dev Allows an `ActiveSteward` to propose a policy change related to epoch advancement or parameters.
     *      The `_policyHash` should point to an off-chain document describing the full policy.
     * @param _policyHash The IPFS hash or similar identifier for the policy document.
     * @param _description A brief description of the proposed policy.
     */
    function proposeEpochShiftPolicy(bytes32 _policyHash, string calldata _description) public onlyActiveSteward {
        require(_policyHash != 0, "Aethelgard: Policy hash cannot be zero.");
        require(_epochShiftPolicies[_policyHash].proposer == address(0), "Aethelgard: Policy already proposed.");

        _epochShiftPolicies[_policyHash] = Policy({
            policyHash: _policyHash,
            proposer: _msgSender(),
            creationEpoch: currentEpochId,
            yesVotes: 0,
            noVotes: 0,
            isApproved: false,
            isExecuted: false,
            description: _description
        });
        // Initial vote by proposer
        _epochShiftPolicies[_policyHash].hasVoted[_msgSender()] = true;
        _epochShiftPolicies[_policyHash].yesVotes += (generationalWeights[_msgSender()] * _epochParameters[currentEpochId].governanceWeightMultiplier);

        emit EpochShiftPolicyProposed(_policyHash, _msgSender(), currentEpochId);
    }

    /**
     * @dev Allows `ActiveStewards` to vote on proposed policies. Their vote weight is influenced by
     *      their `generationalWeights` and the current epoch's `governanceWeightMultiplier`.
     * @param _policyHash The IPFS hash of the policy to vote on.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnPolicy(bytes32 _policyHash, bool _support) public onlyActiveSteward {
        Policy storage policy = _epochShiftPolicies[_policyHash];
        require(policy.proposer != address(0), "Aethelgard: Policy does not exist.");
        require(policy.creationEpoch == currentEpochId, "Aethelgard: Voting is only open in the creation epoch.");
        require(!policy.hasVoted[_msgSender()], "Aethelgard: Already voted on this policy.");
        require(!policy.isApproved, "Aethelgard: Policy already approved.");

        policy.hasVoted[_msgSender()] = true;
        uint256 effectiveWeight = generationalWeights[_msgSender()] * _epochParameters[currentEpochId].governanceWeightMultiplier;

        if (_support) {
            policy.yesVotes += effectiveWeight;
        } else {
            policy.noVotes += effectiveWeight;
        }

        uint256 totalVotes = policy.yesVotes + policy.noVotes;
        if (totalActiveStewardWeight > 0 && totalVotes >= totalActiveStewardWeight / 2) { // Only check if quorum reached (simplified)
            if (policy.yesVotes * 100 / totalVotes >= minPolicyApprovalRatio) {
                policy.isApproved = true;
                emit PolicyApproved(_policyHash);
            }
        }

        emit PolicyVoted(_policyHash, _msgSender(), _support, currentEpochId);
    }

    /**
     * @dev Executes an approved policy. The actual state changes from the policy would be implemented here
     *      or in a dedicated policy handler. For this example, it simply marks the policy as executed.
     *      Only callable by the owner, representing a final check and implementation.
     * @param _policyHash The IPFS hash of the policy to execute.
     */
    function executePolicy(bytes32 _policyHash) public onlyOwner {
        Policy storage policy = _epochShiftPolicies[_policyHash];
        require(policy.isApproved, "Aethelgard: Policy not approved.");
        require(!policy.isExecuted, "Aethelgard: Policy already executed.");

        // Here would be the logic to apply the actual changes described by the policy.
        // For example, if policy.description detailed a change to `minimumEpochDuration`,
        // that change would be implemented here.
        // This could be achieved via:
        // 1. Parsing the policy hash / data (complex on-chain).
        // 2. Having predefined policy types (e.g., policy type 1 = update min epoch duration).
        // 3. Or, the owner manually applies the approved changes through other admin functions.
        // For this example, we'll just mark it as executed.

        policy.isExecuted = true;
        emit PolicyExecuted(_policyHash);
    }

    /**
     * @dev Designates an address as a successor for a future epoch. The `_proofHash` is an off-chain
     *      hash that the heir needs to provide to claim their succession.
     * @param _heir The address of the designated heir.
     * @param _claimEpoch The epoch when the heir can claim succession.
     * @param _proofHash The hash of an off-chain proof (e.g., encrypted document, key fragment).
     */
    function designateSuccessor(address _heir, uint256 _claimEpoch, bytes32 _proofHash) public {
        require(_heir != address(0), "Aethelgard: Heir cannot be zero address.");
        require(_heir != _msgSender(), "Aethelgard: Cannot designate self as heir.");
        require(_claimEpoch > currentEpochId, "Aethelgard: Claim epoch must be in the future.");
        require(_successorDesignations[_msgSender()][_heir].heir == address(0), "Aethelgard: Heir already designated by this sender.");

        _successorDesignations[_msgSender()][_heir] = SuccessorDesignation({
            heir: _heir,
            claimEpoch: _claimEpoch,
            proofHash: _proofHash,
            designator: _msgSender(),
            isActive: true
        });

        emit SuccessorDesignated(_msgSender(), _heir, _claimEpoch);
    }

    /**
     * @dev Allows a designated successor to claim their succession rights upon reaching the claim epoch
     *      and providing the correct proof hash.
     * @param _proofHash The off-chain proof hash provided by the heir.
     */
    function claimSuccession(bytes32 _proofHash) public {
        address potentialHeir = _msgSender();
        bool foundDesignation = false;
        address designatorAddress = address(0);

        // Iterate through all possible designators to find a matching proofHash for the potentialHeir
        // This is inefficient if many designators, but demonstrates the concept without a direct mapping from proofHash
        // In a real system, there would be an index or a different proof mechanism
        for (uint256 i = 0; i < totalActiveStewardWeight; i++) { // Simplified loop example, actual iteration over map keys is hard.
                                                                // A better approach would be to have designators specify heir by address when claiming
                                                                // or requiring the claimant to provide the designator's address
             // This loop is illustrative, direct map iteration over keys is not possible in Solidity
             // For a real implementation, `_successorDesignations[designator][potentialHeir]` would be checked
             // or the heir would provide the designator's address as a parameter.
             // Let's assume the heir provides the designator's address.
            // Simplified: claimant must know their designator and provide it.
            // If we require the claimant to provide the designator, the function signature changes:
            // `function claimSuccession(address _designator, bytes32 _proofHash)`
            // For now, let's keep it as is, and acknowledge this limitation/simplification.
            // The following check would be done in a loop OR if _designator was a param:
            // `SuccessorDesignation storage designation = _successorDesignations[_designator][potentialHeir];`
            // Since `_successorDesignations` is `designator => heir => designation`, we need to know the designator.
            // To make this function work without iterating all designators, the heir needs to provide the `designator` address.
            // Let's change the function signature slightly to make it feasible.
            revert("Aethelgard: To claim, the designator's address must be provided for efficiency.");
            // Example of how it would work if `_designator` was a parameter:
            // SuccessorDesignation storage designation = _successorDesignations[_designator][potentialHeir];
        }

        // For the sake of completing the function, let's assume we magically know the designator.
        // A more robust solution might involve a lookup table for proof hashes or requiring the heir to specify the designator.
        // This is a common challenge with general "claim" functions in Solidity.
        
        // This part of the code is highly simplified/conceptual due to Solidity's map iteration limits.
        // In a practical dApp, the heir would likely prove identity & designator off-chain,
        // or the function would require `_designator` as a parameter.
        // For demonstration, let's assume `_msgSender()` IS the heir AND we know their `designator` through another means or it's a direct mapping.
        
        // Let's modify the design so that `_successorDesignations` maps `proofHash => SuccessorDesignation`
        // This way, the claimant only needs to provide the proofHash.

        // REWIRING SUCCESSION FOR SIMPLICITY: proofHash is the key.
        // This removes the need to iterate designators or pass extra params, making it more "claim-like"
        // But, this means one proofHash can only belong to one designator-heir pair.
    }

    // New version for `designateSuccessor` and `claimSuccession` using `proofHash` as primary key for claims.
    // This allows `claimSuccession` to work without needing to know the designator directly.
    mapping(bytes32 => SuccessorDesignation) private _proofHashSuccessorDesignations; // proofHash => Designation

    /**
     * @dev (Revised) Designates an address as a successor for a future epoch.
     *      The `_proofHash` is the unique identifier for this designation, allowing the heir to claim directly.
     * @param _heir The address of the designated heir.
     * @param _claimEpoch The epoch when the heir can claim succession.
     * @param _proofHash The unique hash of an off-chain proof (e.g., encrypted document, key fragment). Must be unique.
     */
    function designateSuccessor(address _heir, uint256 _claimEpoch, bytes32 _proofHash) public {
        require(_heir != address(0), "Aethelgard: Heir cannot be zero address.");
        require(_heir != _msgSender(), "Aethelgard: Cannot designate self as heir.");
        require(_claimEpoch > currentEpochId, "Aethelgard: Claim epoch must be in the future.");
        require(_proofHash != 0, "Aethelgard: Proof hash cannot be zero.");
        require(_proofHashSuccessorDesignations[_proofHash].designator == address(0), "Aethelgard: Proof hash already used for a designation.");

        _proofHashSuccessorDesignations[_proofHash] = SuccessorDesignation({
            heir: _heir,
            claimEpoch: _claimEpoch,
            proofHash: _proofHash,
            designator: _msgSender(),
            isActive: true
        });
        // Also map designator to proofHashes to allow revocation
        // mapping(address => bytes32[]) private _designatorProofHashes;
        // _designatorProofHashes[_msgSender()].push(_proofHash);
        // This requires `_designatorProofHashes` which means more complex state.
        // For current `revokeSuccessor` to work with this model, it needs the `_proofHash` for revocation.
        // Let's assume `revokeSuccessor` also takes `_proofHash`.

        emit SuccessorDesignated(_msgSender(), _heir, _claimEpoch);
    }

    /**
     * @dev (Revised) Allows a designated successor to claim their succession rights upon reaching the claim epoch
     *      and providing the correct proof hash.
     * @param _proofHash The off-chain proof hash that identifies the succession designation.
     */
    function claimSuccession(bytes32 _proofHash) public {
        SuccessorDesignation storage designation = _proofHashSuccessorDesignations[_proofHash];

        require(designation.designator != address(0), "Aethelgard: No designation found for this proof hash.");
        require(designation.heir == _msgSender(), "Aethelgard: Caller is not the designated heir.");
        require(designation.isActive, "Aethelgard: Designation is not active or has been revoked.");
        require(currentEpochId >= designation.claimEpoch, "Aethelgard: Claim epoch not yet reached.");

        designation.isActive = false; // Claimed designations are no longer active

        // Upon claiming, the heir could potentially inherit roles, funds, etc.
        // This is a placeholder for actual inheritance logic.
        // Example: isActiveSteward[designation.designator] = false;
        //          isActiveSteward[designation.heir] = true;
        //          generationalWeights[designation.heir] = generationalWeights[designation.designator];
        //          generationalWeights[designation.designator] = 0; // Or transfer
        // This logic would need to be carefully designed based on what "succession" means.

        emit SuccessionClaimed(_msgSender(), designation.claimEpoch);
    }

    /**
     * @dev (Revised) Allows the original designator to revoke a previously designated successor using the `_proofHash`.
     * @param _proofHash The unique proof hash of the designation to revoke.
     */
    function revokeSuccessor(bytes32 _proofHash) public {
        SuccessorDesignation storage designation = _proofHashSuccessorDesignations[_proofHash];

        require(designation.designator != address(0), "Aethelgard: No designation found for this proof hash.");
        require(designation.designator == _msgSender(), "Aethelgard: Caller is not the designator.");
        require(designation.isActive, "Aethelgard: Designation is already inactive.");

        designation.isActive = false;

        emit SuccessorRevoked(designation.designator, designation.heir);
    }


    // --- Protocol Roles & Parameters ---

    /**
     * @dev Assigns or revokes the `Sentinel` role. Only callable by the owner.
     * @param _sentinel The address to set/unset as a sentinel.
     * @param _isActivated True to activate, false to deactivate.
     */
    function setSentinel(address _sentinel, bool _isActivated) public onlyOwner {
        require(_sentinel != address(0), "Aethelgard: Sentinel address cannot be zero.");
        isSentinel[_sentinel] = _isActivated;
        emit SentinelRoleUpdated(_sentinel, _isActivated);
    }

    /**
     * @dev Assigns or revokes the `ActiveSteward` role. Only callable by the owner.
     *      Also manages their `generationalWeights` and `totalActiveStewardWeight`.
     * @param _steward The address to set/unset as an active steward.
     * @param _isActivated True to activate, false to deactivate.
     */
    function setActiveSteward(address _steward, bool _isActivated) public onlyOwner {
        require(_steward != address(0), "Aethelgard: Steward address cannot be zero.");
        if (_isActivated && !isActiveSteward[_steward]) {
            isActiveSteward[_steward] = true;
            generationalWeights[_steward] = 100; // Default base weight
            totalActiveStewardWeight += 100;
        } else if (!_isActivated && isActiveSteward[_steward]) {
            isActiveSteward[_steward] = false;
            totalActiveStewardWeight -= generationalWeights[_steward];
            generationalWeights[_steward] = 0; // Remove weight
        }
        emit ActiveStewardRoleUpdated(_steward, _isActivated);
    }

    /**
     * @dev Updates the global minimum time required between epochs. Only callable by the owner.
     * @param _newDuration The new minimum duration in seconds.
     */
    function updateMinimumEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Aethelgard: Duration must be greater than zero.");
        minimumEpochDuration = _newDuration;
        emit MinimumEpochDurationUpdated(_newDuration);
    }

    /**
     * @dev Updates the global number of sentinels required to validate an insight. Only callable by the owner.
     * @param _newThreshold The new insight validation threshold.
     */
    function updateInsightValidationThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold > 0, "Aethelgard: Threshold must be greater than zero.");
        insightValidationThreshold = _newThreshold;
        emit InsightValidationThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Updates the minimum percentage of 'yes' votes required for a policy to pass. Only callable by the owner.
     * @param _newRatio The new ratio (e.g., 51 for 51%).
     */
    function updateMinPolicyApprovalRatio(uint256 _newRatio) public onlyOwner {
        require(_newRatio > 0 && _newRatio <= 100, "Aethelgard: Ratio must be between 1 and 100.");
        minPolicyApprovalRatio = _newRatio;
        emit UpdateMinPolicyApprovalRatio(_newRatio); // Event name typo in planning, let's use a new event
    }
    event UpdateMinPolicyApprovalRatio(uint256 newRatio);


    /**
     * @dev Adjusts an `ActiveSteward`'s influence (voting power) in generational governance. Only callable by the owner.
     * @param _member The address of the steward.
     * @param _weight The new weight to assign to the steward.
     */
    function updateGenerationalWeight(address _member, uint256 _weight) public onlyOwner {
        require(isActiveSteward[_member], "Aethelgard: Member is not an active steward.");
        uint256 oldWeight = generationalWeights[_member];
        generationalWeights[_member] = _weight;
        totalActiveStewardWeight = totalActiveStewardWeight - oldWeight + _weight;
        emit GenerationalWeightUpdated(_member, oldWeight, _weight);
    }

    // --- ERC721Receiver Interface ---
    // Required to receive ERC721 tokens safely
    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
```