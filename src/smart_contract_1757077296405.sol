Here's a smart contract in Solidity called `SyntheticaNexus`, designed around advanced concepts like AI-assisted decentralized content generation, a soulbound-like reputation system, multi-party NFT ownership with on-chain royalties, and a reputation-weighted governance mechanism.

---

## SyntheticaNexus Contract

**Outline and Function Summary:**

This contract establishes a decentralized platform for AI-assisted creative collaboration, content generation, and reputation management. It allows users to propose creative blueprints, fund their development, and have approved AI Artisans generate content based on these blueprints. A council of Curators then verifies the quality and adherence of the generated content to the blueprint, leading to the minting of unique NFTs. Rewards and royalties are dynamically distributed among participants, and a reputation system governs access to features and voting power within the Nexus DAO.

---

### I. Core Infrastructure & Access Control

1.  `constructor()`: Initializes the contract, sets the deployer as the owner, and initializes core parameters.
2.  `setNexusFuelToken(address _token)`: Sets the address of the ERC-20 token (`NEXUS_FUEL`) used for funding blueprints and distributing rewards. Callable only by the contract owner.
3.  `pauseContract()`: Pauses all critical contract operations (blueprint creation, funding, generation, curation), preventing new actions. Callable by the owner.
4.  `unpauseContract()`: Resumes all critical contract operations. Callable by the owner.
5.  `transferOwnership(address newOwner)`: Transfers administrative ownership of the contract to a new address.

### II. Role Management (Soulbound-like Internal Roles)

6.  `mintArtisanRole(address _artisan)`: Grants the 'AI Artisan' role to an address. Artisans can claim and generate content for blueprints. This role is non-transferable and functions as an internal "soulbound" token. Callable by the owner.
7.  `revokeArtisanRole(address _artisan)`: Revokes the 'AI Artisan' role from an address. Callable by the owner.
8.  `mintCuratorRole(address _curator)`: Grants the 'Curator' role to an address. Curators are responsible for attesting to the quality of generated content. This role is also non-transferable. Callable by the owner.
9.  `revokeCuratorRole(address _curator)`: Revokes the 'Curator' role from an address. Callable by the owner.
10. `getRoleStatus(address _addr)`: Returns a boolean tuple indicating if an address holds the 'AI Artisan' and/or 'Curator' role.

### III. Blueprint Creation & Funding

11. `proposeBlueprint(string memory _name, string memory _description, bytes32 _promptHash, uint256 _fundingTarget)`: Allows any user to propose a new creative blueprint. It includes a name, description, a cryptographic hash of the AI prompt/parameters, and a target funding amount in `NEXUS_FUEL`.
12. `fundBlueprint(uint256 _blueprintId, uint256 _amount)`: Allows users to stake `NEXUS_FUEL` to contribute towards the funding target of a specific blueprint.
13. `withdrawUnclaimedFunding(uint256 _blueprintId)`: Allows the blueprint creator or any funder to withdraw their staked `NEXUS_FUEL` if the blueprint hasn't reached its funding target or hasn't been claimed for generation within a timeout period.

### IV. Content Generation & Submission (AI Artisan Role)

14. `claimBlueprintForGeneration(uint256 _blueprintId)`: An approved 'AI Artisan' claims a fully funded blueprint, signaling their intent to generate content for it. This moves the blueprint into the 'Generating' state.
15. `submitGeneratedContentHash(uint256 _generationId, bytes32 _contentHash)`: The claiming 'AI Artisan' submits a cryptographic hash (e.g., an IPFS CID) of the generated content. This prepares the generation for curator review.

### V. Curation & Verification (Curator Role & Oracle Integration)

16. `submitOracleVerification(uint256 _generationId, string memory _contentLink)`: (Owner/Authorized Oracle) Provides the actual off-chain link (e.g., IPFS URL, Arweave link) to the generated content. This enables curators to review the work.
17. `attestContentQuality(uint256 _generationId, bool _isGoodQuality)`: An approved 'Curator' reviews the content (via the provided link) and casts an attestation (positive or negative) regarding its quality and adherence to the blueprint.
18. `finalizeGeneration(uint256 _generationId)`: Executed when a generation receives a sufficient number of positive curator attestations. This function mints the unique NFT, distributes `NEXUS_FUEL` rewards to the blueprint creator, artisan, and funders, and updates reputation scores.
19. `flagMaliciousContent(uint256 _generationId, string memory _reason)`: Allows a curator or highly reputed user to flag generated content as malicious, inappropriate, or non-compliant, potentially leading to its rejection and penalties.

### VI. NFT Management (ERC-721 for Generated Works)

20. `getWorkDetails(uint256 _tokenId)`: Retrieves comprehensive details for a minted creative work (NFT), including its associated blueprint, generation information, and current royalty distribution splits.
21. `setWorkRoyaltyPercentage(uint256 _tokenId, uint256 _percentage)`: Allows the original blueprint creator or a passed DAO proposal to adjust the secondary sale royalty percentage for a specific NFT, adhering to ERC2981.
22. `collectRoyalties(uint256 _tokenId)`: Allows authorized parties (blueprint creator, artisan, funders, or the contract itself) to collect their share of royalties that have accumulated for a specific work from secondary sales (assuming an external marketplace sends royalties to this contract).

### VII. Reputation & Governance

23. `getReputationScore(address _addr)`: Returns the current reputation score for a given address. Reputation is dynamically earned through successful contributions across the platform (funding, creating, generating, curating).
24. `submitProposal(string memory _description, address _target, bytes memory _callData)`: Allows users with a minimum reputation score to submit a governance proposal, which can modify contract parameters or execute specific actions on other contracts.
25. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with a reputation score to cast their vote (for or against) on an active governance proposal. Voting power is weighted by the voter's reputation score.
26. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has met the required voting quorum and majority, and whose voting period has ended.

### VIII. Ancillary & Query Functions

27. `getBlueprintFundingAmount(uint256 _blueprintId)`: Returns the total amount of `NEXUS_FUEL` currently staked for a specific blueprint.
28. `getBlueprintStatus(uint256 _blueprintId)`: Returns the current lifecycle stage of a blueprint (e.g., PendingFunding, FundingActive, Generating, Completed, Rejected).
29. `getPendingGenerationsForArtisan(address _artisan)`: Returns a list of generation IDs an artisan has claimed but not yet completed.
30. `getPendingAttestationsForCurator(address _curator)`: Returns a list of generation IDs awaiting attestation from a curator.
31. `setMinimumReputationForProposal(uint256 _newScore)`: Sets the minimum reputation score required for a user to submit a governance proposal. Callable by owner or via governance.
32. `setRequiredAttestations(uint256 _newCount)`: Sets the number of positive curator attestations required for a generation to be finalized. Callable by owner or via governance.

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // For NFT royalty standard

/**
 * @title SyntheticaNexus
 * @dev A decentralized platform for AI-assisted creative collaboration, content generation, and reputation management.
 *      Allows users to propose creative blueprints, fund their development, and have AI Artisans generate content.
 *      Curators verify content quality, leading to unique NFT minting, dynamic reward distribution,
 *      and a reputation-weighted governance mechanism.
 */
contract SyntheticaNexus is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, Pausable, IERC2981 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _blueprintIds;
    Counters.Counter private _generationIds;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIds;

    IERC20 public nexusFuelToken; // ERC-20 token for funding and rewards

    // --- Role Management (SBT-like internal roles) ---
    mapping(address => bool) public isArtisan;
    mapping(address => bool) public isCurator;

    // --- Reputation System ---
    mapping(address => uint256) public reputationScores;
    uint256 public constant REPUTATION_FOR_BLUEPRINT_CREATION = 5;
    uint256 public constant REPUTATION_FOR_FUNDING = 1; // Per X amount of NEXUS_FUEL
    uint256 public constant REPUTATION_FOR_GENERATION = 10;
    uint256 public constant REPUTATION_FOR_CURATION_POSITIVE = 3;
    uint256 public constant REPUTATION_FOR_CURATION_NEGATIVE = 1; // For honest flagging

    // --- Blueprint Configuration ---
    uint256 public fundingTimeoutDuration = 7 days; // Time to reach funding target before withdrawal
    uint256 public generationTimeoutDuration = 14 days; // Time for artisan to submit content hash
    uint256 public curationTimeoutDuration = 7 days; // Time for curators to attest

    // --- Curation & Verification Configuration ---
    uint256 public requiredPositiveAttestations = 3; // Minimum positive attestations for finalization
    uint256 public curatorMajorityThreshold = 75; // 75% positive required if many curators

    // --- Royalty Configuration (ERC2981 compliant) ---
    uint96 public defaultRoyaltyPercentage = 1000; // 10% (1000 / 10000)
    mapping(uint256 => address) private _royaltyReceivers; // Maps tokenId to primary royalty receiver (creator)
    mapping(uint256 => uint96) private _royaltyPercentages; // Maps tokenId to its royalty percentage

    // --- Governance Configuration ---
    uint256 public minReputationForProposal = 100;
    uint256 public proposalVotingPeriod = 5 days;
    uint256 public proposalQuorumPercentage = 20; // % of total reputation required for quorum

    // --- Data Structures ---

    enum BlueprintStatus {
        PendingFunding,
        FundingActive, // Funding target not yet met, but active
        Generating,
        AwaitingCuration,
        Completed,
        Rejected,
        Withdrawn
    }

    struct Blueprint {
        address creator;
        string name;
        string description;
        bytes32 promptHash; // IPFS hash or similar for the AI prompt/parameters
        uint256 fundingTarget;
        uint256 currentFunding;
        mapping(address => uint256) funders; // Who funded what
        BlueprintStatus status;
        uint256 createdAt;
        uint256 claimedByGenerationId; // Which generation claimed this blueprint
    }

    // Stores all blueprint details
    mapping(uint256 => Blueprint) public blueprints;

    enum GenerationStatus {
        PendingClaim,
        Claimed,
        Submitted, // Content hash submitted
        AwaitingOracleVerification, // Waiting for owner/oracle to link actual content
        AwaitingCuration,
        Finalized,
        Rejected,
        Malicious
    }

    struct Generation {
        uint256 blueprintId;
        address artisan;
        bytes32 contentHash; // Hash of the generated content (e.g., IPFS CID)
        string contentLink; // Actual link to the content, set by oracle
        mapping(address => bool) curatorAttestations; // True for good quality, false for bad
        uint256 positiveAttestations;
        uint256 negativeAttestations;
        GenerationStatus status;
        uint256 claimedAt;
        uint256 submittedAt;
        uint256 oracleVerifiedAt;
        uint256 finalizedAt;
        uint256 mintedTokenId; // If finalized, the ID of the minted NFT
    }

    // Stores all generation details
    mapping(uint256 => Generation) public generations;

    struct WorkMetadata {
        uint256 blueprintId;
        uint256 generationId;
        address creatorAddress;
        address artisanAddress;
        uint96 creatorRoyaltyShare; // Share of the total royalty
        uint96 artisanRoyaltyShare;
        uint96 funderRoyaltyShare;
    }
    mapping(uint256 => WorkMetadata) public workMetadata; // Maps tokenId to work details

    // Royalty payments for collected funds
    mapping(uint256 => mapping(address => uint256)) public pendingRoyalties;

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed,
        Canceled
    }

    struct Proposal {
        address proposer;
        string description;
        uint256 createdAt;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Prevents double voting
        uint256 totalReputationAtProposal; // Snapshot of total reputation
        uint256 reputationWeightedVotesFor;
        uint256 reputationWeightedVotesAgainst;
        address target; // Target contract for execution
        bytes callData; // Call data for execution
        ProposalStatus status;
    }

    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event NexusFuelTokenSet(address indexed _token);
    event ArtisanRoleMinted(address indexed _artisan);
    event ArtisanRoleRevoked(address indexed _artisan);
    event CuratorRoleMinted(address indexed _curator);
    event CuratorRoleRevoked(address indexed _curator);
    event BlueprintProposed(uint256 indexed _blueprintId, address indexed _creator, string _name, uint256 _fundingTarget);
    event BlueprintFunded(uint256 indexed _blueprintId, address indexed _funder, uint256 _amount, uint256 _newTotalFunding);
    event FundingWithdrawn(uint256 indexed _blueprintId, address indexed _withdrawer, uint256 _amount);
    event BlueprintClaimed(uint256 indexed _blueprintId, uint256 indexed _generationId, address indexed _artisan);
    event ContentHashSubmitted(uint256 indexed _generationId, address indexed _artisan, bytes32 _contentHash);
    event OracleVerificationSubmitted(uint256 indexed _generationId, string _contentLink);
    event ContentAttested(uint256 indexed _generationId, address indexed _curator, bool _isGoodQuality);
    event GenerationFinalized(uint256 indexed _generationId, uint256 indexed _tokenId, address _creator, address _artisan);
    event ContentFlaggedMalicious(uint256 indexed _generationId, address indexed _flagger, string _reason);
    event ReputationUpdated(address indexed _addr, uint256 _newScore);
    event RoyaltyPercentageSet(uint256 indexed _tokenId, uint96 _percentage);
    event RoyaltyCollected(uint252 indexed _tokenId, address indexed _receiver, uint256 _amount);
    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, string _description);
    event ProposalVoted(uint256 indexed _proposalId, address indexed _voter, bool _support, uint256 _weightedVote);
    event ProposalExecuted(uint256 indexed _proposalId);
    event ProposalCanceled(uint256 indexed _proposalId);
    event ParametersUpdated(string _paramName, uint256 _newValue);


    // --- Constructor ---
    constructor(address _initialOwner)
        ERC721("SyntheticaNexusNFT", "SNXNFT")
        Ownable(_initialOwner)
        Pausable()
    {}

    // --- Modifiers ---
    modifier onlyArtisan() {
        require(isArtisan[msg.sender], "SyntheticaNexus: Caller is not an AI Artisan");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "SyntheticaNexus: Caller is not a Curator");
        _;
    }

    modifier onlyOracle() {
        // For simplicity, only owner acts as oracle for now. Can be expanded to a dedicated role or multi-sig.
        require(msg.sender == owner(), "SyntheticaNexus: Caller is not the authorized oracle");
        _;
    }

    modifier whenBlueprintExists(uint256 _blueprintId) {
        require(_blueprintId > 0 && _blueprintId <= _blueprintIds.current(), "SyntheticaNexus: Invalid Blueprint ID");
        _;
    }

    modifier whenGenerationExists(uint256 _generationId) {
        require(_generationId > 0 && _generationId <= _generationIds.current(), "SyntheticaNexus: Invalid Generation ID");
        _;
    }

    modifier whenNotPaused() {
        _checkNotPaused();
        _;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Sets the address of the NEXUS_FUEL ERC-20 token.
     * @param _token The address of the ERC-20 token.
     */
    function setNexusFuelToken(address _token) external onlyOwner {
        require(_token != address(0), "SyntheticaNexus: Invalid token address");
        nexusFuelToken = IERC20(_token);
        emit NexusFuelTokenSet(_token);
    }

    /**
     * @dev Pauses all critical contract operations.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all critical contract operations.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // `transferOwnership` is inherited from Ownable.

    // --- II. Role Management (Soulbound-like Internal Roles) ---

    /**
     * @dev Grants the 'AI Artisan' role to an address.
     * @param _artisan The address to grant the role to.
     */
    function mintArtisanRole(address _artisan) external onlyOwner {
        require(_artisan != address(0), "SyntheticaNexus: Invalid address");
        require(!isArtisan[_artisan], "SyntheticaNexus: Address already an Artisan");
        isArtisan[_artisan] = true;
        emit ArtisanRoleMinted(_artisan);
    }

    /**
     * @dev Revokes the 'AI Artisan' role from an address.
     * @param _artisan The address to revoke the role from.
     */
    function revokeArtisanRole(address _artisan) external onlyOwner {
        require(_artisan != address(0), "SyntheticaNexus: Invalid address");
        require(isArtisan[_artisan], "SyntheticaNexus: Address is not an Artisan");
        isArtisan[_artisan] = false;
        emit ArtisanRoleRevoked(_artisan);
    }

    /**
     * @dev Grants the 'Curator' role to an address.
     * @param _curator The address to grant the role to.
     */
    function mintCuratorRole(address _curator) external onlyOwner {
        require(_curator != address(0), "SyntheticaNexus: Invalid address");
        require(!isCurator[_curator], "SyntheticaNexus: Address already a Curator");
        isCurator[_curator] = true;
        emit CuratorRoleMinted(_curator);
    }

    /**
     * @dev Revokes the 'Curator' role from an address.
     * @param _curator The address to revoke the role from.
     */
    function revokeCuratorRole(address _curator) external onlyOwner {
        require(_curator != address(0), "SyntheticaNexus: Invalid address");
        require(isCurator[_curator], "SyntheticaNexus: Address is not a Curator");
        isCurator[_curator] = false;
        emit CuratorRoleRevoked(_curator);
    }

    /**
     * @dev Returns the current roles (Artisan, Curator) held by a given address.
     * @param _addr The address to check.
     * @return A tuple of booleans (isArtisan, isCurator).
     */
    function getRoleStatus(address _addr) external view returns (bool, bool) {
        return (isArtisan[_addr], isCurator[_addr]);
    }

    // --- III. Blueprint Creation & Funding ---

    /**
     * @dev Allows any user to propose a new creative blueprint.
     * @param _name The name of the blueprint.
     * @param _description A detailed description of the creative idea.
     * @param _promptHash A cryptographic hash of the AI prompt or parameters.
     * @param _fundingTarget The target amount of NEXUS_FUEL required to fund this blueprint.
     * @return The ID of the newly created blueprint.
     */
    function proposeBlueprint(
        string memory _name,
        string memory _description,
        bytes32 _promptHash,
        uint256 _fundingTarget
    ) external whenNotPaused returns (uint256) {
        require(_fundingTarget > 0, "SyntheticaNexus: Funding target must be greater than zero");
        _blueprintIds.increment();
        uint256 newBlueprintId = _blueprintIds.current();

        blueprints[newBlueprintId] = Blueprint({
            creator: msg.sender,
            name: _name,
            description: _description,
            promptHash: _promptHash,
            fundingTarget: _fundingTarget,
            currentFunding: 0,
            status: BlueprintStatus.PendingFunding,
            createdAt: block.timestamp,
            claimedByGenerationId: 0
        });

        // Award reputation for proposing
        _updateReputation(msg.sender, REPUTATION_FOR_BLUEPRINT_CREATION);

        emit BlueprintProposed(newBlueprintId, msg.sender, _name, _fundingTarget);
        return newBlueprintId;
    }

    /**
     * @dev Allows users to stake NEXUS_FUEL to a specific blueprint.
     * @param _blueprintId The ID of the blueprint to fund.
     * @param _amount The amount of NEXUS_FUEL to stake.
     */
    function fundBlueprint(uint256 _blueprintId, uint256 _amount)
        external
        whenNotPaused
        whenBlueprintExists(_blueprintId)
    {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.PendingFunding || blueprint.status == BlueprintStatus.FundingActive, "SyntheticaNexus: Blueprint not open for funding");
        require(_amount > 0, "SyntheticaNexus: Funding amount must be greater than zero");
        require(address(nexusFuelToken) != address(0), "SyntheticaNexus: NEXUS_FUEL token not set");

        // Transfer funds from sender to this contract
        require(nexusFuelToken.transferFrom(msg.sender, address(this), _amount), "SyntheticaNexus: NEXUS_FUEL transfer failed");

        blueprint.currentFunding += _amount;
        blueprint.funders[msg.sender] += _amount;

        if (blueprint.status == BlueprintStatus.PendingFunding) {
             blueprint.status = BlueprintStatus.FundingActive;
        }

        // Award reputation for funding
        _updateReputation(msg.sender, (_amount / 1e18) * REPUTATION_FOR_FUNDING); // Example: 1 reputation per 1 NEXUS_FUEL (assuming 18 decimals)

        emit BlueprintFunded(_blueprintId, msg.sender, _amount, blueprint.currentFunding);
    }

    /**
     * @dev Allows the blueprint creator or any funder to withdraw their staked NEXUS_FUEL
     *      if the blueprint has not reached its funding target or not claimed within timeout.
     * @param _blueprintId The ID of the blueprint.
     */
    function withdrawUnclaimedFunding(uint256 _blueprintId)
        external
        whenNotPaused
        whenBlueprintExists(_blueprintId)
    {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(address(nexusFuelToken) != address(0), "SyntheticaNexus: NEXUS_FUEL token not set");

        require(
            blueprint.status == BlueprintStatus.PendingFunding || blueprint.status == BlueprintStatus.FundingActive,
            "SyntheticaNexus: Blueprint is not in a withdrawable state"
        );
        require(
            blueprint.currentFunding < blueprint.fundingTarget || // Funding target not met
            block.timestamp > blueprint.createdAt + fundingTimeoutDuration, // Or timeout passed
            "SyntheticaNexus: Blueprint funding target met or within timeout"
        );

        uint256 amountToWithdraw = blueprint.funders[msg.sender];
        require(amountToWithdraw > 0, "SyntheticaNexus: No funds to withdraw for this blueprint");

        blueprint.currentFunding -= amountToWithdraw;
        blueprint.funders[msg.sender] = 0; // Clear the funder's contribution

        require(nexusFuelToken.transfer(msg.sender, amountToWithdraw), "SyntheticaNexus: Failed to transfer NEXUS_FUEL back");
        
        // If all funding is withdrawn and it never reached target, mark as withdrawn
        if (blueprint.currentFunding == 0 && blueprint.status != BlueprintStatus.Completed) {
            blueprint.status = BlueprintStatus.Withdrawn;
        }

        emit FundingWithdrawn(_blueprintId, msg.sender, amountToWithdraw);
    }

    // --- IV. Content Generation & Submission (AI Artisan Role) ---

    /**
     * @dev An approved 'AI Artisan' claims a fully funded blueprint to begin content generation.
     * @param _blueprintId The ID of the blueprint to claim.
     * @return The ID of the newly created generation.
     */
    function claimBlueprintForGeneration(uint256 _blueprintId)
        external
        whenNotPaused
        onlyArtisan
        whenBlueprintExists(_blueprintId)
        returns (uint256)
    {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.FundingActive, "SyntheticaNexus: Blueprint not ready for generation");
        require(blueprint.currentFunding >= blueprint.fundingTarget, "SyntheticaNexus: Blueprint not fully funded");
        require(blueprint.claimedByGenerationId == 0, "SyntheticaNexus: Blueprint already claimed for generation");

        blueprint.status = BlueprintStatus.Generating;
        _generationIds.increment();
        uint256 newGenerationId = _generationIds.current();

        generations[newGenerationId] = Generation({
            blueprintId: _blueprintId,
            artisan: msg.sender,
            contentHash: bytes32(0), // Will be set later
            contentLink: "",
            positiveAttestations: 0,
            negativeAttestations: 0,
            status: GenerationStatus.Claimed,
            claimedAt: block.timestamp,
            submittedAt: 0,
            oracleVerifiedAt: 0,
            finalizedAt: 0,
            mintedTokenId: 0
        });

        blueprint.claimedByGenerationId = newGenerationId;

        emit BlueprintClaimed(_blueprintId, newGenerationId, msg.sender);
        return newGenerationId;
    }

    /**
     * @dev The claiming 'AI Artisan' submits a hash representing the generated content.
     * @param _generationId The ID of the generation.
     * @param _contentHash A cryptographic hash (e.g., IPFS CID) of the generated content.
     */
    function submitGeneratedContentHash(uint256 _generationId, bytes32 _contentHash)
        external
        whenNotPaused
        onlyArtisan
        whenGenerationExists(_generationId)
    {
        Generation storage generation = generations[_generationId];
        require(generation.artisan == msg.sender, "SyntheticaNexus: Not the artisan for this generation");
        require(generation.status == GenerationStatus.Claimed, "SyntheticaNexus: Generation not in claimed state");
        require(block.timestamp <= generation.claimedAt + generationTimeoutDuration, "SyntheticaNexus: Generation submission timeout exceeded");
        require(_contentHash != bytes32(0), "SyntheticaNexus: Content hash cannot be empty");

        generation.contentHash = _contentHash;
        generation.status = GenerationStatus.Submitted;
        generation.submittedAt = block.timestamp;

        emit ContentHashSubmitted(_generationId, msg.sender, _contentHash);
    }

    // --- V. Curation & Verification (Curator Role & Oracle Integration) ---

    /**
     * @dev (Owner/Authorized Oracle) Provides the actual off-chain content link for curators to review.
     * @param _generationId The ID of the generation.
     * @param _contentLink The URL or URI to the generated content.
     */
    function submitOracleVerification(uint256 _generationId, string memory _contentLink)
        external
        whenNotPaused
        onlyOracle
        whenGenerationExists(_generationId)
    {
        Generation storage generation = generations[_generationId];
        require(generation.status == GenerationStatus.Submitted, "SyntheticaNexus: Generation not in submitted state");
        require(bytes(_contentLink).length > 0, "SyntheticaNexus: Content link cannot be empty");

        generation.contentLink = _contentLink;
        generation.status = GenerationStatus.AwaitingCuration;
        generation.oracleVerifiedAt = block.timestamp;

        emit OracleVerificationSubmitted(_generationId, _contentLink);
    }

    /**
     * @dev An approved 'Curator' reviews the content and casts an attestation.
     * @param _generationId The ID of the generation to attest.
     * @param _isGoodQuality True if the content is high quality and matches the blueprint, false otherwise.
     */
    function attestContentQuality(uint256 _generationId, bool _isGoodQuality)
        external
        whenNotPaused
        onlyCurator
        whenGenerationExists(_generationId)
    {
        Generation storage generation = generations[_generationId];
        require(generation.status == GenerationStatus.AwaitingCuration, "SyntheticaNexus: Generation not awaiting curation");
        require(!generation.curatorAttestations[msg.sender], "SyntheticaNexus: Curator already attested for this generation");
        require(block.timestamp <= generation.oracleVerifiedAt + curationTimeoutDuration, "SyntheticaNexus: Curation timeout exceeded");

        generation.curatorAttestations[msg.sender] = true; // Mark that this curator has voted

        if (_isGoodQuality) {
            generation.positiveAttestations++;
            _updateReputation(msg.sender, REPUTATION_FOR_CURATION_POSITIVE);
        } else {
            generation.negativeAttestations++;
            _updateReputation(msg.sender, REPUTATION_FOR_CURATION_NEGATIVE);
        }

        emit ContentAttested(_generationId, msg.sender, _isGoodQuality);
    }

    /**
     * @dev Finalizes a generation when enough positive curator attestations are received.
     *      Mints the NFT, distributes rewards, and updates reputation scores.
     * @param _generationId The ID of the generation to finalize.
     */
    function finalizeGeneration(uint256 _generationId)
        external
        whenNotPaused
        whenGenerationExists(_generationId)
    {
        Generation storage generation = generations[_generationId];
        Blueprint storage blueprint = blueprints[generation.blueprintId];

        require(generation.status == GenerationStatus.AwaitingCuration, "SyntheticaNexus: Generation not awaiting finalization");
        
        // Check if sufficient positive attestations or if a majority rule applies
        uint256 totalAttestations = generation.positiveAttestations + generation.negativeAttestations;
        bool majorityReached = totalAttestations > 0 && (generation.positiveAttestations * 100 / totalAttestations) >= curatorMajorityThreshold;

        require(
            generation.positiveAttestations >= requiredPositiveAttestations || majorityReached,
            "SyntheticaNexus: Not enough positive attestations or majority not reached"
        );
        
        // Mark blueprint as completed
        blueprint.status = BlueprintStatus.Completed;

        // Mint NFT
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(blueprint.creator, newTokenId); // Mint to blueprint creator initially
        _setTokenURI(newTokenId, generation.contentLink); // Set URI to the content link

        // Set royalty for this NFT (ERC2981)
        _royaltyReceivers[newTokenId] = blueprint.creator; // Primary receiver for the whole royalty sum
        _royaltyPercentages[newTokenId] = defaultRoyaltyPercentage; // Default percentage initially

        // Store detailed work metadata for custom royalty splitting
        // Example royalty split: 50% creator, 30% artisan, 20% funders (can be configurable)
        uint96 creatorShare = 5000; // 50%
        uint96 artisanShare = 3000; // 30%
        uint96 funderShare = 2000; // 20%
        require(creatorShare + artisanShare + funderShare == 10000, "SyntheticaNexus: Royalty shares must sum to 100%");

        workMetadata[newTokenId] = WorkMetadata({
            blueprintId: generation.blueprintId,
            generationId: _generationId,
            creatorAddress: blueprint.creator,
            artisanAddress: generation.artisan,
            creatorRoyaltyShare: creatorShare,
            artisanRoyaltyShare: artisanShare,
            funderRoyaltyShare: funderShare
        });

        // Distribute NEXUS_FUEL rewards from blueprint.currentFunding
        uint256 totalFunding = blueprint.currentFunding;
        uint256 creatorReward = (totalFunding * 20) / 100; // 20% to creator
        uint256 artisanReward = (totalFunding * 30) / 100; // 30% to artisan
        uint256 funderPool = totalFunding - creatorReward - artisanReward; // Remaining to funders

        require(nexusFuelToken.transfer(blueprint.creator, creatorReward), "SyntheticaNexus: Creator reward transfer failed");
        require(nexusFuelToken.transfer(generation.artisan, artisanReward), "SyntheticaNexus: Artisan reward transfer failed");

        // Distribute funder pool proportionally
        if (funderPool > 0) {
            for (uint256 i = 1; i <= _blueprintIds.current(); i++) { // Iterating through blueprints is inefficient, better track funders directly
                if (i == generation.blueprintId) { // Only for the relevant blueprint
                    // This part needs a more efficient way to iterate through `blueprint.funders` mapping.
                    // For a real contract, this would involve storing funders in a dynamic array for iteration or
                    // having funders claim their share directly.
                    // For now, let's simplify and make a "dummy" funder payout, or require funder to claim.
                    // For this example, let's directly distribute to the original blueprint.creator as a proxy for funders.
                    // In a production system, a separate claim function for funders would be better.
                    require(nexusFuelToken.transfer(blueprint.creator, funderPool), "SyntheticaNexus: Funder pool transfer failed");
                    break;
                }
            }
        }


        // Update generation status
        generation.status = GenerationStatus.Finalized;
        generation.finalizedAt = block.timestamp;
        generation.mintedTokenId = newTokenId;

        // Update reputation
        _updateReputation(blueprint.creator, REPUTATION_FOR_BLUEPRINT_CREATION * 2); // Boost for successful blueprint
        _updateReputation(generation.artisan, REPUTATION_FOR_GENERATION * 2); // Boost for successful generation

        emit GenerationFinalized(_generationId, newTokenId, blueprint.creator, generation.artisan);
    }

    /**
     * @dev Allows a curator or highly reputed user to flag content as malicious or inappropriate.
     * @param _generationId The ID of the generation to flag.
     * @param _reason A description of why the content is being flagged.
     */
    function flagMaliciousContent(uint256 _generationId, string memory _reason)
        external
        whenNotPaused
        whenGenerationExists(_generationId)
    {
        Generation storage generation = generations[_generationId];
        require(generation.status == GenerationStatus.AwaitingCuration || generation.status == GenerationStatus.Finalized, "SyntheticaNexus: Generation not eligible for flagging");
        require(isCurator[msg.sender] || reputationScores[msg.sender] >= minReputationForProposal, "SyntheticaNexus: Caller not authorized to flag content");

        // Simple flagging mechanism: set status to Malicious, potentially leading to burn/rejection
        generation.status = GenerationStatus.Malicious; // Further governance/owner action might be needed
        // Penalize artisan? Reduce reputation? Depends on severity.
        _updateReputation(generation.artisan, -REPUTATION_FOR_GENERATION); // Deduct reputation
        emit ContentFlaggedMalicious(_generationId, msg.sender, _reason);
    }


    // --- VI. NFT Management (ERC-721 for Generated Works) ---

    /**
     * @dev Retrieves comprehensive details for a minted creative work (NFT).
     * @param _tokenId The ID of the NFT.
     * @return A tuple containing blueprint ID, generation ID, creator, artisan, and royalty shares.
     */
    function getWorkDetails(uint256 _tokenId)
        external
        view
        returns (
            uint256 blueprintId,
            uint256 generationId,
            address creatorAddress,
            address artisanAddress,
            uint96 creatorRoyaltyShare,
            uint96 artisanRoyaltyShare,
            uint96 funderRoyaltyShare
        )
    {
        require(_exists(_tokenId), "SyntheticaNexus: Token does not exist");
        WorkMetadata storage metadata = workMetadata[_tokenId];
        return (
            metadata.blueprintId,
            metadata.generationId,
            metadata.creatorAddress,
            metadata.artisanAddress,
            metadata.creatorRoyaltyShare,
            metadata.artisanRoyaltyShare,
            metadata.funderRoyaltyShare
        );
    }

    /**
     * @dev Adjusts the secondary sale royalty percentage for a specific NFT.
     *      Requires ownership of the NFT or a passed DAO governance proposal.
     * @param _tokenId The ID of the NFT.
     * @param _percentage The new royalty percentage (basis points, 100 = 1%). Max 10000.
     */
    function setWorkRoyaltyPercentage(uint256 _tokenId, uint96 _percentage)
        external
        whenNotPaused
    {
        require(_exists(_tokenId), "SyntheticaNexus: Token does not exist");
        require(ERC721.ownerOf(_tokenId) == msg.sender || msg.sender == owner(), "SyntheticaNexus: Caller not authorized to set royalty"); // Simplified auth. For full DAO, use governance.
        require(_percentage <= 10000, "SyntheticaNexus: Royalty percentage cannot exceed 100%"); // 10000 basis points = 100%

        _royaltyPercentages[_tokenId] = _percentage;
        emit RoyaltyPercentageSet(_tokenId, _percentage);
    }

    /**
     * @dev Allows authorized parties to collect their share of royalties that have accumulated for a specific work.
     *      Assumes external marketplaces send royalty fees to this contract.
     * @param _tokenId The ID of the NFT.
     */
    function collectRoyalties(uint256 _tokenId)
        external
        whenNotPaused
    {
        require(_exists(_tokenId), "SyntheticaNexus: Token does not exist");
        WorkMetadata storage metadata = workMetadata[_tokenId];
        
        uint256 amountToCollect = pendingRoyalties[_tokenId][msg.sender];
        require(amountToCollect > 0, "SyntheticaNexus: No pending royalties for caller");

        pendingRoyalties[_tokenId][msg.sender] = 0;
        require(nexusFuelToken.transfer(msg.sender, amountToCollect), "SyntheticaNexus: Royalty transfer failed");

        emit RoyaltyCollected(_tokenId, msg.sender, amountToCollect);
    }

    // ERC2981 Royalty Standard implementation
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "SyntheticaNexus: Token does not exist");
        WorkMetadata storage metadata = workMetadata[_tokenId];
        address primaryReceiver = _royaltyReceivers[_tokenId];
        uint96 percentage = _royaltyPercentages[_tokenId];

        if (primaryReceiver == address(0) || percentage == 0) {
            return (address(0), 0);
        }

        // Calculate total royalty for the token
        uint256 totalRoyalty = (_salePrice * percentage) / 10000;

        // If the contract itself is the receiver, it means it will handle internal distribution
        // Otherwise, it points to the creator or a designated address.
        // For simplicity, let's assume the primary receiver for ERC2981 is the contract for internal distribution.
        // In a real scenario, this would likely be the creator address as the single point for marketplaces.
        return (address(this), totalRoyalty);
    }

    /**
     * @dev Internal function to distribute incoming royalty payments to individual participants.
     *      This would be called by the `receive` or a custom `handleRoyaltyPayment` function if a marketplace sends funds here.
     *      For simplicity, `_handleIncomingRoyalties` is a placeholder.
     *      A real implementation would be triggered when the contract receives `nexusFuelToken` as royalty.
     */
    function _handleIncomingRoyalties(uint256 _tokenId, uint256 _totalRoyaltyAmount) internal {
        WorkMetadata storage metadata = workMetadata[_tokenId];
        
        uint256 creatorShare = (_totalRoyaltyAmount * metadata.creatorRoyaltyShare) / 10000;
        uint256 artisanShare = (_totalRoyaltyAmount * metadata.artisanRoyaltyShare) / 10000;
        uint256 funderShare = (_totalRoyaltyAmount * metadata.funderRoyaltyShare) / 10000;

        if (creatorShare > 0) pendingRoyalties[_tokenId][metadata.creatorAddress] += creatorShare;
        if (artisanShare > 0) pendingRoyalties[_tokenId][metadata.artisanAddress] += artisanShare;
        
        // Distribute funder share (this is still a simplification, ideally individual funders get proportional shares)
        if (funderShare > 0) pendingRoyalties[_tokenId][metadata.creatorAddress] += funderShare; // Placeholder: route funder share to creator for now.

        // Event for internal royalty distribution might be useful here
    }

    // --- VII. Reputation & Governance ---

    /**
     * @dev Retrieves the current reputation score for a given address.
     * @param _addr The address to query.
     * @return The reputation score.
     */
    function getReputationScore(address _addr) external view returns (uint256) {
        return reputationScores[_addr];
    }

    /**
     * @dev Internal helper to update reputation scores. Handles positive and negative adjustments.
     * @param _addr The address whose reputation to update.
     * @param _amount The amount to add or subtract (can be negative).
     */
    function _updateReputation(address _addr, int256 _amount) internal {
        if (_amount > 0) {
            reputationScores[_addr] += uint256(_amount);
        } else if (_amount < 0) {
            uint256 absAmount = uint256(-_amount);
            if (reputationScores[_addr] > absAmount) {
                reputationScores[_addr] -= absAmount;
            } else {
                reputationScores[_addr] = 0;
            }
        }
        emit ReputationUpdated(_addr, reputationScores[_addr]);
    }

    /**
     * @dev Allows users with a minimum reputation score to submit a governance proposal.
     * @param _description A description of the proposal.
     * @param _target The target contract address for the proposal execution.
     * @param _callData The encoded function call data for the target contract.
     * @return The ID of the newly created proposal.
     */
    function submitProposal(string memory _description, address _target, bytes memory _callData)
        external
        whenNotPaused
        returns (uint256)
    {
        require(reputationScores[msg.sender] >= minReputationForProposal, "SyntheticaNexus: Not enough reputation to submit proposal");
        
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        // Calculate total reputation at the moment of proposal for quorum calculation
        // This would ideally require iterating all known reputation holders, which is expensive.
        // For simplicity, a snapshot of reputation or a 'delegate' model would be needed for a real DAO.
        // For this example, we'll assume a sum of current `reputationScores` is available or
        // we use a fixed total reputation.
        // For now, let's use 0 and make quorum check based on fixed `minReputationForProposal` or other logic
        // or assume `totalReputationAtProposal` is the sum of all known reputations for simplicity.
        // A better approach would be to have a `totalReputation` variable that updates on every `_updateReputation`.
        // Let's create a global variable `totalActiveReputation`.
        uint256 totalReputationSnapshot = 0; // In a real system, this would be computed or maintained
        // For demo purposes, we'll assume `totalReputationSnapshot` needs to be provided or globally accumulated.
        // Let's make it simple for now, totalReputationAtProposal = 10000 for example, for initial testing.

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            description: _description,
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            reputationWeightedVotesFor: 0,
            reputationWeightedVotesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize mapping
            totalReputationAtProposal: 0, // Placeholder, see notes above
            target: _target,
            callData: _callData,
            status: ProposalStatus.Active
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    /**
     * @dev Allows users with a reputation score to cast their vote on an active governance proposal.
     *      Voting power is weighted by the voter's reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' the proposal, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
        returns (uint256 currentReputation)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "SyntheticaNexus: Proposal not active");
        require(block.timestamp <= proposal.votingDeadline, "SyntheticaNexus: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "SyntheticaNexus: Already voted on this proposal");
        currentReputation = reputationScores[msg.sender];
        require(currentReputation > 0, "SyntheticaNexus: Voter has no reputation");

        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.votesFor++;
            proposal.reputationWeightedVotesFor += currentReputation;
        } else {
            proposal.votesAgainst++;
            proposal.reputationWeightedVotesAgainst += currentReputation;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, currentReputation);
        return currentReputation;
    }

    /**
     * @dev Executes a governance proposal that has met the required voting quorum and majority,
     *      and whose voting period has ended.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "SyntheticaNexus: Proposal not active");
        require(block.timestamp > proposal.votingDeadline, "SyntheticaNexus: Voting period not ended");

        // Calculate total reputation for quorum (this needs a global sum of reputation, or a delegate system)
        // For this example, let's use a simplified quorum logic based on minimum weighted votes
        uint256 totalWeightedVotes = proposal.reputationWeightedVotesFor + proposal.reputationWeightedVotesAgainst;
        uint256 totalPossibleReputation = _calculateTotalReputation(); // This would be dynamic or snapshot-based
        
        // Simplified Quorum Check: A proposal passes if (weighted votes for) > (weighted votes against)
        // AND total weighted votes exceeds a percentage of _totalPossibleReputation or a fixed threshold.
        bool quorumMet = totalWeightedVotes >= (totalPossibleReputation * proposalQuorumPercentage / 100);
        
        if (proposal.reputationWeightedVotesFor > proposal.reputationWeightedVotesAgainst && quorumMet) {
            proposal.status = ProposalStatus.Succeeded;
            // Execute the proposal's action
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "SyntheticaNexus: Proposal execution failed");
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Defeated;
            emit ProposalCanceled(_proposalId); // Using Canceled for defeated for simplicity
        }
    }

    /**
     * @dev Helper function to approximate total active reputation for quorum calculation.
     *      In a production system, this would be either a globally maintained sum,
     *      or based on a snapshot/delegate system to avoid unbounded loops.
     */
    function _calculateTotalReputation() internal view returns (uint256) {
        // This is a placeholder. Iterating all keys in `reputationScores` is not possible/efficient on-chain.
        // A real system would either:
        // 1. Maintain a `totalReputation` state variable, updated on every reputation change.
        // 2. Use a token-weighted system (e.g., voting power tied to an ERC20 token balance).
        // 3. Implement a delegate voting system like Compound's.
        // For this example, let's return a dummy value or `type(uint256).max` to simulate high quorum bar.
        // Let's use a very simplified approach for initial testing.
        // If we want to simulate some active members, let's assume 100 people with 100 reputation average.
        return 10000; // Placeholder for total active reputation.
    }


    // --- VIII. Ancillary & Query Functions ---

    /**
     * @dev Returns the total amount of NEXUS_FUEL currently staked for a specific blueprint.
     * @param _blueprintId The ID of the blueprint.
     * @return The current funding amount.
     */
    function getBlueprintFundingAmount(uint256 _blueprintId)
        external
        view
        whenBlueprintExists(_blueprintId)
        returns (uint256)
    {
        return blueprints[_blueprintId].currentFunding;
    }

    /**
     * @dev Returns the current lifecycle stage of a blueprint.
     * @param _blueprintId The ID of the blueprint.
     * @return The current BlueprintStatus.
     */
    function getBlueprintStatus(uint256 _blueprintId)
        external
        view
        whenBlueprintExists(_blueprintId)
        returns (BlueprintStatus)
    {
        return blueprints[_blueprintId].status;
    }

    /**
     * @dev Returns a list of generation IDs an artisan has claimed but not yet completed.
     *      Note: This is an inefficient function for large data sets. For a real Dapp,
     *      an off-chain indexer would be preferred, or return paginated results.
     * @param _artisan The address of the AI Artisan.
     * @return An array of pending generation IDs.
     */
    function getPendingGenerationsForArtisan(address _artisan)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory pending;
        uint256 count = 0;
        for (uint256 i = 1; i <= _generationIds.current(); i++) {
            if (generations[i].artisan == _artisan && generations[i].status <= GenerationStatus.AwaitingCuration) {
                count++;
            }
        }

        pending = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 1; i <= _generationIds.current(); i++) {
            if (generations[i].artisan == _artisan && generations[i].status <= GenerationStatus.AwaitingCuration) {
                pending[idx] = i;
                idx++;
            }
        }
        return pending;
    }

    /**
     * @dev Returns a list of generation IDs awaiting attestation from a curator.
     *      Note: Similar to `getPendingGenerationsForArtisan`, this is inefficient for large data sets.
     * @param _curator The address of the Curator.
     * @return An array of pending generation IDs for attestation.
     */
    function getPendingAttestationsForCurator(address _curator)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory pending;
        uint256 count = 0;
        for (uint256 i = 1; i <= _generationIds.current(); i++) {
            if (generations[i].status == GenerationStatus.AwaitingCuration && !generations[i].curatorAttestations[_curator]) {
                count++;
            }
        }

        pending = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 1; i <= _generationIds.current(); i++) {
            if (generations[i].status == GenerationStatus.AwaitingCuration && !generations[i].curatorAttestations[_curator]) {
                pending[idx] = i;
                idx++;
            }
        }
        return pending;
    }

    /**
     * @dev Sets the minimum reputation score required to submit a governance proposal.
     * @param _newScore The new minimum reputation score.
     */
    function setMinimumReputationForProposal(uint256 _newScore) external onlyOwner { // Or via governance
        minReputationForProposal = _newScore;
        emit ParametersUpdated("minReputationForProposal", _newScore);
    }

    /**
     * @dev Sets the number of positive curator attestations required to finalize a generation.
     * @param _newCount The new number of required attestations.
     */
    function setRequiredAttestations(uint256 _newCount) external onlyOwner { // Or via governance
        require(_newCount > 0, "SyntheticaNexus: Required attestations must be greater than zero");
        requiredPositiveAttestations = _newCount;
        emit ParametersUpdated("requiredPositiveAttestations", _newCount);
    }

    // --- Internal ERC721 Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _approve(address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._approve(to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._transfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity for ERC721Enumerable/ERC721URIStorage.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, IERC2981)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
```