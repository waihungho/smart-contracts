This smart contract, **CognitiveForgeNexus**, proposes a novel decentralized protocol for managing dynamic NFTs, referred to as "Cognitive Constructs." These NFTs are not static digital assets but rather living entities that evolve based on AI oracle assessments and community contributions. The protocol integrates an internal utility token, "Cognitive Fragments," and a reputation system ("Influence Score") to incentivize participation and ensure the integrity of the evolving constructs.

Cognitive Constructs can represent either **generative art seeds** that evolve visually, or **scientific hypotheses/data models** that update their validation scores based on submitted proofs and AI analysis.

---

# CognitiveForgeNexus Smart Contract

## Outline and Function Summary

**I. Protocol Foundation & Administration:**
*   **`constructor(address _aiOracleAddress, address _fragmentTokenOwner)`**: Initializes the protocol, sets the trusted AI oracle address, and mints initial Cognitive Fragments for a designated owner.
*   **`setProtocolOwner(address newOwner)`**: Allows the current protocol owner to transfer administrative ownership to a new address.
*   **`setAIOracleAddress(address newOracle)`**: Updates the address of the trusted AI oracle.
*   **`pauseProtocol()`**: Halts critical operations of the protocol (e.g., transfers, evolution requests) in emergency situations.
*   **`unpauseProtocol()`**: Resumes previously paused protocol operations.
*   **`withdrawProtocolFees()`**: Enables the protocol owner to withdraw any accumulated ETH fees from the contract.

**II. Cognitive Fragments (Internal ERC-20 Token):**
*   **`getFragmentBalance(address account)`**: Retrieves the Cognitive Fragment balance of a specified account.
*   **`transferFragments(address recipient, uint256 amount)`**: Allows a user to transfer their Cognitive Fragments to another address.
*   **`approveFragmentSpender(address spender, uint256 amount)`**: Grants a `spender` permission to transfer a specified `amount` of fragments on behalf of the caller.
*   **`transferFragmentsFrom(address sender, address recipient, uint256 amount)`**: Allows an approved `spender` to transfer fragments from `sender` to `recipient`.
*   **`stakeFragments(uint256 amount)`**: Users stake Cognitive Fragments into the protocol to gain influence and participate in governance/validation.
*   **`unstakeFragments(uint256 amount)`**: Users retrieve their previously staked Cognitive Fragments.

**III. Cognitive Constructs (Dynamic ERC-721 NFTs):**
*   **`createCognitiveConstruct(string memory initialPrompt, bool isGenerativeArt, uint256 feeInFragments)`**: Mints a new Cognitive Construct NFT. The caller provides an initial prompt, specifies if it's for art or research, and pays a fee in Fragments.
*   **`getConstructDetails(uint256 tokenId)`**: Returns all comprehensive details for a given Cognitive Construct NFT, including its type, current state, and evolution history.
*   **`getConstructManifestationHash(uint256 tokenId)`**: Provides the current `bytes32` hash representing the evolving state of the Construct (e.g., visual output for art, data model for research).
*   **`transferFrom(address from, address to, uint256 tokenId)`**: Standard ERC721 function for transferring ownership of a Construct.
*   **`approve(address to, uint256 tokenId)`**: Standard ERC721 function to approve a single address to control a specific Construct.
*   **`setApprovalForAll(address operator, bool approved)`**: Standard ERC721 function to approve or revoke an operator's control over all of the caller's Constructs.
*   **`burnConstruct(uint256 tokenId)`**: Allows the owner of a Cognitive Construct to permanently destroy it.

**IV. AI Oracle & Construct Evolution:**
*   **`submitContributionData(uint256 tokenId, string memory dataContentHash, string memory description)`**: Users submit a cryptographic hash (e.g., IPFS CID, ZK proof hash) of off-chain data relevant to a specific Construct. This data serves as input for AI evolution.
*   **`requestAIEvolution(uint256 tokenId, uint256 contributionId, uint256 costInFragments, uint256 callbackGasLimit)`**: Initiates an AI oracle request to evaluate a specific `contributionId` for a `tokenId`. The caller pays a fee in Fragments and specifies a gas limit for the oracle's callback.
*   **`aiOracleCallback(uint256 requestId, uint256 tokenId, bytes32 newManifestationHash, int256 validationScoreChange, address[] memory rewardRecipients, uint256[] memory rewardAmounts)`**: (EXTERNAL, ONLY\_ORACLE) This function is called back by the AI oracle after processing a request. It updates the Construct's `currentManifestationHash`, adjusts its `validationScore`, and distributes `Cognitive Fragments` rewards to contributors and endorsers.

**V. User Reputation & Interaction:**
*   **`getInfluenceScore(address user)`**: Retrieves the accumulated Influence Score for a given user, reflecting their successful contributions and staked fragments.
*   **`delegateInfluence(address delegatee)`**: Allows a user to delegate their Influence Score to another address, useful for collective governance or expert panels.
*   **`revokeInfluenceDelegation()`**: Revokes any active influence delegation made by the caller.
*   **`claimContributionRewards(uint256 contributionId)`**: Enables users to claim Cognitive Fragments earned from their contributions that were positively assessed by the AI.

**VI. Decentralized Validation & Review:**
*   **`endorseContribution(uint256 tokenId, uint256 contributionId)`**: Users with staked Fragments can endorse a submitted contribution. Endorsements add weight to the contribution for AI processing and can earn rewards.
*   **`challengeContribution(uint256 tokenId, uint256 contributionId, uint256 bondAmount)`**: Users can challenge the validity of a submitted contribution. A bond in Cognitive Fragments is required, which may be forfeited or refunded based on the challenge's resolution.
*   **`resolveChallenge(uint256 contributionId, bool isValid, address[] memory bondDistributors, uint256[] memory bondAmounts)`**: (EXTERNAL, ONLY\_ORACLE) The AI oracle or protocol admin resolves a challenge, determining the validity of the contribution and distributing the challenge bonds accordingly.

**VII. Protocol Economics & Incentives:**
*   **`setEvolutionCost(uint256 newCost)`**: Admin function to adjust the base cost in Cognitive Fragments for initiating an AI evolution request.
*   **`setEndorsementRewardRate(uint256 rate)`**: Admin function to set the reward multiplier for successful endorsements, influencing how the AI distributes rewards.
*   **`setChallengeBondRate(uint256 rateBasisPoints)`**: Admin function to set the percentage (in basis points) of the evolution cost required as a bond to challenge a contribution.

**VIII. Governance & Future Expansion (Simplified):**
*   **`proposeParameterChange(string memory description, address targetContract, bytes memory callData, uint256 votingPeriodDays, uint256 minInfluenceForVoteThreshold)`**: Allows users with sufficient influence to create a governance proposal to change protocol parameters or execute arbitrary calls.
*   **`voteOnProposal(uint256 proposalId, bool support)`**: Users with influence can cast their votes (for or against) on active governance proposals.
*   **`executeProposal(uint256 proposalId)`**: Executes a governance proposal that has successfully passed its voting period and met the required vote threshold.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// While Fragments are implemented internally, IERC20 is imported for conceptual clarity
// and to illustrate that it functions as a token.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

/**
 * @title CognitiveForgeNexus
 * @author [Your Name/Alias: AI-Forge]
 * @notice A decentralized protocol for dynamic NFTs (Cognitive Constructs) that evolve
 *         based on AI oracle assessments and community contributions. It features
 *         an internal ERC-20 utility token (Cognitive Fragments), a reputation
 *         (Influence Score) system, and mechanisms for decentralized data validation.
 *         Cognitive Constructs can represent generative art seeds or scientific hypotheses.
 *
 * Outline and Function Summary:
 *
 * I. Protocol Foundation & Administration:
 *    - constructor: Initializes the protocol, sets AI oracle, mints initial Fragments.
 *    - setProtocolOwner: Changes the protocol's administrative owner.
 *    - setAIOracleAddress: Updates the trusted AI oracle address.
 *    - pauseProtocol: Halts core operations in emergencies.
 *    - unpauseProtocol: Resumes operations.
 *    - withdrawProtocolFees: Allows owner to withdraw accumulated ETH fees.
 *
 * II. Cognitive Fragments (Internal ERC-20 Token):
 *    - getFragmentBalance: Retrieves an account's Cognitive Fragment balance.
 *    - transferFragments: Transfers Fragments between users.
 *    - approveFragmentSpender: Approves a spender to move Fragments on behalf of the owner.
 *    - transferFragmentsFrom: Transfers Fragments using an allowance.
 *    - stakeFragments: Users stake Fragments to boost influence or participate.
 *    - unstakeFragments: Users retrieve staked Fragments.
 *
 * III. Cognitive Constructs (Dynamic ERC-721 NFTs):
 *    - createCognitiveConstruct: Mints a new NFT with an initial prompt and type.
 *    - getConstructDetails: Retrieves all detailed information for a specific Construct NFT.
 *    - getConstructManifestationHash: Returns the current AI-generated state hash of a Construct.
 *    - transferFrom (ERC721): Standard ERC721 transfer function.
 *    - approve (ERC721): Standard ERC721 approval function.
 *    - setApprovalForAll (ERC721): Standard ERC721 approval for all tokens.
 *    - burnConstruct: Allows burning of a Cognitive Construct.
 *
 * IV. AI Oracle & Construct Evolution:
 *    - submitContributionData: Users submit a hashed reference to off-chain data for a Construct.
 *    - requestAIEvolution: Initiates an AI oracle request for a Construct, consuming Fragments.
 *    - aiOracleCallback: (EXTERNAL, ONLY_ORACLE) Callback function for the AI oracle to report results,
 *                      update Construct state, and distribute Fragment rewards.
 *
 * V. User Reputation & Interaction:
 *    - getInfluenceScore: Retrieves a user's accumulated Influence Score.
 *    - delegateInfluence: Delegates a user's Influence Score to another address.
 *    - revokeInfluenceDelegation: Revokes a previously set influence delegation.
 *    - claimContributionRewards: Allows users to claim Fragments earned from successful contributions.
 *
 * VI. Decentralized Validation & Review:
 *    - endorseContribution: Users endorse a submitted contribution, adding weight for AI processing.
 *    - challengeContribution: Users challenge a contribution, requiring a bond.
 *    - resolveChallenge: (EXTERNAL, ADMIN/ORACLE) Resolves a challenge, distributing bonds.
 *
 * VII. Protocol Economics & Incentives:
 *    - setEvolutionCost: Admin sets the base cost in Fragments for AI evolution requests.
 *    - setEndorsementRewardRate: Admin sets the reward multiplier for successful endorsements.
 *    - setChallengeBondRate: Admin sets the percentage of fragments required as a bond to challenge.
 *
 * VIII. Governance & Future Expansion (Simplified):
 *    - proposeParameterChange: Initiates a governance proposal for protocol parameter adjustment.
 *    - voteOnProposal: Users with influence vote on active proposals.
 *    - executeProposal: Executes a passed proposal.
 *
 * Total Functions: 29
 */
contract CognitiveForgeNexus is Ownable, Pausable, ERC721, ERC721Burnable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // NFT Counter
    Counters.Counter private _tokenIdCounter;

    // --- Cognitive Fragment (Internal ERC-20) Logic ---
    string public constant FRAGMENT_NAME = "Cognitive Fragment";
    string public constant FRAGMENT_SYMBOL = "CFG";
    uint8 public constant FRAGMENT_DECIMALS = 18;
    mapping(address => uint256) private _fragmentBalances;
    mapping(address => mapping(address => uint256)) private _fragmentAllowances;
    uint256 private _totalSupplyFragments;

    event TransferFragments(address indexed from, address indexed to, uint256 value);
    event ApprovalFragments(address indexed owner, address indexed spender, uint256 value);
    // --- End Cognitive Fragment Logic ---

    address public aiOracleAddress;
    uint256 public nextAIRequestId = 1; // Unique ID for AI requests

    // Protocol Fees
    uint256 public protocolETHFees;

    // Evolution & Reward Parameters
    uint256 public evolutionCostFragments; // Cost to request AI evolution
    uint256 public endorsementRewardRate; // Multiplier for endorsement rewards
    uint256 public challengeBondRateBasisPoints; // Basis points for challenge bond (e.g., 1000 = 10%)

    // --- Data Structures ---

    enum ConstructType {
        GenerativeArt,
        ResearchHypothesis
    }

    struct CognitiveConstruct {
        uint256 tokenId;
        address creator;
        ConstructType constructType;
        string initialPrompt;
        bytes32 currentManifestationHash; // Hash representing the current state (visuals for art, data model for research)
        int256 validationScore; // For research, how well it validates; for art, aesthetic score.
        uint256 lastEvolutionTimestamp;
        uint256 totalContributions; // Number of unique data contributions
        uint256 totalEndorsements; // Total endorsements across all contributions
    }

    mapping(uint256 => CognitiveConstruct) public cognitiveConstructs; // tokenId => CognitiveConstruct

    struct Contribution {
        uint256 contributionId;
        uint256 tokenId;
        address contributor;
        string dataContentHash; // Hash of off-chain data (e.g., IPFS CID, cryptographic proof hash)
        string description;
        uint256 submissionTimestamp;
        uint256 endorsementCount;
        uint256 challengeCount;
        bool isChallenged;
        bool isValidatedByAI; // If AI processed and found positive
        mapping(address => bool) hasEndorsed; // User => has endorsed this contribution
        uint256 fragmentsClaimable; // Fragments awarded but not yet claimed
    }

    mapping(uint256 => Contribution) public contributions; // contributionId => Contribution
    Counters.Counter private _contributionIdCounter;

    struct AIRequest {
        uint256 tokenId;
        uint256 contributionDataIndex; // Index of the contribution being evaluated
        address requester;
        uint256 requestTimestamp;
        bool isFulfilled;
    }

    mapping(uint256 => AIRequest) public aiRequests; // requestId => AIRequest

    // User Influence System
    mapping(address => uint256) public influenceScores;
    mapping(address => address) public delegatedInfluence; // user => delegatee

    // Staking for influence / participation
    mapping(address => uint256) public stakedFragments;

    // Governance Proposals (simplified)
    struct Proposal {
        uint256 proposalId;
        string description;
        bytes callData; // Encoded function call to execute if passed
        address targetContract;
        uint256 voteThreshold; // Required influence score for passing
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTimestamp;
        uint256 endTimestamp;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks who has voted on this specific proposal
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;

    // --- Events ---
    event AIRequestInitiated(
        uint256 indexed requestId,
        uint256 indexed tokenId,
        uint256 indexed contributionDataIndex,
        address requester,
        uint256 cost
    );
    event AIRequestFulfilled(
        uint256 indexed requestId,
        uint256 indexed tokenId,
        bytes32 newManifestationHash,
        int256 validationScoreChange
    );
    event CognitiveConstructCreated(
        uint256 indexed tokenId,
        address indexed creator,
        ConstructType constructType,
        string initialPrompt
    );
    event ContributionSubmitted(
        uint256 indexed contributionId,
        uint256 indexed tokenId,
        address indexed contributor,
        string dataContentHash
    );
    event ContributionEndorsed(uint256 indexed contributionId, address indexed endorser);
    event ContributionChallenged(
        uint256 indexed contributionId,
        address indexed challenger,
        uint256 bondAmount
    );
    event ChallengeResolved(
        uint256 indexed contributionId,
        bool isValid,
        address indexed resolver,
        uint256 refundedBond,
        uint256 forfeitedBond
    );
    event InfluenceUpdated(address indexed user, uint256 newScore);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event FragmentsStaked(address indexed user, uint256 amount);
    event FragmentsUnstaked(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 endTimestamp);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event RewardsClaimed(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "CognitiveForgeNexus: Only AI oracle can call this");
        _;
    }

    // --- I. Protocol Foundation & Administration ---

    /**
     * @notice Initializes the CognitiveForgeNexus protocol.
     * @param _aiOracleAddress The address of the trusted AI oracle.
     * @param _fragmentTokenOwner The address to receive initial Cognitive Fragments.
     */
    constructor(address _aiOracleAddress, address _fragmentTokenOwner)
        ERC721("Cognitive Construct", "COG")
        Ownable(msg.sender)
    {
        aiOracleAddress = _aiOracleAddress;
        _mintFragments(_fragmentTokenOwner, 1_000_000 * (10 ** FRAGMENT_DECIMALS)); // Initial fragments for owner
        evolutionCostFragments = 10 * (10 ** FRAGMENT_DECIMALS); // Default cost: 10 fragments
        endorsementRewardRate = 100; // 100 fragments base reward per endorsement (can be scaled by AI)
        challengeBondRateBasisPoints = 1000; // 10% of evolution cost as challenge bond
    }

    /**
     * @notice Changes the owner of the protocol.
     * @param newOwner The address of the new protocol owner.
     */
    function setProtocolOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    /**
     * @notice Updates the trusted AI oracle address.
     * @param newOracle The address of the new AI oracle.
     */
    function setAIOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "CognitiveForgeNexus: Invalid AI oracle address");
        aiOracleAddress = newOracle;
    }

    /**
     * @notice Pauses core operations of the protocol in case of an emergency.
     */
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses core operations of the protocol.
     */
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the protocol owner to withdraw accumulated ETH fees.
     */
    function withdrawProtocolFees() public onlyOwner {
        require(protocolETHFees > 0, "CognitiveForgeNexus: No ETH fees to withdraw");
        uint256 amount = protocolETHFees;
        protocolETHFees = 0;
        payable(owner()).transfer(amount);
    }

    // --- II. Cognitive Fragments (Internal ERC-20 Token) ---

    // Internal ERC-20 mint function
    function _mintFragments(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupplyFragments += amount;
        _fragmentBalances[account] += amount;
        emit TransferFragments(address(0), account, amount);
    }

    // Internal ERC-20 burn function
    function _burnFragments(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_fragmentBalances[account] >= amount, "ERC20: burn amount exceeds balance");
        _fragmentBalances[account] -= amount;
        _totalSupplyFragments -= amount;
        emit TransferFragments(account, address(0), amount);
    }

    // Internal ERC-20 transfer logic
    function _transferFragments(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_fragmentBalances[from] >= amount, "ERC20: transfer amount exceeds balance");

        _fragmentBalances[from] -= amount;
        _fragmentBalances[to] += amount;
        emit TransferFragments(from, to, amount);
    }

    // Internal ERC-20 approve logic
    function _approveFragments(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _fragmentAllowances[owner][spender] = amount;
        emit ApprovalFragments(owner, spender, amount);
    }

    /**
     * @notice Returns the amount of fragments owned by `account`.
     * @param account The address to query the balance of.
     * @return The amount of fragments owned by `account`.
     */
    function getFragmentBalance(address account) public view returns (uint256) {
        return _fragmentBalances[account];
    }

    /**
     * @notice Moves `amount` fragments from the caller's account to `recipient`.
     * @param recipient The address to send fragments to.
     * @param amount The amount of fragments to send.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFragments(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        _transferFragments(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's fragments.
     * @param spender The address to approve.
     * @param amount The amount to set as allowance.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approveFragmentSpender(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approveFragments(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Moves `amount` fragments from `sender` to `recipient` using the
     *         allowance mechanism. `amount` is then deducted from the caller's allowance.
     * @param sender The address to move fragments from.
     * @param recipient The address to move fragments to.
     * @param amount The amount of fragments to move.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFragmentsFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _fragmentAllowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approveFragments(sender, msg.sender, currentAllowance - amount);
        }
        _transferFragments(sender, recipient, amount);
        return true;
    }

    /**
     * @notice Allows a user to stake Cognitive Fragments to participate in protocol activities or boost influence.
     * @param amount The amount of fragments to stake.
     */
    function stakeFragments(uint256 amount) public whenNotPaused {
        require(amount > 0, "CognitiveForgeNexus: Stake amount must be greater than zero");
        _transferFragments(msg.sender, address(this), amount); // Transfer fragments to contract
        stakedFragments[msg.sender] += amount;
        influenceScores[msg.sender] += (amount / (10 ** FRAGMENT_DECIMALS)) * 10; // Simplified influence boost (10 points per fragment unit)
        emit FragmentsStaked(msg.sender, amount);
        emit InfluenceUpdated(msg.sender, influenceScores[msg.sender]);
    }

    /**
     * @notice Allows a user to unstake Cognitive Fragments.
     * @param amount The amount of fragments to unstake.
     */
    function unstakeFragments(uint256 amount) public whenNotPaused {
        require(amount > 0, "CognitiveForgeNexus: Unstake amount must be greater than zero");
        require(stakedFragments[msg.sender] >= amount, "CognitiveForgeNexus: Not enough fragments staked");
        stakedFragments[msg.sender] -= amount;
        
        // Remove influence boost, ensuring score doesn't go negative
        uint256 influenceDecrease = (amount / (10 ** FRAGMENT_DECIMALS)) * 10;
        if (influenceScores[msg.sender] > influenceDecrease) {
            influenceScores[msg.sender] -= influenceDecrease;
        } else {
            influenceScores[msg.sender] = 0;
        }
        
        _transferFragments(address(this), msg.sender, amount); // Transfer fragments back to user
        emit FragmentsUnstaked(msg.sender, amount);
        emit InfluenceUpdated(msg.sender, influenceScores[msg.sender]);
    }

    // --- III. Cognitive Constructs (Dynamic ERC-721 NFTs) ---

    /**
     * @notice Mints a new Cognitive Construct NFT.
     * @param initialPrompt A descriptive string for the construct (e.g., AI art prompt, hypothesis text).
     * @param isGenerativeArt True if it's an art construct, false for research hypothesis.
     * @param feeInFragments The amount of Cognitive Fragments to pay as a creation fee.
     */
    function createCognitiveConstruct(
        string memory initialPrompt,
        bool isGenerativeArt,
        uint256 feeInFragments
    ) public whenNotPaused {
        require(feeInFragments > 0, "CognitiveForgeNexus: Creation fee must be positive");
        _transferFragments(msg.sender, address(this), feeInFragments); // Pay creation fee to the protocol

        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        ConstructType cType = isGenerativeArt ? ConstructType.GenerativeArt : ConstructType.ResearchHypothesis;

        cognitiveConstructs[newId] = CognitiveConstruct({
            tokenId: newId,
            creator: msg.sender,
            constructType: cType,
            initialPrompt: initialPrompt,
            currentManifestationHash: bytes32(0), // Initial empty hash
            validationScore: 0,
            lastEvolutionTimestamp: block.timestamp,
            totalContributions: 0,
            totalEndorsements: 0
        });

        _mint(msg.sender, newId);
        emit CognitiveConstructCreated(newId, msg.sender, cType, initialPrompt);
    }

    /**
     * @notice Returns all detailed information of a specific Cognitive Construct NFT.
     * @param tokenId The ID of the Cognitive Construct.
     * @return A tuple containing all construct details.
     */
    function getConstructDetails(uint256 tokenId)
        public
        view
        returns (
            uint256,
            address,
            ConstructType,
            string memory,
            bytes32,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        CognitiveConstruct storage construct = cognitiveConstructs[tokenId];
        require(construct.creator != address(0), "CognitiveForgeNexus: Construct does not exist");
        return (
            construct.tokenId,
            construct.creator,
            construct.constructType,
            construct.initialPrompt,
            construct.currentManifestationHash,
            construct.validationScore,
            construct.lastEvolutionTimestamp,
            construct.totalContributions,
            construct.totalEndorsements
        );
    }

    /**
     * @notice Returns the current AI-generated manifestation hash of a Construct.
     *         This hash represents the current visual state for art or data model for research.
     * @param tokenId The ID of the Cognitive Construct.
     * @return The current manifestation hash.
     */
    function getConstructManifestationHash(uint256 tokenId) public view returns (bytes32) {
        CognitiveConstruct storage construct = cognitiveConstructs[tokenId];
        require(construct.creator != address(0), "CognitiveForgeNexus: Construct does not exist");
        return construct.currentManifestationHash;
    }

    /**
     * @notice Burns a Cognitive Construct NFT.
     * @param tokenId The ID of the Cognitive Construct to burn.
     */
    function burnConstruct(uint256 tokenId) public {
        _burn(tokenId); // ERC721Burnable provides _burn, which includes owner check
    }

    // ERC721 standard functions (transferFrom, approve, setApprovalForAll) are inherited.

    // --- IV. AI Oracle & Construct Evolution ---

    /**
     * @notice Users submit a hashed reference to off-chain data relevant to a construct.
     *         This data will later be picked for AI evolution.
     * @param tokenId The ID of the Cognitive Construct.
     * @param dataContentHash A hash of the off-chain data (e.g., IPFS CID, cryptographic proof hash).
     * @param description A brief description of the contribution.
     */
    function submitContributionData(
        uint256 tokenId,
        string memory dataContentHash,
        string memory description
    ) public whenNotPaused {
        require(cognitiveConstructs[tokenId].creator != address(0), "CognitiveForgeNexus: Construct does not exist");
        require(bytes(dataContentHash).length > 0, "CognitiveForgeNexus: Data content hash cannot be empty");

        _contributionIdCounter.increment();
        uint256 newContributionId = _contributionIdCounter.current();

        contributions[newContributionId] = Contribution({
            contributionId: newContributionId,
            tokenId: tokenId,
            contributor: msg.sender,
            dataContentHash: dataContentHash,
            description: description,
            submissionTimestamp: block.timestamp,
            endorsementCount: 0,
            challengeCount: 0,
            isChallenged: false,
            isValidatedByAI: false,
            fragmentsClaimable: 0
        });

        cognitiveConstructs[tokenId].totalContributions++;
        emit ContributionSubmitted(newContributionId, tokenId, msg.sender, dataContentHash);
    }

    /**
     * @notice Initiates an AI oracle request for a specific Cognitive Construct, using a submitted contribution.
     *         Costs Cognitive Fragments, which are paid to the protocol and potentially to endorsers/challengers.
     *         ETH sent with this transaction can be used by the oracle for gas fees.
     * @param tokenId The ID of the Cognitive Construct to evolve.
     * @param contributionId The ID of the specific contribution data to be evaluated by AI.
     * @param costInFragments The amount of Cognitive Fragments to pay for this evolution request.
     * @param callbackGasLimit Gas limit for the AI oracle's callback transaction.
     */
    function requestAIEvolution(
        uint256 tokenId,
        uint256 contributionId,
        uint256 costInFragments,
        uint256 callbackGasLimit // Simulates a standard Chainlink/Provable callback gas limit
    ) public payable whenNotPaused {
        require(cognitiveConstructs[tokenId].creator != address(0), "CognitiveForgeNexus: Construct does not exist");
        require(
            contributions[contributionId].tokenId == tokenId,
            "CognitiveForgeNexus: Contribution ID does not match Token ID"
        );
        require(costInFragments >= evolutionCostFragments, "CognitiveForgeNexus: Insufficient evolution cost");

        _transferFragments(msg.sender, address(this), costInFragments); // Transfer fragments to protocol
        protocolETHFees += msg.value; // Store any ETH sent (e.g., for oracle gas fees)

        uint256 currentRequestId = nextAIRequestId++;
        aiRequests[currentRequestId] = AIRequest({
            tokenId: tokenId,
            contributionDataIndex: contributionId,
            requester: msg.sender,
            requestTimestamp: block.timestamp,
            isFulfilled: false
        });

        // This event simulates a call to an off-chain AI oracle.
        // A real system would have an oracle client contract that makes an external call
        // and later calls back `aiOracleCallback`.
        emit AIRequestInitiated(currentRequestId, tokenId, contributionId, msg.sender, costInFragments);
    }

    /**
     * @notice Callback function for the AI oracle to report results of a construct evolution.
     *         Updates the Construct's state, distributes Fragment rewards.
     * @dev This function is external and can only be called by the designated AI oracle address.
     * @param requestId The ID of the original AI request.
     * @param tokenId The ID of the Cognitive Construct that was evolved.
     * @param newManifestationHash The new hash representing the evolved state.
     * @param validationScoreChange The change in the construct's validation score.
     * @param rewardRecipients An array of addresses to receive fragment rewards.
     * @param rewardAmounts An array of corresponding fragment amounts for rewards.
     */
    function aiOracleCallback(
        uint256 requestId,
        uint256 tokenId,
        bytes32 newManifestationHash,
        int256 validationScoreChange,
        address[] memory rewardRecipients,
        uint256[] memory rewardAmounts
    ) public onlyAIOracle whenNotPaused {
        AIRequest storage req = aiRequests[requestId];
        require(req.tokenId == tokenId, "CognitiveForgeNexus: Request ID mismatch");
        require(!req.isFulfilled, "CognitiveForgeNexus: AI request already fulfilled");

        req.isFulfilled = true; // Mark request as fulfilled

        CognitiveConstruct storage construct = cognitiveConstructs[tokenId];
        construct.currentManifestationHash = newManifestationHash;
        construct.validationScore += validationScoreChange;
        construct.lastEvolutionTimestamp = block.timestamp;

        // Mark the processed contribution as validated by AI if the score increased
        Contribution storage processedContribution = contributions[req.contributionDataIndex];
        processedContribution.isValidatedByAI = (validationScoreChange > 0); 

        // Distribute rewards by accumulating claimable fragments
        require(rewardRecipients.length == rewardAmounts.length, "CognitiveForgeNexus: Reward arrays length mismatch");
        for (uint256 i = 0; i < rewardRecipients.length; i++) {
            require(rewardRecipients[i] != address(0), "CognitiveForgeNexus: Reward recipient cannot be zero address");
            // Add fragments to the contributor's claimable balance for this specific contribution
            contributions[req.contributionDataIndex].fragmentsClaimable += rewardAmounts[i];
            
            // Directly boost influence for successful contributions/endorsements.
            // Simplified: 1 influence point per fragment unit awarded (assuming 18 decimals)
            influenceScores[rewardRecipients[i]] += rewardAmounts[i] / (10 ** FRAGMENT_DECIMALS); 
            emit InfluenceUpdated(rewardRecipients[i], influenceScores[rewardRecipients[i]]);
        }

        emit AIRequestFulfilled(requestId, tokenId, newManifestationHash, validationScoreChange);
    }

    // --- V. User Reputation & Interaction ---

    /**
     * @notice Retrieves a user's current Influence Score. If the user has delegated, returns the delegatee's score.
     * @param user The address of the user.
     * @return The Influence Score of the user or their delegatee.
     */
    function getInfluenceScore(address user) public view returns (uint256) {
        address delegatee = delegatedInfluence[user];
        return influenceScores[delegatee != address(0) ? delegatee : user];
    }

    /**
     * @notice Delegates a user's Influence Score to another address.
     *         Useful for DAO participation or expert review panels.
     * @param delegatee The address to delegate influence to.
     */
    function delegateInfluence(address delegatee) public whenNotPaused {
        require(delegatee != address(0), "CognitiveForgeNexus: Delegatee cannot be zero address");
        require(delegatee != msg.sender, "CognitiveForgeNexus: Cannot delegate influence to self");
        delegatedInfluence[msg.sender] = delegatee;
        emit InfluenceDelegated(msg.sender, delegatee);
    }

    /**
     * @notice Revokes a previously set influence delegation.
     */
    function revokeInfluenceDelegation() public whenNotPaused {
        require(delegatedInfluence[msg.sender] != address(0), "CognitiveForgeNexus: No active delegation to revoke");
        delete delegatedInfluence[msg.sender];
        emit InfluenceDelegated(msg.sender, address(0)); // Emit with address(0) to signify revocation
    }

    /**
     * @notice Allows users to claim Cognitive Fragments earned from their contributions
     *         being positively assessed by the AI oracle.
     * @param contributionId The ID of the contribution for which to claim rewards.
     */
    function claimContributionRewards(uint256 contributionId) public whenNotPaused {
        Contribution storage contribution = contributions[contributionId];
        require(contribution.contributor == msg.sender, "CognitiveForgeNexus: Not the contributor of this reward");
        require(contribution.fragmentsClaimable > 0, "CognitiveForgeNexus: No fragments to claim for this contribution");

        uint256 amountToClaim = contribution.fragmentsClaimable;
        contribution.fragmentsClaimable = 0; // Reset claimable for this contribution

        _transferFragments(address(this), msg.sender, amountToClaim);
        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    // --- VI. Decentralized Validation & Review ---

    /**
     * @notice Users with staked fragments can endorse a submitted contribution data.
     *         Endorsements increase the weight of a contribution for AI processing and can earn rewards.
     * @param tokenId The ID of the Cognitive Construct.
     * @param contributionId The ID of the contribution to endorse.
     */
    function endorseContribution(uint256 tokenId, uint256 contributionId) public whenNotPaused {
        require(cognitiveConstructs[tokenId].creator != address(0), "CognitiveForgeNexus: Construct does not exist");
        require(
            contributions[contributionId].tokenId == tokenId,
            "CognitiveForgeNexus: Contribution ID does not match Token ID"
        );
        Contribution storage contribution = contributions[contributionId];
        require(!contribution.hasEndorsed[msg.sender], "CognitiveForgeNexus: Already endorsed this contribution");
        require(stakedFragments[msg.sender] > 0, "CognitiveForgeNexus: Must stake fragments to endorse");

        contribution.endorsementCount++;
        contribution.hasEndorsed[msg.sender] = true;
        cognitiveConstructs[tokenId].totalEndorsements++;
        influenceScores[msg.sender] += 1; // Small influence boost for endorsing
        emit ContributionEndorsed(contributionId, msg.sender);
        emit InfluenceUpdated(msg.sender, influenceScores[msg.sender]);
    }

    /**
     * @notice Users can challenge a submitted contribution, requiring a bond.
     *         If the challenge is successful (AI or Admin invalidates), the challenger gets part of the bond.
     * @param tokenId The ID of the Cognitive Construct.
     * @param contributionId The ID of the contribution to challenge.
     * @param bondAmount The amount of Cognitive Fragments to put up as a bond.
     */
    function challengeContribution(
        uint256 tokenId,
        uint256 contributionId,
        uint256 bondAmount
    ) public whenNotPaused {
        require(cognitiveConstructs[tokenId].creator != address(0), "CognitiveForgeNexus: Construct does not exist");
        require(
            contributions[contributionId].tokenId == tokenId,
            "CognitiveForgeNexus: Contribution ID does not match Token ID"
        );
        Contribution storage contribution = contributions[contributionId];
        require(contribution.contributor != msg.sender, "CognitiveForgeNexus: Cannot challenge your own contribution");
        require(!contribution.isChallenged, "CognitiveForgeNexus: Contribution already under challenge");
        
        uint256 requiredBond = (evolutionCostFragments * challengeBondRateBasisPoints) / 10000;
        require(bondAmount >= requiredBond, "CognitiveForgeNexus: Insufficient bond amount");

        _transferFragments(msg.sender, address(this), bondAmount); // Challenger's bond transferred to contract
        contribution.isChallenged = true;
        contribution.challengeCount++;
        // In a more complex system, bonds from multiple challengers would be tracked individually.
        // Here, we simplify by just transferring to the contract and assuming `resolveChallenge`
        // handles the distribution of all collected bonds.

        emit ContributionChallenged(contributionId, msg.sender, bondAmount);
    }

    /**
     * @notice Resolves a challenge on a contribution, distributing bonds.
     * @dev This function can only be called by the AI Oracle or Protocol Owner (admin).
     * @param contributionId The ID of the challenged contribution.
     * @param isValid True if the contribution is deemed valid, false if invalid by the resolver.
     * @param bondDistributors Addresses to distribute (refund/forfeit) challenge bonds to.
     * @param bondAmounts The corresponding amounts to distribute to each distributor.
     */
    function resolveChallenge(
        uint256 contributionId,
        bool isValid,
        address[] memory bondDistributors,
        uint256[] memory bondAmounts
    ) public onlyAIOracle whenNotPaused { // onlyAIOracle or onlyOwner, depending on governance
        Contribution storage contribution = contributions[contributionId];
        require(contribution.isChallenged, "CognitiveForgeNexus: Contribution is not challenged");

        contribution.isChallenged = false; // Challenge resolved

        uint256 totalBondRefunded = 0;
        uint256 totalBondForfeited = 0; // Forfeited to protocol or other beneficiaries

        require(bondDistributors.length == bondAmounts.length, "CognitiveForgeNexus: Bond arrays length mismatch");
        for (uint256 i = 0; i < bondDistributors.length; i++) {
            // This distribution mechanism is simplified. A robust system would track individual
            // challenger/contributor bonds and distribute based on specific outcome rules.
            // For this example, we simply transfer the determined amounts.
            _transferFragments(address(this), bondDistributors[i], bondAmounts[i]);
            
            // Update influence based on challenge outcome
            if (isValid) { // Challenger was wrong, contributor/endorsers are right
                if(bondDistributors[i] == contribution.contributor) influenceScores[bondDistributors[i]] += 5;
                // Track total forfeited (simplified, as actual bond source not tracked here)
                totalBondForfeited += bondAmounts[i]; 
            } else { // Challenger was right, contributor was wrong
                if(bondDistributors[i] == msg.sender) influenceScores[bondDistributors[i]] += 5; // Challenger gets influence
                // Track total refunded (simplified)
                totalBondRefunded += bondAmounts[i];
            }
            emit InfluenceUpdated(bondDistributors[i], influenceScores[bondDistributors[i]]);
        }

        emit ChallengeResolved(contributionId, isValid, msg.sender, totalBondRefunded, totalBondForfeited);
    }

    // --- VII. Protocol Economics & Incentives ---

    /**
     * @notice Admin sets the base cost in Cognitive Fragments for AI evolution requests.
     * @param newCost The new cost in fragments (must be greater than zero).
     */
    function setEvolutionCost(uint256 newCost) public onlyOwner {
        require(newCost > 0, "CognitiveForgeNexus: Evolution cost must be positive");
        evolutionCostFragments = newCost;
    }

    /**
     * @notice Admin sets the reward multiplier for successful endorsements.
     *         This rate is used by the AI oracle during reward distribution (e.g., as a base for calculations).
     * @param rate The new endorsement reward rate.
     */
    function setEndorsementRewardRate(uint256 rate) public onlyOwner {
        endorsementRewardRate = rate;
    }

    /**
     * @notice Admin sets the percentage (in basis points) of the evolution cost required as a bond to challenge.
     * @param rateBasisPoints The new challenge bond rate in basis points (e.g., 1000 for 10%, 10000 for 100%).
     */
    function setChallengeBondRate(uint256 rateBasisPoints) public onlyOwner {
        require(rateBasisPoints <= 10000, "CognitiveForgeNexus: Rate cannot exceed 100%");
        challengeBondRateBasisPoints = rateBasisPoints;
    }

    // --- VIII. Governance & Future Expansion (Simplified) ---

    /**
     * @notice Allows users with sufficient influence to propose changes to protocol parameters.
     * @param description A brief description of the proposal.
     * @param targetContract The address of the contract to call (e.g., `address(this)` for self-modification).
     * @param callData The encoded function call to be executed if the proposal passes.
     * @param votingPeriodDays The duration of the voting period in days.
     * @param minInfluenceForVoteThreshold Minimum total votes (influence) required for proposal to pass.
     */
    function proposeParameterChange(
        string memory description,
        address targetContract,
        bytes memory callData,
        uint256 votingPeriodDays,
        uint256 minInfluenceForVoteThreshold
    ) public whenNotPaused {
        // Require a minimum influence to propose
        require(getInfluenceScore(msg.sender) >= 50, "CognitiveForgeNexus: Insufficient influence to propose");
        require(targetContract != address(0), "CognitiveForgeNexus: Target contract cannot be zero address");
        require(bytes(callData).length > 0, "CognitiveForgeNexus: Call data cannot be empty");
        require(votingPeriodDays > 0, "CognitiveForgeNexus: Voting period must be positive");
        require(minInfluenceForVoteThreshold > 0, "CognitiveForgeNexus: Vote threshold must be positive");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: description,
            callData: callData,
            targetContract: targetContract,
            voteThreshold: minInfluenceForVoteThreshold,
            votesFor: 0,
            votesAgainst: 0,
            creationTimestamp: block.timestamp,
            endTimestamp: block.timestamp + (votingPeriodDays * 1 days),
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize mapping within struct for this proposal
        });

        emit ProposalCreated(proposalId, description, proposals[proposalId].endTimestamp);
    }

    /**
     * @notice Allows users with influence to vote on active proposals.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTimestamp > 0, "CognitiveForgeNexus: Proposal does not exist");
        require(block.timestamp <= proposal.endTimestamp, "CognitiveForgeNexus: Voting period has ended");
        require(!proposal.executed, "CognitiveForgeNexus: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "CognitiveForgeNexus: Already voted on this proposal");

        uint256 voterInfluence = getInfluenceScore(msg.sender);
        require(voterInfluence > 0, "CognitiveForgeNexus: Voter has no influence");

        if (support) {
            proposal.votesFor += voterInfluence;
        } else {
            proposal.votesAgainst += voterInfluence;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Executes a passed proposal. Only callable after the voting period ends and if conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTimestamp > 0, "CognitiveForgeNexus: Proposal does not exist");
        require(block.timestamp > proposal.endTimestamp, "CognitiveForgeNexus: Voting period not ended yet");
        require(!proposal.executed, "CognitiveForgeNexus: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "CognitiveForgeNexus: No votes cast on this proposal");

        // Simple majority and threshold check
        require(
            proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= proposal.voteThreshold,
            "CognitiveForgeNexus: Proposal did not pass"
        );

        proposal.executed = true;

        // Execute the proposal's call data using low-level call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "CognitiveForgeNexus: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }
}
```