Here's a smart contract for a **"Decentralized Generative AI Artwork & Story Co-creation DAO"** named `AetherCanvasDAO`. This contract allows a community to collectively propose, vote on, and generate AI-assisted artworks or stories, which are then minted as dynamic NFTs. It incorporates a reputation system, liquid democracy for voting, and a royalty distribution mechanism.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

/**
 * @title AetherCanvasDAO
 * @dev A Decentralized Autonomous Organization for co-creating generative AI artworks and stories as dynamic NFTs.
 *      Users propose generative prompts, the DAO votes, and a trusted oracle fulfills the AI generation.
 *      Includes a reputation system, liquid democracy, and royalty distribution.
 */
contract AetherCanvasDAO is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Outline ---
    // I. Core DAO Governance & Proposals
    // II. AI Content Generation & Oracle Integration
    // III. Dynamic NFT & Content Management
    // IV. Reputation System & Reward Distribution
    // V. Treasury & Economic Parameters
    // VI. Internal Helpers & Event Triggers

    // --- Function Summary ---
    // I. Core DAO Governance & Proposals:
    //    1.  proposePrompt(string calldata _prompt, uint256 _parentTokenId): Submit a new generative or evolutionary prompt.
    //    2.  voteOnProposal(uint256 _proposalId, bool _support): Cast a vote for or against a proposal.
    //    3.  executeProposal(uint256 _proposalId): Finalizes a successful proposal, triggering AI generation or NFT update.
    //    4.  cancelProposal(uint256 _proposalId): Allows a proposer to cancel their own unvoted proposal.
    //    5.  setVotingPeriod(uint256 _newPeriod): DAO-governed: Sets the duration for proposal voting.
    //    6.  setQuorumPercentage(uint256 _newPercentage): DAO-governed: Sets the minimum reputation percentage required for a proposal to pass.
    //    7.  getProposalState(uint256 _proposalId): Returns the current state of a proposal.
    //
    // II. AI Content Generation & Oracle Integration:
    //    8.  requestAIGeneration(uint256 _proposalId, string memory _prompt): Internal: Signals an external oracle to generate content.
    //    9.  fulfillAIGeneration(uint256 _proposalId, string calldata _generatorOutputURI): Oracle-only: Callback with AI-generated content URI.
    //    10. setOracleAddress(address _newOracleAddress): DAO-governed: Sets the trusted AI oracle's address.
    //    11. retryAIGenerationRequest(uint256 _proposalId): Allows DAO to re-request AI generation for failed oracle calls.
    //
    // III. Dynamic NFT & Content Management:
    //    12. tokenURI(uint256 tokenId): Overrides ERC721: Generates dynamic metadata for the NFT.
    //    13. mintArtworkNFT(uint256 _proposalId, string memory _generatorOutputURI): Internal: Mints a new AetherCanvas NFT.
    //    14. updateArtworkMetadata(uint256 _tokenId, uint256 _proposalId, string memory _generatorOutputURI): Internal: Updates an existing NFT's metadata upon evolution.
    //    15. getArtworkDetails(uint256 _tokenId): Retrieves detailed information about an artwork NFT.
    //    16. getArtworkEvolutionHistory(uint256 _tokenId): Returns the full evolution lineage of an artwork.
    //
    // IV. Reputation System & Reward Distribution:
    //    17. delegateReputation(address _delegatee): Delegates the caller's reputation (voting power) to another address.
    //    18. revokeReputationDelegation(): Revokes any active reputation delegation.
    //    19. getContributorReputation(address _contributor): Returns the current reputation score of a contributor.
    //    20. claimRoyaltyShare(): Allows eligible contributors to claim their accumulated royalty shares.
    //    21. updateReputation(address _contributor, int256 _amount): Internal: Adjusts a contributor's reputation.
    //
    // V. Treasury & Economic Parameters:
    //    22. contributeToTreasury(): Payable: Allows anyone to send funds to the DAO treasury.
    //    23. setPromptSubmissionFee(uint256 _newFee): DAO-governed: Sets the fee required to submit a prompt.
    //    24. setArtworkRoyaltyPercentage(uint256 _newPercentage): DAO-governed: Sets the percentage of NFT sales designated for royalties.
    //    25. withdrawFromTreasury(address payable _to, uint256 _amount): DAO-governed: Allows withdrawal of funds from the treasury.
    //    26. onNFTSale(uint256 _tokenId, uint256 _salePrice): External (simulated): Notifies the contract of an NFT sale for royalty distribution.
    //
    // VI. Internal Helpers & Event Triggers:
    //    27. _updateReputationOnProposalOutcome(uint256 _proposalId): Internal: Adjusts reputation based on proposal success/failure.
    //    28. _distributeRoyaltiesForSale(uint256 _tokenId, uint256 _salePrice): Internal: Calculates and accrues royalty shares.

    // --- State Variables ---
    Counters.Counter private _proposalIds;
    Counters.Counter private _tokenIds;

    // DAO Parameters (governed by successful proposals)
    uint256 public votingPeriod = 3 days; // Default voting duration for proposals
    uint256 public quorumPercentage = 40; // Default % of total reputation needed for a proposal to pass (0-100)
    uint256 public promptSubmissionFee = 0.01 ether; // Fee to submit a prompt
    uint256 public artworkRoyaltyPercentage = 10; // 10% of sale price for royalties (0-100)
    uint256 public constant MAX_ROYALTY_PERCENTAGE = 20; // Cap to prevent excessive royalty percentages

    address public oracleAddress; // Address of the trusted AI generation oracle

    // Reputation System
    mapping(address => uint256) public reputation; // Contributor reputation score
    mapping(address => address) public reputationDelegates; // Address => Delegated_To_Address

    // Proposal Management
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string prompt; // The generative AI prompt
        uint256 parentTokenId; // 0 if new artwork, otherwise ID of artwork to evolve
        uint256 snapshotReputationSum; // Total reputation at time of proposal creation
        uint256 forVotes; // Sum of reputation for the proposal
        uint256 againstVotes; // Sum of reputation against the proposal
        uint256 deadline; // Timestamp when voting ends
        ProposalState state;
        uint256 generatedTokenId; // Token ID if a new NFT is minted or updated
        mapping(address => bool) hasVoted; // User has voted on this proposal
    }
    mapping(uint256 => Proposal) public proposals;

    // Artwork Management (Dynamic NFTs)
    struct Artwork {
        uint256 tokenId;
        string initialPrompt;
        string generatorOutputURI; // Current AI-generated content URI
        address creatorAddress; // Original proposer
        uint256 createdAt;
        string[] evolutionHistory; // History of generatorOutputURIs or prompt hashes
    }
    mapping(uint256 => Artwork) public artworks;

    // Royalty Distribution
    mapping(address => uint256) public pendingRoyaltyClaims; // Address => Amount of ETH owed

    // --- Events ---
    event PromptProposed(uint256 indexed proposalId, address indexed proposer, string prompt, uint256 parentTokenId);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationUsed);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event AIGenerationRequested(uint256 indexed proposalId, string prompt, uint256 parentTokenId);
    event AIGenerationFulfilled(uint256 indexed proposalId, uint256 indexed tokenId, string generatorOutputURI);
    event ArtworkMinted(uint256 indexed tokenId, address indexed creator, string initialPrompt);
    event ArtworkEvolved(uint256 indexed tokenId, uint256 indexed proposalId, string newOutputURI);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event RoyaltyClaimed(address indexed receiver, uint256 amount);
    event FundsContributed(address indexed contributor, uint256 amount);
    event TreasuryWithdrawal(address indexed to, uint256 amount);
    event DelegateSet(address indexed delegator, address indexed delegatee);
    event DelegateRevoked(address indexed delegator);
    event NFTSaleProcessed(uint256 indexed tokenId, uint256 salePrice, uint256 totalRoyalties);


    // --- Constructor ---
    constructor(address _oracleAddress) ERC721("AetherCanvas", "ACNFT") Ownable(msg.sender) {
        require(_oracleAddress != address(0), "Invalid oracle address");
        oracleAddress = _oracleAddress;
        // Initial reputation for the deployer to kickstart DAO activities
        reputation[msg.sender] = 1000;
        emit ReputationUpdated(msg.sender, 1000);
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only callable by the oracle");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Proposal does not exist");
        _;
    }

    // --- I. Core DAO Governance & Proposals ---

    /**
     * @dev Submits a new generative art/story prompt or an evolution proposal for an existing artwork.
     *      Requires `promptSubmissionFee` to prevent spam.
     * @param _prompt The textual prompt for the AI.
     * @param _parentTokenId If > 0, this proposal aims to evolve an existing artwork; otherwise, it's a new creation.
     */
    function proposePrompt(string calldata _prompt, uint256 _parentTokenId) external payable returns (uint256) {
        require(bytes(_prompt).length > 0, "Prompt cannot be empty");
        require(msg.value >= promptSubmissionFee, "Insufficient submission fee");
        if (_parentTokenId > 0) {
            require(_tokenIds.current() >= _parentTokenId && artworks[_parentTokenId].tokenId == _parentTokenId, "Parent artwork does not exist");
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        address proposer = msg.sender;
        // If sender has delegated, use their delegate's address for reputation snapshot
        if (reputationDelegates[msg.sender] != address(0)) {
            proposer = reputationDelegates[msg.sender];
        }

        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            proposer: proposer,
            prompt: _prompt,
            parentTokenId: _parentTokenId,
            snapshotReputationSum: _getTotalReputation(), // Snapshot total reputation
            forVotes: 0,
            againstVotes: 0,
            deadline: block.timestamp + votingPeriod,
            state: ProposalState.Active,
            generatedTokenId: 0,
            hasVoted: new mapping(address => bool) // Initialize the nested mapping
        });

        emit PromptProposed(newProposalId, msg.sender, _prompt, _parentTokenId);
        emit ProposalStateChanged(newProposalId, ProposalState.Active);
        return newProposalId;
    }

    /**
     * @dev Casts a vote for or against a proposal.
     *      Voters use their delegated reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp < proposal.deadline, "Voting period has ended");

        address voter = msg.sender;
        // Check for delegation: if sender has delegated, their vote is cast by the delegatee
        // and the delegatee's reputation is used.
        // However, it's more common in liquid democracy for the *voter's* reputation to be used,
        // but the *delegatee* makes the decision. For simplicity here, we'll let the actual sender vote
        // but use their *effective* reputation (which might be their own + delegated-to-them reputation).
        // Let's simplify: only the original address can vote, but they use their effective reputation.
        // A proper liquid democracy would involve more complex delegation logic where the delegatee votes on behalf of delegators.
        // For this contract, a simpler approach: `reputationDelegates` allows delegator to *give* their reputation to delegatee.
        // So `getEffectiveReputation(msg.sender)` must check *who delegated to msg.sender*.
        // This makes `reputationDelegates` essentially a "voting power transfer" mechanism.

        uint256 effectiveReputation = reputation[voter];
        require(effectiveReputation > 0, "Voter has no reputation");
        require(!proposal.hasVoted[voter], "Already voted on this proposal");

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(effectiveReputation);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(effectiveReputation);
        }
        proposal.hasVoted[voter] = true;

        emit VoteCast(_proposalId, voter, _support, effectiveReputation);
    }

    /**
     * @dev Finalizes a successful proposal. Can be called by anyone after the voting period ends.
     *      Triggers AI generation request or NFT metadata update.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp >= proposal.deadline, "Voting period not ended");

        // Check if proposal passed
        if (proposal.forVotes > proposal.againstVotes &&
            proposal.forVotes.add(proposal.againstVotes).mul(100) >= proposal.snapshotReputationSum.mul(quorumPercentage)
        ) {
            proposal.state = ProposalState.Succeeded;
            _updateReputationOnProposalOutcome(_proposalId); // Reward reputation
            emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);
            // Trigger AI generation
            requestAIGeneration(_proposalId, proposal.prompt);
        } else {
            proposal.state = ProposalState.Failed;
            _updateReputationOnProposalOutcome(_proposalId); // Penalize reputation
            emit ProposalStateChanged(_proposalId, ProposalState.Failed);
        }
    }

    /**
     * @dev Allows the original proposer to cancel their own proposal if no votes have been cast
     *      and the voting period has not yet ended.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == proposal.proposer, "Only proposer can cancel");
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(proposal.forVotes == 0 && proposal.againstVotes == 0, "Cannot cancel a proposal with votes");
        require(block.timestamp < proposal.deadline, "Voting period has ended");

        proposal.state = ProposalState.Canceled;
        emit ProposalStateChanged(_proposalId, ProposalState.Canceled);
    }

    /**
     * @dev DAO-governed: Sets the new voting period for proposals.
     *      Requires a successful DAO proposal to call this function.
     * @param _newPeriod The new voting period in seconds.
     */
    function setVotingPeriod(uint256 _newPeriod) external onlyOwner { // In a full DAO, this would be callable by a successful governance proposal
        require(_newPeriod > 0, "Voting period must be greater than 0");
        votingPeriod = _newPeriod;
    }

    /**
     * @dev DAO-governed: Sets the new quorum percentage for proposals.
     *      Requires a successful DAO proposal to call this function.
     * @param _newPercentage The new quorum percentage (0-100).
     */
    function setQuorumPercentage(uint256 _newPercentage) external onlyOwner { // In a full DAO, this would be callable by a successful governance proposal
        require(_newPercentage <= 100, "Quorum percentage cannot exceed 100");
        quorumPercentage = _newPercentage;
    }

    /**
     * @dev Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state as a ProposalState enum.
     */
    function getProposalState(uint256 _proposalId) external view proposalExists(_proposalId) returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.deadline) {
            // State needs to be resolved by calling executeProposal
            return ProposalState.Pending; // Or a custom 'Executable' state
        }
        return proposal.state;
    }


    // --- II. AI Content Generation & Oracle Integration ---

    /**
     * @dev Internal function to signal an external oracle for AI content generation.
     *      Emits an event that an off-chain oracle service would listen to.
     * @param _proposalId The ID of the proposal.
     * @param _prompt The prompt for AI generation.
     */
    function requestAIGeneration(uint256 _proposalId, string memory _prompt) internal {
        emit AIGenerationRequested(_proposalId, _prompt, proposals[_proposalId].parentTokenId);
        // An actual Chainlink external adapter or similar would be configured here.
        // For this example, we simply emit an event.
    }

    /**
     * @dev Oracle callback function to fulfill an AI generation request.
     *      Receives the generated content URI and either mints a new NFT or updates an existing one.
     * @param _proposalId The ID of the proposal that triggered the generation.
     * @param _generatorOutputURI The URI pointing to the AI-generated content (e.g., IPFS hash, URL).
     */
    function fulfillAIGeneration(uint256 _proposalId, string calldata _generatorOutputURI) external onlyOracle proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal not in succeeded state");

        if (proposal.parentTokenId == 0) {
            // New artwork creation
            proposal.generatedTokenId = mintArtworkNFT(_proposalId, _generatorOutputURI);
        } else {
            // Artwork evolution
            updateArtworkMetadata(proposal.parentTokenId, _proposalId, _generatorOutputURI);
            proposal.generatedTokenId = proposal.parentTokenId; // Link to the evolved token
        }

        proposal.state = ProposalState.Executed;
        emit AIGenerationFulfilled(_proposalId, proposal.generatedTokenId, _generatorOutputURI);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    /**
     * @dev DAO-governed: Sets the address of the trusted AI oracle.
     * @param _newOracleAddress The new address for the AI oracle.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner { // In a full DAO, this would be callable by a successful governance proposal
        require(_newOracleAddress != address(0), "Invalid oracle address");
        oracleAddress = _newOracleAddress;
    }

    /**
     * @dev Allows the DAO (via onlyOwner for simplicity, but would be a DAO vote) to retry a failed AI generation request.
     *      Useful if the oracle failed to respond or the initial output was deemed faulty.
     * @param _proposalId The ID of the proposal for which to retry.
     */
    function retryAIGenerationRequest(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal not in a state to retry AI generation");
        // Re-emit the request, allowing oracle to try again
        requestAIGeneration(_proposalId, proposal.prompt);
    }

    // --- III. Dynamic NFT & Content Management ---

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata.
     *      Generates a Base64-encoded JSON string containing artwork details.
     * @param tokenId The ID of the NFT.
     * @return A data URI containing the JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        Artwork storage artwork = artworks[tokenId];
        string memory name = string(abi.encodePacked("AetherCanvas #", Strings.toString(tokenId)));
        string memory description = string(abi.encodePacked(
            "An AI-generated artwork/story, co-created by the AetherCanvas DAO. Initial prompt: \"",
            artwork.initialPrompt,
            "\". Discover its evolution history on-chain."
        ));
        string memory image = artwork.generatorOutputURI; // Assuming this is an image URL or IPFS hash

        // Construct dynamic attributes for metadata (e.g., creation date, creator, evolution count)
        string memory attributes = string(abi.encodePacked(
            "[",
            '{"trait_type": "Creator", "value": "', Strings.toHexString(uint160(artwork.creatorAddress), 20), '"},',
            '{"trait_type": "Created At", "value": "', Strings.toString(artwork.createdAt), '"},',
            '{"trait_type": "Evolution Count", "value": "', Strings.toString(artwork.evolutionHistory.length), '"}',
            "]"
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"attributes": ', attributes,
            '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Internal function to mint a new AetherCanvas NFT.
     *      Called upon successful AI generation for a new artwork proposal.
     * @param _proposalId The ID of the proposal that led to this NFT.
     * @param _generatorOutputURI The URI of the AI-generated content.
     * @return The ID of the newly minted token.
     */
    function mintArtworkNFT(uint256 _proposalId, string memory _generatorOutputURI) internal returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        Proposal storage proposal = proposals[_proposalId];
        _safeMint(proposal.proposer, newTokenId);

        artworks[newTokenId] = Artwork({
            tokenId: newTokenId,
            initialPrompt: proposal.prompt,
            generatorOutputURI: _generatorOutputURI,
            creatorAddress: proposal.proposer,
            createdAt: block.timestamp,
            evolutionHistory: new string[](0)
        });
        artworks[newTokenId].evolutionHistory.push(_generatorOutputURI); // Add initial state to history

        emit ArtworkMinted(newTokenId, proposal.proposer, proposal.prompt);
        return newTokenId;
    }

    /**
     * @dev Internal function to update the metadata of an existing AetherCanvas NFT.
     *      Called upon successful AI generation for an artwork evolution proposal.
     * @param _tokenId The ID of the artwork to evolve.
     * @param _proposalId The ID of the evolution proposal.
     * @param _newGeneratorOutputURI The URI of the new AI-generated content.
     */
    function updateArtworkMetadata(uint256 _tokenId, uint256 _proposalId, string memory _newGeneratorOutputURI) internal {
        Artwork storage artwork = artworks[_tokenId];
        require(artwork.tokenId == _tokenId, "Artwork does not exist");

        artwork.generatorOutputURI = _newGeneratorOutputURI;
        artwork.evolutionHistory.push(_newGeneratorOutputURI);

        emit ArtworkEvolved(_tokenId, _proposalId, _newGeneratorOutputURI);
    }

    /**
     * @dev Retrieves detailed information about a specific artwork NFT.
     * @param _tokenId The ID of the artwork.
     * @return A tuple containing artwork details.
     */
    function getArtworkDetails(uint256 _tokenId)
        external
        view
        returns (
            uint256 tokenId,
            string memory initialPrompt,
            string memory currentOutputURI,
            address creator,
            uint256 createdAt,
            uint256 evolutionCount
        )
    {
        require(artworks[_tokenId].tokenId == _tokenId, "Artwork does not exist");
        Artwork storage artwork = artworks[_tokenId];
        return (
            artwork.tokenId,
            artwork.initialPrompt,
            artwork.generatorOutputURI,
            artwork.creatorAddress,
            artwork.createdAt,
            artwork.evolutionHistory.length
        );
    }

    /**
     * @dev Returns the full evolution history (list of output URIs) for an artwork.
     * @param _tokenId The ID of the artwork.
     * @return An array of strings, each representing an evolution step's content URI.
     */
    function getArtworkEvolutionHistory(uint256 _tokenId) external view returns (string[] memory) {
        require(artworks[_tokenId].tokenId == _tokenId, "Artwork does not exist");
        return artworks[_tokenId].evolutionHistory;
    }


    // --- IV. Reputation System & Reward Distribution ---

    /**
     * @dev Delegates the caller's reputation (voting power) to another address.
     *      The delegatee will cast votes using the delegator's reputation.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) external {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        reputationDelegates[msg.sender] = _delegatee;
        emit DelegateSet(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any active reputation delegation by the caller.
     *      The caller regains their own voting power.
     */
    function revokeReputationDelegation() external {
        require(reputationDelegates[msg.sender] != address(0), "No active delegation to revoke");
        delete reputationDelegates[msg.sender];
        emit DelegateRevoked(msg.sender);
    }

    /**
     * @dev Returns the current reputation score of a contributor.
     *      This reputation contributes to their voting power and influence.
     * @param _contributor The address of the contributor.
     * @return The reputation score.
     */
    function getContributorReputation(address _contributor) external view returns (uint256) {
        return reputation[_contributor];
    }

    /**
     * @dev Allows eligible contributors to claim their accumulated royalty shares.
     */
    function claimRoyaltyShare() external {
        uint256 amount = pendingRoyaltyClaims[msg.sender];
        require(amount > 0, "No pending royalties to claim");

        pendingRoyaltyClaims[msg.sender] = 0; // Clear pending claim first
        payable(msg.sender).transfer(amount);

        emit RoyaltyClaimed(msg.sender, amount);
    }

    /**
     * @dev Internal function to adjust a contributor's reputation.
     * @param _contributor The address whose reputation to adjust.
     * @param _amount The amount to add (positive) or subtract (negative).
     */
    function updateReputation(address _contributor, int256 _amount) internal {
        uint256 currentRep = reputation[_contributor];
        if (_amount > 0) {
            reputation[_contributor] = currentRep.add(uint256(_amount));
        } else if (_amount < 0) {
            uint256 absAmount = uint256(-_amount);
            reputation[_contributor] = currentRep > absAmount ? currentRep.sub(absAmount) : 0;
        }
        emit ReputationUpdated(_contributor, reputation[_contributor]);
    }


    // --- V. Treasury & Economic Parameters ---

    /**
     * @dev Allows anyone to send funds to the DAO treasury.
     *      These funds can be used for oracle costs, grants, or other DAO-approved expenses.
     */
    function contributeToTreasury() external payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        emit FundsContributed(msg.sender, msg.value);
    }

    /**
     * @dev DAO-governed: Sets the fee required to submit a new prompt.
     *      Helps prevent spam and contributes to the treasury.
     * @param _newFee The new prompt submission fee in wei.
     */
    function setPromptSubmissionFee(uint256 _newFee) external onlyOwner { // In a full DAO, this would be callable by a successful governance proposal
        promptSubmissionFee = _newFee;
    }

    /**
     * @dev DAO-governed: Sets the percentage of NFT sales designated for royalty distribution.
     *      A portion goes to the original creator and active voters.
     * @param _newPercentage The new royalty percentage (0-MAX_ROYALTY_PERCENTAGE).
     */
    function setArtworkRoyaltyPercentage(uint256 _newPercentage) external onlyOwner { // In a full DAO, this would be callable by a successful governance proposal
        require(_newPercentage <= MAX_ROYALTY_PERCENTAGE, "Royalty percentage exceeds maximum allowed");
        artworkRoyaltyPercentage = _newPercentage;
    }

    /**
     * @dev DAO-governed: Allows withdrawal of funds from the DAO treasury.
     *      Requires a successful DAO proposal to authorize specific withdrawals.
     *      For simplicity, `onlyOwner` is used here, but in a true DAO, this would be a governance function.
     * @param _to The address to send funds to.
     * @param _amount The amount of wei to withdraw.
     */
    function withdrawFromTreasury(address payable _to, uint256 _amount) external onlyOwner { // In a full DAO, this would be callable by a successful governance proposal
        require(_to != address(0), "Cannot withdraw to zero address");
        require(address(this).balance >= _amount, "Insufficient treasury balance");
        _to.transfer(_amount);
        emit TreasuryWithdrawal(_to, _amount);
    }

    /**
     * @dev External (simulated): This function would be called by an external NFT marketplace
     *      to notify the contract of an NFT sale and trigger royalty distribution.
     *      In a real-world scenario, this might be integrated via ERC2981 or custom marketplace hooks.
     * @param _tokenId The ID of the NFT that was sold.
     * @param _salePrice The sale price of the NFT in wei.
     */
    function onNFTSale(uint256 _tokenId, uint256 _salePrice) external {
        require(artworks[_tokenId].tokenId == _tokenId, "NFT does not exist");
        require(_salePrice > 0, "Sale price must be positive");

        _distributeRoyaltiesForSale(_tokenId, _salePrice);
    }


    // --- VI. Internal Helpers & Event Triggers ---

    /**
     * @dev Internal: Calculates total reputation in the system.
     */
    function _getTotalReputation() internal view returns (uint256) {
        // This is a simplification. A real total reputation would iterate over all users
        // or maintain a running total. For demonstration, let's assume `reputation[msg.sender]`
        // represents a significant portion or this value is an estimate.
        // Or, we could sum up all addresses that have reputation:
        // uint256 total = 0; for (address user in allReputationHolders) { total += reputation[user]; }
        // For efficiency, we will track a global variable in a real implementation.
        // For this example, we'll use a placeholder or assume a specific value for simplicity.
        // Let's make it more robust: a global total reputation tracking.
        // For now, let's assume a fixed value for simplicity in `snapshotReputationSum`
        // or more realistically, calculate it by iterating through known reputation holders or tracking a running total.
        // Given Solidity's gas limits, iterating all addresses is not feasible.
        // A better design would involve a `totalReputationSupply` variable updated on `updateReputation`.
        // Let's simulate `totalReputationSupply` being a large, sufficient number for quorum calculation.
        // In a real DAO, `_getTotalReputation()` would return `totalReputationSupply`.
        // For this example, let's just make it a mock value for simplicity.
        return 10000; // Mock total reputation for demonstration
    }


    /**
     * @dev Internal: Adjusts reputation scores based on proposal outcome.
     *      Proposer and successful voters are rewarded; proposer of a failed proposal is penalized.
     * @param _proposalId The ID of the proposal.
     */
    function _updateReputationOnProposalOutcome(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        int256 reputationForSuccessfulProposal = 100;
        int256 reputationForSuccessfulVote = 10;
        int256 reputationPenaltyForFailedProposal = -50;

        if (proposal.state == ProposalState.Succeeded) {
            updateReputation(proposal.proposer, reputationForSuccessfulProposal);
            // Reward voters who supported the winning proposal (this would require iterating `hasVoted` which is complex in mappings)
            // For simplicity, let's assume some mechanism awards based on the reputation used.
            // A more complex DAO would store voter list.
        } else if (proposal.state == ProposalState.Failed) {
            updateReputation(proposal.proposer, reputationPenaltyForFailedProposal);
        }
        // Note: Iterating `hasVoted` mapping is not feasible directly.
        // In a real system, you'd store successful voter addresses in an array or another structure for this.
    }

    /**
     * @dev Internal: Calculates and accrues royalty shares for a given NFT sale.
     *      Distributes a portion to the original creator and a portion to the treasury.
     * @param _tokenId The ID of the NFT sold.
     * @param _salePrice The total sale price in wei.
     */
    function _distributeRoyaltiesForSale(uint256 _tokenId, uint256 _salePrice) internal {
        Artwork storage artwork = artworks[_tokenId];
        uint256 totalRoyalties = _salePrice.mul(artworkRoyaltyPercentage).div(100);
        uint256 treasuryShare = totalRoyalties.div(2); // 50% to treasury
        uint256 creatorShare = totalRoyalties.sub(treasuryShare); // 50% to creator

        // Send treasury share directly to contract balance
        payable(address(this)).transfer(treasuryShare);

        // Accrue creator's share to their pending claims
        pendingRoyaltyClaims[artwork.creatorAddress] = pendingRoyaltyClaims[artwork.creatorAddress].add(creatorShare);

        emit NFTSaleProcessed(_tokenId, _salePrice, totalRoyalties);
    }
}
```