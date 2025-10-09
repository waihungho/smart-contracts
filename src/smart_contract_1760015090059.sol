The `VeritasProtocol` is a sophisticated Solidity smart contract designed to establish an on-chain, community-validated knowledge graph. It enables users to submit "assertions" (knowledge snippets), which then undergo a reputation-weighted validation process. Successful validation leads to the creation of Soulbound Knowledge Attestations (SKAs) for the individual contributors and allows for bundling multiple validated assertions into dynamic, transferable Veri-NFTs. The protocol incorporates staking, slashing, and linking mechanisms to foster a robust, verifiable, and interconnected knowledge base, promoting decentralized science (DeSci) and verifiable information in the Web3 ecosystem.

**Key Advanced Concepts & Features:**

*   **On-chain Knowledge Graph:** Assertions can be linked to each other, forming a directed graph that represents relationships between pieces of knowledge directly on the blockchain.
*   **Reputation-Weighted Validation:** Participants stake "Veritas Points" (VPs) to vote on the veracity of assertions. The weight of their vote is directly proportional to their staked VPs, incentivizing honest and knowledgeable participation.
*   **Staking & Slashing:** VPs are staked during challenges. Correct voters are rewarded with VPs and a share of ETH from the treasury (funded by protocol fees/deposits), while incorrect voters are penalized by having a portion of their staked VPs slashed.
*   **Soulbound Knowledge Attestations (SKAs):** Upon successful validation of an assertion they submitted, contributors receive a non-transferable SKA, serving as an on-chain credential for their contribution and expertise.
*   **Dynamic Veri-NFTs:** Bundles of validated assertions can be minted as transferable ERC-721 tokens. Their metadata URI is dynamic, potentially reflecting the current validation status of their contained assertions, allowing for "living" NFTs that adapt to new information.
*   **Challenge-Based Consensus:** A multi-stage validation and dispute system where assertions move through `Pending`, `Challenged`, `Validated`, and `Invalidated` states based on community voting.
*   **Decentralized Treasury:** A contract-owned treasury that accumulates ETH (e.g., from fees, donations) to fund rewards for successful validators and disputers.

---

### **Veritas Protocol: Decentralized Knowledge Graph & Attestation Engine**

**Outline:**
The Veritas Protocol establishes an on-chain, community-validated knowledge graph. Users submit "assertions" (knowledge snippets), which undergo a reputation-weighted validation process. Successful assertions lead to the creation of Soulbound Knowledge Attestations (SKAs) for the contributor and can be bundled into transferable Veri-NFTs. The system incorporates staking, slashing, and linking mechanics to foster a robust, verifiable, and interconnected knowledge base, promoting decentralized science and verifiable information.

**Function Summary:**

---

### **I. Knowledge Assertion Management (Content & Structure)**

1.  `submitAssertion(string memory _contentHash, string memory _statement, string[] memory _tags, uint256[] memory _linkedAssertionIds)`
    *   **Description:** Submits a new knowledge assertion to the protocol. It includes a content hash (e.g., IPFS), a human-readable statement, relevant tags for categorization, and an array of IDs of existing assertions that this new assertion logically links to. The assertion initially enters a `Pending` state awaiting community validation.
    *   **Advanced Concept:** On-chain Knowledge Graph node creation.
    *   **Event:** `AssertionSubmitted`

2.  `getAssertionDetails(uint256 _assertionId)`
    *   **Description:** Retrieves comprehensive details of a specific knowledge assertion, including its submitter, content hash, statement, tags, timestamp, linked assertions, current status, and any active challenge ID.
    *   **Advanced Concept:** Querying graph nodes and their metadata.

3.  `linkAssertions(uint256 _fromAssertionId, uint256 _toAssertionId)`
    *   **Description:** Establishes a directed link from one existing assertion to another. This function allows for building the knowledge graph by defining relationships between different knowledge units. Requires both assertions to exist and prevents duplicate links.
    *   **Advanced Concept:** On-chain Knowledge Graph edge creation.
    *   **Event:** `AssertionLinked`

4.  `getAssertionLinks(uint256 _assertionId)`
    *   **Description:** Returns an array of assertion IDs that are directly linked *from* the specified assertion. This helps in traversing the knowledge graph.
    *   **Advanced Concept:** Querying graph edges.

---

### **II. Reputation (Veritas Points - VPs)**

5.  `stakeVeritasPoints(uint256 _amount)`
    *   **Description:** Allows a user to lock a specified amount of their Veritas Points (VPs). Staked VPs contribute to a user's voting weight in validation and dispute challenges, enabling them to earn rewards.
    *   **Advanced Concept:** Reputation staking for influence.
    *   **Event:** `VeritasPointsStaked`

6.  `unstakeVeritasPoints(uint256 _amount)`
    *   **Description:** Allows a user to unlock a specified amount of their staked VPs. This action is subject to a protocol-defined cooldown period to prevent rapid shifts in voting power during active challenges.
    *   **Advanced Concept:** Cooldown mechanism for reputation management.
    *   **Event:** `VeritasPointsUnstaked`

7.  `getVeritasPointsBalance(address _account)`
    *   **Description:** Returns the total Veritas Points balance for a given address. This includes both available (unstaked) and currently staked VPs.
    *   **Advanced Concept:** Non-transferable internal reputation token balance.

---

### **III. Assertion Validation & Dispute Lifecycle**

8.  `proposeValidationChallenge(uint256 _assertionId, uint256 _stakeAmount)`
    *   **Description:** Initiates a challenge phase for an assertion that is either `Pending` or `Invalidated`. Proposers must commit a minimum stake of VPs. The challenge begins a voting period where stakers decide on the assertion's truthfulness.
    *   **Advanced Concept:** Prediction market-like mechanism for truth-finding.
    *   **Event:** `ValidationChallengeProposed`, `VoteCast` (for proposer's initial vote)

9.  `voteOnValidationChallenge(uint256 _challengeId, bool _isTrue, uint256 _stakeAmount)`
    *   **Description:** Allows users with staked VPs to cast a vote on an active validation challenge. Voters commit additional VPs to support their 'True' or 'False' vote.
    *   **Advanced Concept:** Reputation-weighted voting.
    *   **Event:** `VoteCast`

10. `finalizeValidationChallenge(uint256 _challengeId)`
    *   **Description:** Concludes a validation challenge after its voting period ends. The assertion's status is updated based on the majority vote. Winning voters receive ETH rewards and additional VPs, while losing voters have a portion of their staked VPs slashed. A Soulbound Knowledge Attestation (SKA) is minted to the original submitter if the assertion is validated.
    *   **Advanced Concept:** Slashing & reward distribution, automated state transitions, Soulbound Token minting trigger.
    *   **Event:** `ValidationChallengeFinalized`, `VeritasPointsMinted`, `TreasuryWithdrawal` (internal to `_distributeRewardsAndSlash`)

11. `proposeDispute(uint256 _assertionId, string memory _reason, uint256 _stakeAmount)`
    *   **Description:** Initiates a dispute against an *already validated* assertion. This allows the community to re-evaluate assertions if new information or evidence suggests they might be incorrect. The proposer must provide a reason and stake VPs.
    *   **Advanced Concept:** Continuous auditing/truth-refinement for the knowledge base.
    *   **Event:** `DisputeProposed`, `VoteCast` (for proposer's initial vote)

12. `voteOnDispute(uint256 _disputeId, bool _isIncorrect, uint256 _stakeAmount)`
    *   **Description:** Allows users to cast a vote on an active dispute challenge. Voters commit VPs to indicate whether they believe the assertion is 'Incorrect' (supporting the dispute) or 'Correct' (rejecting the dispute).
    *   **Advanced Concept:** Counter-argumentation and truth-refinement through voting.
    *   **Event:** `VoteCast`

13. `finalizeDispute(uint256 _disputeId)`
    *   **Description:** Concludes a dispute challenge. If the dispute passes (majority votes 'Incorrect'), the assertion's status is changed to `Invalidated`. Rewards and slashes are distributed similarly to validation challenges, based on the dispute's outcome.
    *   **Advanced Concept:** Adaptive knowledge base, reflecting evolving consensus.
    *   **Event:** `DisputeFinalized`, `VeritasPointsMinted`, `TreasuryWithdrawal` (internal to `_distributeRewardsAndSlash`)

---

### **IV. Knowledge Attestations (SKAs & Veri-NFTs)**

14. `mintSoulboundAttestation(uint256 _assertionId)`
    *   **Description:** Mints a non-transferable Soulbound Knowledge Attestation (SKA) to the original contributor of an assertion, upon its successful validation. This function is typically called internally by `finalizeValidationChallenge`.
    *   **Advanced Concept:** Soulbound Tokens (SBTs) for on-chain identity and reputation.
    *   **Event:** `SoulboundAttestationMinted`

15. `bundleAndMintVeriNFT(uint256[] memory _assertionIds, string memory _nftName, string memory _nftSymbol, string memory _baseURI)`
    *   **Description:** Mints a new, transferable Veri-NFT (an ERC-721 token) that bundles multiple *validated* knowledge assertions. This allows for the creation of composite knowledge assets.
    *   **Advanced Concept:** Dynamic NFTs, composable on-chain knowledge.
    *   **Event:** `VeriNFTMinted`

16. `getVeriNFTAssertions(uint256 _tokenId)`
    *   **Description:** Returns the array of assertion IDs that are bundled within a specific Veri-NFT, allowing users to inspect the knowledge content of the NFT.
    *   **Advanced Concept:** Introspection of NFT content.

17. `tokenURI(uint256 _tokenId)`
    *   **Description:** Overrides the standard ERC721 `tokenURI` function. It dynamically generates the metadata URI for a Veri-NFT, potentially reflecting the current validation status of its bundled assertions. For example, it might include an indicator of whether any bundled assertion has been `Invalidated`.
    *   **Advanced Concept:** Dynamic NFT metadata, reflecting underlying on-chain state changes.
    *   **Event:** (Implicitly `VeriNFTMetadataUpdated` if a real external update occurs, but this is a `view` function)

---

### **V. Protocol Governance & Treasury**

18. `depositToTreasury()`
    *   **Description:** Allows any user or contract to send ETH to the Veritas Protocol's treasury. These funds are used to reward participants in validation and dispute challenges.
    *   **Advanced Concept:** Community-funded decentralized treasury.
    *   **Event:** `TreasuryDeposit`

19. `withdrawFromTreasury(address _to, uint256 _amount)`
    *   **Description:** Allows the designated governance address (the contract owner in this implementation) to withdraw a specified amount of ETH from the protocol's treasury to a target address.
    *   **Advanced Concept:** Access-controlled treasury management.
    *   **Event:** `TreasuryWithdrawal`

20. `setProtocolParameters(uint256 _challengeDuration, uint256 _minChallengeStake, uint256 _validationRewardRate, uint256 _disputeRewardRate, uint256 _slashFactor, uint256 _unstakeCooldownPeriod)`
    *   **Description:** Enables the governance address to configure critical operational parameters of the protocol. This includes the duration of challenges, minimum stakes required, reward rates for validation/disputes, the slashing factor for incorrect voters, and the cooldown period for unstaking VPs.
    *   **Advanced Concept:** On-chain parameter governance.
    *   **Event:** `ProtocolParametersSet`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 

// Outline:
// The Veritas Protocol establishes an on-chain, community-validated knowledge graph. Users submit "assertions" (knowledge snippets),
// which undergo a reputation-weighted validation process. Successful assertions lead to the creation of Soulbound Knowledge Attestations (SKAs)
// for the contributor and can be bundled into transferable Veri-NFTs. The system incorporates staking, slashing, and linking mechanics
// to foster a robust, verifiable, and interconnected knowledge base, promoting decentralized science and verifiable information.

// Function Summary:

// I. Knowledge Assertion Management (Content & Structure)
// 1. submitAssertion(string memory _contentHash, string memory _statement, string[] memory _tags, uint256[] memory _linkedAssertionIds)
//    Submits a new knowledge assertion with a content hash, human-readable statement, tags, and links to existing assertions.
// 2. getAssertionDetails(uint256 _assertionId)
//    Retrieves comprehensive details of a specific knowledge assertion.
// 3. linkAssertions(uint256 _fromAssertionId, uint256 _toAssertionId)
//    Establishes a directed link between two assertions, representing a relationship.
// 4. getAssertionLinks(uint256 _assertionId)
//    Returns all assertions linked from a given assertion.

// II. Reputation (Veritas Points - VPs)
// 5. stakeVeritasPoints(uint256 _amount)
//    Locks VPs to participate in validation, earn rewards, and increase voting weight.
// 6. unstakeVeritasPoints(uint256 _amount)
//    Unlocks staked VPs after a cool-down period.
// 7. getVeritasPointsBalance(address _account)
//    Returns the total VPs (staked + available) for an account.

// III. Assertion Validation & Dispute Lifecycle
// 8. proposeValidationChallenge(uint256 _assertionId, uint256 _stakeAmount)
//    Initiates a challenge phase for an assertion, requiring stakers to vote on its veracity.
// 9. voteOnValidationChallenge(uint256 _challengeId, bool _isTrue, uint256 _stakeAmount)
//    Casts a vote (true/false) on an active validation challenge, committing a stake.
// 10. finalizeValidationChallenge(uint256 _challengeId)
//     Concludes a validation challenge, distributing rewards/slashing stakes based on the majority vote and minting SKAs/Veri-NFTs.
// 11. proposeDispute(uint256 _assertionId, string memory _reason, uint256 _stakeAmount)
//     Initiates a dispute against an *already validated* assertion, flagging it for re-evaluation.
// 12. voteOnDispute(uint256 _disputeId, bool _isIncorrect, uint256 _stakeAmount)
//     Casts a vote (incorrect/correct) on an active dispute, committing a stake.
// 13. finalizeDispute(uint256 _disputeId)
//     Concludes a dispute, potentially revoking validation status, distributing rewards/slashing, and updating Veri-NFT metadata.

// IV. Knowledge Attestations (SKAs & Veri-NFTs)
// 14. mintSoulboundAttestation(uint256 _assertionId)
//     Mints a non-transferable SKA to the assertion's original contributor upon successful validation.
// 15. bundleAndMintVeriNFT(uint256[] memory _assertionIds, string memory _nftName, string memory _nftSymbol, string memory _baseURI)
//     Mints a transferable Veri-NFT, bundling multiple *validated* assertions into a single token.
// 16. getVeriNFTAssertions(uint256 _tokenId)
//     Returns the list of assertion IDs contained within a specific Veri-NFT.
// 17. tokenURI(uint256 _tokenId)
//     Overrides the ERC721 tokenURI function to provide a dynamic URI for a Veri-NFT, potentially reflecting its bundled assertions' status.

// V. Protocol Governance & Treasury
// 18. depositToTreasury()
//     Allows anyone to contribute ETH to the protocol's treasury.
// 19. withdrawFromTreasury(address _to, uint256 _amount)
//     Allows the designated governance address (owner) to withdraw funds from the treasury.
// 20. setProtocolParameters(uint256 _challengeDuration, uint256 _minChallengeStake, uint256 _validationRewardRate, uint256 _disputeRewardRate, uint256 _slashFactor, uint256 _unstakeCooldownPeriod)
//     Allows governance to configure key protocol parameters like challenge durations, minimum stakes, reward rates, and slashing factors.

contract VeritasProtocol is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256; 

    // --- State Variables ---

    // 1. Assertion Management
    struct Assertion {
        address submitter;
        string contentHash; // IPFS hash or similar for actual content
        string statement;   // Human-readable summary
        string[] tags;
        uint256 timestamp;
        uint256[] linkedAssertions; // IDs of other assertions this one links to
        Status status;              // Current validation status
        uint256 currentChallengeId; // ID of active validation/dispute challenge, 0 if none
    }

    enum Status {
        Pending,     // Just submitted, awaiting validation
        Challenged,  // Undergoing validation or dispute
        Validated,   // Approved by community
        Invalidated  // Deemed false/incorrect by community
    }

    mapping(uint256 => Assertion) public assertions;
    Counters.Counter private _assertionIds;

    // 2. Reputation (Veritas Points - VPs)
    mapping(address => uint256) private _veritasPoints; // Total VPs (available + staked). Non-transferable.
    mapping(address => uint256) private _stakedVeritasPoints;
    mapping(address => uint256) private _lastUnstakeTime; // For cooldown

    uint256 public UNSTAKE_COOLDOWN_PERIOD; // settable by governance

    // 3. Validation & Dispute Challenges
    struct Challenge {
        uint256 assertionId;
        address proposer;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 totalYesWeight; // Sum of VPs staked by 'Yes' voters
        uint256 totalNoWeight;  // Sum of VPs staked by 'No' voters
        address[] voters; // List of all addresses that voted in this challenge (for iteration)
        mapping(address => uint256) voterStakes; // user => staked amount in this challenge
        mapping(address => bool) voterVotes;     // user => true (Yes/True) / false (No/False)
        bool isValidationChallenge; // true for validation, false for dispute
        bool finalized;
    }

    mapping(uint256 => Challenge) public challenges;
    Counters.Counter private _challengeIds;

    uint256 public challengeDuration;   // settable by governance
    uint256 public minChallengeStake;   // settable by governance

    // Reward/Penalty Configuration (settable by governance)
    uint256 public validationRewardRate; // ETH reward per VP for correct validation
    uint256 public disputeRewardRate;    // ETH reward per VP for successful dispute
    uint256 public slashFactor;          // Factor by which losing stakes are slashed (e.g., 2 = 50% slash means lose 50%)

    // 4. Knowledge Attestations (SKAs & Veri-NFTs)
    // SKAs (Soulbound Knowledge Attestations) - non-transferable, custom mapping
    mapping(address => mapping(uint256 => bool)) public soulboundAttestations; // owner => assertionId => exists

    // Veri-NFTs (ERC-721 based)
    mapping(uint256 => uint256[]) public veriNftBundledAssertions; // tokenId => list of assertionIds
    Counters.Counter private _nextTokenId; // ERC721's internal counter
    mapping(uint256 => string) private _tokenURIs; // For per-token metadata URI. ERC721's `_setTokenURI` uses this implicitly.

    // --- Events ---
    event AssertionSubmitted(uint256 indexed assertionId, address indexed submitter, string contentHash, string statement);
    event AssertionLinked(uint256 indexed fromAssertionId, uint256 indexed toAssertionId);
    event VeritasPointsMinted(address indexed receiver, uint256 amount);
    event VeritasPointsStaked(address indexed user, uint256 amount);
    event VeritasPointsUnstaked(address indexed user, uint256 amount);
    event ValidationChallengeProposed(uint256 indexed challengeId, uint256 indexed assertionId, address indexed proposer);
    event VoteCast(uint256 indexed challengeId, address indexed voter, bool vote, uint256 stakeAmount, uint256 voterVPWeight);
    event ValidationChallengeFinalized(uint256 indexed challengeId, uint256 indexed assertionId, bool result, uint256 totalYesWeight, uint256 totalNoWeight);
    event DisputeProposed(uint256 indexed disputeId, uint256 indexed assertionId, address indexed proposer, string reason);
    event DisputeFinalized(uint256 indexed disputeId, uint256 indexed assertionId, bool result, uint256 totalYesWeight, uint256 totalNoWeight);
    event SoulboundAttestationMinted(address indexed owner, uint256 indexed assertionId);
    event VeriNFTMinted(uint256 indexed tokenId, address indexed owner, uint256[] assertionIds);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed receiver, uint256 amount);
    event ProtocolParametersSet(
        uint256 _challengeDuration,
        uint256 _minChallengeStake,
        uint256 _validationRewardRate,
        uint256 _disputeRewardRate,
        uint256 _slashFactor,
        uint256 _unstakeCooldownPeriod
    );

    // --- Constructor ---
    /// @dev Initializes the contract with ERC721 name/symbol and sets initial governance parameters.
    /// @param initialOwner The address of the initial governance controller.
    /// @param _initialChallengeDuration Default duration for challenges in seconds.
    /// @param _initialMinChallengeStake Default minimum stake to participate in challenges (in VPs, scaled by 10**18).
    /// @param _initialValidationRewardRate Default reward rate for correct validation (in ETH per VP staked).
    /// @param _initialDisputeRewardRate Default reward rate for successful disputes (in ETH per VP staked).
    /// @param _initialSlashFactor Default factor for slashing losing stakes (e.2. 2 means 50% slash).
    /// @param _initialUnstakeCooldownPeriod Default cooldown period for unstaking VPs in seconds.
    constructor(
        address initialOwner,
        uint256 _initialChallengeDuration,
        uint256 _initialMinChallengeStake,
        uint256 _initialValidationRewardRate,
        uint256 _initialDisputeRewardRate,
        uint256 _initialSlashFactor,
        uint256 _initialUnstakeCooldownPeriod
    ) ERC721("VeriNFT", "VNFT") Ownable(initialOwner) {
        challengeDuration = _initialChallengeDuration;
        minChallengeStake = _initialMinChallengeStake;
        validationRewardRate = _initialValidationRewardRate;
        disputeRewardRate = _initialDisputeRewardRate;
        slashFactor = _initialSlashFactor;
        UNSTAKE_COOLDOWN_PERIOD = _initialUnstakeCooldownPeriod;

        // Mint some initial VPs to the owner for bootstrapping the system
        _mintVeritasPoints(initialOwner, 1000 ether); // Example: 1000 VPs (with 18 decimals) for the owner
    }

    // --- Internal VPs Management (Not exposed as part of the 20 main functions) ---
    function _mintVeritasPoints(address _to, uint256 _amount) internal {
        _veritasPoints[_to] = _veritasPoints[_to].add(_amount);
        emit VeritasPointsMinted(_to, _amount);
    }

    function _burnVeritasPoints(address _from, uint256 _amount) internal {
        _veritasPoints[_from] = _veritasPoints[_from].sub(_amount);
        // Ensure staked points are also reduced if overall balance drops below staked
        if (_stakedVeritasPoints[_from] > _veritasPoints[_from]) {
            _stakedVeritasPoints[_from] = _veritasPoints[_from];
        }
    }

    // --- I. Knowledge Assertion Management ---

    /// @notice Submits a new knowledge assertion to the protocol.
    /// @param _contentHash IPFS hash or similar identifier for the full assertion content.
    /// @param _statement A concise, human-readable summary or direct statement of the assertion.
    /// @param _tags An array of keywords to categorize the assertion.
    /// @param _linkedAssertionIds An array of IDs of existing assertions that this new assertion links to.
    /// @return The unique ID of the newly submitted assertion.
    function submitAssertion(
        string memory _contentHash,
        string memory _statement,
        string[] memory _tags,
        uint256[] memory _linkedAssertionIds
    ) external returns (uint256) {
        _assertionIds.increment();
        uint256 newId = _assertionIds.current();

        for (uint256 i = 0; i < _linkedAssertionIds.length; i++) {
            require(_linkedAssertionIds[i] > 0 && assertions[_linkedAssertionIds[i]].submitter != address(0), "VeritasProtocol: Linked assertion does not exist");
        }

        assertions[newId] = Assertion({
            submitter: _msgSender(),
            contentHash: _contentHash,
            statement: _statement,
            tags: _tags,
            timestamp: block.timestamp,
            linkedAssertions: _linkedAssertionIds,
            status: Status.Pending,
            currentChallengeId: 0
        });

        emit AssertionSubmitted(newId, _msgSender(), _contentHash, _statement);
        return newId;
    }

    /// @notice Retrieves comprehensive details of a specific knowledge assertion.
    /// @param _assertionId The ID of the assertion to retrieve.
    /// @return A tuple containing all assertion details.
    function getAssertionDetails(uint256 _assertionId)
        external
        view
        returns (
            address submitter,
            string memory contentHash,
            string memory statement,
            string[] memory tags,
            uint256 timestamp,
            uint256[] memory linkedAssertions,
            Status status,
            uint256 currentChallengeId
        )
    {
        require(_assertionId > 0 && assertions[_assertionId].submitter != address(0), "VeritasProtocol: Assertion does not exist");
        Assertion storage assertion = assertions[_assertionId];
        return (
            assertion.submitter,
            assertion.contentHash,
            assertion.statement,
            assertion.tags,
            assertion.timestamp,
            assertion.linkedAssertions,
            assertion.status,
            assertion.currentChallengeId
        );
    }

    /// @notice Establishes a directed link from one assertion to another.
    /// @param _fromAssertionId The ID of the assertion initiating the link.
    /// @param _toAssertionId The ID of the assertion being linked to.
    function linkAssertions(uint256 _fromAssertionId, uint256 _toAssertionId) external {
        require(_fromAssertionId > 0 && assertions[_fromAssertionId].submitter != address(0), "VeritasProtocol: From assertion does not exist");
        require(_toAssertionId > 0 && assertions[_toAssertionId].submitter != address(0), "VeritasProtocol: To assertion does not exist");
        require(_fromAssertionId != _toAssertionId, "VeritasProtocol: Cannot link an assertion to itself");

        Assertion storage fromAssertion = assertions[_fromAssertionId];
        // Ensure the link doesn't already exist to prevent duplicates
        for (uint256 i = 0; i < fromAssertion.linkedAssertions.length; i++) {
            require(fromAssertion.linkedAssertions[i] != _toAssertionId, "VeritasProtocol: Assertions are already linked");
        }

        fromAssertion.linkedAssertions.push(_toAssertionId);
        emit AssertionLinked(_fromAssertionId, _toAssertionId);
    }

    /// @notice Returns all assertions linked *from* a given assertion.
    /// @param _assertionId The ID of the assertion whose links are to be retrieved.
    /// @return An array of assertion IDs that are linked from the given assertion.
    function getAssertionLinks(uint256 _assertionId) external view returns (uint256[] memory) {
        require(_assertionId > 0 && assertions[_assertionId].submitter != address(0), "VeritasProtocol: Assertion does not exist");
        return assertions[_assertionId].linkedAssertions;
    }

    // --- II. Reputation (Veritas Points - VPs) ---

    /// @notice Stakes Veritas Points (VPs) to participate in validation and disputes.
    /// @param _amount The amount of VPs to stake.
    function stakeVeritasPoints(uint256 _amount) external {
        require(_amount > 0, "VeritasProtocol: Stake amount must be greater than zero");
        require(_veritasPoints[_msgSender()] >= _stakedVeritasPoints[_msgSender()].add(_amount), "VeritasProtocol: Insufficient available VPs");

        _stakedVeritasPoints[_msgSender()] = _stakedVeritasPoints[_msgSender()].add(_amount);
        emit VeritasPointsStaked(_msgSender(), _amount);
    }

    /// @notice Unstakes Veritas Points (VPs) after a cooldown period.
    /// @param _amount The amount of VPs to unstake.
    function unstakeVeritasPoints(uint256 _amount) external {
        require(_amount > 0, "VeritasProtocol: Unstake amount must be greater than zero");
        require(_stakedVeritasPoints[_msgSender()] >= _amount, "VeritasProtocol: Not enough VPs staked");
        require(block.timestamp >= _lastUnstakeTime[_msgSender()].add(UNSTAKE_COOLDOWN_PERIOD), "VeritasProtocol: Unstake cooldown in progress");

        _stakedVeritasPoints[_msgSender()] = _stakedVeritasPoints[_msgSender()].sub(_amount);
        _lastUnstakeTime[_msgSender()] = block.timestamp; // Reset cooldown after any unstake
        emit VeritasPointsUnstaked(_msgSender(), _amount);
    }

    /// @notice Returns the total Veritas Points (available + staked) for an account.
    /// @param _account The address to query.
    /// @return The total VPs for the account.
    function getVeritasPointsBalance(address _account) external view returns (uint256) {
        return _veritasPoints[_account];
    }

    // --- III. Assertion Validation & Dispute Lifecycle ---

    /// @notice Initiates a challenge phase for an assertion, requiring stakers to vote on its veracity.
    ///         Only assertions in `Pending` or `Invalidated` status can be challenged for validation.
    /// @param _assertionId The ID of the assertion to challenge.
    /// @param _stakeAmount The amount of VPs to stake for proposing this challenge.
    /// @return The unique ID of the newly created validation challenge.
    function proposeValidationChallenge(uint256 _assertionId, uint256 _stakeAmount) external nonReentrant returns (uint256) {
        require(_assertionId > 0 && assertions[_assertionId].submitter != address(0), "VeritasProtocol: Assertion does not exist");
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.status == Status.Pending || assertion.status == Status.Invalidated, "VeritasProtocol: Assertion not in a state to be validated");
        require(assertion.currentChallengeId == 0, "VeritasProtocol: Assertion already has an active challenge");
        require(_stakeAmount >= minChallengeStake, "VeritasProtocol: Stake amount too low");
        require(_stakedVeritasPoints[_msgSender()] >= _stakeAmount, "VeritasProtocol: Insufficient staked VPs");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            assertionId: _assertionId,
            proposer: _msgSender(),
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(challengeDuration),
            totalYesWeight: _stakeAmount, // Proposer effectively votes 'Yes' by proposing
            totalNoWeight: 0,
            voters: new address[](0), // Initialize empty array
            isValidationChallenge: true,
            finalized: false
        });

        // Record proposer's vote
        challenges[newChallengeId].voterStakes[_msgSender()] = _stakeAmount;
        challenges[newChallengeId].voterVotes[_msgSender()] = true; // Proposer implicitly votes 'True' for validation
        challenges[newChallengeId].voters.push(_msgSender());

        assertion.status = Status.Challenged;
        assertion.currentChallengeId = newChallengeId;

        emit ValidationChallengeProposed(newChallengeId, _assertionId, _msgSender());
        emit VoteCast(newChallengeId, _msgSender(), true, _stakeAmount, _stakeAmount); // Proposer's initial vote
        return newChallengeId;
    }

    /// @notice Casts a vote (true/false) on an active validation challenge, committing a stake.
    /// @param _challengeId The ID of the active challenge.
    /// @param _isTrue The vote (true for correct, false for incorrect).
    /// @param _stakeAmount The amount of VPs to commit to this vote.
    function voteOnValidationChallenge(uint256 _challengeId, bool _isTrue, uint256 _stakeAmount) external nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.assertionId != 0, "VeritasProtocol: Challenge does not exist");
        require(challenge.isValidationChallenge, "VeritasProtocol: Not a validation challenge");
        require(!challenge.finalized, "VeritasProtocol: Challenge already finalized");
        require(block.timestamp < challenge.endTimestamp, "VeritasProtocol: Challenge voting period has ended");
        require(challenge.voterStakes[_msgSender()] == 0, "VeritasProtocol: Already voted in this challenge");
        require(_stakeAmount >= minChallengeStake, "VeritasProtocol: Stake amount too low");
        require(_stakedVeritasPoints[_msgSender()] >= _stakeAmount, "VeritasProtocol: Insufficient staked VPs");

        // Record vote
        challenge.voterStakes[_msgSender()] = _stakeAmount;
        challenge.voterVotes[_msgSender()] = _isTrue;
        challenge.voters.push(_msgSender());

        if (_isTrue) {
            challenge.totalYesWeight = challenge.totalYesWeight.add(_stakeAmount);
        } else {
            challenge.totalNoWeight = challenge.totalNoWeight.add(_stakeAmount);
        }

        emit VoteCast(_challengeId, _msgSender(), _isTrue, _stakeAmount, _stakeAmount);
    }

    /// @notice Concludes a validation challenge, distributing rewards/slashing stakes based on the majority vote.
    /// @param _challengeId The ID of the challenge to finalize.
    function finalizeValidationChallenge(uint256 _challengeId) external nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.assertionId != 0, "VeritasProtocol: Challenge does not exist");
        require(challenge.isValidationChallenge, "VeritasProtocol: Not a validation challenge");
        require(!challenge.finalized, "VeritasProtocol: Challenge already finalized");
        require(block.timestamp >= challenge.endTimestamp, "VeritasProtocol: Challenge voting period has not ended yet");

        challenge.finalized = true;
        Assertion storage assertion = assertions[challenge.assertionId];
        assertion.currentChallengeId = 0; // Clear active challenge ID

        bool validationResult = challenge.totalYesWeight >= challenge.totalNoWeight; // True if 'Yes' wins or tie

        if (validationResult) {
            assertion.status = Status.Validated;
            _distributeRewardsAndSlash(challenge, true, validationRewardRate);
            // Mint SKA to original submitter upon successful validation
            _mintSoulboundAttestation(assertion.submitter, challenge.assertionId);
        } else {
            assertion.status = Status.Invalidated;
            _distributeRewardsAndSlash(challenge, false, validationRewardRate);
        }

        emit ValidationChallengeFinalized(_challengeId, challenge.assertionId, validationResult, challenge.totalYesWeight, challenge.totalNoWeight);
    }

    /// @notice Initiates a dispute against an *already validated* assertion, flagging it for re-evaluation.
    ///         Only assertions in `Validated` status can be disputed.
    /// @param _assertionId The ID of the assertion to dispute.
    /// @param _reason A brief reason for the dispute.
    /// @param _stakeAmount The amount of VPs to stake for proposing this dispute.
    /// @return The unique ID of the newly created dispute challenge.
    function proposeDispute(uint256 _assertionId, string memory _reason, uint256 _stakeAmount) external nonReentrant returns (uint256) {
        require(_assertionId > 0 && assertions[_assertionId].submitter != address(0), "VeritasProtocol: Assertion does not exist");
        Assertion storage assertion = assertions[_assertionId];
        require(assertion.status == Status.Validated, "VeritasProtocol: Assertion not in Validated state to be disputed");
        require(assertion.currentChallengeId == 0, "VeritasProtocol: Assertion already has an active challenge");
        require(_stakeAmount >= minChallengeStake, "VeritasProtocol: Stake amount too low");
        require(_stakedVeritasPoints[_msgSender()] >= _stakeAmount, "VeritasProtocol: Insufficient staked VPs");

        _challengeIds.increment();
        uint256 newDisputeId = _challengeIds.current();

        challenges[newDisputeId] = Challenge({
            assertionId: _assertionId,
            proposer: _msgSender(),
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(challengeDuration),
            totalYesWeight: 0, // 'Yes' in dispute means 'assertion is correct (no dispute)'
            totalNoWeight: _stakeAmount, // Proposer votes 'No' = 'assertion is incorrect'
            voters: new address[](0), // Initialize empty array
            isValidationChallenge: false,
            finalized: false
        });

        // Record proposer's vote
        challenges[newDisputeId].voterStakes[_msgSender()] = _stakeAmount;
        challenges[newDisputeId].voterVotes[_msgSender()] = false; // Proposer implicitly votes 'False' = 'incorrect'
        challenges[newDisputeId].voters.push(_msgSender());

        assertion.status = Status.Challenged;
        assertion.currentChallengeId = newDisputeId;

        emit DisputeProposed(newDisputeId, _assertionId, _msgSender(), _reason);
        emit VoteCast(newDisputeId, _msgSender(), false, _stakeAmount, _stakeAmount); // Proposer's initial vote
        return newDisputeId;
    }

    /// @notice Casts a vote (incorrect/correct) on an active dispute.
    /// @param _disputeId The ID of the active dispute.
    /// @param _isIncorrect The vote (true for assertion is incorrect, false for assertion is correct).
    /// @param _stakeAmount The amount of VPs to commit to this vote.
    function voteOnDispute(uint256 _disputeId, bool _isIncorrect, uint256 _stakeAmount) external nonReentrant {
        Challenge storage challenge = challenges[_disputeId];
        require(challenge.assertionId != 0, "VeritasProtocol: Challenge does not exist");
        require(!challenge.isValidationChallenge, "VeritasProtocol: Not a dispute challenge");
        require(!challenge.finalized, "VeritasProtocol: Challenge already finalized");
        require(block.timestamp < challenge.endTimestamp, "VeritasProtocol: Dispute voting period has ended");
        require(challenge.voterStakes[_msgSender()] == 0, "VeritasProtocol: Already voted in this dispute");
        require(_stakeAmount >= minChallengeStake, "VeritasProtocol: Stake amount too low");
        require(_stakedVeritasPoints[_msgSender()] >= _stakeAmount, "VeritasProtocol: Insufficient staked VPs");

        // Record vote
        challenge.voterStakes[_msgSender()] = _stakeAmount;
        challenge.voterVotes[_msgSender()] = _isIncorrect;
        challenge.voters.push(_msgSender());

        if (_isIncorrect) {
            challenge.totalNoWeight = challenge.totalNoWeight.add(_stakeAmount);
        } else {
            challenge.totalYesWeight = challenge.totalYesWeight.add(_stakeAmount);
        }

        emit VoteCast(_disputeId, _msgSender(), _isIncorrect, _stakeAmount, _stakeAmount);
    }

    /// @notice Concludes a dispute, potentially revoking validation status, distributing rewards/slashing.
    /// @param _disputeId The ID of the dispute to finalize.
    function finalizeDispute(uint256 _disputeId) external nonReentrant {
        Challenge storage challenge = challenges[_disputeId];
        require(challenge.assertionId != 0, "VeritasProtocol: Challenge does not exist");
        require(!challenge.isValidationChallenge, "VeritasProtocol: Not a dispute challenge");
        require(!challenge.finalized, "VeritasProtocol: Challenge already finalized");
        require(block.timestamp >= challenge.endTimestamp, "VeritasProtocol: Dispute voting period has not ended yet");

        challenge.finalized = true;
        Assertion storage assertion = assertions[challenge.assertionId];
        assertion.currentChallengeId = 0; // Clear active challenge ID

        // Dispute passes if 'No' (assertion is incorrect) wins or ties.
        bool disputeResult = challenge.totalNoWeight >= challenge.totalYesWeight;

        if (disputeResult) {
            assertion.status = Status.Invalidated;
            // Reward 'No' voters (who said assertion is incorrect), slash 'Yes' voters
            _distributeRewardsAndSlash(challenge, false, disputeRewardRate);
        } else {
            assertion.status = Status.Validated; // Re-affirmed as valid
            // Reward 'Yes' voters (who said assertion is correct), slash 'No' voters
            _distributeRewardsAndSlash(challenge, true, disputeRewardRate);
        }

        emit DisputeFinalized(_disputeId, challenge.assertionId, disputeResult, challenge.totalYesWeight, challenge.totalNoWeight);
    }

    /// @dev Internal helper function to distribute rewards and slash stakes based on challenge outcome.
    ///      Assumes ETH rewards are from contract balance and VP rewards/slashes affect _veritasPoints and _stakedVeritasPoints.
    /// @param _challenge The challenge struct.
    /// @param _winningVote The boolean representing the winning vote (true for Yes, false for No).
    /// @param _rewardRate The reward rate (in ETH per VP) to use.
    function _distributeRewardsAndSlash(Challenge storage _challenge, bool _winningVote, uint256 _rewardRate) internal {
        uint256 totalWinningWeight = _winningVote ? _challenge.totalYesWeight : _challenge.totalNoWeight;
        uint256 totalLosingWeight = _winningVote ? _challenge.totalNoWeight : _challenge.totalYesWeight;

        // Calculate total ETH rewards to distribute from contract treasury
        uint256 ethPoolForRewards = totalLosingWeight.mul(_rewardRate).div(1 ether); // Assuming _rewardRate is scaled by 1 ether
        
        // Cap rewards to available contract balance
        if (address(this).balance < ethPoolForRewards) {
            ethPoolForRewards = address(this).balance; 
        }

        // Calculate total VPs to slash from losers and distribute to winners
        uint256 totalVPsToSlash = totalLosingWeight.div(slashFactor); 
        uint256 totalVPsToMint = totalVPsToSlash; 

        // Iterate through all voters to distribute rewards or apply slashes
        for (uint256 i = 0; i < _challenge.voters.length; i++) {
            address voter = _challenge.voters[i];
            // Skip address 0 if it somehow got into the list (shouldn't happen with `_msgSender()` checks)
            if (voter == address(0)) continue; 

            uint256 voterStake = _challenge.voterStakes[voter];
            bool voterVotedCorrectly = (_challenge.voterVotes[voter] == _winningVote);

            if (voterVotedCorrectly) {
                // Winning voters get their stake back (implicitly by not being slashed)
                // Mint additional VPs as reward
                if (totalWinningWeight > 0) { // Avoid division by zero
                    uint256 rewardVPs = (voterStake.mul(totalVPsToMint)).div(totalWinningWeight);
                    _mintVeritasPoints(voter, rewardVPs);

                    // Distribute ETH rewards
                    uint256 ethReward = (voterStake.mul(ethPoolForRewards)).div(totalWinningWeight);
                    if (ethReward > 0) {
                        (bool success, ) = payable(voter).call{value: ethReward}("");
                        require(success, "VeritasProtocol: Failed to send ETH reward");
                    }
                }
            } else {
                // Losing voters get their staked VPs slashed
                uint256 slashedVPs = voterStake.div(slashFactor); // Amount of VPs lost
                _burnVeritasPoints(voter, slashedVPs);
                _stakedVeritasPoints[voter] = _stakedVeritasPoints[voter].sub(slashedVPs); // Reduce staked VPs directly
            }
        }
    }


    // --- IV. Knowledge Attestations (SKAs & Veri-NFTs) ---

    /// @notice Mints a non-transferable Soulbound Knowledge Attestation (SKA) to the assertion's original contributor.
    ///         This function is primarily called internally upon successful validation of an assertion.
    /// @param _recipient The address to mint the SKA to.
    /// @param _assertionId The ID of the assertion for which to mint an SKA.
    function _mintSoulboundAttestation(address _recipient, uint256 _assertionId) internal {
        require(assertions[_assertionId].submitter != address(0), "VeritasProtocol: Assertion does not exist");
        require(assertions[_assertionId].status == Status.Validated, "VeritasProtocol: Assertion not validated");
        require(!soulboundAttestations[_recipient][_assertionId], "VeritasProtocol: SKA already minted for this assertion");

        soulboundAttestations[_recipient][_assertionId] = true;
        emit SoulboundAttestationMinted(_recipient, _assertionId);
    }
    
    /// @notice Mints a non-transferable Soulbound Knowledge Attestation (SKA) to the assertion's original contributor.
    ///         This function is made public only for a direct call if needed, but intended for internal use via finalize.
    /// @param _assertionId The ID of the assertion for which to mint an SKA.
    function mintSoulboundAttestation(uint256 _assertionId) external {
        _mintSoulboundAttestation(assertions[_assertionId].submitter, _assertionId);
    }

    /// @notice Mints a transferable Veri-NFT, bundling multiple *validated* assertions into a single token.
    /// @param _assertionIds An array of IDs of validated assertions to bundle.
    /// @param _nftName The name of the Veri-NFT (for standard ERC721 metadata).
    /// @param _nftSymbol The symbol for the Veri-NFT (for standard ERC721 metadata).
    /// @param _baseURI The base URI for the Veri-NFT metadata. This will be extended by `tokenURI`.
    /// @return The unique ID of the newly minted Veri-NFT.
    function bundleAndMintVeriNFT(
        uint256[] memory _assertionIds,
        string memory _nftName, // These parameters override ERC721's internal _name and _symbol which are fixed in constructor.
        string memory _nftSymbol, // But for dynamic tokens, they can be part of metadata.
        string memory _baseURI
    ) external returns (uint256) {
        require(_assertionIds.length > 0, "VeritasProtocol: Must bundle at least one assertion");

        for (uint256 i = 0; i < _assertionIds.length; i++) {
            require(_assertionIds[i] > 0 && assertions[_assertionIds[i]].submitter != address(0), "VeritasProtocol: Assertion does not exist");
            require(assertions[_assertionIds[i]].status == Status.Validated, "VeritasProtocol: Assertion not validated");
        }

        uint256 newItemId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(_msgSender(), newItemId);
        _tokenURIs[newItemId] = _baseURI; // Store base URI, tokenURI will construct full path dynamically

        veriNftBundledAssertions[newItemId] = _assertionIds;

        emit VeriNFTMinted(newItemId, _msgSender(), _assertionIds);
        return newItemId;
    }

    /// @notice Returns the list of assertion IDs contained within a specific Veri-NFT.
    /// @param _tokenId The ID of the Veri-NFT.
    /// @return An array of assertion IDs.
    function getVeriNFTAssertions(uint256 _tokenId) external view returns (uint256[] memory) {
        require(_exists(_tokenId), "VeritasProtocol: Veri-NFT does not exist");
        return veriNftBundledAssertions[_tokenId];
    }

    /// @notice Overrides the ERC721 tokenURI function to provide a dynamic URI for a Veri-NFT.
    ///         The URI can dynamically reflect the status of its bundled assertions.
    /// @param _tokenId The ID of the Veri-NFT.
    /// @return The URI pointing to the metadata of the Veri-NFT.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _tokenURIs[_tokenId];
        
        // Example of dynamic metadata: append status of one of the assertions.
        // For simplicity, let's just use the first assertion's status if any.
        uint256[] memory bundled = veriNftBundledAssertions[_tokenId];
        if (bundled.length > 0) {
            Assertion storage firstAssertion = assertions[bundled[0]];
            string memory statusIndicator;
            if (firstAssertion.status == Status.Validated) {
                statusIndicator = "validated";
            } else if (firstAssertion.status == Status.Invalidated) {
                statusIndicator = "invalidated";
            } else {
                statusIndicator = "pending"; // Or challenged
            }
            // A more complex system would fetch all assertion statuses or build a JSON dynamically.
            return string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), "/", statusIndicator, ".json"));
        }
        return string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"));
    }

    // --- V. Protocol Governance & Treasury ---

    /// @notice Allows anyone to contribute ETH to the protocol's treasury.
    function depositToTreasury() external payable {
        require(msg.value > 0, "VeritasProtocol: Deposit amount must be greater than zero");
        emit TreasuryDeposit(_msgSender(), msg.value);
    }

    /// @notice Allows the designated governance address (owner) to withdraw funds from the treasury.
    /// @param _to The address to send the ETH to.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawFromTreasury(address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "VeritasProtocol: Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "VeritasProtocol: Insufficient balance in treasury");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "VeritasProtocol: Failed to withdraw ETH");
        emit TreasuryWithdrawal(_to, _amount);
    }

    /// @notice Allows governance to configure key protocol parameters.
    /// @param _challengeDuration_ Duration for validation/dispute challenges in seconds.
    /// @param _minChallengeStake_ Minimum VP stake to participate in challenges (scaled by 10**18).
    /// @param _validationRewardRate_ ETH reward rate for correct validation (scaled by 10**18).
    /// @param _disputeRewardRate_ ETH reward rate for successful disputes (scaled by 10**18).
    /// @param _slashFactor_ Factor by which losing stakes are slashed (e.g., 2 for 50% slash).
    /// @param _unstakeCooldownPeriod_ Cooldown period for unstaking VPs in seconds.
    function setProtocolParameters(
        uint256 _challengeDuration_,
        uint256 _minChallengeStake_,
        uint256 _validationRewardRate_,
        uint256 _disputeRewardRate_,
        uint256 _slashFactor_,
        uint256 _unstakeCooldownPeriod_
    ) external onlyOwner {
        require(_challengeDuration_ > 0, "VeritasProtocol: Challenge duration must be positive");
        require(_minChallengeStake_ > 0, "VeritasProtocol: Min stake must be positive");
        require(_slashFactor_ > 0, "VeritasProtocol: Slash factor must be positive");
        require(_unstakeCooldownPeriod_ >= 0, "VeritasProtocol: Unstake cooldown cannot be negative");

        challengeDuration = _challengeDuration_;
        minChallengeStake = _minChallengeStake_;
        validationRewardRate = _validationRewardRate_;
        disputeRewardRate = _disputeRewardRate_;
        slashFactor = _slashFactor_;
        UNSTAKE_COOLDOWN_PERIOD = _unstakeCooldownPeriod_;

        emit ProtocolParametersSet(
            challengeDuration,
            minChallengeStake,
            validationRewardRate,
            disputeRewardRate,
            slashFactor,
            UNSTAKE_COOLDOWN_PERIOD
        );
    }
}
```