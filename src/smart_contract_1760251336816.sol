Here's a smart contract called "OmniForge" designed with advanced, creative, and trendy concepts in mind. It focuses on decentralized, AI-assisted generative asset creation, dynamic NFTs, and a novel influence-based governance system.

---

## OmniForge: Decentralized Generative Asset & Influence Protocol

### Outline

**Purpose:** OmniForge is a pioneering decentralized protocol that enables the collaborative creation, funding, and governance of AI-generated digital assets (NFTs). It integrates off-chain AI models via a secure oracle network, allows for dynamic and evolving NFT metadata, and empowers its community through a unique Influence-based reputation and voting system.

**Key Concepts:**

1.  **AI-as-a-Service (via Oracle):** Users can commission AI models to generate unique digital assets (art, media, etc.) by providing prompts and parameters. The contract interacts with a trusted off-chain AI oracle for execution and fulfillment.
2.  **Dynamic NFTs:** Generated assets are tokenized as ERC-721 NFTs. Their metadata and URI can evolve over time through "enhancement" requests or "merging" with other assets, reflecting ongoing creative collaboration.
3.  **Decentralized Curation (Forgemasters):** A special role, "Forgemasters," are elected by the community. They can curate prompts for better AI output and review oracle fulfillments, ensuring quality and preventing malicious content.
4.  **Reputation & Influence Token Governance:** A simulated internal "Influence Token" ($INF) system grants users voting power based on their staked $INF. This power is used for governance proposals, Forgemaster elections, and bounty approvals.
5.  **Collaborative Funding (Bounties):** Users can pool funds to create bounties for specific generative tasks, incentivizing creators to produce desired assets.
6.  **Generative Derivatives/Remixes:** The protocol supports the evolution and combination of existing assets, fostering a recursive creative economy.

### Function Summary (29 Functions)

**I. Core Configuration & Safety:**

1.  `constructor(address _oracleAddress, string memory _baseUri)`: Initializes the contract, sets the owner, the oracle address, and the base URI for NFTs.
2.  `setOmniForgeOracle(address _newOracleAddress)`: Allows the owner to update the trusted AI oracle address.
3.  `setGenerationFee(uint256 _newFee)`: Sets the fee required to request a new asset generation.
4.  `setForgemasterRoleFee(uint256 _newFee)`: Sets the fee paid to Forgemasters for curating prompts.
5.  `pause()`: Allows the owner to pause core functionalities in emergencies.
6.  `unpause()`: Allows the owner to unpause the contract.
7.  `withdrawETH(address _to, uint256 _amount)`: Allows the owner to withdraw accumulated ETH from the contract.

**II. Influence & Reputation Management (Simulated $INF Token):**

8.  `stakeInfluence(uint256 _amount)`: Users stake their internal $INF to gain active influence (voting power).
9.  `unstakeInfluence(uint256 _amount)`: Users unstake their $INF.
10. `delegateInfluence(address _delegatee)`: Delegates one's active influence to another address.
11. `getInfluenceScore(address _user)`: Returns the current active influence score of a user (staked + delegated-in).
12. `claimInfluenceRewards()`: Allows users to claim simulated $INF rewards based on participation (simplified, placeholder for complex reward logic).

**III. Generative Asset Creation (NFTs):**

13. `requestAssetGeneration(string memory _prompt, string memory _modelParameters)`: Users submit a prompt and AI model parameters, paying a fee, which triggers an off-chain oracle request.
14. `fulfillAssetGeneration(uint256 _requestId, string memory _generatedUri, string memory _aiModelUsed)`: Callback from the oracle to mint a new NFT with the generated metadata upon successful AI output.
15. `enhanceAsset(uint256 _tokenId, string memory _newPrompt, string memory _modelParameters)`: NFT owner requests an enhancement or remix of their existing asset, updating its metadata via another oracle request.
16. `requestAssetMerge(uint256[] memory _tokenIdsToMerge, string memory _newPrompt)`: Proposes merging multiple existing NFTs into a new composite NFT, requiring a community vote.

**IV. Forgemaster Role & Curation:**

17. `nominateForgemaster(address _candidate)`: Influence holders can nominate users to become Forgemasters.
18. `voteOnForgemaster(uint256 _nominationId, bool _approve)`: Influence holders vote on active Forgemaster nominations.
19. `appointForgemaster(uint256 _nominationId)`: Executes the appointment of a new Forgemaster if the nomination passes the vote.
20. `curatePrompt(uint256 _requestId, string memory _curatedPrompt)`: Forgemasters can refine pending generation prompts (before oracle execution) to improve quality and earn a fee.
21. `reviewOracleFulfillment(uint256 _requestId, bool _approve)`: Forgemasters can approve or reject the output from the oracle before an NFT is minted or updated, acting as a quality filter.

**V. Governance & Parameter Updates:**

22. `proposeAIModelParameterChange(string memory _paramName, string memory _newValue)`: Users can propose changes to general AI model parameters that the oracle should consider (e.g., safety filters, style biases).
23. `voteOnProposal(uint256 _proposalId, bool _approve)`: Influence holders vote on active governance proposals.
24. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal, updating system parameters.

**VI. Bounty System:**

25. `createGenerationBounty(string memory _targetPrompt, uint256 _rewardAmount)`: Creates a bounty for a specific generative asset, requiring contributors to meet specific criteria.
26. `contributeToBounty(uint256 _bountyId)`: Users can contribute ETH to increase the reward for an existing bounty.
27. `submitBountyFulfillment(uint256 _bountyId, uint256 _generatedTokenId)`: Submits an existing generated NFT as a fulfillment for a bounty.
28. `voteOnBountyFulfillment(uint256 _bountyId, uint256 _submissionId, bool _approve)`: Influence holders vote on whether a submitted asset adequately fulfills the bounty criteria.
29. `awardBounty(uint256 _bountyId, uint256 _submissionId)`: Awards the bounty funds to the creator of the winning submission.

**VII. ERC721 Overrides:**

*   `tokenURI(uint256 tokenId)`: Returns the URI for a given token, which can be dynamically updated.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// This interface represents the expected functions from our off-chain AI Oracle.
// In a real scenario, this might be Chainlink Functions, a custom secure relayer,
// or another verifiable compute solution.
interface IOmniForgeOracle {
    function requestGeneration(uint256 _requestId, address _callbackContract, bytes calldata _data) external;
    function requestEnhancement(uint256 _requestId, address _callbackContract, bytes calldata _data) external;
    function requestMerge(uint256 _requestId, address _callbackContract, bytes calldata _data) external;
}

// This represents a simplified internal Influence Token system.
// In a production environment, this would likely be a full-fledged ERC-20 contract
// with more complex distribution and governance features.
contract SimplifiedInfluenceToken {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakedBalances;
    mapping(address => address) public delegates; // address => whom they delegate to

    function mint(address _to, uint256 _amount) internal {
        balances[_to] += _amount;
    }

    function transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        require(balances[_from] >= _amount, "Insufficient balance");
        balances[_from] -= _amount;
        balances[_to] += _amount;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function totalStaked(address _owner) public view returns (uint256) {
        return stakedBalances[_owner];
    }
}


contract OmniForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    IOmniForgeOracle public omniForgeOracle;
    SimplifiedInfluenceToken public influenceToken; // Using a simplified internal token for example
    
    uint256 public generationFee; // Fee to request new asset generation
    uint256 public forgemasterRoleFee; // Fee for forgemasters curating prompts

    string private _baseTokenURI; // Base URI for generated NFTs
    Counters.Counter private _tokenIdCounter; // Global NFT ID counter
    Counters.Counter private _requestIdCounter; // Global oracle request ID counter
    Counters.Counter private _proposalIdCounter; // Global governance proposal ID counter
    Counters.Counter private _nominationIdCounter; // Global forgemaster nomination ID counter
    Counters.Counter private _bountyIdCounter; // Global bounty ID counter
    Counters.Counter private _submissionIdCounter; // Global bounty submission ID counter


    // Mapping from tokenId to its current metadata URI
    mapping(uint256 => string) private _tokenUris;

    // Forgemaster role management
    mapping(address => bool) public isForgemaster;

    // AI model parameters that can be governed
    mapping(string => string) public aiModelParameters;

    // --- Structs for Requests, Proposals, Bounties ---

    enum RequestStatus { PendingOracle, PendingForgemasterReview, Fulfilled, Rejected }

    struct AssetGenerationRequest {
        address creator;
        string prompt;
        string modelParameters;
        uint256 feePaid;
        RequestStatus status;
        uint256 tokenId; // Set upon fulfillment
        uint256 createdAt;
        string curatedPrompt; // Can be modified by forgemaster
        address forgemasterReviewer; // Forgemaster who reviewed/approved
    }
    mapping(uint256 => AssetGenerationRequest) public generationRequests;

    struct ForgemasterNomination {
        address candidate;
        uint256 createdAt;
        mapping(address => bool) votes; // Voter => has_voted
        uint256 yesVotes;
        uint256 noVotes;
        bool active;
        bool approved;
    }
    mapping(uint256 => ForgemasterNomination) public forgemasterNominations;

    enum ProposalStatus { Open, Passed, Failed, Executed }

    struct GovernanceProposal {
        address proposer;
        string proposalType; // e.g., "AI_MODEL_PARAM_CHANGE", "ASSET_MERGE_REQUEST"
        string paramName;
        string newValue;
        uint256 createdAt;
        mapping(address => bool) votes; // Voter => has_voted
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalInfluenceAtStart; // Total influence when proposal opened
        ProposalStatus status;
        uint256[] tokenIdsToMerge; // For ASSET_MERGE_REQUEST
        string newMergePrompt; // For ASSET_MERGE_REQUEST
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    struct GenerationBounty {
        address creator;
        string targetPrompt;
        uint256 rewardAmount;
        uint256 currentContributions; // ETH contributed
        bool active;
        uint256 createdAt;
        uint256 winningSubmissionId; // Set after award
    }
    mapping(uint256 => GenerationBounty) public generationBounties;

    struct BountySubmission {
        address submitter;
        uint256 bountyId;
        uint256 generatedTokenId; // The NFT fulfilling the bounty
        uint256 createdAt;
        mapping(address => bool) votes; // Voter => has_voted
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalInfluenceAtStart;
        bool approved;
    }
    mapping(uint256 => BountySubmission) public bountySubmissions;


    // --- Events ---
    event OracleRequestSent(uint256 indexed requestId, address indexed creator, string prompt, string modelParameters);
    event AssetMinted(uint256 indexed tokenId, uint256 indexed requestId, address indexed owner, string uri);
    event AssetEnhanced(uint256 indexed tokenId, uint256 indexed requestId, string newUri);
    event ForgemasterNominated(uint256 indexed nominationId, address indexed candidate, address indexed nominator);
    event ForgemasterAppointed(address indexed candidate);
    event PromptCurated(uint256 indexed requestId, address indexed forgemaster, string oldPrompt, string newPrompt);
    event OracleFulfillmentReviewed(uint256 indexed requestId, address indexed reviewer, bool approved);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string proposalType);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event BountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, string targetPrompt);
    event BountyContributed(uint256 indexed bountyId, address indexed contributor, uint256 amount);
    event BountySubmitted(uint256 indexed submissionId, uint256 indexed bountyId, address indexed submitter, uint256 indexed tokenId);
    event BountyAwarded(uint256 indexed bountyId, uint256 indexed winningSubmissionId, address indexed recipient);


    // --- Constructor ---
    constructor(address _oracleAddress, string memory _baseUri)
        ERC721("OmniForge Asset", "OMNI")
        Ownable(msg.sender)
    {
        require(_oracleAddress != address(0), "Invalid oracle address");
        omniForgeOracle = IOmniForgeOracle(_oracleAddress);
        
        influenceToken = new SimplifiedInfluenceToken(); // Deploying our simplified InfluenceToken
        _baseTokenURI = _baseUri;
        generationFee = 0.01 ether; // Default fee
        forgemasterRoleFee = 0.001 ether; // Default forgemaster fee
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == address(omniForgeOracle), "Only Oracle can call this function");
        _;
    }

    modifier onlyForgemaster() {
        require(isForgemaster[msg.sender], "Only Forgemasters can call this function");
        _;
    }

    // --- I. Core Configuration & Safety ---

    function setOmniForgeOracle(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "Invalid oracle address");
        omniForgeOracle = IOmniForgeOracle(_newOracleAddress);
    }

    function setGenerationFee(uint256 _newFee) external onlyOwner {
        generationFee = _newFee;
    }

    function setForgemasterRoleFee(uint256 _newFee) external onlyOwner {
        forgemasterRoleFee = _newFee;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawETH(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid recipient");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        payable(_to).transfer(_amount);
    }

    // --- II. Influence & Reputation Management (Simplified $INF Token) ---
    // Note: In a real system, the InfluenceToken would be a separate, more complex ERC-20 contract.
    // This implementation is a simplification for demonstration within a single contract.

    function _getInfluencePower(address _user) internal view returns (uint256) {
        address delegatee = influenceToken.delegates[_user];
        if (delegatee != address(0)) {
            return influenceToken.stakedBalances[delegatee];
        }
        return influenceToken.stakedBalances[_user];
    }

    function stakeInfluence(uint256 _amount) external whenNotPaused {
        require(influenceToken.balanceOf(msg.sender) >= _amount, "Insufficient $INF balance");
        influenceToken.transfer(msg.sender, address(this), _amount); // Simulate transferring to contract
        influenceToken.stakedBalances[msg.sender] += _amount;
    }

    function unstakeInfluence(uint256 _amount) external whenNotPaused {
        require(influenceToken.stakedBalances[msg.sender] >= _amount, "Not enough staked $INF");
        influenceToken.stakedBalances[msg.sender] -= _amount;
        influenceToken.transfer(address(this), msg.sender, _amount); // Simulate returning from contract
    }

    function delegateInfluence(address _delegatee) external whenNotPaused {
        require(_delegatee != msg.sender, "Cannot delegate to self");
        influenceToken.delegates[msg.sender] = _delegatee;
    }

    function getInfluenceScore(address _user) public view returns (uint256) {
        return _getInfluencePower(_user);
    }
    
    // Simplified placeholder for claiming rewards. In reality, this would involve complex logic
    // like measuring participation, time staked, successful votes, etc.
    function claimInfluenceRewards() external {
        // Example: award 1 $INF for claiming (very simplified)
        influenceToken.mint(msg.sender, 1 ether); // Assuming 1 $INF = 1e18
    }

    // --- III. Generative Asset Creation (NFTs) ---

    function requestAssetGeneration(string memory _prompt, string memory _modelParameters)
        external
        payable
        whenNotPaused
        returns (uint256 requestId)
    {
        require(msg.value >= generationFee, "Insufficient fee for generation");

        requestId = _requestIdCounter.current();
        _requestIdCounter.increment();

        generationRequests[requestId] = AssetGenerationRequest({
            creator: msg.sender,
            prompt: _prompt,
            modelParameters: _modelParameters,
            feePaid: msg.value,
            status: RequestStatus.PendingOracle,
            tokenId: 0, // Will be set on fulfillment
            createdAt: block.timestamp,
            curatedPrompt: _prompt, // Default to user prompt
            forgemasterReviewer: address(0)
        });

        // Prepare data for the oracle.
        // In a real system, this would be more structured (e.g., abi.encode).
        bytes memory oracleData = abi.encodePacked(
            requestId.toString(),
            _prompt,
            _modelParameters,
            address(this).toString() // Callback contract
        );

        omniForgeOracle.requestGeneration(requestId, address(this), oracleData);
        emit OracleRequestSent(requestId, msg.sender, _prompt, _modelParameters);
    }

    function fulfillAssetGeneration(uint256 _requestId, string memory _generatedUri, string memory _aiModelUsed)
        external
        onlyOracle
        whenNotPaused
    {
        AssetGenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.PendingOracle || req.status == RequestStatus.PendingForgemasterReview, "Request not in valid state for fulfillment");

        // If a forgemaster curated it, they get a fee
        if (req.forgemasterReviewer != address(0)) {
            payable(req.forgemasterReviewer).transfer(forgemasterRoleFee);
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(req.creator, newTokenId);
        _setTokenURI(newTokenId, _generatedUri);

        req.status = RequestStatus.Fulfilled;
        req.tokenId = newTokenId;
        
        emit AssetMinted(newTokenId, _requestId, req.creator, _generatedUri);
    }

    function enhanceAsset(uint256 _tokenId, string memory _newPrompt, string memory _modelParameters)
        external
        payable
        whenNotPaused
        returns (uint256 requestId)
    {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only token owner can enhance");
        require(msg.value >= generationFee, "Insufficient fee for enhancement");

        requestId = _requestIdCounter.current();
        _requestIdCounter.increment();

        generationRequests[requestId] = AssetGenerationRequest({
            creator: msg.sender,
            prompt: _newPrompt,
            modelParameters: _modelParameters,
            feePaid: msg.value,
            status: RequestStatus.PendingOracle,
            tokenId: _tokenId, // This request is for an existing token
            createdAt: block.timestamp,
            curatedPrompt: _newPrompt,
            forgemasterReviewer: address(0)
        });

        bytes memory oracleData = abi.encodePacked(
            requestId.toString(),
            _tokenId.toString(),
            _newPrompt,
            _modelParameters,
            address(this).toString()
        );

        omniForgeOracle.requestEnhancement(requestId, address(this), oracleData);
        emit OracleRequestSent(requestId, msg.sender, _newPrompt, _modelParameters);
    }

    function fulfillAssetEnhancement(uint256 _requestId, string memory _newUri)
        external
        onlyOracle
        whenNotPaused
    {
        AssetGenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.PendingOracle || req.status == RequestStatus.PendingForgemasterReview, "Request not in valid state for fulfillment");
        require(_exists(req.tokenId), "Target token for enhancement does not exist");

        // If a forgemaster curated it, they get a fee
        if (req.forgemasterReviewer != address(0)) {
            payable(req.forgemasterReviewer).transfer(forgemasterRoleFee);
        }

        _setTokenURI(req.tokenId, _newUri);
        req.status = RequestStatus.Fulfilled;

        emit AssetEnhanced(req.tokenId, _requestId, _newUri);
    }
    
    function requestAssetMerge(uint256[] memory _tokenIdsToMerge, string memory _newPrompt)
        external
        whenNotPaused
        returns (uint256 proposalId)
    {
        require(_tokenIdsToMerge.length >= 2, "Need at least 2 tokens to merge");
        
        // Ensure msg.sender owns all tokens to be merged
        for (uint256 i = 0; i < _tokenIdsToMerge.length; i++) {
            require(ownerOf(_tokenIdsToMerge[i]) == msg.sender, "Must own all tokens to merge");
        }

        proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            proposalType: "ASSET_MERGE_REQUEST",
            paramName: "",
            newValue: "",
            createdAt: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            totalInfluenceAtStart: _getInfluencePower(msg.sender), // Capture influence at proposal start
            status: ProposalStatus.Open,
            tokenIdsToMerge: _tokenIdsToMerge,
            newMergePrompt: _newPrompt
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, "ASSET_MERGE_REQUEST");
    }

    // --- IV. Forgemaster Role & Curation ---

    function nominateForgemaster(address _candidate) external whenNotPaused returns (uint256 nominationId) {
        require(_candidate != address(0), "Invalid candidate address");
        require(!isForgemaster[_candidate], "Candidate is already a Forgemaster");

        nominationId = _nominationIdCounter.current();
        _nominationIdCounter.increment();

        forgemasterNominations[nominationId] = ForgemasterNomination({
            candidate: _candidate,
            createdAt: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            active: true,
            approved: false
        });
        emit ForgemasterNominated(nominationId, _candidate, msg.sender);
    }

    function voteOnForgemaster(uint256 _nominationId, bool _approve) external whenNotPaused {
        ForgemasterNomination storage nomination = forgemasterNominations[_nominationId];
        require(nomination.active, "Nomination is not active");
        require(!nomination.votes[msg.sender], "Already voted on this nomination");

        uint256 voterInfluence = _getInfluencePower(msg.sender);
        require(voterInfluence > 0, "No influence to vote");

        nomination.votes[msg.sender] = true;
        if (_approve) {
            nomination.yesVotes += voterInfluence;
        } else {
            nomination.noVotes += voterInfluence;
        }
        emit VoteCast(_nominationId, msg.sender, _approve);
    }

    function appointForgemaster(uint256 _nominationId) external onlyOwner whenNotPaused {
        ForgemasterNomination storage nomination = forgemasterNominations[_nominationId];
        require(nomination.active, "Nomination not active");
        require(nomination.yesVotes > nomination.noVotes, "Nomination did not pass");
        
        isForgemaster[nomination.candidate] = true;
        nomination.active = false;
        nomination.approved = true;
        emit ForgemasterAppointed(nomination.candidate);
    }

    function curatePrompt(uint256 _requestId, string memory _curatedPrompt) external onlyForgemaster whenNotPaused {
        AssetGenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.PendingOracle, "Request not in pending oracle status");
        
        // Update the prompt and set status for forgemaster review
        req.curatedPrompt = _curatedPrompt;
        req.status = RequestStatus.PendingForgemasterReview;
        req.forgemasterReviewer = msg.sender;
        emit PromptCurated(_requestId, msg.sender, req.prompt, _curatedPrompt);

        // Here, the oracle would ideally be notified to use the curated prompt.
        // For simplicity, we assume the oracle will pick up the 'curatedPrompt' field
        // when it processes the original request ID.
    }

    function reviewOracleFulfillment(uint256 _requestId, bool _approve) external onlyForgemaster whenNotPaused {
        AssetGenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.PendingForgemasterReview, "Request not pending forgemaster review");
        require(req.forgemasterReviewer == msg.sender, "Only the assigned Forgemaster can review");

        if (_approve) {
            req.status = RequestStatus.Fulfilled; // Allow the fulfillment process to continue (e.g., call back from oracle)
        } else {
            req.status = RequestStatus.Rejected;
            // Potentially refund fee or allow creator to resubmit with new prompt
        }
        emit OracleFulfillmentReviewed(_requestId, msg.sender, _approve);
    }

    // --- V. Governance & Parameter Updates ---

    function proposeAIModelParameterChange(string memory _paramName, string memory _newValue)
        external
        whenNotPaused
        returns (uint256 proposalId)
    {
        require(_getInfluencePower(msg.sender) > 0, "No influence to propose");

        proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            proposalType: "AI_MODEL_PARAM_CHANGE",
            paramName: _paramName,
            newValue: _newValue,
            createdAt: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            totalInfluenceAtStart: _getInfluencePower(msg.sender), // Placeholder: Should be total network influence
            status: ProposalStatus.Open,
            tokenIdsToMerge: new uint256[](0),
            newMergePrompt: ""
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, "AI_MODEL_PARAM_CHANGE");
    }

    function voteOnProposal(uint256 _proposalId, bool _approve) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Open, "Proposal not open for voting");
        require(!proposal.votes[msg.sender], "Already voted on this proposal");

        uint256 voterInfluence = _getInfluencePower(msg.sender);
        require(voterInfluence > 0, "No influence to vote");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes += voterInfluence;
        } else {
            proposal.noVotes += voterInfluence;
        }
        emit VoteCast(_proposalId, msg.sender, _approve);
    }

    function executeProposal(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Open, "Proposal not open");
        // Simplified majority rule. In complex DAOs, quorum and time limits apply.
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass");
        
        proposal.status = ProposalStatus.Executed;

        if (keccak256(abi.encodePacked(proposal.proposalType)) == keccak256(abi.encodePacked("AI_MODEL_PARAM_CHANGE"))) {
            aiModelParameters[proposal.paramName] = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.proposalType)) == keccak256(abi.encodePacked("ASSET_MERGE_REQUEST"))) {
            // Initiate oracle request for merging assets
            uint256 requestId = _requestIdCounter.current();
            _requestIdCounter.increment();

            // Create a pseudo-request for tracking the merge
            generationRequests[requestId] = AssetGenerationRequest({
                creator: proposal.proposer,
                prompt: proposal.newMergePrompt,
                modelParameters: "merge", // Special parameter
                feePaid: 0, // Fee for merge would be separate
                status: RequestStatus.PendingOracle,
                tokenId: 0, // New token ID for merged asset
                createdAt: block.timestamp,
                curatedPrompt: proposal.newMergePrompt,
                forgemasterReviewer: address(0)
            });

            bytes memory oracleData = abi.encodePacked(
                requestId.toString(),
                abi.encode(proposal.tokenIdsToMerge),
                proposal.newMergePrompt,
                address(this).toString()
            );

            omniForgeOracle.requestMerge(requestId, address(this), oracleData);
            emit OracleRequestSent(requestId, proposal.proposer, proposal.newMergePrompt, "merge");
        }
        emit ProposalExecuted(_proposalId);
    }

    function fulfillAssetMerge(uint256 _requestId, uint256[] memory _burnedTokenIds, string memory _newUri)
        external
        onlyOracle
        whenNotPaused
    {
        AssetGenerationRequest storage req = generationRequests[_requestId];
        require(req.status == RequestStatus.PendingOracle, "Request not in valid state for fulfillment");

        // Burn the source NFTs
        for (uint256 i = 0; i < _burnedTokenIds.length; i++) {
            require(ownerOf(_burnedTokenIds[i]) == req.creator, "Owner mismatch for token to burn"); // Ensure original owner for security
            _burn(_burnedTokenIds[i]);
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(req.creator, newTokenId);
        _setTokenURI(newTokenId, _newUri);

        req.status = RequestStatus.Fulfilled;
        req.tokenId = newTokenId;
        
        emit AssetMinted(newTokenId, _requestId, req.creator, _newUri);
    }


    // --- VI. Bounty System ---

    function createGenerationBounty(string memory _targetPrompt, uint256 _rewardAmount)
        external
        payable
        whenNotPaused
        returns (uint256 bountyId)
    {
        require(msg.value >= _rewardAmount, "Insufficient initial contribution");

        bountyId = _bountyIdCounter.current();
        _bountyIdCounter.increment();

        generationBounties[bountyId] = GenerationBounty({
            creator: msg.sender,
            targetPrompt: _targetPrompt,
            rewardAmount: _rewardAmount,
            currentContributions: msg.value,
            active: true,
            createdAt: block.timestamp,
            winningSubmissionId: 0
        });
        emit BountyCreated(bountyId, msg.sender, _rewardAmount, _targetPrompt);
    }

    function contributeToBounty(uint256 _bountyId) external payable whenNotPaused {
        GenerationBounty storage bounty = generationBounties[_bountyId];
        require(bounty.active, "Bounty is not active");
        require(msg.value > 0, "Contribution must be greater than zero");

        bounty.currentContributions += msg.value;
        emit BountyContributed(_bountyId, msg.sender, msg.value);
    }

    function submitBountyFulfillment(uint256 _bountyId, uint256 _generatedTokenId) external whenNotPaused returns (uint256 submissionId) {
        GenerationBounty storage bounty = generationBounties[_bountyId];
        require(bounty.active, "Bounty is not active");
        require(_exists(_generatedTokenId), "Submitted token does not exist");
        require(ownerOf(_generatedTokenId) == msg.sender, "Must own the submitted token");

        submissionId = _submissionIdCounter.current();
        _submissionIdCounter.increment();

        bountySubmissions[submissionId] = BountySubmission({
            submitter: msg.sender,
            bountyId: _bountyId,
            generatedTokenId: _generatedTokenId,
            createdAt: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            totalInfluenceAtStart: _getInfluencePower(msg.sender), // Placeholder for influence at submission
            approved: false
        });
        emit BountySubmitted(submissionId, _bountyId, msg.sender, _generatedTokenId);
    }

    function voteOnBountyFulfillment(uint256 _bountyId, uint256 _submissionId, bool _approve) external whenNotPaused {
        BountySubmission storage submission = bountySubmissions[_submissionId];
        require(submission.bountyId == _bountyId, "Submission ID does not match Bounty ID");
        require(generationBounties[_bountyId].active, "Bounty is not active");
        require(!submission.votes[msg.sender], "Already voted on this submission");

        uint256 voterInfluence = _getInfluencePower(msg.sender);
        require(voterInfluence > 0, "No influence to vote");

        submission.votes[msg.sender] = true;
        if (_approve) {
            submission.yesVotes += voterInfluence;
        } else {
            submission.noVotes += voterInfluence;
        }
        emit VoteCast(_submissionId, msg.sender, _approve); // Using general VoteCast for bounties too
    }

    function awardBounty(uint256 _bountyId, uint256 _submissionId) external whenNotPaused {
        GenerationBounty storage bounty = generationBounties[_bountyId];
        BountySubmission storage submission = bountySubmissions[_submissionId];

        require(bounty.active, "Bounty is not active");
        require(submission.bountyId == _bountyId, "Submission ID does not match Bounty ID");
        require(submission.yesVotes > submission.noVotes, "Submission did not pass voting");
        require(bounty.currentContributions >= bounty.rewardAmount, "Insufficient funds in bounty");

        submission.approved = true;
        bounty.active = false; // Close bounty after awarding
        bounty.winningSubmissionId = _submissionId;

        payable(submission.submitter).transfer(bounty.rewardAmount); // Transfer bounty reward
        // Any remaining ETH in bounty goes to treasury/owner or returned (logic simplified)

        emit BountyAwarded(_bountyId, _submissionId, submission.submitter);
    }

    // --- VII. ERC721 Overrides ---
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _uri) internal {
        _tokenUris[tokenId] = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _uri = _tokenUris[tokenId];
        if (bytes(_uri).length == 0) {
            return super.tokenURI(tokenId);
        }
        return _uri;
    }
}
```