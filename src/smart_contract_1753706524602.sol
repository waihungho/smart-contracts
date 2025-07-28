```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ChronoscribeGenesis: A Dynamic, AI-Curated, Soulbound NFT Registry for Evolving Digital Identities & Collaborative Lore Generation.
//
// This contract empowers users to mint unique, non-transferable "Chronoscribe Identity" NFTs. These identities are dynamic,
// evolving based on user contributions to a shared "Chronoscribe Archive," AI oracle assessments, and community governance.
// The system fosters a decentralized, evolving narrative or knowledge base, where digital identities are directly linked
// to their verifiable contributions and reputation within the Chronoscribe ecosystem.
//
// Key Concepts:
// - Soulbound Tokens (SBTs): Identities are non-transferable, representing a fixed digital presence.
// - Dynamic NFTs: Identity metadata and visual representation evolve based on on-chain state.
// - AI Oracle Integration: An external AI (simulated via oracle) evaluates contributions and curates identity evolution.
// - Collaborative World-building: Users contribute to a shared archive, building collective lore or knowledge.
// - On-chain Reputation: Reputation scores tied to identities, influencing governance and evolution.
//
// ---------------------------------------------------------------------------------------------------------------------
// OUTLINE & FUNCTION SUMMARY
// ---------------------------------------------------------------------------------------------------------------------
//
// I. Core Identity & NFT Management (Chronoscribe Genesis SBTs)
//    - Manages the creation and state of Soulbound Chronoscribe Identity NFTs.
//    1.  `mintChronoscribeIdentity()`: Allows a user to mint their unique, non-transferable Chronoscribe Identity NFT.
//    2.  `getChronoscribeIdentityUri(tokenId)`: Retrieves the dynamic metadata URI for a given identity, reflecting its current state.
//    3.  `updateIdentityMetadataHash(tokenId, newHash)`: (Internal/System) Updates the integrity hash for an identity's off-chain metadata.
//    4.  `getCurrentIdentityFacets(tokenId)`: Returns the set of currently unlocked "facets" (attributes) for an identity.
//    5.  `setIdentityFacet(tokenId, facetId, isActive)`: (Internal/System) Activates or deactivates a specific facet for an identity, triggering metadata change.
//    6.  `tokenURI(tokenId)`: ERC721 standard function to get the token's metadata URI (overridden for dynamic URI).
//
// II. Collaborative Archive & Contribution System
//    - Enables users to submit and manage contributions to the shared Chronoscribe Archive.
//    7.  `submitArchivalContribution(contentType, contentHash, metadata)`: Submits a hash and metadata representing a user's contribution to the archive.
//    8.  `getContributionDetails(contributionId)`: Retrieves the full details of a specific submitted contribution.
//    9.  `flagContribution(contributionId, reason)`: Allows users to flag contributions for review (e.g., inappropriate content).
//    10. `resolveFlag(contributionId, resolvedState)`: (Admin/Moderator) Resolves a flagged contribution, potentially marking it as valid or invalid.
//
// III. AI Oracle & Curation Layer
//    - Integrates with an external AI oracle for appraisal, curation, and identity evolution.
//    11. `setAIOracleAddress(newOracle)`: (Admin) Sets the authorized address for the AI Oracle.
//    12. `requestAIAppraisal(contributionId)`: Initiates a request to the AI Oracle for appraisal of a specific contribution.
//    13. `fulfillAIAppraisal(requestId, contributionId, appraisalScore, narrativeImpact, newFacetsToUnlock)`: Callback from the AI Oracle, providing appraisal results and suggested identity facets.
//    14. `registerAIAppraisalResult(contributionId, appraisalScore, narrativeImpact, newFacetsToUnlock)`: (Internal/System) Processes AI appraisal results, updates reputation, and applies new facets.
//
// IV. Reputation & Influence System
//    - Tracks and manages reputation scores for Chronoscribe Identities.
//    15. `getIdentityReputation(tokenId)`: Retrieves the current reputation score for a specific identity.
//    16. `getContributionNarrativeImpact(contributionId)`: Retrieves the narrative impact score assigned by the AI for a contribution.
//    17. `accrueReputation(tokenId, points)`: (Internal/System) Adds reputation points to an identity based on approved contributions.
//
// V. Governance & Community Curation
//    - Provides mechanisms for community-driven decisions and proposals.
//    18. `proposeNarrativeEvolution(proposalType, dataHash, targetIdentityId)`: Allows an identity holder to propose a direct change or evolution within the narrative/identity system.
//    19. `voteOnProposal(proposalId, support)`: Identity holders vote on active proposals.
//    20. `executeProposal(proposalId)`: Executes a proposal that has met its voting thresholds.
//    21. `setProposalThresholds(minReputation, quorumPercentage)`: (Admin) Sets the minimum reputation required to propose and the quorum for voting.
//
// VI. Time-Based & Event-Driven Evolution
//    - Facilitates periodic or event-driven global evolution of the Chronoscribe ecosystem.
//    22. `triggerEpochEvolution()`: (Trusted Relayer) Advances the Chronoscribe Epoch, potentially triggering global reassessments or general facet unlocks.
//    23. `getChronoscribeEpoch()`: Returns the current Chronoscribe Epoch number.
//
// VII. Utilities & Admin
//    - Standard administrative and utility functions.
//    24. `pauseContract()`: (Admin) Pauses most contract functionalities.
//    25. `unpauseContract()`: (Admin) Unpauses contract functionalities.
//    26. `withdrawFunds()`: (Admin) Allows the owner to withdraw any accumulated ETH (if fees were implemented).
// ---------------------------------------------------------------------------------------------------------------------


contract ChronoscribeGenesis is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Total count of Chronoscribe Identities minted
    Counters.Counter private _tokenIdCounter;
    // Total count of contributions to the archive
    Counters.Counter private _contributionIdCounter;
    // Total count of governance proposals
    Counters.Counter private _proposalIdCounter;
    // Current Chronoscribe Epoch (time-based evolution marker)
    uint256 public chronoscribeEpoch;

    // Mapping of tokenId to Identity struct
    mapping(uint256 => Identity) public identities;
    // Mapping of contributionId to Contribution struct
    mapping(uint256 => Contribution) public contributions;
    // Mapping of proposalId to Proposal struct
    mapping(uint256 => Proposal) public proposals;

    // Mapping of address to tokenId (for reverse lookup)
    mapping(address => uint256) public addressToTokenId;
    // Mapping to track if an address has minted an identity
    mapping(address => bool) public hasMintedIdentity;

    // AI Oracle address (simulated off-chain AI computation)
    address public aiOracleAddress;
    // Base URI for dynamic NFT metadata server
    string private _baseTokenURI;

    // Governance parameters
    uint256 public minReputationToPropose;
    uint256 public proposalQuorumPercentage; // e.g., 51 for 51%
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Example: 7 days to vote

    // --- Struct Definitions ---

    struct Identity {
        uint256 tokenId;
        uint256 reputation;
        // Mapping of facetId => isActive. Facets represent specific attributes or unlocks for the identity.
        // E.g., 1= "Knowledge Seeker", 2= "Lore Master", 3= "Curator"
        mapping(uint256 => bool) facets;
        string currentMetadataHash; // Hash of the latest dynamically generated metadata
        uint256 lastEvolutionEpoch;
        address ownerAddress; // Storing owner to simplify lookups
    }

    enum ContentType { TEXT, DATA, CODE, ART, OTHER }

    struct Contribution {
        uint256 id;
        uint256 contributorId; // tokenId of the contributor
        ContentType contentType;
        bytes32 contentHash; // IPFS hash or similar hash of the actual content
        string metadataURI; // URI to additional description/metadata about the content
        uint256 submittedAt;
        uint256 aiAppraisalScore; // Score from AI: 0-100
        uint256 narrativeImpactScore; // Derived from AI appraisal
        bool aiAppraised;
        bool flagged;
        string flagReason; // Reason if flagged
        bool isValid; // True if content passed checks/AI appraisal, false if rejected/invalidated
        uint256 requestAiId; // ID for the AI appraisal request
    }

    enum ProposalType { NARRATIVE_EVOLUTION, PARAMETER_CHANGE, MODERATION_ACTION }

    struct Proposal {
        uint256 id;
        uint256 proposerId; // tokenId of the proposer
        uint256 creationTime;
        ProposalType proposalType;
        bytes32 dataHash; // Hash of proposal details (e.g., new facets, parameter values for PARAMETER_CHANGE)
        uint256 targetIdentityId; // Optional: if proposal targets a specific identity
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVoters; // Total unique identities that voted
        mapping(uint256 => bool) hasVoted; // tokenId => voted status
        bool executed;
        bool passed; // Set once voting period ends and threshold met
    }

    // --- Events ---

    event ChronoscribeIdentityMinted(uint256 indexed tokenId, address indexed owner);
    event IdentityMetadataUpdated(uint256 indexed tokenId, string newMetadataHash);
    event IdentityFacetUpdated(uint256 indexed tokenId, uint256 facetId, bool isActive);
    event ContributionSubmitted(uint256 indexed contributionId, uint256 indexed contributorId, ContentType contentType, bytes32 contentHash);
    event ContributionFlagged(uint256 indexed contributionId, address indexed flagger, string reason);
    event ContributionFlagResolved(uint256 indexed contributionId, bool resolvedState);
    event AIAppraisalRequested(uint256 indexed contributionId, uint256 requestId);
    event AIAppraisalFulfilled(uint256 indexed requestId, uint256 indexed contributionId, uint256 appraisalScore, uint256 narrativeImpact, uint256[] newFacets);
    event IdentityReputationAccrued(uint256 indexed tokenId, uint256 points);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed proposerId, ProposalType proposalType);
    event ProposalVoted(uint256 indexed proposalId, uint256 indexed voterId, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event EpochAdvanced(uint256 newEpoch);
    event AIOracleAddressSet(address indexed oldAddress, address indexed newAddress);

    // --- Constructor ---

    constructor(string memory baseTokenURI_)
        ERC721("ChronoscribeGenesis", "CHRONOSCRIBE")
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseTokenURI_;
        minReputationToPropose = 100; // Example initial value
        proposalQuorumPercentage = 51; // Example: 51%
        chronoscribeEpoch = 1;
    }

    // --- ERC721 Overrides for Soulbound Behavior ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Prevent any transfers after minting.
        // Transfers from address(0) are allowed during mint.
        require(from == address(0), "Chronoscribe: Identity is soulbound and cannot be transferred");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Explicitly disallow transferFrom to reinforce soulbound nature
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Chronoscribe: Identity is soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Chronoscribe: Identity is soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("Chronoscribe: Identity is soulbound and cannot be transferred");
    }

    // --- I. Core Identity & NFT Management ---

    /**
     * @notice Mints a unique, non-transferable Chronoscribe Identity NFT to the caller.
     * @dev Each address can only mint one identity.
     */
    function mintChronoscribeIdentity() public whenNotPaused {
        require(!hasMintedIdentity[msg.sender], "Chronoscribe: You already own a Chronoscribe Identity.");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        hasMintedIdentity[msg.sender] = true;
        addressToTokenId[msg.sender] = newTokenId;

        // Initialize identity struct
        Identity storage newIdentity = identities[newTokenId];
        newIdentity.tokenId = newTokenId;
        newIdentity.reputation = 0;
        newIdentity.lastEvolutionEpoch = chronoscribeEpoch;
        newIdentity.ownerAddress = msg.sender;

        emit ChronoscribeIdentityMinted(newTokenId, msg.sender);
    }

    /**
     * @notice Retrieves the dynamic metadata URI for a given identity.
     * @dev The URI points to an off-chain service that generates metadata based on the identity's state.
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     * @return The URI for the identity's metadata.
     */
    function getChronoscribeIdentityUri(uint256 tokenId) public view returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        // The URI should dynamically reflect the identity's current state (facets, reputation, epoch)
        // This structure assumes _baseTokenURI points to a service like "https://api.chronoscribe.io/metadata/"
        // and the service then uses the tokenId to query on-chain state to construct the JSON.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    /**
     * @notice ERC721 standard function to get the token's metadata URI.
     * @dev Overridden to call getChronoscribeIdentityUri for dynamic metadata.
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return getChronoscribeIdentityUri(tokenId);
    }

    /**
     * @notice (Internal/System) Updates the integrity hash for an identity's off-chain metadata.
     * @dev This function is intended to be called by the AI oracle or system processes after an evolution.
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     * @param newHash The new hash representing the updated metadata.
     */
    function updateIdentityMetadataHash(uint256 tokenId, string calldata newHash) internal {
        require(bytes(newHash).length > 0, "Chronoscribe: New metadata hash cannot be empty.");
        identities[tokenId].currentMetadataHash = newHash;
        emit IdentityMetadataUpdated(tokenId, newHash);
    }

    /**
     * @notice Returns the set of currently unlocked "facets" (attributes) for an identity.
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     * @return An array of uint256 representing active facet IDs.
     */
    function getCurrentIdentityFacets(uint256 tokenId) public view returns (uint256[] memory) {
        _requireOwned(tokenId);
        // This function would typically iterate through known facet IDs.
        // For simplicity, we'll return an empty array if no specific facet list is stored directly.
        // The actual facet data is in the mapping `identities[tokenId].facets`.
        // Retrieving all active facets requires iterating over all possible facet IDs, which is not scalable on-chain.
        // A more practical approach would be to have the off-chain metadata service query individual facets,
        // or have a specific storage mechanism for active facets as an array.
        // For demonstration, let's assume we can retrieve a few common facets.
        // To truly return ALL active facets, we'd need a separate array storage or a view function that queries specific known facets.
        // For now, this is conceptual for off-chain use.
        // The dynamic metadata generation service would read `identities[tokenId].facets[facetId]`.
        // This function will just return a placeholder or require explicit facet IDs.
        return new uint256[](0); // Placeholder, actual facets are looked up individually
    }

    /**
     * @notice (Internal/System) Activates or deactivates a specific facet for an identity.
     * @dev Intended to be called by trusted entities (AI Oracle, governance execution).
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     * @param facetId The ID of the facet to activate/deactivate.
     * @param isActive True to activate, false to deactivate.
     */
    function setIdentityFacet(uint256 tokenId, uint256 facetId, bool isActive) internal {
        require(tokenId > 0 && tokenId <= _tokenIdCounter.current(), "Chronoscribe: Invalid Token ID.");
        identities[tokenId].facets[facetId] = isActive;
        emit IdentityFacetUpdated(tokenId, facetId, isActive);
        // Optionally, trigger a metadata update hash here
        // updateIdentityMetadataHash(tokenId, "newHashBasedOnFacets"); // This would be complex in real scenario
    }

    // --- II. Collaborative Archive & Contribution System ---

    /**
     * @notice Submits a hash and metadata representing a user's contribution to the Chronoscribe Archive.
     * @dev The actual content is stored off-chain (e.g., IPFS) and referenced by contentHash.
     * @param contentType The type of content (e.g., TEXT, DATA, CODE).
     * @param contentHash The cryptographic hash (e.g., IPFS CID) of the actual content.
     * @param metadataURI A URI pointing to additional descriptive metadata for the contribution.
     */
    function submitArchivalContribution(
        ContentType contentType,
        bytes32 contentHash,
        string calldata metadataURI
    ) public whenNotPaused {
        require(hasMintedIdentity[msg.sender], "Chronoscribe: Only identity holders can submit contributions.");
        require(contentHash != bytes32(0), "Chronoscribe: Content hash cannot be empty.");
        require(bytes(metadataURI).length > 0, "Chronoscribe: Metadata URI cannot be empty.");

        _contributionIdCounter.increment();
        uint256 newContributionId = _contributionIdCounter.current();
        uint256 contributorId = addressToTokenId[msg.sender];

        Contribution storage newContribution = contributions[newContributionId];
        newContribution.id = newContributionId;
        newContribution.contributorId = contributorId;
        newContribution.contentType = contentType;
        newContribution.contentHash = contentHash;
        newContribution.metadataURI = metadataURI;
        newContribution.submittedAt = block.timestamp;
        newContribution.isValid = true; // Mark as valid until flagged/rejected

        emit ContributionSubmitted(newContributionId, contributorId, contentType, contentHash);
    }

    /**
     * @notice Retrieves the full details of a specific submitted contribution.
     * @param contributionId The ID of the contribution.
     * @return A tuple containing all details of the contribution.
     */
    function getContributionDetails(uint256 contributionId)
        public
        view
        returns (
            uint256 id,
            uint256 contributorId,
            ContentType contentType,
            bytes32 contentHash,
            string memory metadataURI,
            uint256 submittedAt,
            uint256 aiAppraisalScore,
            uint256 narrativeImpactScore,
            bool aiAppraised,
            bool flagged,
            string memory flagReason,
            bool isValid
        )
    {
        require(contributionId > 0 && contributionId <= _contributionIdCounter.current(), "Chronoscribe: Invalid Contribution ID.");
        Contribution storage c = contributions[contributionId];
        return (
            c.id,
            c.contributorId,
            c.contentType,
            c.contentHash,
            c.metadataURI,
            c.submittedAt,
            c.aiAppraisalScore,
            c.narrativeImpactScore,
            c.aiAppraised,
            c.flagged,
            c.flagReason,
            c.isValid
        );
    }

    /**
     * @notice Allows any identity holder to flag a contribution for review.
     * @dev Requires the flipper to hold an identity.
     * @param contributionId The ID of the contribution to flag.
     * @param reason A brief reason for flagging.
     */
    function flagContribution(uint256 contributionId, string calldata reason) public whenNotPaused {
        require(hasMintedIdentity[msg.sender], "Chronoscribe: Only identity holders can flag contributions.");
        require(contributionId > 0 && contributionId <= _contributionIdCounter.current(), "Chronoscribe: Invalid Contribution ID.");
        require(bytes(reason).length > 0, "Chronoscribe: Flag reason cannot be empty.");
        
        Contribution storage c = contributions[contributionId];
        require(!c.flagged, "Chronoscribe: Contribution already flagged.");

        c.flagged = true;
        c.flagReason = reason;
        emit ContributionFlagged(contributionId, msg.sender, reason);
    }

    /**
     * @notice (Admin/Moderator) Resolves a flagged contribution, marking it as valid or invalid.
     * @dev Only the contract owner can resolve flags. In a real DAO, this could be a governance decision.
     * @param contributionId The ID of the flagged contribution.
     * @param resolvedState True to mark as valid, false to mark as invalid.
     */
    function resolveFlag(uint256 contributionId, bool resolvedState) public onlyOwner whenNotPaused {
        require(contributionId > 0 && contributionId <= _contributionIdCounter.current(), "Chronoscribe: Invalid Contribution ID.");
        Contribution storage c = contributions[contributionId];
        require(c.flagged, "Chronoscribe: Contribution is not flagged.");

        c.flagged = false; // Flag resolved
        c.isValid = resolvedState;
        c.flagReason = ""; // Clear reason after resolution
        emit ContributionFlagResolved(contributionId, resolvedState);
    }

    // --- III. AI Oracle & Curation Layer ---

    /**
     * @notice (Admin) Sets the authorized address for the AI Oracle.
     * @dev This address is trusted to call `fulfillAIAppraisal`.
     * @param newOracle The address of the AI Oracle.
     */
    function setAIOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "Chronoscribe: AI Oracle address cannot be zero.");
        emit AIOracleAddressSet(aiOracleAddress, newOracle);
        aiOracleAddress = newOracle;
    }

    /**
     * @notice Initiates a request to the AI Oracle for appraisal of a specific contribution.
     * @dev This function would typically trigger an off-chain Chainlink request or similar.
     *      Returns a simulated request ID for tracking.
     * @param contributionId The ID of the contribution to be appraised.
     * @return The simulated request ID.
     */
    function requestAIAppraisal(uint256 contributionId) public whenNotPaused returns (uint256) {
        require(contributionId > 0 && contributionId <= _contributionIdCounter.current(), "Chronoscribe: Invalid Contribution ID.");
        Contribution storage c = contributions[contributionId];
        require(!c.aiAppraised, "Chronoscribe: Contribution already appraised by AI.");
        require(c.isValid, "Chronoscribe: Cannot appraise an invalid contribution.");

        // In a real Chainlink integration, this would use ChainlinkClient.requestBytes
        // For simulation, we'll just assign a simple request ID
        uint256 requestId = block.timestamp + contributionId; // Simple unique ID

        c.requestAiId = requestId;
        emit AIAppraisalRequested(contributionId, requestId);
        return requestId;
    }

    /**
     * @notice Callback from the AI Oracle, providing appraisal results and suggested identity facets.
     * @dev Only callable by the designated `aiOracleAddress`.
     * @param requestId The ID of the original appraisal request.
     * @param contributionId The ID of the contribution that was appraised.
     * @param appraisalScore The AI's score for the contribution (e.g., 0-100).
     * @param narrativeImpact The AI's assessment of the contribution's narrative impact.
     * @param newFacetsToUnlock An array of facet IDs that the AI suggests unlocking for the contributor's identity.
     */
    function fulfillAIAppraisal(
        uint256 requestId,
        uint256 contributionId,
        uint256 appraisalScore,
        uint256 narrativeImpact,
        uint256[] calldata newFacetsToUnlock
    ) public whenNotPaused {
        require(msg.sender == aiOracleAddress, "Chronoscribe: Only AI Oracle can fulfill appraisals.");
        require(contributionId > 0 && contributionId <= _contributionIdCounter.current(), "Chronoscribe: Invalid Contribution ID.");
        
        Contribution storage c = contributions[contributionId];
        require(c.requestAiId == requestId, "Chronoscribe: Mismatched request ID for appraisal.");
        require(!c.aiAppraised, "Chronoscribe: Contribution already appraised.");
        require(c.isValid, "Chronoscribe: Contribution not valid for appraisal.");

        c.aiAppraisalScore = appraisalScore;
        c.narrativeImpactScore = narrativeImpact;
        c.aiAppraised = true;

        // Register the appraisal result and trigger identity updates
        _registerAIAppraisalResult(contributionId, appraisalScore, narrativeImpact, newFacetsToUnlock);

        emit AIAppraisalFulfilled(requestId, contributionId, appraisalScore, narrativeImpact, newFacetsToUnlock);
    }

    /**
     * @notice (Internal/System) Processes AI appraisal results, updates reputation, and applies new facets.
     * @dev Called internally by `fulfillAIAppraisal`.
     * @param contributionId The ID of the contribution.
     * @param appraisalScore The AI's score.
     * @param narrativeImpact The AI's narrative impact score.
     * @param newFacetsToUnlock Array of facet IDs to unlock.
     */
    function _registerAIAppraisalResult(
        uint256 contributionId,
        uint256 appraisalScore,
        uint256 narrativeImpact,
        uint256[] calldata newFacetsToUnlock
    ) internal {
        Contribution storage c = contributions[contributionId];
        uint256 contributorId = c.contributorId;

        // Accrue reputation based on appraisal score and narrative impact
        uint256 reputationPoints = (appraisalScore / 10) + (narrativeImpact / 5); // Example calculation
        _accrueReputation(contributorId, reputationPoints);

        // Unlock new facets for the contributor's identity
        for (uint256 i = 0; i < newFacetsToUnlock.length; i++) {
            setIdentityFacet(contributorId, newFacetsToUnlock[i], true);
        }
        // Optionally, update the identity's metadata hash to reflect new facets
        // updateIdentityMetadataHash(contributorId, "newHashBasedOnAIResult");
    }

    // --- IV. Reputation & Influence System ---

    /**
     * @notice Retrieves the current reputation score for a specific identity.
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     * @return The reputation score.
     */
    function getIdentityReputation(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return identities[tokenId].reputation;
    }

    /**
     * @notice Retrieves the narrative impact score assigned by the AI for a contribution.
     * @param contributionId The ID of the contribution.
     * @return The narrative impact score.
     */
    function getContributionNarrativeImpact(uint256 contributionId) public view returns (uint256) {
        require(contributionId > 0 && contributionId <= _contributionIdCounter.current(), "Chronoscribe: Invalid Contribution ID.");
        return contributions[contributionId].narrativeImpactScore;
    }

    /**
     * @notice (Internal/System) Adds reputation points to an identity.
     * @dev Called internally after successful AI appraisals or governance actions.
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     * @param points The number of reputation points to add.
     */
    function _accrueReputation(uint256 tokenId, uint256 points) internal {
        require(tokenId > 0 && tokenId <= _tokenIdCounter.current(), "Chronoscribe: Invalid Token ID.");
        identities[tokenId].reputation += points;
        emit IdentityReputationAccrued(tokenId, points);
    }

    // --- V. Governance & Community Curation ---

    /**
     * @notice Allows an identity holder to propose a direct change or evolution within the narrative/identity system.
     * @dev Requires the proposer to meet `minReputationToPropose`.
     * @param proposalType The type of proposal (e.g., NARRATIVE_EVOLUTION, PARAMETER_CHANGE).
     * @param dataHash A hash representing the details of the proposal (e.g., new facets, parameter values).
     * @param targetIdentityId Optional: If the proposal targets a specific identity (0 if not applicable).
     */
    function proposeNarrativeEvolution(
        ProposalType proposalType,
        bytes32 dataHash,
        uint256 targetIdentityId
    ) public whenNotPaused {
        require(hasMintedIdentity[msg.sender], "Chronoscribe: Only identity holders can propose.");
        uint256 proposerId = addressToTokenId[msg.sender];
        require(identities[proposerId].reputation >= minReputationToPropose, "Chronoscribe: Insufficient reputation to propose.");
        require(dataHash != bytes32(0), "Chronoscribe: Proposal data hash cannot be empty.");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposerId = proposerId;
        newProposal.creationTime = block.timestamp;
        newProposal.proposalType = proposalType;
        newProposal.dataHash = dataHash;
        newProposal.targetIdentityId = targetIdentityId;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        newProposal.passed = false;

        emit ProposalCreated(newProposalId, proposerId, proposalType);
    }

    /**
     * @notice Identity holders vote on active proposals.
     * @dev Each identity can vote once per proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        require(hasMintedIdentity[msg.sender], "Chronoscribe: Only identity holders can vote.");
        uint256 voterId = addressToTokenId[msg.sender];
        
        require(proposalId > 0 && proposalId <= _proposalIdCounter.current(), "Chronoscribe: Invalid Proposal ID.");
        Proposal storage p = proposals[proposalId];
        require(block.timestamp <= p.creationTime + PROPOSAL_VOTING_PERIOD, "Chronoscribe: Voting period has ended.");
        require(!p.executed, "Chronoscribe: Proposal already executed.");
        require(!p.hasVoted[voterId], "Chronoscribe: You have already voted on this proposal.");

        p.hasVoted[voterId] = true;
        p.totalVoters++;

        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }

        emit ProposalVoted(proposalId, voterId, support);
    }

    /**
     * @notice Executes a proposal that has met its voting thresholds after the voting period ends.
     * @dev Anyone can call this after the voting period.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        require(proposalId > 0 && proposalId <= _proposalIdCounter.current(), "Chronoscribe: Invalid Proposal ID.");
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Chronoscribe: Proposal already executed.");
        require(block.timestamp > p.creationTime + PROPOSAL_VOTING_PERIOD, "Chronoscribe: Voting period not yet ended.");

        uint256 totalEligibleVoters = _tokenIdCounter.current(); // Total minted identities
        require(totalEligibleVoters > 0, "Chronoscribe: No identities minted to vote.");

        uint256 requiredQuorum = (totalEligibleVoters * proposalQuorumPercentage) / 100;
        
        bool passed = false;
        if (p.totalVoters >= requiredQuorum && p.votesFor > p.votesAgainst) {
            passed = true;
            // Execute logic based on proposal type
            if (p.proposalType == ProposalType.NARRATIVE_EVOLUTION) {
                // Example: Unlock a specific facet for the target identity
                require(p.targetIdentityId > 0 && p.targetIdentityId <= _tokenIdCounter.current(), "Chronoscribe: Invalid target identity for narrative evolution.");
                // This `dataHash` could encode facet ID. For simplicity, let's assume `dataHash` contains a specific facet ID.
                uint256 facetToUnlock = uint256(p.dataHash); // This is a simplification, real data might be more complex
                setIdentityFacet(p.targetIdentityId, facetToUnlock, true);
                _accrueReputation(p.targetIdentityId, 50); // Reward for successful evolution
            } else if (p.proposalType == ProposalType.PARAMETER_CHANGE) {
                // Example: Change a governance parameter. Requires parsing dataHash for specific parameter.
                // This would be more complex and require a separate helper for decoding `dataHash`
                // For demonstration, let's say dataHash encodes a new minReputationToPropose.
                // This is a dangerous simplification for production!
                // minReputationToPropose = uint256(p.dataHash);
            } else if (p.proposalType == ProposalType.MODERATION_ACTION) {
                // Example: Invalidate a contribution. `dataHash` could contain contributionId.
                // For simplicity, let's assume `dataHash` contains the contribution ID.
                uint256 contributionToModerate = uint256(p.dataHash);
                if (contributionToModerate > 0 && contributionToModerate <= _contributionIdCounter.current()) {
                     contributions[contributionToModerate].isValid = false;
                     contributions[contributionToModerate].flagged = false;
                     contributions[contributionToModerate].flagReason = "Invalidated by Governance";
                }
            }
        }
        
        p.executed = true;
        p.passed = passed;
        emit ProposalExecuted(proposalId, passed);
    }

    /**
     * @notice (Admin) Sets the minimum reputation required to propose and the quorum for voting.
     * @param minReputation The new minimum reputation to propose.
     * @param quorumPercentage_ The new quorum percentage for proposals (0-100).
     */
    function setProposalThresholds(uint256 minReputation, uint256 quorumPercentage_) public onlyOwner {
        require(quorumPercentage_ <= 100, "Chronoscribe: Quorum percentage cannot exceed 100.");
        minReputationToPropose = minReputation;
        proposalQuorumPercentage = quorumPercentage_;
    }

    // --- VI. Time-Based & Event-Driven Evolution ---

    /**
     * @notice (Trusted Relayer) Advances the Chronoscribe Epoch.
     * @dev This can trigger global reassessments or general facet unlocks based on epoch.
     *      Intended to be called periodically by a trusted relayer or keeper.
     */
    function triggerEpochEvolution() public whenNotPaused {
        // This could be restricted to a specific `epochRelayer` address, or become a DAO proposal.
        // For simplicity, let's allow owner to trigger, or anyone if no specific relayer set.
        // For demonstration, restricting to owner. In a real system, Chainlink Keepers would be ideal.
        require(msg.sender == owner(), "Chronoscribe: Only owner can trigger epoch evolution."); 
        
        chronoscribeEpoch++;
        // Implement logic for global epoch-based evolution here.
        // E.g., apply global facets to all identities, or trigger background AI re-evaluations.
        // This is highly conceptual and would involve iterating over many identities, potentially
        // leading to high gas costs. A more practical approach would be batch processing or lazy evolution.
        
        emit EpochAdvanced(chronoscribeEpoch);
    }

    /**
     * @notice Returns the current Chronoscribe Epoch number.
     * @return The current epoch.
     */
    function getChronoscribeEpoch() public view returns (uint256) {
        return chronoscribeEpoch;
    }

    // --- VII. Utilities & Admin ---

    /**
     * @notice (Admin) Pauses most contract functionalities.
     * @dev Only callable by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @notice (Admin) Unpauses contract functionalities.
     * @dev Only callable by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @notice (Admin) Allows the owner to withdraw any accumulated ETH.
     * @dev Useful if contract collects fees (though not implemented in this version).
     */
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Chronoscribe: ETH withdrawal failed.");
    }

    // --- Internal Helpers ---

    /**
     * @dev Internal function to check if the caller owns the specified token.
     * @param tokenId The ID of the Chronoscribe Identity NFT.
     */
    function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "Chronoscribe: Token does not exist.");
        require(identities[tokenId].ownerAddress == msg.sender, "Chronoscribe: Caller is not the owner of this identity.");
    }
}
```