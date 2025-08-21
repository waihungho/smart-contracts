The following Solidity smart contract, `SynthosAI`, is designed as a decentralized platform for AI-powered narrative and digital asset synthesis. It introduces a novel concept where users can initiate AI synthesis requests, either to generate new "Chronicle Artefact" NFTs or to evolve existing ones, creating dynamic, living digital assets. The contract integrates a simplified oracle system for off-chain AI inference, a basic reputation mechanism for AI agents, and a unique "narrative linking" feature allowing community-governed connections between digital artefacts.

It avoids direct duplication of any single existing open-source project by combining several advanced concepts (AI interaction, dynamic NFTs, on-chain governance for narrative, basic oracle reputation) into a cohesive, creative, and trending use case.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SynthosAI
 * @dev A Decentralized AI-Powered Narrative & Digital Asset Synthesis Platform.
 *      This contract enables users to submit prompts for AI synthesis, creating dynamic
 *      "Chronicle Artefact" NFTs or public narrative fragments. AI inference is performed
 *      off-chain by whitelisted "Aether Oracles," with results submitted back on-chain.
 *      The platform also explores concepts of narrative linking and decentralized AI reputation.
 *
 * Outline & Function Summary:
 *
 * I. Core Platform Configuration & Administration (Ownable)
 *    1. `constructor()`: Initializes the contract with an ERC721 name and symbol ("Chronicle Artefact", "CHRON").
 *    2. `setPaymentToken(address _tokenAddress)`: Sets the ERC20 token address that will be accepted for all payments (e.g., synthesis fees).
 *    3. `setSynthesisFee(uint256 _fee)`: Sets the amount of `paymentToken` required for each AI synthesis request.
 *    4. `addWhitelistedAetherOracle(address _oracleAddress)`: Adds an address to the whitelist, allowing it to fulfill AI synthesis requests.
 *    5. `removeWhitelistedAetherOracle(address _oracleAddress)`: Removes an address from the whitelist of trusted AI oracles.
 *    6. `pauseContract()`: Pauses all user-facing functionalities (e.g., requests, minting, voting) in case of an emergency.
 *    7. `unpauseContract()`: Unpauses the contract, restoring normal operations.
 *    8. `withdrawFunds()`: Allows the contract owner to withdraw accumulated `paymentToken` fees from the contract.
 *    9. `setMinVotesForLink(uint256 _minVotes)`: Sets the minimum number of 'for' votes required for a narrative link proposal to be executed.
 *
 * II. AI Synthesis Request & Fulfillment
 *    10. `initiateSynthesisRequest(string calldata _prompt, uint256 _chronicleIdToEvolve)`:
 *        Allows a user to submit a text prompt for AI processing.
 *        - If `_chronicleIdToEvolve` is 0, a new public narrative fragment will be created upon fulfillment.
 *        - If `_chronicleIdToEvolve` is a valid existing Chronicle Artefact ID, the request is for evolving that specific NFT's metadata.
 *        Requires payment of `synthesisFee` in the configured `paymentToken`.
 *    11. `fulfillSynthesisRequest(uint256 _requestId, string calldata _metadataURI, string calldata _contentHash)`:
 *        Called by a whitelisted Aether Oracle to submit the AI-generated output for a previously initiated request.
 *        - `_metadataURI`: The URI (e.g., IPFS link) to the JSON metadata conforming to ERC721 standard.
 *        - `_contentHash`: A hash (e.g., IPFS hash) of the actual AI-generated content (e.g., text, image data).
 *        Updates the request status and, if applicable, the associated NFT's metadata.
 *    12. `getSynthesisRequest(uint256 _requestId)`: Retrieves comprehensive details about a specific synthesis request.
 *
 * III. Chronicle Artefact (Dynamic NFTs) Management (ERC721-based)
 *    13. `mintChronicleArtefact(uint256 _requestId)`:
 *        Allows the original requester to mint a new Chronicle Artefact NFT, provided the synthesis request
 *        was fulfilled and was intended for a new (not evolving) artefact.
 *    14. `tokenURI(uint256 tokenId)`: Overrides the standard ERC721 `tokenURI` function to return the *current* metadata URI for a Chronicle Artefact, which can change upon evolution.
 *    15. `getChronicleEvolutionCount(uint256 _chronicleId)`: Returns the number of times a specific Chronicle Artefact has had its metadata evolved by AI synthesis.
 *    16. `getChronicleOwner(uint256 _chronicleId)`: Returns the current owner address of a specific Chronicle Artefact. (Wrapper around ERC721's `ownerOf`).
 *
 * IV. Narrative Linking & Discovery
 *    17. `proposeNarrativeLink(uint256 _chronicleIdA, uint256 _chronicleIdB, string calldata _reason)`:
 *        Allows an owner of two Chronicle Artefacts to propose a conceptual link between them, providing a textual reason.
 *        This creates a new, pending narrative link proposal for community vote.
 *    18. `voteOnNarrativeLink(uint256 _proposalId, bool _approve)`:
 *        Allows other Chronicle Artefact owners (excluding the proposer or owners of the linked NFTs) to vote on a pending narrative link proposal.
 *    19. `executeNarrativeLink(uint256 _proposalId)`:
 *        Finalizes a narrative link proposal if it has reached the `minVotesForLink` threshold.
 *        Upon execution, the `linkedChronicles` array for both NFTs is updated to reflect the new connection.
 *    20. `getNarrativeLinkProposal(uint256 _proposalId)`: Retrieves detailed information about a specific narrative link proposal.
 *    21. `getLinkedChronicles(uint256 _chronicleId)`: Returns an array of Chronicle Artefact IDs that are formally linked to a given artefact.
 *
 * V. AI Oracle Reputation & Statistics (Simplified)
 *    22. `submitAetherOracleRating(address _oracleAddress, uint8 _rating)`:
 *        Allows any user to submit a rating (1-5) for a whitelisted Aether Oracle's performance.
 *        This contributes to the oracle's simplified reputation score.
 *    23. `getAetherOracleAverageRating(address _oracleAddress)`: Retrieves the calculated average rating for a given Aether Oracle.
 *    24. `getAetherOracleSuccessfulFulfillments(address _oracleAddress)`: Returns the total count of successfully fulfilled synthesis requests by an oracle.
 *    25. `getAetherOracleTotalFulfillments(address _oracleAddress)`: Returns the total count of all fulfillment attempts (successful or otherwise) by an oracle.
 */
contract SynthosAI is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter; // Manages unique token IDs for Chronicle Artefacts

    IERC20 public paymentToken; // ERC20 token used for payments
    uint256 public synthesisFee; // Fee for initiating synthesis requests

    // Whitelisted Aether Oracles (addresses that can fulfill requests)
    mapping(address => bool) public isWhitelistedAetherOracle;

    // Pausability status
    bool public paused;

    // --- Request Management ---

    struct SynthesisRequest {
        address requester;          // Address of the user who initiated the request
        string prompt;              // The text prompt submitted for AI synthesis
        uint256 chronicleIdToEvolve; // 0 if creating a new artefact/fragment, otherwise the ID of the NFT to evolve
        string metadataURI;         // AI-generated output: URI to ERC721 metadata JSON
        string contentHash;         // AI-generated output: Hash of the raw content (e.g., IPFS hash of text/image)
        bool fulfilled;             // True if the request has been fulfilled by an oracle
        address fulfiller;          // The oracle address that fulfilled the request
        uint256 timestamp;          // Timestamp when the request was initiated
        bool minted;                // True if a new NFT has been minted from this request (only applicable if chronicleIdToEvolve was 0)
    }

    uint256 public nextRequestId; // Counter for unique synthesis request IDs
    mapping(uint256 => SynthesisRequest) public synthesisRequests; // Stores all synthesis requests

    // Mapping to prevent multiple pending evolution requests for the same Chronicle Artefact
    mapping(uint256 => uint256) internal _pendingRequestForChronicle; // chronicleId => requestId

    // --- Chronicle Artefact (NFT) Details ---

    // Custom data stored for each Chronicle Artefact NFT
    struct ChronicleData {
        uint256 evolutionCount;     // Number of times this artefact's metadata has been evolved
        string currentMetadataURI;  // The current metadata URI for this artefact
        uint256[] linkedChronicles; // Array of other Chronicle Artefact IDs linked to this one
    }

    mapping(uint256 => ChronicleData) internal _chronicleData; // Stores custom data for each NFT

    // --- Narrative Linking ---

    struct NarrativeLinkProposal {
        address proposer;           // The address that proposed the link
        uint256 chronicleIdA;       // ID of the first Chronicle Artefact in the link
        uint256 chronicleIdB;       // ID of the second Chronicle Artefact in the link
        string reason;              // Textual reason/justification for the proposed link
        uint256 votesFor;           // Count of 'for' votes
        uint256 votesAgainst;       // Count of 'against' votes
        mapping(address => bool) hasVoted; // Tracks addresses that have voted on this proposal
        bool executed;              // True if the link has been formally established
        bool active;                // True if the proposal is still open for voting/execution
        uint256 timestamp;          // Timestamp when the proposal was created
    }

    uint256 public nextProposalId;  // Counter for unique narrative link proposal IDs
    mapping(uint256 => NarrativeLinkProposal) public narrativeLinkProposals; // Stores all link proposals
    uint256 public minVotesForLink; // Minimum 'for' votes required to execute a narrative link

    // --- Aether Oracle Reputation (Simplified) ---

    struct OracleReputation {
        uint256 totalRatings;           // Total number of ratings received
        uint256 sumOfRatings;           // Sum of all ratings (for average calculation)
        uint256 successfulFulfillments; // Count of requests successfully fulfilled by this oracle
        uint256 totalFulfillments;      // Total count of all requests attempted by this oracle (successful or not)
    }

    mapping(address => OracleReputation) public aetherOracleReputation; // Stores reputation data for each oracle

    // --- Events ---

    event PaymentTokenSet(address indexed _tokenAddress);
    event SynthesisFeeSet(uint256 _fee);
    event AetherOracleWhitelisted(address indexed _oracleAddress);
    event AetherOracleRemoved(address indexed _oracleAddress);
    event ContractPaused();
    event ContractUnpaused();
    event FundsWithdrawn(address indexed _to, uint256 _amount);
    event SynthesisRequestInitiated(uint256 indexed _requestId, address indexed _requester, string _prompt, uint256 _chronicleIdToEvolve);
    event SynthesisRequestFulfilled(uint256 indexed _requestId, address indexed _fulfiller, string _metadataURI, string _contentHash);
    event ChronicleArtefactMinted(uint256 indexed _chronicleId, address indexed _owner, string _metadataURI);
    event ChronicleArtefactEvolved(uint256 indexed _chronicleId, uint256 _newEvolutionCount, string _newMetadataURI);
    event NarrativeLinkProposed(uint256 indexed _proposalId, uint256 indexed _chronicleIdA, uint256 indexed _chronicleIdB, address indexed _proposer);
    event NarrativeLinkVoted(uint256 indexed _proposalId, address indexed _voter, bool _approved);
    event NarrativeLinkExecuted(uint256 indexed _proposalId, uint256 indexed _chronicleIdA, uint256 indexed _chronicleIdB);
    event AetherOracleRatingSubmitted(address indexed _oracleAddress, address indexed _rater, uint8 _rating);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyWhitelistedAetherOracle() {
        require(isWhitelistedAetherOracle[msg.sender], "Caller is not a whitelisted Aether Oracle");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("Chronicle Artefact", "CHRON") Ownable(msg.sender) {
        paused = false;
        nextRequestId = 1;
        nextProposalId = 1;
        synthesisFee = 1 ether; // Default fee (e.g., 10^18 units of paymentToken), can be changed by owner
        minVotesForLink = 3;    // Default minimum 'for' votes for a narrative link, can be changed by owner
    }

    // --- I. Core Platform Configuration & Administration (Ownable) ---

    /**
     * @dev Sets the ERC20 token address to be used for all payments (e.g., synthesis fees).
     *      Only callable by the contract owner.
     * @param _tokenAddress The address of the ERC20 token contract.
     */
    function setPaymentToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        paymentToken = IERC20(_tokenAddress);
        emit PaymentTokenSet(_tokenAddress);
    }

    /**
     * @dev Sets the fee required to initiate a synthesis request.
     *      The fee is denominated in the `paymentToken`. Only callable by the contract owner.
     * @param _fee The new synthesis fee amount.
     */
    function setSynthesisFee(uint256 _fee) external onlyOwner {
        synthesisFee = _fee;
        emit SynthesisFeeSet(_fee);
    }

    /**
     * @dev Adds an address to the whitelist of trusted AI oracles.
     *      Only whitelisted oracles can fulfill synthesis requests. Only callable by the contract owner.
     * @param _oracleAddress The address to whitelist.
     */
    function addWhitelistedAetherOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address");
        require(!isWhitelistedAetherOracle[_oracleAddress], "Oracle already whitelisted");
        isWhitelistedAetherOracle[_oracleAddress] = true;
        emit AetherOracleWhitelisted(_oracleAddress);
    }

    /**
     * @dev Removes an address from the whitelist of trusted AI oracles.
     *      Only callable by the contract owner.
     * @param _oracleAddress The address to remove from the whitelist.
     */
    function removeWhitelistedAetherOracle(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address");
        require(isWhitelistedAetherOracle[_oracleAddress], "Oracle not whitelisted");
        isWhitelistedAetherOracle[_oracleAddress] = false;
        emit AetherOracleRemoved(_oracleAddress);
    }

    /**
     * @dev Pauses core contract functionalities in emergencies.
     *      Prevents new synthesis requests, minting, voting, etc. Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner {
        require(!paused, "Contract already paused");
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring normal operations.
     *      Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner {
        require(paused, "Contract not paused");
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Allows the owner to withdraw collected `paymentToken` fees from the contract.
     *      Only callable by the contract owner.
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");
        require(paymentToken.transfer(owner(), balance), "Token transfer failed");
        emit FundsWithdrawn(owner(), balance);
    }

    /**
     * @dev Sets the minimum number of 'for' votes required for a narrative link proposal to be executed.
     * @param _minVotes The new minimum vote count.
     */
    function setMinVotesForLink(uint256 _minVotes) external onlyOwner {
        require(_minVotes > 0, "Minimum votes must be positive");
        minVotesForLink = _minVotes;
    }

    // --- II. AI Synthesis Request & Fulfillment ---

    /**
     * @dev Initiates a new AI synthesis request.
     *      Requires payment of `synthesisFee` in the configured `paymentToken`.
     *      If `_chronicleIdToEvolve` is 0, it's a new request for a public narrative fragment.
     *      If non-zero, it's a request to evolve an existing Chronicle Artefact's metadata.
     * @param _prompt The text prompt for the AI.
     * @param _chronicleIdToEvolve The ID of the Chronicle Artefact to evolve (0 for new).
     */
    function initiateSynthesisRequest(string calldata _prompt, uint256 _chronicleIdToEvolve)
        external
        whenNotPaused
        nonReentrant
    {
        require(bytes(_prompt).length > 0, "Prompt cannot be empty");
        require(address(paymentToken) != address(0), "Payment token not set");
        require(synthesisFee > 0, "Synthesis fee must be greater than zero");
        require(paymentToken.transferFrom(msg.sender, address(this), synthesisFee), "Fee payment failed");

        if (_chronicleIdToEvolve != 0) {
            require(_exists(_chronicleIdToEvolve), "Chronicle Artefact does not exist");
            require(ownerOf(_chronicleIdToEvolve) == msg.sender, "Caller is not the owner of the Chronicle Artefact");
            require(_pendingRequestForChronicle[_chronicleIdToEvolve] == 0, "Chronicle already has a pending evolution request");
        }

        uint256 currentRequestId = nextRequestId++;
        synthesisRequests[currentRequestId] = SynthesisRequest({
            requester: msg.sender,
            prompt: _prompt,
            chronicleIdToEvolve: _chronicleIdToEvolve,
            metadataURI: "", // To be set by oracle
            contentHash: "", // To be set by oracle
            fulfilled: false,
            fulfiller: address(0),
            timestamp: block.timestamp,
            minted: false
        });

        if (_chronicleIdToEvolve != 0) {
            _pendingRequestForChronicle[_chronicleIdToEvolve] = currentRequestId;
        }

        emit SynthesisRequestInitiated(currentRequestId, msg.sender, _prompt, _chronicleIdToEvolve);
    }

    /**
     * @dev Called by a whitelisted Aether Oracle to submit the AI-generated output for a given request.
     *      Updates the state of the request and potentially triggers an NFT update or mint.
     * @param _requestId The ID of the synthesis request to fulfill.
     * @param _metadataURI The URI for the generated ERC721 metadata JSON.
     * @param _contentHash A hash or URI for the raw AI-generated content (e.g., text, image).
     */
    function fulfillSynthesisRequest(uint256 _requestId, string calldata _metadataURI, string calldata _contentHash)
        external
        onlyWhitelistedAetherOracle
        whenNotPaused
        nonReentrant
    {
        SynthesisRequest storage request = synthesisRequests[_requestId];
        require(request.requester != address(0), "Request does not exist");
        require(!request.fulfilled, "Request already fulfilled");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty");
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");

        request.fulfilled = true;
        request.fulfiller = msg.sender;
        request.metadataURI = _metadataURI;
        request.contentHash = _contentHash;

        aetherOracleReputation[msg.sender].successfulFulfillments++;
        aetherOracleReputation[msg.sender].totalFulfillments++;

        // If it was an evolution request, update the NFT
        if (request.chronicleIdToEvolve != 0) {
            // Internal call to update existing NFT metadata
            _evolveChronicleArtefactMetadata(request.chronicleIdToEvolve, _metadataURI);
            delete _pendingRequestForChronicle[request.chronicleIdToEvolve]; // Clear pending request
        }

        emit SynthesisRequestFulfilled(_requestId, msg.sender, _metadataURI, _contentHash);
    }

    /**
     * @dev Retrieves the details of a specific synthesis request.
     * @param _requestId The ID of the request.
     * @return requester The address that initiated the request.
     * @return prompt The prompt string.
     * @return chronicleIdToEvolve The ID of the Chronicle Artefact targeted for evolution (0 if new).
     * @return metadataURI The generated metadata URI.
     * @return contentHash The generated content hash.
     * @return fulfilled True if the request has been fulfilled.
     * @return fulfiller The oracle address that fulfilled the request.
     * @return timestamp The timestamp when the request was initiated.
     * @return minted True if an NFT was minted from this request.
     */
    function getSynthesisRequest(uint256 _requestId)
        external
        view
        returns (
            address requester,
            string memory prompt,
            uint256 chronicleIdToEvolve,
            string memory metadataURI,
            string memory contentHash,
            bool fulfilled,
            address fulfiller,
            uint256 timestamp,
            bool minted
        )
    {
        SynthesisRequest storage request = synthesisRequests[_requestId];
        require(request.requester != address(0), "Request does not exist");
        return (
            request.requester,
            request.prompt,
            request.chronicleIdToEvolve,
            request.metadataURI,
            request.contentHash,
            request.fulfilled,
            request.fulfiller,
            request.timestamp,
            request.minted
        );
    }

    // --- III. Chronicle Artefact (Dynamic NFTs) Management ---

    /**
     * @dev Allows the requester to mint a new Chronicle Artefact NFT based on a fulfilled synthesis request
     *      that was initiated without an existing `_chronicleIdToEvolve`.
     * @param _requestId The ID of the fulfilled synthesis request.
     */
    function mintChronicleArtefact(uint256 _requestId) external whenNotPaused nonReentrant {
        SynthesisRequest storage request = synthesisRequests[_requestId];
        require(request.requester == msg.sender, "Only requester can mint");
        require(request.fulfilled, "Request not yet fulfilled");
        require(request.chronicleIdToEvolve == 0, "This request was for an existing Chronicle evolution");
        require(!request.minted, "Chronicle Artefact already minted for this request");

        uint256 newChronicleId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, newChronicleId);
        _chronicleData[newChronicleId].currentMetadataURI = request.metadataURI;
        _chronicleData[newChronicleId].evolutionCount = 0; // Initial mint is version 0

        request.minted = true; // Mark request as minted

        emit ChronicleArtefactMinted(newChronicleId, msg.sender, request.metadataURI);
    }

    /**
     * @dev Internal function to update an existing Chronicle Artefact's metadata URI and increment its evolution count.
     * @param _chronicleId The ID of the Chronicle Artefact to evolve.
     * @param _newMetadataURI The new metadata URI for the artefact.
     */
    function _evolveChronicleArtefactMetadata(uint256 _chronicleId, string memory _newMetadataURI) internal {
        require(_exists(_chronicleId), "Chronicle Artefact does not exist");
        _chronicleData[_chronicleId].currentMetadataURI = _newMetadataURI;
        _chronicleData[_chronicleId].evolutionCount++;
        // Emit metadata update for off-chain indexing services to track the evolution
        emit ChronicleArtefactEvolved(_chronicleId, _chronicleData[_chronicleId].evolutionCount, _newMetadataURI);
    }

    /**
     * @dev Overrides ERC721's `tokenURI` to return the current (potentially evolved) metadata URI for a Chronicle Artefact.
     * @param tokenId The ID of the token.
     * @return The current metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _chronicleData[tokenId].currentMetadataURI;
    }

    /**
     * @dev Returns how many times a specific Chronicle Artefact has had its metadata evolved.
     * @param _chronicleId The ID of the Chronicle Artefact.
     * @return The evolution count.
     */
    function getChronicleEvolutionCount(uint256 _chronicleId) external view returns (uint256) {
        require(_exists(_chronicleId), "Chronicle Artefact does not exist");
        return _chronicleData[_chronicleId].evolutionCount;
    }

    /**
     * @dev Returns the owner of a specific Chronicle Artefact. (A wrapper around ERC721's `ownerOf`).
     * @param _chronicleId The ID of the Chronicle Artefact.
     * @return The owner's address.
     */
    function getChronicleOwner(uint256 _chronicleId) external view returns (address) {
        require(_exists(_chronicleId), "Chronicle Artefact does not exist");
        return ownerOf(_chronicleId);
    }

    // --- IV. Narrative Linking & Discovery ---

    /**
     * @dev Allows an owner of two Chronicle Artefacts to propose a conceptual link between them,
     *      along with a textual reason for the link. This creates a pending link proposal.
     * @param _chronicleIdA The ID of the first Chronicle Artefact.
     * @param _chronicleIdB The ID of the second Chronicle Artefact.
     * @param _reason The textual reason for proposing the link.
     */
    function proposeNarrativeLink(uint256 _chronicleIdA, uint256 _chronicleIdB, string calldata _reason)
        external
        whenNotPaused
    {
        require(_chronicleIdA != _chronicleIdB, "Cannot link a Chronicle to itself");
        require(_exists(_chronicleIdA), "Chronicle A does not exist");
        require(_exists(_chronicleIdB), "Chronicle B does not exist");
        require(ownerOf(_chronicleIdA) == msg.sender, "Caller is not the owner of Chronicle A");
        require(ownerOf(_chronicleIdB) == msg.sender, "Caller is not the owner of Chronicle B");
        require(bytes(_reason).length > 0, "Reason for link cannot be empty");

        // Simple check to prevent duplicate direct links (does not check for indirect paths)
        for (uint256 i = 0; i < _chronicleData[_chronicleIdA].linkedChronicles.length; i++) {
            if (_chronicleData[_chronicleIdA].linkedChronicles[i] == _chronicleIdB) {
                revert("Chronicles are already directly linked");
            }
        }

        uint256 currentProposalId = nextProposalId++;
        narrativeLinkProposals[currentProposalId] = NarrativeLinkProposal({
            proposer: msg.sender,
            chronicleIdA: _chronicleIdA,
            chronicleIdB: _chronicleIdB,
            reason: _reason,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: true,
            timestamp: block.timestamp
        });

        emit NarrativeLinkProposed(currentProposalId, _chronicleIdA, _chronicleIdB, msg.sender);
    }

    /**
     * @dev Allows other Chronicle Artefact owners to vote on pending narrative link proposals.
     *      Cannot vote if you are the proposer or own either of the linked Chronicles.
     *      Requires the voter to own at least one Chronicle Artefact.
     * @param _proposalId The ID of the narrative link proposal.
     * @param _approve True to vote 'for' the link, false to vote 'against'.
     */
    function voteOnNarrativeLink(uint256 _proposalId, bool _approve) external whenNotPaused {
        NarrativeLinkProposal storage proposal = narrativeLinkProposals[_proposalId];
        require(proposal.active, "Proposal is not active");
        require(!proposal.executed, "Proposal already executed");
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal");
        require(ownerOf(proposal.chronicleIdA) != msg.sender && ownerOf(proposal.chronicleIdB) != msg.sender, "Cannot vote if you own either of the proposed Chronicles");
        require(ERC721.balanceOf(msg.sender) > 0, "Voter must own at least one Chronicle Artefact"); // Basic Sybil resistance
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit NarrativeLinkVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Finalizes a narrative link if it reaches a sufficient vote threshold.
     *      Upon execution, the `linkedChronicles` array for both NFTs is updated.
     * @param _proposalId The ID of the narrative link proposal.
     */
    function executeNarrativeLink(uint256 _proposalId) external nonReentrant {
        NarrativeLinkProposal storage proposal = narrativeLinkProposals[_proposalId];
        require(proposal.active, "Proposal is not active");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.votesFor >= minVotesForLink, "Not enough votes to execute link");
        // Additional checks like a time limit for voting could be added here.

        // Add linkage to both chronicles (bi-directional)
        _chronicleData[proposal.chronicleIdA].linkedChronicles.push(proposal.chronicleIdB);
        _chronicleData[proposal.chronicleIdB].linkedChronicles.push(proposal.chronicleIdA);

        proposal.executed = true;
        proposal.active = false; // Deactivate proposal after execution

        emit NarrativeLinkExecuted(_proposalId, proposal.chronicleIdA, proposal.chronicleIdB);
    }

    /**
     * @dev Retrieves details of a specific narrative link proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposer The address that proposed the link.
     * @return chronicleIdA The ID of the first linked Chronicle.
     * @return chronicleIdB The ID of the second linked Chronicle.
     * @return reason The reason provided for the link.
     * @return votesFor The count of 'for' votes.
     * @return votesAgainst The count of 'against' votes.
     * @return executed True if the link has been executed.
     * @return active True if the proposal is still active.
     * @return timestamp The timestamp when the proposal was created.
     */
    function getNarrativeLinkProposal(uint256 _proposalId)
        external
        view
        returns (
            address proposer,
            uint256 chronicleIdA,
            uint256 chronicleIdB,
            string memory reason,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed,
            bool active,
            uint256 timestamp
        )
    {
        NarrativeLinkProposal storage proposal = narrativeLinkProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (
            proposal.proposer,
            proposal.chronicleIdA,
            proposal.chronicleIdB,
            proposal.reason,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.active,
            proposal.timestamp
        );
    }

    /**
     * @dev Returns a list of Chronicle Artefact IDs that are formally linked to a given one.
     * @param _chronicleId The ID of the Chronicle Artefact.
     * @return An array of linked Chronicle Artefact IDs.
     */
    function getLinkedChronicles(uint256 _chronicleId) external view returns (uint256[] memory) {
        require(_exists(_chronicleId), "Chronicle Artefact does not exist");
        return _chronicleData[_chronicleId].linkedChronicles;
    }

    // --- V. AI Oracle Reputation & Statistics (Simplified) ---

    /**
     * @dev Allows users to submit a rating (1-5) for a whitelisted Aether Oracle's performance.
     *      This contributes to the oracle's simplified reputation score.
     *      (Note: For a production system, more robust spam prevention or proof-of-interaction would be needed.)
     * @param _oracleAddress The address of the Aether Oracle being rated.
     * @param _rating The rating to submit (1-5).
     */
    function submitAetherOracleRating(address _oracleAddress, uint8 _rating) external whenNotPaused {
        require(isWhitelistedAetherOracle[_oracleAddress], "Oracle is not whitelisted");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        // Future improvement: require msg.sender to have recently interacted with this oracle or own an NFT fulfilled by them.

        aetherOracleReputation[_oracleAddress].totalRatings++;
        aetherOracleReputation[_oracleAddress].sumOfRatings += _rating;

        emit AetherOracleRatingSubmitted(_oracleAddress, msg.sender, _rating);
    }

    /**
     * @dev Retrieves the current average rating for a given Aether Oracle.
     * @param _oracleAddress The address of the Aether Oracle.
     * @return The average rating (integer division). Returns 0 if no ratings.
     */
    function getAetherOracleAverageRating(address _oracleAddress) external view returns (uint256) {
        OracleReputation storage rep = aetherOracleReputation[_oracleAddress];
        if (rep.totalRatings == 0) {
            return 0;
        }
        return rep.sumOfRatings / rep.totalRatings; // Integer division
    }

    /**
     * @dev Returns the total count of successfully fulfilled synthesis requests by an oracle.
     * @param _oracleAddress The address of the Aether Oracle.
     * @return The count of successful fulfillments.
     */
    function getAetherOracleSuccessfulFulfillments(address _oracleAddress) external view returns (uint256) {
        return aetherOracleReputation[_oracleAddress].successfulFulfillments;
    }

    /**
     * @dev Returns the total count of all fulfillment attempts (successful or otherwise) by an oracle.
     *      In this simplified model, this count will typically match successful fulfillments unless more failure states are added.
     * @param _oracleAddress The address of the Aether Oracle.
     * @return The total count of fulfillment attempts.
     */
    function getAetherOracleTotalFulfillments(address _oracleAddress) external view returns (uint256) {
        return aetherOracleReputation[_oracleAddress].totalFulfillments;
    }
}
```