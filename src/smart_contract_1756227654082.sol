This smart contract, named **AetherForge**, is a cutting-edge platform designed to foster decentralized creativity, leveraging AI oracles and dynamic Soulbound NFTs. It enables users to propose "creative challenges" with bounties, submit their unique solutions (potentially AI-assisted), and have their work evaluated by both community votes and a designated AI oracle. Successful contributors earn non-transferable "Creative Proof" NFTs that dynamically evolve with their reputation and achievements, along with a creative reputation score. The platform itself features a light form of "self-evolution" by allowing proposals and votes on certain platform parameters.

---

## AetherForge Smart Contract: Outline & Function Summary

**Contract Name:** `AetherForge`

**Core Concepts:**

1.  **AI-Augmented Creative Challenges:** Users propose challenges (e.g., "design a logo," "write a story prompt") with an ETH bounty. Submissions are judged by both community votes and an AI oracle.
2.  **Dynamic Soulbound NFTs (Creative Proofs):** Successful submitters earn non-transferable ERC721 NFTs. These NFTs, called "Creative Proofs," dynamically update their metadata (e.g., visual traits, level) based on the user's overall creative reputation and the quality/AI score of their contributions. They are "soulbound" to represent a user's on-chain creative identity and achievements.
3.  **Reputation-Based Voting & Rewards:** Users with a minimum reputation score can vote on submissions. Votes are weighted by reputation. Successful challenges distribute the bounty and award reputation points.
4.  **Adaptive Platform Parameters (Self-Evolving):** A subset of platform parameters (e.g., voting period, submission period) can be proposed for change by reputable users. Community voting determines if these changes are enacted, allowing the platform to adapt over time.
5.  **Decentralized Content Curation:** The community actively participates in evaluating and rewarding creative output.

---

### Function Summary

**A. Admin & Platform Management (5 Functions)**

1.  `constructor()`: Initializes the contract with an owner, AI oracle address, and initial parameters.
2.  `updateAIOracleAddress(address _newAIOracle)`: Allows the owner to update the trusted AI oracle address.
3.  `setMinBountyAmount(uint256 _newMinAmount)`: Sets the minimum ETH required for a challenge bounty.
4.  `withdrawPlatformFees()`: Allows the owner to withdraw accumulated platform fees.
5.  `pauseContract()`: Pauses core contract functionalities in case of emergencies.
6.  `unpauseContract()`: Unpauses the contract.

**B. Challenge Management (4 Functions)**

7.  `proposeChallenge(string calldata _description, string calldata _aiPrompt, uint256 _submissionPeriod, uint256 _votingPeriod, bytes32[] calldata _requiredSkillTags)`: Creates a new creative challenge. Requires a bounty and platform fee.
8.  `cancelChallenge(uint256 _challengeId)`: Allows the proposer to cancel an open challenge if no submissions have been made.
9.  `submitToChallenge(uint256 _challengeId, string calldata _contentHash, string calldata _metadataURI)`: Allows users to submit their creative work (referenced by IPFS hash) to an active challenge.
10. `closeChallengeAndDistributeRewards(uint256 _challengeId)`: Finalizes a challenge, determines the winner based on votes and AI evaluation, distributes the bounty, updates reputation, and mints Creative Proof NFTs.

**C. Submission & Voting (2 Functions)**

11. `voteOnSubmission(uint256 _challengeId, uint256 _submissionId, uint8 _score)`: Allows reputable users to cast a score (1-5) on a submission. Voting power is weighted by reputation.
12. `registerAIEvaluation(uint256 _challengeId, uint256 _submissionId, uint8 _aiScore, string calldata _aiFeedbackHash)`: Callable only by the designated AI oracle to submit an AI-generated score and feedback for a submission.

**D. Dynamic NFT & Reputation (4 Functions)**

13. `getUserReputation(address _user)`: Returns the creative reputation score for a given user.
14. `claimSkillTag(bytes32 _skillTag)`: Allows users to declare specific creative skill tags for their profile.
15. `mintCreativeProofNFT(address _to, uint256 _challengeId, uint256 _submissionId)`: *Internal function* called upon successful challenge completion to mint a Soulbound NFT.
16. `updateCreativeProofTrait(uint256 _tokenId, bytes32 _newTraitData)`: *Internal function* to update an NFT's on-chain trait data, causing its metadata to evolve.

**E. Information Retrieval (5 Functions)**

17. `getChallengeDetails(uint256 _challengeId)`: Retrieves all details for a specific challenge.
18. `getSubmissionDetails(uint256 _challengeId, uint256 _submissionId)`: Retrieves details for a specific submission.
19. `getUserCreativeProofs(address _user)`: Returns an array of `tokenId`s for Creative Proofs owned by a user.
20. `tokenURI(uint256 _tokenId)`: ERC721 standard function, returns a dynamically generated URI for the NFT metadata, reflecting its current level and traits.

**F. Parameter Adaption (Self-Evolving) (3 Functions)**

21. `proposeParameterChange(string calldata _paramName, uint256 _newValue, uint256 _voteDuration)`: Allows reputable users to propose changes to platform parameters (e.g., `minReputationToVote`, `platformFeePercentage`).
22. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Allows reputable users to vote on an active parameter change proposal.
23. `executeParameterChange(uint256 _proposalId)`: Executes a parameter change if the proposal passes and the voting period has ended.

---

### ERC721 Standard Functions (Not counted in the 20+ "advanced" functions, but essential)

*   `balanceOf(address owner)`
*   `ownerOf(uint256 tokenId)`
*   `approve(address to, uint256 tokenId)`
*   `getApproved(uint256 tokenId)`
*   `setApprovalForAll(address operator, bool approved)`
*   `isApprovedForAll(address owner, address operator)`
*   `transferFrom(address from, address to, uint256 tokenId)`: *Overridden to revert for Soulbound functionality.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Contract: AetherForge
// Description: A decentralized platform for AI-augmented creative challenges,
//              featuring dynamic Soulbound NFTs and a reputation-based
//              governance system for parameter adaptation.

// --- Outline & Function Summary ---
//
// Core Concepts:
// 1. AI-Augmented Creative Challenges: Users propose challenges with ETH bounties. Submissions are judged by community votes and an AI oracle.
// 2. Dynamic Soulbound NFTs (Creative Proofs): Successful submitters earn non-transferable ERC721 NFTs that evolve with reputation and achievements.
// 3. Reputation-Based Voting & Rewards: Users with sufficient reputation can vote on submissions, with weighted voting power.
// 4. Adaptive Platform Parameters (Self-Evolving): Reputable users can propose and vote on changes to platform parameters.
// 5. Decentralized Content Curation: Community-driven evaluation and rewarding of creative output.
//
// Function Categories:
// A. Admin & Platform Management (5 Functions + 2 Pausable + 1 Ownable)
//    - constructor(): Initializes contract.
//    - updateAIOracleAddress(): Updates AI oracle address.
//    - setMinBountyAmount(): Sets minimum challenge bounty.
//    - withdrawPlatformFees(): Owner withdraws fees.
//    - pauseContract(): Pauses core functionalities.
//    - unpauseContract(): Unpauses functionalities.
//    - transferOwnership(): OpenZeppelin Ownable.
//
// B. Challenge Management (4 Functions)
//    - proposeChallenge(): Creates a new creative challenge.
//    - cancelChallenge(): Cancels an open challenge.
//    - submitToChallenge(): Submits work to a challenge.
//    - closeChallengeAndDistributeRewards(): Finalizes challenge, distributes rewards, mints NFTs.
//
// C. Submission & Voting (2 Functions)
//    - voteOnSubmission(): Casts a reputation-weighted vote on a submission.
//    - registerAIEvaluation(): AI oracle submits evaluation.
//
// D. Dynamic NFT & Reputation (4 Functions)
//    - getUserReputation(): Retrieves user's reputation score.
//    - claimSkillTag(): Users declare skills.
//    - mintCreativeProofNFT(): (Internal) Mints a Soulbound NFT.
//    - updateCreativeProofTrait(): (Internal) Updates NFT's on-chain trait data.
//
// E. Information Retrieval (5 Functions)
//    - getChallengeDetails(): Retrieves challenge details.
//    - getSubmissionDetails(): Retrieves submission details.
//    - getUserCreativeProofs(): Gets NFTs owned by a user.
//    - tokenURI(): ERC721 dynamic metadata URI.
//    - getAllSkillTags(): Retrieves all unique skill tags.
//
// F. Parameter Adaption (Self-Evolving) (3 Functions)
//    - proposeParameterChange(): Proposes a platform parameter change.
//    - voteOnParameterChange(): Votes on a parameter change proposal.
//    - executeParameterChange(): Executes a passed parameter change proposal.
//
// ERC721 Standard Functions (Overridden/Included for compliance):
//    - balanceOf(), ownerOf(), approve(), getApproved(), setApprovalForAll(), isApprovedForAll()
//    - transferFrom(): OVERRIDDEN to revert for Soulbound NFT functionality.
//
// --- End Summary ---

contract AetherForge is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _challengeIds;
    Counters.Counter private _submissionIds;
    Counters.Counter private _nftTokenIds;
    Counters.Counter private _proposalIds;

    address public aiOracleAddress;
    uint256 public platformFeePercentage; // e.g., 500 for 5% (500 / 10000)
    uint256 public minBountyAmount; // Minimum ETH required for a challenge bounty
    uint256 public minReputationToVote; // Minimum reputation score required to vote
    uint256 public minReputationToProposeParamChange; // Minimum reputation to propose param change
    uint256 public defaultVotingPeriod; // Default duration for voting phase in seconds
    uint256 public defaultSubmissionPeriod; // Default duration for submission phase in seconds
    uint256 public defaultProposalVoteDuration; // Default duration for parameter change proposals

    // Structs
    enum ChallengeState {
        Open,
        Submitting,
        Voting,
        Completed,
        Cancelled
    }

    struct Challenge {
        uint256 id;
        address proposer;
        string description;
        string aiPrompt; // AI prompt for creative generation (optional)
        uint256 bountyAmount;
        uint256 platformFee;
        uint256 submissionDeadline;
        uint256 votingDeadline;
        ChallengeState state;
        uint256 winningSubmissionId;
        uint256 totalSubmissions;
        bytes32[] requiredSkillTags;
        mapping(uint256 => Submission) submissions; // Nested mapping for submissions
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this challenge
    }

    struct Submission {
        uint256 id;
        uint256 challengeId;
        address submitter;
        string contentHash; // IPFS hash of the creative work
        string metadataURI; // Additional metadata URI for the submission (e.g., AI logs, process)
        int256 totalCommunityScore; // Sum of weighted votes (can be negative if scores are negative)
        uint256 totalCommunityVoters; // Number of unique voters
        uint8 aiEvaluationScore; // Score from AI oracle (0-100)
        string aiFeedbackHash; // IPFS hash of AI feedback
        bool aiEvaluated;
    }

    struct CreativeProof {
        uint256 tokenId;
        uint256 challengeId; // The challenge it was earned from
        uint256 submissionId; // The submission it represents
        uint256 level; // Represents the quality/success, affects dynamic traits
        bytes32 traitData; // On-chain trait data that can evolve (e.g., hash of aesthetic properties)
    }

    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        string paramName; // Name of the parameter to change (e.g., "platformFeePercentage")
        uint256 newValue; // The new value for the parameter
        uint256 voteDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    // Mappings
    mapping(uint256 => Challenge) public challenges;
    mapping(address => uint256) public userReputation; // Creative reputation score for users
    mapping(address => uint256[]) public userCreativeProofs; // Map user to array of owned NFT tokenIds
    mapping(uint256 => CreativeProof) public creativeProofs; // Map tokenId to CreativeProof details
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(bytes32 => bool) public availableSkillTags; // A global list of skill tags
    mapping(address => mapping(bytes32 => bool)) public userSkillTags; // Tracks skills claimed by users

    // --- Events ---
    event AIOracleUpdated(address indexed newAIOracle);
    event PlatformFeeUpdated(uint256 newFee);
    event MinBountyAmountUpdated(uint256 newMinAmount);
    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, uint256 bounty, uint256 submissionDeadline, uint256 votingDeadline);
    event ChallengeCancelled(uint256 indexed challengeId, address indexed by);
    event SubmissionMade(uint256 indexed challengeId, uint256 indexed submissionId, address indexed submitter, string contentHash);
    event VoteCast(uint256 indexed challengeId, uint256 indexed submissionId, address indexed voter, uint8 score, uint256 reputationWeight);
    event AIEvaluationRegistered(uint256 indexed challengeId, uint256 indexed submissionId, uint8 aiScore, string aiFeedbackHash);
    event ChallengeCompleted(uint256 indexed challengeId, uint256 indexed winningSubmissionId, address indexed winner, uint256 bountyDistributed, uint256 platformFee);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event CreativeProofMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed challengeId, uint256 submissionId);
    event CreativeProofTraitUpdated(uint256 indexed tokenId, bytes32 newTraitData);
    event SkillTagClaimed(address indexed user, bytes32 skillTag);
    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue, uint256 voteDeadline);
    event ParameterVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event DefaultVotingPeriodUpdated(uint256 newPeriod);
    event DefaultSubmissionPeriodUpdated(uint256 newPeriod);
    event DefaultProposalVoteDurationUpdated(uint256 newPeriod);
    event MinReputationToVoteUpdated(uint256 newMinReputation);
    event MinReputationToProposeParamChangeUpdated(uint256 newMinReputation);


    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AF: Not AI Oracle");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= _challengeIds.current(), "AF: Challenge does not exist");
        _;
    }

    modifier submissionExists(uint256 _challengeId, uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= challenges[_challengeId].totalSubmissions, "AF: Submission does not exist");
        _;
    }

    modifier hasMinReputation(uint256 _minRep) {
        require(userReputation[msg.sender] >= _minRep, "AF: Insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(
        address _aiOracleAddress,
        uint256 _platformFeePercentage,
        uint256 _minBountyAmount,
        uint256 _minReputationToVote,
        uint256 _minReputationToProposeParamChange,
        uint256 _defaultSubmissionPeriod,
        uint256 _defaultVotingPeriod,
        uint256 _defaultProposalVoteDuration
    ) ERC721("CreativeProof", "CP") Ownable(msg.sender) Pausable(false) {
        require(_aiOracleAddress != address(0), "AF: AI oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;
        platformFeePercentage = _platformFeePercentage;
        minBountyAmount = _minBountyAmount;
        minReputationToVote = _minReputationToVote;
        minReputationToProposeParamChange = _minReputationToProposeParamChange;
        defaultSubmissionPeriod = _defaultSubmissionPeriod;
        defaultVotingPeriod = _defaultVotingPeriod;
        defaultProposalVoteDuration = _defaultProposalVoteDuration;

        // Initialize some default skill tags
        availableSkillTags["design"] = true;
        availableSkillTags["writing"] = true;
        availableSkillTags["coding"] = true;
        availableSkillTags["art"] = true;
    }

    // --- A. Admin & Platform Management (5 Functions + Pausable/Ownable) ---

    function updateAIOracleAddress(address _newAIOracle) external onlyOwner {
        require(_newAIOracle != address(0), "AF: New AI oracle address cannot be zero");
        aiOracleAddress = _newAIOracle;
        emit AIOracleUpdated(_newAIOracle);
    }

    function setPlatformFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee <= 10000, "AF: Fee percentage cannot exceed 100%");
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    function setMinBountyAmount(uint256 _newMinAmount) external onlyOwner {
        minBountyAmount = _newMinAmount;
        emit MinBountyAmountUpdated(_newMinAmount);
    }

    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        // Exclude outstanding bounties from withdrawable fees (simple approximation: bounty amounts are assumed to be separate from fees)
        // For a more robust system, a dedicated fee balance tracking would be necessary.
        uint256 totalFees = 0;
        for (uint256 i = 1; i <= _challengeIds.current(); i++) {
            totalFees += challenges[i].platformFee;
        }

        // Only allow withdrawing what's genuinely platform fees, not user bounties.
        // This is a simplified approach. In a real system, you'd track fee vs bounty
        // separately or design withdrawal to only touch specific accounts.
        require(balance >= totalFees, "AF: Not enough balance to cover calculated fees");
        
        // This attempts to withdraw the calculated total fees.
        // If the contract holds more (e.g., unused bounties from cancelled challenges without refunds),
        // those remain. A real system would have explicit refund mechanisms.
        (bool success, ) = payable(owner()).call{value: totalFees}("");
        require(success, "AF: Fee withdrawal failed");
    }

    function setDefaultVotingPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "AF: Period must be positive");
        defaultVotingPeriod = _newPeriod;
        emit DefaultVotingPeriodUpdated(_newPeriod);
    }

    function setDefaultSubmissionPeriod(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "AF: Period must be positive");
        defaultSubmissionPeriod = _newPeriod;
        emit DefaultSubmissionPeriodUpdated(_newPeriod);
    }

    function setDefaultProposalVoteDuration(uint256 _newPeriod) external onlyOwner {
        require(_newPeriod > 0, "AF: Period must be positive");
        defaultProposalVoteDuration = _newPeriod;
        emit DefaultProposalVoteDurationUpdated(_newPeriod);
    }

    function setMinReputationToVote(uint256 _newMinReputation) external onlyOwner {
        minReputationToVote = _newMinReputation;
        emit MinReputationToVoteUpdated(_newMinReputation);
    }

    function setMinReputationToProposeParamChange(uint256 _newMinReputation) external onlyOwner {
        minReputationToProposeParamChange = _newMinReputation;
        emit MinReputationToProposeParamChangeUpdated(_newMinReputation);
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }


    // --- B. Challenge Management (4 Functions) ---

    function proposeChallenge(
        string calldata _description,
        string calldata _aiPrompt,
        uint256 _submissionPeriod, // in seconds
        uint256 _votingPeriod,     // in seconds
        bytes32[] calldata _requiredSkillTags // Optional skill tags
    ) external payable whenNotPaused returns (uint256) {
        require(msg.value >= minBountyAmount, "AF: Insufficient bounty amount");
        require(_submissionPeriod > 0, "AF: Submission period must be positive");
        require(_votingPeriod > 0, "AF: Voting period must be positive");

        uint256 bounty = msg.value;
        uint256 fee = (bounty * platformFeePercentage) / 10000;
        uint256 netBounty = bounty - fee;

        _challengeIds.increment();
        uint256 newId = _challengeIds.current();

        challenges[newId].id = newId;
        challenges[newId].proposer = msg.sender;
        challenges[newId].description = _description;
        challenges[newId].aiPrompt = _aiPrompt;
        challenges[newId].bountyAmount = netBounty; // Store net bounty after fee
        challenges[newId].platformFee = fee;
        challenges[newId].submissionDeadline = block.timestamp + _submissionPeriod;
        challenges[newId].votingDeadline = challenges[newId].submissionDeadline + _votingPeriod;
        challenges[newId].state = ChallengeState.Open; // Starts in 'Open' or 'Submitting'
        challenges[newId].requiredSkillTags = _requiredSkillTags;

        emit ChallengeProposed(
            newId,
            msg.sender,
            netBounty,
            challenges[newId].submissionDeadline,
            challenges[newId].votingDeadline
        );

        return newId;
    }

    function cancelChallenge(uint256 _challengeId) external whenNotPaused challengeExists(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];
        require(msg.sender == challenge.proposer, "AF: Only proposer can cancel");
        require(challenge.state == ChallengeState.Open || challenge.state == ChallengeState.Submitting, "AF: Challenge can only be cancelled in open/submitting phase");
        require(challenge.totalSubmissions == 0, "AF: Cannot cancel challenge with submissions");

        challenge.state = ChallengeState.Cancelled;

        // Refund the proposer
        (bool success, ) = payable(msg.sender).call{value: challenge.bountyAmount + challenge.platformFee}("");
        require(success, "AF: Bounty refund failed");

        emit ChallengeCancelled(_challengeId, msg.sender);
    }

    function submitToChallenge(
        uint256 _challengeId,
        string calldata _contentHash, // IPFS hash of the creative work
        string calldata _metadataURI // Optional URI for AI logs or detailed process
    ) external whenNotPaused challengeExists(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];
        require(block.timestamp <= challenge.submissionDeadline, "AF: Submission period has ended");
        require(challenge.state == ChallengeState.Open || challenge.state == ChallengeState.Submitting, "AF: Challenge not in submission phase");

        // Transition state if it's the first submission and still 'Open'
        if (challenge.state == ChallengeState.Open) {
            challenge.state = ChallengeState.Submitting;
        }

        _submissionIds.increment();
        uint256 newSubmissionId = _submissionIds.current();
        challenge.totalSubmissions++;

        challenge.submissions[newSubmissionId].id = newSubmissionId;
        challenge.submissions[newSubmissionId].challengeId = _challengeId;
        challenge.submissions[newSubmissionId].submitter = msg.sender;
        challenge.submissions[newSubmissionId].contentHash = _contentHash;
        challenge.submissions[newSubmissionId].metadataURI