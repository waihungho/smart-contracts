This smart contract, "ChronicleForge," introduces an advanced concept centered around **Adaptive Soulbound NFTs (ASBNs)** that serve as dynamic, verifiable on-chain identities. These ASBNs evolve visually and functionally based on a user's accumulated **"Impact Score"** (contributions to verifiable public good initiatives) and **"Reputation Score"** (attestations, staking, and participation).

The contract integrates elements of:
1.  **Soulbound Tokens (SBTs):** Non-transferable NFTs tied to a user's address.
2.  **Dynamic NFTs:** Metadata and visual traits evolve based on on-chain state.
3.  **Decentralized Identity/Reputation:** Building a public, verifiable profile.
4.  **Verifiable Impact Finance (ReFi-inspired):** Tracking contributions to designated initiatives.
5.  **On-chain Trait Generation:** A deterministic algorithm within the contract dictates ASBN evolution.
6.  **Delegated Attestations:** Users can vouch for others, influencing reputation.
7.  **Moderated Dispute System:** For handling malicious attestations or reports.

---

## ChronicleForge Smart Contract

### Outline:

*   **`ChronicleForge` Contract:** The main contract inheriting ERC721, Ownable, and Pausable.
*   **Custom Errors:** For clearer error handling.
*   **Events:** For tracking significant state changes.
*   **Enums:** For initiative statuses.
*   **Structs:**
    *   `UserForgeProfile`: Stores user-specific data like scores, ASBN ID, and attestation data.
    *   `ImpactInitiative`: Details about public good initiatives.
    *   `UserAttestation`: Details of an attestation made by one user about another.
    *   `TraitSpec`: Represents the dynamic visual/functional traits of an ASBN.
    *   `ReportEntry`: For dispute resolution.
*   **State Variables:** Mappings to store profiles, initiatives, attestations, ASBN properties, and system configurations.
*   **Access Control:** `Ownable` and `Pausable` modifiers, plus custom `onlyModerator`.
*   **Core ASBN (Soulbound ERC721) Functions:** Minting, metadata, and transfer restrictions.
*   **Impact Initiative Functions:** Creation, contribution, and management of initiatives.
*   **Reputation & Attestation Functions:** Attesting to users, revoking attestations, and score calculation.
*   **Dynamic Trait Generation Functions:** Deterministic logic for ASBN evolution based on scores.
*   **Staking Functions:** Staking native tokens for temporary reputation boosts.
*   **Moderation & Dispute Resolution Functions:** Reporting malicious activities and resolution by moderators.
*   **Configuration & Utility Functions:** Setting URIs, pausing, and moderator management.

### Function Summary:

1.  **`constructor(string memory baseURI_, string memory name_, string memory symbol_)`**: Initializes the contract with base URI, ERC721 name, and symbol.
2.  **`setBaseURI(string memory newBaseURI_)`**: (Admin) Sets the base URI for ASBN metadata.
3.  **`pauseContract()`**: (Admin) Pauses certain contract functionalities.
4.  **`unpauseContract()`**: (Admin) Unpauses contract functionalities.
5.  **`setModerator(address _moderator, bool _isModerator)`**: (Admin) Grants or revokes moderator status.
6.  **`mintAdaptiveSoulboundNFT(address _owner)`**: Mints a new Adaptive Soulbound NFT for the specified owner. An address can only have one.
7.  **`getTokenURI(uint256 tokenId)`**: Returns the dynamic metadata URI for a given ASBN.
8.  **`getASBNOwner(uint256 tokenId)`**: Returns the owner of a given ASBN.
9.  **`hasASBN(address _user)`**: Checks if an address possesses an ASBN.
10. **`createImpactInitiative(string memory _name, string memory _description, address _beneficiary, uint256 _targetAmount)`**: (Admin/Moderator) Creates a new public good initiative.
11. **`recordImpactContribution(uint256 _initiativeId, uint256 _amount, bytes32 _proofHash)`**: Records a contribution by the caller to an impact initiative, boosting their Impact Score.
12. **`updateInitiativeStatus(uint256 _initiativeId, InitiativeStatus _newStatus)`**: (Admin/Moderator) Changes the status of an initiative.
13. **`getImpactInitiative(uint256 _initiativeId)`**: Returns details of an impact initiative.
14. **`attestToUser(address _attestedUser, uint256 _reputationBoost, string memory _attestationContext)`**: Allows a user to attest to another user's positive contribution/reputation, boosting their Reputation Score.
15. **`revokeAttestation(bytes32 _attestationId)`**: Allows an attester to revoke their previously made attestation.
16. **`getReputationScore(address _user)`**: Returns the current Reputation Score of a user.
17. **`getImpactScore(address _user)`**: Returns the current Impact Score of a user.
18. **`stakeForReputationBoost(uint256 _amount)`**: Allows a user to stake native tokens to temporarily boost their Reputation Score.
19. **`unstakeReputationBoost()`**: Allows a user to unstake their native tokens, removing the temporary reputation boost.
20. **`getASBNSpec(address _user)`**: Returns the current dynamically generated trait specifications for a user's ASBN.
21. **`reportMaliciousAttestation(bytes32 _attestationId, string memory _reason)`**: Allows any user to report a potentially false or malicious attestation.
22. **`resolveReport(bytes32 _reportId, bool _isMalicious, uint256 _penaltyAmount)`**: (Admin/Moderator) Resolves a reported malicious attestation, applying penalties if necessary.
23. **`setTraitWeight(string memory _traitName, uint256 _weight)`**: (Admin) Adjusts the weight/influence of various scores on specific ASBN traits (e.g., how much impact score influences "aura color").
24. **`withdrawInitiativeFunds(uint256 _initiativeId)`**: (Admin/Moderator) Allows the beneficiary to withdraw collected funds for a completed or approved initiative.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ChronicleForge
 * @dev An advanced smart contract for Adaptive Soulbound NFTs (ASBNs) that serve as dynamic,
 *      verifiable on-chain identities. These ASBNs evolve visually and functionally
 *      based on a user's accumulated "Impact Score" (contributions to verifiable public good initiatives)
 *      and "Reputation Score" (attestations, staking, and participation).
 *
 *      The contract integrates:
 *      - Soulbound Tokens (SBTs): Non-transferable NFTs tied to a user's address.
 *      - Dynamic NFTs: Metadata and visual traits evolve based on on-chain state.
 *      - Decentralized Identity/Reputation: Building a public, verifiable profile.
 *      - Verifiable Impact Finance (ReFi-inspired): Tracking contributions to designated initiatives.
 *      - On-chain Trait Generation: A deterministic algorithm within the contract dictates ASBN evolution.
 *      - Delegated Attestations: Users can vouch for others, influencing reputation.
 *      - Moderated Dispute System: For handling malicious attestations or reports.
 */
contract ChronicleForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Custom Errors ---
    error AlreadyHasASBN();
    error NoASBNFound();
    error UnauthorizedAction();
    error InitiativeNotFound();
    error InvalidInitiativeStatus();
    error InsufficientContribution();
    error AttestationNotFound();
    error CannotAttestToSelf();
    error AttestationAlreadyRevoked();
    error AlreadyStaked();
    error NoStakeFound();
    error NoFundsToWithdraw();
    error ReportNotFound();
    error AttestationIsSelfReported();
    error InitiativeTargetNotMetOrOngoing();
    error AlreadyMinted();
    error CannotModifyActiveTraitWeight();

    // --- Events ---
    event ASBNMinted(address indexed owner, uint256 tokenId);
    event ImpactContributionRecorded(address indexed contributor, uint256 indexed initiativeId, uint256 amount, bytes32 proofHash);
    event ImpactInitiativeCreated(uint256 indexed initiativeId, string name, address beneficiary, uint256 targetAmount);
    event InitiativeStatusUpdated(uint256 indexed initiativeId, InitiativeStatus newStatus);
    event UserAttested(address indexed attester, address indexed attestedUser, bytes32 attestationId, uint256 reputationBoost);
    event AttestationRevoked(bytes32 indexed attestationId);
    event ReputationBoostStaked(address indexed user, uint256 amount);
    event ReputationBoostUnstaked(address indexed user, uint256 amount);
    event ASBNSpecUpdated(uint256 indexed tokenId, bytes32 newSpecHash);
    event ReportFiled(bytes32 indexed reportId, bytes32 indexed attestationId, address indexed reporter, string reason);
    event ReportResolved(bytes32 indexed reportId, bool isMalicious, uint256 penaltyAmount);
    event ModeratorStatusUpdated(address indexed moderator, bool isModerator);
    event InitiativeFundsWithdrawn(uint256 indexed initiativeId, address indexed beneficiary, uint256 amount);
    event TraitWeightUpdated(string traitName, uint256 newWeight);

    // --- Enums ---
    enum InitiativeStatus { Active, Completed, Cancelled, Paused }

    // --- Structs ---
    struct UserForgeProfile {
        uint256 asbnTokenId;      // ID of the user's Soulbound NFT
        uint256 reputationScore;  // Aggregated reputation score
        uint256 impactScore;      // Aggregated impact score from contributions
        uint256 stakedAmount;     // Amount of native token staked for reputation boost
        uint256 stakeTimestamp;   // Timestamp when stake was made
        mapping(bytes32 => UserAttestation) attestationsGiven; // Attestations given by this user
        bytes32[] attestationsGivenIds; // IDs of attestations given
    }

    struct ImpactInitiative {
        string name;
        string description;
        address beneficiary;
        uint256 targetAmount;      // Target funding or contribution amount
        uint256 currentAmount;     // Current collected amount or contribution units
        InitiativeStatus status;
        address creator;
        uint256 createdAt;
    }

    struct UserAttestation {
        address attester;
        address attestedUser;
        uint256 reputationBoost;
        string context;           // Context/reason for attestation
        uint256 timestamp;
        bool revoked;
    }

    // TraitSpec is not stored directly on-chain for each ASBN, but calculated dynamically.
    // This struct defines the output of the _calculateASBNSpec function.
    struct TraitSpec {
        string baseShape;
        string auraColor;
        string coreMaterial;
        string embellishment;
        string glyphPattern;
        string tier; // e.g., "Bronze", "Silver", "Gold" based on combined scores
    }

    struct ReportEntry {
        bytes32 attestationId;
        address reporter;
        string reason;
        bool resolved;
        bool isMalicious; // Outcome of the report
        uint256 createdAt;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _initiativeIdCounter;
    Counters.Counter private _reportIdCounter;

    mapping(address => UserForgeProfile) public userProfiles;
    mapping(uint256 => address) public asbnToOwner; // tokenId -> owner (for ERC721 compatibility)
    mapping(address => uint256) public ownerToAsbn; // owner -> tokenId (for quick lookup)

    mapping(uint256 => ImpactInitiative) public impactInitiatives;
    mapping(bytes32 => UserAttestation) public allAttestations; // Global mapping for all attestations
    mapping(address => bytes32[]) public attestationsReceived; // User -> list of attestation IDs received

    string private _baseTokenURI; // Base URI for metadata server
    mapping(address => bool) public moderators; // Address -> isModerator

    // Weights for how reputation/impact scores influence specific traits (Admin configurable)
    mapping(string => uint256) public traitWeights;

    mapping(bytes32 => ReportEntry) public reports; // reportId -> ReportEntry

    // --- Constructor ---
    constructor(string memory baseURI_, string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI_;

        // Initialize default trait weights (can be adjusted by owner)
        traitWeights["baseShape"] = 100; // General profile progress
        traitWeights["auraColor"] = 50;  // Impact Score influence
        traitWeights["coreMaterial"] = 75; // Reputation Score influence
        traitWeights["embellishment"] = 30; // Number of attestations received
        traitWeights["glyphPattern"] = 20; // Staked amount
        traitWeights["tier"] = 200; // Overall score
    }

    // --- Modifiers ---
    modifier onlyModerator() {
        if (!moderators[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedAction();
        }
        _;
    }

    // --- Configuration & Utility Functions ---

    /**
     * @dev Sets the base URI for ASBN metadata. This URI will be prefixed to token IDs
     *      to form the full metadata URL (e.g., https://api.chronicleforge.com/asbn/{tokenId}).
     *      The off-chain server will then query the contract to dynamically generate the JSON.
     * @param newBaseURI_ The new base URI.
     */
    function setBaseURI(string memory newBaseURI_) public onlyOwner {
        _baseTokenURI = newBaseURI_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      This function constructs a dynamic URI by appending the tokenId to the base URI.
     *      An off-chain service is expected to resolve this URI and generate the JSON metadata
     *      by querying the contract's state (e.g., getASBNSpec) for the given tokenId's owner.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return string.concat(_baseTokenURI, tokenId.toString());
    }

    /**
     * @dev Pauses certain contract functionalities. Only callable by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract functionalities. Only callable by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Grants or revokes moderator status for an address.
     *      Moderators can perform actions like updating initiative statuses or resolving reports.
     * @param _moderator The address to set as moderator.
     * @param _isModerator True to grant, false to revoke.
     */
    function setModerator(address _moderator, bool _isModerator) public onlyOwner {
        moderators[_moderator] = _isModerator;
        emit ModeratorStatusUpdated(_moderator, _isModerator);
    }

    /**
     * @dev Adjusts the weight/influence of various scores on specific ASBN traits.
     *      This allows the owner to fine-tune how reputation and impact scores translate
     *      into the dynamic visual representation of the ASBN.
     * @param _traitName The name of the trait (e.g., "auraColor", "tier").
     * @param _weight The new weight (e.g., 1 to 100, where 100 is high influence).
     */
    function setTraitWeight(string memory _traitName, uint256 _weight) public onlyOwner {
        // Prevent setting weight to 0 if it's an active trait, unless it's a specific use case
        // For simplicity, we allow setting any weight >= 0.
        // A more complex system might have a minimum weight or specific ranges.
        traitWeights[_traitName] = _weight;
        emit TraitWeightUpdated(_traitName, _weight);
    }

    // --- Core ASBN (Soulbound ERC721) Functions ---

    /**
     * @dev Mints a new Adaptive Soulbound NFT for the specified owner.
     *      Each address can only possess one ASBN. This ASBN is non-transferable.
     * @param _owner The address to mint the ASBN for.
     */
    function mintAdaptiveSoulboundNFT(address _owner) public whenNotPaused {
        if (userProfiles[_owner].asbnTokenId != 0) {
            revert AlreadyHasASBN();
        }

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _mint(_owner, newItemId);

        userProfiles[_owner].asbnTokenId = newItemId;
        asbnToOwner[newItemId] = _owner;
        ownerToAsbn[_owner] = newItemId;

        emit ASBNMinted(_owner, newItemId);
        emit ASBNSpecUpdated(newItemId, keccak256(abi.encode(_calculateASBNSpec(_owner)))); // Initial spec update
    }

    /**
     * @dev Returns the owner of the specified ASBN.
     * @param tokenId The ID of the ASBN.
     * @return The address of the ASBN owner.
     */
    function getASBNOwner(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return asbnToOwner[tokenId];
    }

    /**
     * @dev Checks if an address possesses an ASBN.
     * @param _user The address to check.
     * @return True if the user has an ASBN, false otherwise.
     */
    function hasASBN(address _user) public view returns (bool) {
        return userProfiles[_user].asbnTokenId != 0;
    }

    // --- ERC721 Overrides for Soulbound functionality ---
    // These functions ensure the ASBNs are non-transferable.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Prevent any transfers other than minting (from address(0)) or burning (to address(0))
        if (from != address(0) && to != address(0)) {
            revert ERC721InvalidSender(from); // Or a custom more specific error for soulbound
        }
    }

    // Explicitly override these to prevent any transfer-like operations
    function approve(address to, uint256 tokenId) public pure override {
        revert ERC721InvalidApprover(to); // Soulbound: no approvals allowed
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert ERC771InvalidOperator(operator); // Soulbound: no approvals allowed
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert ERC721InvalidSender(from); // Soulbound: no transfers allowed
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert ERC721InvalidSender(from); // Soulbound: no transfers allowed
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert ERC721InvalidSender(from); // Soulbound: no transfers allowed
    }

    // --- Impact Initiative Functions ---

    /**
     * @dev Creates a new public good initiative that users can contribute to.
     *      Only callable by the contract owner or a moderator.
     * @param _name The name of the initiative.
     * @param _description A description of the initiative.
     * @param _beneficiary The address that will receive collected funds/contributions.
     * @param _targetAmount The target amount of contributions (can be in native token or units).
     */
    function createImpactInitiative(string memory _name, string memory _description, address _beneficiary, uint256 _targetAmount) public onlyModerator whenNotPaused {
        _initiativeIdCounter.increment();
        uint256 newInitiativeId = _initiativeIdCounter.current();

        impactInitiatives[newInitiativeId] = ImpactInitiative({
            name: _name,
            description: _description,
            beneficiary: _beneficiary,
            targetAmount: _targetAmount,
            currentAmount: 0,
            status: InitiativeStatus.Active,
            creator: msg.sender,
            createdAt: block.timestamp
        });

        emit ImpactInitiativeCreated(newInitiativeId, _name, _beneficiary, _targetAmount);
    }

    /**
     * @dev Records a contribution by the caller to an impact initiative.
     *      The amount sent with the transaction contributes to the initiative's currentAmount
     *      and boosts the sender's Impact Score.
     *      A `_proofHash` is included, representing an off-chain verifiable proof of impact.
     * @param _initiativeId The ID of the initiative.
     * @param _amount The amount of native token being contributed.
     * @param _proofHash A hash representing off-chain proof of contribution/impact.
     */
    function recordImpactContribution(uint256 _initiativeId, uint256 _amount, bytes32 _proofHash) public payable whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        if (initiative.beneficiary == address(0)) { // Check if initiative exists
            revert InitiativeNotFound();
        }
        if (initiative.status != InitiativeStatus.Active) {
            revert InvalidInitiativeStatus();
        }
        if (msg.value < _amount) {
            revert InsufficientContribution();
        }

        initiative.currentAmount = initiative.currentAmount.add(_amount);
        userProfiles[msg.sender].impactScore = userProfiles[msg.sender].impactScore.add(_amount);

        // Ensure user has an ASBN to update its dynamic traits
        if (userProfiles[msg.sender].asbnTokenId != 0) {
            emit ASBNSpecUpdated(userProfiles[msg.sender].asbnTokenId, keccak256(abi.encode(_calculateASBNSpec(msg.sender))));
        }

        emit ImpactContributionRecorded(msg.sender, _initiativeId, _amount, _proofHash);
    }

    /**
     * @dev Changes the status of an existing initiative.
     *      Only callable by the contract owner or a moderator.
     * @param _initiativeId The ID of the initiative.
     * @param _newStatus The new status (Active, Completed, Cancelled, Paused).
     */
    function updateInitiativeStatus(uint256 _initiativeId, InitiativeStatus _newStatus) public onlyModerator {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        if (initiative.beneficiary == address(0)) {
            revert InitiativeNotFound();
        }
        initiative.status = _newStatus;
        emit InitiativeStatusUpdated(_initiativeId, _newStatus);
    }

    /**
     * @dev Returns details of an impact initiative.
     * @param _initiativeId The ID of the initiative.
     * @return A struct containing all details of the initiative.
     */
    function getImpactInitiative(uint256 _initiativeId) public view returns (ImpactInitiative memory) {
        if (impactInitiatives[_initiativeId].beneficiary == address(0)) {
            revert InitiativeNotFound();
        }
        return impactInitiatives[_initiativeId];
    }

    /**
     * @dev Allows the beneficiary to withdraw collected funds for a completed or approved initiative.
     *      Can only be called by the beneficiary, and only if the initiative is Completed.
     * @param _initiativeId The ID of the initiative.
     */
    function withdrawInitiativeFunds(uint256 _initiativeId) public whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        if (initiative.beneficiary == address(0)) {
            revert InitiativeNotFound();
        }
        if (initiative.status != InitiativeStatus.Completed) {
            revert InitiativeTargetNotMetOrOngoing(); // Or a more specific error for non-completed
        }
        if (initiative.beneficiary != msg.sender) {
            revert UnauthorizedAction();
        }
        if (initiative.currentAmount == 0) {
            revert NoFundsToWithdraw();
        }

        uint256 amountToWithdraw = initiative.currentAmount;
        initiative.currentAmount = 0; // Reset after withdrawal

        // Transfer funds
        (bool success, ) = payable(initiative.beneficiary).call{value: amountToWithdraw}("");
        require(success, "Failed to withdraw funds");

        emit InitiativeFundsWithdrawn(_initiativeId, initiative.beneficiary, amountToWithdraw);
    }

    // --- Reputation & Attestation Functions ---

    /**
     * @dev Allows a user to attest to another user's positive contribution/reputation.
     *      This boosts the attested user's Reputation Score and is recorded on-chain.
     * @param _attestedUser The address of the user being attested to.
     * @param _reputationBoost The amount of reputation to add (e.g., 10 for minor, 100 for significant).
     * @param _attestationContext A brief context/reason for the attestation.
     * @return The ID of the new attestation.
     */
    function attestToUser(address _attestedUser, uint256 _reputationBoost, string memory _attestationContext) public whenNotPaused returns (bytes32) {
        if (!hasASBN(msg.sender)) {
            revert NoASBNFound(); // Only ASBN holders can attest
        }
        if (!hasASBN(_attestedUser)) {
            revert NoASBNFound(); // Can only attest to other ASBN holders
        }
        if (msg.sender == _attestedUser) {
            revert CannotAttestToSelf();
        }

        bytes32 attestationId = keccak256(abi.encodePacked(msg.sender, _attestedUser, _attestationContext, block.timestamp));

        allAttestations[attestationId] = UserAttestation({
            attester: msg.sender,
            attestedUser: _attestedUser,
            reputationBoost: _reputationBoost,
            context: _attestationContext,
            timestamp: block.timestamp,
            revoked: false
        });

        userProfiles[_attestedUser].reputationScore = userProfiles[_attestedUser].reputationScore.add(_reputationBoost);
        attestationsReceived[_attestedUser].push(attestationId);
        userProfiles[msg.sender].attestationsGiven[attestationId] = allAttestations[attestationId]; // Copy to attester's given map
        userProfiles[msg.sender].attestationsGivenIds.push(attestationId);


        if (userProfiles[_attestedUser].asbnTokenId != 0) {
            emit ASBNSpecUpdated(userProfiles[_attestedUser].asbnTokenId, keccak256(abi.encode(_calculateASBNSpec(_attestedUser))));
        }

        emit UserAttested(msg.sender, _attestedUser, attestationId, _reputationBoost);
        return attestationId;
    }

    /**
     * @dev Allows an attester to revoke their previously made attestation.
     *      This reduces the attested user's Reputation Score.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(bytes32 _attestationId) public whenNotPaused {
        UserAttestation storage attestation = allAttestations[_attestationId];
        if (attestation.attester == address(0) || attestation.revoked) {
            revert AttestationNotFound();
        }
        if (attestation.attester != msg.sender) {
            revert UnauthorizedAction();
        }

        attestation.revoked = true;
        userProfiles[attestation.attestedUser].reputationScore = userProfiles[attestation.attestedUser].reputationScore.sub(attestation.reputationBoost);

        if (userProfiles[attestation.attestedUser].asbnTokenId != 0) {
            emit ASBNSpecUpdated(userProfiles[attestation.attestedUser].asbnTokenId, keccak256(abi.encode(_calculateASBNSpec(attestation.attestedUser))));
        }

        emit AttestationRevoked(_attestationId);
    }

    /**
     * @dev Returns the current Reputation Score of a user.
     * @param _user The address of the user.
     * @return The user's current Reputation Score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        uint256 baseRep = userProfiles[_user].reputationScore;
        uint256 stakedRepBoost = (block.timestamp.sub(userProfiles[_user].stakeTimestamp) > 0) ? userProfiles[_user].stakedAmount.div(100) : 0; // Example boost logic
        return baseRep.add(stakedRepBoost);
    }

    /**
     * @dev Returns the current Impact Score of a user.
     * @param _user The address of the user.
     * @return The user's current Impact Score.
     */
    function getImpactScore(address _user) public view returns (uint256) {
        return userProfiles[_user].impactScore;
    }

    // --- Staking Functions for Reputation Boost ---

    /**
     * @dev Allows a user to stake native tokens to temporarily boost their Reputation Score.
     *      The boost amount is proportional to the staked amount and duration.
     * @param _amount The amount of native tokens to stake.
     */
    function stakeForReputationBoost(uint256 _amount) public payable whenNotPaused {
        if (!hasASBN(msg.sender)) {
            revert NoASBNFound();
        }
        if (userProfiles[msg.sender].stakedAmount > 0) {
            revert AlreadyStaked();
        }
        if (msg.value < _amount) {
            revert InsufficientContribution(); // Reusing error, but implies not enough ETH sent
        }

        userProfiles[msg.sender].stakedAmount = _amount;
        userProfiles[msg.sender].stakeTimestamp = block.timestamp;

        // Trigger ASBN spec update
        emit ASBNSpecUpdated(userProfiles[msg.sender].asbnTokenId, keccak256(abi.encode(_calculateASBNSpec(msg.sender))));
        emit ReputationBoostStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to unstake their native tokens, removing the temporary reputation boost.
     */
    function unstakeReputationBoost() public whenNotPaused {
        if (userProfiles[msg.sender].stakedAmount == 0) {
            revert NoStakeFound();
        }

        uint256 amountToUnstake = userProfiles[msg.sender].stakedAmount;
        userProfiles[msg.sender].stakedAmount = 0;
        userProfiles[msg.sender].stakeTimestamp = 0;

        // Transfer funds back
        (bool success, ) = payable(msg.sender).call{value: amountToUnstake}("");
        require(success, "Failed to unstake funds");

        // Trigger ASBN spec update
        if (userProfiles[msg.sender].asbnTokenId != 0) {
            emit ASBNSpecUpdated(userProfiles[msg.sender].asbnTokenId, keccak256(abi.encode(_calculateASBNSpec(msg.sender))));
        }
        emit ReputationBoostUnstaked(msg.sender, amountToUnstake);
    }

    // --- Dynamic Trait Generation Functions ---

    /**
     * @dev Returns the current dynamically generated trait specifications for a user's ASBN.
     *      This function calculates the traits on-the-fly based on the user's current
     *      Reputation Score, Impact Score, and other on-chain metrics.
     *      This is the core "AI-ish" logic for ASBN evolution.
     * @param _user The address of the user.
     * @return A TraitSpec struct representing the ASBN's current visual and functional attributes.
     */
    function getASBNSpec(address _user) public view returns (TraitSpec memory) {
        if (!hasASBN(_user)) {
            revert NoASBNFound();
        }
        return _calculateASBNSpec(_user);
    }

    /**
     * @dev Internal pure/view function to deterministically calculate ASBN traits based on user's scores.
     *      This is where the "dynamic" and "adaptive" logic resides.
     *      The actual rendering of these traits into images/metadata happens off-chain,
     *      but the logic for *what* traits are present is entirely on-chain.
     * @param _user The address of the user.
     * @return A TraitSpec struct.
     */
    function _calculateASBNSpec(address _user) internal view returns (TraitSpec memory) {
        UserForgeProfile storage profile = userProfiles[_user];
        uint256 reputation = getReputationScore(_user); // Use boosted reputation
        uint256 impact = profile.impactScore;
        uint256 totalAttestations = attestationsReceived[_user].length;
        uint256 asbnAge = (profile.asbnTokenId != 0) ? (block.timestamp - _startTimes[profile.asbnTokenId]) : 0; // _startTimes is from ERC721
        uint256 combinedScore = reputation.add(impact); // Simple combination, can be weighted

        TraitSpec memory spec;

        // Apply trait weights for more nuanced influence
        uint256 baseShapeWeight = traitWeights["baseShape"] > 0 ? traitWeights["baseShape"] : 1;
        uint256 auraColorWeight = traitWeights["auraColor"] > 0 ? traitWeights["auraColor"] : 1;
        uint256 coreMaterialWeight = traitWeights["coreMaterial"] > 0 ? traitWeights["coreMaterial"] : 1;
        uint256 embellishmentWeight = traitWeights["embellishment"] > 0 ? traitWeights["embellishment"] : 1;
        uint256 glyphPatternWeight = traitWeights["glyphPattern"] > 0 ? traitWeights["glyphPattern"] : 1;
        uint256 tierWeight = traitWeights["tier"] > 0 ? traitWeights["tier"] : 1;

        // Example dynamic trait logic:
        // Base Shape
        if (combinedScore.div(baseShapeWeight) < 1000) spec.baseShape = "Fragment";
        else if (combinedScore.div(baseShapeWeight) < 5000) spec.baseShape = "Crystal";
        else if (combinedScore.div(baseShapeWeight) < 15000) spec.baseShape = "Relic";
        else spec.baseShape = "Monument";

        // Aura Color based on Impact
        if (impact.div(auraColorWeight) < 500) spec.auraColor = "Grey";
        else if (impact.div(auraColorWeight) < 2000) spec.auraColor = "Green";
        else if (impact.div(auraColorWeight) < 7000) spec.auraColor = "Blue";
        else spec.auraColor = "Gold";

        // Core Material based on Reputation
        if (reputation.div(coreMaterialWeight) < 700) spec.coreMaterial = "Stone";
        else if (reputation.div(coreMaterialWeight) < 3000) spec.coreMaterial = "Iron";
        else if (reputation.div(coreMaterialWeight) < 10000) spec.coreMaterial = "Silver";
        else spec.coreMaterial = "Mythril";

        // Embellishment based on Attestations
        if (totalAttestations.div(embellishmentWeight) < 5) spec.embellishment = "None";
        else if (totalAttestations.div(embellishmentWeight) < 15) spec.embellishment = "Runes";
        else if (totalAttestations.div(embellishmentWeight) < 30) spec.embellishment = "Gems";
        else spec.embellishment = "Crown";

        // Glyph Pattern based on Staked Amount (or ASBN Age)
        if (profile.stakedAmount.div(glyphPatternWeight) > 0 || asbnAge.div(3600*24*30) > 6) { // Staked or older than 6 months
            if (profile.stakedAmount.div(glyphPatternWeight) > 1 ether || asbnAge.div(3600*24*30) > 12) { // More stake or older than 1 year
                spec.glyphPattern = "Arcane";
            } else {
                spec.glyphPattern = "Geometric";
            }
        } else {
            spec.glyphPattern = "Simple";
        }

        // Tier based on overall progress
        if (combinedScore.div(tierWeight) < 2000) spec.tier = "Apprentice";
        else if (combinedScore.div(tierWeight) < 10000) spec.tier = "Journeyman";
        else if (combinedScore.div(tierWeight) < 30000) spec.tier = "Master";
        else spec.tier = "Grandmaster";

        return spec;
    }

    // --- Moderation & Dispute Resolution Functions ---

    /**
     * @dev Allows any user to report a potentially false or malicious attestation.
     *      This flags the attestation for review by a moderator.
     * @param _attestationId The ID of the attestation being reported.
     * @param _reason A description of why the attestation is considered malicious.
     * @return The ID of the filed report.
     */
    function reportMaliciousAttestation(bytes32 _attestationId, string memory _reason) public whenNotPaused returns (bytes32) {
        UserAttestation storage attestation = allAttestations[_attestationId];
        if (attestation.attester == address(0)) {
            revert AttestationNotFound();
        }
        if (attestation.attester == msg.sender) { // Attester cannot report their own attestation
            revert AttestationIsSelfReported();
        }

        _reportIdCounter.increment();
        bytes32 reportId = keccak256(abi.encodePacked(_reportIdCounter.current(), _attestationId, msg.sender, block.timestamp));

        reports[reportId] = ReportEntry({
            attestationId: _attestationId,
            reporter: msg.sender,
            reason: _reason,
            resolved: false,
            isMalicious: false, // Default to false, moderator sets true
            createdAt: block.timestamp
        });

        emit ReportFiled(reportId, _attestationId, msg.sender, _reason);
        return reportId;
    }

    /**
     * @dev Resolves a reported malicious attestation. Only callable by the owner or a moderator.
     *      If the report is deemed malicious, the attested user's reputation is penalized,
     *      and the attester (if malicious) can also be penalized.
     * @param _reportId The ID of the report to resolve.
     * @param _isMalicious True if the attestation is confirmed malicious, false otherwise.
     * @param _penaltyAmount If malicious, the amount of reputation to deduct from the attester.
     */
    function resolveReport(bytes32 _reportId, bool _isMalicious, uint256 _penaltyAmount) public onlyModerator {
        ReportEntry storage report = reports[_reportId];
        if (report.attestationId == 0) { // Check if report exists
            revert ReportNotFound();
        }
        if (report.resolved) {
            revert UnauthorizedAction(); // Already resolved
        }

        report.resolved = true;
        report.isMalicious = _isMalicious;

        if (_isMalicious) {
            UserAttestation storage attestation = allAttestations[report.attestationId];
            if (attestation.attester == address(0)) { // Attestation might have been revoked already
                revert AttestationNotFound();
            }

            // Revoke the malicious attestation
            if (!attestation.revoked) {
                attestation.revoked = true;
                userProfiles[attestation.attestedUser].reputationScore = userProfiles[attestation.attestedUser].reputationScore.sub(attestation.reputationBoost);
            }

            // Penalize the malicious attester
            userProfiles[attestation.attester].reputationScore = userProfiles[attestation.attester].reputationScore.sub(_penaltyAmount);

            // Update ASBNs
            if (userProfiles[attestation.attestedUser].asbnTokenId != 0) {
                emit ASBNSpecUpdated(userProfiles[attestation.attestedUser].asbnTokenId, keccak256(abi.encode(_calculateASBNSpec(attestation.attestedUser))));
            }
            if (userProfiles[attestation.attester].asbnTokenId != 0) {
                emit ASBNSpecUpdated(userProfiles[attestation.attester].asbnTokenId, keccak256(abi.encode(_calculateASBNSpec(attestation.attester))));
            }
        }

        emit ReportResolved(_reportId, _isMalicious, _penaltyAmount);
    }
}
```