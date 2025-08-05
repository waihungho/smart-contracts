This smart contract, named **"NexusForge"**, aims to create a decentralized network for verifiable contributions, leveraging dynamic Soulbound Tokens (SBTs) as reputation profiles. It introduces advanced concepts like skill-tree based reputation, a community-driven attestation mechanism with dispute resolution, and reputation-gated access to features and rewards. It avoids duplicating existing open-source projects by combining these elements in a novel way.

---

## NexusForge: Decentralized Contribution & Reputation Network

### Contract Overview
NexusForge is a sophisticated Solidity smart contract designed to facilitate and verify contributions within a decentralized network. It introduces a novel approach to reputation management by linking verifiable contributions to dynamic Soulbound Tokens (SBTs) that evolve based on a user's activity and reputation across different skill categories. This system incentivizes valuable participation and gates access to network features based on proven expertise and trustworthiness.

### Core Concepts
1.  **Verifiable Contributions:** Users submit proof of their off-chain or on-chain contributions (e.g., data submission, service provision, open-source code, research).
2.  **Attestation Mechanism:** Designated "Attestors" (who themselves have earned reputation) review and verify these contributions. This decentralizes the verification process.
3.  **Dynamic Soulbound Profiles (SBTs):** Each participant possesses a non-transferable Soulbound Profile NFT. This NFT's metadata and visual representation dynamically update to reflect their accumulated reputation, skill levels, and achievements within the network.
4.  **Skill-Tree Reputation:** Reputation isn't monolithic; it's categorized into different "Skill Trees" (e.g., `DataCollection`, `CodeReview`, `Research`). Users gain reputation within specific skill categories, allowing for granular recognition of expertise.
5.  **Reputation-Gated Access:** Certain advanced features, higher reward multipliers, or governance voting power are only accessible to users who meet specific reputation thresholds or skill levels.
6.  **Dispute Resolution:** A mechanism for challenging false attestations or rejections, managed by elected "Network Operators" or a DAO.
7.  **Native Utility Token (`CONTR`):** An ERC20 token used for rewarding contributions and potentially for staking by Attestors or for accessing premium features.

### Key Features
*   **Decentralized Identity:** Your SBT is your persistent, non-transferable identity in the network.
*   **Gamified Progression:** Earn points, level up in skills, and see your SBT evolve.
*   **Proof-of-Contribution:** A robust system for validating real-world or digital contributions.
*   **Community-Driven Verification:** Empowering trusted members (Attestors) to verify work.
*   **Anti-Sybil:** SBTs inherently resist sybil attacks by being non-transferable and tied to verifiable activity.
*   **Dynamic Rewards:** Reward multipliers adjust based on contribution value, skill category, and potentially network demand.

### Function Summary

**I. Core Setup & Admin Functions (Managed by Owner/Network Operator)**
1.  `constructor()`: Initializes the contract with the `CONTR` token address and sets the initial owner.
2.  `setNetworkOperator(address _newOperator)`: Sets the address designated as the network operator, responsible for high-level management and dispute resolution.
3.  `addSkillCategory(bytes32 _categoryId, string memory _name, uint256 _baseRewardMultiplier)`: Registers a new category for contributions (e.g., "Data Collection", "Code Review").
4.  `updateSkillCategory(bytes32 _categoryId, string memory _newName, uint256 _newBaseRewardMultiplier)`: Modifies details of an existing skill category.
5.  `addAttestor(address _attestorAddress)`: Grants the role of an Attestor to an address. Attestors verify contributions.
6.  `removeAttestor(address _attestorAddress)`: Revokes the Attestor role from an address.
7.  `setMinAttestorReputation(uint256 _minReputation)`: Sets the minimum overall reputation an address must have to act as an Attestor.
8.  `depositRewardTokens(uint256 _amount)`: Allows the network operator to deposit `CONTR` tokens into the contract for future rewards.
9.  `withdrawExcessFunds(address _tokenAddress, address _to, uint256 _amount)`: Allows the network operator to withdraw accidental token deposits.
10. `pause()`: Pauses core contract functionalities in case of emergency.
11. `unpause()`: Unpauses the contract.

**II. Contribution Submission & Attestation**
12. `submitContributionProof(bytes32 _categoryId, string memory _proofURI, uint256 _contributionValue)`: Allows users to submit evidence of their contribution to a specific skill category.
13. `attestContribution(uint256 _contributionId)`: Attestors verify a pending contribution, marking it as `Approved` and triggering reputation/reward distribution.
14. `rejectContribution(uint256 _contributionId, string memory _reason)`: Attestors reject a pending contribution, providing a reason.

**III. Reputation & Soulbound Profile (SBT) Management**
15. `mintSoulboundProfile()`: Mints a unique, non-transferable Soulbound Profile NFT for the caller. Callable only once per address.
16. `updateSoulboundProfileURI(uint256 _tokenId)`: Triggers an update to the metadata URI of a user's Soulbound Profile NFT, reflecting their latest reputation and skill levels.
17. `getReputationScore(address _user)`: Returns the total accumulated reputation score for a user.
18. `getSkillCategoryLevel(address _user, bytes32 _categoryId)`: Returns the reputation level of a user within a specific skill category.
19. `getSoulboundProfileURI(uint256 _tokenId)`: Returns the current metadata URI for a given Soulbound Profile NFT.

**IV. Dispute Resolution**
20. `challengeAttestation(uint256 _contributionId, string memory _reason)`: Allows any user to challenge an `Approved` or `Rejected` attestation, moving its status to `Disputed`.
21. `resolveDispute(uint256 _contributionId, bool _isValidAttestation)`: The Network Operator resolves a disputed attestation, either confirming the original attestation or overturning it. This can affect Attestor reputation.

**V. Gated Features & Rewards**
22. `claimContributionRewards()`: Allows users to claim their accrued `CONTR` token rewards from approved contributions.
23. `accessReputationGatedFeature(uint256 _minReputationRequired)`: An example function that requires a minimum overall reputation score to be called.
24. `accessSkillGatedFeature(bytes32 _categoryId, uint256 _minSkillLevelRequired)`: An example function that requires a minimum skill level in a specific category to be called.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential future off-chain signed proofs

/**
 * @title NexusForge: Decentralized Contribution & Reputation Network
 * @author YourName (or Anonymous)
 * @notice This contract facilitates verifiable contributions, manages dynamic Soulbound Tokens (SBTs) as
 *         reputation profiles, and implements a skill-tree based reputation system with gated access.
 *         It introduces a novel combination of concepts: community-driven attestation, dynamic NFTs
 *         based on on-chain activity, and dispute resolution for contributions.
 *
 * @dev This is a complex contract combining multiple advanced concepts. While detailed, a production
 *      system would require extensive auditing, gas optimization, and potentially layer-2 scaling
 *      solutions for high volume attestation. Metadata generation for SBTs is externalized (e.g., IPFS).
 */
contract NexusForge is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // --- State Variables & Data Structures ---

    IERC20 public immutable CONTR_TOKEN; // The utility token for rewards

    // Represents the status of a contribution
    enum ContributionStatus {
        Pending,   // Awaiting attestation
        Approved,  // Verified and approved
        Rejected,  // Rejected by an attestor
        Disputed   // Under dispute (after a challenge)
    }

    // Structure for a submitted contribution
    struct Contribution {
        address contributor;
        bytes32 categoryId;
        string proofURI;        // URI pointing to off-chain proof (e.g., IPFS hash of documentation)
        uint256 value;          // A quantitative measure of the contribution's impact/effort
        uint256 submittedAt;
        uint256 approvedAt;
        address attestor;       // Address of the attestor if approved/rejected
        string rejectionReason; // Reason for rejection
        ContributionStatus status;
        uint256 rewardAmount;   // Amount of CONTR tokens rewarded for this contribution
        uint256 reputationGain; // Reputation points awarded for this contribution
    }

    // Structure for a skill category
    struct SkillCategory {
        string name;
        uint256 baseRewardMultiplier; // Multiplier for rewards in this category (e.g., 1000 for 1x, 1500 for 1.5x)
        uint256 attestationFee;       // Optional fee for attestors to claim (future use, or for staking)
        bool exists;                  // To differentiate between unset and intentionally deleted
    }

    // --- Mappings ---

    uint256 public nextContributionId;
    mapping(uint256 => Contribution) public contributions;

    address public networkOperator; // A designated address (or multi-sig/DAO) for high-level operations & dispute resolution

    // Attestor management
    mapping(address => bool) public isAttestor;
    uint256 public minAttestorReputation = 0; // Minimum total reputation required to be an active attestor

    // Reputation and skill levels
    mapping(address => uint256) public totalReputation; // Overall reputation score for a user
    mapping(address => mapping(bytes32 => uint256)) public skillReputation; // Reputation per skill category for a user
    mapping(address => uint256) public pendingRewards; // CONTR tokens earned, awaiting claim

    // Soulbound Profile (SBT) management
    mapping(address => uint256) public sbtTokenId; // Maps user address to their SBT token ID
    mapping(uint256 => address) public sbtOwner; // Maps SBT token ID to owner address (redundant with ERC721, but explicit)
    uint256 public nextSbtId;

    // Skill Categories
    mapping(bytes32 => SkillCategory) public skillCategories; // Maps categoryId hash to SkillCategory struct

    // --- Events ---

    event NetworkOperatorSet(address indexed _oldOperator, address indexed _newOperator);
    event SkillCategoryAdded(bytes32 indexed _categoryId, string _name, uint256 _baseRewardMultiplier);
    event SkillCategoryUpdated(bytes32 indexed _categoryId, string _newName, uint256 _newBaseRewardMultiplier);
    event AttestorAdded(address indexed _attestor);
    event AttestorRemoved(address indexed _attestor);
    event MinAttestorReputationSet(uint256 _minReputation);
    event RewardTokensDeposited(address indexed _depositor, uint256 _amount);

    event ContributionSubmitted(uint256 indexed _id, address indexed _contributor, bytes32 indexed _categoryId, uint256 _value);
    event ContributionAttested(uint256 indexed _id, address indexed _attestor, uint256 _rewardAmount, uint256 _reputationGain);
    event ContributionRejected(uint256 indexed _id, address indexed _attestor, string _reason);
    event ContributionChallenged(uint256 indexed _id, address indexed _challenger, string _reason);
    event DisputeResolved(uint256 indexed _id, address indexed _resolver, bool _isValidAttestation);

    event SoulboundProfileMinted(address indexed _owner, uint256 indexed _tokenId);
    event SoulboundProfileURIUpdated(uint256 indexed _tokenId, string _newURI);
    event RewardsClaimed(address indexed _claimer, uint256 _amount);

    // --- Modifiers ---

    modifier onlyNetworkOperator() {
        require(msg.sender == networkOperator, "NexusForge: Caller is not the network operator");
        _;
    }

    modifier onlyAttestor() {
        require(isAttestor[msg.sender], "NexusForge: Caller is not an attestor");
        require(totalReputation[msg.sender] >= minAttestorReputation, "NexusForge: Attestor does not meet min reputation");
        _;
    }

    modifier reputationGated(uint256 _minReputationRequired) {
        require(totalReputation[msg.sender] >= _minReputationRequired, "NexusForge: Insufficient overall reputation");
        _;
    }

    modifier skillGated(bytes32 _categoryId, uint256 _minSkillLevelRequired) {
        require(skillReputation[msg.sender][_categoryId] >= _minSkillLevelRequired, "NexusForge: Insufficient skill level in category");
        _;
    }

    modifier onlySBTAtrributeOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(ERC721.ownerOf(_tokenId), _tokenId), "NexusForge: Caller is not owner of this SBT");
        _;
    }


    // --- Constructor ---

    constructor(address _contrTokenAddress)
        ERC721("NexusForge Soulbound Profile", "NFSP")
        Ownable(msg.sender) // Owner is the initial deployer
    {
        CONTR_TOKEN = IERC20(_contrTokenAddress);
        networkOperator = msg.sender; // Initial network operator is the deployer
        emit NetworkOperatorSet(address(0), msg.sender);
    }

    // --- I. Core Setup & Admin Functions ---

    /**
     * @dev Sets the address of the network operator. Only callable by the current owner.
     *      The network operator is responsible for resolving disputes and high-level management.
     * @param _newOperator The address to set as the new network operator.
     */
    function setNetworkOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "NexusForge: New operator cannot be zero address");
        address oldOperator = networkOperator;
        networkOperator = _newOperator;
        emit NetworkOperatorSet(oldOperator, _newOperator);
    }

    /**
     * @dev Adds a new skill category for contributions. Only callable by the network operator.
     * @param _categoryId A unique bytes32 identifier for the category (e.g., keccak256("DATA_COLLECTION")).
     * @param _name A human-readable name for the category.
     * @param _baseRewardMultiplier The base multiplier for rewards in this category (e.g., 1000 for 1x, 1500 for 1.5x).
     */
    function addSkillCategory(bytes32 _categoryId, string memory _name, uint256 _baseRewardMultiplier) external onlyNetworkOperator {
        require(!skillCategories[_categoryId].exists, "NexusForge: Skill category already exists");
        require(bytes(_name).length > 0, "NexusForge: Category name cannot be empty");
        require(_baseRewardMultiplier > 0, "NexusForge: Base reward multiplier must be positive");

        skillCategories[_categoryId] = SkillCategory({
            name: _name,
            baseRewardMultiplier: _baseRewardMultiplier,
            attestationFee: 0, // Default to 0, can be updated
            exists: true
        });
        emit SkillCategoryAdded(_categoryId, _name, _baseRewardMultiplier);
    }

    /**
     * @dev Updates an existing skill category. Only callable by the network operator.
     * @param _categoryId The bytes32 identifier of the category to update.
     * @param _newName The new human-readable name for the category (empty string to keep current).
     * @param _newBaseRewardMultiplier The new base multiplier for rewards (0 to keep current).
     */
    function updateSkillCategory(bytes32 _categoryId, string memory _newName, uint256 _newBaseRewardMultiplier) external onlyNetworkOperator {
        require(skillCategories[_categoryId].exists, "NexusForge: Skill category does not exist");

        SkillCategory storage category = skillCategories[_categoryId];
        if (bytes(_newName).length > 0) {
            category.name = _newName;
        }
        if (_newBaseRewardMultiplier > 0) {
            category.baseRewardMultiplier = _newBaseRewardMultiplier;
        }
        emit SkillCategoryUpdated(_categoryId, category.name, category.baseRewardMultiplier);
    }

    /**
     * @dev Grants the role of an Attestor to an address. Only callable by the network operator.
     *      Attestors verify contributions.
     * @param _attestorAddress The address to grant the Attestor role.
     */
    function addAttestor(address _attestorAddress) external onlyNetworkOperator {
        require(_attestorAddress != address(0), "NexusForge: Attestor address cannot be zero");
        require(!isAttestor[_attestorAddress], "NexusForge: Address is already an attestor");
        isAttestor[_attestorAddress] = true;
        emit AttestorAdded(_attestorAddress);
    }

    /**
     * @dev Revokes the Attestor role from an address. Only callable by the network operator.
     * @param _attestorAddress The address to remove from the Attestor role.
     */
    function removeAttestor(address _attestorAddress) external onlyNetworkOperator {
        require(_attestorAddress != address(0), "NexusForge: Attestor address cannot be zero");
        require(isAttestor[_attestorAddress], "NexusForge: Address is not an attestor");
        isAttestor[_attestorAddress] = false;
        emit AttestorRemoved(_attestorAddress);
    }

    /**
     * @dev Sets the minimum overall reputation an address must have to act as an Attestor.
     *      Only callable by the network operator.
     * @param _minReputation The minimum required reputation score.
     */
    function setMinAttestorReputation(uint256 _minReputation) external onlyNetworkOperator {
        minAttestorReputation = _minReputation;
        emit MinAttestorReputationSet(_minReputation);
    }

    /**
     * @dev Allows the network operator to deposit CONTR tokens into the contract for future rewards.
     * @param _amount The amount of CONTR tokens to deposit.
     */
    function depositRewardTokens(uint256 _amount) external onlyNetworkOperator {
        require(_amount > 0, "NexusForge: Deposit amount must be positive");
        CONTR_TOKEN.transferFrom(msg.sender, address(this), _amount);
        emit RewardTokensDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows the network operator to withdraw accidental token deposits (excluding CONTR_TOKEN balance).
     *      Ensures the contract can be recovered from incorrect token transfers.
     * @param _tokenAddress The address of the token to withdraw.
     * @param _to The recipient address.
     * @param _amount The amount to withdraw.
     */
    function withdrawExcessFunds(address _tokenAddress, address _to, uint256 _amount) external onlyNetworkOperator {
        require(_tokenAddress != address(CONTR_TOKEN), "NexusForge: Cannot withdraw CONTR_TOKEN directly, use specific functions");
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(_to, _amount), "NexusForge: Failed to withdraw excess funds");
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations. Only callable by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume. Only callable by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }


    // --- II. Contribution Submission & Attestation ---

    /**
     * @dev Allows users to submit evidence of their contribution to a specific skill category.
     *      Requires a minted Soulbound Profile.
     * @param _categoryId The bytes32 identifier of the skill category.
     * @param _proofURI A URI pointing to off-chain proof (e.g., IPFS hash of documentation, GitHub link).
     * @param _contributionValue A quantitative measure of the contribution's impact/effort (e.g., 1-100).
     */
    function submitContributionProof(
        bytes32 _categoryId,
        string memory _proofURI,
        uint256 _contributionValue
    ) external whenNotPaused nonReentrant {
        require(sbtTokenId[msg.sender] != 0, "NexusForge: User must have a Soulbound Profile");
        require(skillCategories[_categoryId].exists, "NexusForge: Skill category does not exist");
        require(bytes(_proofURI).length > 0, "NexusForge: Proof URI cannot be empty");
        require(_contributionValue > 0, "NexusForge: Contribution value must be positive");

        uint256 id = nextContributionId++;
        contributions[id] = Contribution({
            contributor: msg.sender,
            categoryId: _categoryId,
            proofURI: _proofURI,
            value: _contributionValue,
            submittedAt: block.timestamp,
            approvedAt: 0,
            attestor: address(0),
            rejectionReason: "",
            status: ContributionStatus.Pending,
            rewardAmount: 0,
            reputationGain: 0
        });

        emit ContributionSubmitted(id, msg.sender, _categoryId, _contributionValue);
    }

    /**
     * @dev Attestors verify a pending contribution. If approved, reputation and rewards are distributed.
     *      An attestor cannot attest their own contribution.
     * @param _contributionId The ID of the contribution to attest.
     */
    function attestContribution(uint256 _contributionId) external onlyAttestor whenNotPaused nonReentrant {
        Contribution storage c = contributions[_contributionId];
        require(c.status == ContributionStatus.Pending, "NexusForge: Contribution is not pending");
        require(c.contributor != msg.sender, "NexusForge: Cannot attest your own contribution");
        require(skillCategories[c.categoryId].exists, "NexusForge: Contribution category no longer exists");

        // Calculate reputation gain and reward
        uint256 baseReputationGain = c.value * 10; // Example: 10 reputation points per unit of value
        uint256 rewardAmount = (c.value * skillCategories[c.categoryId].baseRewardMultiplier) / 1000; // Value * multiplier

        totalReputation[c.contributor] += baseReputationGain;
        skillReputation[c.contributor][c.categoryId] += baseReputationGain;
        pendingRewards[c.contributor] += rewardAmount;

        c.status = ContributionStatus.Approved;
        c.attestor = msg.sender;
        c.approvedAt = block.timestamp;
        c.rewardAmount = rewardAmount;
        c.reputationGain = baseReputationGain;

        // Optionally, an attestor could gain minor reputation for valid attestations
        totalReputation[msg.sender] += (baseReputationGain / 10); // 10% of contributor's gain
        
        emit ContributionAttested(_contributionId, msg.sender, rewardAmount, baseReputationGain);
        
        // Trigger SBT URI update for the contributor
        if (sbtTokenId[c.contributor] != 0) {
            _updateSBTMetadata(sbtTokenId[c.contributor]);
        }
    }

    /**
     * @dev Attestors reject a pending contribution, providing a reason.
     *      An attestor cannot reject their own contribution.
     * @param _contributionId The ID of the contribution to reject.
     * @param _reason The reason for rejection.
     */
    function rejectContribution(uint256 _contributionId, string memory _reason) external onlyAttestor whenNotPaused {
        Contribution storage c = contributions[_contributionId];
        require(c.status == ContributionStatus.Pending, "NexusForge: Contribution is not pending");
        require(c.contributor != msg.sender, "NexusForge: Cannot reject your own contribution");
        require(bytes(_reason).length > 0, "NexusForge: Rejection reason cannot be empty");

        c.status = ContributionStatus.Rejected;
        c.attestor = msg.sender;
        c.rejectionReason = _reason;

        emit ContributionRejected(_contributionId, msg.sender, _reason);
    }

    // --- III. Reputation & Soulbound Profile (SBT) Management ---

    /**
     * @dev Mints a unique, non-transferable Soulbound Profile NFT for the caller.
     *      Callable only once per address. The token ID will be based on nextSbtId.
     *      The initial URI will be generated automatically.
     */
    function mintSoulboundProfile() external whenNotPaused {
        require(sbtTokenId[msg.sender] == 0, "NexusForge: User already has a Soulbound Profile");

        uint256 tokenId = nextSbtId++;
        _safeMint(msg.sender, tokenId);
        sbtTokenId[msg.sender] = tokenId;
        sbtOwner[tokenId] = msg.sender; // Store owner mapping explicitly for non-transferability checks

        _updateSBTMetadata(tokenId); // Set initial metadata

        emit SoulboundProfileMinted(msg.sender, tokenId);
    }

    /**
     * @dev Internal function to update the metadata URI of a user's Soulbound Profile NFT.
     *      This function is called automatically when reputation or skill levels change.
     *      It constructs a new metadata URI based on the user's current status.
     *      In a real application, this URI would point to dynamic JSON content on IPFS or a decentralized storage.
     * @param _tokenId The ID of the Soulbound Profile NFT to update.
     */
    function _updateSBTMetadata(uint256 _tokenId) internal {
        address owner = sbtOwner[_tokenId]; // Using internal mapping for consistency
        require(owner != address(0), "NexusForge: SBT not found for this token ID");

        // Example metadata generation - this would typically be more complex and externalized
        // For simplicity, we just generate a placeholder URI.
        // A real implementation would:
        // 1. Fetch current reputation and skill levels.
        // 2. Generate a JSON string representing the SBT's attributes (name, description, image, traits).
        //    e.g., { "name": "NexusForge Profile #" + _tokenId, "description": "Dynamic profile representing contributions.", "image": "ipfs://...", "attributes": [{"trait_type": "Total Reputation", "value": totalReputation[owner]}, {"trait_type": "Skill: Data Collection", "value": skillReputation[owner][keccak256(abi.encodePacked("DATA_COLLECTION"))]}] }
        // 3. Upload the JSON to IPFS and get the CID.
        // 4. Set the new URI using `_setTokenURI`.

        string memory baseURI = "ipfs://QmbT7z4mYk9xR5q6jF2bH8p7aG1cE0dF3xW2yV1u0sXp7/"; // Example IPFS base URI
        string memory newURI = string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        
        _setTokenURI(_tokenId, newURI);
        emit SoulboundProfileURIUpdated(_tokenId, newURI);
    }

    /**
     * @dev Allows an SBT owner to explicitly trigger an update of their SBT's metadata URI.
     *      This can be useful if off-chain metadata generation relies on polling or if visual changes need to be reflected immediately.
     * @param _tokenId The ID of the Soulbound Profile NFT to update.
     */
    function updateSoulboundProfileURI(uint256 _tokenId) external onlySBTAtrributeOwner(_tokenId) {
        require(sbtOwner[_tokenId] == msg.sender, "NexusForge: You can only update your own SBT");
        _updateSBTMetadata(_tokenId);
    }

    /**
     * @dev Returns the total accumulated reputation score for a user.
     * @param _user The address of the user.
     * @return The total reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return totalReputation[_user];
    }

    /**
     * @dev Returns the reputation level of a user within a specific skill category.
     * @param _user The address of the user.
     * @param _categoryId The bytes32 identifier of the skill category.
     * @return The skill category reputation level.
     */
    function getSkillCategoryLevel(address _user, bytes32 _categoryId) external view returns (uint256) {
        return skillReputation[_user][_categoryId];
    }

    /**
     * @dev Returns the current metadata URI for a given Soulbound Profile NFT.
     * @param _tokenId The ID of the Soulbound Profile NFT.
     * @return The metadata URI.
     */
    function getSoulboundProfileURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURI(_tokenId);
    }


    // --- IV. Dispute Resolution ---

    /**
     * @dev Allows any user to challenge an `Approved` or `Rejected` attestation.
     *      Moves the contribution status to `Disputed`, awaiting resolution by the Network Operator.
     * @param _contributionId The ID of the contribution to challenge.
     * @param _reason The reason for challenging the attestation.
     */
    function challengeAttestation(uint256 _contributionId, string memory _reason) external whenNotPaused {
        Contribution storage c = contributions[_contributionId];
        require(c.status == ContributionStatus.Approved || c.status == ContributionStatus.Rejected, "NexusForge: Contribution not in approved or rejected status");
        require(c.status != ContributionStatus.Disputed, "NexusForge: Contribution is already under dispute");
        require(bytes(_reason).length > 0, "NexusForge: Challenge reason cannot be empty");

        c.status = ContributionStatus.Disputed;
        // Store challenger and reason internally if needed for resolution logic
        // For simplicity in this example, only the event logs are used to record challenger and reason.

        emit ContributionChallenged(_contributionId, msg.sender, _reason);
    }

    /**
     * @dev The Network Operator resolves a disputed attestation.
     *      If `_isValidAttestation` is true, the original attestation (approved/rejected) stands.
     *      If false, the original attestation is overturned. This can lead to reputation penalties for the original attestor.
     * @param _contributionId The ID of the disputed contribution.
     * @param _isValidAttestation True if the original attestation was correct, false if it was incorrect.
     */
    function resolveDispute(uint256 _contributionId, bool _isValidAttestation) external onlyNetworkOperator whenNotPaused nonReentrant {
        Contribution storage c = contributions[_contributionId];
        require(c.status == ContributionStatus.Disputed, "NexusForge: Contribution is not under dispute");

        if (_isValidAttestation) {
            // Original attestation stands. Revert to Approved/Rejected status based on original.
            if (c.attestor != address(0)) { // Ensure there was an attestor
                // If it was rejected, and dispute says rejection was valid, no change
                // If it was approved, and dispute says approval was valid, no change
                // No reputation change for attestor if their original decision was upheld
            }
            // Restore status based on what it was before dispute (Approved or Rejected)
            c.status = (c.rewardAmount > 0 || c.reputationGain > 0) ? ContributionStatus.Approved : ContributionStatus.Rejected;
        } else {
            // Original attestation was incorrect, overturn it.
            if (c.attestor != address(0)) { // Ensure there was an attestor
                // Attestor loses reputation for an incorrect attestation
                uint256 penalty = c.reputationGain > 0 ? c.reputationGain : c.value * 5; // Example penalty
                if (totalReputation[c.attestor] > penalty) {
                    totalReputation[c.attestor] -= penalty;
                } else {
                    totalReputation[c.attestor] = 0;
                }
                 // Trigger SBT URI update for the attestor if their reputation changed
                if (sbtTokenId[c.attestor] != 0) {
                    _updateSBTMetadata(sbtTokenId[c.attestor]);
                }
            }

            if (c.rewardAmount > 0 || c.reputationGain > 0) {
                // If it was previously approved but now overturned:
                // Deduct reputation and rewards from contributor, set to Rejected.
                totalReputation[c.contributor] -= c.reputationGain;
                skillReputation[c.contributor][c.categoryId] -= c.reputationGain;
                if (pendingRewards[c.contributor] >= c.rewardAmount) {
                    pendingRewards[c.contributor] -= c.rewardAmount;
                } else {
                    pendingRewards[c.contributor] = 0;
                }
                c.status = ContributionStatus.Rejected;
                c.rejectionReason = "Overturned by network operator after dispute";
            } else {
                // If it was previously rejected but now overturned:
                // Mark as Pending (or directly as Approved if operator wants to approve it fully).
                // For simplicity, let's mark it as Pending for re-attestation or direct approval.
                c.status = ContributionStatus.Pending; // Requires re-attestation
                c.rejectionReason = "";
                c.attestor = address(0); // Clear original attestor
            }
            // Trigger SBT URI update for the contributor if their reputation changed
            if (sbtTokenId[c.contributor] != 0) {
                _updateSBTMetadata(sbtTokenId[c.contributor]);
            }
        }

        emit DisputeResolved(_contributionId, msg.sender, _isValidAttestation);
    }

    // --- V. Gated Features & Rewards ---

    /**
     * @dev Allows users to claim their accrued CONTR token rewards from approved contributions.
     *      Requires the `CONTR_TOKEN` contract to have sufficient balance.
     */
    function claimContributionRewards() external nonReentrant whenNotPaused {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "NexusForge: No rewards to claim");
        pendingRewards[msg.sender] = 0; // Clear pending rewards BEFORE transfer

        require(CONTR_TOKEN.transfer(msg.sender, amount), "NexusForge: Failed to transfer rewards");
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev An example function that requires a minimum overall reputation score to be called.
     *      This demonstrates how reputation can gate access to certain network features or benefits.
     * @param _minReputationRequired The minimum total reputation score required.
     */
    function accessReputationGatedFeature(uint256 _minReputationRequired)
        external
        view
        reputationGated(_minReputationRequired)
    {
        // This function represents some protected logic or data access
        // For example, accessing premium data feeds, higher-tier voting rights, etc.
        // It does nothing in this example but demonstrates the modifier's use.
        // solhint-disable-next-line no-empty-blocks
    }

    /**
     * @dev An example function that requires a minimum skill level in a specific category to be called.
     *      This demonstrates how specialized skill reputation can gate access.
     * @param _categoryId The bytes32 identifier of the required skill category.
     * @param _minSkillLevelRequired The minimum skill level required in that category.
     */
    function accessSkillGatedFeature(bytes32 _categoryId, uint256 _minSkillLevelRequired)
        external
        view
        skillGated(_categoryId, _minSkillLevelRequired)
    {
        // This function represents some specialized logic or data access requiring specific expertise.
        // For example, moderating content in that category, specialized development tasks, etc.
        // It does nothing in this example but demonstrates the modifier's use.
        // solhint-disable-next-line no-empty-blocks
    }

    // --- ERC721 Overrides for Soulbound (Non-Transferable) ---

    /**
     * @dev Overrides `_beforeTokenTransfer` to prevent any transfers of SBTs.
     *      Soulbound Tokens are non-transferable.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && to != address(0)) {
            revert("NexusForge: Soulbound Tokens are non-transferable.");
        }
    }

    /**
     * @dev Overrides `_approve` to prevent setting approvals for SBTs.
     */
    function approve(address to, uint256 tokenId) public pure override {
        revert("NexusForge: Soulbound Tokens cannot be approved for transfer.");
    }

    /**
     * @dev Overrides `setApprovalForAll` to prevent setting approvals for all SBTs.
     */
    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("NexusForge: Soulbound Tokens cannot be approved for all.");
    }

    /**
     * @dev Overrides `transferFrom` to prevent direct transfers of SBTs.
     */
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("NexusForge: Soulbound Tokens are non-transferable.");
    }

    /**
     * @dev Overrides `safeTransferFrom` to prevent direct safe transfers of SBTs.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("NexusForge: Soulbound Tokens are non-transferable.");
    }

    /**
     * @dev Overrides `safeTransferFrom` to prevent direct safe transfers of SBTs.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public pure override {
        revert("NexusForge: Soulbound Tokens are non-transferable.");
    }

    // --- Helper View Functions (Public Getters) ---

    /**
     * @dev Returns the status of a specific contribution.
     * @param _contributionId The ID of the contribution.
     * @return The status enum value.
     */
    function getContributionStatus(uint256 _contributionId) external view returns (ContributionStatus) {
        return contributions[_contributionId].status;
    }

    /**
     * @dev Checks if an address is currently an attestor and meets the minimum reputation.
     * @param _addr The address to check.
     * @return True if the address is an active attestor, false otherwise.
     */
    function isActiveAttestor(address _addr) external view returns (bool) {
        return isAttestor[_addr] && totalReputation[_addr] >= minAttestorReputation;
    }

    /**
     * @dev Returns the total number of contributions submitted so far.
     * @return The total number of contributions.
     */
    function getTotalContributions() external view returns (uint256) {
        return nextContributionId;
    }

    /**
     * @dev Returns the total CONTR token rewards pending for a user.
     * @param _user The address of the user.
     * @return The amount of pending CONTR tokens.
     */
    function getPendingRewards(address _user) external view returns (uint256) {
        return pendingRewards[_user];
    }
}
```