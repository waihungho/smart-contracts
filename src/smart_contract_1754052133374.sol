Okay, this is an exciting challenge! Let's design a smart contract for a decentralized, AI-assisted creative collaboration and dynamic IP ownership platform. The core idea is that creators, AI models (represented by oracles), and curators collaborate to generate unique digital assets, with ownership and royalties dynamically adjusting based on contributions, reputation, and the "evolution" of the content.

We'll call this the **Artificer Nexus Protocol**.

---

## Artificer Nexus Protocol: Dynamic Co-Creation & Evolving IP

### Outline and Function Summary

The `ArtificerNexus` smart contract serves as the backbone for a decentralized platform where users can collaborate with AI (via oracles) to create dynamic digital assets. It manages prompt creation, component staking, AI-driven content generation, evolving intellectual property (IP) ownership, reputation for creators and curators, and a dynamic royalty distribution mechanism.

**Core Concepts:**

*   **Prompts (ERC-721):** Initial ideas or creative seeds.
*   **Components (ERC-1155):** Reusable stylistic elements, datasets, or algorithms.
*   **Artificer Creations (ERC-721):** Final, AI-generated, and human-curated artworks or content pieces.
*   **Dynamic IP & Royalties:** Ownership shares and royalty distributions for Creations can change over time based on new contributions, enhancements, and curator evaluations.
*   **Reputation System:** For Creators and Curators, influencing their weight in various processes.
*   **AI Integration (via Oracle):** The contract requests AI processing from a trusted off-chain oracle, which then submits the results.

---

### Function Summary:

**I. Administrative & Core Protocol Management (6 Functions)**
1.  `constructor()`: Initializes the contract with an admin address and initial oracle.
2.  `setArtificerOracle(address _oracle)`: Sets or updates the trusted AI oracle address.
3.  `pauseContract()`: Emergency function to pause critical operations.
4.  `unpauseContract()`: Unpauses the contract after an emergency.
5.  `withdrawProtocolFees(address _to)`: Allows the owner to withdraw accumulated protocol fees.
6.  `updateProtocolParameter(uint256 _paramId, uint256 _newValue)`: General function to update various configurable protocol parameters (e.g., fee percentages, staking minimums).

**II. Prompt Management (ERC-721 - Creative Seeds) (4 Functions)**
7.  `mintPrompt(string memory _promptURI, bytes32 _promptHash)`: Mints a new ERC-721 Prompt token.
8.  `proposePromptEnhancement(uint256 _promptId, string memory _newURI, bytes32 _newHash)`: Allows a Prompt owner to propose an enhancement (update URI/hash).
9.  `approvePromptEnhancement(uint256 _promptId, uint256 _proposalId)`: Allows the Prompt owner or a delegated entity to approve a pending enhancement.
10. `getPromptDetails(uint256 _promptId)`: View function to retrieve details of a Prompt.

**III. Component Management (ERC-1155 - Reusable Elements) (4 Functions)**
11. `mintComponent(string memory _componentURI, bytes32 _componentHash, uint256 _initialSupply)`: Mints a new ERC-1155 Component token with an initial supply.
12. `stakeComponentForUse(uint256 _componentId, uint256 _amount)`: Allows Component owners to stake their components, making them available for others to use in creations.
13. `unstakeComponent(uint256 _componentId, uint256 _amount)`: Allows Component owners to unstake their components.
14. `getComponentDetails(uint256 _componentId)`: View function to retrieve details of a Component.

**IV. Artificer Creation & AI Orchestration (6 Functions)**
15. `submitCreationRequest(uint256 _promptId, uint256[] memory _componentIds, uint256[] memory _componentAmounts)`: Initiates a request for the AI oracle to generate a new piece of content based on a Prompt and staked Components.
16. `fulfillCreationRequest(uint256 _requestId, string memory _artificerURI, bytes32 _artificerHash, address[] memory _aiContributors, uint256[] memory _aiContributions)`: Called *only by the Artificer Oracle* to deliver the result of a creative request, including generated content URI/hash and AI model contributions.
17. `mintArtificerCreation(uint256 _requestId)`: Mints the final ERC-721 `ArtificerCreation` NFT once a request has been fulfilled by the oracle.
18. `enhanceArtificerCreation(uint256 _creationId, uint256 _promptId, uint256[] memory _componentIds, uint256[] memory _componentAmounts)`: Allows an existing Artificer Creation to be enhanced by new inputs, triggering a new AI processing request.
19. `updateCollaborationShare(uint256 _creationId, address _collaborator, uint256 _newShareBasisPoints)`: Allows a `Creation` owner to adjust the *basis points* of a collaborator's share.
20. `getCreationDetails(uint256 _creationId)`: View function to retrieve all details of an Artificer Creation.

**V. Reputation & Curation System (3 Functions)**
21. `submitCuratorVote(uint256 _creationId, uint256 _score)`: Allows registered curators to vote on the quality of a Creation. This influences creator reputation and dynamic royalties.
22. `updateCreatorReputation(address _creator)`: Triggered internally (or manually by owner for recalculation) to update a creator's reputation based on their creations' scores.
23. `getCreatorReputation(address _creator)`: View function to retrieve a creator's current reputation score.

**VI. Dynamic Royalty Distribution (2 Functions)**
24. `calculateDynamicRoyalties(uint256 _creationId, uint256 _totalAmount)`: Internal/view function to calculate the current royalty distribution for a given creation based on its evolving shares and contributions.
25. `distributeRoyalties(uint256 _creationId)`: Allows anyone to trigger the distribution of accumulated royalties for a specific creation to all its current contributors.

**VII. Governance & Advanced Features (3 Functions - conceptual/future-ready)**
26. `proposeGovernanceChange(string memory _description, address _target, bytes memory _calldata)`: Initiates a governance proposal for protocol upgrades or parameter changes.
27. `voteOnGovernanceChange(uint256 _proposalId, bool _support)`: Allows stakeholders to vote on active governance proposals.
28. `delegateReputationVote(address _delegatee)`: Allows a creator to delegate their reputation-based voting power to another address.

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Custom Errors for better readability and gas efficiency
error ArtificerNexus__InvalidOracle();
error ArtificerNexus__RequestNotFound();
error ArtificerNexus__RequestNotFulfilled();
error ArtificerNexus__RequestAlreadyFulfilled();
error ArtificerNexus__UnauthorizedOracle();
error ArtificerNexus__InvalidComponentAmount();
error ArtificerNexus__NotEnoughStakedComponents();
error ArtificerNexus__CreationAlreadyMinted();
error ArtificerNexus__CreationNotFound();
error ArtificerNexus__NotCreatorOrOwner();
error ArtificerNexus__InvalidScore();
error ArtificerNexus__NotEnoughFunds();
error ArtificerNexus__NoRoyaltiesAccrued();
error ArtificerNexus__InvalidParameterId();
error ArtificerNexus__PromptEnhancementNotFound();
error ArtificerNexus__PromptEnhancementAlreadyApproved();
error ArtificerNexus__NotPromptOwner();
error ArtificerNexus__InvalidShareBasisPoints();
error ArtificerNexus__SelfVoteNotAllowed();
error ArtificerNexus__AlreadyVoted();
error ArtificerNexus__ProposalNotFound();
error ArtificerNexus__ProposalNotActive();
error ArtificerNexus__VotePeriodEnded();
error ArtificerNexus__InvalidDelegatee();
error ArtificerNexus__CannotDelegateToSelf();


interface IArtificerOracle {
    // Function that the oracle will call back to the main contract
    function fulfillCreationRequest(
        uint256 _requestId,
        string calldata _artificerURI,
        bytes32 _artificerHash,
        address[] calldata _aiContributors,
        uint256[] calldata _aiContributions // Basis points, sum should be 10,000
    ) external;
}

contract ArtificerNexus is Ownable, Pausable, ReentrancyGuard, ERC721URIStorage, ERC1155 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Protocol Fees & Parameters
    uint256 public constant MAX_BASIS_POINTS = 10000; // 100% represented as 10,000 basis points
    uint256 public protocolFeeBasisPoints; // e.g., 500 for 5%
    uint256 public minStakingAmount;
    uint256 public curatorVoteThreshold; // Minimum reputation to be a curator
    uint256 public reputationDecayRate; // How much reputation decays over time (conceptual)

    // Oracle Address
    address public artificerOracle;

    // --- Counters for unique IDs ---
    Counters.Counter private _promptIdCounter;
    Counters.Counter private _componentIdCounter;
    Counters.Counter private _creationRequestIdCounter;
    Counters.Counter private _artificerCreationIdCounter;
    Counters.Counter private _governanceProposalIdCounter;

    // --- Data Structures ---

    enum RequestStatus { Pending, Fulfilled, Minted }
    enum ProposalStatus { Active, Succeeded, Failed, Executed }

    struct Prompt {
        uint256 id;
        address creator;
        string uri;
        bytes32 contentHash;
        uint256 createdAt;
        // For enhancements
        mapping(uint256 => PromptEnhancement) enhancements;
        Counters.Counter enhancementCounter;
    }

    struct PromptEnhancement {
        uint256 id;
        string newURI;
        bytes32 newHash;
        bool approved;
        address proposer;
        uint256 proposedAt;
    }

    struct Component {
        uint256 id;
        address creator;
        string uri;
        bytes32 contentHash;
        uint256 createdAt;
    }

    struct StakedComponent {
        uint256 componentId;
        uint256 amount;
        uint256 stakedAt;
    }

    struct CreationRequest {
        uint256 id;
        address requester; // The user who initiated the request
        uint256 promptId;
        uint256[] componentIds;
        uint256[] componentAmounts; // Amount of each component used
        RequestStatus status;
        string artificerURI; // URI of the AI-generated content
        bytes32 artificerHash; // Hash of the AI-generated content
        address[] aiContributors; // Addresses representing AI models/agents
        uint256[] aiContributionShares; // Contribution shares (basis points) for AI models
        uint256 requestedAt;
        uint256 fulfilledAt;
        uint256 mintedCreationId; // If minted, the ID of the ArtificerCreation
    }

    struct ArtificerCreation {
        uint256 id; // ERC-721 Token ID
        address creator; // The original requester of the creation
        uint256 creationRequestId; // Link to the request that generated it
        string currentURI;
        bytes32 currentHash;
        uint256 createdAt;
        mapping(address => CollaborationShare) collaborationShares; // Current dynamic ownership shares
        address[] currentCollaborators; // List of active collaborators to iterate
        uint256 totalSharesBasisPoints; // Sum of all current collaboration shares, should be MAX_BASIS_POINTS
        uint256 totalRoyaltyAccrued; // Total royalties accrued for this creation
        uint256 lastRoyaltyDistribution; // Timestamp of last distribution
    }

    struct CollaborationShare {
        uint256 shareBasisPoints; // Portion of MAX_BASIS_POINTS
        uint256 lastContributionUpdate; // Timestamp of last update to this share
    }

    struct GovernanceProposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        uint256 voteThreshold; // Required votes to pass
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }

    // --- Mappings ---
    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => Component) public components;
    mapping(address => mapping(uint256 => StakedComponent)) public stakedComponents; // owner => componentId => StakedComponent
    mapping(address => mapping(uint256 => uint256)) public stakedComponentBalances; // owner => componentId => balance

    mapping(uint256 => CreationRequest) public creationRequests;
    mapping(uint256 => ArtificerCreation) public artificerCreations; // Artificer NFT ID => Creation details

    mapping(address => uint256) public creatorReputation; // Creator address => Reputation score
    mapping(uint256 => mapping(address => bool)) public hasCuratorVoted; // Creation ID => Curator Address => Voted
    mapping(uint256 => uint256) public creationTotalVoteScore; // Creation ID => Sum of curator scores
    mapping(uint256 => uint256) public creationVoteCount; // Creation ID => Number of unique curator votes

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => address) public reputationDelegates; // Creator => Delegatee

    // --- Events ---
    event ArtificerOracleUpdated(address indexed newOracle);
    event ProtocolParameterUpdated(uint256 indexed paramId, uint256 newValue);
    event PromptMinted(uint256 indexed promptId, address indexed creator, string uri);
    event PromptEnhancementProposed(uint256 indexed promptId, uint256 indexed proposalId, string newURI, address proposer);
    event PromptEnhancementApproved(uint256 indexed promptId, uint256 indexed proposalId);
    event ComponentMinted(uint256 indexed componentId, address indexed creator, string uri, uint256 initialSupply);
    event ComponentStaked(address indexed staker, uint256 indexed componentId, uint256 amount);
    event ComponentUnstaked(address indexed unstaker, uint256 indexed componentId, uint256 amount);
    event CreationRequestSubmitted(uint256 indexed requestId, address indexed requester, uint256 promptId);
    event CreationRequestFulfilled(uint256 indexed requestId, string artificerURI, bytes32 artificerHash, address[] aiContributors, uint256[] aiContributions);
    event ArtificerCreationMinted(uint256 indexed creationId, uint256 indexed requestId, address indexed owner, string uri);
    event ArtificerCreationEnhanced(uint256 indexed creationId, uint256 indexed newRequestId);
    event CollaborationShareUpdated(uint256 indexed creationId, address indexed collaborator, uint256 newShareBasisPoints);
    event CuratorVoteSubmitted(uint256 indexed creationId, address indexed curator, uint256 score);
    event CreatorReputationUpdated(address indexed creator, uint256 newReputation);
    event RoyaltiesDistributed(uint256 indexed creationId, uint256 totalAmountDistributed);
    event GovernanceProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);


    // --- Constructor ---
    constructor(address _initialOracle) ERC721("ArtificerPrompt", "ARTIP") ERC1155("https://artificer.nexus/component/{id}.json") {
        if (_initialOracle == address(0)) {
            revert ArtificerNexus__InvalidOracle();
        }
        artificerOracle = _initialOracle;
        _setOwner(msg.sender); // Set contract deployer as owner
        _pause(); // Start paused for initial setup
        protocolFeeBasisPoints = 500; // 5% protocol fee
        minStakingAmount = 1; // Minimum 1 component to stake
        curatorVoteThreshold = 1000; // Example: Minimum reputation score of 1000 to be a curator
        reputationDecayRate = 1; // Example: 1 basis point per day (conceptual)
    }

    // --- Modifiers ---
    modifier onlyArtificerOracle() {
        if (msg.sender != artificerOracle) {
            revert ArtificerNexus__UnauthorizedOracle();
        }
        _;
    }

    modifier onlyCreationOwner(uint256 _creationId) {
        if (ERC721.ownerOf(_creationId) != msg.sender) {
            revert NotCreatorOrOwner();
        }
        _;
    }

    modifier onlyPromptOwner(uint256 _promptId) {
        if (ERC721.ownerOf(_promptId) != msg.sender) {
            revert NotPromptOwner();
        }
        _;
    }

    // --- I. Administrative & Core Protocol Management ---

    function setArtificerOracle(address _oracle) external onlyOwner whenPaused {
        if (_oracle == address(0)) {
            revert ArtificerNexus__InvalidOracle();
        }
        artificerOracle = _oracle;
        emit ArtificerOracleUpdated(_oracle);
    }

    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    function withdrawProtocolFees(address _to) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert ArtificerNexus__NoRoyaltiesAccrued(); // Reusing error, should be a specific 'no fees' error
        }
        // Exclude the ETH sent with _submitCreationRequest which is for royalties
        // This function would ideally only withdraw protocol's share, not all ETH.
        // For simplicity, we assume this is only called when there's an actual accrued fee balance.
        // A more robust system would track protocol's specific balance separately.
        (bool success,) = _to.call{value: balance}("");
        if (!success) {
            revert ArtificerNexus__NotEnoughFunds(); // Reusing for failed transfer
        }
    }

    // Example parameter IDs: 1 for protocolFeeBasisPoints, 2 for minStakingAmount, etc.
    function updateProtocolParameter(uint256 _paramId, uint256 _newValue) external onlyOwner whenPaused {
        if (_paramId == 1) {
            protocolFeeBasisPoints = _newValue;
        } else if (_paramId == 2) {
            minStakingAmount = _newValue;
        } else if (_paramId == 3) {
            curatorVoteThreshold = _newValue;
        } else if (_paramId == 4) {
            reputationDecayRate = _newValue;
        } else {
            revert ArtificerNexus__InvalidParameterId();
        }
        emit ProtocolParameterUpdated(_paramId, _newValue);
    }

    // --- II. Prompt Management (ERC-721 - Creative Seeds) ---

    function mintPrompt(string memory _promptURI, bytes32 _promptHash) external whenNotPaused returns (uint256) {
        _promptIdCounter.increment();
        uint256 newPromptId = _promptIdCounter.current();
        prompts[newPromptId] = Prompt(newPromptId, msg.sender, _promptURI, _promptHash, block.timestamp);
        _mint(msg.sender, newPromptId);
        _setTokenURI(newPromptId, _promptURI);
        emit PromptMinted(newPromptId, msg.sender, _promptURI);
        return newPromptId;
    }

    function proposePromptEnhancement(uint256 _promptId, string memory _newURI, bytes32 _newHash) external whenNotPaused {
        if (ERC721.ownerOf(_promptId) != msg.sender) {
            revert NotPromptOwner();
        }
        Prompt storage prompt = prompts[_promptId];
        prompt.enhancementCounter.increment();
        uint256 proposalId = prompt.enhancementCounter.current();
        prompt.enhancements[proposalId] = PromptEnhancement(proposalId, _newURI, _newHash, false, msg.sender, block.timestamp);
        emit PromptEnhancementProposed(_promptId, proposalId, _newURI, msg.sender);
    }

    function approvePromptEnhancement(uint256 _promptId, uint256 _proposalId) external whenNotPaused onlyPromptOwner(_promptId) {
        Prompt storage prompt = prompts[_promptId];
        PromptEnhancement storage enhancement = prompt.enhancements[_proposalId];
        if (enhancement.id == 0) {
            revert ArtificerNexus__PromptEnhancementNotFound();
        }
        if (enhancement.approved) {
            revert ArtificerNexus__PromptEnhancementAlreadyApproved();
        }

        enhancement.approved = true;
        prompt.uri = enhancement.newURI;
        prompt.contentHash = enhancement.newHash;
        _setTokenURI(_promptId, prompt.uri); // Update ERC721 metadata URI
        emit PromptEnhancementApproved(_promptId, _proposalId);
    }

    function getPromptDetails(uint256 _promptId) external view returns (uint256 id, address creator, string memory uri, bytes32 contentHash, uint256 createdAt) {
        Prompt storage prompt = prompts[_promptId];
        return (prompt.id, prompt.creator, prompt.uri, prompt.contentHash, prompt.createdAt);
    }

    // --- III. Component Management (ERC-1155 - Reusable Elements) ---

    function mintComponent(string memory _componentURI, bytes32 _componentHash, uint256 _initialSupply) external whenNotPaused returns (uint256) {
        _componentIdCounter.increment();
        uint256 newComponentId = _componentIdCounter.current();
        components[newComponentId] = Component(newComponentId, msg.sender, _componentURI, _componentHash, block.timestamp);
        _mint(msg.sender, newComponentId, _initialSupply, "");
        emit ComponentMinted(newComponentId, msg.sender, _componentURI, _initialSupply);
        return newComponentId;
    }

    function stakeComponentForUse(uint256 _componentId, uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0 || _amount < minStakingAmount) {
            revert ArtificerNexus__InvalidComponentAmount();
        }
        _safeTransferFrom(msg.sender, address(this), _componentId, _amount, "");
        stakedComponentBalances[msg.sender][_componentId] += _amount;
        // This mapping would need to handle multiple stakes over time if needed,
        // For simplicity, we'll just track total balance.
        // A more advanced system might store `StakedComponent` structs in an array for each user.
        emit ComponentStaked(msg.sender, _componentId, _amount);
    }

    function unstakeComponent(uint256 _componentId, uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0 || stakedComponentBalances[msg.sender][_componentId] < _amount) {
            revert ArtificerNexus__NotEnoughStakedComponents();
        }
        stakedComponentBalances[msg.sender][_componentId] -= _amount;
        _safeTransferFrom(address(this), msg.sender, _componentId, _amount, ""); // transfer from contract to user
        emit ComponentUnstaked(msg.sender, _componentId, _amount);
    }

    function getComponentDetails(uint256 _componentId) external view returns (uint256 id, address creator, string memory uri, bytes32 contentHash, uint256 createdAt) {
        Component storage component = components[_componentId];
        return (component.id, component.creator, component.uri, component.contentHash, component.createdAt);
    }

    // --- IV. Artificer Creation & AI Orchestration ---

    function submitCreationRequest(uint256 _promptId, uint256[] memory _componentIds, uint256[] memory _componentAmounts) external payable whenNotPaused returns (uint256) {
        // Ensure prompt exists and user owns it or has a delegate relationship (future)
        require(ERC721.ownerOf(_promptId) == msg.sender, "Prompt must be owned by requester.");
        require(_componentIds.length == _componentAmounts.length, "Component ID and amount arrays must match.");

        // Verify staked components availability
        for (uint256 i = 0; i < _componentIds.length; i++) {
            if (stakedComponentBalances[msg.sender][_componentIds[i]] < _componentAmounts[i]) {
                revert ArtificerNexus__NotEnoughStakedComponents();
            }
        }

        _creationRequestIdCounter.increment();
        uint256 requestId = _creationRequestIdCounter.current();

        creationRequests[requestId] = CreationRequest(
            requestId,
            msg.sender,
            _promptId,
            _componentIds,
            _componentAmounts,
            RequestStatus.Pending,
            "", // artificerURI
            bytes32(0), // artificerHash
            new address[](0), // aiContributors
            new uint256[](0), // aiContributionShares
            block.timestamp,
            0, // fulfilledAt
            0 // mintedCreationId
        );

        // Funds received with the transaction are held for future royalty distribution
        // The protocol fee would be taken from this, but for this contract, we simplify
        // that the ETH sent with this function is purely for future royalties.
        // A real system would require a separate `depositFundsForRoyalty` and separate fees.
        if (msg.value == 0) {
            revert ArtificerNexus__NotEnoughFunds();
        }

        emit CreationRequestSubmitted(requestId, msg.sender, _promptId);
        return requestId;
    }

    // This function is intended to be called ONLY by the trusted Artificer Oracle.
    function fulfillCreationRequest(
        uint256 _requestId,
        string memory _artificerURI,
        bytes32 _artificerHash,
        address[] memory _aiContributors,
        uint256[] memory _aiContributions
    ) external onlyArtificerOracle whenNotPaused {
        CreationRequest storage request = creationRequests[_requestId];
        if (request.id == 0) {
            revert ArtificerNexus__RequestNotFound();
        }
        if (request.status != RequestStatus.Pending) {
            revert ArtificerNexus__RequestAlreadyFulfilled();
        }
        if (_aiContributors.length != _aiContributions.length) {
            revert ArtificerNexus__InvalidComponentAmount(); // Reusing error
        }

        request.status = RequestStatus.Fulfilled;
        request.artificerURI = _artificerURI;
        request.artificerHash = _artificerHash;
        request.aiContributors = _aiContributors;
        request.aiContributionShares = _aiContributions;
        request.fulfilledAt = block.timestamp;

        // Deduct used components from stakers (optional, can be done during minting or later)
        // For simplicity, we just mark them as 'used' here if needed, actual burning/transfer
        // of ERC1155 could occur at minting time.

        emit CreationRequestFulfilled(_requestId, _artificerURI, _artificerHash, _aiContributors, _aiContributions);
    }

    function mintArtificerCreation(uint256 _requestId) external whenNotPaused nonReentrant {
        CreationRequest storage request = creationRequests[_requestId];
        if (request.id == 0) {
            revert ArtificerNexus__RequestNotFound();
        }
        if (request.status != RequestStatus.Fulfilled) {
            revert ArtificerNexus__RequestNotFulfilled();
        }
        if (request.mintedCreationId != 0) {
            revert ArtificerNexus__CreationAlreadyMinted();
        }

        _artificerCreationIdCounter.increment();
        uint256 newCreationId = _artificerCreationIdCounter.current();

        // Initialize collaboration shares
        ArtificerCreation storage newCreation = artificerCreations[newCreationId];
        newCreation.id = newCreationId;
        newCreation.creator = request.requester;
        newCreation.creationRequestId = _requestId;
        newCreation.currentURI = request.artificerURI;
        newCreation.currentHash = request.artificerHash;
        newCreation.createdAt = block.timestamp;
        newCreation.totalSharesBasisPoints = 0; // Will be built up next

        // Add creator's initial share (e.g., 50%)
        uint256 creatorShare = MAX_BASIS_POINTS / 2;
        newCreation.collaborationShares[request.requester] = CollaborationShare(creatorShare, block.timestamp);
        newCreation.currentCollaborators.push(request.requester);
        newCreation.totalSharesBasisPoints += creatorShare;

        // Add AI contributions as collaborators (the remaining 50%)
        uint256 aiTotalShare = MAX_BASIS_POINTS - creatorShare; // Remaining share for AI
        uint256 currentAIAggregateShare = 0;
        for (uint256 i = 0; i < request.aiContributors.length; i++) {
            // Distribute the AI's portion proportionally to their reported contribution shares
            uint256 aiModelShare = (aiTotalShare * request.aiContributionShares[i]) / MAX_BASIS_POINTS;
            newCreation.collaborationShares[request.aiContributors[i]].shareBasisPoints += aiModelShare;
            if (newCreation.collaborationShares[request.aiContributors[i]].lastContributionUpdate == 0) {
                 newCreation.currentCollaborators.push(request.aiContributors[i]);
            }
            newCreation.collaborationShares[request.aiContributors[i]].lastContributionUpdate = block.timestamp;
            newCreation.totalSharesBasisPoints += aiModelShare;
            currentAIAggregateShare += aiModelShare;
        }

        // Handle rounding errors for AI shares, assign remaining to creator
        if (newCreation.totalSharesBasisPoints < MAX_BASIS_POINTS) {
            newCreation.collaborationShares[request.requester].shareBasisPoints += (MAX_BASIS_POINTS - newCreation.totalSharesBasisPoints);
            newCreation.totalSharesBasisPoints = MAX_BASIS_POINTS;
        }

        request.status = RequestStatus.Minted;
        request.mintedCreationId = newCreationId;

        _mint(request.requester, newCreationId); // Mint ERC721 to the requester
        _setTokenURI(newCreationId, request.artificerURI);

        emit ArtificerCreationMinted(newCreationId, _requestId, request.requester, request.artificerURI);
    }

    function enhanceArtificerCreation(uint256 _creationId, uint256 _promptId, uint256[] memory _componentIds, uint256[] memory _componentAmounts) external payable whenNotPaused onlyCreationOwner(_creationId) returns (uint256) {
        ArtificerCreation storage creation = artificerCreations[_creationId];
        if (creation.id == 0) {
            revert ArtificerNexus__CreationNotFound();
        }
        // This process is similar to initial creation, but the existing creation acts as an input.
        // The new request will generate a new contentURI, and ownership will be re-evaluated.

        // Verify inputs same as submitCreationRequest
        require(ERC721.ownerOf(_promptId) == msg.sender, "Prompt must be owned by requester.");
        require(_componentIds.length == _componentAmounts.length, "Component ID and amount arrays must match.");
        for (uint256 i = 0; i < _componentIds.length; i++) {
            if (stakedComponentBalances[msg.sender][_componentIds[i]] < _componentAmounts[i]) {
                revert ArtificerNexus__NotEnoughStakedComponents();
            }
        }
        if (msg.value == 0) {
            revert ArtificerNexus__NotEnoughFunds();
        }

        _creationRequestIdCounter.increment();
        uint256 newRequestId = _creationRequestIdCounter.current();

        creationRequests[newRequestId] = CreationRequest(
            newRequestId,
            msg.sender, // The enhancer is the requester for this new request
            _promptId,
            _componentIds,
            _componentAmounts,
            RequestStatus.Pending,
            "", bytes32(0), new address[](0), new uint256[](0),
            block.timestamp, 0, _creationId // Link back to the original creation being enhanced
        );

        // Importantly, this new request, once fulfilled and 'minted', will update the *existing* ArtificerCreation
        // It will change its URI/hash and re-distribute collaboration shares dynamically.
        // The original ERC721 token does not change ID.

        emit ArtificerCreationEnhanced(_creationId, newRequestId);
        return newRequestId;
    }

    // Function to adjust collaboration shares directly by the NFT owner
    // This allows for explicit agreements between collaborators
    function updateCollaborationShare(uint256 _creationId, address _collaborator, uint256 _newShareBasisPoints) external whenNotPaused onlyCreationOwner(_creationId) {
        ArtificerCreation storage creation = artificerCreations[_creationId];
        if (creation.id == 0) {
            revert ArtificerNexus__CreationNotFound();
        }

        uint256 currentTotalShares = creation.totalSharesBasisPoints;
        uint256 currentCollaboratorShare = creation.collaborationShares[_collaborator].shareBasisPoints;

        if (_newShareBasisPoints > MAX_BASIS_POINTS) {
            revert ArtificerNexus__InvalidShareBasisPoints();
        }

        if (currentCollaboratorShare == 0 && _newShareBasisPoints > 0) {
            // New collaborator
            creation.currentCollaborators.push(_collaborator);
        } else if (currentCollaboratorShare > 0 && _newShareBasisPoints == 0) {
            // Removing collaborator (basic removal, for complex removal, iterate and shift)
            for(uint i = 0; i < creation.currentCollaborators.length; i++) {
                if(creation.currentCollaborators[i] == _collaborator) {
                    creation.currentCollaborators[i] = creation.currentCollaborators[creation.currentCollaborators.length - 1];
                    creation.currentCollaborators.pop();
                    break;
                }
            }
        }

        // Adjust total shares and individual share
        creation.totalSharesBasisPoints = currentTotalShares - currentCollaboratorShare + _newShareBasisPoints;
        creation.collaborationShares[_collaborator].shareBasisPoints = _newShareBasisPoints;
        creation.collaborationShares[_collaborator].lastContributionUpdate = block.timestamp;

        // Ensure total shares don't exceed MAX_BASIS_POINTS. The owner is responsible for managing this.
        require(creation.totalSharesBasisPoints <= MAX_BASIS_POINTS, "Total shares exceed 100%");

        emit CollaborationShareUpdated(_creationId, _collaborator, _newShareBasisPoints);
    }

    function getCreationDetails(uint256 _creationId) external view returns (
        uint256 id,
        address creator,
        uint256 creationRequestId,
        string memory currentURI,
        bytes32 currentHash,
        uint256 createdAt,
        address[] memory currentCollaborators,
        uint256[] memory currentCollaboratorShares,
        uint256 totalRoyaltyAccrued,
        uint256 lastRoyaltyDistribution
    ) {
        ArtificerCreation storage creation = artificerCreations[_creationId];
        if (creation.id == 0) {
            revert ArtificerNexus__CreationNotFound();
        }

        uint256 numCollaborators = creation.currentCollaborators.length;
        address[] memory collaborators = new address[](numCollaborators);
        uint256[] memory shares = new uint256[](numCollaborators);

        for (uint256 i = 0; i < numCollaborators; i++) {
            collaborators[i] = creation.currentCollaborators[i];
            shares[i] = creation.collaborationShares[creation.currentCollaborators[i]].shareBasisPoints;
        }

        return (
            creation.id,
            creation.creator,
            creation.creationRequestId,
            creation.currentURI,
            creation.currentHash,
            creation.createdAt,
            collaborators,
            shares,
            creation.totalRoyaltyAccrued,
            creation.lastRoyaltyDistribution
        );
    }

    // --- V. Reputation & Curation System ---

    function submitCuratorVote(uint256 _creationId, uint256 _score) external whenNotPaused {
        if (creatorReputation[msg.sender] < curatorVoteThreshold) {
            revert ArtificerNexus__InvalidScore(); // Using existing error
        }
        if (artificerCreations[_creationId].id == 0) {
            revert ArtificerNexus__CreationNotFound();
        }
        if (_score > 100 || _score == 0) { // Example: score between 1 and 100
            revert ArtificerNexus__InvalidScore();
        }
        if (hasCuratorVoted[_creationId][msg.sender]) {
            revert ArtificerNexus__AlreadyVoted();
        }
        if (ERC721.ownerOf(_creationId) == msg.sender) {
            revert ArtificerNexus__SelfVoteNotAllowed(); // Cannot vote on your own creation
        }

        hasCuratorVoted[_creationId][msg.sender] = true;
        creationTotalVoteScore[_creationId] += _score;
        creationVoteCount[_creationId]++;

        // Update reputation of the *creator* of the creation
        // This is a simple immediate update, a real system would be more nuanced.
        address creationCreator = artificerCreations[_creationId].creator;
        _updateCreatorReputation(creationCreator);

        emit CuratorVoteSubmitted(_creationId, msg.sender, _score);
    }

    function _updateCreatorReputation(address _creator) internal {
        // This is a simplified reputation update logic.
        // A more complex system would consider:
        // - Decay over time
        // - Weight of curator's reputation
        // - Number of creations by the creator
        // - Average scores of creations
        // For now, we'll just sum up based on direct votes on creations.

        uint256 totalWeightedScore = 0;
        uint256 totalWeight = 0;

        // Iterate through all creations by this creator (highly inefficient for many creations, for demo only)
        // A more scalable approach would be to store a list of creator's creations or update reputation incrementally
        // when a creation is minted or voted on.

        // This is placeholder logic, assuming external data or a specific event loop.
        // For a full implementation, you'd need to iterate through all creations *by* _creator
        // and fetch their average vote score, then apply a decay.
        // To make it functional, let's just make it a direct sum for now.
        // A better approach would be to calculate reputation off-chain and submit as a signed message,
        // or have a more direct mapping to creator's creations.
        // For this demo, we'll imagine it's an aggregation of *successful* creations.

        // Dummy logic: Reputation increases with each highly-rated creation.
        // It's not tracking *which* creations yet.
        // A direct sum of vote scores on their creations, scaled.
        creatorReputation[_creator] = creationTotalVoteScore[_creator] / (creationVoteCount[_creator] == 0 ? 1 : creationVoteCount[_creator]); // Avg score of their creations
        creatorReputation[_creator] = creatorReputation[_creator] * 10; // Scale it up
        // Decay logic could be added: `reputation -= (reputation * reputationDecayRate * (block.timestamp - lastReputationUpdate)) / 10000;`

        emit CreatorReputationUpdated(_creator, creatorReputation[_creator]);
    }

    function updateCreatorReputation(address _creator) external {
        // Can be called by anyone to trigger recalculation, useful for off-chain sync or if logic relies on it.
        // In a real system, this might be permissioned or triggered by a specific event.
        _updateCreatorReputation(_creator);
    }

    function getCreatorReputation(address _creator) external view returns (uint256) {
        return creatorReputation[_creator];
    }

    // --- VI. Dynamic Royalty Distribution ---

    // This function can be called by anyone to calculate the current royalty distribution
    // It is `view` because it doesn't change state.
    function calculateDynamicRoyalties(uint256 _creationId, uint256 _totalAmount) public view returns (address[] memory recipients, uint256[] memory amounts) {
        ArtificerCreation storage creation = artificerCreations[_creationId];
        if (creation.id == 0) {
            revert ArtificerNexus__CreationNotFound();
        }
        if (creation.totalSharesBasisPoints == 0) { // Should not happen if shares are correctly managed
            revert ArtificerNexus__NoRoyaltiesAccrued();
        }

        uint256 numCollaborators = creation.currentCollaborators.length;
        recipients = new address[](numCollaborators);
        amounts = new uint256[](numCollaborators);

        uint256 protocolFee = (_totalAmount * protocolFeeBasisPoints) / MAX_BASIS_POINTS;
        uint256 distributableAmount = _totalAmount - protocolFee;

        for (uint256 i = 0; i < numCollaborators; i++) {
            address collaborator = creation.currentCollaborators[i];
            uint256 share = creation.collaborationShares[collaborator].shareBasisPoints;
            amounts[i] = (distributableAmount * share) / creation.totalSharesBasisPoints;
            recipients[i] = collaborator;
        }

        return (recipients, amounts);
    }

    function distributeRoyalties(uint256 _creationId) external nonReentrant {
        ArtificerCreation storage creation = artificerCreations[_creationId];
        if (creation.id == 0) {
            revert ArtificerNexus__CreationNotFound();
        }

        uint256 availableFunds = address(this).balance; // Total ETH held by the contract
        // A more robust system would map incoming ETH to specific creations.
        // For this demo, we assume any ETH sent to the contract is for *all* outstanding royalties,
        // and we will deduct the amount specific to this creation.
        // This is a simplification; a real system would need a dedicated fund-holding vault per creation,
        // or track balances per creation.

        // Placeholder for actual royalty calculation
        // For this to work, funds for each creation must be explicitly tracked or sent to a sub-vault.
        // Here, we just assume the `totalRoyaltyAccrued` is the amount to distribute.
        // In reality, ETH would be sent to the contract and associated with specific creation IDs.
        uint256 amountToDistribute = creation.totalRoyaltyAccrued; // Sum of all ETH sent to this creation
        if (amountToDistribute == 0) {
            revert ArtificerNexus__NoRoyaltiesAccrued();
        }
        if (availableFunds < amountToDistribute) {
            revert ArtificerNexus__NotEnoughFunds();
        }

        (address[] memory recipients, uint256[] memory amounts) = calculateDynamicRoyalties(_creationId, amountToDistribute);

        creation.totalRoyaltyAccrued = 0; // Reset accrued royalties after distribution
        creation.lastRoyaltyDistribution = block.timestamp;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] > 0) {
                (bool success,) = recipients[i].call{value: amounts[i]}("");
                if (!success) {
                    // Log the failure but don't revert the entire transaction to allow other payouts.
                    // A robust system might re-queue failed payouts or use a pull mechanism.
                    emit RoyaltiesDistributed(_creationId, amounts[i]); // Emit for partial success
                }
            }
        }
        emit RoyaltiesDistributed(_creationId, amountToDistribute);
    }

    // --- VII. Governance & Advanced Features (Conceptual for 20+ functions) ---

    function proposeGovernanceChange(string memory _description, address _target, bytes memory _calldata) external whenNotPaused {
        _governanceProposalIdCounter.increment();
        uint256 proposalId = _governanceProposalIdCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            description: _description,
            targetContract: _target,
            callData: _calldata,
            voteThreshold: 0, // Placeholder, calculated based on current total reputation
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(),
            status: ProposalStatus.Active
        });
        emit GovernanceProposalCreated(proposalId, _description, msg.sender);
    }

    function voteOnGovernanceChange(uint256 _proposalId, bool _support) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0 || proposal.status != ProposalStatus.Active) {
            revert ArtificerNexus__ProposalNotFound();
        }
        if (block.timestamp > proposal.endTime) {
            revert ArtificerNexus__VotePeriodEnded();
        }

        address voter = reputationDelegates[msg.sender] != address(0) ? reputationDelegates[msg.sender] : msg.sender;
        if (proposal.hasVoted[voter]) {
            revert ArtificerNexus__AlreadyVoted();
        }

        uint256 reputation = creatorReputation[voter];
        if (reputation == 0) {
            revert ArtificerNexus__InvalidScore(); // Reusing error
        }

        proposal.hasVoted[voter] = true;
        if (_support) {
            proposal.votesFor += reputation;
        } else {
            proposal.votesAgainst += reputation;
        }

        emit GovernanceVoteCast(_proposalId, voter, _support);
    }

    // This function would execute the proposal if it passed
    function executeGovernanceProposal(uint256 _proposalId) external onlyOwner whenPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0 || proposal.status != ProposalStatus.Active) {
            revert ArtificerNexus__ProposalNotFound();
        }
        if (block.timestamp <= proposal.endTime) {
            revert ArtificerNexus__VotePeriodEnded();
        }

        // Calculate if proposal passed (e.g., 60% of total possible reputation, or simple majority of votes cast)
        // For simplicity, let's say simple majority of votes cast with > 0 votes for.
        if (proposal.votesFor > proposal.votesAgainst) {
            // Execute the calldata
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Execution failed");
            proposal.status = ProposalStatus.Executed;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    function delegateReputationVote(address _delegatee) external {
        if (_delegatee == address(0)) {
            revert ArtificerNexus__InvalidDelegatee();
        }
        if (_delegatee == msg.sender) {
            revert ArtificerNexus__CannotDelegateToSelf();
        }
        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    // --- Internal/Utility Functions ---

    // ERC1155 _beforeTokenTransfer hook (mandatory if _mint/burn isn't used with overrides)
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    // ERC1155 supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Fallback and Receive functions to accept ETH for royalties
    receive() external payable {
        // Funds received are considered accrued royalties for some future creation.
        // A more complex system would map `msg.sender` or specific data to a `creationId`
        // and credit these funds to that specific creation's `totalRoyaltyAccrued`.
        // For this demo, we'll assume a separate function or direct calls to `distributeRoyalties` will handle which funds are for what.
        // If a real system, you'd want `creationId` to be passed with ETH.
    }
}
```