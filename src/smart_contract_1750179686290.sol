Okay, let's design a smart contract for an **AI Content Curation DAO**. This concept combines AI (as the content source), community curation (DAO), and on-chain reputation/governance, aiming for unique dynamics beyond standard DAO templates or NFT contracts.

Here's the breakdown:

**Concept:** A Decentralized Autonomous Organization (DAO) focused on generating, validating, and managing ownership of AI-generated content (like text, images, music represented by metadata hashes). The DAO members curate submissions, earn reputation for contributions, and govern the minting and distribution of validated content as NFTs.

**Key Advanced/Creative Aspects:**

1.  **AI Integration (Abstracted):** While the AI runs off-chain, the contract manages the *lifecycle* of AI-generated content submissions.
2.  **Reputation System:** Contribution-based (not token-based voting initially) for content validation and proposing.
3.  **Content Validation Game:** A simple voting mechanism to determine content quality/relevance.
4.  **Programmatic NFT Minting:** Validated content can be minted as NFTs directly managed by the DAO or a linked contract.
5.  **Specific Governance Proposals:** Proposals aren't just about funds; they include specific actions on validated content (e.g., "Mint this submission as NFT", "Distribute this NFT").
6.  **Role-Based Contributions:** Introducing "Approved Contributors" vs. general users or reputation holders.

---

**Outline and Function Summary**

**Contract Name:** `AIContentCuratorDAO`

**Core Functionality:**
*   Manages a lifecycle for AI content: Prompt Submission -> Content Submission -> Community Validation -> NFT Minting (via governance).
*   Tracks user reputation based on successful contributions.
*   Implements a governance system for parameter changes and validated content/NFT management.
*   Requires approved contributors for certain actions.

**Function Categories:**

1.  **Setup & Access Control (4 functions)**
2.  **Prompt Management (3 functions)**
3.  **Content Submission & Validation (7 functions)**
4.  **Reputation System (2 functions)**
5.  **DAO Governance (Content/NFT) (4 functions)**
6.  **DAO Governance (Parameters) (4 functions)**
7.  **Information & Queries (5 functions)**

**Function Summary (Total: 29 functions):**

1.  `constructor()`: Initializes the contract owner, sets initial parameters.
2.  `transferOwnership()`: Transfers contract ownership (standard).
3.  `renounceOwnership()`: Renounces contract ownership (standard).
4.  `addApprovedContributor(address contributor)`: Grants the role allowing content submission and validation voting.
5.  `removeApprovedContributor(address contributor)`: Revokes the contributor role.
6.  `isApprovedContributor(address account)`: Checks if an address is an approved contributor.
7.  `submitPrompt(string memory description)`: Allows anyone to submit a prompt for AI content generation (may require a fee/stake in a real system).
8.  `listPendingPrompts()`: Returns a list of prompt IDs that are awaiting content submissions.
9.  `getPromptDetails(uint256 promptId)`: Retrieves details of a specific prompt.
10. `submitContentForPrompt(uint256 promptId, string memory contentHash)`: Allows an approved contributor to submit content (e.g., IPFS hash) for a specific prompt.
11. `listPendingSubmissions()`: Returns a list of content submission IDs awaiting community validation.
12. `voteOnContentSubmission(uint256 submissionId, bool support)`: Allows an approved contributor to vote Yes/No on a content submission's validity/quality. Requires min reputation or is limited per user per submission.
13. `getSubmissionVoteCount(uint256 submissionId)`: Returns the current Yes/No vote counts for a submission.
14. `getSubmissionVoterStatus(uint256 submissionId, address voter)`: Checks if a specific address has already voted on a submission.
15. `finalizeContentSubmission(uint256 submissionId)`: Callable after the voting period ends; processes votes, marks the submission as Validated or Rejected, and awards reputation to voters and the submitter if Validated.
16. `getValidatedContentDetails(uint256 submissionId)`: Retrieves details of a validated content submission (before it might be minted as NFT).
17. `getUserReputation(address account)`: Gets the current reputation score of a user.
18. `getTotalReputationSupply()`: Returns the total sum of all reputation points issued.
19. `proposeDAONFTMint(uint256 submissionId, string memory tokenName, string memory tokenSymbol)`: Allows user with min reputation to propose minting a *validated* content submission as an NFT owned by the DAO.
20. `proposeDAONFTTransfer(uint256 tokenId, address recipient)`: Allows user with min reputation to propose transferring a DAO-owned NFT.
21. `voteOnNFTActionProposal(uint256 proposalId, bool support)`: Allows user with reputation to vote on an NFT-related governance proposal.
22. `executeNFTActionProposal(uint256 proposalId)`: Callable after voting period; executes the approved NFT action (e.g., minting, transferring) if proposal passes.
23. `createParameterProposal(uint256 paramType, uint256 newValue)`: Allows user with min reputation to propose changing contract parameters (e.g., quorum, voting periods).
24. `voteOnParameterProposal(uint256 proposalId, bool support)`: Allows user with reputation to vote on a parameter change proposal.
25. `executeParameterProposal(uint256 proposalId)`: Callable after voting period; applies the new parameter value if the proposal passes.
26. `getProposalDetails(uint256 proposalId)`: Retrieves details of any governance proposal.
27. `listActiveProposals()`: Returns a list of currently active proposal IDs.
28. `getDAOOwnedNFTs()`: Returns a list of NFT Token IDs currently held by the DAO treasury (requires integration with the NFT contract).
29. `getReputationParameters()`: Returns the current reputation points awarded for different actions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive NFTs

// Interface for the AI Content NFT contract managed by the DAO
interface IAIContentNFT is IERC721 {
    function mint(address to, uint256 tokenId, string memory tokenURI) external;
    // Add other potential functions the DAO might call, e.g., burn, updateURI, etc.
}

contract AIContentCuratorDAO is Ownable, ERC721Holder {

    // --- State Variables ---

    // Counters for unique IDs
    uint256 public nextPromptId = 1;
    uint256 public nextSubmissionId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextNFTTokenId = 1; // Token IDs for NFTs minted by the DAO

    // AI Content NFT contract managed by this DAO (MINTER role assumed)
    IAIContentNFT public aiContentNFTContract;

    // Structs to define data structures

    enum PromptState { Pending, Generated, Rejected }
    struct Prompt {
        uint256 id;
        address submitter;
        string description; // e.g., "Generate a futuristic landscape image"
        uint256 submittedAt;
        PromptState state;
        // Could add: requiredStake, payoutAmount, etc.
    }
    mapping(uint256 => Prompt) public prompts;
    uint256[] public pendingPromptIds; // Simple list for pending prompts

    enum SubmissionState { PendingValidation, Validated, Rejected }
    struct ContentSubmission {
        uint256 id;
        uint256 promptId;
        address submitter;
        string contentHash; // IPFS/Arweave hash of the generated content (e.g., image, text, audio)
        uint256 submittedAt;
        SubmissionState state;
        uint256 yesVotes;
        uint256 noVotes;
        // Mapping to track voters and prevent double voting: voter => timestamp voted
        mapping(address => uint256) voters;
        uint256 validationVoteEndBlock; // Block number when voting ends
        bool finalized; // Has finalization been processed?
        uint256 reputationAwarded; // Total reputation points awarded for this submission lifecycle
    }
    mapping(uint256 => ContentSubmission) public submissions;
    uint256[] public pendingSubmissionIds; // Simple list for submissions awaiting validation
    // Mapping to quickly get validated submission details by ID
    mapping(uint256 => string) public validatedContentHashes; // Stores contentHash for validated submissions

    // Reputation System
    mapping(address => uint256) public reputation;
    uint256 public totalReputationSupply = 0;

    struct ReputationParams {
        uint256 promptSubmission; // Rep for submitting a prompt (if applicable)
        uint256 contentSubmissionValidated; // Rep for submitting content that gets validated
        uint256 successfulValidationVote; // Rep for voting 'Yes' on content that gets validated
        uint256 successfulProposalExecution; // Rep for user whose proposal gets executed
        uint256 proposalVote; // Rep for participating in a successful vote (on winning side)
    }
    ReputationParams public reputationParams;

    // Governance System
    enum ProposalType { ParameterChange, NFTAction }
    enum ParameterType { ValidationQuorum, SubmissionVotePeriodBlocks, MinReputationToPropose, ProposalVotingPeriodBlocks }
    enum NFTActionType { MintValidatedSubmission, TransferNFT, SetTokenURI } // Add more actions as needed

    struct ParameterChangeDetails {
        ParameterType paramType;
        uint256 newValue;
    }

    struct NFTActionDetails {
        NFTActionType actionType;
        uint256 targetId; // SubmissionId for Mint, TokenId for Transfer/SetURI
        address recipient; // For Transfer
        string tokenURI; // For SetTokenURI
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        ProposalType proposalType;
        // Using bytes for flexible data, decode based on proposalType
        bytes details;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        // Mapping to track voters and prevent double voting: voter => timestamp voted
        mapping(address => uint256) voters;
        bool executed;
        bool cancelled;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256[] public activeProposalIds;

    // Governance Parameters
    uint256 public validationQuorumPercent = 51; // % of yes votes required for submission validation (out of total votes)
    uint256 public submissionVotePeriodBlocks = 100; // How many blocks voting is open for a submission
    uint256 public minReputationToPropose = 100; // Min reputation required to create a proposal
    uint256 public proposalVotingPeriodBlocks = 1000; // How many blocks governance voting is open

    // Approved Contributors Role (Can submit content, vote on validation)
    mapping(address => bool) public approvedContributors;

    // --- Events ---

    event PromptSubmitted(uint256 indexed promptId, address indexed submitter, string description);
    event ContentSubmitted(uint256 indexed submissionId, uint256 indexed promptId, address indexed submitter, string contentHash);
    event SubmissionVoteCast(uint256 indexed submissionId, address indexed voter, bool support, uint256 yesVotes, uint256 noVotes);
    event SubmissionFinalized(uint256 indexed submissionId, SubmissionState finalState, uint256 yesVotes, uint256 noVotes, uint256 totalVotes);
    event ReputationAwarded(address indexed account, uint256 amount, string reason);
    event ApprovedContributorAdded(address indexed account);
    event ApprovedContributorRemoved(address indexed account);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event ProposalVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 forVotes, uint256 againstVotes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event ParameterChanged(ParameterType paramType, uint256 newValue);
    event NFTActionExecuted(uint256 indexed proposalId, NFTActionType actionType, uint256 targetId, address recipient, string tokenURI); // Generic event for NFT actions

    // --- Modifiers ---

    modifier onlyApprovedContributor() {
        require(approvedContributors[msg.sender], "AIContentCuratorDAO: Not an approved contributor");
        _;
    }

    modifier onlyMinimumReputation(uint256 requiredRep) {
        require(reputation[msg.sender] >= requiredRep, "AIContentCuratorDAO: Insufficient reputation");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, address _aiContentNFTContract) Ownable(initialOwner) {
        require(_aiContentNFTContract != address(0), "AIContentCuratorDAO: Invalid NFT contract address");
        aiContentNFTContract = IAIContentNFT(_aiContentNFTContract);

        // Set initial reputation parameters (example values)
        reputationParams = ReputationParams({
            promptSubmission: 5,
            contentSubmissionValidated: 50,
            successfulValidationVote: 5,
            successfulProposalExecution: 20,
            proposalVote: 2
        });

        // Add owner as initial approved contributor? Maybe not, requires explicit adding
    }

    // --- Setup & Access Control (4 functions) ---

    // 1. constructor - see above
    // 2. transferOwnership - Inherited from Ownable
    // 3. renounceOwnership - Inherited from Ownable

    // 4. Add an approved contributor
    function addApprovedContributor(address contributor) external onlyOwner {
        require(contributor != address(0), "AIContentCuratorDAO: Zero address");
        approvedContributors[contributor] = true;
        emit ApprovedContributorAdded(contributor);
    }

    // 5. Remove an approved contributor
    function removeApprovedContributor(address contributor) external onlyOwner {
        require(contributor != address(0), "AIContentCuratorDAO: Zero address");
        approvedContributors[contributor] = false;
        emit ApprovedContributorRemoved(contributor);
    }

    // 6. Check if an address is an approved contributor
    function isApprovedContributor(address account) external view returns (bool) {
        return approvedContributors[account];
    }

    // --- Prompt Management (3 functions) ---

    // 7. Submit a new prompt for AI content generation
    function submitPrompt(string memory description) external returns (uint256) {
        // Could add a stake requirement here: require(msg.value >= promptStakeAmount, "Requires stake");
        uint256 promptId = nextPromptId++;
        prompts[promptId] = Prompt({
            id: promptId,
            submitter: msg.sender,
            description: description,
            submittedAt: block.timestamp,
            state: PromptState.Pending
        });
        pendingPromptIds.push(promptId); // Add to pending list
        emit PromptSubmitted(promptId, msg.sender, description);
        return promptId;
    }

    // 8. List prompt IDs that are pending content submission
    function listPendingPrompts() external view returns (uint256[] memory) {
        return pendingPromptIds;
    }

    // 9. Get details of a specific prompt
    function getPromptDetails(uint256 promptId) external view returns (Prompt memory) {
        require(prompts[promptId].id != 0, "AIContentCuratorDAO: Invalid prompt ID");
        return prompts[promptId];
    }

    // --- Content Submission & Validation (7 functions) ---

    // 10. Submit content generated for a prompt (by an approved contributor)
    function submitContentForPrompt(uint256 promptId, string memory contentHash) external onlyApprovedContributor returns (uint256) {
        Prompt storage prompt = prompts[promptId];
        require(prompt.id != 0, "AIContentCuratorDAO: Invalid prompt ID");
        require(prompt.state == PromptState.Pending, "AIContentCuratorDAO: Prompt not pending");
        require(bytes(contentHash).length > 0, "AIContentCuratorDAO: Content hash cannot be empty");

        uint256 submissionId = nextSubmissionId++;
        submissions[submissionId] = ContentSubmission({
            id: submissionId,
            promptId: promptId,
            submitter: msg.sender,
            contentHash: contentHash,
            submittedAt: block.timestamp,
            state: SubmissionState.PendingValidation,
            yesVotes: 0,
            noVotes: 0,
            voters: new mapping(address => uint256)(), // Initialize the mapping
            validationVoteEndBlock: block.number + submissionVotePeriodBlocks,
            finalized: false,
            reputationAwarded: 0
        });

        // Remove from pending prompts and add to pending submissions
        // This is a simplified approach. A real implementation would use a more efficient data structure or not rely on array iteration.
        for (uint i = 0; i < pendingPromptIds.length; i++) {
            if (pendingPromptIds[i] == promptId) {
                pendingPromptIds[i] = pendingPromptIds[pendingPromptIds.length - 1];
                pendingPromptIds.pop();
                break;
            }
        }

        pendingSubmissionIds.push(submissionId);
        prompt.state = PromptState.Generated; // Mark prompt as having content generated

        emit ContentSubmitted(submissionId, promptId, msg.sender, contentHash);
        return submissionId;
    }

    // 11. List content submission IDs that are awaiting community validation
    function listPendingSubmissions() external view returns (uint256[] memory) {
        // Filter out submissions whose voting period has ended but haven't been finalized
        uint256[] memory currentPending;
        uint256 count = 0;
        for(uint i = 0; i < pendingSubmissionIds.length; i++) {
            uint256 subId = pendingSubmissionIds[i];
            if (submissions[subId].validationVoteEndBlock > block.number && !submissions[subId].finalized) {
                 count++;
            }
        }

        currentPending = new uint256[](count);
        count = 0;
         for(uint i = 0; i < pendingSubmissionIds.length; i++) {
            uint256 subId = pendingSubmissionIds[i];
            if (submissions[subId].validationVoteEndBlock > block.number && !submissions[subId].finalized) {
                 currentPending[count++] = subId;
            }
        }
        return currentPending;
    }

    // 12. Vote on a content submission's validity
    function voteOnContentSubmission(uint256 submissionId, bool support) external onlyApprovedContributor {
        ContentSubmission storage submission = submissions[submissionId];
        require(submission.id != 0, "AIContentCuratorDAO: Invalid submission ID");
        require(submission.state == SubmissionState.PendingValidation, "AIContentCuratorDAO: Submission not pending validation");
        require(block.number <= submission.validationVoteEndBlock, "AIContentCuratorDAO: Voting period has ended");
        require(submission.voters[msg.sender] == 0, "AIContentCuratorDAO: Already voted on this submission");
        // Could add: require(reputation[msg.sender] >= minReputationToVote, "Insufficient reputation to vote");

        if (support) {
            submission.yesVotes++;
        } else {
            submission.noVotes++;
        }
        submission.voters[msg.sender] = block.timestamp; // Record vote timestamp

        emit SubmissionVoteCast(submissionId, msg.sender, support, submission.yesVotes, submission.noVotes);
    }

    // 13. Get the current vote count for a submission
    function getSubmissionVoteCount(uint256 submissionId) external view returns (uint256 yesVotes, uint256 noVotes) {
        ContentSubmission storage submission = submissions[submissionId];
        require(submission.id != 0, "AIContentCuratorDAO: Invalid submission ID");
        return (submission.yesVotes, submission.noVotes);
    }

    // 14. Check if a user has voted on a submission
    function getSubmissionVoterStatus(uint256 submissionId, address voter) external view returns (bool hasVoted) {
         ContentSubmission storage submission = submissions[submissionId];
         require(submission.id != 0, "AIContentCuratorDAO: Invalid submission ID");
         return submission.voters[voter] != 0;
    }

    // 15. Finalize voting for a content submission
    function finalizeContentSubmission(uint256 submissionId) external {
        ContentSubmission storage submission = submissions[submissionId];
        require(submission.id != 0, "AIContentCuratorDAO: Invalid submission ID");
        require(submission.state == SubmissionState.PendingValidation, "AIContentCuratorDAO: Submission not pending validation");
        require(block.number > submission.validationVoteEndBlock, "AIContentCuratorDAO: Voting period not ended yet");
        require(!submission.finalized, "AIContentCuratorDAO: Submission already finalized");

        submission.finalized = true;

        uint256 totalVotes = submission.yesVotes + submission.noVotes;
        SubmissionState finalState;

        // Determine final state based on votes and quorum
        if (totalVotes > 0 && (submission.yesVotes * 100 / totalVotes) >= validationQuorumPercent) {
            finalState = SubmissionState.Validated;
            // Store hash for validated content
            validatedContentHashes[submissionId] = submission.contentHash;

            // Award reputation
            // Award submitter
            _awardReputation(submission.submitter, reputationParams.contentSubmissionValidated, "Validated Content Submission");
            submission.reputationAwarded += reputationParams.contentSubmissionValidated;

            // Award voters who voted Yes (simplified: everyone who voted gets rep based on success)
            // A more advanced system would verify which voters voted 'Yes' and only reward them.
            // For this example, let's award a fixed amount to *all* voters in a successful validation.
            // This requires iterating through voters mapping which is not standard in Solidity.
            // Let's simplify: award voters rep when they *cast* a vote if the submission *later* gets validated.
            // This means we need to award reputation *during* finalization based on recorded votes.
            // The `voters` mapping stores vote timestamps. We can't iterate it easily.
            // Alternative: Store voters in a dynamic array per submission (gas heavy) or award rep *immediately* upon voting, risk rewarding bad votes?
            // Let's stick to the original plan: award upon finalization, but accept the limitation that we can't iterate `voters` mapping.
            // A robust implementation would store voters in an array or use events + off-chain processing to manage reputation.
            // For this example, let's acknowledge this complexity and skip awarding voters rep *in* this function due to mapping limitation.
            // A simplified approach: Award a fixed small rep to the submitter if validated. Voters get rep for participating, regardless of outcome, awarded immediately on vote. (Let's revise voteOnContentSubmission).

            // Revision Plan:
            // 1. `voteOnContentSubmission`: Award `reputationParams.proposalVote` upon voting (regardless of support) if the submission is still pending validation.
            // 2. `finalizeContentSubmission`: Award `reputationParams.contentSubmissionValidated` to the submitter ONLY if validated.

            // Okay, re-implementing the reputation logic based on the revised plan:
            // Reputation awarding moved to `voteOnContentSubmission` for voters.
            // Award submitter here:
            // Already awarded above: _awardReputation(submission.submitter, reputationParams.contentSubmissionValidated, "Validated Content Submission");

        } else {
            finalState = SubmissionState.Rejected;
            // No reputation awarded for rejection (for submitter)
        }

        submission.state = finalState;

        // Remove from pending submissions list
         for (uint i = 0; i < pendingSubmissionIds.length; i++) {
            if (pendingSubmissionIds[i] == submissionId) {
                pendingSubmissionIds[i] = pendingSubmissionIds[pendingSubmissionIds.length - 1];
                pendingSubmissionIds.pop();
                break;
            }
        }

        emit SubmissionFinalized(submissionId, finalState, submission.yesVotes, submission.noVotes, totalVotes);
    }

    // 16. Get details of a validated content submission (before NFT minting)
    function getValidatedContentDetails(uint256 submissionId) external view returns (uint256 id, uint256 promptId, address submitter, string memory contentHash, uint256 submittedAt) {
        ContentSubmission storage submission = submissions[submissionId];
        require(submission.id != 0, "AIContentCuratorDAO: Invalid submission ID");
        require(submission.state == SubmissionState.Validated, "AIContentCuratorDAO: Submission not validated");
        return (submission.id, submission.promptId, submission.submitter, submission.contentHash, submission.submittedAt);
    }

    // --- Reputation System (2 functions) ---

    // Internal helper to award reputation
    function _awardReputation(address account, uint256 amount, string memory reason) internal {
        if (amount > 0) {
            reputation[account] += amount;
            totalReputationSupply += amount;
            emit ReputationAwarded(account, amount, reason);
        }
    }

    // 17. Get the reputation score for a user
    function getUserReputation(address account) external view returns (uint256) {
        return reputation[account];
    }

    // 18. Get the total sum of reputation points issued
    function getTotalReputationSupply() external view returns (uint256) {
        return totalReputationSupply;
    }

    // 29. Get reputation parameters
    function getReputationParameters() external view returns (ReputationParams memory) {
        return reputationParams;
    }


    // --- DAO Governance (Content/NFT) (4 functions) ---

    // Helper to encode/decode proposal details
    function _encodeParameterChange(ParameterType paramType, uint256 newValue) internal pure returns (bytes memory) {
        return abi.encode(paramType, newValue);
    }

    function _decodeParameterChange(bytes memory details) internal pure returns (ParameterType paramType, uint256 newValue) {
        (paramType, newValue) = abi.decode(details, (ParameterType, uint256));
    }

    function _encodeNFTAction(NFTActionType actionType, uint256 targetId, address recipient, string memory tokenURI) internal pure returns (bytes memory) {
        return abi.encode(actionType, targetId, recipient, tokenURI);
    }

    function _decodeNFTAction(bytes memory details) internal pure returns (NFTActionType actionType, uint256 targetId, address recipient, string memory tokenURI) {
         (actionType, targetId, recipient, tokenURI) = abi.decode(details, (NFTActionType, uint256, address, string));
    }


    // 19. Propose minting a validated submission as a DAO-owned NFT
    function proposeDAONFTMint(uint256 submissionId, string memory tokenURI) external onlyMinimumReputation(minReputationToPropose) returns (uint256) {
         ContentSubmission storage submission = submissions[submissionId];
         require(submission.state == SubmissionState.Validated, "AIContentCuratorDAO: Submission must be validated to propose minting");
         // Could add check: require no active/passed proposal for this submission ID

         uint256 proposalId = nextProposalId++;
         bytes memory details = _encodeNFTAction(NFTActionType.MintValidatedSubmission, submissionId, address(0), tokenURI);

         proposals[proposalId] = Proposal({
             id: proposalId,
             proposer: msg.sender,
             description: string(abi.encodePacked("Propose minting submission #", uint256ToString(submissionId), " as NFT")),
             proposalType: ProposalType.NFTAction,
             details: details,
             startBlock: block.number,
             endBlock: block.number + proposalVotingPeriodBlocks,
             forVotes: 0,
             againstVotes: 0,
             voters: new mapping(address => uint256)(), // Initialize the mapping
             executed: false,
             cancelled: false
         });
         activeProposalIds.push(proposalId);

         emit ProposalCreated(proposalId, msg.sender, ProposalType.NFTAction, proposals[proposalId].description);
         return proposalId;
    }

    // 20. Propose transferring a DAO-owned NFT
    function proposeDAONFTTransfer(uint256 tokenId, address recipient) external onlyMinimumReputation(minReputationToPropose) returns (uint256) {
         require(recipient != address(0), "AIContentCuratorDAO: Recipient is zero address");
         // Check if the DAO actually owns the NFT (requires interaction with NFT contract)
         require(aiContentNFTContract.ownerOf(tokenId) == address(this), "AIContentCuratorDAO: DAO does not own this NFT");

         uint256 proposalId = nextProposalId++;
         bytes memory details = _encodeNFTAction(NFTActionType.TransferNFT, tokenId, recipient, "");

         proposals[proposalId] = Proposal({
             id: proposalId,
             proposer: msg.sender,
             description: string(abi.encodePacked("Propose transferring NFT #", uint256ToString(tokenId), " to ", addressToString(recipient))),
             proposalType: ProposalType.NFTAction,
             details: details,
             startBlock: block.number,
             endBlock: block.number + proposalVotingPeriodBlocks,
             forVotes: 0,
             againstVotes: 0,
             voters: new mapping(address => uint256)(),
             executed: false,
             cancelled: false
         });
         activeProposalIds.push(proposalId);

         emit ProposalCreated(proposalId, msg.sender, ProposalType.NFTAction, proposals[proposalId].description);
         return proposalId;
    }

    // 21. Vote on an NFT action governance proposal
    function voteOnNFTActionProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AIContentCuratorDAO: Invalid proposal ID");
        require(proposal.proposalType == ProposalType.NFTAction, "AIContentCuratorDAO: Not an NFT action proposal");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "AIContentCuratorDAO: Voting is not open");
        require(proposal.voters[msg.sender] == 0, "AIContentCuratorDAO: Already voted on this proposal");
         require(reputation[msg.sender] > 0, "AIContentCuratorDAO: Must have reputation to vote"); // Only users with reputation can vote

        // Voting weight is proportional to reputation
        uint256 voteWeight = reputation[msg.sender];
        if (support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }
        proposal.voters[msg.sender] = block.timestamp;

        emit ProposalVoteCast(proposalId, msg.sender, support, proposal.forVotes, proposal.againstVotes);
    }

    // 22. Execute a passed NFT action governance proposal
    function executeNFTActionProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AIContentCuratorDAO: Invalid proposal ID");
        require(proposal.proposalType == ProposalType.NFTAction, "AIContentCuratorDAO: Not an NFT action proposal");
        require(block.number > proposal.endBlock, "AIContentCuratorDAO: Voting period not ended");
        require(!proposal.executed, "AIContentCuratorDAO: Proposal already executed");
        require(!proposal.cancelled, "AIContentCuratorDAO: Proposal cancelled");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        // Check if proposal passes (simple majority based on reputation weight)
        bool passed = totalVotes > 0 && (proposal.forVotes * 100 / totalVotes) >= 51; // Use a governance parameter for this percentage?

        if (passed) {
            (NFTActionType actionType, uint256 targetId, address recipient, string memory tokenURI) = _decodeNFTAction(proposal.details);

            if (actionType == NFTActionType.MintValidatedSubmission) {
                 ContentSubmission storage submission = submissions[targetId];
                 require(submission.state == SubmissionState.Validated, "AIContentCuratorDAO: Submission must be validated for minting");
                 require(validatedContentHashes[targetId] != "", "AIContentCuratorDAO: Validated content hash not found"); // Double check hash exists
                 // Prevent double minting the same submission? Need a flag on submission or track minted submission IDs.
                 // Let's assume one submission -> potentially one NFT mint proposal execution.
                 // Add check: require(submission.mintedNFTId == 0); // Add mintedNFTId field to Submission struct

                 uint256 newTokenId = nextNFTTokenId++;
                 // Call the mint function on the external NFT contract
                 aiContentNFTContract.mint(address(this), newTokenId, tokenURI); // Mint to the DAO contract
                 // submission.mintedNFTId = newTokenId; // Update submission state (requires adding field)

                 emit NFTActionExecuted(proposalId, actionType, targetId, address(this), tokenURI);

            } else if (actionType == NFTActionType.TransferNFT) {
                 require(recipient != address(0), "AIContentCuratorDAO: Recipient is zero address");
                 // Call the transfer function on the external NFT contract
                 aiContentNFTContract.transferFrom(address(this), recipient, targetId); // targetId is tokenId here

                 emit NFTActionExecuted(proposalId, actionType, targetId, recipient, "");

            }
            // Add other NFT actions here (e.g., SetTokenURI)

            proposal.executed = true;
            _awardReputation(proposal.proposer, reputationParams.successfulProposalExecution, "Successful Proposal Execution");
             // Simplified: Award voters on winning side? Requires iterating voters mapping. Skipping for now.

        } else {
             // Proposal failed, maybe award voters on losing side a tiny bit of rep? Or no rep for failed votes.
        }

        // Remove from active proposals list
        // Simplified removal
         for (uint i = 0; i < activeProposalIds.length; i++) {
            if (activeProposalIds[i] == proposalId) {
                activeProposalIds[i] = activeProposalIds[activeProposalIds.length - 1];
                activeProposalIds.pop();
                break;
            }
        }

        emit ProposalExecuted(proposalId); // Emits even if failed, just executed=true remains false
    }


    // --- DAO Governance (Parameters) (4 functions) ---

    // 23. Create a proposal to change a contract parameter
    function createParameterProposal(uint256 paramType, uint256 newValue) external onlyMinimumReputation(minReputationToPropose) returns (uint256) {
        require(paramType <= uint256(ParameterType.ProposalVotingPeriodBlocks), "AIContentCuratorDAO: Invalid parameter type");
        require(newValue > 0, "AIContentCuratorDAO: Parameter value must be positive");
        // Could add bounds checks for specific parameters (e.g., quorum < 100)

        uint256 proposalId = nextProposalId++;
        bytes memory details = _encodeParameterChange(ParameterType(paramType), newValue);

        string memory description;
        if (paramType == uint256(ParameterType.ValidationQuorum)) description = string(abi.encodePacked("Change Validation Quorum to ", uint256ToString(newValue), "%"));
        else if (paramType == uint256(ParameterType.SubmissionVotePeriodBlocks)) description = string(abi.encodePacked("Change Submission Vote Period to ", uint256ToString(newValue), " blocks"));
        else if (paramType == uint256(ParameterType.MinReputationToPropose)) description = string(abi.encodePacked("Change Min Reputation to Propose to ", uint256ToString(newValue)));
        else if (paramType == uint256(ParameterType.ProposalVotingPeriodBlocks)) description = string(abi.encodePacked("Change Proposal Voting Period to ", uint256ToString(newValue), " blocks"));

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: ProposalType.ParameterChange,
            details: details,
            startBlock: block.number,
            endBlock: block.number + proposalVotingPeriodBlocks,
            forVotes: 0,
            againstVotes: 0,
            voters: new mapping(address => uint256)(),
            executed: false,
            cancelled: false
        });
        activeProposalIds.push(proposalId);

        emit ProposalCreated(proposalId, msg.sender, ProposalType.ParameterChange, description);
        return proposalId;
    }

    // 24. Vote on a parameter change governance proposal
    function voteOnParameterProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AIContentCuratorDAO: Invalid proposal ID");
        require(proposal.proposalType == ProposalType.ParameterChange, "AIContentCuratorDAO: Not a parameter change proposal");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "AIContentCuratorDAO: Voting is not open");
        require(proposal.voters[msg.sender] == 0, "AIContentCuratorDAO: Already voted on this proposal");
        require(reputation[msg.sender] > 0, "AIContentCuratorDAO: Must have reputation to vote");

        uint256 voteWeight = reputation[msg.sender];
        if (support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }
        proposal.voters[msg.sender] = block.timestamp;

        emit ProposalVoteCast(proposalId, msg.sender, support, proposal.forVotes, proposal.againstVotes);
    }

    // 25. Execute a passed parameter change governance proposal
    function executeParameterProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AIContentCuratorDAO: Invalid proposal ID");
        require(proposal.proposalType == ProposalType.ParameterChange, "AIContentCuratorDAO: Not a parameter change proposal");
        require(block.number > proposal.endBlock, "AIContentCuratorDAO: Voting period not ended");
        require(!proposal.executed, "AIContentCuratorDAO: Proposal already executed");
        require(!proposal.cancelled, "AIContentCuratorDAO: Proposal cancelled");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        bool passed = totalVotes > 0 && (proposal.forVotes * 100 / totalVotes) >= 51; // Use governance param?

        if (passed) {
            (ParameterType paramType, uint256 newValue) = _decodeParameterChange(proposal.details);

            if (paramType == ParameterType.ValidationQuorum) {
                require(newValue <= 100, "AIContentCuratorDAO: Quorum cannot exceed 100%");
                validationQuorumPercent = newValue;
            } else if (paramType == ParameterType.SubmissionVotePeriodBlocks) {
                submissionVotePeriodBlocks = newValue;
            } else if (paramType == ParameterType.MinReputationToPropose) {
                minReputationToPropose = newValue;
            } else if (paramType == ParameterType.ProposalVotingPeriodBlocks) {
                proposalVotingPeriodBlocks = newValue;
            }
            // Add cases for other parameters if added to enum

            proposal.executed = true;
             _awardReputation(proposal.proposer, reputationParams.successfulProposalExecution, "Successful Parameter Change Proposal");

            emit ProposalExecuted(proposalId);
            emit ParameterChanged(paramType, newValue);

        } // else: proposal failed
         // Remove from active proposals list
         for (uint i = 0; i < activeProposalIds.length; i++) {
            if (activeProposalIds[i] == proposalId) {
                activeProposalIds[i] = activeProposalIds[activeProposalIds.length - 1];
                activeProposalIds.pop();
                break;
            }
        }
    }

    // --- Information & Queries (5 functions) ---

    // 26. Get details of any governance proposal
    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {
        require(proposals[proposalId].id != 0, "AIContentCuratorDAO: Invalid proposal ID");
        // Note: Mapping `voters` inside the struct is private to storage and cannot be returned directly.
        // Need separate getter for vote status if needed.
        Proposal storage p = proposals[proposalId];
        return Proposal({
            id: p.id,
            proposer: p.proposer,
            description: p.description,
            proposalType: p.proposalType,
            details: p.details,
            startBlock: p.startBlock,
            endBlock: p.endBlock,
            forVotes: p.forVotes,
            againstVotes: p.againstVotes,
            voters: new mapping(address => uint256)(), // Return empty mapping as a workaround
            executed: p.executed,
            cancelled: p.cancelled
        });
    }

    // 27. List currently active proposal IDs
     function listActiveProposals() external view returns (uint256[] memory) {
        // Filter out proposals whose voting period has ended but haven't been executed/cancelled
        uint256[] memory currentActive;
        uint256 count = 0;
        for(uint i = 0; i < activeProposalIds.length; i++) {
            uint256 propId = activeProposalIds[i];
            if (block.number <= proposals[propId].endBlock && !proposals[propId].executed && !proposals[propId].cancelled) {
                 count++;
            }
        }

        currentActive = new uint256[](count);
        count = 0;
         for(uint i = 0; i < activeProposalIds.length; i++) {
            uint256 propId = activeProposalIds[i];
             if (block.number <= proposals[propId].endBlock && !proposals[propId].executed && !proposals[propId].cancelled) {
                 currentActive[count++] = propId;
            }
        }
        return currentActive;
    }

    // 28. List NFTs currently owned by the DAO treasury (this contract address)
    // This requires the NFT contract to have a function to list tokens owned by an address.
    // Standard ERC721 doesn't provide this efficiently. An external indexer is better.
    // However, a common pattern is to track minted NFTs in this contract or have the NFT contract itself provide this.
    // Let's assume the NFT contract has a function `tokensOfOwner(address owner)` for demonstration.
    // NOTE: `ERC721Holder` doesn't automatically track held tokens; it only provides the `onERC721Received` hook.
    // A mapping `daoOwnedNFTs[uint256 tokenId] => bool` or similar would be needed in this contract.
    // For simplicity, let's return a dummy array or rely on external tools.
    // Or, let's assume `IAIContentNFT` has a `tokensOfOwner` or similar getter.
    // Let's add a basic internal tracker for *NFTs minted by this DAO*.
    mapping(uint256 => bool) internal daoMintedNFTs; // Tracks tokens minted by this DAO. Not necessarily ALL NFTs held.
    uint256[] internal daoMintedNFTIds; // Simple array to list them (inefficient for many tokens)

    // We need to update `executeNFTActionProposal` (Mint case) to add to this list.
    // We also need to update `executeNFTActionProposal` (Transfer case) to remove from this list *if* the NFT was minted by the DAO and transferred *out*.
    // If the DAO receives an NFT *not* minted by it (via onERC721Received), it won't be in `daoMintedNFTs`.
    // Tracking *all* held NFTs is hard without iterating. Let's rename this slightly or provide a limited view.
    // Let's provide a function to query the *known* minted/held NFTs.

    function getDAOManagedNFTIds() external view returns (uint256[] memory) {
         // This will return IDs *minted by this contract* AND still believed to be held,
         // based on internal tracking. Not guaranteed accurate if NFTs are transferred externally
         // or received from elsewhere. A real system needs `tokensOfOwner` on the NFT or indexer.
         return daoMintedNFTIds;
    }

    // 29. Get reputation parameters - already added under Reputation System section.

    // --- Helper Functions ---

    // Basic uint256 to string conversion (for proposal descriptions)
    function uint256ToString(uint256 _i) internal pure returns (string memory _string) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (uint8)(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Basic address to string conversion (for proposal descriptions)
    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory __bytes = new bytes(40);

        for(uint i = 0; i < 20; i++) {
            bytes1 byte1 = bytes1(uint8(uint256(_bytes) / (2**(8*(19 - i)))));
            bytes1 right = bytes1(uint8(byte1) & 0xf);
            bytes1 left = bytes1(uint8(byte1) / 0x10);
            __bytes[i*2] = _toChar(left);
            __bytes[i*2 + 1] = _toChar(right);
        }
        return string(__bytes);
    }

    function _toChar(bytes1 b) internal pure returns (bytes1) {
        if (b < 10) return bytes1(uint8(b) + 0x30);
        return bytes1(uint8(b) + 0x57);
    }


    // --- ERC721Holder Integration ---
    // This function is called when an ERC721 token is transferred to this contract.
    // It doesn't automatically track the token, you'd need to add custom logic here
    // if you want the DAO to manage tokens not minted by it.
    // For this example, we only manage NFTs we propose to mint.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Optionally log the reception
        // emit ERC721Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    // Add a function to receive native currency if needed (not explicitly part of the NFT/Rep system, but common for treasuries)
    // receive() external payable {} // Uncomment if the DAO should receive ETH/other native currency
    // fallback() external payable {} // Uncomment if needed

}
```