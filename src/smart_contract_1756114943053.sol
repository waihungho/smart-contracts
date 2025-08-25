```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title The ÆtherForge Protocol
 * @author [Your Name/Alias]
 * @notice A Decentralized Autonomous Intellectual Property (DAIP) Creation and Licensing Platform.
 * This contract enables a community to collaboratively create, evolve, and monetize digital assets
 * (represented as evolving IP concepts). It focuses on fractional ownership, community-driven
 * evolution, reputation building, and dynamic licensing.
 *
 * --- Outline and Function Summary ---
 *
 * I. Core Concepts:
 *    - ForgeAsset: An NFT-like representation of an evolving digital asset (IP concept). It's built up by contributions.
 *    - Contribution: A specific addition or modification proposed for a ForgeAsset.
 *    - Evolution Proposal: A significant proposed change or merging of contributions for an asset,
 *      requiring staked governance token (AFG) influence to vote.
 *    - License: A time-bound right to use a ForgeAsset for a specific purpose, generating royalties for asset owners.
 *    - Fractional Ownership: Multiple addresses can own a percentage of a ForgeAsset.
 *    - Reputation System: Tracks the value of a user's contributions and participation in the protocol.
 *
 * II. Function Categories and Summaries:
 *
 *    A. Asset Creation & Management (7 functions)
 *       1.  `proposeGenesisIdea(string _conceptHash, string _metadataURI)`: Initiates a new ForgeAsset with a foundational idea.
 *           - Parameters: `_conceptHash` (IPFS/Arweave hash of the initial concept data), `_metadataURI` (URI for asset metadata).
 *           - Effect: Creates a new `ForgeAsset` entry, assigns 100% initial ownership to the caller.
 *       2.  `contributeToAsset(uint256 _assetId, string _contributionHash, string _metadataURI)`: Adds a new contribution (e.g., an enhancement, a module, an alternative) to an existing ForgeAsset.
 *           - Parameters: `_assetId`, `_contributionHash`, `_metadataURI`.
 *           - Effect: Records the contribution, assigns initial influence/share for future ownership.
 *       3.  `upvoteContribution(uint256 _assetId, uint256 _contributionIndex)`: Allows users to signal approval for a specific contribution. Influences reputation and potential future ownership.
 *           - Parameters: `_assetId`, `_contributionIndex`.
 *           - Effect: Increments `upvotes` for the contribution, potentially boosts the contributor's reputation.
 *       4.  `finalizeAssetVersion(uint256 _assetId)`: Marks the current state of an asset (after successful evolution or a series of contributions) as a stable version.
 *           - Parameters: `_assetId`.
 *           - Effect: Creates a new version snapshot, potentially adjusts ownership shares based on successful contributions.
 *       5.  `transferAssetShare(uint256 _assetId, address _to, uint256 _percentage)`: Transfers a percentage of the caller's ownership share of an asset to another address.
 *           - Parameters: `_assetId`, `_to`, `_percentage` (e.g., 1000 for 10% out of 10000 total units).
 *           - Effect: Updates fractional ownership mappings.
 *       6.  `getAssetDetails(uint256 _assetId)`: Retrieves comprehensive details about a specific ForgeAsset.
 *           - Parameters: `_assetId`.
 *           - Effect: Returns asset's `id`, `ownerCount`, `creationTimestamp`, `latestVersionHash`, `metadataURI`, `totalShares`, `status`.
 *       7.  `getAssetContributions(uint256 _assetId)`: Fetches details of all contributions made to a given asset.
 *           - Parameters: `_assetId`.
 *           - Effect: Returns arrays of contribution hashes, metadata URIs, contributors, and upvote counts.
 *
 *    B. Evolution & Reputation (6 functions)
 *       8.  `stakeForInfluence(uint256 _amount)`: Stakes the protocol's governance token (AFG) to gain influence for voting on evolution proposals.
 *           - Parameters: `_amount` (of AFG tokens).
 *           - Effect: Locks AFG tokens, increases caller's `votingInfluence`.
 *       9.  `proposeEvolutionChange(uint256 _assetId, string _proposedChangeHash, string _metadataURI)`: Proposes a significant modification, merger, or refinement to a ForgeAsset, requiring community vote.
 *           - Parameters: `_assetId`, `_proposedChangeHash`, `_metadataURI`.
 *           - Effect: Creates an `EvolutionProposal`, starts a voting period.
 *       10. `voteOnEvolutionProposal(uint256 _assetId, uint256 _proposalId, bool _approve)`: Casts a vote (approve/reject) on an active evolution proposal using staked influence.
 *           - Parameters: `_assetId`, `_proposalId`, `_approve`.
 *           - Effect: Records vote, consumes caller's `votingInfluence` for this proposal.
 *       11. `executeEvolutionProposal(uint256 _assetId, uint256 _proposalId)`: Executes an approved evolution proposal, updating the asset's core properties and distributing rewards/reputation.
 *           - Parameters: `_assetId`, `_proposalId`.
 *           - Effect: If successful, updates `latestVersionHash`, distributes `reputationPoints`, potentially adjusts ownership.
 *       12. `claimReputation(uint256 _assetId)`: Allows a user to claim reputation points earned from successful contributions or votes on a specific asset.
 *           - Parameters: `_assetId`.
 *           - Effect: Adds earned reputation to `userReputation`.
 *       13. `getUserReputation(address _user)`: Retrieves the total accumulated reputation score for a given user.
 *           - Parameters: `_user`.
 *           - Effect: Returns `userReputation[_user]`.
 *
 *    C. Licensing & Monetization (6 functions)
 *       14. `offerLicense(uint256 _assetId, uint256 _pricePerUse, uint256 _durationBlocks, string _licenseType)`: Allows an asset owner to define and list terms for licensing their ForgeAsset.
 *           - Parameters: `_assetId`, `_pricePerUse` (in ETH/WETH), `_durationBlocks`, `_licenseType` (e.g., "Commercial", "Research").
 *           - Effect: Creates a `LicenseOffer`.
 *       15. `purchaseLicense(uint256 _assetId, uint256 _licenseOfferId)`: Buys a license for a ForgeAsset based on an existing offer.
 *           - Parameters: `_assetId`, `_licenseOfferId`.
 *           - Effect: Creates an active `License`, transfers funds to royalty pool.
 *       16. `extendLicense(uint256 _licenseId, uint256 _additionalDurationBlocks)`: Extends the duration of an active license.
 *           - Parameters: `_licenseId`, `_additionalDurationBlocks`.
 *           - Effect: Extends `expirationBlock` of the `License`, requires additional payment.
 *       17. `terminateLicense(uint256 _licenseId)`: Allows either the licensor (under breach conditions) or the licensee (prematurely) to terminate a license.
 *           - Parameters: `_licenseId`.
 *           - Effect: Sets `License.isActive` to false. Funds are handled per terms.
 *       18. `claimLicenseRoyalties(uint256 _assetId)`: Allows fractional owners of an asset to claim their accumulated royalty share from active licenses.
 *           - Parameters: `_assetId`.
 *           - Effect: Transfers ETH/WETH from the asset's royalty pool to eligible owners based on their shares.
 *       19. `updateRoyaltySplit(uint256 _assetId, address[] _owners, uint256[] _percentages)`: Adjusts the distribution of future royalties among the current fractional owners of an asset.
 *           - Parameters: `_assetId`, `_owners`, `_percentages` (sum must be 10000).
 *           - Effect: Updates the `assetRoyaltySplit` mapping for the asset.
 *
 *    D. Protocol Governance & Utility (5 functions)
 *       20. `setProtocolFee(uint256 _newFee)`: Allows the contract owner to set the protocol's fee percentage on license purchases.
 *           - Parameters: `_newFee` (e.g., 500 for 5% out of 10000 total units).
 *           - Effect: Updates `protocolFeePercentage`.
 *       21. `withdrawProtocolFees()`: Allows the contract owner to withdraw accumulated protocol fees.
 *           - Parameters: None.
 *           - Effect: Transfers accumulated ETH/WETH from the contract to the owner.
 *       22. `setGovernanceToken(address _tokenAddress)`: Sets the address of the AFG ERC-20 token used for staking and influence.
 *           - Parameters: `_tokenAddress`.
 *           - Effect: Updates `AFG_TOKEN` address.
 *       23. `emergencyPause()`: Allows the contract owner to pause critical functions in case of an emergency.
 *           - Parameters: None.
 *           - Effect: Sets `_paused` to true.
 *       24. `unpause()`: Allows the contract owner to unpause the contract after an emergency.
 *           - Parameters: None.
 *           - Effect: Sets `_paused` to false.
 */
contract AetherForgeProtocol is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    uint256 private _nextAssetId;
    uint256 private _nextProposalId;
    uint256 private _nextLicenseOfferId;
    uint256 private _nextLicenseId;

    // Scaling factor for percentages (e.g., 100% = 10000)
    uint256 public constant PERCENT_DENOMINATOR = 10000;

    // Protocol fee percentage (e.g., 500 for 5%)
    uint256 public protocolFeePercentage;
    uint256 public accumulatedProtocolFees; // In Wei

    IERC20 public AFG_TOKEN; // Address of the governance token

    // --- Structs ---

    enum AssetStatus {
        GenesisProposed,
        Evolving,
        Finalized,
        Retired
    }

    struct ForgeAsset {
        uint256 id;
        address creator;
        uint256 creationTimestamp;
        string genesisConceptHash; // Initial idea hash (IPFS/Arweave)
        string latestVersionHash;  // Current "state" or "version" hash
        string metadataURI;        // General metadata URI for the asset
        AssetStatus status;
        uint256 totalShares;       // Total shares outstanding for this asset (out of PERCENT_DENOMINATOR)
    }

    struct Contribution {
        uint256 id;
        uint256 assetId;
        address contributor;
        uint256 timestamp;
        string contributionHash; // Hash of the new/modified content
        string metadataURI;      // Metadata specific to this contribution
        uint256 upvotes;         // Community upvotes
        bool claimedReputation;  // If reputation from this contribution has been claimed
    }

    enum ProposalStatus {
        Pending,
        Voting,
        Approved,
        Rejected,
        Executed
    }

    struct EvolutionProposal {
        uint256 id;
        uint256 assetId;
        address proposer;
        string proposedChangeHash; // Hash of the proposed change (e.g., merge contributions)
        string metadataURI;        // Metadata for the proposal
        uint256 creationTimestamp;
        uint256 votingEndTime;
        uint256 totalVotesFor;     // Total influence votes for
        uint256 totalVotesAgainst;  // Total influence votes against
        ProposalStatus status;
    }

    struct LicenseOffer {
        uint256 id;
        uint256 assetId;
        address offerer; // Usually an owner, but could be specific agent
        uint256 pricePerUse; // In Wei (e.g., ETH)
        uint256 durationBlocks; // Duration in blocks
        string licenseType; // e.g., "Commercial", "Research", "Trial"
        bool isActive;
    }

    struct License {
        uint256 id;
        uint256 assetId;
        address licensee;
        address licensor; // The address who issued the license (could be the system or an owner)
        uint256 offerId;
        uint256 pricePaid;
        uint256 activationBlock;
        uint256 expirationBlock;
        string licenseType; // Redundant, but for historical context
        bool isActive;
    }

    // --- Mappings ---

    mapping(uint256 => ForgeAsset) public forgeAssets;
    mapping(uint256 => mapping(address => uint256)) public assetShares; // assetId => owner => share (out of PERCENT_DENOMINATOR)
    mapping(uint256 => address[]) public assetShareOwners; // assetId => list of owners for easier iteration
    mapping(uint256 => uint256) public assetRoyaltyPool; // assetId => total accumulated royalties in Wei

    mapping(uint256 => Contribution[]) public assetContributions; // assetId => list of contributions
    mapping(uint256 => mapping(address => bool)) public userUpvotedContribution; // assetId => contributionIndex => user => bool

    mapping(uint256 => EvolutionProposal[]) public assetEvolutionProposals; // assetId => list of proposals
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public proposalVotes; // assetId => proposalId => voter => hasVoted
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public proposalInfluenceVotes; // assetId => proposalId => voter => influence_used

    mapping(address => uint256) public userReputation; // address => total reputation score
    mapping(address => uint256) public userStakedInfluence; // address => AFG tokens staked for influence

    mapping(uint256 => LicenseOffer) public licenseOffers; // offerId => LicenseOffer
    mapping(uint256 => License) public activeLicenses;    // licenseId => License
    // Utility mapping to easily find an offer by assetId and owner for renewal/termination logic
    mapping(uint256 => mapping(uint256 => uint256)) public assetOfferToLicenseId; // assetId => offerId => licenseId (latest active)

    // Dynamic royalty split among owners for future royalties
    mapping(uint256 => mapping(address => uint256)) public assetRoyaltySplit; // assetId => owner => percentage (out of PERCENT_DENOMINATOR)
    mapping(uint256 => address[]) public assetRoyaltyReceivers; // assetId => list of addresses for current royalty split

    // --- Events ---

    event AssetCreated(uint256 indexed assetId, address indexed creator, string conceptHash, string metadataURI);
    event ContributionAdded(uint256 indexed assetId, uint256 indexed contributionIndex, address indexed contributor, string contributionHash);
    event ContributionUpvoted(uint256 indexed assetId, uint256 indexed contributionIndex, address indexed upvoter);
    event AssetVersionFinalized(uint256 indexed assetId, string latestVersionHash);
    event ShareTransferred(uint256 indexed assetId, address indexed from, address indexed to, uint256 percentage);

    event InfluenceStaked(address indexed user, uint256 amount, uint256 newInfluence);
    event EvolutionProposed(uint256 indexed assetId, uint256 indexed proposalId, address indexed proposer, string proposedChangeHash);
    event VoteCast(uint256 indexed assetId, uint256 indexed proposalId, address indexed voter, bool approved, uint256 influenceUsed);
    event ProposalExecuted(uint256 indexed assetId, uint256 indexed proposalId, bool success);
    event ReputationClaimed(address indexed user, uint256 indexed assetId, uint256 amount);

    event LicenseOffered(uint256 indexed assetId, uint256 indexed offerId, address indexed offerer, uint256 pricePerUse, uint256 durationBlocks, string licenseType);
    event LicensePurchased(uint256 indexed assetId, uint256 indexed licenseId, address indexed licensee, uint256 pricePaid, uint256 expirationBlock);
    event LicenseExtended(uint256 indexed licenseId, uint256 newExpirationBlock, uint256 additionalCost);
    event LicenseTerminated(uint256 indexed licenseId, address indexed terminator);
    event RoyaltiesClaimed(uint256 indexed assetId, address indexed owner, uint256 amount);
    event RoyaltySplitUpdated(uint256 indexed assetId, address[] owners, uint256[] percentages);

    event ProtocolFeeSet(uint256 newFeePercentage);
    event ProtocolFeesWithdrawn(address indexed owner, uint256 amount);
    event GovernanceTokenSet(address indexed tokenAddress);

    // --- Constructor ---

    constructor() {
        protocolFeePercentage = 500; // 5% by default
        _nextAssetId = 1;
        _nextProposalId = 1;
        _nextLicenseOfferId = 1;
        _nextLicenseId = 1;
    }

    // --- Modifiers ---

    modifier onlyAssetOwner(uint256 _assetId) {
        require(assetShares[_assetId][msg.sender] > 0, "Not an owner of this asset");
        _;
    }

    modifier onlyActiveAsset(uint256 _assetId) {
        require(forgeAssets[_assetId].id != 0, "Asset does not exist");
        require(forgeAssets[_assetId].status != AssetStatus.Retired, "Asset is retired");
        _;
    }

    modifier onlyAFGTokenSet() {
        require(address(AFG_TOKEN) != address(0), "AFG token address not set");
        _;
    }

    // --- A. Asset Creation & Management (7 functions) ---

    /**
     * @notice Initiates a new ForgeAsset with a foundational idea. The caller becomes the sole initial owner.
     * @param _conceptHash IPFS/Arweave hash of the initial concept data.
     * @param _metadataURI URI for general asset metadata.
     * @return The ID of the newly created asset.
     */
    function proposeGenesisIdea(string calldata _conceptHash, string calldata _metadataURI)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 assetId = _nextAssetId++;
        ForgeAsset storage newAsset = forgeAssets[assetId];
        newAsset.id = assetId;
        newAsset.creator = msg.sender;
        newAsset.creationTimestamp = block.timestamp;
        newAsset.genesisConceptHash = _conceptHash;
        newAsset.latestVersionHash = _conceptHash;
        newAsset.metadataURI = _metadataURI;
        newAsset.status = AssetStatus.GenesisProposed;
        newAsset.totalShares = PERCENT_DENOMINATOR; // 100%

        assetShares[assetId][msg.sender] = PERCENT_DENOMINATOR;
        assetShareOwners[assetId].push(msg.sender);
        // Initial royalty split is 100% to creator
        assetRoyaltySplit[assetId][msg.sender] = PERCENT_DENOMINATOR;
        assetRoyaltyReceivers[assetId].push(msg.sender);

        emit AssetCreated(assetId, msg.sender, _conceptHash, _metadataURI);
        return assetId;
    }

    /**
     * @notice Adds a new contribution (e.g., an enhancement, a module, an alternative) to an existing ForgeAsset.
     * @param _assetId The ID of the asset to contribute to.
     * @param _contributionHash Hash of the new/modified content.
     * @param _metadataURI Metadata specific to this contribution.
     */
    function contributeToAsset(
        uint256 _assetId,
        string calldata _contributionHash,
        string calldata _metadataURI
    ) external whenNotPaused onlyActiveAsset(_assetId) {
        ForgeAsset storage asset = forgeAssets[_assetId];
        require(asset.status != AssetStatus.Finalized, "Asset is finalized and cannot be contributed to directly.");

        uint256 contributionIndex = assetContributions[_assetId].length;
        assetContributions[_assetId].push(
            Contribution({
                id: contributionIndex,
                assetId: _assetId,
                contributor: msg.sender,
                timestamp: block.timestamp,
                contributionHash: _contributionHash,
                metadataURI: _metadataURI,
                upvotes: 0,
                claimedReputation: false
            })
        );
        asset.status = AssetStatus.Evolving; // Mark as evolving if not already

        emit ContributionAdded(_assetId, contributionIndex, msg.sender, _contributionHash);
    }

    /**
     * @notice Allows users to signal approval for a specific contribution. Influences reputation and potential future ownership adjustments.
     * @param _assetId The ID of the asset.
     * @param _contributionIndex The index of the contribution within the asset's contributions array.
     */
    function upvoteContribution(uint256 _assetId, uint256 _contributionIndex) external whenNotPaused onlyActiveAsset(_assetId) {
        require(_contributionIndex < assetContributions[_assetId].length, "Contribution does not exist");
        require(!userUpvotedContribution[_assetId][_contributionIndex][msg.sender], "Already upvoted this contribution");

        assetContributions[_assetId][_contributionIndex].upvotes = assetContributions[_assetId][_contributionIndex].upvotes.add(1);
        userUpvotedContribution[_assetId][_contributionIndex][msg.sender] = true;

        emit ContributionUpvoted(_assetId, _contributionIndex, msg.sender);
    }

    /**
     * @notice Marks the current state of an asset (after successful evolution or a series of contributions) as a stable version.
     *         This can trigger a review and potentially adjust ownership shares based on successful contributions.
     *         For simplicity, in this example, it just updates the status and allows for future royalty split adjustments.
     * @param _assetId The ID of the asset to finalize.
     */
    function finalizeAssetVersion(uint256 _assetId) external whenNotPaused onlyAssetOwner(_assetId) {
        ForgeAsset storage asset = forgeAssets[_assetId];
        require(asset.status != AssetStatus.Finalized, "Asset is already finalized");

        asset.status = AssetStatus.Finalized;
        // In a more complex system, this would trigger an ownership recalculation based on upvotes/successful evolution.
        // For now, it's a status change that allows for updated royalty splits.

        emit AssetVersionFinalized(_assetId, asset.latestVersionHash);
    }

    /**
     * @notice Transfers a percentage of the caller's ownership share of an asset to another address.
     * @param _assetId The ID of the asset.
     * @param _to The recipient address.
     * @param _percentage The percentage of shares to transfer (out of PERCENT_DENOMINATOR).
     */
    function transferAssetShare(uint256 _assetId, address _to, uint256 _percentage)
        external
        whenNotPaused
        onlyAssetOwner(_assetId)
    {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_percentage > 0 && _percentage <= PERCENT_DENOMINATOR, "Invalid percentage");
        require(assetShares[_assetId][msg.sender] >= _percentage, "Insufficient shares");

        assetShares[_assetId][msg.sender] = assetShares[_assetId][msg.sender].sub(_percentage);
        if (assetShares[_assetId][msg.sender] == 0) {
            // Remove sender from owners list if they have no shares left
            for (uint i = 0; i < assetShareOwners[_assetId].length; i++) {
                if (assetShareOwners[_assetId][i] == msg.sender) {
                    assetShareOwners[_assetId][i] = assetShareOwners[_assetId][assetShareOwners[_assetId].length - 1];
                    assetShareOwners[_assetId].pop();
                    break;
                }
            }
        }

        if (assetShares[_assetId][_to] == 0) {
            assetShareOwners[_assetId].push(_to);
        }
        assetShares[_assetId][_to] = assetShares[_assetId][_to].add(_percentage);

        emit ShareTransferred(_assetId, msg.sender, _to, _percentage);
    }

    /**
     * @notice Retrieves comprehensive details about a specific ForgeAsset.
     * @param _assetId The ID of the asset.
     * @return tuple containing asset details.
     */
    function getAssetDetails(uint256 _assetId)
        external
        view
        returns (
            uint256 id,
            address creator,
            uint256 creationTimestamp,
            string memory genesisConceptHash,
            string memory latestVersionHash,
            string memory metadataURI,
            AssetStatus status,
            uint256 totalShares,
            uint256 ownerCount
        )
    {
        ForgeAsset storage asset = forgeAssets[_assetId];
        require(asset.id != 0, "Asset does not exist");

        return (
            asset.id,
            asset.creator,
            asset.creationTimestamp,
            asset.genesisConceptHash,
            asset.latestVersionHash,
            asset.metadataURI,
            asset.status,
            asset.totalShares,
            assetShareOwners[_assetId].length
        );
    }

    /**
     * @notice Fetches details of all contributions made to a given asset.
     * @param _assetId The ID of the asset.
     * @return Arrays of contribution hashes, metadata URIs, contributors, and upvote counts.
     */
    function getAssetContributions(uint256 _assetId)
        external
        view
        returns (
            string[] memory contributionHashes,
            string[] memory metadataURIs,
            address[] memory contributors,
            uint256[] memory upvoteCounts
        )
    {
        Contribution[] storage contributions = assetContributions[_assetId];
        contributionHashes = new string[](contributions.length);
        metadataURIs = new string[](contributions.length);
        contributors = new address[](contributions.length);
        upvoteCounts = new uint256[](contributions.length);

        for (uint256 i = 0; i < contributions.length; i++) {
            contributionHashes[i] = contributions[i].contributionHash;
            metadataURIs[i] = contributions[i].metadataURI;
            contributors[i] = contributions[i].contributor;
            upvoteCounts[i] = contributions[i].upvotes;
        }
        return (contributionHashes, metadataURIs, contributors, upvoteCounts);
    }

    // --- B. Evolution & Reputation (6 functions) ---

    /**
     * @notice Stakes the protocol's governance token (AFG) to gain influence for voting on evolution proposals.
     * @param _amount The amount of AFG tokens to stake.
     */
    function stakeForInfluence(uint256 _amount) external whenNotPaused onlyAFGTokenSet {
        require(_amount > 0, "Amount must be greater than zero");
        require(AFG_TOKEN.transferFrom(msg.sender, address(this), _amount), "AFG transfer failed");

        userStakedInfluence[msg.sender] = userStakedInfluence[msg.sender].add(_amount);
        emit InfluenceStaked(msg.sender, _amount, userStakedInfluence[msg.sender]);
    }

    /**
     * @notice Proposes a significant modification, merger, or refinement to a ForgeAsset, requiring community vote.
     * @param _assetId The ID of the asset to propose a change for.
     * @param _proposedChangeHash Hash of the proposed new state or logic (IPFS/Arweave).
     * @param _metadataURI Metadata specific to this proposal.
     * @return The ID of the newly created proposal.
     */
    function proposeEvolutionChange(
        uint256 _assetId,
        string calldata _proposedChangeHash,
        string calldata _metadataURI
    ) external whenNotPaused onlyActiveAsset(_assetId) returns (uint256) {
        require(forgeAssets[_assetId].status != AssetStatus.Finalized, "Finalized assets cannot be directly evolved by proposal.");
        uint256 proposalId = _nextProposalId++;
        uint256 proposalIndex = assetEvolutionProposals[_assetId].length;

        assetEvolutionProposals[_assetId].push(
            EvolutionProposal({
                id: proposalId,
                assetId: _assetId,
                proposer: msg.sender,
                proposedChangeHash: _proposedChangeHash,
                metadataURI: _metadataURI,
                creationTimestamp: block.timestamp,
                votingEndTime: block.timestamp.add(72 hours), // 3 days voting period
                totalVotesFor: 0,
                totalVotesAgainst: 0,
                status: ProposalStatus.Voting
            })
        );

        emit EvolutionProposed(_assetId, proposalId, msg.sender, _proposedChangeHash);
        return proposalId;
    }

    /**
     * @notice Casts a vote (approve/reject) on an active evolution proposal using staked influence.
     * @param _assetId The ID of the asset.
     * @param _proposalId The ID of the evolution proposal.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnEvolutionProposal(uint256 _assetId, uint256 _proposalId, bool _approve)
        external
        whenNotPaused
        onlyActiveAsset(_assetId)
    {
        EvolutionProposal storage proposal = assetEvolutionProposals[_assetId][_proposalId-1]; // Assuming proposalId starts at 1
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Voting, "Proposal is not in voting phase");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(userStakedInfluence[msg.sender] > 0, "No influence staked to vote");
        require(!proposalVotes[_assetId][_proposalId][msg.sender], "Already voted on this proposal");

        uint256 influenceToUse = userStakedInfluence[msg.sender]; // Use all available influence for simplicity
        proposalInfluenceVotes[_assetId][_proposalId][msg.sender] = influenceToUse;
        proposalVotes[_assetId][_proposalId][msg.sender] = true;

        if (_approve) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(influenceToUse);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(influenceToUse);
        }

        // Unstake influence *after* vote for this proposal. It can be restaked for another vote.
        // This is a design choice: influence is "spent" per vote, not consumed from total stake.
        // userStakedInfluence[msg.sender] = userStakedInfluence[msg.sender].sub(influenceToUse);
        // If we want to use influence per vote, it implies the influence is not 'liquid' but applied to one vote.
        // Let's assume influence is a general pool, but can only be used once per proposal.

        emit VoteCast(_assetId, _proposalId, msg.sender, _approve, influenceToUse);
    }

    /**
     * @notice Executes an approved evolution proposal, updating the asset's core properties and distributing rewards/reputation.
     *         Can only be called after the voting period ends and if the proposal passed.
     * @param _assetId The ID of the asset.
     * @param _proposalId The ID of the evolution proposal.
     */
    function executeEvolutionProposal(uint256 _assetId, uint256 _proposalId) external whenNotPaused onlyActiveAsset(_assetId) {
        EvolutionProposal storage proposal = assetEvolutionProposals[_assetId][_proposalId-1];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Voting, "Proposal is not in voting phase");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended yet");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.status = ProposalStatus.Approved;
            forgeAssets[_assetId].latestVersionHash = proposal.proposedChangeHash;
            forgeAssets[_assetId].metadataURI = proposal.metadataURI; // Update asset metadata with proposal's metadata

            // For simplicity, successful proposals reward reputation to proposer and voters.
            userReputation[proposal.proposer] = userReputation[proposal.proposer].add(100); // Proposer reward
            // Could iterate through all voters to reward them too, but gas heavy. Let's make it on claim for contributions.

            emit ProposalExecuted(_assetId, _proposalId, true);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit ProposalExecuted(_assetId, _proposalId, false);
        }
    }

    /**
     * @notice Allows a user to claim reputation points earned from successful contributions or votes on a specific asset.
     *         Simplified: grants reputation for contributions after an asset is finalized or a proposal is executed.
     * @param _assetId The ID of the asset.
     */
    function claimReputation(uint256 _assetId) external whenNotPaused {
        require(forgeAssets[_assetId].id != 0, "Asset does not exist");
        uint256 reputationEarned = 0;

        // Claim reputation for contributions that have upvotes and are not yet claimed
        for (uint256 i = 0; i < assetContributions[_assetId].length; i++) {
            Contribution storage contribution = assetContributions[_assetId][i];
            if (contribution.contributor == msg.sender && contribution.upvotes > 0 && !contribution.claimedReputation) {
                reputationEarned = reputationEarned.add(contribution.upvotes); // Basic: 1 reputation per upvote
                contribution.claimedReputation = true;
            }
        }
        // Could also add reputation for successful votes on executed proposals

        require(reputationEarned > 0, "No reputation to claim for this asset");
        userReputation[msg.sender] = userReputation[msg.sender].add(reputationEarned);
        emit ReputationClaimed(msg.sender, _assetId, reputationEarned);
    }

    /**
     * @notice Retrieves the total accumulated reputation score for a given user.
     * @param _user The address of the user.
     * @return The total reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    // --- C. Licensing & Monetization (6 functions) ---

    /**
     * @notice Allows an asset owner to define and list terms for licensing their ForgeAsset.
     * @param _assetId The ID of the asset.
     * @param _pricePerUse The price in Wei per duration blocks.
     * @param _durationBlocks The duration of the license in blocks.
     * @param _licenseType A string describing the type of license (e.g., "Commercial", "Research").
     * @return The ID of the newly created license offer.
     */
    function offerLicense(
        uint256 _assetId,
        uint256 _pricePerUse,
        uint256 _durationBlocks,
        string calldata _licenseType
    ) external whenNotPaused onlyAssetOwner(_assetId) returns (uint256) {
        require(_pricePerUse > 0, "Price must be greater than zero");
        require(_durationBlocks > 0, "Duration must be greater than zero");
        require(bytes(_licenseType).length > 0, "License type cannot be empty");

        uint256 offerId = _nextLicenseOfferId++;
        licenseOffers[offerId] = LicenseOffer({
            id: offerId,
            assetId: _assetId,
            offerer: msg.sender,
            pricePerUse: _pricePerUse,
            durationBlocks: _durationBlocks,
            licenseType: _licenseType,
            isActive: true
        });

        emit LicenseOffered(_assetId, offerId, msg.sender, _pricePerUse, _durationBlocks, _licenseType);
        return offerId;
    }

    /**
     * @notice Buys a license for a ForgeAsset based on an existing offer.
     * @param _assetId The ID of the asset.
     * @param _licenseOfferId The ID of the license offer.
     * @return The ID of the newly purchased license.
     */
    function purchaseLicense(uint256 _assetId, uint256 _licenseOfferId) external payable whenNotPaused {
        LicenseOffer storage offer = licenseOffers[_licenseOfferId];
        require(offer.id != 0 && offer.isActive, "License offer not found or inactive");
        require(offer.assetId == _assetId, "Offer does not match asset ID");
        require(msg.value == offer.pricePerUse, "Incorrect payment amount");

        uint256 licenseId = _nextLicenseId++;
        uint256 protocolShare = msg.value.mul(protocolFeePercentage).div(PERCENT_DENOMINATOR);
        uint256 royaltyShare = msg.value.sub(protocolShare);

        activeLicenses[licenseId] = License({
            id: licenseId,
            assetId: _assetId,
            licensee: msg.sender,
            licensor: offer.offerer, // The one who made the offer
            offerId: _licenseOfferId,
            pricePaid: msg.value,
            activationBlock: block.number,
            expirationBlock: block.number.add(offer.durationBlocks),
            licenseType: offer.licenseType,
            isActive: true
        });
        assetOfferToLicenseId[_assetId][_licenseOfferId] = licenseId;

        assetRoyaltyPool[_assetId] = assetRoyaltyPool[_assetId].add(royaltyShare);
        accumulatedProtocolFees = accumulatedProtocolFees.add(protocolShare);

        emit LicensePurchased(_assetId, licenseId, msg.sender, msg.value, activeLicenses[licenseId].expirationBlock);
        return licenseId;
    }

    /**
     * @notice Extends the duration of an active license.
     * @param _licenseId The ID of the license to extend.
     * @param _additionalDurationBlocks The number of blocks to add to the license duration.
     */
    function extendLicense(uint256 _licenseId, uint256 _additionalDurationBlocks) external payable whenNotPaused {
        License storage license = activeLicenses[_licenseId];
        require(license.id != 0 && license.isActive, "License not found or inactive");
        require(license.licensee == msg.sender, "Only licensee can extend");
        require(_additionalDurationBlocks > 0, "Additional duration must be greater than zero");

        LicenseOffer storage offer = licenseOffers[license.offerId];
        require(offer.id != 0 && offer.isActive, "Original license offer is no longer active");

        uint256 requiredPayment = offer.pricePerUse.div(offer.durationBlocks).mul(_additionalDurationBlocks);
        require(msg.value == requiredPayment, "Incorrect payment for extension");

        uint256 protocolShare = msg.value.mul(protocolFeePercentage).div(PERCENT_DENOMINATOR);
        uint256 royaltyShare = msg.value.sub(protocolShare);

        license.expirationBlock = license.expirationBlock.add(_additionalDurationBlocks);
        license.pricePaid = license.pricePaid.add(msg.value);

        assetRoyaltyPool[license.assetId] = assetRoyaltyPool[license.assetId].add(royaltyShare);
        accumulatedProtocolFees = accumulatedProtocolFees.add(protocolShare);

        emit LicenseExtended(_licenseId, license.expirationBlock, msg.value);
    }

    /**
     * @notice Allows either the licensor (under breach conditions) or the licensee (prematurely) to terminate a license.
     *         No refunds are handled by this contract in a basic implementation.
     * @param _licenseId The ID of the license to terminate.
     */
    function terminateLicense(uint256 _licenseId) external whenNotPaused {
        License storage license = activeLicenses[_licenseId];
        require(license.id != 0 && license.isActive, "License not found or already inactive");
        require(license.licensee == msg.sender || license.licensor == msg.sender || forgeAssets[license.assetId].creator == msg.sender, "Not authorized to terminate license");

        license.isActive = false;
        // Refunds or penalties would be external to this basic contract or part of a more complex dispute resolution.
        // For simplicity, no funds are moved on termination.

        emit LicenseTerminated(_licenseId, msg.sender);
    }

    /**
     * @notice Allows fractional owners of an asset to claim their accumulated royalty share from active licenses.
     * @param _assetId The ID of the asset.
     */
    function claimLicenseRoyalties(uint256 _assetId) external whenNotPaused onlyAssetOwner(_assetId) {
        uint256 availableRoyalties = assetRoyaltyPool[_assetId];
        require(availableRoyalties > 0, "No royalties available for this asset");

        address[] memory receivers = assetRoyaltyReceivers[_assetId];
        uint256 senderShare = assetRoyaltySplit[_assetId][msg.sender];
        require(senderShare > 0, "You do not have a royalty share in this asset.");

        uint256 amountToClaim = availableRoyalties.mul(senderShare).div(PERCENT_DENOMINATOR);
        require(amountToClaim > 0, "Calculated claim amount is zero");

        // Reduce pool BEFORE transfer to prevent reentrancy
        assetRoyaltyPool[_assetId] = assetRoyaltyPool[_assetId].sub(amountToClaim);

        (bool success, ) = msg.sender.call{value: amountToClaim}("");
        require(success, "Failed to transfer royalties");

        emit RoyaltiesClaimed(_assetId, msg.sender, amountToClaim);
    }

    /**
     * @notice Adjusts the distribution of future royalties among the current fractional owners of an asset.
     *         Can only be called by an asset owner. The sum of percentages must be 100%.
     * @param _assetId The ID of the asset.
     * @param _owners An array of addresses that will receive royalties.
     * @param _percentages An array of percentages (out of PERCENT_DENOMINATOR) corresponding to `_owners`.
     */
    function updateRoyaltySplit(uint256 _assetId, address[] calldata _owners, uint256[] calldata _percentages)
        external
        whenNotPaused
        onlyAssetOwner(_assetId)
    {
        require(_owners.length == _percentages.length, "Arrays must be of same length");
        require(_owners.length > 0, "Must specify at least one owner");

        uint256 totalPercentage;
        // Check if all owners actually own a share in the asset and sum percentages
        for (uint256 i = 0; i < _owners.length; i++) {
            require(assetShares[_assetId][_owners[i]] > 0, "Address in split is not an asset owner");
            totalPercentage = totalPercentage.add(_percentages[i]);
        }
        require(totalPercentage == PERCENT_DENOMINATOR, "Percentages must sum to 100%");

        // Clear existing split
        for (uint256 i = 0; i < assetRoyaltyReceivers[_assetId].length; i++) {
            delete assetRoyaltySplit[_assetId][assetRoyaltyReceivers[_assetId][i]];
        }
        delete assetRoyaltyReceivers[_assetId]; // Clear the array

        // Set new split
        for (uint256 i = 0; i < _owners.length; i++) {
            assetRoyaltySplit[_assetId][_owners[i]] = _percentages[i];
            assetRoyaltyReceivers[_assetId].push(_owners[i]);
        }

        emit RoyaltySplitUpdated(_assetId, _owners, _percentages);
    }

    // --- D. Protocol Governance & Utility (5 functions) ---

    /**
     * @notice Allows the contract owner to set the protocol's fee percentage on license purchases.
     * @param _newFee The new fee percentage (e.g., 500 for 5%).
     */
    function setProtocolFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= PERCENT_DENOMINATOR, "Fee cannot exceed 100%");
        protocolFeePercentage = _newFee;
        emit ProtocolFeeSet(_newFee);
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = accumulatedProtocolFees;
        require(amount > 0, "No fees to withdraw");
        accumulatedProtocolFees = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw fees");

        emit ProtocolFeesWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Sets the address of the AFG ERC-20 token used for staking and influence.
     *         Can only be called once.
     * @param _tokenAddress The address of the AFG token contract.
     */
    function setGovernanceToken(address _tokenAddress) external onlyOwner {
        require(address(AFG_TOKEN) == address(0), "AFG token address already set");
        require(_tokenAddress != address(0), "Token address cannot be zero");
        AFG_TOKEN = IERC20(_tokenAddress);
        emit GovernanceTokenSet(_tokenAddress);
    }

    /**
     * @notice Allows the contract owner to pause critical functions in case of an emergency.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows the contract owner to unpause the contract after an emergency.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
```