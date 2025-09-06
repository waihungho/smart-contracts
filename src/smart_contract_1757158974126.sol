## AegisSynergy: Decentralized AI-Augmented Collaboration Network

**Contract Overview:**
AegisSynergy is an advanced decentralized autonomous organization (DAO) designed to foster Sybil-resistant collaboration and intelligent decision-making. It integrates a unique Verifiable Contribution Badge (VCB) system, a challengeable AI-augmented proposal evaluation mechanism, and dynamic governance parameters to create a robust and adaptive collective intelligence platform.

**Key Features:**
1.  **Verifiable Contribution Badges (VCBs):** Non-transferable ERC-721 tokens representing specific roles, skills, or validated contributions within the network. These badges form the foundation of on-chain reputation and influence voting power.
2.  **AI-Augmented Proposal Evaluation:** Proposals submitted to the DAO can be evaluated by a designated AI Oracle, which provides a score and justification.
3.  **Challengeable AI Recommendations:** Users can stake tokens to challenge an AI's evaluation if they believe it's inaccurate or biased. These challenges are then resolved by a human or DAO-designated authority, with stakes distributed based on the outcome.
4.  **Reputation-Weighted & Dynamic Governance:** Voting power is weighted by the types and number of VCBs held by a user. Governance parameters (e.g., proposal fee, challenge stake, voting duration, quorum) can be dynamically adjusted through governance proposals, adapting the DAO to its needs.
5.  **Secure Treasury Management:** Funds collected by the DAO (e.g., proposal fees, lost challenge stakes) are managed through governance-approved proposals, including ETH and ERC-20 token withdrawals.

---

**Function Summary:**

**I. Core Infrastructure & Access Control (6 functions)**
*   `constructor()`: Initializes the contract, sets up access control roles (DEFAULT_ADMIN_ROLE, VCB_MINTER_ROLE, AI_ORACLE_ROLE, AI_CHALLENGE_RESOLVER_ROLE), and sets initial governance parameters.
*   `updateUint256Parameter(bytes32 _paramHash, uint256 _newValue)`: Allows `DEFAULT_ADMIN_ROLE` to update various `uint256` configuration parameters (e.g., proposal fee, challenge stake, voting duration, quorum percentage).
*   `grantRole(bytes32 role, address account)`: Standard OpenZeppelin function, grants a role to an account. (Requires `DEFAULT_ADMIN_ROLE`).
*   `revokeRole(bytes32 role, address account)`: Standard OpenZeppelin function, revokes a role from an account. (Requires `DEFAULT_ADMIN_ROLE`).
*   `pause()`: Pauses core contract operations in case of emergency. (Requires `DEFAULT_ADMIN_ROLE`).
*   `unpause()`: Unpauses core contract operations. (Requires `DEFAULT_ADMIN_ROLE`).

**II. Verifiable Contribution Badges (VCBs) - ERC721 Non-transferable (6 functions)**
*   `mintVCB(address _recipient, uint256 _badgeType, string memory _uri)`: Mints a new non-transferable VCB of a specific type to a recipient. Only `VCB_MINTER_ROLE`.
*   `burnVCB(uint256 _tokenId)`: Burns an existing VCB. Only `VCB_MINTER_ROLE`.
*   `getVCBCount(address _owner)`: Returns the total number of VCBs held by a specific address.
*   `hasVCB(address _owner, uint256 _badgeType)`: Checks if an address holds at least one VCB of a specific type.
*   `getVCBDetails(uint256 _tokenId)`: Returns the badge type and URI for a given VCB token ID.
*   `getHoldersByBadgeType(uint256 _badgeType)`: Returns the total count of *unique* addresses holding at least one VCB of a specific type.

**III. AI-Augmented Proposal System (10 functions)**
*   `submitProposal(address _target, uint256 _value, bytes memory _calldata, string memory _description)`: Submits a new governance proposal. Requires a `PROPOSAL_SUBMISSION_FEE` and a minimum number of VCBs from the proposer.
*   `receiveAIRecommendation(uint256 _proposalId, int256 _score, string memory _justification)`: Called by the `AI_ORACLE_ROLE` to submit an AI evaluation for a proposal, moving it to the `AI_Evaluated` state and starting the challenge period.
*   `challengeAIRecommendation(uint256 _proposalId)`: Allows any user to challenge an AI's recommendation by staking `AI_CHALLENGE_STAKE`. Moves the proposal to the `AI_Challenged` state, pausing the process until resolved.
*   `resolveAIChallenge(uint256 _challengeId, bool _aiWasCorrect)`: Called by `AI_CHALLENGE_RESOLVER_ROLE` to resolve an AI challenge. Distributes/refunds stakes based on outcome and moves the proposal to the `Voting` state.
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users (or their delegates) to cast their vote (for/against) on a proposal. Voting power is determined by `calculateVotingWeight`.
*   `delegateVote(address _delegatee)`: Delegates the caller's entire voting power to another address.
*   `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal by making an external call.
*   `getProposalState(uint256 _proposalId)`: Returns the current (dynamically evaluated) state of a proposal.
*   `getProposalVoteCounts(uint256 _proposalId)`: Returns the total 'for' and 'against' votes cast for a proposal.
*   `calculateVotingWeight(address _voter)`: Public view function to compute a user's total voting power based on their held VCBs and their associated weights.

**IV. Treasury & Dynamic Parameters (3 functions)**
*   `depositFunds()`: Allows users to deposit ETH into the contract's treasury, increasing the DAO's collective funds.
*   `withdrawERC20(address _token, address _to, uint256 _amount)`: Allows `DEFAULT_ADMIN_ROLE` (typically triggered by a successful governance proposal) to withdraw ERC20 tokens from the treasury.
*   `withdrawETH(address _to, uint256 _amount)`: Allows `DEFAULT_ADMIN_ROLE` (typically triggered by a successful governance proposal) to withdraw ETH from the treasury.

**Total Functions: 25** (excluding internal/private helpers)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interface for a hypothetical AI Oracle contract that would respond with recommendations
interface IAIOracle {
    function requestAIRecommendation(uint256 _proposalId, string memory _prompt) external;
}

// ====================================================================================================
// AegisSynergy: Decentralized AI-Augmented Collaboration Network
// ====================================================================================================

// Contract Overview:
// AegisSynergy is an advanced decentralized autonomous organization (DAO) designed to foster
// Sybil-resistant collaboration and intelligent decision-making. It integrates a unique
// Verifiable Contribution Badge (VCB) system, a challengeable AI-augmented proposal evaluation
// mechanism, and dynamic governance parameters to create a robust and adaptive collective
// intelligence platform.
//
// Key Features:
// 1. Verifiable Contribution Badges (VCBs): Non-transferable ERC-721 tokens representing specific
//    roles, skills, or validated contributions within the network. These badges form the foundation
//    of on-chain reputation and influence voting power.
// 2. AI-Augmented Proposal Evaluation: Proposals submitted to the DAO can be evaluated by a designated
//    AI Oracle, which provides a score and justification.
// 3. Challengeable AI Recommendations: Users can stake tokens to challenge an AI's evaluation if
//    they believe it's inaccurate or biased. These challenges are then resolved by a human or
//    DAO-designated authority.
// 4. Reputation-Weighted & Dynamic Governance: Voting power is weighted by the types and number of
//    VCBs held by a user. Governance parameters (e.g., quorum, voting duration) can dynamically
//    adjust based on network participation and activity through governance proposals.
// 5. Secure Treasury Management: Funds collected by the DAO are managed through governance-approved
//    proposals, including ETH and ERC-20 token withdrawals.

// ====================================================================================================
// Function Summary:
// ====================================================================================================

// I. Core Infrastructure & Access Control (6 functions)
//    - constructor(): Initializes the contract, sets up access control roles (DEFAULT_ADMIN_ROLE,
//                     VCB_MINTER_ROLE, AI_ORACLE_ROLE, AI_CHALLENGE_RESOLVER_ROLE), and initial parameters.
//    - updateUint256Parameter(bytes32 _paramHash, uint256 _newValue): Allows DEFAULT_ADMIN_ROLE to
//      update various uint256 configuration parameters (e.g., proposal fee, challenge stake, voting duration).
//    - grantRole(bytes32 role, address account): Standard OpenZeppelin function, grants a role. (DEFAULT_ADMIN_ROLE only).
//    - revokeRole(bytes32 role, address account): Standard OpenZeppelin function, revokes a role. (DEFAULT_ADMIN_ROLE only).
//    - pause(): Pauses the contract operations in case of emergency (DEFAULT_ADMIN_ROLE only).
//    - unpause(): Unpauses the contract operations (DEFAULT_ADMIN_ROLE only).

// II. Verifiable Contribution Badges (VCBs) - ERC721 Non-transferable (6 functions)
//    - mintVCB(address _recipient, uint256 _badgeType, string memory _uri): Mints a new VCB of a
//      specific type to an address. Only VCB_MINTER_ROLE.
//    - burnVCB(uint256 _tokenId): Burns a VCB. Only VCB_MINTER_ROLE.
//    - getVCBCount(address _owner): Returns the total number of VCBs held by an address.
//    - hasVCB(address _owner, uint256 _badgeType): Checks if an address holds a specific type of VCB.
//    - getVCBDetails(uint256 _tokenId): Returns the badge type and URI for a given VCB token ID.
//    - getHoldersByBadgeType(uint256 _badgeType): Returns the total count of unique addresses holding a specific badge type.

// III. AI-Augmented Proposal System (10 functions)
//    - submitProposal(address _target, uint256 _value, bytes memory _calldata, string memory _description):
//      Submits a new governance proposal. Requires a PROPOSAL_SUBMISSION_FEE and minimum VCBs.
//    - receiveAIRecommendation(uint256 _proposalId, int256 _score, string memory _justification):
//      Called by AI_ORACLE_ROLE to submit an AI evaluation for a proposal. Moves proposal to AI_Evaluated state.
//    - challengeAIRecommendation(uint256 _proposalId): Allows any user to challenge an AI's
//      recommendation by staking AI_CHALLENGE_STAKE. Moves proposal to AI_Challenged state.
//    - resolveAIChallenge(uint256 _challengeId, bool _aiWasCorrect): Called by AI_CHALLENGE_RESOLVER_ROLE
//      to resolve an AI challenge. Distributes/refunds stake and updates the proposal's effective AI score.
//    - voteOnProposal(uint256 _proposalId, bool _support): Allows users to cast their vote (for/against)
//      on a proposal. Voting weight is determined by calculateVotingWeight.
//    - delegateVote(address _delegatee): Delegates the caller's entire voting power to another address.
//    - executeProposal(uint256 _proposalId): Executes a successfully passed proposal.
//    - getProposalState(uint256 _proposalId): Returns the current state of a proposal.
//    - getProposalVoteCounts(uint256 _proposalId): Returns the total 'for' and 'against' votes for a proposal.
//    - calculateVotingWeight(address _voter): Public view function to compute a user's voting power
//      based on their held VCBs.

// IV. Treasury & Dynamic Parameters (3 functions)
//    - depositFunds(): Allows users to deposit ETH into the contract's treasury.
//    - withdrawERC20(address _token, address _to, uint256 _amount): Allows DEFAULT_ADMIN_ROLE (via
//      governance proposal) to withdraw ERC20 tokens from the treasury.
//    - withdrawETH(address _to, uint256 _amount): Allows DEFAULT_ADMIN_ROLE (via governance proposal)
//      to withdraw ETH from the treasury.

// Total Functions: 25 (excluding internal/private helpers)
// ====================================================================================================

contract AegisSynergy is ERC721Enumerable, AccessControl, ReentrancyGuard {
    // --- Roles ---
    bytes32 public constant VCB_MINTER_ROLE = keccak256("VCB_MINTER_ROLE");
    bytes32 public constant AI_ORACLE_ROLE = keccak256("AI_ORACLE_ROLE");
    bytes32 public constant AI_CHALLENGE_RESOLVER_ROLE = keccak256("AI_CHALLENGE_RESOLVER_ROLE");

    // --- Enums ---
    enum ProposalState {
        Pending,          // Just submitted, awaiting AI evaluation
        AI_Evaluated,     // AI score received, challenge period active
        AI_Challenged,    // AI score is being disputed, awaiting resolution
        Voting,           // Open for voting
        Succeeded,        // Passed quorum and majority
        Failed,           // Did not pass quorum or majority
        Executed          // Successfully executed
    }

    // --- Structs ---
    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes calldataPayload;
        string description;
        uint256 creationTime;
        uint256 processEndTime; // Used for AI challenge period, then voting period
        ProposalState state;
        int256 aiScore; // AI's recommendation score (e.g., -100 to 100)
        string aiJustification;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 aiChallengeId; // 0 if no active challenge
        bool aiScoreOverridden; // True if AI score was successfully challenged as incorrect
        mapping(address => bool) hasVoted; // Tracks if an address (or its delegate) has voted
    }

    struct AIChallenge {
        uint256 proposalId;
        address challenger;
        string reason; // Reason provided by challenger (not actively used in logic, but for transparency)
        uint256 stake;
        bool resolved;
        bool aiWasCorrect; // Outcome of the challenge: true if AI was correct, false if AI was incorrect
    }

    // --- State Variables ---
    uint256 public nextProposalId;
    uint256 public nextChallengeId;
    uint256 private _nextVCBTokenId; // Separate counter for VCB token IDs

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => AIChallenge) public aiChallenges;

    // VCBs are non-transferable ERC721s.
    uint256[] public availableBadgeTypes; // e.g., 0: Developer, 1: Strategist, etc.
    mapping(uint256 => uint256) public badgeTypeToWeight; // Voting weight provided by each badge type
    mapping(address => mapping(uint256 => uint256)) private _userBadgeTypeCounts; // How many of each badge type a user has
    mapping(uint256 => uint256) private _tokenIdToBadgeType; // Maps VCB tokenId to its badge type
    mapping(uint256 => uint256) private _uniqueBadgeTypeHoldersCount; // Total unique addresses holding a specific badge type

    // Governance Parameters (updatable by DEFAULT_ADMIN_ROLE via updateUint256Parameter)
    mapping(bytes32 => uint256) public uint256Parameters;
    bytes32 public constant PARAM_PROPOSAL_FEE = keccak256("PROPOSAL_FEE");
    bytes32 public constant PARAM_MIN_VCBS_FOR_PROPOSAL = keccak256("MIN_VCBS_FOR_PROPOSAL");
    bytes32 public constant PARAM_VOTING_DURATION = keccak256("VOTING_DURATION"); // seconds for main voting phase
    bytes32 public constant PARAM_PROPOSAL_QUORUM_PERCENTAGE = keccak256("PROPOSAL_QUORUM_PERCENTAGE"); // 0-10000 (for 0-100%)
    bytes32 public constant PARAM_AI_CHALLENGE_STAKE = keccak256("AI_CHALLENGE_STAKE");
    bytes32 public constant PARAM_AI_CHALLENGE_DURATION = keccak256("AI_CHALLENGE_DURATION"); // seconds for AI challenge period
    bytes32 public constant PARAM_AI_CONSIDERATION_THRESHOLD = keccak256("AI_CONSIDERATION_THRESHOLD"); // e.g., 70 for AI score >= 70 being 'positive'

    // Delegation for voting power
    mapping(address => address) public delegates;

    // Pausability state
    bool public paused;

    // --- Events ---
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event AIRecommendationReceived(uint256 indexed proposalId, int256 score, string justification);
    event AIRecommendationChallenged(uint256 indexed proposalId, uint256 indexed challengeId, address indexed challenger);
    event AIChallengeResolved(uint256 indexed challengeId, uint256 indexed proposalId, bool aiWasCorrect, uint256 refundAmount);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ParameterUpdated(bytes32 indexed paramHash, uint256 newValue);
    event VCB_Minted(address indexed recipient, uint256 indexed tokenId, uint256 badgeType);
    event VCB_Burned(uint256 indexed tokenId);
    event Delegated(address indexed delegator, address indexed delegatee);
    event Paused(address account);
    event Unpaused(address account);

    // --- Constructor ---
    constructor(
        address _admin,
        string memory _name,
        string memory _symbol
    ) ERC721Enumerable(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Grant deployer admin too

        _grantRole(VCB_MINTER_ROLE, _admin);
        _grantRole(VCB_MINTER_ROLE, msg.sender);

        // Set initial governance parameters
        uint256Parameters[PARAM_PROPOSAL_FEE] = 0.05 ether; // 0.05 ETH
        uint256Parameters[PARAM_MIN_VCBS_FOR_PROPOSAL] = 1; // User needs at least 1 VCB to propose
        uint256Parameters[PARAM_VOTING_DURATION] = 3 days; // 3 days for voting
        uint256Parameters[PARAM_PROPOSAL_QUORUM_PERCENTAGE] = 5000; // 50.00% (5000/10000)
        uint256Parameters[PARAM_AI_CHALLENGE_STAKE] = 0.1 ether; // 0.1 ETH to challenge AI
        uint256Parameters[PARAM_AI_CHALLENGE_DURATION] = 1 days; // 1 day for AI challenge period
        uint256Parameters[PARAM_AI_CONSIDERATION_THRESHOLD] = 70; // AI score >= 70 is 'positive'

        // Initialize example badge types and their weights
        // These could also be configurable via governance proposals
        availableBadgeTypes.push(0); // Developer
        badgeTypeToWeight[0] = 5;
        availableBadgeTypes.push(1); // Strategist
        badgeTypeToWeight[1] = 10;
        availableBadgeTypes.push(2); // AI Analyst
        badgeTypeToWeight[2] = 8;
        availableBadgeTypes.push(3); // Moderator
        badgeTypeToWeight[3] = 3;
        availableBadgeTypes.push(4); // Community Guardian
        badgeTypeToWeight[4] = 2;
    }

    // --- Pausability Modifiers & Functions ---
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        paused = false;
        emit Unpaused(_msgSender());
    }

    // --- I. Core Infrastructure & Access Control ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        // VCBs are non-transferable, except for minting (from zero address) and burning (to zero address)
        require(from == address(0) || to == address(0), "VCB: Not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function updateUint256Parameter(bytes32 _paramHash, uint256 _newValue)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(uint256Parameters[_paramHash] != 0 || _paramHash == PARAM_PROPOSAL_FEE, "Param: Invalid parameter hash"); // Ensure parameter exists
        uint256Parameters[_paramHash] = _newValue;
        emit ParameterUpdated(_paramHash, _newValue);
    }

    // --- II. Verifiable Contribution Badges (VCBs) ---

    function mintVCB(address _recipient, uint256 _badgeType, string memory _uri)
        public
        onlyRole(VCB_MINTER_ROLE)
        whenNotPaused
    {
        require(_recipient != address(0), "VCB: Mint to non-zero address");
        require(badgeTypeToWeight[_badgeType] > 0, "VCB: Invalid badge type"); // Ensure badge type is configured

        _nextVCBTokenId++;
        _safeMint(_recipient, _nextVCBTokenId);
        _setTokenURI(_nextVCBTokenId, _uri);
        _tokenIdToBadgeType[_nextVCBTokenId] = _badgeType; // Store badge type for tokenId
        
        if (_userBadgeTypeCounts[_recipient][_badgeType] == 0) {
            // First time this user gets this badge type, increment unique holder count
            _uniqueBadgeTypeHoldersCount[_badgeType]++;
        }
        _userBadgeTypeCounts[_recipient][_badgeType]++; // Increment count of this badge type for the user
        
        emit VCB_Minted(_recipient, _nextVCBTokenId, _badgeType);
    }

    function burnVCB(uint256 _tokenId)
        public
        onlyRole(VCB_MINTER_ROLE)
        whenNotPaused
    {
        require(_exists(_tokenId), "VCB: Token does not exist");
        address owner = ownerOf(_tokenId);
        uint256 badgeType = _tokenIdToBadgeType[_tokenId];
        require(badgeTypeToWeight[badgeType] > 0, "VCB: Badge type not configured for token");

        _burn(_tokenId);
        delete _tokenIdToBadgeType[_tokenId]; // Clear mapping

        require(_userBadgeTypeCounts[owner][badgeType] > 0, "VCB: User does not have this badge type count to burn");
        _userBadgeTypeCounts[owner][badgeType]--;

        if (_userBadgeTypeCounts[owner][badgeType] == 0) {
            // If user no longer has any badges of this type, decrement unique holder count
            _uniqueBadgeTypeHoldersCount[_badgeType]--;
        }
        emit VCB_Burned(_tokenId);
    }

    function getVCBCount(address _owner) public view returns (uint256) {
        return balanceOf(_owner);
    }

    function hasVCB(address _owner, uint256 _badgeType) public view returns (bool) {
        return _userBadgeTypeCounts[_owner][_badgeType] > 0;
    }

    function getVCBDetails(uint256 _tokenId) public view returns (uint256 badgeType, string memory uri) {
        require(_exists(_tokenId), "VCB: Token does not exist");
        return (_tokenIdToBadgeType[_tokenId], tokenURI(_tokenId));
    }

    function getHoldersByBadgeType(uint256 _badgeType) public view returns (uint256) {
        return _uniqueBadgeTypeHoldersCount[_badgeType];
    }


    // --- III. AI-Augmented Proposal System ---

    function submitProposal(
        address _target,
        uint256 _value,
        bytes memory _calldata,
        string memory _description
    ) public payable whenNotPaused returns (uint256) {
        require(balanceOf(_msgSender()) >= uint256Parameters[PARAM_MIN_VCBS_FOR_PROPOSAL], "Proposer: Not enough VCBs to propose");
        require(msg.value == uint256Parameters[PARAM_PROPOSAL_FEE], "Proposer: Incorrect proposal fee");

        uint256 proposalId = nextProposalId;
        proposals[proposalId] = Proposal({
            proposer: _msgSender(),
            target: _target,
            value: _value,
            calldataPayload: _calldata,
            description: _description,
            creationTime: block.timestamp,
            processEndTime: 0, // Set later for challenge/voting
            state: ProposalState.Pending,
            aiScore: 0,
            aiJustification: "",
            forVotes: 0,
            againstVotes: 0,
            aiChallengeId: 0,
            aiScoreOverridden: false
            // mappings are not initializable in structs, will be empty
        });

        nextProposalId++;
        emit ProposalSubmitted(proposalId, _msgSender(), _description);

        // In a real system, the `IAIOracle` would be called here:
        // IAIOracle(address(getRoleMember(AI_ORACLE_ROLE, 0))).requestAIRecommendation(proposalId, _description);
        // For this example, we assume `receiveAIRecommendation` will be called externally by the oracle system.

        return proposalId;
    }

    function receiveAIRecommendation(
        uint256 _proposalId,
        int256 _score,
        string memory _justification
    ) public onlyRole(AI_ORACLE_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "AI: Proposal does not exist"); // Check if proposal is initialized
        require(proposal.state == ProposalState.Pending, "AI: Proposal not in Pending state");

        proposal.aiScore = _score;
        proposal.aiJustification = _justification;
        proposal.state = ProposalState.AI_Evaluated;
        proposal.processEndTime = block.timestamp + uint256Parameters[PARAM_AI_CHALLENGE_DURATION];

        emit AIRecommendationReceived(_proposalId, _score, _justification);
        emit ProposalStateChanged(_proposalId, ProposalState.AI_Evaluated);
    }

    function challengeAIRecommendation(uint256 _proposalId) public payable whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Challenge: Proposal does not exist");
        require(proposal.state == ProposalState.AI_Evaluated, "Challenge: Proposal not in AI_Evaluated state");
        require(block.timestamp <= proposal.processEndTime, "Challenge: AI challenge period has ended");
        require(proposal.aiChallengeId == 0, "Challenge: Proposal already has an active challenge");
        require(msg.value == uint256Parameters[PARAM_AI_CHALLENGE_STAKE], "Challenge: Incorrect stake amount");

        uint256 challengeId = nextChallengeId;
        aiChallenges[challengeId] = AIChallenge({
            proposalId: _proposalId,
            challenger: _msgSender(),
            reason: "AI recommendation disputed", // Simplified reason, could accept a string
            stake: msg.value,
            resolved: false,
            aiWasCorrect: false
        });
        nextChallengeId++;

        proposal.aiChallengeId = challengeId;
        proposal.state = ProposalState.AI_Challenged;
        proposal.processEndTime = 0; // Reset end time until challenge is resolved

        emit AIRecommendationChallenged(_proposalId, challengeId, _msgSender());
        emit ProposalStateChanged(_proposalId, ProposalState.AI_Challenged);
    }

    function resolveAIChallenge(uint256 _challengeId, bool _aiWasCorrect)
        public
        onlyRole(AI_CHALLENGE_RESOLVER_ROLE)
        whenNotPaused
        returns (uint256)
    {
        AIChallenge storage challenge = aiChallenges[_challengeId];
        require(challenge.proposalId != 0, "Challenge: Does not exist"); // Check if challenge exists
        require(!challenge.resolved, "Challenge: Already resolved");
        
        Proposal storage proposal = proposals[challenge.proposalId];
        require(proposal.proposer != address(0), "Challenge: Linked proposal does not exist");
        require(proposal.state == ProposalState.AI_Challenged, "Challenge: Linked proposal not in Challenged state");

        challenge.resolved = true;
        challenge.aiWasCorrect = _aiWasCorrect;
        proposal.aiScoreOverridden = !_aiWasCorrect; // If AI was incorrect, its score is overridden

        uint256 refundAmount = 0;
        if (!_aiWasCorrect) { // AI was incorrect, challenger wins
            refundAmount = challenge.stake;
            payable(challenge.challenger).transfer(refundAmount);
        } // If AI was correct, challenger loses stake, which remains in the contract treasury

        // After resolution, move to Voting state and start voting period
        proposal.state = ProposalState.Voting;
        proposal.processEndTime = block.timestamp + uint256Parameters[PARAM_VOTING_DURATION];

        emit AIChallengeResolved(_challengeId, challenge.proposalId, _aiWasCorrect, refundAmount);
        emit ProposalStateChanged(challenge.proposalId, ProposalState.Voting);
        return refundAmount;
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Vote: Proposal does not exist");
        require(proposal.state == ProposalState.Voting, "Vote: Proposal not in Voting state");
        require(block.timestamp <= proposal.processEndTime, "Vote: Voting period has ended");

        address voter = _msgSender();
        address actualVoter = delegates[voter] != address(0) ? delegates[voter] : voter;
        
        require(!proposal.hasVoted[actualVoter], "Vote: Already voted or delegated vote used");

        uint256 weight = calculateVotingWeight(actualVoter);
        require(weight > 0, "Vote: Voter has no voting weight");

        if (_support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }
        proposal.hasVoted[actualVoter] = true; // Mark the actual voter (or delegate) as having voted
        
        emit VoteCast(_proposalId, actualVoter, _support, weight);
    }

    function delegateVote(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "Delegate: Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "Delegate: Cannot delegate to self");
        // Prevent circular delegation (A->B->A or A->B->C->A)
        address current = _delegatee;
        while (current != address(0)) {
            require(current != _msgSender(), "Delegate: Circular delegation detected");
            current = delegates[current];
        }

        delegates[_msgSender()] = _delegatee;
        emit Delegated(_msgSender(), _delegatee);
    }
    
    function executeProposal(uint256 _proposalId) public payable nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Execute: Proposal does not exist");
        require(getProposalState(_proposalId) == ProposalState.Succeeded, "Execute: Proposal not in Succeeded state");

        // Already checked state in getProposalState, no need for block.timestamp check here.

        // Set state before external call to prevent reentrancy
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);

        // Execute the proposal payload
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "Execute: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // This function dynamically evaluates the state of a proposal based on current time
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) {
            return ProposalState.Pending; // Or a custom 'NonExistent' state if proposal ID is truly invalid
        }
        
        // If AI challenge period passed, automatically move to Voting
        if (proposal.state == ProposalState.AI_Evaluated && block.timestamp > proposal.processEndTime) {
            return ProposalState.Voting;
        }
        // If voting period passed, evaluate outcome
        if (proposal.state == ProposalState.Voting && block.timestamp > proposal.processEndTime) {
            uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
            if (totalVotes == 0) { // No votes cast, implicitly failed for not meeting quorum/majority
                return ProposalState.Failed;
            }

            // Quorum check
            if ((proposal.forVotes * 10000) / totalVotes < uint256Parameters[PARAM_PROPOSAL_QUORUM_PERCENTAGE]) {
                return ProposalState.Failed;
            }
            // Majority check
            if (proposal.forVotes <= proposal.againstVotes) {
                return ProposalState.Failed;
            }
            return ProposalState.Succeeded;
        }
        return proposal.state;
    }

    function getProposalVoteCounts(uint256 _proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal: Does not exist");
        return (proposal.forVotes, proposal.againstVotes);
    }

    function calculateVotingWeight(address _voter) public view returns (uint256) {
        uint256 totalWeight = 0;
        // Sum weights from all badge types held by the voter
        for (uint256 i = 0; i < availableBadgeTypes.length; i++) {
            uint256 badgeType = availableBadgeTypes[i];
            if (_userBadgeTypeCounts[_voter][badgeType] > 0) {
                totalWeight += _userBadgeTypeCounts[_voter][badgeType] * badgeTypeToWeight[badgeType];
            }
        }
        return totalWeight;
    }

    // --- IV. Treasury & Dynamic Parameters ---

    receive() external payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    function depositFunds() public payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    function withdrawERC20(address _token, address _to, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // In a full DAO, this would be executed via a successful governance proposal
        nonReentrant
        whenNotPaused
    {
        require(_to != address(0), "Withdraw: To zero address");
        IERC20(_token).transfer(_to, _amount);
    }

    function withdrawETH(address _to, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // In a full DAO, this would be executed via a successful governance proposal
        nonReentrant
        whenNotPaused
    {
        require(_to != address(0), "Withdraw: To zero address");
        payable(_to).transfer(_amount);
    }
}
```