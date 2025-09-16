Here's a Solidity smart contract named `SynergisticArtProtocol` that embodies interesting, advanced, creative, and trendy concepts. It focuses on decentralized, AI-assisted generative art creation, dynamic NFTs, a community reputation system, and on-chain governance over AI parameters.

The core idea is a DAO (Decentralized Autonomous Organization) that coordinates a (simulated) generative AI to produce art, which can then be minted as dynamic NFTs. These NFTs can evolve over time based on owner requests or pre-set triggers, with the community curating the generated output and governing the AI's "creative" parameters.

---

### `SynergisticArtProtocol`

**Description:**
A decentralized protocol for community-driven, AI-assisted generative art creation and dynamic NFT management. It integrates a simulated AI oracle for art generation, a reputation system for contributors, a governance mechanism for steering AI parameters and treasury, and dynamic NFTs that can evolve. The protocol encourages active participation in both art generation and curation through a token-staked voting and reputation system.

**Key Features:**
*   **AI Oracle Integration (Simulated):** The contract interacts with an assumed off-chain AI service via a simple interface, sending prompts and receiving generated art data (e.g., IPFS hashes).
*   **Dynamic NFTs:** NFTs whose metadata and visual representation can change over time, either by explicit owner request or automated, pre-defined triggers.
*   **Reputation System:** Users earn non-transferable reputation scores for contributing valuable inspiration, participating in curation, and successful governance proposals. Reputation boosts voting power.
*   **AI Parameter Governance:** The community, through governance proposals, can vote on and update the core parameters (e.g., base prompt templates, creative weights, default styles) that guide the AI's art generation.
*   **Community-Driven Curation:** Generated art blocks must pass a community curation vote (weighted by reputation) before they can be minted as NFTs.
*   **Staking & Influence:** Users stake native SAP Tokens to gain enhanced voting power, proposal creation rights, and potentially prioritized AI generation.
*   **Autonomous Treasury Management:** Treasury funds (from generation fees, etc.) are managed via governance proposals for covering AI oracle costs, artist rewards, or protocol development.
*   **Gamified Contribution:** Incentivizes meaningful engagement through reputation and potential token rewards.

**Outline and Function Summary:**

**I. Core Management & Configuration**
1.  `constructor(IERC20 _sapToken, IAIOracle _aiOracle, IDynamicNFT _dynamicNFTFactory, address initialOwner)`: Initializes the protocol with essential contract addresses and owner.
2.  `setAIOracleAddress(IAIOracle _newAIOracle)`: Updates the AI oracle contract address. (Owner)
3.  `setNFTFactoryAddress(IDynamicNFT _newDynamicNFTFactory)`: Updates the Dynamic NFT factory contract address. (Owner)
4.  `updateGenerationFee(uint256 _newFee)`: Sets the fee required (in SAP Tokens) for requesting AI art generation. (Owner)
5.  `updateMinimumStakedForProposal(uint256 _newMinStake)`: Sets the minimum SAP Tokens required to be staked for creating a governance proposal. (Owner)
6.  `pauseContract()`: Pauses critical contract functionality in emergencies. (Owner)
7.  `unpauseContract()`: Unpauses contract functionality. (Owner)
8.  `rescueERC20(IERC20 tokenAddress, address to, uint256 amount)`: Allows the owner to recover accidentally sent ERC20 tokens (excluding the protocol's native token). (Owner)

**II. AI Oracle Interaction & Art Generation**
9.  `requestAIArtGeneration(string memory _inspirationPrompt)`: Submits a user-defined prompt to the AI oracle for art generation. Requires paying `generationFee`. (User)
10. `fulfillAIArtGeneration(bytes32 _requestId, string memory _resultURI)`: Callback from the AI oracle, providing the URI (e.g., IPFS hash) of the generated art or updated NFT metadata. (AI Oracle)
11. `failGeneration(bytes32 _requestId, string memory _reason)`: Callback from the AI oracle in case a generation request fails, triggering a fee refund. (AI Oracle)
12. `submitInspirationPrompt(string memory _promptContent)`: Users contribute text prompts to a collective pool of inspiration, earning reputation. (User)
13. `submitDataReference(string memory _dataURI)`: Users submit external data references (e.g., IPFS hashes) as inspiration, earning reputation. (User)

**III. NFT Management (Dynamic & Curated)**
14. `curateGeneratedArt(bytes32 _requestId, bool _accept)`: Users vote on the quality and relevance of newly AI-generated art blocks. Voting power is linked to reputation. (User)
15. `finalizeCuration(bytes32 _requestId)`: Finalizes a curation round for a given `requestId` after the voting period, determining if the art is accepted. (Anyone)
16. `mintDynamicArtNFT(bytes32 _requestId, uint256 _tokenId)`: Mints a new Dynamic NFT based on an AI-generated art block that has been successfully curated and accepted. (User)
17. `requestNFTReGeneration(uint256 _tokenId, string memory _newInspiration)`: An NFT owner can request their NFT's metadata to be re-generated by the AI, potentially altering its appearance. (NFT Owner)
18. `freezeNFTMetadata(uint256 _tokenId)`: Allows an NFT owner to make their NFT's metadata immutable, preventing further re-generations. (NFT Owner)
19. `unfreezeNFTMetadata(uint256 _tokenId)`: Allows an NFT owner to reverse `freezeNFTMetadata`, enabling re-generation again. (NFT Owner)
20. `setNFTEvolutionTrigger(uint256 _tokenId, uint256 _triggerTime, string memory _triggerPrompt)`: Sets conditions (e.g., time-based) for an NFT's automated metadata evolution in the future. (NFT Owner)
21. `triggerAutomatedNFTEvolution(uint256 _tokenId)`: Activates an automated NFT evolution when its pre-set trigger conditions are met. (Anyone, with rewards)

**IV. Reputation & Staking**
22. `stakeTokens(uint256 _amount)`: Users stake SAP Tokens to gain increased voting power, proposal creation rights, and reputation. (User)
23. `unstakeTokens(uint256 _amount)`: Users unstake their SAP Tokens. (User)
24. `getReputationScore(address _user)`: Returns the current reputation score for a specific user. (View)
25. `distributeReputationRewards(address[] memory _users, uint256[] memory _amounts)`: Allows the owner or an authorized entity to manually distribute reputation. (Owner/Admin)

**V. Governance & Treasury**
26. `proposeAIParameterChange(string memory _description, string memory _basePromptTemplate, uint256 _creativeWeight, uint256 _styleWeight, string memory _defaultStyle)`: Creates a proposal to update the AI's core generative parameters. (User)
27. `createTreasuryProposal(string memory _description, address _recipient, uint256 _amount)`: Creates a proposal to transfer SAP Tokens from the contract's treasury to a specified recipient. (User)
28. `voteOnProposal(uint256 _proposalId, bool _support)`: Users cast their vote (yes/no) on an active governance proposal. Voting power is proportional to staked tokens and reputation. (User)
29. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal after its voting period ends. (Anyone)

**VI. View Functions**
30. `getProposalDetails(uint256 _proposalId)`: Returns all details of a specific governance proposal. (View)
31. `getActiveAIParameters()`: Returns the currently active AI generative parameters. (View)
32. `getGenerationRequestDetails(bytes32 _requestId)`: Provides status and details for a given AI generation request. (View)
33. `getCurationStatus(bytes32 _requestId)`: Returns the current curation information for an AI-generated art block. (View)
34. `getStakedBalance(address _user)`: Returns the amount of SAP Tokens staked by a user. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Interfaces ---

/**
 * @dev Placeholder interface for an off-chain AI Oracle service.
 *      In a real-world scenario, this would likely involve a Chainlink-like oracle
 *      to ensure verifiable and decentralized computation results.
 */
interface IAIOracle {
    event GenerationRequested(address indexed requester, bytes32 requestId, string prompt, uint256 feeAmount);
    event GenerationFulfilled(bytes32 requestId, string resultURI);
    event GenerationFailed(bytes32 requestId, string reason);

    /**
     * @dev Requests the AI service to generate content based on a prompt.
     * @param _prompt The textual prompt for the AI.
     * @param _fee The fee paid for the generation request.
     * @return requestId A unique identifier for this request.
     */
    function requestGeneration(string memory _prompt, uint256 _fee) external returns (bytes32 requestId);

    /**
     * @dev Callback function to be called by the AI Oracle after successful generation.
     * @param _requestId The ID of the original request.
     * @param _resultURI The URI (e.g., IPFS hash) pointing to the generated content.
     */
    function fulfillGeneration(bytes32 _requestId, string memory _resultURI) external;

    /**
     * @dev Callback function to be called by the AI Oracle if generation fails.
     * @param _requestId The ID of the original request.
     * @param _reason A description of why the generation failed.
     */
    function failGeneration(bytes32 _requestId, string memory _reason) external;
}

/**
 * @dev Placeholder interface for a Dynamic NFT contract (ERC721 extension).
 *      This NFT is "dynamic" because its metadata can be updated post-mint.
 */
interface IDynamicNFT {
    event MetadataUpdated(uint256 indexed tokenId, string newURI);
    event NFTFrozen(uint256 indexed tokenId);
    event NFTUnfrozen(uint256 indexed tokenId);

    /**
     * @dev Mints a new NFT to an address with initial metadata.
     * @param to The recipient of the NFT.
     * @param tokenId The unique ID for the new NFT.
     * @param tokenURI The initial metadata URI for the NFT.
     */
    function mint(address to, uint256 tokenId, string memory tokenURI) external;

    /**
     * @dev Updates the metadata URI for an existing NFT.
     * @param tokenId The ID of the NFT to update.
     * @param newTokenURI The new metadata URI.
     */
    function updateMetadata(uint256 tokenId, string memory newTokenURI) external;

    /**
     * @dev Checks if an NFT's metadata is currently frozen.
     * @param tokenId The ID of the NFT.
     * @return True if frozen, false otherwise.
     */
    function isMetadataFrozen(uint256 tokenId) external view returns (bool);

    /**
     * @dev Freezes an NFT's metadata, preventing further updates.
     * @param tokenId The ID of the NFT to freeze.
     */
    function freezeMetadata(uint256 tokenId) external;

    /**
     * @dev Unfreezes an NFT's metadata, allowing updates again.
     * @param tokenId The ID of the NFT to unfreeze.
     */
    function unfreezeMetadata(uint256 tokenId) external;

    /**
     * @dev Returns the metadata URI for a given token ID.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Returns the owner of the specified token.
     * @param tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function ownerOf(uint256 tokenId) external view returns (address);
}

// --- Main Contract ---

/**
 * @title SynergisticArtProtocol
 * @dev A decentralized protocol for community-driven, AI-assisted generative art creation and dynamic NFT management.
 *      It integrates a simulated AI oracle for art generation, a reputation system for contributors,
 *      a governance mechanism for steering AI parameters and treasury, and dynamic NFTs that can evolve.
 */
contract SynergisticArtProtocol is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---

    IERC20 public immutable sapToken;
    IAIOracle public aiOracle;
    IDynamicNFT public dynamicNFTFactory;

    uint256 public generationFee; // Fee in SAP Tokens for AI generation requests
    uint256 public minStakeForProposal; // Minimum SAP Tokens staked to create a proposal
    uint256 public curationQuorumPercentage = 51; // Percentage of total reputation needed to finalize a curation (simplified, could be more complex)
    uint256 public curationVoteDuration = 1 days; // How long a curation round lasts

    // AI Parameters, governed by the community
    struct AIParameters {
        string basePromptTemplate; // E.g., "A digital painting of {concept} in the style of {style}, highly detailed."
        uint256 creativeWeight;    // Influences how "creative" vs. "literal" the AI is (0-100)
        uint256 styleWeight;       // Influences adherence to a specific style (0-100)
        string defaultStyle;       // Default artistic style
        uint256 parameterVersion;  // Tracks changes
    }
    AIParameters public currentAIParameters;

    // Reputation system: mapping user address to their reputation score
    mapping(address => uint256) public reputationScores;

    // Staking for influence: mapping user address to their staked SAP Tokens
    mapping(address => uint256) public stakedBalances;

    // AI Generation Requests management (internal to SAP)
    enum GenerationStatus { Pending, Generated, Failed }
    struct GenerationRequest {
        address requester;
        bytes32 requestId;
        string prompt;
        uint256 timestamp;
        GenerationStatus status;
        string resultURI;
    }
    mapping(bytes32 => GenerationRequest) public generationRequests;

    // Inspiration Inputs: a log of community-contributed prompts/references
    struct InspirationInput {
        address contributor;
        string content; // Text prompt or IPFS hash
        uint256 timestamp;
        InputType inputType;
    }
    enum InputType { Prompt, DataReference }
    InspirationInput[] public recentInspirations; // Stores recent inputs (could be a more optimized queue)

    // Curation for AI generated art
    struct CurationInfo {
        bytes32 requestId;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 submissionTime;
        bool finalized;
        bool accepted; // If true, can be minted as NFT
    }
    mapping(bytes32 => CurationInfo) public curations;
    mapping(bytes32 => mapping(address => bool)) public hasCuratorVoted; // Tracks individual curator votes per request

    // NFT Evolution Triggers: for automated updates to dynamic NFTs
    struct NFTEvolutionTrigger {
        uint256 triggerTime; // Timestamp when evolution should occur
        string triggerPrompt; // New prompt to use for re-generation
        bool activated;       // True if this trigger has already caused an evolution
    }
    mapping(uint256 => NFTEvolutionTrigger) public nftEvolutionTriggers; // tokenId => trigger info
    mapping(bytes32 => uint256) public requestIdToNFTId; // Maps a generation request ID to an NFT token ID for re-generation purposes.


    // Governance Proposals
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 submitTime;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
        ProposalType proposalType;
        bytes callData; // For executive proposals like AIParameterUpdate
        address targetContract; // For executive proposals
        address recipient; // Specific to TreasurySpend
        uint256 amount;    // Specific to TreasurySpend
    }
    enum ProposalType {
        AIParameterUpdate,
        TreasurySpend,
        GenericMessage // For general discussion/consensus, no on-chain execution
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voter => bool


    // --- Events ---
    event AIOracleAddressUpdated(address indexed newAddress);
    event NFTFactoryAddressUpdated(address indexed newAddress);
    event GenerationFeeUpdated(uint256 newFee);
    event MinStakeForProposalUpdated(uint256 newMinStake);
    event ReputationRewarded(address indexed user, uint256 amount);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event InspirationSubmitted(address indexed contributor, uint256 timestamp, InputType inputType, string content);
    event ArtCurationStarted(bytes32 indexed requestId, uint256 submissionTime);
    event ArtCurationFinalized(bytes32 indexed requestId, bool accepted);
    event DynamicArtNFTMinted(address indexed minter, uint256 indexed tokenId, bytes32 indexed requestId, string tokenURI);
    event NFTReGenerationRequested(uint256 indexed tokenId, address indexed requester, string newInspiration);
    event NFTEvolutionTriggerSet(uint256 indexed tokenId, uint256 triggerTime, string triggerPrompt);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "SAP: Only AI Oracle can call this");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(dynamicNFTFactory.ownerOf(_tokenId) == msg.sender, "SAP: Only NFT owner can call this");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the SynergisticArtProtocol contract.
     * @param _sapToken The address of the ERC20 token used for staking and fees.
     * @param _aiOracle The address of the AI Oracle contract.
     * @param _dynamicNFTFactory The address of the Dynamic NFT factory contract.
     * @param initialOwner The initial owner of this contract.
     */
    constructor(
        IERC20 _sapToken,
        IAIOracle _aiOracle,
        IDynamicNFT _dynamicNFTFactory,
        address initialOwner
    )
        Ownable(initialOwner)
        Pausable()
    {
        require(address(_sapToken) != address(0), "SAP: SAP Token address cannot be zero");
        require(address(_aiOracle) != address(0), "SAP: AI Oracle address cannot be zero");
        require(address(_dynamicNFTFactory) != address(0), "SAP: Dynamic NFT Factory address cannot be zero");

        sapToken = _sapToken;
        aiOracle = _aiOracle;
        dynamicNFTFactory = _dynamicNFTFactory;

        generationFee = 100 * (10 ** sapToken.decimals()); // Example: 100 SAP Tokens
        minStakeForProposal = 500 * (10 ** sapToken.decimals()); // Example: 500 SAP Tokens

        // Initialize default AI parameters
        currentAIParameters = AIParameters({
            basePromptTemplate: "A vibrant digital artwork of {concept} with {mood}, in a {style} style.",
            creativeWeight: 75,
            styleWeight: 60,
            defaultStyle: "impressionistic",
            parameterVersion: 1
        });
    }

    // --- I. Core Management & Configuration (Owner functions) ---

    /**
     * @dev Updates the address of the AI oracle contract.
     * @param _newAIOracle The new AI oracle contract address.
     */
    function setAIOracleAddress(IAIOracle _newAIOracle) public onlyOwner {
        require(address(_newAIOracle) != address(0), "SAP: New AI Oracle address cannot be zero");
        aiOracle = _newAIOracle;
        emit AIOracleAddressUpdated(address(_newAIOracle));
    }

    /**
     * @dev Updates the address of the Dynamic NFT factory contract.
     * @param _newDynamicNFTFactory The new Dynamic NFT factory contract address.
     */
    function setNFTFactoryAddress(IDynamicNFT _newDynamicNFTFactory) public onlyOwner {
        require(address(_newDynamicNFTFactory) != address(0), "SAP: New NFT Factory address cannot be zero");
        dynamicNFTFactory = _newDynamicNFTFactory;
        emit NFTFactoryAddressUpdated(address(_newDynamicNFTFactory));
    }

    /**
     * @dev Sets the fee required for requesting AI art generation.
     * @param _newFee The new fee amount in SAP Tokens (with decimals).
     */
    function updateGenerationFee(uint256 _newFee) public onlyOwner {
        generationFee = _newFee;
        emit GenerationFeeUpdated(_newFee);
    }

    /**
     * @dev Sets the minimum stake required in SAP Tokens to create a governance proposal.
     * @param _newMinStake The new minimum stake amount.
     */
    function updateMinimumStakedForProposal(uint256 _newMinStake) public onlyOwner {
        minStakeForProposal = _newMinStake;
        emit MinStakeForProposalUpdated(_newMinStake);
    }

    /**
     * @dev Pauses critical contract functionality. Can only be called by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses critical contract functionality. Can only be called by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to rescue accidentally sent ERC20 tokens (not the protocol's native token).
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param to The recipient address for the rescued tokens.
     * @param amount The amount of tokens to rescue.
     */
    function rescueERC20(IERC20 tokenAddress, address to, uint256 amount) public onlyOwner {
        require(address(tokenAddress) != address(sapToken), "SAP: Cannot rescue protocol's native token");
        require(to != address(0), "SAP: Recipient cannot be zero address");
        require(tokenAddress.transfer(to, amount), "SAP: ERC20 transfer failed");
    }

    // --- II. AI Oracle Interaction & Art Generation ---

    /**
     * @dev Requests the AI oracle to generate art based on user input and current AI parameters.
     *      Requires payment of `generationFee` in SAP Tokens, which is transferred to the contract's treasury.
     * @param _inspirationPrompt The specific prompt or concept from the user.
     * @return requestId The unique identifier for the generation request.
     */
    function requestAIArtGeneration(string memory _inspirationPrompt) public whenNotPaused nonReentrant returns (bytes32 requestId) {
        require(bytes(_inspirationPrompt).length > 0, "SAP: Inspiration prompt cannot be empty");
        require(sapToken.transferFrom(msg.sender, address(this), generationFee), "SAP: Token transfer failed for generation fee");

        // Combine user prompt with current AI parameters' base template
        string memory fullPrompt = string(abi.encodePacked(
            currentAIParameters.basePromptTemplate,
            " Concept: ", _inspirationPrompt,
            ", Mood: dynamic, Style: ", currentAIParameters.defaultStyle,
            ", Creative Weight: ", Strings.toString(currentAIParameters.creativeWeight),
            ", Style Weight: ", Strings.toString(currentAIParameters.styleWeight)
        ));

        requestId = aiOracle.requestGeneration(fullPrompt, generationFee);
        generationRequests[requestId] = GenerationRequest({
            requester: msg.sender,
            requestId: requestId,
            prompt: fullPrompt,
            timestamp: block.timestamp,
            status: GenerationStatus.Pending,
            resultURI: ""
        });
        // Reputation awarded for initiating a generation request
        reputationScores[msg.sender] += 1; // Small base reputation
    }

    /**
     * @dev Callback function from the AI oracle to provide generated art data.
     *      Only callable by the registered AI oracle. If the request was for an NFT re-generation,
     *      it updates the NFT's metadata; otherwise, it starts a curation process.
     * @param _requestId The ID of the generation request.
     * @param _resultURI The URI (e.g., IPFS hash) of the generated art metadata/image.
     */
    function fulfillAIArtGeneration(bytes32 _requestId, string memory _resultURI) public onlyAIOracle whenNotPaused {
        GenerationRequest storage req = generationRequests[_requestId];
        require(req.status == GenerationStatus.Pending, "SAP: Request not pending or already fulfilled/failed");
        require(bytes(_resultURI).length > 0, "SAP: Result URI cannot be empty");

        req.status = GenerationStatus.Generated;
        req.resultURI = _resultURI;

        if (requestIdToNFTId[_requestId] != 0) {
            // This was a re-generation request for an existing NFT
            uint256 nftToUpdate = requestIdToNFTId[_requestId];
            require(dynamicNFTFactory.ownerOf(nftToUpdate) == req.requester, "SAP: NFT owner mismatch for re-generation");
            require(!dynamicNFTFactory.isMetadataFrozen(nftToUpdate), "SAP: NFT metadata is frozen, cannot update");

            dynamicNFTFactory.updateMetadata(nftToUpdate, _resultURI);
            delete requestIdToNFTId[_requestId]; // Clean up the mapping
        } else {
            // This was a new art generation request, start curation process
            curations[_requestId] = CurationInfo({
                requestId: _requestId,
                yesVotes: 0,
                noVotes: 0,
                submissionTime: block.timestamp,
                finalized: false,
                accepted: false
            });
            emit ArtCurationStarted(_requestId, block.timestamp);
        }
    }

    /**
     * @dev Callback function from the AI oracle if a generation request fails.
     *      Only callable by the registered AI oracle. Refunds the generation fee.
     * @param _requestId The ID of the failed generation request.
     * @param _reason The reason for failure.
     */
    function failGeneration(bytes32 _requestId, string memory _reason) public onlyAIOracle {
        GenerationRequest storage req = generationRequests[_requestId];
        require(req.status == GenerationStatus.Pending, "SAP: Request not pending or already fulfilled/failed");

        req.status = GenerationStatus.Failed;
        require(sapToken.transfer(req.requester, generationFee), "SAP: Refund failed for generation fee"); // Refund fee
        emit IAIOracle.GenerationFailed(_requestId, _reason);

        // Clean up mapping if it was a re-generation request
        if (requestIdToNFTId[_requestId] != 0) {
            delete requestIdToNFTId[_requestId];
        }
    }

    /**
     * @dev Users submit text prompts to enrich the collective AI input pool.
     *      Earns the contributor reputation.
     * @param _promptContent The text prompt or concept.
     */
    function submitInspirationPrompt(string memory _promptContent) public whenNotPaused {
        require(bytes(_promptContent).length > 0, "SAP: Prompt content cannot be empty");
        recentInspirations.push(InspirationInput({
            contributor: msg.sender,
            content: _promptContent,
            timestamp: block.timestamp,
            inputType: InputType.Prompt
        }));
        reputationScores[msg.sender] += 5; // Reward for contributing inspiration
        emit InspirationSubmitted(msg.sender, block.timestamp, InputType.Prompt, _promptContent);
    }

    /**
     * @dev Users submit IPFS hashes or URLs pointing to external data/images as inspiration references.
     *      Earns the contributor reputation.
     * @param _dataURI The URI of the external data.
     */
    function submitDataReference(string memory _dataURI) public whenNotPaused {
        require(bytes(_dataURI).length > 0, "SAP: Data URI cannot be empty");
        // Basic validation for URI format could be added here
        recentInspirations.push(InspirationInput({
            contributor: msg.sender,
            content: _dataURI,
            timestamp: block.timestamp,
            inputType: InputType.DataReference
        }));
        reputationScores[msg.sender] += 7; // Higher reward for external data
        emit InspirationSubmitted(msg.sender, block.timestamp, InputType.DataReference, _dataURI);
    }

    // --- III. NFT Management (Dynamic & Curated) ---

    /**
     * @dev Users vote on the quality or relevance of recently AI-generated art blocks.
     *      Voting requires reputation. Voting power is proportional to reputation score.
     * @param _requestId The ID of the AI generation request being curated.
     * @param _accept True to vote "yes", false to vote "no".
     */
    function curateGeneratedArt(bytes32 _requestId, bool _accept) public whenNotPaused {
        CurationInfo storage curation = curations[_requestId];
        require(curation.submissionTime > 0, "SAP: Curation not found or not yet started");
        require(block.timestamp <= curation.submissionTime + curationVoteDuration, "SAP: Curation period ended");
        require(!curation.finalized, "SAP: Curation already finalized");
        require(!hasCuratorVoted[_requestId][msg.sender], "SAP: Already voted on this curation");
        require(reputationScores[msg.sender] > 0, "SAP: Must have reputation to curate");

        hasCuratorVoted[_requestId][msg.sender] = true;
        uint256 voteWeight = reputationScores[msg.sender];
        if (_accept) {
            curation.yesVotes += voteWeight;
        } else {
            curation.noVotes += voteWeight;
        }
        reputationScores[msg.sender] += 2; // Small reward for participating in curation
    }

    /**
     * @dev Finalizes a curation round and determines if the art block is accepted.
     *      Can be called by anyone after the curation period ends.
     * @param _requestId The ID of the generation request to finalize.
     */
    function finalizeCuration(bytes32 _requestId) public {
        CurationInfo storage curation = curations[_requestId];
        require(curation.submissionTime > 0, "SAP: Curation not found");
        require(block.timestamp > curation.submissionTime + curationVoteDuration, "SAP: Curation period not yet ended");
        require(!curation.finalized, "SAP: Curation already finalized");

        curation.finalized = true;
        uint256 totalVotes = curation.yesVotes + curation.noVotes;
        if (totalVotes > 0 && (curation.yesVotes * 100 / totalVotes) >= curationQuorumPercentage) {
            curation.accepted = true;
        } else {
            curation.accepted = false;
        }
        emit ArtCurationFinalized(_requestId, curation.accepted);
    }

    /**
     * @dev Mints a new Dynamic NFT based on an accepted AI-generated art block.
     *      Anyone can mint once curation is finalized and accepted.
     * @param _requestId The ID of the accepted generation request.
     * @param _tokenId The desired token ID for the new NFT.
     */
    function mintDynamicArtNFT(bytes32 _requestId, uint256 _tokenId) public whenNotPaused {
        CurationInfo storage curation = curations[_requestId];
        GenerationRequest storage genReq = generationRequests[_requestId];

        require(curation.accepted, "SAP: Art block not accepted for minting");
        require(genReq.status == GenerationStatus.Generated, "SAP: Art generation not complete");

        // Simple check to prevent re-minting of the same token ID.
        // In a production system, a more robust ID management (e.g., auto-increment, collision resolution)
        // would be necessary within the IDynamicNFT contract or a separate registry.
        try dynamicNFTFactory.tokenURI(_tokenId) returns (string memory uri) {
            require(bytes(uri).length == 0, "SAP: Token ID already exists or in use");
        } catch {
            // tokenURI call failed, likely means token doesn't exist, which is fine.
        }

        dynamicNFTFactory.mint(msg.sender, _tokenId, genReq.resultURI);
        // Generation fee was already collected in requestAIArtGeneration and remains in the contract's treasury.
        emit DynamicArtNFTMinted(msg.sender, _tokenId, _requestId, genReq.resultURI);
        reputationScores[msg.sender] += 10; // Reward for minting accepted art
    }

    /**
     * @dev Allows an NFT owner to request their NFT's metadata to be re-generated by the AI.
     *      Costs `generationFee` and triggers a new AI generation request. The new metadata will be
     *      updated directly on the NFT upon fulfillment, bypassing curation.
     * @param _tokenId The ID of the NFT to re-generate.
     * @param _newInspiration An optional new prompt/inspiration for the re-generation.
     */
    function requestNFTReGeneration(uint256 _tokenId, string memory _newInspiration) public onlyNFTOwner(_tokenId) whenNotPaused nonReentrant returns (bytes32 requestId) {
        require(!dynamicNFTFactory.isMetadataFrozen(_tokenId), "SAP: NFT metadata is frozen");
        require(sapToken.transferFrom(msg.sender, address(this), generationFee), "SAP: Token transfer failed for re-generation fee");

        string memory currentURI = dynamicNFTFactory.tokenURI(_tokenId);
        // Combine new inspiration with current AI parameters' base template for the re-generation
        string memory fullPrompt = string(abi.encodePacked(
            currentAIParameters.basePromptTemplate,
            " Concept: ", _newInspiration,
            ", Regenerating from original: ", currentURI,
            ", Mood: evolving, Style: ", currentAIParameters.defaultStyle,
            ", Creative Weight: ", Strings.toString(currentAIParameters.creativeWeight),
            ", Style Weight: ", Strings.toString(currentAIParameters.styleWeight)
        ));

        requestId = aiOracle.requestGeneration(fullPrompt, generationFee);
        generationRequests[requestId] = GenerationRequest({
            requester: msg.sender,
            requestId: requestId,
            prompt: fullPrompt,
            timestamp: block.timestamp,
            status: GenerationStatus.Pending,
            resultURI: ""
        });
        requestIdToNFTId[requestId] = _tokenId; // Link request to NFT for direct update
        reputationScores[msg.sender] += 3; // Reward for evolving an NFT
        emit NFTReGenerationRequested(_tokenId, msg.sender, _newInspiration);
    }

    /**
     * @dev Allows an NFT owner to make their NFT's metadata immutable, preventing future re-generations.
     * @param _tokenId The ID of the NFT to freeze.
     */
    function freezeNFTMetadata(uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        dynamicNFTFactory.freezeMetadata(_tokenId);
    }

    /**
     * @dev Allows an NFT owner to unfreeze their NFT's metadata, enabling re-generation again.
     * @param _tokenId The ID of the NFT to unfreeze.
     */
    function unfreezeNFTMetadata(uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        dynamicNFTFactory.unfreezeMetadata(_tokenId);
    }

    /**
     * @dev Sets conditions for an NFT's automated evolution (e.g., time-based, external event trigger).
     *      When `triggerTime` is reached, anyone can call `triggerAutomatedNFTEvolution` to initiate the re-generation.
     * @param _tokenId The ID of the NFT.
     * @param _triggerTime The timestamp when the evolution can be triggered.
     * @param _triggerPrompt A new prompt or inspiration to use for the automated re-generation.
     */
    function setNFTEvolutionTrigger(uint256 _tokenId, uint256 _triggerTime, string memory _triggerPrompt) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(!dynamicNFTFactory.isMetadataFrozen(_tokenId), "SAP: NFT metadata is frozen, cannot set evolution trigger");
        require(_triggerTime > block.timestamp, "SAP: Trigger time must be in the future");
        require(bytes(_triggerPrompt).length > 0, "SAP: Trigger prompt cannot be empty");

        nftEvolutionTriggers[_tokenId] = NFTEvolutionTrigger({
            triggerTime: _triggerTime,
            triggerPrompt: _triggerPrompt,
            activated: false
        });
        emit NFTEvolutionTriggerSet(_tokenId, _triggerTime, _triggerPrompt);
    }

    /**
     * @dev Triggers an automated NFT evolution if the conditions are met.
     *      Can be called by anyone (e.g., a bot or another user). The protocol covers the generation fee
     *      for this automated evolution. Rewards the caller for activating the trigger.
     * @param _tokenId The ID of the NFT to evolve.
     * @return requestId The unique identifier for the automated generation request.
     */
    function triggerAutomatedNFTEvolution(uint256 _tokenId) public whenNotPaused returns (bytes32 requestId) {
        NFTEvolutionTrigger storage trigger = nftEvolutionTriggers[_tokenId];
        require(trigger.triggerTime > 0, "SAP: No evolution trigger set for this NFT");
        require(block.timestamp >= trigger.triggerTime, "SAP: Evolution trigger time not yet reached");
        require(!trigger.activated, "SAP: Evolution trigger already activated");
        require(!dynamicNFTFactory.isMetadataFrozen(_tokenId), "SAP: NFT metadata is frozen, cannot evolve");
        require(dynamicNFTFactory.ownerOf(_tokenId) != address(0), "SAP: NFT does not exist");

        trigger.activated = true; // Mark as activated to prevent re-triggering

        // The protocol covers the generation fee for automated triggers.
        // Ensure contract has sufficient balance and allowance for the AI oracle.
        string memory fullPrompt = string(abi.encodePacked(
            currentAIParameters.basePromptTemplate,
            " Concept: ", trigger.triggerPrompt,
            ", Evolving existing art, Mood: transformational, Style: ", currentAIParameters.defaultStyle
        ));

        // The AI Oracle's requestGeneration function takes a fee, but in this specific automated scenario,
        // we're assuming the protocol covers it or the oracle has a separate billing mechanism.
        // For simulation, we'll pass 0 as fee. In a real system, the protocol would internally
        // manage its token balance for this.
        requestId = aiOracle.requestGeneration(fullPrompt, 0); // Protocol covers fee
        generationRequests[requestId] = GenerationRequest({
            requester: dynamicNFTFactory.ownerOf(_tokenId), // Original NFT owner is logical requester
            requestId: requestId,
            prompt: fullPrompt,
            timestamp: block.timestamp,
            status: GenerationStatus.Pending,
            resultURI: ""
        });
        requestIdToNFTId[requestId] = _tokenId; // Link request to NFT for direct update upon fulfillment

        reputationScores[msg.sender] += 5; // Reward for triggering evolution
        emit NFTReGenerationRequested(_tokenId, msg.sender, trigger.triggerPrompt); // Re-using event
    }

    // --- IV. Reputation & Staking ---

    /**
     * @dev Users stake SAP Tokens to gain voting power, proposal rights, and reputation.
     * @param _amount The amount of SAP Tokens to stake.
     */
    function stakeTokens(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "SAP: Stake amount must be greater than zero");
        require(sapToken.transferFrom(msg.sender, address(this), _amount), "SAP: Token transfer failed for staking");
        stakedBalances[msg.sender] += _amount;
        // Reputation gain: 1 reputation point for every 10 (base units) staked tokens
        reputationScores[msg.sender] += (_amount / (10 ** sapToken.decimals())) / 10;
        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Users unstake their SAP Tokens. (No cooldown period for simplicity in this example).
     * @param _amount The amount of SAP Tokens to unstake.
     */
    function unstakeTokens(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "SAP: Unstake amount must be greater than zero");
        require(stakedBalances[msg.sender] >= _amount, "SAP: Insufficient staked balance");
        stakedBalances[msg.sender] -= _amount;
        require(sapToken.transfer(msg.sender, _amount), "SAP: Token transfer failed for unstaking");
        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Returns the reputation score for a given address.
     * @param _user The address to query.
     * @return The current reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Distributes reputation rewards to users. Can be called by owner or automated mechanism
     *      (e.g., for high-quality inspirations, successful curators, etc.).
     * @param _users An array of addresses to reward.
     * @param _amounts An array of corresponding reputation amounts.
     */
    function distributeReputationRewards(address[] memory _users, uint256[] memory _amounts) public onlyOwner {
        require(_users.length == _amounts.length, "SAP: Mismatched array lengths");
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "SAP: Cannot reward zero address");
            reputationScores[_users[i]] += _amounts[i];
            emit ReputationRewarded(_users[i], _amounts[i]);
        }
    }

    // --- V. Governance & Treasury ---

    /**
     * @dev Creates a proposal to update the AI's core generative parameters. Requires minimum staked tokens.
     * @param _description Description of the proposal.
     * @param _basePromptTemplate New base prompt template.
     * @param _creativeWeight New creative weight (0-100).
     * @param _styleWeight New style weight (0-100).
     * @param _defaultStyle New default artistic style.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeAIParameterChange(
        string memory _description,
        string memory _basePromptTemplate,
        uint256 _creativeWeight,
        uint256 _styleWeight,
        string memory _defaultStyle
    ) public whenNotPaused returns (uint256 proposalId) {
        require(stakedBalances[msg.sender] >= minStakeForProposal, "SAP: Insufficient stake to create proposal");
        require(bytes(_description).length > 0, "SAP: Description cannot be empty");
        require(_creativeWeight <= 100 && _styleWeight <= 100, "SAP: Weights must be between 0 and 100");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            proposer: msg.sender,
            submitTime: block.timestamp,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days, // 3-day voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false,
            proposalType: ProposalType.AIParameterUpdate,
            // CallData for internal function updateAIParameters, targetting this contract itself
            callData: abi.encodeWithSelector(
                this._updateAIParameters.selector, // Use internal helper
                _basePromptTemplate,
                _creativeWeight,
                _styleWeight,
                _defaultStyle
            ),
            targetContract: address(this),
            recipient: address(0),
            amount: 0
        });
        emit ProposalCreated(proposalId, msg.sender, ProposalType.AIParameterUpdate, _description);
    }

    /**
     * @dev Internal function to update AI parameters. Designed to be called by `executeProposal`.
     *      It effectively transfers temporary 'ownership' for this specific call to the protocol's governance.
     */
    function _updateAIParameters(
        string memory _basePromptTemplate,
        uint256 _creativeWeight,
        uint256 _styleWeight,
        string memory _defaultStyle
    ) internal onlyOwner { // Access restricted to `onlyOwner`, which `executeProposal` temporarily leverages
        currentAIParameters = AIParameters({
            basePromptTemplate: _basePromptTemplate,
            creativeWeight: _creativeWeight,
            styleWeight: _styleWeight,
            defaultStyle: _defaultStyle,
            parameterVersion: currentAIParameters.parameterVersion + 1
        });
        // No explicit event for internal state change, but ProposalExecuted event confirms it.
    }

    /**
     * @dev Creates a proposal to spend treasury funds. Requires minimum staked tokens.
     * @param _description Description of the proposal.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of SAP Tokens (with decimals) to send.
     * @return proposalId The ID of the newly created proposal.
     */
    function createTreasuryProposal(string memory _description, address _recipient, uint256 _amount) public whenNotPaused returns (uint256 proposalId) {
        require(stakedBalances[msg.sender] >= minStakeForProposal, "SAP: Insufficient stake to create proposal");
        require(bytes(_description).length > 0, "SAP: Description cannot be empty");
        require(_recipient != address(0), "SAP: Recipient cannot be zero address");
        require(_amount > 0, "SAP: Amount must be greater than zero");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            proposer: msg.sender,
            submitTime: block.timestamp,
            startTime: block.timestamp,
            endTime: block.timestamp + 3 days, // 3-day voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false,
            proposalType: ProposalType.TreasurySpend,
            callData: bytes(""), // Not used for TreasurySpend when handled directly
            targetContract: address(0), // Not used when handled directly
            recipient: _recipient,
            amount: _amount
        });
        emit ProposalCreated(proposalId, msg.sender, ProposalType.TreasurySpend, _description);
    }

    /**
     * @dev Allows users to vote on active governance proposals. Voting power is determined by staked tokens and reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id > 0, "SAP: Proposal not found");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "SAP: Voting period not active");
        require(!hasVotedOnProposal[_proposalId][msg.sender], "SAP: Already voted on this proposal");
        require(stakedBalances[msg.sender] > 0 || reputationScores[msg.sender] > 0, "SAP: Must have stake or reputation to vote");

        // Calculate voting power: 1 staked token (base units) = 1 VP, 10 reputation points = 1 VP
        uint256 votingPower = (stakedBalances[msg.sender] / (10 ** sapToken.decimals())) + (reputationScores[msg.sender] / 10);
        require(votingPower > 0, "SAP: Insufficient voting power");

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        if (_support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        reputationScores[msg.sender] += 1; // Small reward for participating in governance
        emit ProposalVoted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev Executes a passed governance proposal. Can be called by anyone after the voting period ends.
     *      Handles different proposal types: AI parameter updates via `callData` and treasury spends directly.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id > 0, "SAP: Proposal not found");
        require(block.timestamp > proposal.endTime, "SAP: Voting period not ended");
        require(!proposal.executed, "SAP: Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        // Simple majority for passing. Could add quorum requirement based on total voting power.
        if (totalVotes > 0 && proposal.yesVotes > proposal.noVotes) {
            proposal.passed = true;
            proposal.executed = true; // Mark as executed for state consistency

            if (proposal.proposalType == ProposalType.GenericMessage) {
                emit ProposalExecuted(_proposalId, true);
                return; // No on-chain execution for generic messages
            }

            bool success = false;
            if (proposal.proposalType == ProposalType.AIParameterUpdate) {
                // To call an onlyOwner function (_updateAIParameters) from an external context (executeProposal),
                // we temporarily transfer ownership to `address(this)` itself. This is a common pattern in DAO contracts.
                // The new owner must be the contract itself for the `callData` to succeed with `onlyOwner` modifier.
                address originalOwner = owner();
                _transferOwnership(address(this)); // Temporarily make contract owner

                (success, ) = proposal.targetContract.call(proposal.callData);
                _transferOwnership(originalOwner); // Revert ownership

                require(success, "SAP: AI Parameter update failed");
            } else if (proposal.proposalType == ProposalType.TreasurySpend) {
                // For TreasurySpend, directly transfer funds from contract's balance
                require(sapToken.balanceOf(address(this)) >= proposal.amount, "SAP: Insufficient treasury funds");
                success = sapToken.transfer(proposal.recipient, proposal.amount);
                require(success, "SAP: Treasury funds transfer failed");
            }
            emit ProposalExecuted(_proposalId, success);
        } else {
            proposal.executed = true; // Mark as executed even if it failed to pass
            proposal.passed = false;
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // --- VI. View Functions ---

    /**
     * @dev Returns details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing all details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Returns the currently active AI generative parameters.
     * @return AIParameters struct.
     */
    function getActiveAIParameters() public view returns (AIParameters memory) {
        return currentAIParameters;
    }

    /**
     * @dev Returns the status and details of an AI generation request.
     * @param _requestId The ID of the generation request.
     * @return GenerationRequest struct.
     */
    function getGenerationRequestDetails(bytes32 _requestId) public view returns (GenerationRequest memory) {
        return generationRequests[_requestId];
    }

    /**
     * @dev Returns the curation status for a specific AI-generated art request.
     * @param _requestId The ID of the generation request.
     * @return CurationInfo struct.
     */
    function getCurationStatus(bytes32 _requestId) public view returns (CurationInfo memory) {
        return curations[_requestId];
    }

    /**
     * @dev Returns the staked balance of a user.
     * @param _user The address to query.
     * @return The amount of SAP Tokens staked by the user.
     */
    function getStakedBalance(address _user) public view returns (uint256) {
        return stakedBalances[_user];
    }

    // --- Helper functions for String Conversion (for internal prompt building) ---
    // Source: OpenZeppelin's `Strings.sol` (Simplified for this specific use case)
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits--;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```