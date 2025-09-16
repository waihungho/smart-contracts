This smart contract, `CognitoNexus`, represents a "Sentient Collective Autonomous Entity" (SCAE) where a decentralized community governs the evolution of AI-generated content and creative direction. It blends advanced concepts like dynamic NFTs influenced by AI feedback, a decentralized "Inspiration Pool" to fund AI tasks, community-driven content curation, and Soulbound Tokens for recognizing key contributors, all underpinned by a robust governance system.

The core idea is to create a platform where a collective consciousness (the DAO) guides an artificial intelligence in creative endeavors, with the output becoming dynamic, community-curated, and collectible NFTs.

---

### **CognitoNexus: Decentralized AI-Driven Creative & Governance Platform**

**Description:** `CognitoNexus` is designed as a decentralized collective intelligence, enabling a community to govern, fund, and curate AI-generated creative works. It integrates advanced DAO functionalities, AI oracle interaction, dynamic NFTs that evolve with community input, and non-transferable Soulbound Tokens for contributor recognition. The platform aims to explore novel synergies between decentralized governance and artificial intelligence in fostering a new era of digital creativity.

**Key Features:**

*   **Advanced DAO Governance:** Comprehensive proposal, voting (with delegation), and execution system for protocol upgrades and creative direction.
*   **AI Oracle Integration:** A dedicated channel for a trusted AI agent to submit verifiable proofs of AI-generated content based on community prompts.
*   **Inspiration Pool:** A community-funded pool of `SCAE` tokens to incentivize AI creative tasks and reward successful submissions.
*   **Decentralized Content Curation:** A mechanism for community members to review and approve AI-generated content, determining which creations proceed to NFT minting.
*   **Dynamic Cognito NFTs:** NFTs (`ERC-721`) whose metadata can be updated by the DAO, allowing them to evolve based on new AI input or community interaction, with an option to "freeze" their state.
*   **Soulbound Contributor Recognition:** Non-transferable digital badges (SBT-like) to acknowledge and reward significant community contributors.
*   **SCAE Token Staking:** Mechanism for users to stake governance tokens (`SCAE`) to gain voting power and earn rewards, fostering active participation.

---

### **Outline and Function Summary:**

**I. Core & Administration**
1.  `constructor()`: Initializes the contract, sets initial owner, core token, AI oracle, and governance parameters.
2.  `setSCAETokenAddress(address _tokenAddress)`: Sets the address of the SCAE governance token (Owner-only).
3.  `setAIOracleAddress(address _oracleAddress)`: Sets the trusted AI oracle address for submitting AI proofs (Owner-only).
4.  `pause()`: Pauses contract operations in emergencies (Owner-only).
5.  `unpause()`: Unpauses contract operations (Owner-only).
6.  `transferOwnership(address newOwner)`: Transfers contract ownership (Inherited from Ownable).

**II. Governance & DAO (Advanced Proposal System)**
7.  `submitProposal(string memory _description, bytes memory _calldata, address _target, uint256 _value)`: Allows stakers meeting the `proposalThreshold` to submit new governance proposals for voting.
8.  `voteOnProposal(uint256 _proposalId, bool _support)`: Enables `SCAE` token holders with sufficient stake to vote 'for' or 'against' an active proposal.
9.  `delegateVote(address _delegatee)`: Delegates a staker's voting power to another address.
10. `revokeDelegation()`: Revokes any active voting delegation, returning power to the delegator.
11. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed the voting period and quorum requirements.
12. `getProposalState(uint256 _proposalId)`: Returns the current state of a specific proposal (e.g., Pending, Active, Passed, Failed, Executed).

**III. AI Interaction & Creative Pool (Decentralized AI Prompting & Curation)**
13. `depositToInspirationPool(uint256 _amount)`: Allows users to deposit `SCAE` tokens to fund AI-driven creative tasks and rewards.
14. `requestAIPromptGeneration(string memory _theme, uint256 _rewardAmount)`: Proposes a new AI creative task (e.g., "generate sci-fi concept art"), which itself requires governance approval for funding.
15. `submitAIGeneratedContentProof(uint256 _promptId, string memory _contentHash, string memory _metadataURI)`: The designated `aiOracle` submits verifiable proof (e.g., IPFS hash) of AI-generated content based on an approved prompt.
16. `curateAICreation(uint256 _promptId, uint256 _creationIndex, bool _approve)`: Community members (stakers) vote to approve or reject submitted AI content, with approved content becoming eligible for NFT minting.
17. `getAIRequestStatus(uint256 _promptId)`: Checks the current state of an AI prompt generation request.

**IV. Dynamic Cognito NFTs (AI-Influenced Digital Art)**
18. `mintCognitoNFT(uint256 _promptId, uint256 _creationIndex, address _recipient)`: Mints a new `Cognito` NFT (ERC-721) based on an approved and curated AI creation.
19. `updateCognitoNFTMetadata(uint256 _tokenId, string memory _newURI)`: Allows the DAO (via `onlyOwner` or governance) to update the metadata of a `Cognito` NFT, enabling dynamic attributes.
20. `freezeCognitoNFTState(uint256 _tokenId)`: Permanently locks the metadata of a `Cognito` NFT, making it immutable.
21. `burnCognitoNFT(uint256 _tokenId)`: Allows an NFT owner to permanently remove their `Cognito` NFT from circulation.

**V. Contributor Recognition (Soulbound-like Credentials)**
22. `awardContributorSBT(address _contributor, string memory _badgeURI)`: The DAO (via `onlyOwner` or governance) awards a non-transferable "Soulbound Token" (SBT-like credential) to a significant contributor.
23. `updateContributorSBT(address _contributor, string memory _newBadgeURI)`: Updates the badge URI or status of an existing contributor SBT.
24. `checkContributorSBT(address _contributor)`: Checks if an address holds a contributor SBT and returns its associated URI.

**VI. Staking & Rewards**
25. `stakeSCAETokens(uint256 _amount)`: Stakes `SCAE` tokens to gain voting power and become eligible for rewards.
26. `unstakeSCAETokens(uint256 _amount)`: Initiates the unstaking process; tokens become claimable after a `stakingLockupPeriod`.
27. `claimRewards()`: Allows stakers to claim accumulated `SCAE` rewards and any unstaked tokens after their lockup period.

**VII. View & Utility Functions**
28. `getTotalStaked(address _staker)`: Returns the total `SCAE` tokens currently staked by a specific address.
29. `getVotingPower(address _voter)`: Returns the effective voting power of an address, considering any active delegation.
30. `getNFTMetadataURI(uint256 _tokenId)`: Returns the current metadata URI for a `Cognito` NFT.
31. `getInspirationPoolBalance()`: Returns the current total balance of `SCAE` tokens in the Inspiration Pool.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion

/**
 * @title CognitoNexus
 * @author YourName (placeholder)
 * @notice A Decentralized AI-Driven Creative & Governance Platform.
 *
 * @dev CognitoNexus represents a "Sentient Collective Autonomous Entity" (SCAE) where the community
 *      governs an evolving pool of AI-generated content and creative direction. It integrates
 *      advanced concepts like dynamic NFTs influenced by AI feedback, a decentralized
 *      "Inspiration Pool" to fund AI tasks, community curation mechanisms, and Soulbound
 *      Tokens for recognizing key contributors. The platform aims to explore the synergy
 *      between decentralized governance and artificial intelligence in creative endeavors.
 */

// --- OUTLINE AND FUNCTION SUMMARY ---

// I. Core & Administration
//    1.  constructor(): Initializes the contract, sets initial owner and core parameters.
//    2.  setSCAETokenAddress(address _tokenAddress): Sets the address of the SCAE governance token.
//    3.  setAIOracleAddress(address _oracleAddress): Sets the trusted AI oracle address for submitting AI proofs.
//    4.  pause(): Pauses contract operations in emergencies (Owner-only).
//    5.  unpause(): Unpauses contract operations (Owner-only).
//    6.  transferOwnership(address newOwner): Transfers contract ownership.

// II. Governance & DAO (Advanced Proposal System)
//    7.  submitProposal(string memory _description, bytes memory _calldata, address _target, uint256 _value): Submits a new governance proposal requiring SCAE token stake.
//    8.  voteOnProposal(uint256 _proposalId, bool _support): Allows SCAE token holders to vote on a proposal.
//    9.  delegateVote(address _delegatee): Delegates voting power to another address.
//    10. revokeDelegation(): Revokes any active voting delegation.
//    11. executeProposal(uint256 _proposalId): Executes a passed proposal.
//    12. getProposalState(uint256 _proposalId): Returns the current state of a specific proposal.

// III. AI Interaction & Creative Pool (Decentralized AI Prompting & Curation)
//    13. depositToInspirationPool(uint256 _amount): Users deposit SCAE tokens to fund AI-driven creative tasks.
//    14. requestAIPromptGeneration(string memory _theme, uint256 _rewardAmount): Proposes a new AI creative prompt, funded from the Inspiration Pool.
//    15. submitAIGeneratedContentProof(uint256 _promptId, string memory _contentHash, string memory _metadataURI): AI Oracle submits verifiable proof of AI-generated content.
//    16. curateAICreation(uint256 _promptId, uint256 _creationIndex, bool _approve): Community votes to approve or reject submitted AI content.
//    17. getAIRequestStatus(uint256 _promptId): Checks the status of an AI prompt generation request.

// IV. Dynamic Cognito NFTs (AI-Influenced Digital Art)
//    18. mintCognitoNFT(uint256 _promptId, uint256 _creationIndex, address _recipient): Mints a new Cognito NFT based on an approved AI creation.
//    19. updateCognitoNFTMetadata(uint256 _tokenId, string memory _newURI): Allows DAO or designated roles to update dynamic NFT metadata.
//    20. freezeCognitoNFTState(uint256 _tokenId): Freezes the metadata of a Cognito NFT, making it immutable.
//    21. burnCognitoNFT(uint256 _tokenId): Allows an NFT owner to burn their Cognito NFT.

// V. Contributor Recognition (Soulbound-like Credentials)
//    22. awardContributorSBT(address _contributor, string memory _badgeURI): DAO awards a non-transferable Soulbound Token (SBT) for significant contributions.
//    23. updateContributorSBT(address _contributor, string memory _newBadgeURI): Updates the URI/status of an existing contributor SBT.
//    24. checkContributorSBT(address _contributor): Checks if an address holds a contributor SBT.

// VI. Staking & Rewards
//    25. stakeSCAETokens(uint256 _amount): Stakes SCAE tokens for governance participation and rewards.
//    26. unstakeSCAETokens(uint256 _amount): Unstakes SCAE tokens after a lock-up period.
//    27. claimRewards(): Claims accumulated rewards from staking and participation.

// VII. View & Utility Functions
//    28. getTotalStaked(address _staker): Returns the total SCAE tokens staked by an address.
//    29. getVotingPower(address _voter): Returns the voting power of an address (including delegation).
//    30. getNFTMetadataURI(uint256 _tokenId): Returns the URI for a Cognito NFT.
//    31. getInspirationPoolBalance(): Returns the current balance of the Inspiration Pool.

contract CognitoNexus is Ownable, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Core Token & Oracle Addresses
    IERC20 public scaeToken; // The governance token for the platform
    address public aiOracle; // Address of the trusted AI oracle

    // Governance Parameters
    uint256 public proposalThreshold; // Minimum SCAE tokens (wei) required to submit a proposal
    uint256 public votingPeriod;      // Duration in blocks for which a proposal is active for voting
    uint256 public quorumPercentage;  // Percentage (0-100) of total staked tokens required for a proposal to pass

    // Staking Parameters
    uint256 public minStakeForVoting; // Minimum tokens (wei) required to vote on a proposal
    uint256 public stakingLockupPeriod; // Time in seconds tokens are locked after unstake request
    uint256 public rewardRatePerDay; // Base rate for calculating staking rewards, e.g., 100 for 1% per day for example purposes

    // Counters for unique IDs
    Counters.Counter private _proposalIds;
    Counters.Counter private _promptIds;
    Counters.Counter private _nftIds;

    // --- Mappings & Structs ---

    // Governance
    enum ProposalState { Pending, Active, Passed, Failed, Executed }
    struct Proposal {
        uint256 id;
        string description;
        bytes calldataPayload; // The function call to execute if proposal passes
        address target;        // The contract address to call
        uint256 value;         // ETH value to send with the call (if any)
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        address proposer;
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    mapping(address => address) public delegates; // delegator => delegatee
    mapping(address => uint256) public delegatedVotingPower; // Tracks effective votes for a delegatee (sum of delegated stakes)

    // AI & Creative Pool
    uint256 public inspirationPoolBalance; // Total SCAE tokens in the inspiration pool
    enum AIRequestState { Proposed, Active, ContentSubmitted, Curated, Completed, Rejected }
    struct AIRequest {
        uint256 id;
        string theme;
        uint256 rewardAmount; // SCAE tokens to be rewarded to AI oracle/curators
        address proposer;
        AIRequestState state;
        uint256 proposalId; // ID of the governance proposal that approved this AI request
        uint256 submissionDeadline; // Timestamp by which AI content should be submitted

        // For tracking AI content submissions for this prompt
        struct AICreation {
            string contentHash; // IPFS hash or similar for AI generated content proof
            string metadataURI; // Base URI for potential NFT metadata
            address submitter;  // The AI Oracle or designated agent
            bool isApproved;    // Whether community curation approved it
            bool isMinted;      // Whether an NFT has been minted from it
        }
        AICreation[] submittedCreations;
    }
    mapping(uint256 => AIRequest) public aiRequests;

    // Dynamic NFTs (CognitoNFTs)
    mapping(uint256 => bool) public isNFTMetadataFrozen; // tokenId => frozen status

    // Contributor Recognition (SBT-like)
    // For simplicity, we implement SBTs as non-transferable ERC721-like badges within this contract.
    // They are not actual ERC721 tokens but represent a unique URI for a contributor.
    mapping(address => string) public contributorSBTs; // contributor address => badge URI
    mapping(address => bool) public hasContributorSBT; // contributor address => true if they have an SBT

    // Staking
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 lastRewardClaimTime; // Timestamp of last reward claim
        // In a more complex system, could track lockup status for partial unstakes
    }
    mapping(address => StakerInfo) public stakerInfos;
    mapping(address => uint256) public pendingUnstakeAmount; // Amount requested to unstake, waiting for lockup
    mapping(address => uint256) public unstakeLockupEnd; // Timestamp when pendingUnstakeAmount becomes available

    uint256 public totalStakedTokens; // Track total staked tokens for quorum calculation

    // Events
    event SCAETokenAddressSet(address indexed _tokenAddress);
    event AIOracleAddressSet(address indexed _oracleAddress);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event DelegationChanged(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(uint256 indexed proposalId);
    event DepositToInspirationPool(address indexed depositor, uint256 amount);
    event AIPromptRequested(uint256 indexed promptId, address indexed proposer, string theme, uint256 rewardAmount);
    event AIPromptActivated(uint256 indexed promptId, uint256 submissionDeadline);
    event AIGeneratedContentProofSubmitted(uint252 indexed promptId, uint256 creationIndex, string contentHash, string metadataURI);
    event AICreationCurated(uint256 indexed promptId, uint256 creationIndex, address indexed curator, bool approved);
    event CognitoNFTMinted(uint256 indexed tokenId, uint256 indexed promptId, address indexed recipient, string tokenURI);
    event CognitoNFTMetadataUpdated(uint224 indexed tokenId, string newURI);
    event CognitoNFTFrozen(uint256 indexed tokenId);
    event ContributorSBT Awarded(address indexed contributor, string badgeURI);
    event ContributorSBTUpdated(address indexed contributor, string newBadgeURI);
    event TokensStaked(address indexed staker, uint256 amount);
    event UnstakeRequested(address indexed staker, uint256 amount, uint256 lockupEnd);
    event TokensUnstakedClaimed(address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed staker, uint256 amount);

    // --- Constructor ---

    constructor(
        address _scaeTokenAddress,
        address _aiOracleAddress,
        uint256 _proposalThreshold,
        uint256 _votingPeriod,
        uint256 _quorumPercentage,
        uint256 _minStakeForVoting,
        uint256 _stakingLockupPeriod,
        uint256 _rewardRatePerDay,
        string memory _name,
        string memory _symbol
    )
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        require(_scaeTokenAddress != address(0), "SCAE token address cannot be zero");
        require(_aiOracleAddress != address(0), "AI Oracle address cannot be zero");
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Quorum percentage must be between 1-100");
        require(_rewardRatePerDay > 0, "Reward rate must be greater than zero");

        scaeToken = IERC20(_scaeTokenAddress);
        aiOracle = _aiOracleAddress;
        proposalThreshold = _proposalThreshold;
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        minStakeForVoting = _minStakeForVoting;
        stakingLockupPeriod = _stakingLockupPeriod;
        rewardRatePerDay = _rewardRatePerDay;

        emit SCAETokenAddressSet(_scaeTokenAddress);
        emit AIOracleAddressSet(_aiOracleAddress);
    }

    // --- I. Core & Administration ---

    /**
     * @notice Sets the address of the SCAE governance token.
     * @dev Can only be called by the contract owner.
     * @param _tokenAddress The new address for the SCAE token.
     */
    function setSCAETokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "SCAE token address cannot be zero");
        scaeToken = IERC20(_tokenAddress);
        emit SCAETokenAddressSet(_tokenAddress);
    }

    /**
     * @notice Sets the trusted AI oracle address.
     * @dev Only the owner can set this. This oracle is responsible for submitting verifiable AI content proofs.
     * @param _oracleAddress The new address for the AI oracle.
     */
    function setAIOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "AI Oracle address cannot be zero");
        aiOracle = _oracleAddress;
        emit AIOracleAddressSet(_oracleAddress);
    }

    /**
     * @notice Pauses contract operations in case of an emergency.
     * @dev Only the owner can call this. Certain critical functions will be blocked.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract operations after an emergency.
     * @dev Only the owner can call this.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // `transferOwnership` is inherited from Ownable, serves as function 6.

    // --- II. Governance & DAO (Advanced Proposal System) ---

    /**
     * @notice Submits a new governance proposal for community voting.
     * @dev Requires the proposer to have at least `proposalThreshold` SCAE tokens staked.
     *      The proposal's target and calldata allow for arbitrary contract interactions.
     * @param _description A brief description of the proposal.
     * @param _calldata The ABI-encoded function call to execute if the proposal passes.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _value The amount of ETH (in wei) to send with the call (if target is payable).
     * @return proposalId The ID of the newly created proposal.
     */
    function submitProposal(
        string memory _description,
        bytes memory _calldata,
        address _target,
        uint256 _value
    ) public whenNotPaused returns (uint256) {
        require(stakerInfos[msg.sender].stakedAmount >= proposalThreshold, "Proposer must meet threshold stake");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            calldataPayload: _calldata,
            target: _target,
            value: _value,
            startBlock: block.number,
            endBlock: block.number + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            proposer: msg.sender,
            state: ProposalState.Active, // Set to active immediately upon submission
            executed: false
        });

        emit ProposalSubmitted(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @notice Allows SCAE token holders to vote on a proposal.
     * @dev Voters must have at least `minStakeForVoting` tokens (either directly staked or delegated to them).
     *      A voter can only vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active for voting");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Voting period has ended or not started");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower >= minStakeForVoting, "Insufficient voting power to vote");

        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        hasVoted[_proposalId][msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @notice Delegates voting power to another address.
     * @dev All currently staked tokens of the delegator will contribute to the delegatee's voting power.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");

        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee != address(0)) {
            delegatedVotingPower[currentDelegatee] -= stakerInfos[msg.sender].stakedAmount;
        }

        delegates[msg.sender] = _delegatee;
        delegatedVotingPower[_delegatee] += stakerInfos[msg.sender].stakedAmount;

        emit DelegationChanged(msg.sender, _delegatee);
    }

    /**
     * @notice Revokes any active voting delegation, returning voting power to the delegator.
     */
    function revokeDelegation() public whenNotPaused {
        address currentDelegatee = delegates[msg.sender];
        require(currentDelegatee != address(0), "No active delegation to revoke");

        delegatedVotingPower[currentDelegatee] -= stakerInfos[msg.sender].stakedAmount;
        delete delegates[msg.sender];
        // Voting power automatically reverts to msg.sender via getVotingPower

        emit DelegationChanged(msg.sender, address(0)); // Signifies revocation
    }

    /**
     * @notice Executes a proposal that has passed the voting criteria.
     * @dev Can only be executed once, after the voting period, if quorum and majority are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public payable whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");

        // Ensure proposal state is updated before checking execution conditions
        _updateProposalState(_proposalId);

        require(proposal.state == ProposalState.Passed, "Proposal has not passed or is not in a passed state");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        // Execute the arbitrary call
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Returns the current state of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return The current state (Pending, Active, Passed, Failed, Executed).
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (block.number < proposal.startBlock) {
            return ProposalState.Pending; // Should ideally be Active from submitProposal
        }
        if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        }

        // Voting period has ended, determine final outcome
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = totalStakedTokens * quorumPercentage / 100; // Use totalStakedTokens for quorum

        if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
            return ProposalState.Passed;
        } else {
            return ProposalState.Failed;
        }
    }

    /**
     * @dev Internal helper to update a proposal's state after voting ends.
     */
    function _updateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (block.number > proposal.endBlock && proposal.state == ProposalState.Active) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 requiredQuorum = totalStakedTokens * quorumPercentage / 100;

            if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
                proposal.state = ProposalState.Passed;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }
    }

    // --- III. AI Interaction & Creative Pool (Decentralized AI Prompting & Curation) ---

    /**
     * @notice Allows users to deposit SCAE tokens into the Inspiration Pool.
     * @dev These tokens fund rewards for AI prompt generation and curation.
     * @param _amount The amount of SCAE tokens to deposit.
     */
    function depositToInspirationPool(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        scaeToken.transferFrom(msg.sender, address(this), _amount);
        inspirationPoolBalance += _amount;
        emit DepositToInspirationPool(msg.sender, _amount);
    }

    /**
     * @notice Proposes a new AI creative prompt, requiring governance approval.
     * @dev The `_rewardAmount` is allocated from the Inspiration Pool if the proposal passes.
     *      This creates a governance proposal internally to fund the AI task.
     * @param _theme The theme or topic for the AI to generate content on.
     * @param _rewardAmount The amount of SCAE tokens to reward the AI oracle/curators upon successful completion.
     * @return promptId The ID of the AI prompt request.
     */
    function requestAIPromptGeneration(string memory _theme, uint256 _rewardAmount) public whenNotPaused returns (uint256) {
        require(_rewardAmount > 0, "Reward amount must be greater than zero");
        require(stakerInfos[msg.sender].stakedAmount >= proposalThreshold, "Proposer must meet threshold stake to request AI prompt");

        _promptIds.increment();
        uint256 promptId = _promptIds.current();

        // Create the AI request in a "Proposed" state
        aiRequests[promptId] = AIRequest({
            id: promptId,
            theme: _theme,
            rewardAmount: _rewardAmount,
            proposer: msg.sender,
            state: AIRequestState.Proposed,
            proposalId: 0, // Placeholder, filled after actual governance proposal is submitted
            submissionDeadline: 0,
            submittedCreations: new AIRequest.AICreation[](0)
        });

        // The governance proposal calls `activateAIPrompt` if it passes
        bytes memory calldataPayload = abi.encodeWithSelector(
            this.activateAIPrompt.selector,
            promptId,
            _rewardAmount
        );

        uint256 proposalGId = submitProposal(
            string(abi.encodePacked("AI Prompt: ", _theme, " (Reward: ", Strings.toString(_rewardAmount), " SCAE)")),
            calldataPayload,
            address(this),
            0 // No ETH required for this internal call
        );
        aiRequests[promptId].proposalId = proposalGId; // Link AI request to governance proposal

        emit AIPromptRequested(promptId, msg.sender, _theme, _rewardAmount);
        return promptId;
    }

    /**
     * @dev Internal function called by a passed governance proposal to activate an AI prompt.
     * @param _promptId The ID of the AI prompt to activate.
     * @param _rewardAmount The reward amount confirmed by governance.
     */
    function activateAIPrompt(uint256 _promptId, uint256 _rewardAmount) public {
        // This function should ONLY be called by the contract itself via a successful governance proposal execution.
        // `msg.sender == address(this)` check ensures this.
        require(msg.sender == address(this), "Only callable by contract itself (via proposal execution)");

        AIRequest storage req = aiRequests[_promptId];
        require(req.state == AIRequestState.Proposed, "AI request not in Proposed state");
        require(req.rewardAmount == _rewardAmount, "Reward amount mismatch from proposal");
        require(inspirationPoolBalance >= _rewardAmount, "Insufficient funds in Inspiration Pool");

        req.state = AIRequestState.Active;
        req.submissionDeadline = block.timestamp + 2 days; // Example deadline: 2 days
        // inspirationPoolBalance -= _rewardAmount; // Reward is allocated, not deducted yet. Deducted on successful curation.

        emit AIPromptActivated(_promptId, req.submissionDeadline);
    }

    /**
     * @notice AI Oracle submits verifiable proof of AI-generated content based on an active prompt.
     * @dev Only the designated `aiOracle` address can call this.
     *      `_contentHash` should be a verifiable hash (e.g., IPFS CID) of the generated content.
     *      `_metadataURI` provides the initial metadata for a potential NFT.
     * @param _promptId The ID of the AI prompt for which content was generated.
     * @param _contentHash The hash/CID of the AI-generated content.
     * @param _metadataURI The URI for the NFT metadata (e.g., IPFS link to JSON).
     */
    function submitAIGeneratedContentProof(
        uint256 _promptId,
        string memory _contentHash,
        string memory _metadataURI
    ) public whenNotPaused {
        require(msg.sender == aiOracle, "Only AI Oracle can submit content proof");
        AIRequest storage req = aiRequests[_promptId];
        require(req.state == AIRequestState.Active, "AI request is not active for submissions");
        require(block.timestamp <= req.submissionDeadline, "Submission deadline passed");

        req.submittedCreations.push(AIRequest.AICreation({
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            submitter: msg.sender,
            isApproved: false,
            isMinted: false
        }));

        req.state = AIRequestState.ContentSubmitted; // Can go back to Active if more submissions are allowed

        emit AIGeneratedContentProofSubmitted(_promptId, req.submittedCreations.length - 1, _contentHash, _metadataURI);
    }

    /**
     * @notice Community members curate submitted AI creations by voting for approval.
     * @dev This could be a simple up/down vote, or a more complex weighted system.
     *      For simplicity, a 'yes' vote by any staker approves the content.
     *      In a real-world scenario, this might be another sub-proposal or a weighted voting system.
     *      Only callable by addresses with `minStakeForVoting`.
     * @param _promptId The ID of the AI prompt.
     * @param _creationIndex The index of the submitted creation in the `submittedCreations` array.
     * @param _approve True to approve the creation, false to reject.
     */
    function curateAICreation(uint256 _promptId, uint256 _creationIndex, bool _approve) public whenNotPaused {
        require(getVotingPower(msg.sender) >= minStakeForVoting, "Insufficient stake for curation");
        AIRequest storage req = aiRequests[_promptId];
        require(req.state == AIRequestState.ContentSubmitted, "AI request not in content submission phase");
        require(_creationIndex < req.submittedCreations.length, "Invalid creation index");
        require(!req.submittedCreations[_creationIndex].isApproved, "Creation already approved or rejected");

        if (_approve) {
            req.submittedCreations[_creationIndex].isApproved = true;
            req.state = AIRequestState.Curated; // Changes state once one creation is approved
            // Deduct reward from Inspiration Pool and send to AI Oracle (submitter)
            require(inspirationPoolBalance >= req.rewardAmount, "Inspiration Pool balance too low for reward.");
            inspirationPoolBalance -= req.rewardAmount;
            scaeToken.transfer(req.submittedCreations[_creationIndex].submitter, req.rewardAmount);
            emit RewardsClaimed(req.submittedCreations[_creationIndex].submitter, req.rewardAmount);
        } else {
            // More complex logic could allow multiple rejections before marking request as Rejected
            // For simplicity, a rejection here could be temporary or final depending on rules
            // Let's assume a single rejection doesn't finalize the prompt immediately.
            // A DAO could create a proposal to reject the entire prompt if no suitable content is found.
            // For now, only explicit approval changes state to Curated.
        }

        emit AICreationCurated(_promptId, _creationIndex, msg.sender, _approve);
    }

    /**
     * @notice Checks the current status of an AI prompt generation request.
     * @param _promptId The ID of the AI prompt.
     * @return The current state of the AI request.
     */
    function getAIRequestStatus(uint256 _promptId) public view returns (AIRequestState) {
        return aiRequests[_promptId].state;
    }

    // --- IV. Dynamic Cognito NFTs (AI-Influenced Digital Art) ---

    /**
     * @notice Mints a new Cognito NFT based on an approved AI creation.
     * @dev Only callable by the contract owner (or a governance proposal).
     *      Requires the AI creation to be approved via curation.
     * @param _promptId The ID of the AI prompt.
     * @param _creationIndex The index of the approved creation.
     * @param _recipient The address to mint the NFT to.
     */
    function mintCognitoNFT(uint256 _promptId, uint256 _creationIndex, address _recipient) public onlyOwner whenNotPaused {
        AIRequest storage req = aiRequests[_promptId];
        require(req.state == AIRequestState.Curated, "AI request not in Curated state"); // Or allow minting multiple from Curated state
        require(_creationIndex < req.submittedCreations.length, "Invalid creation index");
        require(req.submittedCreations[_creationIndex].isApproved, "Creation not approved for minting");
        require(!req.submittedCreations[_creationIndex].isMinted, "NFT already minted for this creation");

        _nftIds.increment();
        uint256 newId = _nftIds.current();

        _safeMint(_recipient, newId);
        _setTokenURI(newId, req.submittedCreations[_creationIndex].metadataURI);

        req.submittedCreations[_creationIndex].isMinted = true;
        // Optionally, update AIRequest state to Completed if all approved creations are minted.
        // For simplicity, let's just mark the creation as minted.

        emit CognitoNFTMinted(newId, _promptId, _recipient, req.submittedCreations[_creationIndex].metadataURI);
    }

    /**
     * @notice Allows DAO (via governance proposal) to update dynamic NFT metadata.
     * @dev This enables "dynamic" NFTs where attributes can change over time based on new AI input,
     *      community interaction, or other on-chain events.
     *      Cannot update if the NFT's metadata is frozen.
     * @param _tokenId The ID of the Cognito NFT.
     * @param _newURI The new URI for the NFT metadata.
     */
    function updateCognitoNFTMetadata(uint256 _tokenId, string memory _newURI) public onlyOwner whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(!isNFTMetadataFrozen[_tokenId], "NFT metadata is frozen and cannot be updated");
        _setTokenURI(_tokenId, _newURI);
        emit CognitoNFTMetadataUpdated(_tokenId, _newURI);
    }

    /**
     * @notice Freezes the metadata of a Cognito NFT, making it immutable.
     * @dev Once frozen, the `updateCognitoNFTMetadata` function can no longer change its URI.
     *      This could be for "finalizing" a piece of AI art.
     * @param _tokenId The ID of the Cognito NFT.
     */
    function freezeCognitoNFTState(uint256 _tokenId) public onlyOwner whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(!isNFTMetadataFrozen[_tokenId], "NFT metadata is already frozen");
        isNFTMetadataFrozen[_tokenId] = true;
        emit CognitoNFTFrozen(_tokenId);
    }

    /**
     * @notice Allows an NFT owner to burn their Cognito NFT.
     * @dev Burning the NFT permanently removes it from circulation.
     * @param _tokenId The ID of the Cognito NFT to burn.
     */
    function burnCognitoNFT(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        _burn(_tokenId);
    }

    // --- V. Contributor Recognition (Soulbound-like Credentials) ---

    /**
     * @notice DAO awards a non-transferable Soulbound Token (SBT) for significant contributions.
     * @dev This is not an actual ERC721 transfer but marks an address as a recognized contributor
     *      with an associated badge URI. These are non-transferable.
     * @param _contributor The address of the contributor.
     * @param _badgeURI The URI pointing to the badge/credential metadata.
     */
    function awardContributorSBT(address _contributor, string memory _badgeURI) public onlyOwner whenNotPaused {
        require(_contributor != address(0), "Contributor address cannot be zero");
        require(!hasContributorSBT[_contributor], "Contributor already has an SBT");

        contributorSBTs[_contributor] = _badgeURI;
        hasContributorSBT[_contributor] = true;
        emit ContributorSBT Awarded(_contributor, _badgeURI);
    }

    /**
     * @notice Updates the URI/status of an existing contributor SBT.
     * @dev Allows the DAO to upgrade or change a contributor's recognition badge.
     * @param _contributor The address of the contributor.
     * @param _newBadgeURI The new URI for the badge/credential metadata.
     */
    function updateContributorSBT(address _contributor, string memory _newBadgeURI) public onlyOwner whenNotPaused {
        require(hasContributorSBT[_contributor], "Contributor does not have an SBT to update");
        contributorSBTs[_contributor] = _newBadgeURI;
        emit ContributorSBTUpdated(_contributor, _newBadgeURI);
    }

    /**
     * @notice Checks if an address holds a contributor SBT and returns its URI.
     * @param _contributor The address to check.
     * @return The badge URI if an SBT exists, otherwise an empty string.
     */
    function checkContributorSBT(address _contributor) public view returns (string memory) {
        if (hasContributorSBT[_contributor]) {
            return contributorSBTs[_contributor];
        }
        return "";
    }

    // --- VI. Staking & Rewards ---

    /**
     * @notice Stakes SCAE tokens for governance participation and potential rewards.
     * @dev Tokens are locked for a defined period after unstake request.
     *      Staking increases voting power.
     * @param _amount The amount of SCAE tokens to stake.
     */
    function stakeSCAETokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        scaeToken.transferFrom(msg.sender, address(this), _amount);

        // Update total staked for quorum calculation
        totalStakedTokens += _amount;

        // Claim any pending rewards before updating stake to calculate accurately
        _claimAndCalculateRewards(msg.sender);

        // Update staker's balance
        stakerInfos[msg.sender].stakedAmount += _amount;
        stakerInfos[msg.sender].lastRewardClaimTime = block.timestamp; // Reset reward timer for new stake

        // Update delegate's voting power or self
        address effectiveVoter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        if (effectiveVoter == msg.sender) {
            // Direct staker, their voting power is their stake
        } else {
            // Delegator, their stake adds to delegatee's power
            delegatedVotingPower[effectiveVoter] += _amount;
        }

        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @notice Initiates the unstaking process for SCAE tokens.
     * @dev Tokens will be locked for `stakingLockupPeriod` before they can be claimed.
     *      Unstaking reduces voting power immediately.
     * @param _amount The amount of SCAE tokens to unstake.
     */
    function unstakeSCAETokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakerInfos[msg.sender].stakedAmount >= _amount, "Insufficient staked tokens");
        require(pendingUnstakeAmount[msg.sender] == 0 || unstakeLockupEnd[msg.sender] <= block.timestamp, "Previous unstake lockup active");

        // Claim any pending rewards first for accurate calculation
        _claimAndCalculateRewards(msg.sender);

        // Reduce staker's balance
        stakerInfos[msg.sender].stakedAmount -= _amount;
        totalStakedTokens -= _amount;

        // Reduce delegate's voting power or self
        address effectiveVoter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        if (effectiveVoter == msg.sender) {
            // Direct staker, their voting power is their stake
        } else {
            // Delegator, their stake adds to delegatee's power
            delegatedVotingPower[effectiveVoter] -= _amount;
        }

        // Set lockup for this amount
        pendingUnstakeAmount[msg.sender] = _amount;
        unstakeLockupEnd[msg.sender] = block.timestamp + stakingLockupPeriod;

        emit UnstakeRequested(msg.sender, _amount, unstakeLockupEnd[msg.sender]);
    }

    /**
     * @notice Claims accumulated rewards from staking and participation.
     * @dev Rewards are calculated based on staked amount and `rewardRatePerDay` since last claim.
     *      Also allows claiming of unstaked tokens if lockup period has passed.
     */
    function claimRewards() public whenNotPaused {
        uint256 totalClaimable = 0;

        // Claim staking rewards
        uint256 rewards = _claimAndCalculateRewards(msg.sender);
        totalClaimable += rewards;

        // Claim unstaked tokens if lockup is over
        if (pendingUnstakeAmount[msg.sender] > 0 && unstakeLockupEnd[msg.sender] <= block.timestamp) {
            totalClaimable += pendingUnstakeAmount[msg.sender];
            emit TokensUnstakedClaimed(msg.sender, pendingUnstakeAmount[msg.sender]);
            pendingUnstakeAmount[msg.sender] = 0;
            unstakeLockupEnd[msg.sender] = 0; // Reset lockup
        }

        require(totalClaimable > 0, "No rewards or unstaked tokens to claim");
        scaeToken.transfer(msg.sender, totalClaimable);

        emit RewardsClaimed(msg.sender, totalClaimable);
    }

    /**
     * @dev Internal function to calculate and reset rewards for a staker.
     * @param _staker The address of the staker.
     * @return The calculated reward amount.
     */
    function _claimAndCalculateRewards(address _staker) internal returns (uint256) {
        StakerInfo storage staker = stakerInfos[_staker];
        uint256 currentStaked = staker.stakedAmount;

        if (currentStaked == 0 || staker.lastRewardClaimTime == 0) {
            return 0; // No active stake or first stake
        }

        uint256 timeElapsed = block.timestamp - staker.lastRewardClaimTime;
        if (timeElapsed == 0) {
            return 0; // No time elapsed since last claim
        }

        // Reward calculation: (staked amount * rewardRatePerDay * timeElapsed) / (100 * 1 day in seconds)
        // Divide by 100 to get percentage from rewardRatePerDay (e.g., 100 means 1%)
        uint256 rewardAmount = (currentStaked * rewardRatePerDay * timeElapsed) / (100 * 1 days); // 1 day in seconds

        staker.lastRewardClaimTime = block.timestamp; // Reset last claim time
        return rewardAmount;
    }


    // --- VII. View & Utility Functions ---

    /**
     * @notice Returns the total SCAE tokens currently staked by a specific address.
     * @param _staker The address of the staker.
     * @return The total staked amount.
     */
    function getTotalStaked(address _staker) public view returns (uint256) {
        return stakerInfos[_staker].stakedAmount;
    }

    /**
     * @notice Returns the effective voting power of an address, considering delegation.
     * @param _voter The address for which to query voting power.
     * @return The total voting power.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        if (delegates[_voter] != address(0)) {
            // If _voter has delegated, their own stake contributes to the delegatee's power, not their own direct power.
            return 0;
        }
        // If _voter is a delegatee, they have their own stake plus all delegated stakes to them.
        // If _voter has not delegated and is not a delegatee, they just have their own stake.
        return stakerInfos[_voter].stakedAmount + delegatedVotingPower[_voter];
    }

    /**
     * @notice Returns the metadata URI for a specific Cognito NFT.
     * @param _tokenId The ID of the Cognito NFT.
     * @return The token URI.
     */
    function getNFTMetadataURI(uint256 _tokenId) public view override returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    /**
     * @notice Returns the current balance of the Inspiration Pool.
     * @return The amount of SCAE tokens in the Inspiration Pool.
     */
    function getInspirationPoolBalance() public view returns (uint256) {
        return inspirationPoolBalance;
    }

    // Fallback function to receive Ether if needed by proposals
    receive() external payable {}
}
```