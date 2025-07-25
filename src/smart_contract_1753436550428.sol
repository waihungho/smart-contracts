Here's a Solidity smart contract system, "AetherMind Syndicate," designed to be interesting, advanced, creative, and trendy. It focuses on a decentralized collective intelligence network where users contribute "insights" that become dynamic NFTs, and their reputation (tracked via Soulbound Tokens) influences their governance power. AI integration via an oracle allows for analysis and evolution of these insights.

This system aims to **not duplicate existing open-source projects** by combining several advanced concepts into a unique architecture:

*   **Dynamic NFTs (dNFTs):** "InsightNFTs" whose metadata and attributes can evolve based on validated contributions and AI analysis.
*   **Soulbound Tokens (SBTs):** "SyndicateMemberProfiles" represent non-transferable reputation and skill, directly tying a member's on-chain identity to their standing and voting power.
*   **AI Oracle Integration (Simulated):** A mechanism to request off-chain AI analysis for insight proposals, potentially influencing NFT evolution or contributor reputation.
*   **Decentralized Collective Intelligence:** A structured process for members to propose, validate, and evolve intellectual property (insights).
*   **On-chain Governance:** Members govern the syndicate using their SBT-derived reputation as voting power, including delegation.

---

### **Outline:**

**I. Core Contracts & Interfaces**
    A. `IAIPromptOracle`: Interface for the AI Oracle (simulated).
    B. `SyndicateMemberProfile`: ERC721-based Soulbound Token (SBT) for member identity and reputation.
    C. `InsightNFT`: ERC721-based Dynamic NFT (dNFT) for intellectual contributions.
    D. `AetherMindSyndicate`: The main orchestrator contract.

**II. `SyndicateMemberProfile` (SBT) Contract Functions**
    *   `constructor()`: Initializes the SBT.
    *   `mint()`: Mints a new non-transferable profile for a member.
    *   `_transfer()` (override): Prevents transfers, making it soulbound.
    *   `setApprovalForAll()` (override): Prevents approvals.
    *   `approve()` (override): Prevents approvals.
    *   `updateReputation()`: Updates a member's reputation score (called by main contract).
    *   `incrementContributionCount()`: Increments contribution count (called by main contract).
    *   `setSkillTags()`: Allows a member to update their skill tags.
    *   `getMemberData()`: Retrieves a member's detailed data.
    *   `getTokenIdByAddress()`: Gets profile ID by address.
    *   `tokenURI()`: Returns the metadata URI for the profile.

**III. `InsightNFT` (dNFT) Contract Functions**
    *   `constructor()`: Initializes the dNFT.
    *   `mint()`: Mints a new Insight NFT (called by main contract).
    *   `evolveInsight()`: Updates the cognitive power and metadata URI of an Insight NFT (called by main contract, e.g., after AI analysis).
    *   `updateMetadataURI()`: Allows direct update of metadata URI.
    *   `getInsightData()`: Retrieves an Insight NFT's detailed data.
    *   `tokenURI()`: Returns the current dynamic metadata URI.

**IV. `AetherMindSyndicate` (Main Logic) Contract Functions**
    **A. Initialization & Configuration**
        1.  `constructor()`: Sets up initial contract addresses.
        2.  `setInsightNFTAddress()`: Configures InsightNFT contract address.
        3.  `setMemberProfileAddress()`: Configures SyndicateMemberProfile contract address.
        4.  `setAIPromptOracle()`: Configures AI Prompt Oracle contract address.
        5.  `updateMinProposalStakeAmount()`: Adjusts the required stake for proposals.
        6.  `updateAIOracleResponseFee()`: Adjusts the fee for AI analysis requests.
    **B. Member Management**
        7.  `joinSyndicate()`: Allows an address to mint their unique Soulbound Syndicate Member Profile.
    **C. Insight Proposal & Validation System**
        8.  `submitInsightProposal()`: Submits a new insight idea for community validation, requiring a stake.
        9.  `voteOnProposal()`: Allows members to vote on active insight proposals, using their reputation as voting power.
        10. `finalizeProposalVoting()`: Concludes the voting period, mints InsightNFT if approved, and updates contributor's reputation.
    **D. AI Oracle Integration**
        11. `requestAIAnalysis()`: Requests an off-chain AI analysis for a finalized insight, potentially influencing its future evolution.
        12. `fulfillPromptAnalysis()`: Callback function for the AI Oracle to deliver analysis results.
    **E. Dynamic NFT Evolution**
        13. `evolveInsightNFT()`: Triggers the evolution of an Insight NFT (e.g., updating its cognitive power and metadata based on AI analysis or further community input).
    **F. Governance (DAO)**
        14. `delegateVotePower()`: Allows a member to delegate their voting power to another member.
        15. `getVotingPower()`: Returns the effective voting power of an address, considering delegation.
        16. `proposeGovernanceAction()`: Submits a new governance proposal for the syndicate.
        17. `voteOnGovernanceProposal()`: Votes on an active governance proposal, using effective voting power.
        18. `executeGovernanceProposal()`: Executes a governance proposal that has successfully passed.
    **G. Treasury & Incentives**
        19. `withdrawTreasuryFunds()`: Allows the contract owner (initially, would transition to DAO control) to withdraw treasury funds.
    **H. Query Functions**
        20. `getMemberProfile()`: Retrieves a member's profile data and tokenId by address.
        21. `getInsightDetails()`: Retrieves an Insight NFT's data and current owner.
        22. `getProposalState()`: Returns the current state of an insight proposal.
        23. `getTotalStaked()`: Returns the total amount of ETH staked in the contract.

---

### **Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Placeholder for a native token, if applicable
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string for URIs

// --- I. Core Contracts & Interfaces ---

// A. IAIPromptOracle: Interface for the AI Oracle (simulated)
// In a real scenario, this would interact with a decentralized oracle network like Chainlink
// or a custom off-chain service that feeds AI results back on-chain.
interface IAIPromptOracle {
    // Requests analysis for content (e.g., an IPFS hash of an insight)
    // The requestId is used by the oracle to track the request and by the callback to identify the original request.
    function requestPromptAnalysis(uint256 requestId, string calldata promptContent, address callbackContract) external returns (bytes32);
    // This function is expected to be called by the oracle itself to deliver the result.
    function fulfillPromptAnalysis(uint256 requestId, string calldata analysisResult) external;
}

// B. SyndicateMemberProfile: ERC721-based Soulbound Token (SBT)
// Represents a unique, non-transferable identity and reputation for each syndicate member.
contract SyndicateMemberProfile is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping to store member specific data associated with their SBT
    struct MemberData {
        uint256 reputationScore;       // Increases with validated contributions, impacts voting power.
        string[] skillTags;            // User-defined or AI-attributed areas of expertise.
        uint256 contributionsCount;    // Total number of successfully validated insights.
        uint256 governanceVotingPower; // Derived from reputation score.
    }

    mapping(uint256 => MemberData) private _memberData; // tokenId => MemberData
    mapping(address => uint256) private _addressToTokenId; // wallet address => tokenId (for quick lookup)

    // Events for transparency
    event MemberJoined(address indexed memberAddress, uint256 tokenId);
    event ReputationUpdated(uint256 indexed tokenId, uint256 newScore);
    event SkillTagsUpdated(uint256 indexed tokenId, string[] newTags);

    // Constructor: Initializes the ERC721 token with a name and symbol.
    // Owned by the main AetherMindSyndicate contract.
    constructor() ERC721("Syndicate Member Profile", "SMP") Ownable(msg.sender) {}

    // Function: mint
    // Mints a new Soulbound Profile NFT for a given address.
    // Can only be called by the owner (AetherMindSyndicate contract).
    function mint(address to) external onlyOwner returns (uint256) {
        require(_addressToTokenId[to] == 0, "Member already has a profile."); // Ensure only one profile per address
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId); // Mints the ERC721 token

        // Initialize member data
        _memberData[newItemId].reputationScore = 1; // Starting reputation score
        _memberData[newItemId].contributionsCount = 0;
        _memberData[newItemId].governanceVotingPower = 1; // Voting power directly linked to reputation
        _addressToTokenId[to] = newItemId; // Map address to new token ID

        emit MemberJoined(to, newItemId);
        return newItemId;
    }

    // Function: _transfer (Override)
    // Overrides the internal ERC721 transfer function to prevent any transfers, making the token soulbound.
    function _transfer(address, address, uint256) internal pure override {
        revert("Syndicate Profiles are soulbound and non-transferable.");
    }

    // Function: setApprovalForAll (Override)
    // Prevents setting approval for all tokens, reinforcing soulbound nature.
    function setApprovalForAll(address, bool) public pure override {
        revert("Syndicate Profiles are soulbound and non-transferable.");
    }

    // Function: approve (Override)
    // Prevents individual token approval, reinforcing soulbound nature.
    function approve(address, uint256) public pure override {
        revert("Syndicate Profiles are soulbound and non-transferable.");
    }

    // Function: updateReputation
    // Updates the reputation score of a member's profile.
    // Can only be called by the owner (AetherMindSyndicate contract) after a validated contribution.
    function updateReputation(uint256 tokenId, uint256 newScore) external onlyOwner {
        require(_exists(tokenId), "Profile does not exist.");
        _memberData[tokenId].reputationScore = newScore;
        _memberData[tokenId].governanceVotingPower = newScore; // Voting power directly scales with reputation
        emit ReputationUpdated(tokenId, newScore);
    }

    // Function: incrementContributionCount
    // Increments the contribution count for a member's profile.
    // Can only be called by the owner (AetherMindSyndicate contract).
    function incrementContributionCount(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Profile does not exist.");
        _memberData[tokenId].contributionsCount++;
    }

    // Function: setSkillTags
    // Allows the owner of a profile to set or update their associated skill tags.
    function setSkillTags(uint256 tokenId, string[] calldata newTags) external {
        require(ownerOf(tokenId) == msg.sender, "Not profile owner.");
        _memberData[tokenId].skillTags = newTags;
        emit SkillTagsUpdated(tokenId, newTags);
    }

    // Function: getMemberData (View)
    // Retrieves all stored data for a given member profile tokenId.
    function getMemberData(uint256 tokenId) external view returns (MemberData memory) {
        require(_exists(tokenId), "Profile does not exist.");
        return _memberData[tokenId];
    }

    // Function: getTokenIdByAddress (View)
    // Returns the tokenId associated with a given wallet address.
    function getTokenIdByAddress(address memberAddress) external view returns (uint256) {
        return _addressToTokenId[memberAddress];
    }

    // Function: tokenURI (Override View)
    // Returns the metadata URI for a given tokenId.
    // This could be made dynamic to reflect real-time reputation/skills.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token.");
        // Placeholder for a dynamic URI based on member data
        string memory baseURI = "ipfs://Qmbcdef1234567890abcdef1234567890abcdef/";
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }
}


// C. InsightNFT: ERC721-based Dynamic NFT (dNFT)
// Represents a valuable intellectual contribution or "insight" within the syndicate.
// Its attributes and metadata can evolve over time based on validation and AI analysis.
contract InsightNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Struct to store detailed data for each Insight NFT
    struct InsightData {
        uint256 cognitivePower;     // Represents complexity/impact, evolves over time.
        string insightType;         // e.g., "DataAnalysis", "CreativePrompt", "Prediction", "Research"
        string sourceContentURI;    // IPFS URI to the original insight content (text, data, etc.)
        uint256 contributorTokenId; // Link to the SyndicateMemberProfile of the original contributor.
        bool isEvolved;             // Has this insight undergone evolution/refinement?
        string currentMetadataURI;  // Dynamically updated metadata URI.
    }

    mapping(uint256 => InsightData) private _insightData;

    // Events for transparency
    event InsightMinted(uint256 indexed tokenId, address indexed contributor, string insightType, string sourceURI);
    event InsightEvolved(uint256 indexed tokenId, uint256 newCognitivePower, string newMetadataURI);
    event MetadataURIUpdated(uint256 indexed tokenId, string newURI);

    // Constructor: Initializes the ERC721 token.
    // Owned by the main AetherMindSyndicate contract.
    constructor() ERC721("AetherMind Insight NFT", "AMNI") Ownable(msg.sender) {}

    // Function: mint
    // Mints a new Insight NFT.
    // Can only be called by the owner (AetherMindSyndicate contract).
    function mint(address to, string calldata insightType, string calldata sourceURI, uint256 contributorTokenId)
        external
        onlyOwner
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId); // Mints the ERC721 token

        // Initialize Insight Data
        _insightData[newItemId].cognitivePower = 100; // Starting cognitive power
        _insightData[newItemId].insightType = insightType;
        _insightData[newItemId].sourceContentURI = sourceURI;
        _insightData[newItemId].contributorTokenId = contributorTokenId;
        _insightData[newItemId].isEvolved = false;

        // Set initial metadata URI (can be dynamic based on initial data)
        string memory initialURI = string(abi.encodePacked("ipfs://QmaBCDEF", Strings.toString(newItemId))); // Placeholder
        _insightData[newItemId].currentMetadataURI = initialURI;
        _setTokenURI(newItemId, initialURI); // Update URI using ERC721URIStorage extension

        emit InsightMinted(newItemId, to, insightType, sourceURI);
        return newItemId;
    }

    // Function: evolveInsight
    // Allows the main contract to update an Insight NFT's cognitive power and metadata URI.
    // This is key for the dynamic nature, allowing the NFT to change post-mint.
    function evolveInsight(uint256 tokenId, uint256 newCognitivePower, string calldata newMetadataURI) external onlyOwner {
        require(_exists(tokenId), "Insight does not exist.");
        _insightData[tokenId].cognitivePower = newCognitivePower;
        _insightData[tokenId].isEvolved = true;
        _insightData[tokenId].currentMetadataURI = newMetadataURI;
        _setTokenURI(tokenId, newMetadataURI); // Update URI using ERC721URIStorage
        emit InsightEvolved(tokenId, newCognitivePower, newMetadataURI);
    }

    // Function: updateMetadataURI
    // Allows the main contract to update just the metadata URI for an Insight NFT.
    function updateMetadataURI(uint256 tokenId, string calldata newURI) external onlyOwner {
        require(_exists(tokenId), "Insight does not exist.");
        _insightData[tokenId].currentMetadataURI = newURI;
        _setTokenURI(tokenId, newURI);
        emit MetadataURIUpdated(tokenId, newURI);
    }

    // Function: getInsightData (View)
    // Retrieves all stored data for a given Insight NFT tokenId.
    function getInsightData(uint256 tokenId) external view returns (InsightData memory) {
        require(_exists(tokenId), "Insight does not exist.");
        return _insightData[tokenId];
    }

    // Function: tokenURI (Override View)
    // Returns the current dynamic metadata URI for a given tokenId.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token.");
        return _insightData[tokenId].currentMetadataURI;
    }
}


// D. AetherMindSyndicate: The Main Orchestrator Contract
// Manages members, insight proposals, AI integration, and governance.
contract AetherMindSyndicate is Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    InsightNFT public insightNFTContract;             // Address of the InsightNFT contract
    SyndicateMemberProfile public memberProfileContract; // Address of the SyndicateMemberProfile contract
    IAIPromptOracle public aiPromptOracle;           // Address of the AI Prompt Oracle contract
    IERC20 public syndicateToken;                     // Placeholder for a native token (e.g., for fees/rewards)

    uint256 public constant PROPOSAL_VALIDATION_PERIOD = 7 days; // Duration for insight proposal voting
    uint256 public minProposalStakeAmount = 0.01 ether; // Minimum ETH stake required to submit an insight proposal
    uint256 public aiOracleResponseFee = 0.005 ether;   // Fee for requesting AI analysis via oracle

    Counters.Counter private _proposalIdCounter; // Counter for insight proposals

    // Enum for the state of an Insight Proposal
    enum ProposalState { Pending, Voting, Approved, Rejected, Finalized }

    // Struct for an Insight Proposal
    struct InsightProposal {
        address proposer;            // Address of the member who submitted the proposal
        uint256 contributorTokenId;  // Link to the member's SBT
        string insightType;          // Type of insight (e.g., "DataAnalysis")
        string sourceContentURI;     // IPFS URI to the insight's actual content
        uint256 stakeAmount;         // Amount staked by the proposer
        uint256 submissionTime;      // Timestamp of submission
        uint256 votingEndTime;       // Timestamp when voting ends
        uint256 votesFor;            // Total voting power for the proposal
        uint256 votesAgainst;        // Total voting power against the proposal
        mapping(address => bool) hasVoted; // Tracks if a specific address (or their delegate) has voted
        ProposalState state;         // Current state of the proposal
        uint256 insightNFTId;        // TokenId of the minted InsightNFT, if approved
        string aiAnalysisResult;     // Result received from AI oracle
        bytes32 aiRequestId;         // Request ID for the AI oracle call
    }

    mapping(uint256 => InsightProposal) public insightProposals; // Stores all insight proposals

    // --- Governance Mechanism ---
    Counters.Counter private _governanceProposalIdCounter; // Counter for governance proposals
    enum GovernanceProposalState { Pending, Active, Succeeded, Failed, Executed }

    // Struct for a Governance Proposal
    struct GovernanceProposal {
        address proposer;               // Address of the member proposing the action
        string description;             // Description of the proposed action
        bytes callData;                 // Encoded function call to be executed if proposal passes
        address targetContract;         // Target contract for the function call
        uint256 votesFor;               // Total voting power for the proposal
        uint256 votesAgainst;           // Total voting power against the proposal
        mapping(address => bool) hasVoted; // Tracks if an effective voter has voted
        uint256 votingEndTime;          // Timestamp when voting ends
        GovernanceProposalState state;  // Current state of the governance proposal
    }

    mapping(uint256 => GovernanceProposal) public governanceProposals; // Stores all governance proposals
    mapping(address => address) public votingDelegations; // Delegator => Delegatee mapping for voting power

    // --- Events ---
    event MemberJoinedSyndicate(address indexed memberAddress, uint256 profileTokenId);
    event InsightProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string insightType, string sourceURI);
    event ProposalVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState finalState, uint256 insightNFTId);
    event AIAnalysisRequested(uint256 indexed proposalId, bytes32 requestId);
    event AIAnalysisReceived(uint256 indexed proposalId, string analysisResult);
    event InsightEvolvedViaAI(uint256 indexed insightNFTId, string newMetadataURI, uint256 newCognitivePower);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    // Ensures the caller is a registered syndicate member (has an SBT profile).
    modifier onlySyndicateMember() {
        require(memberProfileContract.getTokenIdByAddress(msg.sender) != 0, "Not a syndicate member.");
        _;
    }

    // Constructor: Initializes the main contract with addresses of dependent contracts.
    constructor(address _insightNFTAddress, address _memberProfileAddress, address _syndicateTokenAddress) Ownable(msg.sender) {
        insightNFTContract = InsightNFT(_insightNFTAddress);
        memberProfileContract = SyndicateMemberProfile(_memberProfileAddress);
        syndicateToken = IERC20(_syndicateTokenAddress);
    }

    // --- A. Initialization & Configuration ---

    // 2. Function: setInsightNFTAddress
    // Sets or updates the address of the InsightNFT contract. Only callable by the owner.
    function setInsightNFTAddress(address _address) external onlyOwner {
        insightNFTContract = InsightNFT(_address);
    }

    // 3. Function: setMemberProfileAddress
    // Sets or updates the address of the SyndicateMemberProfile contract. Only callable by the owner.
    function setMemberProfileAddress(address _address) external onlyOwner {
        memberProfileContract = SyndicateMemberProfile(_address);
    }

    // 4. Function: setAIPromptOracle
    // Sets or updates the address of the AI Prompt Oracle contract. Only callable by the owner.
    function setAIPromptOracle(address _oracleAddress) external onlyOwner {
        aiPromptOracle = IAIPromptOracle(_oracleAddress);
    }

    // 5. Function: updateMinProposalStakeAmount
    // Updates the minimum ETH stake required to submit an insight proposal. Only callable by the owner.
    function updateMinProposalStakeAmount(uint256 _newAmount) external onlyOwner {
        minProposalStakeAmount = _newAmount;
    }

    // 6. Function: updateAIOracleResponseFee
    // Updates the fee required for AI Oracle responses. Only callable by the owner.
    function updateAIOracleResponseFee(uint256 _newFee) external onlyOwner {
        aiOracleResponseFee = _newFee;
    }

    // --- B. Member Management ---

    // 7. Function: joinSyndicate
    // Allows a new user to join the syndicate by minting a unique Soulbound Member Profile NFT.
    function joinSyndicate() external {
        // Mints a new SyndicateMemberProfile SBT for the caller
        uint256 profileTokenId = memberProfileContract.getTokenIdByAddress(msg.sender);
        require(profileTokenId == 0, "Already a syndicate member.");
        // The SyndicateMemberProfile contract is owned by this contract, granting permission to mint.
        memberProfileContract.mint(msg.sender);
        emit MemberJoinedSyndicate(msg.sender, memberProfileContract.getTokenIdByAddress(msg.sender));
    }

    // --- C. Insight Proposal & Validation System ---

    // 8. Function: submitInsightProposal
    // Allows a syndicate member to submit a new insight proposal, requiring an ETH stake.
    // The content itself (e.g., text, data, a research paper) should be stored off-chain (e.g., IPFS)
    // and its URI provided here.
    function submitInsightProposal(string calldata _insightType, string calldata _sourceContentURI)
        external
        payable // Requires ETH for staking
        onlySyndicateMember
    {
        require(msg.value >= minProposalStakeAmount, "Insufficient stake for proposal.");
        uint256 contributorTokenId = memberProfileContract.getTokenIdByAddress(msg.sender);

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        InsightProposal storage proposal = insightProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.contributorTokenId = contributorTokenId;
        proposal.insightType = _insightType;
        proposal.sourceContentURI = _sourceContentURI;
        proposal.stakeAmount = msg.value;
        proposal.submissionTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + PROPOSAL_VALIDATION_PERIOD;
        proposal.state = ProposalState.Voting; // Proposal directly enters voting phase

        emit InsightProposalSubmitted(proposalId, msg.sender, _insightType, _sourceContentURI);
    }

    // 9. Function: voteOnProposal
    // Allows a syndicate member to vote on an active insight proposal.
    // Their voting power is determined by their reputation score from their Soulbound Profile.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlySyndicateMember {
        InsightProposal storage proposal = insightProposals[_proposalId];
        require(proposal.state == ProposalState.Voting, "Proposal not in voting state.");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal."); // Prevents double voting

        uint256 voterProfileId = memberProfileContract.getTokenIdByAddress(msg.sender);
        SyndicateMemberProfile.MemberData memory memberData = memberProfileContract.getMemberData(voterProfileId);
        uint256 votingPower = memberData.governanceVotingPower; // Use reputation as voting power

        require(votingPower > 0, "Member has no voting power.");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    // 10. Function: finalizeProposalVoting
    // Concludes the voting period for an insight proposal.
    // If approved, an InsightNFT is minted, the contributor's reputation is updated, and stake is returned.
    // If rejected, the stake is forfeited to the treasury (this contract's balance).
    function finalizeProposalVoting(uint256 _proposalId) external {
        InsightProposal storage proposal = insightProposals[_proposalId];
        require(proposal.state == ProposalState.Voting, "Proposal not in voting state.");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended yet.");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal approved
            proposal.state = ProposalState.Approved;

            // Mint InsightNFT for the proposer
            uint256 newInsightNFTId = insightNFTContract.mint(
                proposal.proposer,
                proposal.insightType,
                proposal.sourceContentURI,
                proposal.contributorTokenId
            );
            proposal.insightNFTId = newInsightNFTId;

            // Update contributor's reputation and contribution count
            SyndicateMemberProfile.MemberData memory contributorData = memberProfileContract.getMemberData(proposal.contributorTokenId);
            memberProfileContract.updateReputation(proposal.contributorTokenId, contributorData.reputationScore + 10); // Reward reputation points
            memberProfileContract.incrementContributionCount(proposal.contributorTokenId);

            // Return stake to proposer if successful
            payable(proposal.proposer).transfer(proposal.stakeAmount);

            emit ProposalFinalized(_proposalId, ProposalState.Approved, newInsightNFTId);

        } else {
            // Proposal rejected
            proposal.state = ProposalState.Rejected;
            // Stake is forfeited to the contract's treasury.
            emit ProposalFinalized(_proposalId, ProposalState.Rejected, 0);
        }
        proposal.state = ProposalState.Finalized; // Mark as finalized regardless of outcome
    }

    // --- D. AI Oracle Integration ---

    // 11. Function: requestAIAnalysis
    // Requests an off-chain AI analysis for a *finalized* insight (which has a minted NFT).
    // Requires a fee to be paid.
    function requestAIAnalysis(uint256 _proposalId) external payable onlySyndicateMember {
        InsightProposal storage proposal = insightProposals[_proposalId];
        require(proposal.state == ProposalState.Finalized, "Proposal not finalized.");
        require(proposal.insightNFTId != 0, "No InsightNFT minted for this proposal."); // Must have an associated NFT
        require(address(aiPromptOracle) != address(0), "AI Oracle not set."); // Oracle must be configured
        require(msg.value >= aiOracleResponseFee, "Insufficient fee for AI analysis.");
        require(proposal.aiRequestId == bytes32(0), "AI analysis already requested for this proposal."); // Prevent re-requesting

        // The AI oracle will analyze the 'sourceContentURI' of the associated InsightNFT.
        // For simplicity, we pass the proposalId and let the oracle fetch content from IPFS.
        // In a real scenario, the oracle might take the content hash or full text directly.
        bytes32 requestId = aiPromptOracle.requestPromptAnalysis(_proposalId, proposal.sourceContentURI, address(this));
        proposal.aiRequestId = requestId;

        emit AIAnalysisRequested(_proposalId, requestId);
    }

    // 12. Function: fulfillPromptAnalysis
    // This is a callback function intended to be called by the `IAIPromptOracle` contract
    // to deliver the results of an off-chain AI analysis.
    function fulfillPromptAnalysis(uint256 _proposalId, string calldata _analysisResult) external {
        require(msg.sender == address(aiPromptOracle), "Only authorized AI Oracle can call this.");
        InsightProposal storage proposal = insightProposals[_proposalId];
        require(proposal.aiRequestId != bytes32(0), "No AI analysis was requested for this proposal ID.");

        proposal.aiAnalysisResult = _analysisResult;
        // At this point, the contract could trigger an automatic evolution of the InsightNFT
        // based on the analysis result, or store the result for future governance actions.
        // For demonstration, `evolveInsightNFT` is a separate manual/governance step.
        emit AIAnalysisReceived(_proposalId, _analysisResult);
    }

    // --- E. Dynamic NFT Evolution ---

    // 13. Function: evolveInsightNFT
    // Allows the evolution of an InsightNFT by updating its cognitive power and metadata URI.
    // In a full system, this would typically be triggered by a governance proposal or an
    // automated system after AI analysis provides new insights for the NFT's evolution.
    function evolveInsightNFT(uint256 _insightNFTId, string calldata _newMetadataURI, uint256 _newCognitivePower) external onlyOwner {
        // This function is `onlyOwner` for simplicity in this example.
        // In a full DAO, the ability to evolve NFTs might be:
        // 1. A direct result of AI analysis (automated, if trusted).
        // 2. A governance action voted upon by the syndicate.
        // 3. Triggered by the NFT owner staking more funds or adding more data.
        insightNFTContract.evolveInsight(_insightNFTId, _newCognitivePower, _newMetadataURI);
        emit InsightEvolvedViaAI(_insightNFTId, _newMetadataURI, _newCognitivePower);
    }

    // --- F. Governance (DAO) ---

    // 14. Function: delegateVotePower
    // Allows a syndicate member to delegate their voting power to another member.
    // This is crucial for scaling DAO governance.
    function delegateVotePower(address _delegatee) external onlySyndicateMember {
        require(_delegatee != address(0), "Cannot delegate to zero address.");
        require(_delegatee != msg.sender, "Cannot delegate to self.");
        require(memberProfileContract.getTokenIdByAddress(_delegatee) != 0, "Delegatee must be a syndicate member.");

        votingDelegations[msg.sender] = _delegatee;
    }

    // 15. Function: getVotingPower (View)
    // Returns the effective voting power of an address, resolving any delegations.
    function getVotingPower(address _voter) public view returns (uint256) {
        address trueVoter = _voter;
        // Resolve delegation chain (basic iteration, might be limited in depth for gas)
        while (votingDelegations[trueVoter] != address(0) && votingDelegations[trueVoter] != trueVoter) {
            trueVoter = votingDelegations[trueVoter];
        }
        uint256 voterProfileId = memberProfileContract.getTokenIdByAddress(trueVoter);
        if (voterProfileId == 0) return 0; // Not a member or no profile
        SyndicateMemberProfile.MemberData memory memberData = memberProfileContract.getMemberData(voterProfileId);
        return memberData.governanceVotingPower;
    }

    // 16. Function: proposeGovernanceAction
    // Allows a syndicate member to propose a general governance action (e.g., contract upgrade, parameter change).
    // The `_targetContract` and `_callData` specify the function to be executed if the proposal passes.
    function proposeGovernanceAction(string calldata _description, address _targetContract, bytes calldata _callData)
        external
        onlySyndicateMember
    {
        _governanceProposalIdCounter.increment();
        uint256 proposalId = _governanceProposalIdCounter.current();

        GovernanceProposal storage proposal = governanceProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.targetContract = _targetContract;
        proposal.callData = _callData;
        proposal.votingEndTime = block.timestamp + PROPOSAL_VALIDATION_PERIOD;
        proposal.state = GovernanceProposalState.Active;

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
    }

    // 17. Function: voteOnGovernanceProposal
    // Allows a syndicate member (or their delegatee) to vote on an active governance proposal.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlySyndicateMember {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == GovernanceProposalState.Active, "Governance proposal not active.");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended.");

        address voter = msg.sender;
        // Resolve to the effective voter if delegation is active
        address trueVoter = voter;
        if (votingDelegations[voter] != address(0) && votingDelegations[voter] != voter) {
            trueVoter = votingDelegations[voter];
        }
        require(!proposal.hasVoted[trueVoter], "Already voted on this governance proposal.");

        uint256 votingPower = getVotingPower(trueVoter);
        require(votingPower > 0, "Caller or their delegate has no voting power.");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[trueVoter] = true; // Mark the effective voter as having voted

        emit GovernanceVoteCast(_proposalId, voter, _support, votingPower);
    }

    // 18. Function: executeGovernanceProposal
    // Executes a governance proposal that has passed its voting period and received more "for" votes.
    // This function will make a low-level call to the target contract with the specified calldata.
    function executeGovernanceProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == GovernanceProposalState.Active, "Governance proposal not active.");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended.");
        require(proposal.votesFor > proposal.votesAgainst, "Governance proposal did not pass.");

        proposal.state = GovernanceProposalState.Succeeded; // Mark as succeeded before execution attempt

        // Execute the proposed action via a low-level call
        (bool success,) = proposal.targetContract.call(proposal.callData);
        require(success, "Governance proposal execution failed.");

        proposal.state = GovernanceProposalState.Executed;
        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- G. Treasury & Incentives ---

    // 19. Function: withdrawTreasuryFunds
    // Allows the contract owner to withdraw funds. In a fully decentralized DAO,
    // this would be replaced by a governance action that votes on and executes withdrawals.
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner {
        payable(_recipient).transfer(_amount);
    }

    // --- H. Query Functions ---

    // 20. Function: getMemberProfile (View)
    // Retrieves a member's full profile data and their associated Soulbound Token ID.
    function getMemberProfile(address _memberAddress) external view returns (SyndicateMemberProfile.MemberData memory, uint256 tokenId) {
        uint256 id = memberProfileContract.getTokenIdByAddress(_memberAddress);
        if (id == 0) {
            // Return default/empty data if no profile exists
            return (SyndicateMemberProfile.MemberData(0, new string[](0), 0, 0), 0);
        }
        return (memberProfileContract.getMemberData(id), id);
    }

    // 21. Function: getInsightDetails (View)
    // Retrieves the detailed data of an InsightNFT and its current owner.
    function getInsightDetails(uint256 _insightNFTId) external view returns (InsightNFT.InsightData memory, address owner) {
        InsightNFT.InsightData memory data = insightNFTContract.getInsightData(_insightNFTId);
        address nftOwner = insightNFTContract.ownerOf(_insightNFTId);
        return (data, nftOwner);
    }

    // 22. Function: getProposalState (View)
    // Returns the current state of a specific insight proposal.
    function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
        return insightProposals[_proposalId].state;
    }

    // 23. Function: getTotalStaked (View)
    // Returns the total amount of ETH held by this contract (representing collected stakes and fees).
    function getTotalStaked() external view returns (uint256) {
        return address(this).balance;
    }
}
```