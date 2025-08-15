The `AuraForge Protocol` is a sophisticated Solidity smart contract designed to build a decentralized and dynamic reputation and contribution graph within an ecosystem. Unlike typical NFT projects, it focuses on interconnected data, evolving identities, and AI-aided recognition of contributions. It combines elements of Soulbound Tokens (SBTs) for identity, standard NFTs for projects, and a unique mechanism for dynamic revenue sharing based on verifiable and impactful contributions.

---

### AuraForge Protocol: Outline & Function Summary

**I. Core Identity & Aura (Soulbound Tokens - AuraNodes)**
*   **`registerAuraNode()`**: Creates a unique soulbound AuraNode (SBT) for the caller, establishing their on-chain identity within the protocol. Each address can only register one AuraNode.
*   **`updateAuraNodeProfile(string _metadataURI)`**: Allows an AuraNode owner to update their associated metadata URI (e.g., IPFS hash pointing to profile information).
*   **`getAuraNode(address _owner)`**: Retrieves the token ID of the AuraNode owned by a given address.
*   **`getAuraScore(address _auraNodeOwner)`**: Returns the current accumulated Aura (reputation) score for a specific AuraNode owner.
*   **`_mintAura(address _auraNodeOwner, uint256 _amount)`**: Internal function to securely increment an AuraNode's score, typically called upon successful contribution verification or evaluation.

**II. Contribution Spheres (NFTs - ERC721)**
*   **`createContributionSphere(string _metadataURI)`**: Mints a new ERC721 `ContributionSphere` NFT. This represents a project, initiative, or collective effort. The caller becomes the owner of the new Sphere.
*   **`updateContributionSphereMetadata(uint256 _sphereId, string _newMetadataURI)`**: Allows the owner of a `ContributionSphere` to update its metadata URI.
*   **`transferFrom(address _from, address _to, uint256 _sphereId)`**: Standard ERC721 transfer function for `ContributionSphere` NFTs, allowing their ownership to change.
*   **`getContributionSphereDetails(uint256 _sphereId)`**: Retrieves the owner's address and metadata URI for a given `ContributionSphere` ID.

**III. AuraLinks & Contribution Graph**
*   **`attestContribution(uint256 _sphereId, string _role, string _proofURI)`**: Allows an AuraNode owner to record their claim of contribution to a specific `ContributionSphere`. This creates a pending `AuraLink` that needs verification.
*   **`verifyContribution(uint256 _sphereId, address _contributorNode)`**: Allows the `ContributionSphere` owner to verify a pending contribution attestation from a specific AuraNode. Upon verification, the contributor's Aura score is incremented.
*   **`revokeContribution(uint256 _sphereId, address _contributorNode)`**: Allows the `ContributionSphere` owner to revoke a previously verified contribution. This action will decrement the contributor's Aura score.
*   **`getAuraLinksForSphere(uint256 _sphereId)`**: Returns an array of all AuraNode addresses that have attested or verified contributions to a given `ContributionSphere`.
*   **`getAuraLinksForNode(address _auraNodeOwner)`**: Returns an array of `ContributionSphere` IDs to which a specific AuraNode has contributed.
*   **`computeWeightedContribution(uint256 _sphereId, address _contributorNode)`**: Calculates a dynamic, weighted contribution score for an AuraNode within a specific Sphere. This considers factors like role, verification status, and an AI-determined impact score.

**IV. Dynamic Entitlements & Royalties**
*   **`setSphereRevenueShareBasis(uint256 _sphereId, uint256 _totalShareBasisPoints)`**: Allows the `ContributionSphere` owner to define the total percentage (in basis points, where 10000 = 100%) of future revenue that will be dynamically distributed among verified contributors.
*   **`distributeSphereRevenue(uint256 _sphereId)`**: Allows the `ContributionSphere` owner to deposit funds (e.g., ETH) for distribution. The protocol automatically calculates and allocates shares to verified contributors based on their `computeWeightedContribution`.
*   **`claimSphereRevenue(uint256 _sphereId)`**: Allows a verified contributor to claim their accumulated share of revenue from a `ContributionSphere`.

**V. AuraCasting & Advanced Recognition (Oracle/AI-Enabled - Simulated)**
*   **`requestAuraCastingEvaluation(uint256 _sphereId, address _contributorNode)`**: Initiates a request to a decentralized oracle network (simulated Chainlink) for an AI-aided evaluation of a specific `AuraLink`'s impact and quality.
*   **`fulfillAuraCastingEvaluation(bytes32 _requestId, uint256 _sphereId, address _contributorNode, int256 _impactScore)`**: This is a callback function intended to be invoked by the trusted oracle after an AI evaluation. It updates the impact score of the specified `AuraLink` and potentially adjusts the contributor's Aura.
*   **`setAuraCastingOracleAddress(address _oracle)`**: Allows the contract owner to set the address of the trusted oracle (e.g., a Chainlink oracle).

**VI. Governance & System Parameters**
*   **`setVerificationFee(uint256 _fee)`**: Allows the contract owner to set an optional fee (in native token) required for `verifyContribution` to prevent spam or fund protocol operations.
*   **`proposeAuraParameterChange(bytes32 _paramHash, uint256 _newValue)`**: Initiates a governance proposal to change a system-wide parameter affecting Aura scoring or distribution mechanics. This function is a simplified placeholder for a more advanced DAO system.
*   **`voteOnAuraParameterChange(bytes32 _paramHash, bool _approve)`**: Allows registered AuraNode holders to vote on active governance proposals, with voting weight based on their current Aura score.
*   **`executeAuraParameterChange(bytes32 _paramHash)`**: Executes a governance proposal if it meets predefined quorum and approval thresholds after the voting period ends.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for a mock Chainlink-like oracle
interface IOracle {
    // This function would be called by the oracle upon completion of an off-chain task.
    // In a real Chainlink setup, it would likely be 'fulfillOracleRequest' or similar,
    // with request-specific parameters passed back.
    function fulfill(bytes32 _requestId, uint256 _sphereId, address _contributorNode, int256 _impactScore) external;
}

/**
 * @title AuraForge Protocol
 * @dev A decentralized protocol for building a reputation and contribution graph,
 *      featuring Soulbound AuraNodes, dynamic ContributionSpheres, and AI-aided
 *      recognition (via oracle simulation). It enables dynamic revenue sharing
 *      based on verifiable contributions.
 */
contract AuraForge is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Outline & Function Summary ---

    // I. Core Identity & Aura (Soulbound Tokens - AuraNodes)
    // 1.  `registerAuraNode()`: Creates a new soulbound AuraNode for the caller.
    // 2.  `updateAuraNodeProfile(string _metadataURI)`: Updates profile metadata for an AuraNode.
    // 3.  `getAuraNode(address _owner)`: Retrieves the token ID of an AuraNode for a given address.
    // 4.  `getAuraScore(address _auraNodeOwner)`: Returns the current accumulated Aura score for an AuraNode.
    // 5.  `_mintAura(address _auraNodeOwner, uint256 _amount)`: Internal function to award Aura points.

    // II. Contribution Spheres (NFTs - ERC721)
    // 6.  `createContributionSphere(string _metadataURI)`: Mints a new ContributionSphere NFT.
    // 7.  `updateContributionSphereMetadata(uint256 _sphereId, string _newMetadataURI)`: Updates metadata for a Sphere.
    // 8.  `transferFrom(address _from, address _to, uint256 _sphereId)`: Standard ERC721 transfer for Spheres.
    // 9.  `getContributionSphereDetails(uint256 _sphereId)`: Retrieves details for a specific Sphere.

    // III. AuraLinks & Contribution Graph
    // 10. `attestContribution(uint256 _sphereId, string _role, string _proofURI)`: AuraNode owner attests their contribution.
    // 11. `verifyContribution(uint256 _sphereId, address _contributorNode)`: Sphere owner verifies a contribution, awarding Aura.
    // 12. `revokeContribution(uint256 _sphereId, address _contributorNode)`: Sphere owner revokes a contribution, decrementing Aura.
    // 13. `getAuraLinksForSphere(uint256 _sphereId)`: Retrieves all contributors (AuraNode addresses) to a Sphere.
    // 14. `getAuraLinksForNode(address _auraNodeOwner)`: Retrieves all Spheres an AuraNode has contributed to.
    // 15. `computeWeightedContribution(uint256 _sphereId, address _contributorNode)`: Calculates an AuraNode's weighted contribution to a Sphere.

    // IV. Dynamic Entitlements & Royalties
    // 16. `setSphereRevenueShareBasis(uint256 _sphereId, uint256 _totalShareBasisPoints)`: Sets the basis for dynamic revenue sharing for a Sphere.
    // 17. `distributeSphereRevenue(uint256 _sphereId)`: Distributes deposited revenue to contributors based on their weighted contribution.
    // 18. `claimSphereRevenue(uint256 _sphereId)`: Allows a contributor to claim their share of revenue from a Sphere.

    // V. AuraCasting & Advanced Recognition (Oracle/AI-Enabled - Simulated)
    // 19. `requestAuraCastingEvaluation(uint256 _sphereId, address _contributorNode)`: Requests an AI-aided evaluation of a contribution.
    // 20. `fulfillAuraCastingEvaluation(bytes32 _requestId, uint256 _sphereId, address _contributorNode, int256 _impactScore)`: Oracle callback for evaluation results.
    // 21. `setAuraCastingOracleAddress(address _oracle)`: Sets the address of the trusted oracle.

    // VI. Governance & System Parameters
    // 22. `setVerificationFee(uint256 _fee)`: Sets the fee for contribution verification.
    // 23. `proposeAuraParameterChange(bytes32 _paramHash, uint256 _newValue)`: Initiates a governance proposal for system parameters.
    // 24. `voteOnAuraParameterChange(bytes32 _paramHash, bool _approve)`: Allows AuraNode holders to vote on proposals.
    // 25. `executeAuraParameterChange(bytes32 _paramHash)`: Executes a governance proposal.

    // --- State Variables & Structs ---

    // AuraNodes (Soulbound ERC721-like implementation)
    Counters.Counter private _auraNodeTokenIds; // Tracks the next available AuraNode ID
    mapping(address => uint256) private _auraNodeOf; // Maps owner address to their AuraNode tokenId (0 if no node)
    mapping(uint256 => string) private _auraNodeMetadataURIs; // Maps AuraNode tokenId to its metadata URI
    mapping(address => uint256) private _auraScores; // Maps AuraNode owner address to their total Aura score

    // Contribution Spheres (ERC721)
    Counters.Counter private _sphereTokenIds; // Tracks the next available Sphere ID
    ERC721 private _contributionSpheres; // Instance of the ERC721 contract for Spheres
    mapping(uint256 => string) private _sphereMetadataURIs; // Maps Sphere tokenId to its metadata URI

    // AuraLinks (Contribution Graph Data Structure)
    struct AuraLink {
        uint256 sphereId; // ID of the Contribution Sphere
        address contributorNode; // Address of the AuraNode owner who contributed
        string role; // Role of the contributor (e.g., "Developer", "Designer")
        string proofURI; // URI to off-chain evidence of the contribution
        bool isVerified; // True if the contribution has been verified by the Sphere owner
        int256 impactScore; // AI-determined impact score from AuraCasting (default 0)
        uint256 verificationTimestamp; // Timestamp of verification
        bool exists; // Flag to indicate if this link entry is active
    }

    // A unique key for each AuraLink: keccak256(sphereId, contributorNode)
    mapping(bytes32 => AuraLink) private _auraLinks;
    mapping(uint256 => bytes32[]) private _sphereToAuraLinks; // Maps Sphere ID to a list of its AuraLink keys
    mapping(address => bytes32[]) private _nodeToAuraLinks; // Maps AuraNode owner to a list of their AuraLink keys

    // Dynamic Entitlements & Revenue Sharing
    // 10000 basis points = 100%
    mapping(uint256 => uint256) private _sphereRevenueShareBasis; // Sphere ID to total share basis points to be distributed
    mapping(uint256 => mapping(address => uint256)) private _pendingRevenueClaims; // Sphere ID -> Contributor Address -> Amount in Wei

    // AuraCasting (Oracle Integration)
    address public auraCastingOracle; // Address of the trusted oracle (e.g., Chainlink node)
    mapping(bytes32 => bool) public pendingAuraCastingRequests; // Tracks active oracle requests by their requestId

    // Governance Parameters
    uint256 public verificationFee = 0; // Fee required to verify a contribution (in native token Wei)
    uint256 public BASE_AURA_FOR_VERIFIED_CONTRIBUTION = 100; // Base Aura points awarded per verified contribution

    // Simple Governance Proposal Mechanism
    struct Proposal {
        bytes32 paramHash; // Hash of the parameter being proposed for change
        uint256 newValue; // Proposed new value for the parameter
        uint256 votesFor; // Total Aura score voting for the proposal
        uint256 votesAgainst; // Total Aura score voting against the proposal
        mapping(address => bool) hasVoted; // Tracks if an AuraNode owner has voted
        bool executed; // True if the proposal has been executed
        uint256 creationTime; // Timestamp when the proposal was created
        uint256 expirationTime; // Timestamp when the voting period ends
    }
    mapping(bytes32 => Proposal) public proposals; // Maps proposal hash to its Proposal struct
    bytes32[] public activeProposals; // List of active proposal hashes
    uint256 public constant MIN_VOTING_PERIOD = 3 days; // Minimum duration for voting
    // For a real system, QUORUM_PERCENTAGE would apply to total Aura score supply,
    // which requires iterating all AuraNodes or maintaining a global Aura sum.
    // For this example, quorum is simplified (see executeAuraParameterChange).
    uint256 public constant QUORUM_PERCENTAGE = 20; // 20% (theoretical)

    // --- Events ---

    event AuraNodeRegistered(address indexed owner, uint256 tokenId);
    event AuraNodeProfileUpdated(address indexed owner, string newMetadataURI);
    event AuraScoreUpdated(address indexed owner, uint256 newScore);

    event ContributionSphereCreated(address indexed owner, uint256 sphereId, string metadataURI);
    event ContributionSphereMetadataUpdated(uint256 indexed sphereId, string newMetadataURI);

    event ContributionAttested(uint256 indexed sphereId, address indexed contributor, string role, string proofURI);
    event ContributionVerified(uint256 indexed sphereId, address indexed contributor, uint256 auraAwarded);
    event ContributionRevoked(uint256 indexed sphereId, address indexed contributor, uint256 auraDeducted);
    event ImpactScoreUpdated(uint256 indexed sphereId, address indexed contributor, int256 impactScore);

    event SphereRevenueShareBasisSet(uint256 indexed sphereId, uint256 totalShareBasisPoints);
    event SphereRevenueDistributed(uint256 indexed sphereId, uint256 amount);
    event SphereRevenueClaimed(uint256 indexed sphereId, address indexed contributor, uint256 amount);

    event AuraCastingRequested(bytes32 indexed requestId, uint256 indexed sphereId, address indexed contributor);
    event AuraCastingOracleAddressSet(address indexed newOracleAddress);

    event VerificationFeeSet(uint256 newFee);
    event GovernanceProposalCreated(bytes32 indexed paramHash, uint256 newValue, uint256 expirationTime);
    event GovernanceVoteCast(bytes32 indexed paramHash, address indexed voter, bool support);
    event GovernanceProposalExecuted(bytes32 indexed paramHash);

    // --- Constructor ---

    /**
     * @dev Initializes the AuraForge Protocol, deploying the ERC721 contract for ContributionSpheres.
     * @param _sphereName The name for the ERC721 ContributionSphere contract.
     * @param _sphereSymbol The symbol for the ERC721 ContributionSphere contract.
     */
    constructor(string memory _sphereName, string memory _sphereSymbol) Ownable(msg.sender) {
        _contributionSpheres = new ERC721(_sphereName, _sphereSymbol);
    }

    // --- Modifiers ---

    /**
     * @dev Restricts access to functions callable only by the owner of an AuraNode.
     * @param _owner The address of the expected AuraNode owner.
     */
    modifier onlyAuraNodeOwner(address _owner) {
        require(_auraNodeOf[_owner] > 0, "AuraForge: Caller is not a registered AuraNode owner.");
        require(msg.sender == _owner, "AuraForge: Only the AuraNode owner can perform this action.");
        _;
    }

    /**
     * @dev Restricts access to functions callable only by the owner of a ContributionSphere.
     * @param _sphereId The ID of the ContributionSphere.
     */
    modifier onlySphereOwner(uint256 _sphereId) {
        require(_contributionSpheres.ownerOf(_sphereId) == msg.sender, "AuraForge: Caller is not the Sphere owner.");
        _;
    }

    /**
     * @dev Restricts access to functions callable only by the designated AuraCasting oracle.
     */
    modifier onlyOracle() {
        require(msg.sender == auraCastingOracle, "AuraForge: Only the designated oracle can call this function.");
        _;
    }

    // --- I. Core Identity & Aura (Soulbound Tokens - AuraNodes) ---

    /**
     * @dev Creates a new soulbound AuraNode (SBT) for the caller.
     *      Each address can only register one AuraNode.
     */
    function registerAuraNode() external {
        require(_auraNodeOf[msg.sender] == 0, "AuraForge: You already have an AuraNode.");
        _auraNodeTokenIds.increment();
        uint256 tokenId = _auraNodeTokenIds.current();
        _auraNodeOf[msg.sender] = tokenId; // Map owner to their unique AuraNode ID
        // AuraNodes are purely represented by this mapping and token ID,
        // their soulbound nature is enforced by the absence of ERC721 transfer functions for them.

        emit AuraNodeRegistered(msg.sender, tokenId);
    }

    /**
     * @dev Allows an AuraNode owner to update their associated metadata URI.
     * @param _metadataURI A URI pointing to off-chain metadata (e.g., IPFS hash).
     */
    function updateAuraNodeProfile(string calldata _metadataURI) external onlyAuraNodeOwner(msg.sender) {
        _auraNodeMetadataURIs[_auraNodeOf[msg.sender]] = _metadataURI;
        emit AuraNodeProfileUpdated(msg.sender, _metadataURI);
    }

    /**
     * @dev Retrieves the token ID of the AuraNode owned by a given address.
     * @param _owner The address to query.
     * @return The AuraNode's token ID, or 0 if none exists.
     */
    function getAuraNode(address _owner) external view returns (uint256) {
        return _auraNodeOf[_owner];
    }

    /**
     * @dev Retrieves the current accumulated Aura score for a specific AuraNode owner.
     * @param _auraNodeOwner The address of the AuraNode owner.
     * @return The Aura score.
     */
    function getAuraScore(address _auraNodeOwner) public view returns (uint256) {
        return _auraScores[_auraNodeOwner];
    }

    /**
     * @dev Internal function to increment an AuraNode's score.
     *      Can be called upon successful contribution verification or evaluation.
     * @param _auraNodeOwner The address whose Aura score should be incremented.
     * @param _amount The amount of Aura to add.
     */
    function _mintAura(address _auraNodeOwner, uint256 _amount) internal {
        require(_auraNodeOf[_auraNodeOwner] > 0, "AuraForge: Target address must have an AuraNode.");
        _auraScores[_auraNodeOwner] = _auraScores[_auraNodeOwner].add(_amount);
        emit AuraScoreUpdated(_auraNodeOwner, _auraScores[_auraNodeOwner]);
    }

    /**
     * @dev Internal function to decrement an AuraNode's score.
     * @param _auraNodeOwner The address whose Aura score should be decremented.
     * @param _amount The amount of Aura to deduct.
     */
    function _burnAura(address _auraNodeOwner, uint256 _amount) internal {
        require(_auraNodeOf[_auraNodeOwner] > 0, "AuraForge: Target address must have an AuraNode.");
        _auraScores[_auraNodeOwner] = _auraScores[_auraNodeOwner].sub(_amount, "AuraForge: Insufficient Aura to burn.");
        emit AuraScoreUpdated(_auraNodeOwner, _auraScores[_auraNodeOwner]);
    }

    // --- II. Contribution Spheres (ERC721) ---

    /**
     * @dev Mints a new ERC721 ContributionSphere NFT.
     *      The caller becomes the owner of the new Sphere.
     * @param _metadataURI A URI pointing to off-chain metadata for the Sphere.
     * @return The ID of the newly created Sphere.
     */
    function createContributionSphere(string calldata _metadataURI) external returns (uint256) {
        _sphereTokenIds.increment();
        uint256 sphereId = _sphereTokenIds.current();
        _contributionSpheres.safeMint(msg.sender, sphereId);
        _sphereMetadataURIs[sphereId] = _metadataURI;

        emit ContributionSphereCreated(msg.sender, sphereId, _metadataURI);
        return sphereId;
    }

    /**
     * @dev Allows the owner of a ContributionSphere to update its metadata URI.
     * @param _sphereId The ID of the Sphere to update.
     * @param _newMetadataURI The new URI pointing to off-chain metadata.
     */
    function updateContributionSphereMetadata(uint256 _sphereId, string calldata _newMetadataURI) external onlySphereOwner(_sphereId) {
        _sphereMetadataURIs[_sphereId] = _newMetadataURI;
        emit ContributionSphereMetadataUpdated(_sphereId, _newMetadataURI);
    }

    /**
     * @dev Standard ERC721 transfer for ContributionSphere NFTs.
     *      Requires approval or direct ownership. This function delegates to the underlying ERC721 contract.
     */
    function transferFrom(address _from, address _to, uint256 _sphereId) external {
        _contributionSpheres.transferFrom(_from, _to, _sphereId);
    }
    
    /**
     * @dev Retrieves all stored details for a given ContributionSphere ID.
     * @param _sphereId The ID of the Sphere to query.
     * @return owner The owner's address.
     * @return metadataURI The metadata URI.
     */
    function getContributionSphereDetails(uint256 _sphereId) external view returns (address owner, string memory metadataURI) {
        require(_sphereTokenIds.current() >= _sphereId && _sphereId > 0, "AuraForge: Invalid Sphere ID.");
        owner = _contributionSpheres.ownerOf(_sphereId);
        metadataURI = _sphereMetadataURIs[_sphereId];
    }

    // --- III. AuraLinks & Contribution Graph ---

    /**
     * @dev Allows an AuraNode owner to record their claim of contribution to a specific ContributionSphere.
     *      This creates a pending AuraLink that needs verification by the Sphere owner.
     * @param _sphereId The ID of the Sphere to contribute to.
     * @param _role A string describing the contributor's role (e.g., "Developer", "Designer").
     * @param _proofURI A URI pointing to off-chain evidence of the contribution.
     */
    function attestContribution(uint256 _sphereId, string calldata _role, string calldata _proofURI) external onlyAuraNodeOwner(msg.sender) {
        require(_sphereTokenIds.current() >= _sphereId && _sphereId > 0, "AuraForge: Sphere does not exist.");

        bytes32 linkKey = keccak256(abi.encodePacked(_sphereId, msg.sender));
        require(!_auraLinks[linkKey].exists, "AuraForge: Contribution already attested or verified for this Sphere by this node.");

        _auraLinks[linkKey] = AuraLink({
            sphereId: _sphereId,
            contributorNode: msg.sender,
            role: _role,
            proofURI: _proofURI,
            isVerified: false,
            impactScore: 0, // Default impact score
            verificationTimestamp: 0,
            exists: true
        });

        _sphereToAuraLinks[_sphereId].push(linkKey);
        _nodeToAuraLinks[msg.sender].push(linkKey);

        emit ContributionAttested(_sphereId, msg.sender, _role, _proofURI);
    }

    /**
     * @dev Allows the ContributionSphere owner to verify a pending contribution attestation from a specific AuraNode.
     *      Upon verification, the contributor's Aura score is incremented.
     *      A `verificationFee` can be configured by the contract owner.
     * @param _sphereId The ID of the Sphere.
     * @param _contributorNode The address of the AuraNode owner whose contribution is being verified.
     */
    function verifyContribution(uint256 _sphereId, address _contributorNode) external payable nonReentrant onlySphereOwner(_sphereId) {
        require(msg.value >= verificationFee, "AuraForge: Insufficient verification fee.");
        if (verificationFee > 0) {
            // Transfer fee to contract owner (or a treasury)
            payable(owner()).transfer(msg.value);
        }

        bytes32 linkKey = keccak256(abi.encodePacked(_sphereId, _contributorNode));
        AuraLink storage link = _auraLinks[linkKey];

        require(link.exists, "AuraForge: Contribution attestation does not exist.");
        require(!link.isVerified, "AuraForge: Contribution is already verified.");

        link.isVerified = true;
        link.verificationTimestamp = block.timestamp;

        // Award base Aura points for verification
        _mintAura(_contributorNode, BASE_AURA_FOR_VERIFIED_CONTRIBUTION);

        emit ContributionVerified(_sphereId, _contributorNode, BASE_AURA_FOR_VERIFIED_CONTRIBUTION);
    }

    /**
     * @dev Allows the ContributionSphere owner to revoke a previously verified contribution.
     *      This will decrement the contributor's Aura score.
     * @param _sphereId The ID of the Sphere.
     * @param _contributorNode The address of the AuraNode owner whose contribution is being revoked.
     */
    function revokeContribution(uint256 _sphereId, address _contributorNode) external nonReentrant onlySphereOwner(_sphereId) {
        bytes32 linkKey = keccak256(abi.encodePacked(_sphereId, _contributorNode));
        AuraLink storage link = _auraLinks[linkKey];

        require(link.exists, "AuraForge: Contribution attestation does not exist.");
        require(link.isVerified, "AuraForge: Contribution is not verified yet.");

        link.isVerified = false; // Mark as unverified
        link.impactScore = 0; // Reset impact score upon revocation

        // Deduct Aura points. In a more complex system, this deduction might be based on how long it was verified.
        _burnAura(_contributorNode, BASE_AURA_FOR_VERIFIED_CONTRIBUTION);

        emit ContributionRevoked(_sphereId, _contributorNode, BASE_AURA_FOR_VERIFIED_CONTRIBUTION);
    }

    /**
     * @dev Retrieves an array of all AuraNode addresses that have attested or verified contributions to a given Sphere.
     * @param _sphereId The ID of the Sphere.
     * @return An array of AuraNode owner addresses.
     */
    function getAuraLinksForSphere(uint256 _sphereId) external view returns (address[] memory) {
        bytes32[] storage linkKeys = _sphereToAuraLinks[_sphereId];
        address[] memory contributors = new address[](linkKeys.length);
        for (uint256 i = 0; i < linkKeys.length; i++) {
            contributors[i] = _auraLinks[linkKeys[i]].contributorNode;
        }
        return contributors;
    }

    /**
     * @dev Retrieves an array of ContributionSphere IDs to which a specific AuraNode has contributed.
     * @param _auraNodeOwner The address of the AuraNode owner.
     * @return An array of ContributionSphere IDs.
     */
    function getAuraLinksForNode(address _auraNodeOwner) external view returns (uint256[] memory) {
        bytes32[] storage linkKeys = _nodeToAuraLinks[_auraNodeOwner];
        uint256[] memory spheres = new uint256[](linkKeys.length);
        for (uint256 i = 0; i < linkKeys.length; i++) {
            spheres[i] = _auraLinks[linkKeys[i]].sphereId;
        }
        return spheres;
    }

    /**
     * @dev Calculates a dynamic, weighted contribution score for an AuraNode within a specific Sphere.
     *      This calculation can be customized based on various factors (e.g., role, verification status, impact score).
     * @param _sphereId The ID of the Sphere.
     * @param _contributorNode The address of the AuraNode owner.
     * @return The weighted contribution score for that AuraNode in that Sphere.
     */
    function computeWeightedContribution(uint256 _sphereId, address _contributorNode) public view returns (uint256) {
        bytes32 linkKey = keccak256(abi.encodePacked(_sphereId, _contributorNode));
        AuraLink storage link = _auraLinks[linkKey];

        if (!link.exists || !link.isVerified) {
            return 0; // Only verified contributions count for weighted score
        }

        uint256 score = BASE_AURA_FOR_VERIFIED_CONTRIBUTION; // Base for being verified

        // Add modifiers based on role (simple example)
        if (keccak256(abi.encodePacked(link.role)) == keccak256(abi.encodePacked("Developer"))) {
            score = score.add(50);
        } else if (keccak256(abi.encodePacked(link.role)) == keccak256(abi.encodePacked("Designer"))) {
            score = score.add(30);
        } else if (keccak256(abi.encodePacked(link.role)) == keccak256(abi.encodePacked("Community Manager"))) {
            score = score.add(20);
        }
        // More complex logic could involve duration, external data, etc.

        // Incorporate AI-determined impact score (if available)
        if (link.impactScore > 0) {
            score = score.add(uint256(link.impactScore));
        } else if (link.impactScore < 0) { // Penalize negative impact
             // Ensure score doesn't underflow
             score = score.sub(uint256(link.impactScore * -1), "AuraForge: Weighted score cannot be negative from impact.");
        }

        return score;
    }

    // --- IV. Dynamic Entitlements & Royalties ---

    /**
     * @dev Allows the ContributionSphere owner to define the total percentage (in basis points)
     *      of future revenue that will be dynamically distributed among verified contributors.
     *      10,000 basis points = 100%.
     * @param _sphereId The ID of the Sphere.
     * @param _totalShareBasisPoints The total percentage of revenue to be shared (0-10000).
     */
    function setSphereRevenueShareBasis(uint256 _sphereId, uint256 _totalShareBasisPoints) external onlySphereOwner(_sphereId) {
        require(_totalShareBasisPoints <= 10000, "AuraForge: Share basis points cannot exceed 10000 (100%).");
        _sphereRevenueShareBasis[_sphereId] = _totalShareBasisPoints;
        emit SphereRevenueShareBasisSet(_sphereId, _totalShareBasisPoints);
    }

    /**
     * @dev Allows the ContributionSphere owner to deposit funds for distribution.
     *      The protocol then calculates and allocates shares to verified contributors
     *      based on their `computeWeightedContribution` score relative to the total weighted score
     *      of all verified contributors in that Sphere.
     * @param _sphereId The ID of the Sphere to distribute revenue for.
     */
    function distributeSphereRevenue(uint256 _sphereId) external payable nonReentrant onlySphereOwner(_sphereId) {
        require(msg.value > 0, "AuraForge: No ETH to distribute.");
        
        uint256 totalShareBasis = _sphereRevenueShareBasis[_sphereId];
        require(totalShareBasis > 0, "AuraForge: No share basis defined for this Sphere for distribution.");

        uint256 amountToDistribute = msg.value.mul(totalShareBasis).div(10000);
        
        bytes32[] storage linkKeys = _sphereToAuraLinks[_sphereId];
        uint256 totalWeightedContributionSum = 0;

        // First pass: Calculate total weighted contribution sum of all verified contributors for this Sphere
        for (uint256 i = 0; i < linkKeys.length; i++) {
            AuraLink storage link = _auraLinks[linkKeys[i]];
            if (link.isVerified) {
                totalWeightedContributionSum = totalWeightedContributionSum.add(computeWeightedContribution(_sphereId, link.contributorNode));
            }
        }

        require(totalWeightedContributionSum > 0, "AuraForge: No active, verified contributors or total weighted contribution is zero.");

        // Second pass: Allocate shares based on proportional weighted contribution
        for (uint256 i = 0; i < linkKeys.length; i++) {
            AuraLink storage link = _auraLinks[linkKeys[i]];
            if (link.isVerified) {
                uint256 contributorWeightedScore = computeWeightedContribution(_sphereId, link.contributorNode);
                // Ensure no division by zero if totalWeightedContributionSum somehow becomes 0 after initial check (unlikely but safe)
                if (contributorWeightedScore > 0) {
                    uint256 share = amountToDistribute.mul(contributorWeightedScore).div(totalWeightedContributionSum);
                    if (share > 0) {
                        _pendingRevenueClaims[_sphereId][link.contributorNode] = _pendingRevenueClaims[_sphereId][link.contributorNode].add(share);
                    }
                }
            }
        }

        // Send any remaining unshared ETH back to the owner (if basis points < 10000 or due to rounding)
        uint256 unsharedAmount = msg.value.sub(amountToDistribute);
        if (unsharedAmount > 0) {
            payable(msg.sender).transfer(unsharedAmount);
        }

        emit SphereRevenueDistributed(_sphereId, amountToDistribute);
    }

    /**
     * @dev Allows a verified contributor to claim their accumulated share of revenue from a ContributionSphere.
     * @param _sphereId The ID of the Sphere from which to claim revenue.
     */
    function claimSphereRevenue(uint256 _sphereId) external nonReentrant {
        uint256 amountToClaim = _pendingRevenueClaims[_sphereId][msg.sender];
        require(amountToClaim > 0, "AuraForge: No pending revenue to claim for this Sphere.");

        _pendingRevenueClaims[_sphereId][msg.sender] = 0; // Reset claimable amount to prevent re-claiming
        payable(msg.sender).transfer(amountToClaim);

        emit SphereRevenueClaimed(_sphereId, msg.sender, amountToClaim);
    }

    // --- V. AuraCasting & Advanced Recognition (Oracle/AI-Enabled - Simulated) ---

    /**
     * @dev Requests an AI-aided evaluation of a specific AuraLink's impact.
     *      This function simulates an interaction with a decentralized oracle network
     *      like Chainlink for off-chain computation (e.g., AI model inference).
     *      The caller must be the AuraNode owner of the contribution.
     * @param _sphereId The ID of the Sphere containing the contribution.
     * @param _contributorNode The address of the AuraNode owner who made the contribution.
     */
    function requestAuraCastingEvaluation(uint256 _sphereId, address _contributorNode) external nonReentrant onlyAuraNodeOwner(msg.sender) {
        require(auraCastingOracle != address(0), "AuraForge: AuraCasting Oracle not set.");
        require(_sphereId > 0 && _sphereId <= _sphereTokenIds.current(), "AuraForge: Invalid Sphere ID.");
        require(_contributorNode != address(0) && _auraNodeOf[_contributorNode] > 0, "AuraForge: Invalid AuraNode address.");

        bytes32 linkKey = keccak256(abi.encodePacked(_sphereId, _contributorNode));
        require(_auraLinks[linkKey].exists, "AuraForge: Contribution link does not exist.");
        // Decide if only verified contributions can be evaluated, or also pending ones.
        require(_auraLinks[linkKey].isVerified, "AuraForge: Contribution must be verified before AI evaluation.");
        
        // In a real Chainlink integration, this would initiate an external Chainlink request
        // and return a requestId. Here, we generate a mock requestId.
        // The actual call would look something like:
        // bytes32 requestId = i_chainlink.requestBytes(_jobId, _callbackAddress, _callbackFunction, _data);
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, _sphereId, _contributorNode, msg.sender, "AuraCastingRequest"));
        pendingAuraCastingRequests[requestId] = true;

        // For demonstration, we would manually call fulfillAuraCastingEvaluation from a mock oracle.
        // In a live system, a Chainlink node would make the callback.

        emit AuraCastingRequested(requestId, _sphereId, _contributorNode);
    }

    /**
     * @dev Callback function invoked by the trusted oracle after an AI evaluation.
     *      Updates the impact score of the specified AuraLink and potentially adjusts the contributor's Aura.
     *      This function is only callable by the designated `auraCastingOracle` address.
     * @param _requestId The ID of the original request.
     * @param _sphereId The ID of the Sphere.
     * @param _contributorNode The address of the contributor's AuraNode.
     * @param _impactScore The AI-determined impact score (can be positive or negative).
     */
    function fulfillAuraCastingEvaluation(bytes32 _requestId, uint256 _sphereId, address _contributorNode, int256 _impactScore) external onlyOracle {
        require(pendingAuraCastingRequests[_requestId], "AuraForge: Invalid or already fulfilled request ID.");
        delete pendingAuraCastingRequests[_requestId]; // Mark request as fulfilled

        bytes32 linkKey = keccak256(abi.encodePacked(_sphereId, _contributorNode));
        AuraLink storage link = _auraLinks[linkKey];

        require(link.exists, "AuraForge: Contribution link does not exist for fulfilling.");
        require(link.isVerified, "AuraForge: Only verified contributions can receive an impact score update.");

        link.impactScore = _impactScore;

        // Adjust Aura score based on impact (example logic)
        // This could be refined: perhaps a decaying impact, or only positive impact boosts.
        if (_impactScore > 0) {
            _mintAura(_contributorNode, uint256(_impactScore));
        } else if (_impactScore < 0) {
            _burnAura(_contributorNode, uint256(_impactScore * -1)); // Convert negative to positive for subtraction
        }

        emit ImpactScoreUpdated(_sphereId, _contributorNode, _impactScore);
    }

    /**
     * @dev Allows the contract owner to set the address of the trusted oracle
     *      (e.g., Chainlink VRF Coordinator or custom AI oracle).
     * @param _oracle The address of the new oracle.
     */
    function setAuraCastingOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "AuraForge: Oracle address cannot be zero.");
        auraCastingOracle = _oracle;
        emit AuraCastingOracleAddressSet(_oracle);
    }

    // --- VI. Governance & System Parameters ---

    /**
     * @dev Allows the contract owner to set a fee (e.g., in native token) required
     *      for `verifyContribution` to prevent spam or fund operations.
     * @param _fee The new verification fee in Wei.
     */
    function setVerificationFee(uint256 _fee) external onlyOwner {
        verificationFee = _fee;
        emit VerificationFeeSet(_fee);
    }

    /**
     * @dev Initiates a governance proposal to change a system-wide parameter.
     *      This is a placeholder for a more complex DAO-like voting system where
     *      only AuraNode holders with a minimum Aura score could propose.
     * @param _paramHash A hash representing the parameter to change (e.g., keccak256("BASE_AURA_FOR_VERIFIED_CONTRIBUTION")).
     * @param _newValue The proposed new value for the parameter.
     */
    function proposeAuraParameterChange(bytes32 _paramHash, uint256 _newValue) external onlyAuraNodeOwner(msg.sender) {
        // Simple check to prevent duplicate proposals for the exact same parameter hash.
        // In a real system, you might allow re-proposing after a period or if previous failed.
        require(proposals[_paramHash].creationTime == 0 || proposals[_paramHash].executed, "AuraForge: Proposal for this parameter already exists or is active.");
        
        proposals[_paramHash] = Proposal({
            paramHash: _paramHash,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            // hasVoted mapping is initialized per-struct
            executed: false,
            creationTime: block.timestamp,
            expirationTime: block.timestamp.add(MIN_VOTING_PERIOD)
        });
        activeProposals.push(_paramHash); // Add to list of active proposals
        
        emit GovernanceProposalCreated(_paramHash, _newValue, proposals[_paramHash].expirationTime);
    }

    /**
     * @dev Allows registered AuraNode holders to vote on active governance proposals.
     *      Voting weight is based on their current Aura score.
     * @param _paramHash The hash of the parameter proposal.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnAuraParameterChange(bytes32 _paramHash, bool _approve) external onlyAuraNodeOwner(msg.sender) {
        Proposal storage proposal = proposals[_paramHash];
        require(proposal.creationTime != 0, "AuraForge: Proposal does not exist.");
        require(block.timestamp < proposal.expirationTime, "AuraForge: Voting period has ended for this proposal.");
        require(!proposal.executed, "AuraForge: Proposal already executed.");
        require(!proposal.hasVoted[msg.sender], "AuraForge: You have already voted on this proposal.");

        uint256 voterAura = getAuraScore(msg.sender);
        require(voterAura > 0, "AuraForge: Voter must have an Aura score to vote.");

        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(voterAura);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterAura);
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(_paramHash, msg.sender, _approve);
    }

    /**
     * @dev Executes a governance proposal if it meets quorum and approval thresholds.
     *      This function can be called by anyone after the voting period ends.
     *      Quorum is simplified here: requiring total votes > 0 and majority approval.
     *      A more robust system would calculate total Aura supply for true quorum percentage.
     * @param _paramHash The hash of the parameter proposal to execute.
     */
    function executeAuraParameterChange(bytes32 _paramHash) external nonReentrant {
        Proposal storage proposal = proposals[_paramHash];
        require(proposal.creationTime != 0, "AuraForge: Proposal does not exist.");
        require(block.timestamp >= proposal.expirationTime, "AuraForge: Voting period has not ended yet.");
        require(!proposal.executed, "AuraForge: Proposal already executed.");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "AuraForge: No votes cast for this proposal."); // Basic quorum: at least one vote
        
        // Check for majority approval
        require(proposal.votesFor > proposal.votesAgainst, "AuraForge: Proposal did not pass majority vote.");
        
        // Execute the change based on the parameter hash
        if (_paramHash == keccak256(abi.encodePacked("BASE_AURA_FOR_VERIFIED_CONTRIBUTION"))) {
            BASE_AURA_FOR_VERIFIED_CONTRIBUTION = proposal.newValue;
        } else if (_paramHash == keccak256(abi.encodePacked("VERIFICATION_FEE"))) {
            verificationFee = proposal.newValue;
        } 
        else {
             revert("AuraForge: Unknown or unsupported parameter hash for execution.");
        }

        proposal.executed = true;
        
        // Remove from activeProposals array (simple iteration, can be optimized for large arrays)
        for (uint i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == _paramHash) {
                activeProposals[i] = activeProposals[activeProposals.length - 1]; // Move last element to current position
                activeProposals.pop(); // Remove last element
                break;
            }
        }

        emit GovernanceProposalExecuted(_paramHash);
    }

    // --- View Functions (Additional) ---

    /**
     * @dev Retrieves the current metadata URI for a given AuraNode.
     * @param _auraNodeOwner The address of the AuraNode owner.
     * @return The metadata URI.
     */
    function getAuraNodeMetadataURI(address _auraNodeOwner) external view returns (string memory) {
        uint256 tokenId = _auraNodeOf[_auraNodeOwner];
        require(tokenId > 0, "AuraForge: AuraNode does not exist for this address.");
        return _auraNodeMetadataURIs[tokenId];
    }

    /**
     * @dev Retrieves the current metadata URI for a given ContributionSphere.
     * @param _sphereId The ID of the Sphere.
     * @return The metadata URI.
     */
    function getContributionSphereMetadataURI(uint256 _sphereId) external view returns (string memory) {
        require(_sphereTokenIds.current() >= _sphereId && _sphereId > 0, "AuraForge: Invalid Sphere ID.");
        return _sphereMetadataURIs[_sphereId];
    }

    /**
     * @dev Retrieves the details of a specific AuraLink between a Sphere and a contributor.
     * @param _sphereId The ID of the Sphere.
     * @param _contributorNode The address of the contributor.
     * @return AuraLink struct containing details.
     */
    function getAuraLinkDetails(uint256 _sphereId, address _contributorNode) external view returns (AuraLink memory) {
        bytes32 linkKey = keccak256(abi.encodePacked(_sphereId, _contributorNode));
        require(_auraLinks[linkKey].exists, "AuraForge: AuraLink does not exist.");
        return _auraLinks[linkKey];
    }

    /**
     * @dev Returns the current verification fee.
     */
    function getVerificationFee() external view returns (uint256) {
        return verificationFee;
    }

    /**
     * @dev Returns the current value of BASE_AURA_FOR_VERIFIED_CONTRIBUTION.
     */
    function getBaseAuraForVerifiedContribution() external view returns (uint256) {
        return BASE_AURA_FOR_VERIFIED_CONTRIBUTION;
    }

    /**
     * @dev Returns the current total share basis points for revenue distribution for a specific sphere.
     * @param _sphereId The ID of the Sphere.
     */
    function getSphereRevenueShareBasis(uint256 _sphereId) external view returns (uint256) {
        return _sphereRevenueShareBasis[_sphereId];
    }

    /**
     * @dev Returns the pending revenue in Wei for a contributor in a specific sphere.
     * @param _sphereId The ID of the Sphere.
     * @param _contributor The address of the contributor.
     */
    function getPendingRevenueClaim(uint256 _sphereId, address _contributor) external view returns (uint256) {
        return _pendingRevenueClaims[_sphereId][_contributor];
    }

    /**
     * @dev Returns the details of a governance proposal.
     * @param _paramHash The hash of the proposal.
     */
    function getProposalDetails(bytes32 _paramHash) external view returns (bytes32 paramHash, uint256 newValue, uint256 votesFor, uint256 votesAgainst, bool executed, uint256 creationTime, uint256 expirationTime) {
        Proposal storage p = proposals[_paramHash];
        require(p.creationTime != 0, "AuraForge: Proposal does not exist.");
        return (p.paramHash, p.newValue, p.votesFor, p.votesAgainst, p.executed, p.creationTime, p.expirationTime);
    }

    /**
     * @dev Returns the list of currently active governance proposals.
     */
    function getActiveProposals() external view returns (bytes32[] memory) {
        return activeProposals;
    }
}
```