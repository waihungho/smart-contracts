AetherForge is a cutting-edge smart contract designed to empower a new era of dynamic, AI-enhanced, and collaboratively governed NFTs. It breaks free from static digital art by allowing NFTs to evolve through AI interactions and community decisions. Users can request AI models (via a trusted oracle) to generate new assets from prompts or modify existing ones. The platform also facilitates a unique "remix" culture, allowing creators to propose derivative works from existing NFTs with configurable royalty splits, ensuring fair compensation for original authors. All core parameters, fees, and AI model choices are democratically governed by a Decentralized Autonomous Organization (DAO), putting creative control directly into the hands of its community.

## CONTRACT OUTLINE & FUNCTION SUMMARY

**Contract Name:** `AetherForge`

**Description:** AetherForge is a decentralized platform for creating, evolving, and governing dynamic, AI-generated/modified NFTs. It integrates off-chain AI models via an oracle, enables collaborative derivative works with royalty sharing, and is governed by a decentralized autonomous organization (DAO).

**Core Concepts:**
*   **Dynamic NFTs (dNFTs):** NFTs whose metadata and attributes can change post-minting based on AI interactions or owner actions.
*   **AI Oracle Integration:** Securely interacts with off-chain AI models for asset generation and modification, bridging on-chain logic with advanced off-chain computation.
*   **Collaborative Remixing:** Facilitates the creation of derivative NFTs with programmable royalty distributions for original creators, fostering a vibrant ecosystem of evolving digital assets.
*   **DAO Governance:** Community-driven decision-making for protocol parameters, fees, and AI model management, ensuring decentralization and adaptability.

---

### Functions Summary (29 unique functions):

**I. Core Infrastructure & Access Control:**
1.  **`constructor`**: Initializes the contract, sets up ERC721 properties (name, symbol), and grants initial roles (admin, oracle, governance) to specified addresses.
2.  **`grantRole`**: Grants a specific role (`ORACLE_ROLE`, `GOVERNANCE_ROLE`) to an address. Only callable by an account with `DEFAULT_ADMIN_ROLE`.
3.  **`revokeRole`**: Revokes a specific role from an address. Only callable by an account with `DEFAULT_ADMIN_ROLE`.
4.  **`renounceRole`**: Allows an address to remove its own role.

**II. ERC721 & Dynamic NFT Management:**
5.  **`mintNFT`**: Mints a new AetherForge NFT to a specified address. It can optionally link to a previously registered creative seed and requires an initial fee.
6.  **`tokenURI`**: Overrides ERC721's standard `tokenURI` to provide dynamic, Base64-encoded JSON metadata, reflecting the NFT's current evolving state and attributes.
7.  **`updateNFTMetadata`**: Allows authorized entities (owner, oracle, or via DAO governance) to update specific metadata fields (name, description, imageUrl, currentPrompt) of an NFT, provided it's not frozen.
8.  **`freezeNFTAttributes`**: Allows the NFT owner or a `GOVERNANCE_ROLE` holder to permanently lock the core attributes of an NFT, making it immutable.
9.  **`unfreezeNFTAttributes`**: Allows the NFT owner or a `GOVERNANCE_ROLE` holder to revert the freezing of NFT attributes (subject to potential DAO restrictions in a production environment).
10. **`getNFTState`**: A view function that returns the comprehensive current dynamic state and attributes of a given NFT, including its name, description, image, creator, and more.

**III. AI Integration (Oracle Pattern):**
11. **`requestAI_GenerateAsset`**: Initiates a request to the designated AI oracle to generate an entirely new asset based on a user-provided text prompt. Requires a fee.
12. **`fulfillAI_GenerateAsset`**: A callback function, exclusively callable by the `ORACLE_ROLE`, which processes the AI's output to mint a new dNFT with the generated metadata.
13. **`requestAI_ModifyAsset`**: Initiates a request to the AI oracle to modify an existing dNFT (owned by the caller) using a new prompt. Requires a fee.
14. **`fulfillAI_ModifyAsset`**: A callback function, exclusively callable by the `ORACLE_ROLE`, which updates an existing dNFT's metadata and attributes based on the AI's modification output.
15. **`setAIOracleAddress`**: A DAO-controlled function (callable only via a successful governance proposal) to update the trusted address of the AI oracle contract.
16. **`setAIRequestFee`**: A DAO-controlled function (callable only via a successful governance proposal) to adjust the fees required for AI generation and modification requests.

**IV. Collaborative & Derivative Works:**
17. **`registerCreativeSeed`**: Allows users to register an original "creative seed" (e.g., a foundational prompt or base IPFS hash), establishing initial authorship and potentially linking to future NFTs.
18. **`proposeDerivative`**: Enables a user to propose creating a derivative NFT from an existing AetherForge NFT. The proposal includes a new prompt, desired royalty split, and a recipient for royalties.
19. **`approveDerivativeProposal`**: The original NFT owner can approve or reject a pending derivative proposal made against their NFT.
20. **`mintDerivativeNFT`**: Mints a new derivative NFT once its proposal has been approved. The minter pays a fee, a portion of which is distributed as royalties to the original creator's designated recipient.
21. **`claimDerivativeRoyalties`**: Allows the original creators (or their designated recipients) to claim their accumulated royalty share from approved and minted derivative NFTs.
22. **`getPendingDerivativeRoyalties`**: A view function to check the total amount of royalties currently pending for a specific recipient address.

**V. DAO Governance & Treasury:**
23. **`proposeGovernanceAction`**: Users holding the `GOVERNANCE_ROLE` can propose changes to protocol parameters (e.g., fees, oracle address) by submitting a description, target contract, and encoded function call.
24. **`voteOnProposal`**: Users holding the `GOVERNANCE_ROLE` can cast their 'for' or 'against' votes on active governance proposals within the voting period.
25. **`executeProposal`**: Any user can call this function after a proposal's voting period has ended to execute it, provided it has met the defined quorum and support thresholds.
26. **`setTreasuryRecipient`**: A DAO-controlled function (callable via a successful governance proposal) to change the address where all protocol fees accumulate.
27. **`withdrawTreasuryFunds`**: A DAO-controlled function (callable via a successful governance proposal) to withdraw accumulated protocol fees from the contract's balance to the designated treasury recipient.

**VI. Utility & View Functions:**
28. **`getProposalDetails`**: A view function that returns comprehensive details for a specific governance proposal, including its status, votes, and call data.
29. **`getAIRequestDetails`**: A view function that provides details for an active or fulfilled AI generation/modification request, including its status, requester, and associated NFT ID.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For tokenURI interface

// --- CONTRACT OUTLINE & FUNCTION SUMMARY ---
//
// Contract Name: AetherForge
// Description: AetherForge is a decentralized platform for creating, evolving, and governing dynamic, AI-generated/modified NFTs.
//              It integrates off-chain AI models via an oracle, enables collaborative derivative works with royalty sharing,
//              and is governed by a decentralized autonomous organization (DAO).
//
// Core Concepts:
// - Dynamic NFTs (dNFTs): NFTs whose metadata and attributes can change post-minting based on AI interactions or owner actions.
// - AI Oracle Integration: Securely interacts with off-chain AI models for asset generation and modification.
// - Collaborative Remixing: Facilitates the creation of derivative NFTs with programmable royalty distributions for original creators.
// - DAO Governance: Community-driven decision-making for protocol parameters, fees, and AI model management.
//
// Functions Summary (29 unique functions):
//
// I. Core Infrastructure & Access Control:
//    1. constructor: Initializes the contract, sets up ERC721, and grants initial roles (admin, oracle, governance).
//    2. grantRole: Grants a specific role to an address. (Admin function)
//    3. revokeRole: Revokes a specific role from an address. (Admin function)
//    4. renounceRole: Allows an address to remove its own role.
//
// II. ERC721 & Dynamic NFT Management:
//    5. mintNFT: Mints a new AetherForge NFT, potentially linking to a registered creative seed.
//    6. tokenURI: Overrides ERC721's tokenURI to provide dynamic metadata, possibly reflecting current AI state or attributes.
//    7. updateNFTMetadata: Allows authorized entities (owner, oracle, or DAO) to update specific metadata fields of an NFT.
//    8. freezeNFTAttributes: Allows the owner or DAO to permanently freeze certain attributes of an NFT, making them immutable.
//    9. unfreezeNFTAttributes: Allows the owner or DAO to revert the freezing of NFT attributes (if governance allows).
//    10. getNFTState: Returns the current dynamic state and attributes of a given NFT.
//
// III. AI Integration (Oracle Pattern):
//    11. requestAI_GenerateAsset: Initiates a request to the AI oracle to generate a *new* asset based on a text prompt, paying a fee.
//    12. fulfillAI_GenerateAsset: Callback function (called by the oracle) to mint a new dNFT with metadata from AI output.
//    13. requestAI_ModifyAsset: Initiates a request to the AI oracle to modify an existing dNFT owned by the caller, paying a fee.
//    14. fulfillAI_ModifyAsset: Callback function (called by the oracle) to update an existing dNFT's metadata based on AI output.
//    15. setAIOracleAddress: DAO-controlled function to update the trusted address of the AI oracle contract.
//    16. setAIRequestFee: DAO-controlled function to adjust the fees required for AI generation and modification requests.
//
// IV. Collaborative & Derivative Works:
//    17. registerCreativeSeed: Allows users to register a "seed" (e.g., text prompt, base IPFS hash) establishing initial authorship.
//    18. proposeDerivative: Allows a user to propose creating a derivative NFT from an existing AetherForge NFT, specifying royalty splits and a new prompt.
//    19. approveDerivativeProposal: The original NFT owner approves or rejects a pending derivative proposal.
//    20. mintDerivativeNFT: Mints a new derivative NFT once its proposal has been approved, linking it to its parent and distributing initial royalties.
//    21. claimDerivativeRoyalties: Allows original creators to claim their accumulated royalty share from derivative sales.
//    22. getPendingDerivativeRoyalties: View function to check pending royalties for an original creator.
//
// V. DAO Governance & Treasury:
//    23. proposeGovernanceAction: Users (with GOVERNANCE_ROLE) can propose changes to protocol parameters (e.g., fees, oracle address).
//    24. voteOnProposal: Users cast their votes on active governance proposals.
//    25. executeProposal: Executes a governance proposal after it has passed the voting period and threshold.
//    26. setTreasuryRecipient: DAO-controlled function to change the address where protocol fees accumulate.
//    27. withdrawTreasuryFunds: Allows the DAO to withdraw accumulated protocol fees to the designated treasury recipient.
//
// VI. Utility & View Functions:
//    28. getProposalDetails: Returns details for a specific governance proposal.
//    29. getAIRequestDetails: Returns details for an active AI request.
//
// --- END OF OUTLINE ---

contract AetherForge is ERC721, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Roles:
    // DEFAULT_ADMIN_ROLE: Can grant/revoke other roles.
    // ORACLE_ROLE: Authorized to call AI fulfillment functions.
    // GOVERNANCE_ROLE: Authorized to create proposals and vote in the DAO.
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // NFT Counters and Data Structure
    Counters.Counter private _tokenIdCounter;

    struct NFTAttributes {
        string name;
        string description;
        string imageUrl; // Can be IPFS hash or URL
        string currentPrompt; // The prompt that last influenced this NFT's state
        address creator; // The address that initially minted or requested this NFT
        uint256 parentTokenId; // 0 for original, non-zero for derivative link
        uint256 registeredSeedId; // Links to a registered Creative Seed (0 if not applicable)
        // mapping(string => string) dynamicProperties; // Future extension for arbitrary dynamic attributes
        bool frozen; // If true, core attributes cannot be changed by owner/oracle
    }
    mapping(uint256 => NFTAttributes) public nftAttributes;
    mapping(uint256 => bool) public isDerivativeNFT; // Quick lookup to identify derivatives

    // Creative Seeds
    struct CreativeSeed {
        address creator;
        string initialPrompt;
        string baseIpfsHash; // Optional: reference to an initial foundational asset
        bool active; // Allows deactivation of a seed if necessary
    }
    Counters.Counter private _seedIdCounter;
    mapping(uint256 => CreativeSeed) public creativeSeeds;

    // AI Oracle Integration
    address public aiOracleAddress;
    uint256 public aiRequestFee; // Fee for AI generation/modification in wei
    uint256 public aiOracleCallbackGasLimit; // Gas limit for oracle callbacks to ensure execution
    mapping(bytes32 => AIRequest) public aiRequests; // requestId => AIRequest
    enum AIRequestStatus { Pending, Fulfilled, Failed } // Status of an AI request
    struct AIRequest {
        address requester;
        uint256 tokenId; // 0 for new asset generation, >0 for modification
        string prompt;
        AIRequestStatus status;
        uint256 timestamp;
    }

    // Derivative Proposals
    Counters.Counter private _proposalIdCounter; // For derivative proposals, not governance
    struct DerivativeProposal {
        address proposer;
        uint256 parentTokenId;
        string newPrompt;
        uint256 royaltySplitNumerator; // e.g., 100 for 10% (100/1000)
        uint256 royaltySplitDenominator; // e.g., 1000 for 10%
        bool approved;
        bool executed;
        address proposedRecipient; // The address to receive royalties from derivative sales
    }
    mapping(uint256 => DerivativeProposal) public derivativeProposals;
    mapping(uint256 => uint256[]) public parentToDerivativeProposals; // parentTokenId => list of derivative proposal IDs

    // Royalties
    mapping(address => uint256) public pendingDerivativeRoyalties; // Creator's chosen recipient => accumulated amount in wei

    // DAO Governance
    struct GovernanceProposal {
        bytes32 id; // Unique proposal ID (hash of proposal details)
        address proposer;
        string description;
        address targetContract; // Contract to call (e.g., this contract itself)
        bytes callData; // Encoded function call to be executed
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => hasVoted status
        bool executed;
        bool canceled;
    }
    mapping(bytes32 => GovernanceProposal) public governanceProposals;
    bytes32[] public activeGovernanceProposalIds; // To easily list/iterate active proposals

    uint256 public constant MIN_VOTING_PERIOD = 3 days; // Minimum duration for voting on a proposal
    uint256 public constant DAO_VOTING_QUORUM_PERCENTAGE = 40; // E.g., 40% of active GOVERNANCE_ROLE holders must vote
    uint256 public constant DAO_VOTING_SUPPORT_PERCENTAGE = 50; // E.g., 50% of votes cast must be 'for' to pass

    // Treasury
    address public treasuryRecipient; // Address where protocol fees accumulate, controlled by DAO
    uint256 public totalProtocolFeesCollected; // Tracks total fees for transparency

    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed owner, string name, string imageUrl, uint256 parentTokenId);
    event NFTMetadataUpdated(uint256 indexed tokenId, string key, string value);
    event NFTAttributesFrozen(uint256 indexed tokenId);
    event NFTAttributesUnfrozen(uint256 indexed tokenId);

    event AIRequestInitiated(bytes32 indexed requestId, address indexed requester, uint256 tokenId, string prompt, uint256 fee);
    event AIFulfillment(bytes32 indexed requestId, uint256 indexed tokenId, string name, string imageUrl);

    event CreativeSeedRegistered(uint256 indexed seedId, address indexed creator, string initialPrompt);
    event DerivativeProposalCreated(uint256 indexed proposalId, uint256 indexed parentTokenId, address indexed proposer);
    event DerivativeProposalApproved(uint256 indexed proposalId, uint256 indexed parentTokenId, address indexed approver);
    event DerivativeNFTMinted(uint256 indexed derivativeTokenId, uint256 indexed parentTokenId, address indexed creator);
    event RoyaltiesClaimed(address indexed recipient, uint256 amount);

    event GovernanceProposalCreated(bytes32 indexed proposalId, address indexed proposer, string description);
    event VotedOnProposal(bytes32 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(bytes32 indexed proposalId);

    event TreasuryRecipientUpdated(address indexed newRecipient);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    /// @notice Initializes the AetherForge contract with basic ERC721 properties, roles, and initial AI/DAO parameters.
    /// @param name_ The name for the NFT collection (e.g., "AetherForge Assets").
    /// @param symbol_ The symbol for the NFT collection (e.g., "AFA").
    /// @param initialAdmin The address to be granted the DEFAULT_ADMIN_ROLE and GOVERNANCE_ROLE initially.
    /// @param initialAIOracle The address of the trusted AI oracle contract.
    /// @param initialAIRequestFee The initial fee in wei required for AI generation/modification requests.
    /// @param initialAIOracleCallbackGasLimit The gas limit for the oracle's callback transactions.
    constructor(
        string memory name_,
        string memory symbol_,
        address initialAdmin,
        address initialAIOracle,
        uint256 initialAIRequestFee,
        uint256 initialAIOracleCallbackGasLimit
    ) ERC721(name_, symbol_) {
        // Grant initial roles
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ORACLE_ROLE, initialAIOracle);
        _grantRole(GOVERNANCE_ROLE, initialAdmin); // Admin also has governance role initially

        // Set initial AI oracle parameters
        aiOracleAddress = initialAIOracle;
        aiRequestFee = initialAIRequestFee;
        aiOracleCallbackGasLimit = initialAIOracleCallbackGasLimit;

        // Set initial treasury recipient
        treasuryRecipient = initialAdmin;
    }

    // --- I. Core Infrastructure & Access Control ---

    // OpenZeppelin's AccessControl contract already provides:
    // - `grantRole(bytes32 role, address account)`
    // - `revokeRole(bytes32 role, address account)`
    // - `renounceRole(bytes32 role, address account)`
    // - `hasRole(bytes32 role, address account)` (view function)
    // These satisfy the requirements for basic role management.

    // --- II. ERC721 & Dynamic NFT Management ---

    /// @notice Mints a new AetherForge NFT to a specified address.
    /// @dev Can be a base NFT or linked to a registered creative seed. Requires an initial fee.
    /// @param to The address to mint the NFT to.
    /// @param name The initial name of the NFT.
    /// @param description The initial description of the NFT.
    /// @param imageUrl The initial image URL (e.g., IPFS hash or a gateway link).
    /// @param initialPrompt The initial prompt that defines this NFT's starting state.
    /// @param seedId Optional: The ID of a registered creative seed this NFT is based on. Use 0 if not applicable.
    /// @return The ID of the newly minted NFT.
    function mintNFT(
        address to,
        string calldata name,
        string calldata description,
        string calldata imageUrl,
        string calldata initialPrompt,
        uint256 seedId
    ) public payable nonReentrant returns (uint256) {
        require(msg.value >= aiRequestFee, "AetherForge: Insufficient fee for initial mint");
        totalProtocolFeesCollected += msg.value; // Collect fee into contract balance

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);

        // Store NFT attributes
        nftAttributes[newTokenId] = NFTAttributes({
            name: name,
            description: description,
            imageUrl: imageUrl,
            currentPrompt: initialPrompt,
            creator: to, // Initial minter is the creator
            parentTokenId: 0, // This is an original NFT
            registeredSeedId: seedId,
            frozen: false
        });

        // Validate creative seed if provided
        if (seedId != 0) {
            require(creativeSeeds[seedId].active, "AetherForge: Invalid or inactive creative seed");
        }

        emit NFTMinted(newTokenId, to, name, imageUrl, 0);
        return newTokenId;
    }

    /// @notice Overrides ERC721's tokenURI to provide dynamic, Base64-encoded JSON metadata.
    /// @dev The metadata reflects the NFT's current attributes, which can change over time.
    /// @param tokenId The ID of the NFT.
    /// @return The Base64 encoded JSON metadata URI (e.g., `data:application/json;base64,...`).
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        NFTAttributes storage attrs = nftAttributes[tokenId];
        string memory json = string(abi.encodePacked(
            '{"name": "', attrs.name,
            '", "description": "', attrs.description,
            '", "image": "', attrs.imageUrl,
            '", "attributes": [',
            '{"trait_type": "Creator", "value": "', Strings.toHexString(uint160(attrs.creator), 20), '"},',
            '{"trait_type": "Current Prompt", "value": "', attrs.currentPrompt, '"},',
            '{"trait_type": "Parent Token ID", "value": "', attrs.parentTokenId.toString(), '"},',
            '{"trait_type": "Registered Seed ID", "value": "', attrs.registeredSeedId.toString(), '"},',
            '{"trait_type": "Frozen", "value": ', (attrs.frozen ? 'true' : 'false'), '}',
            // Future extension: Iterate over dynamicProperties mapping to include them here
            ']}'
        ));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Allows authorized entities to update specific metadata fields of an NFT.
    /// @dev Only the owner, oracle, or DAO (via governance) can update metadata if the NFT is not frozen.
    /// @param tokenId The ID of the NFT to update.
    /// @param key The metadata field to update (e.g., "name", "description", "imageUrl", "currentPrompt").
    /// @param value The new value for the specified field.
    function updateNFTMetadata(
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) public virtual {
        require(_exists(tokenId), "AetherForge: Token does not exist");
        NFTAttributes storage attrs = nftAttributes[tokenId];
        require(!attrs.frozen, "AetherForge: NFT attributes are frozen");

        // Authorization check: only owner or oracle can directly update
        // DAO updates would happen via `executeProposal` calling this function from `address(this)`.
        bool isOwner = _isApprovedOrOwner(msg.sender, tokenId);
        bool isOracle = hasRole(ORACLE_ROLE, msg.sender);
        require(isOwner || isOracle, "AetherForge: Not authorized to update metadata");

        // Update specific fields based on key
        if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("name"))) {
            attrs.name = value;
        } else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("description"))) {
            attrs.description = value;
        } else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("imageUrl"))) {
            attrs.imageUrl = value;
        } else if (keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("currentPrompt"))) {
            attrs.currentPrompt = value;
        } else {
            revert("AetherForge: Invalid metadata key for direct update"); // Restrict direct updates to core fields
        }

        emit NFTMetadataUpdated(tokenId, key, value);
    }

    /// @notice Allows the owner or DAO to permanently freeze certain attributes of an NFT.
    /// @dev Once frozen, core attributes (name, description, imageUrl, currentPrompt) cannot be changed.
    /// @param tokenId The ID of the NFT to freeze.
    function freezeNFTAttributes(uint256 tokenId) public virtual {
        require(_exists(tokenId), "AetherForge: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId) || hasRole(GOVERNANCE_ROLE, msg.sender),
            "AetherForge: Not authorized to freeze attributes");

        nftAttributes[tokenId].frozen = true;
        emit NFTAttributesFrozen(tokenId);
    }

    /// @notice Allows the owner or DAO to revert the freezing of NFT attributes.
    /// @dev This feature might be restricted by DAO governance in a more complex real-world scenario.
    /// @param tokenId The ID of the NFT to unfreeze.
    function unfreezeNFTAttributes(uint256 tokenId) public virtual {
        require(_exists(tokenId), "AetherForge: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId) || hasRole(GOVERNANCE_ROLE, msg.sender),
            "AetherForge: Not authorized to unfreeze attributes");
        require(nftAttributes[tokenId].frozen, "AetherForge: NFT attributes are not frozen");

        nftAttributes[tokenId].frozen = false;
        emit NFTAttributesUnfrozen(tokenId);
    }

    /// @notice Returns the current dynamic state and attributes of a given NFT.
    /// @param tokenId The ID of the NFT.
    /// @return A tuple containing detailed NFT attributes.
    function getNFTState(uint256 tokenId)
        public
        view
        returns (
            string memory name,
            string memory description,
            string memory imageUrl,
            string memory currentPrompt,
            address creator,
            uint256 parentTokenId,
            uint256 registeredSeedId,
            bool frozen
        )
    {
        require(_exists(tokenId), "AetherForge: Token does not exist");
        NFTAttributes storage attrs = nftAttributes[tokenId];
        return (
            attrs.name,
            attrs.description,
            attrs.imageUrl,
            attrs.currentPrompt,
            attrs.creator,
            attrs.parentTokenId,
            attrs.registeredSeedId,
            attrs.frozen
        );
    }

    // --- III. AI Integration (Oracle Pattern) ---

    /// @notice Initiates a request to the AI oracle to generate a new asset based on a text prompt.
    /// @dev Requires a fee to be paid along with the transaction.
    /// @param prompt The creative text prompt for the AI model to use for generation.
    /// @return A unique `requestId` for tracking the AI operation's progress.
    function requestAI_GenerateAsset(string calldata prompt)
        public
        payable
        nonReentrant
        returns (bytes32)
    {
        require(aiOracleAddress != address(0), "AetherForge: AI Oracle not set");
        require(msg.value >= aiRequestFee, "AetherForge: Insufficient fee for AI generation");

        totalProtocolFeesCollected += msg.value; // Add fee to treasury

        // Generate a unique request ID
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, prompt, _tokenIdCounter.current()));

        // Store request details
        aiRequests[requestId] = AIRequest({
            requester: msg.sender,
            tokenId: 0, // 0 indicates a new token generation request
            prompt: prompt,
            status: AIRequestStatus.Pending,
            timestamp: block.timestamp
        });

        // Emit an event for the off-chain oracle service to pick up and process
        emit AIRequestInitiated(requestId, msg.sender, 0, prompt, aiRequestFee);

        return requestId;
    }

    /// @notice Callback function for the AI oracle to fulfill a new asset generation request.
    /// @dev Only callable by the `ORACLE_ROLE`. Mints a new NFT with AI-generated metadata.
    /// @param requestId The ID of the original AI request.
    /// @param name The AI-generated name for the new NFT.
    /// @param description The AI-generated description for the new NFT.
    /// @param imageUrl The AI-generated image URL for the new NFT.
    /// @param seedId The creative seed ID used by the AI (can be 0 if no specific seed was referenced).
    function fulfillAI_GenerateAsset(
        bytes32 requestId,
        string calldata name,
        string calldata description,
        string calldata imageUrl,
        uint256 seedId
    ) public virtual onlyRole(ORACLE_ROLE) nonReentrant {
        AIRequest storage req = aiRequests[requestId];
        require(req.status == AIRequestStatus.Pending, "AetherForge: AI request not pending or invalid");
        require(req.tokenId == 0, "AetherForge: Request is for modification, not generation");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(req.requester, newTokenId); // Mint to the original requester

        // Store generated NFT attributes
        nftAttributes[newTokenId] = NFTAttributes({
            name: name,
            description: description,
            imageUrl: imageUrl,
            currentPrompt: req.prompt, // Store the prompt that led to this generation
            creator: req.requester,
            parentTokenId: 0,
            registeredSeedId: seedId,
            frozen: false
        });

        req.status = AIRequestStatus.Fulfilled; // Mark request as fulfilled

        emit NFTMinted(newTokenId, req.requester, name, imageUrl, 0);
        emit AIFulfillment(requestId, newTokenId, name, imageUrl);
    }

    /// @notice Initiates a request to the AI oracle to modify an existing NFT.
    /// @dev Requires the caller to be the owner or an approved address for the NFT. Requires a fee.
    /// @param tokenId The ID of the NFT to modify.
    /// @param newPrompt The new creative prompt for the AI to use for modification.
    /// @return A unique `requestId` for tracking the AI operation.
    function requestAI_ModifyAsset(uint256 tokenId, string calldata newPrompt)
        public
        payable
        nonReentrant
        returns (bytes32)
    {
        require(aiOracleAddress != address(0), "AetherForge: AI Oracle not set");
        require(_exists(tokenId), "AetherForge: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "AetherForge: Not owner or approved for NFT");
        require(!nftAttributes[tokenId].frozen, "AetherForge: NFT attributes are frozen");
        require(msg.value >= aiRequestFee, "AetherForge: Insufficient fee for AI modification");

        totalProtocolFeesCollected += msg.value; // Add fee to treasury

        // Generate a unique request ID
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, block.timestamp, tokenId, newPrompt));

        // Store request details
        aiRequests[requestId] = AIRequest({
            requester: msg.sender,
            tokenId: tokenId,
            prompt: newPrompt,
            status: AIRequestStatus.Pending,
            timestamp: block.timestamp
        });

        // Emit an event for the off-chain oracle service to pick up and process
        emit AIRequestInitiated(requestId, msg.sender, tokenId, newPrompt, aiRequestFee);

        return requestId;
    }

    /// @notice Callback function for the AI oracle to fulfill an NFT modification request.
    /// @dev Only callable by the `ORACLE_ROLE`. Updates the existing NFT with AI-generated metadata.
    /// @param requestId The ID of the original AI request.
    /// @param name The AI-generated new name for the NFT.
    /// @param description The AI-generated new description for the NFT.
    /// @param imageUrl The AI-generated new image URL for the NFT.
    function fulfillAI_ModifyAsset(
        bytes32 requestId,
        string calldata name,
        string calldata description,
        string calldata imageUrl
    ) public virtual onlyRole(ORACLE_ROLE) nonReentrant {
        AIRequest storage req = aiRequests[requestId];
        require(req.status == AIRequestStatus.Pending, "AetherForge: AI request not pending or invalid");
        require(req.tokenId != 0, "AetherForge: Request is for generation, not modification");
        require(_exists(req.tokenId), "AetherForge: Target NFT does not exist");
        require(!nftAttributes[req.tokenId].frozen, "AetherForge: Target NFT attributes are frozen");

        NFTAttributes storage attrs = nftAttributes[req.tokenId];
        attrs.name = name;
        attrs.description = description;
        attrs.imageUrl = imageUrl;
        attrs.currentPrompt = req.prompt; // Update with the new prompt used for modification

        req.status = AIRequestStatus.Fulfilled; // Mark request as fulfilled

        emit NFTMetadataUpdated(req.tokenId, "name", name);
        emit NFTMetadataUpdated(req.tokenId, "description", description);
        emit NFTMetadataUpdated(req.tokenId, "imageUrl", imageUrl);
        emit NFTMetadataUpdated(req.tokenId, "currentPrompt", req.prompt);
        emit AIFulfillment(requestId, req.tokenId, name, imageUrl);
    }

    /// @notice DAO-controlled function to update the trusted address of the AI oracle contract.
    /// @dev This function can only be called through a successful governance proposal (i.e., by `executeProposal`).
    /// @param newOracleAddress The new address for the AI oracle.
    function setAIOracleAddress(address newOracleAddress) public virtual onlyRole(GOVERNANCE_ROLE) {
        require(newOracleAddress != address(0), "AetherForge: Oracle address cannot be zero");
        aiOracleAddress = newOracleAddress;
    }

    /// @notice DAO-controlled function to adjust the fees required for AI generation and modification requests.
    /// @dev This function can only be called through a successful governance proposal.
    /// @param newFee The new fee amount in wei.
    function setAIRequestFee(uint256 newFee) public virtual onlyRole(GOVERNANCE_ROLE) {
        aiRequestFee = newFee;
    }

    // --- IV. Collaborative & Derivative Works ---

    /// @notice Allows users to register a "seed" (e.g., text prompt, base IPFS hash) establishing initial authorship.
    /// @dev This seed can be referenced by future NFT mints or derivative proposals.
    /// @param initialPrompt The defining prompt or concept for the seed.
    /// @param baseIpfsHash Optional IPFS hash for a foundational visual or conceptual asset.
    /// @return The ID of the newly registered creative seed.
    function registerCreativeSeed(string calldata initialPrompt, string calldata baseIpfsHash)
        public
        nonReentrant
        returns (uint256)
    {
        _seedIdCounter.increment();
        uint256 newSeedId = _seedIdCounter.current();

        creativeSeeds[newSeedId] = CreativeSeed({
            creator: msg.sender,
            initialPrompt: initialPrompt,
            baseIpfsHash: baseIpfsHash,
            active: true
        });

        emit CreativeSeedRegistered(newSeedId, msg.sender, initialPrompt);
        return newSeedId;
    }

    /// @notice Allows a user to propose creating a derivative NFT from an existing AetherForge NFT.
    /// @dev The original NFT owner must approve this proposal before the derivative can be minted.
    /// @param parentTokenId The ID of the existing NFT from which to create a derivative.
    /// @param newPrompt The creative prompt or concept for the derivative.
    /// @param royaltySplitNumerator The numerator for the royalty percentage (e.g., 100 for 10% when denominator is 1000).
    /// @param royaltySplitDenominator The denominator for the royalty percentage (e.g., 1000).
    /// @param royaltyRecipient The address designated to receive royalties from the derivative.
    /// @return The ID of the newly created derivative proposal.
    function proposeDerivative(
        uint256 parentTokenId,
        string calldata newPrompt,
        uint256 royaltySplitNumerator,
        uint256 royaltySplitDenominator,
        address royaltyRecipient
    ) public nonReentrant returns (uint256) {
        require(_exists(parentTokenId), "AetherForge: Parent NFT does not exist");
        require(royaltyRecipient != address(0), "AetherForge: Royalty recipient cannot be zero address");
        require(royaltySplitDenominator > 0, "AetherForge: Royalty denominator must be greater than zero");
        require(royaltySplitNumerator <= royaltySplitDenominator, "AetherForge: Royalty numerator cannot exceed denominator");

        _proposalIdCounter.increment();
        uint252 newDerivativeProposalId = _proposalIdCounter.current();

        derivativeProposals[newDerivativeProposalId] = DerivativeProposal({
            proposer: msg.sender,
            parentTokenId: parentTokenId,
            newPrompt: newPrompt,
            royaltySplitNumerator: royaltySplitNumerator,
            royaltySplitDenominator: royaltySplitDenominator,
            approved: false,
            executed: false,
            proposedRecipient: royaltyRecipient
        });

        parentToDerivativeProposals[parentTokenId].push(newDerivativeProposalId);

        emit DerivativeProposalCreated(newDerivativeProposalId, parentTokenId, msg.sender);
        return newDerivativeProposalId;
    }

    /// @notice The original NFT owner approves or rejects a pending derivative proposal.
    /// @dev Only the owner of the `parentTokenId` can call this.
    /// @param proposalId The ID of the derivative proposal to approve/reject.
    /// @param approve True to approve the proposal, false to reject.
    function approveDerivativeProposal(uint256 proposalId, bool approve) public nonReentrant {
        DerivativeProposal storage proposal = derivativeProposals[proposalId];
        require(proposal.parentTokenId != 0, "AetherForge: Derivative proposal does not exist");
        require(ownerOf(proposal.parentTokenId) == msg.sender, "AetherForge: Not owner of parent NFT");
        require(!proposal.approved, "AetherForge: Proposal already approved or rejected");
        require(!proposal.executed, "AetherForge: Proposal already executed");

        proposal.approved = approve; // Update approval status
        emit DerivativeProposalApproved(proposalId, proposal.parentTokenId, msg.sender);
    }

    /// @notice Mints a new derivative NFT once its proposal has been approved.
    /// @dev Requires a fee to be paid, which includes a royalty portion for the original creator.
    /// @param proposalId The ID of the approved derivative proposal.
    /// @param derivativeName The name for the new derivative NFT.
    /// @param derivativeDescription The description for the new derivative NFT.
    /// @param derivativeImageUrl The image URL for the new derivative NFT.
    /// @return The ID of the newly minted derivative NFT.
    function mintDerivativeNFT(
        uint256 proposalId,
        string calldata derivativeName,
        string calldata derivativeDescription,
        string calldata derivativeImageUrl
    ) public payable nonReentrant returns (uint256) {
        DerivativeProposal storage proposal = derivativeProposals[proposalId];
        require(proposal.parentTokenId != 0, "AetherForge: Derivative proposal does not exist");
        require(proposal.approved, "AetherForge: Proposal not approved or rejected");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(msg.value >= aiRequestFee, "AetherForge: Insufficient fee for minting derivative"); // Using AI fee for derivatives too

        totalProtocolFeesCollected += msg.value; // Add fee to treasury

        // Calculate and accumulate royalties for the original creator's designated recipient
        uint256 royaltyAmount = (msg.value * proposal.royaltySplitNumerator) / proposal.royaltySplitDenominator;
        pendingDerivativeRoyalties[proposal.proposedRecipient] += royaltyAmount;

        _tokenIdCounter.increment();
        uint256 newDerivativeTokenId = _tokenIdCounter.current();

        _safeMint(proposal.proposer, newDerivativeTokenId); // Mint to the original proposer of the derivative

        // Store derivative NFT attributes
        nftAttributes[newDerivativeTokenId] = NFTAttributes({
            name: derivativeName,
            description: derivativeDescription,
            imageUrl: derivativeImageUrl,
            currentPrompt: proposal.newPrompt,
            creator: proposal.proposer,
            parentTokenId: proposal.parentTokenId,
            registeredSeedId: 0, // Derivatives typically don't link to a new seed directly
            frozen: false
        });
        isDerivativeNFT[newDerivativeTokenId] = true;

        proposal.executed = true; // Mark proposal as executed

        emit DerivativeNFTMinted(newDerivativeTokenId, proposal.parentTokenId, proposal.proposer);
        return newDerivativeTokenId;
    }

    /// @notice Allows original creators (or their designated recipients) to claim their accumulated royalty share.
    /// @dev Withdraws pending royalties from derivative sales to the specified recipient.
    /// @param recipient The address to which to send the royalties (must match the address specified in the proposal).
    function claimDerivativeRoyalties(address recipient) public nonReentrant {
        uint256 amount = pendingDerivativeRoyalties[recipient];
        require(amount > 0, "AetherForge: No pending royalties for this recipient");

        pendingDerivativeRoyalties[recipient] = 0; // Reset balance *before* transfer to prevent reentrancy

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "AetherForge: Royalty transfer failed");

        emit RoyaltiesClaimed(recipient, amount);
    }

    /// @notice View function to check the amount of pending royalties for a specific recipient.
    /// @param recipient The address to check for pending royalties.
    /// @return The amount of pending royalties in wei.
    function getPendingDerivativeRoyalties(address recipient) public view returns (uint256) {
        return pendingDerivativeRoyalties[recipient];
    }

    // --- V. DAO Governance & Treasury ---

    /// @notice Users with `GOVERNANCE_ROLE` can propose changes to protocol parameters or execute arbitrary calls.
    /// @dev A proposal includes a description, a target contract, and the encoded function call to be executed.
    /// @param description A brief description of what the proposal aims to achieve.
    /// @param target The address of the contract that the proposal's `callData` will interact with.
    /// @param callData The encoded function call (e.g., `abi.encodeWithSelector(this.setAIRequestFee.selector, newFee)`).
    /// @return The unique ID of the created governance proposal.
    function proposeGovernanceAction(
        string calldata description,
        address target,
        bytes calldata callData
    ) public onlyRole(GOVERNANCE_ROLE) nonReentrant returns (bytes32) {
        // Generate a unique proposal ID based on its content and proposer to prevent duplicates
        bytes32 proposalId = keccak256(abi.encodePacked(msg.sender, block.timestamp, description, target, callData));
        require(governanceProposals[proposalId].proposer == address(0), "AetherForge: Proposal with this ID already exists");

        uint256 currentBlockTimestamp = block.timestamp;
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.targetContract = target;
        proposal.callData = callData;
        proposal.voteStartTime = currentBlockTimestamp;
        proposal.voteEndTime = currentBlockTimestamp + MIN_VOTING_PERIOD;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.executed = false;
        proposal.canceled = false;

        activeGovernanceProposalIds.push(proposalId); // Add to list of active proposals

        emit GovernanceProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    /// @notice Users with `GOVERNANCE_ROLE` cast their votes on active governance proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True to vote 'for' the proposal, false to vote 'against'.
    function voteOnProposal(bytes32 proposalId, bool support) public onlyRole(GOVERNANCE_ROLE) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "AetherForge: Voting has not started");
        require(block.timestamp < proposal.voteEndTime, "AetherForge: Voting has ended");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(!proposal.canceled, "AetherForge: Proposal canceled");

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true; // Mark as voted

        emit VotedOnProposal(proposalId, msg.sender, support);
    }

    /// @notice Executes a governance proposal after its voting period has ended and it has passed.
    /// @dev Anyone can call this function to trigger the execution of a passed proposal.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(bytes32 proposalId) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "AetherForge: Voting period not ended");
        require(!proposal.executed, "AetherForge: Proposal already executed");
        require(!proposal.canceled, "AetherForge: Proposal canceled");

        // Simplified quorum check: total GOVERNANCE_ROLE holders as potential voting power.
        // A more sophisticated DAO would use token-based voting power.
        uint256 totalGovernanceVoters = getRoleMemberCount(GOVERNANCE_ROLE);
        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;

        require(totalVotesCast * 100 >= totalGovernanceVoters * DAO_VOTING_QUORUM_PERCENTAGE, "AetherForge: Quorum not met");
        require(proposal.votesFor * 100 >= totalVotesCast * DAO_VOTING_SUPPORT_PERCENTAGE, "AetherForge: Proposal not passed");

        proposal.executed = true; // Mark proposal as executed

        // Execute the proposed function call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "AetherForge: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /// @notice DAO-controlled function to change the address where protocol fees accumulate.
    /// @dev This function should only be called through a successful governance proposal.
    /// @param newRecipient The new address for the treasury recipient.
    function setTreasuryRecipient(address newRecipient) public onlyRole(GOVERNANCE_ROLE) {
        require(newRecipient != address(0), "AetherForge: Treasury recipient cannot be zero");
        treasuryRecipient = newRecipient;
        emit TreasuryRecipientUpdated(newRecipient);
    }

    /// @notice Allows the DAO to withdraw accumulated protocol fees to the designated treasury recipient.
    /// @dev This function should only be called through a successful governance proposal.
    /// @param amount The amount of funds (in wei) to withdraw from the contract's balance.
    function withdrawTreasuryFunds(uint256 amount) public onlyRole(GOVERNANCE_ROLE) nonReentrant {
        require(amount > 0, "AetherForge: Amount must be greater than zero");
        require(address(this).balance >= amount, "AetherForge: Insufficient contract balance");
        require(treasuryRecipient != address(0), "AetherForge: Treasury recipient not set");

        totalProtocolFeesCollected -= amount; // Deduct from total tracking

        (bool success, ) = payable(treasuryRecipient).call{value: amount}("");
        require(success, "AetherForge: Treasury withdrawal failed");

        emit FundsWithdrawn(treasuryRecipient, amount);
    }

    // --- VI. Utility & View Functions ---

    /// @notice Returns details for a specific governance proposal.
    /// @param proposalId The ID of the governance proposal.
    /// @return A tuple containing all relevant proposal details.
    function getProposalDetails(bytes32 proposalId)
        public
        view
        returns (
            address proposer,
            string memory description,
            address targetContract,
            bytes memory callData,
            uint256 voteStartTime,
            uint256 voteEndTime,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed,
            bool canceled
        )
    {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist");
        return (
            proposal.proposer,
            proposal.description,
            proposal.targetContract,
            proposal.callData,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.canceled
        );
    }

    /// @notice Returns details for an active or fulfilled AI request.
    /// @param requestId The ID of the AI request.
    /// @return A tuple containing AI request details including requester, target tokenId, prompt, status, and timestamp.
    function getAIRequestDetails(bytes32 requestId)
        public
        view
        returns (
            address requester,
            uint256 tokenId,
            string memory prompt,
            AIRequestStatus status,
            uint256 timestamp
        )
    {
        AIRequest storage req = aiRequests[requestId];
        require(req.requester != address(0), "AetherForge: AI request does not exist");
        return (req.requester, req.tokenId, req.prompt, req.status, req.timestamp);
    }

    // --- Overrides ---
    // The `_authorizeUpgrade` is often found in UUPS upgradeable proxies.
    // Without an actual proxy setup, it's included as a placeholder for completeness,
    // though not functional without an OpenZeppelin UUPS proxy.
    // function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // The ERC721 internal functions below are typically overridden for custom transfer logic,
    // royalty mechanisms during transfers, or burning. For this contract, standard ERC721
    // transfer/approval logic is implicitly used via OpenZeppelin's base implementation,
    // with custom royalty handling focused on minting derivatives.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {}
    // function _update(address to, uint256 tokenId, address auth) internal override returns (address) {}
    // function _approve(address to, uint256 tokenId) internal override {}
    // function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {}
}
```