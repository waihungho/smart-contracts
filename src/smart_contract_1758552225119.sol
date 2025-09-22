Here's a smart contract in Solidity called "ChronicleForge," designed around the concept of dynamic, evolving NFTs ("Chronicles") that tell stories, track real-world impact, and engage a community through prediction markets and a reputation system.

---

## ChronicleForge Smart Contract

**Description:**
ChronicleForge is a decentralized platform for co-creating dynamic, evolving digital narratives or impact projects, represented as unique, dynamic NFTs called "Chronicles." Chronicles evolve based on community contributions (narrative fragments), verifiable real-world impacts, and prediction markets. The platform fosters community engagement through a reputation system ("Narrative Karma") and DAO-like governance.

**Core Concepts:**
*   **Dynamic NFTs (dNFTs):** Chronicles are ERC721 tokens whose metadata and on-chain properties can change and evolve over time, driven by community actions and verified impact.
*   **Narrative Co-creation:** Users contribute "Fragments" (e.g., text, data, multimedia links) to shape a Chronicle's evolving story. Fragments undergo a community voting process before being "fused" into the main narrative.
*   **Impact Verification:** Chronicles accumulate "Impact Points" based on verifiable real-world outcomes linked to their narrative or mission. An oracle system (simulated here) is responsible for submitting and verifying these proofs.
*   **Prediction Market:** Users can stake "Catalyst" (ERC20) tokens on "Epoch Outcomes," predicting whether a Chronicle will achieve specific impact goals within a defined period. Successful predictors are rewarded.
*   **Reputation System:** "Narrative Karma" is awarded to users for positive contributions, such as successfully fused fragments and accurate epoch predictions, fostering a meritocratic community.
*   **DAO-like Governance:** A simplified governance system allows the community (or initially, the owner) to propose and vote on platform-wide parameter changes and Chronicle-specific decisions.

**Tokens Involved:**
*   **ERC721 (Chronicle):** The core NFT representing an evolving narrative or project.
*   **ERC20 (Catalyst):** An external ERC20 token used for transaction fees (e.g., contributing fragments), staking in prediction markets, and potentially for governance voting power. (An `IERC20` interface is used; a separate `CatalystToken.sol` would implement this.)

---

### Function Summary (25 Functions):

**I. Core Chronicle Management (ERC721-like & Dynamic State)**
1.  `createChronicle(string memory _name, string memory _symbol, string memory _initialNarrativeURI, uint256 _initialGoalImpactPoints)`: Mints a new Chronicle NFT with an initial state and a goal.
2.  `updateChronicleURI(uint256 _chronicleId, string memory _newURI)`: Allows owner/governance to update the main metadata URI of a Chronicle, reflecting its evolution.
3.  `getChronicleCurrentState(uint256 _chronicleId)`: Retrieves the current dynamic state (URI, impact, latest epoch details) of a Chronicle.

**II. Chronicle Evolution & Fragment Contribution**
4.  `contributeFragment(uint256 _chronicleId, string memory _fragmentURI, uint256 _catalystFee)`: Allows users to propose a new narrative fragment for a Chronicle, paying a Catalyst fee.
5.  `voteOnFragment(uint256 _chronicleId, uint256 _fragmentIndex, bool _approve)`: Community members vote to approve or reject proposed fragments.
6.  `fuseFragments(uint256 _chronicleId, uint256[] memory _fragmentIndices, uint256 _fusionCatalystAmount)`: Integrates approved fragments into the Chronicle's narrative, marking them as fused.
7.  `retireFragment(uint252 _chronicleId, uint256 _fragmentIndex)`: Removes a fragment, typically if it's voted against or deemed inappropriate by governance.

**III. Impact Tracking & Verification**
8.  `submitImpactProof(uint256 _chronicleId, string memory _proofURI, int256 _proposedImpactPoints)`: Designated oracle/verifier submits proof of real-world impact for a Chronicle.
9.  `verifyImpactProof(uint256 _chronicleId, uint256 _proofIndex, bool _isVerified)`: Governance or a committee verifies submitted impact proofs, adjusting Chronicle impact points.
10. `getChronicleImpactPoints(uint256 _chronicleId)`: Retrieves the current total verified impact points for a Chronicle.

**IV. Epochs, Staking & Prediction Market**
11. `startNewEpoch(uint256 _chronicleId, uint256 _duration, uint256 _epochGoalImpactPoints)`: Initiates a new prediction epoch for a Chronicle, defining its duration and impact goal.
12. `stakeOnEpochOutcome(uint256 _chronicleId, uint256 _epochId, bool _predictAchievedGoal, uint256 _amount)`: Users stake Catalyst tokens on whether an epoch's impact goal will be achieved.
13. `resolveEpochOutcome(uint256 _chronicleId, uint256 _epochId, bool _actualOutcomeAchieved)`: Oracle/governance resolves the epoch's outcome, determining winners and distributing rewards.
14. `claimEpochRewards(uint256 _chronicleId, uint256 _epochId)`: Allows successful stakers to claim their share of the prize pool.
15. `getEpochPredictionPool(uint256 _chronicleId, uint256 _epochId, bool _forAchievedGoal)`: Retrieves the total Catalyst staked for a particular outcome in an epoch.

**V. Reputation & Governance (DAO-like)**
16. `getNarrativeKarma(address _user)`: Retrieves the Narrative Karma score for a user, reflecting their positive contributions.
17. `delegateVote(address _delegatee)`: Allows users to delegate their voting power to another address (for future weighted voting integration).
18. `proposeGovernanceChange(bytes memory _callData, string memory _description)`: Allows users to propose platform-wide changes or new features, with an executable payload.
19. `voteOnProposal(uint256 _proposalId, bool _approve)`: Community members vote on active governance proposals.
20. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal.
21. `setFragmentVotingParameters(uint256 _minVotes, uint256 _voteDuration)`: Sets global parameters for how fragments are voted upon.

**VI. Platform Configuration & Utility**
22. `setCatalystTokenAddress(address _catalystAddress)`: Sets the address of the Catalyst ERC20 token used throughout the platform.
23. `withdrawFees(address _tokenAddress, address _to, uint256 _amount)`: Allows the owner to withdraw accumulated Catalyst fees from the contract.
24. `updateOracleAddress(address _newOracle)`: Sets the trusted oracle address responsible for impact proofs and epoch resolution.
25. `configureNarrativeKarmaSystem(uint256 _fragmentContributionKarma, uint256 _correctPredictionKarma)`: Configures the Karma rewards for specific positive actions within the platform.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary ---
// (Refer to the detailed summary above for function descriptions)
//
// Contract Name: ChronicleForge
// Description: A decentralized platform for co-creating dynamic, evolving digital narratives or impact projects, represented as unique, dynamic NFTs called "Chronicles." Chronicles evolve based on community contributions, verifiable real-world impacts, and prediction markets.
//
// Core Concepts: Dynamic NFTs (dNFTs), Narrative Co-creation, Impact Verification, Prediction Market, Reputation System, DAO-like Governance.
// Tokens Involved: ERC721 ("Chronicle" NFTs), ERC20 ("Catalyst" Token - IERC20).
//
// Functions (25 total):
// I. Core Chronicle Management (ERC721-like & Dynamic State)
// 1.  createChronicle
// 2.  updateChronicleURI
// 3.  getChronicleCurrentState
// II. Chronicle Evolution & Fragment Contribution
// 4.  contributeFragment
// 5.  voteOnFragment
// 6.  fuseFragments
// 7.  retireFragment
// III. Impact Tracking & Verification
// 8.  submitImpactProof
// 9.  verifyImpactProof
// 10. getChronicleImpactPoints
// IV. Epochs, Staking & Prediction Market
// 11. startNewEpoch
// 12. stakeOnEpochOutcome
// 13. resolveEpochOutcome
// 14. claimEpochRewards
// 15. getEpochPredictionPool
// V. Reputation & Governance (DAO-like)
// 16. getNarrativeKarma
// 17. delegateVote
// 18. proposeGovernanceChange
// 19. voteOnProposal
// 20. executeProposal
// 21. setFragmentVotingParameters
// VI. Platform Configuration & Utility
// 22. setCatalystTokenAddress
// 23. withdrawFees
// 24. updateOracleAddress
// 25. configureNarrativeKarmaSystem


contract ChronicleForge is ERC721, Ownable, Pausable, ReentrancyGuard {
    // --- State Variables ---

    IERC20 public catalystToken; // Address of the Catalyst ERC20 token
    address public oracleAddress; // Address authorized to submit impact proofs and resolve epochs

    // Chronicle Struct: Represents a dynamic NFT
    struct Chronicle {
        string currentNarrativeURI; // The main evolving metadata URI
        int256 totalImpactPoints;   // Accumulated verified impact points (can be negative)
        uint256 lastEpochId;        // ID of the latest epoch
        uint256 createdAt;          // Timestamp of creation
        address creator;            // Address of the creator/minter
        uint256 goalImpactPoints;   // Initial goal for the chronicle
    }
    mapping(uint256 => Chronicle) public chronicles; // chronicleId => Chronicle data
    uint256 private _currentTokenId = 0; // Simple ID counter for Chronicles

    // Fragment Struct: Proposed narrative additions
    struct Fragment {
        string fragmentURI;      // Metadata URI for the fragment content
        address contributor;     // Address of the contributor
        uint256 submittedAtBlock; // Block number of submission, for voting duration
        uint256 yesVotes;        // Number of 'yes' votes
        uint256 noVotes;         // Number of 'no' votes
        bool isApproved;         // True if approved for fusion
        bool isFused;            // True if already integrated into the Chronicle
        bool isRetired;          // True if retired (e.g., voted against)
    }
    mapping(uint256 => Fragment[]) public chronicleFragments; // chronicleId => array of Fragments
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public fragmentVotes; // chronicleId => fragmentIndex => voter => hasVoted

    // Epoch Struct: For prediction market on Chronicle goals
    struct Epoch {
        uint256 epochGoalImpactPoints; // Target impact points for this epoch
        uint256 startTime;             // When the epoch started (timestamp)
        uint256 endTime;               // When the epoch ends (timestamp, for prediction phase)
        bool resolved;                 // True if the epoch outcome has been determined
        bool actualOutcomeAchieved;    // True if the goal was achieved, false otherwise
        uint256 totalStakedForAchieved; // Total Catalyst staked predicting goal achieved
        uint256 totalStakedForFailed;   // Total Catalyst staked predicting goal failed
    }
    mapping(uint256 => mapping(uint256 => Epoch)) public chronicleEpochs; // chronicleId => epochId => Epoch data
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public epochStakesAchieved; // chronicleId => epochId => staker => amount
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public epochStakesFailed; // chronicleId => epochId => staker => amount
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public epochClaimed; // chronicleId => epochId => staker => claimed

    // Impact Proof Struct: Verifiable real-world outcomes
    struct ImpactProof {
        string proofURI;            // URI to the proof document/data
        address submitter;          // Address who submitted the proof (oracle)
        int256 proposedImpactPoints; // Points suggested by the submitter
        uint256 submittedAt;       // Timestamp of submission
        bool isVerified;            // True if approved by governance
        bool isApplied;             // True if the impact points have been added to the Chronicle
    }
    mapping(uint256 => ImpactProof[]) public chronicleImpactProofs; // chronicleId => array of ImpactProofs

    // Reputation System (Narrative Karma)
    mapping(address => uint256) public narrativeKarma;
    uint256 public fragmentContributionKarma = 10; // Karma awarded for a successfully fused fragment
    uint256 public correctPredictionKarma = 5;    // Karma awarded for a correct epoch prediction

    // Governance System (Simple Proposal)
    struct Proposal {
        uint256 id;                 // Unique proposal ID
        address proposer;           // Address who proposed it
        string description;         // Description of the proposal
        bytes callData;             // Calldata for the target contract (ChronicleForge itself)
        uint256 startBlock;         // Block number when voting starts
        uint256 endBlock;           // Block number when voting ends
        uint256 yesVotes;           // Total yes votes (based on Karma or Catalyst, simplified for now)
        uint256 noVotes;            // Total no votes
        bool executed;              // True if the proposal has been executed
        mapping(address => bool) hasVoted; // Address => true if voted
    }
    Proposal[] public proposals;
    uint256 public nextProposalId = 0;
    uint256 public proposalVotingPeriodBlocks = 1000; // e.g., ~4 hours at 14s/block
    uint256 public minKarmaForProposal = 100;        // Minimum Karma to propose (currently not enforced for demo)
    uint256 public minNetVotesForProposalPass = 50; // Minimum net votes (yes - no) for a proposal to pass

    // Fragment Voting Parameters
    uint256 public minVotesRequiredForFragment = 5;     // Minimum total votes for a fragment to be considered
    uint256 public fragmentVotingDurationBlocks = 100; // Blocks duration for fragment voting

    // Delegate voting for governance (basic delegation, actual voting power calculation would be more complex)
    mapping(address => address) public delegates;

    // --- Events ---
    event ChronicleCreated(uint256 indexed chronicleId, address indexed creator, string name, string initialURI, uint256 initialGoal);
    event ChronicleURIUpdated(uint256 indexed chronicleId, string newURI);
    event FragmentContributed(uint256 indexed chronicleId, uint256 indexed fragmentIndex, address indexed contributor, string fragmentURI);
    event FragmentVoted(uint256 indexed chronicleId, uint256 indexed fragmentIndex, address indexed voter, bool approved);
    event FragmentsFused(uint256 indexed chronicleId, uint256[] fusedFragmentIndices, string newSuggestedURI);
    event FragmentRetired(uint256 indexed chronicleId, uint256 indexed fragmentIndex);
    event ImpactProofSubmitted(uint256 indexed chronicleId, uint256 indexed proofIndex, address indexed submitter, int256 proposedPoints);
    event ImpactProofVerified(uint256 indexed chronicleId, uint256 indexed proofIndex, bool isVerified, int256 addedPoints);
    event EpochStarted(uint256 indexed chronicleId, uint256 indexed epochId, uint256 goalPoints, uint256 endTime);
    event EpochStaked(uint256 indexed chronicleId, uint256 indexed epochId, address indexed staker, bool predictedAchieved, uint256 amount);
    event EpochResolved(uint255 indexed chronicleId, uint256 indexed epochId, bool actualOutcomeAchieved, uint256 totalAchievedPool, uint256 totalFailedPool);
    event EpochRewardsClaimed(uint256 indexed chronicleId, uint256 indexed epochId, address indexed staker, uint256 amount);
    event KarmaUpdated(address indexed user, uint256 newKarma);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalExecuted(uint256 indexed proposalId);
    event DelegateSet(address indexed delegator, address indexed delegatee);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event CatalystTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event FeesWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event NarrativeKarmaConfigured(uint256 fragmentKarma, uint256 predictionKarma);
    event FragmentVotingParametersConfigured(uint256 minVotes, uint256 voteDuration);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronicleForge: Only the designated oracle can call this function.");
        _;
    }

    modifier onlyChronicleOwner(uint256 _chronicleId) {
        require(_isApprovedOrOwner(msg.sender, _chronicleId), "ChronicleForge: Caller is not the owner or approved");
        _;
    }

    modifier canVoteOnFragment(uint256 _chronicleId, uint256 _fragmentIndex) {
        require(block.number <= chronicleFragments[_chronicleId][_fragmentIndex].submittedAtBlock + fragmentVotingDurationBlocks, "ChronicleForge: Fragment voting period has ended");
        require(!fragmentVotes[_chronicleId][_fragmentIndex][msg.sender], "ChronicleForge: Already voted on this fragment");
        _;
    }

    modifier canResolveEpoch(uint256 _chronicleId, uint256 _epochId) {
        Epoch storage epoch = chronicleEpochs[_chronicleId][_epochId];
        require(epoch.startTime != 0, "ChronicleForge: Epoch does not exist");
        require(block.timestamp >= epoch.endTime, "ChronicleForge: Epoch has not ended yet");
        require(!epoch.resolved, "ChronicleForge: Epoch already resolved");
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracle, address _catalystTokenAddress) ERC721("ChronicleForge Chronicle", "CHRONICLE") Ownable(msg.sender) {
        require(_initialOracle != address(0), "ChronicleForge: Initial oracle cannot be zero address");
        require(_catalystTokenAddress != address(0), "ChronicleForge: Catalyst token address cannot be zero address");
        oracleAddress = _initialOracle;
        catalystToken = IERC20(_catalystTokenAddress);
    }

    // --- I. Core Chronicle Management (ERC721-like & Dynamic State) ---

    /// @notice Mints a new Chronicle NFT.
    /// @param _name The name of the Chronicle (for internal display/URI).
    /// @param _symbol The symbol of the Chronicle (for internal display/URI).
    /// @param _initialNarrativeURI The initial metadata URI for the Chronicle, pointing to its base state.
    /// @param _initialGoalImpactPoints The initial impact goal set for this Chronicle.
    /// @return The ID of the newly minted Chronicle.
    function createChronicle(
        string memory _name,
        string memory _symbol,
        string memory _initialNarrativeURI,
        uint256 _initialGoalImpactPoints
    ) public pausable returns (uint256) {
        uint256 newChronicleId = _currentTokenId++;
        _safeMint(msg.sender, newChronicleId);
        _setTokenURI(newChronicleId, _initialNarrativeURI); // Sets ERC721 URI

        chronicles[newChronicleId] = Chronicle({
            currentNarrativeURI: _initialNarrativeURI,
            totalImpactPoints: 0,
            lastEpochId: 0,
            createdAt: block.timestamp,
            creator: msg.sender,
            goalImpactPoints: _initialGoalImpactPoints
        });

        emit ChronicleCreated(newChronicleId, msg.sender, _name, _initialNarrativeURI, _initialGoalImpactPoints);
        return newChronicleId;
    }

    /// @notice Allows the owner or governance to update the main metadata URI of a Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _newURI The new metadata URI. This reflects the dynamic evolution of the Chronicle.
    function updateChronicleURI(uint256 _chronicleId, string memory _newURI) public pausable onlyChronicleOwner(_chronicleId) {
        require(bytes(_newURI).length > 0, "ChronicleForge: New URI cannot be empty");
        chronicles[_chronicleId].currentNarrativeURI = _newURI;
        _setTokenURI(_chronicleId, _newURI); // Update ERC721 URI as well
        emit ChronicleURIUpdated(_chronicleId, _newURI);
    }

    /// @notice Retrieves the current dynamic state of a Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return currentNarrativeURI, totalImpactPoints, lastEpochId, createdAt, creatorAddress, goalImpactPoints
    function getChronicleCurrentState(uint256 _chronicleId)
        public
        view
        returns (
            string memory currentNarrativeURI,
            int256 totalImpactPoints,
            uint256 lastEpochId,
            uint256 createdAt,
            address creatorAddress,
            uint256 goalImpactPoints
        )
    {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.createdAt != 0, "ChronicleForge: Chronicle does not exist"); // Ensure chronicle exists
        return (
            chronicle.currentNarrativeURI,
            chronicle.totalImpactPoints,
            chronicle.lastEpochId,
            chronicle.createdAt,
            chronicle.creator,
            chronicle.goalImpactPoints
        );
    }

    // --- II. Chronicle Evolution & Fragment Contribution ---

    /// @notice Allows users to propose a new narrative fragment for a Chronicle.
    /// @dev Requires a Catalyst token fee to prevent spam and incentivize thoughtful contributions.
    /// @param _chronicleId The ID of the Chronicle to contribute to.
    /// @param _fragmentURI The metadata URI for the fragment content (e.g., IPFS hash of text, image, etc.).
    /// @param _catalystFee The amount of Catalyst tokens to pay as a fee.
    function contributeFragment(uint256 _chronicleId, string memory _fragmentURI, uint256 _catalystFee) public pausable nonReentrant {
        require(chronicles[_chronicleId].createdAt != 0, "ChronicleForge: Chronicle does not exist");
        require(bytes(_fragmentURI).length > 0, "ChronicleForge: Fragment URI cannot be empty");
        require(_catalystFee > 0, "ChronicleForge: Catalyst fee must be greater than zero");
        require(catalystToken.transferFrom(msg.sender, address(this), _catalystFee), "ChronicleForge: Catalyst token transfer failed");

        Fragment storage newFragment = chronicleFragments[_chronicleId].push();
        newFragment.fragmentURI = _fragmentURI;
        newFragment.contributor = msg.sender;
        newFragment.submittedAtBlock = block.number;
        newFragment.yesVotes = 0;
        newFragment.noVotes = 0;
        newFragment.isApproved = false;
        newFragment.isFused = false;
        newFragment.isRetired = false;

        emit FragmentContributed(_chronicleId, chronicleFragments[_chronicleId].length - 1, msg.sender, _fragmentURI);
    }

    /// @notice Community members vote to approve or reject proposed fragments.
    /// @dev Voting power is currently 1 vote per user, but could be extended to use Narrative Karma or Catalyst balance.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _fragmentIndex The index of the fragment in the Chronicle's fragment array.
    /// @param _approve True to vote 'yes', false to vote 'no'.
    function voteOnFragment(uint256 _chronicleId, uint256 _fragmentIndex, bool _approve) public pausable canVoteOnFragment(_chronicleId, _fragmentIndex) {
        Fragment storage fragment = chronicleFragments[_chronicleId][_fragmentIndex];
        require(!fragment.isFused && !fragment.isRetired, "ChronicleForge: Fragment already processed");

        if (_approve) {
            fragment.yesVotes++;
        } else {
            fragment.noVotes++;
        }
        fragmentVotes[_chronicleId][_fragmentIndex][msg.sender] = true;

        uint256 totalVotes = fragment.yesVotes + fragment.noVotes;
        // Logic to determine approval/retirement *after* voting period ends and minimum votes are met
        if (block.number > fragment.submittedAtBlock + fragmentVotingDurationBlocks && totalVotes >= minVotesRequiredForFragment) {
            if (fragment.yesVotes >= fragment.noVotes) { // Net positive or equal votes
                fragment.isApproved = true;
                narrativeKarma[fragment.contributor] += fragmentContributionKarma;
                emit KarmaUpdated(fragment.contributor, narrativeKarma[fragment.contributor]);
            } else { // Net negative votes
                fragment.isRetired = true;
            }
        }

        emit FragmentVoted(_chronicleId, _fragmentIndex, msg.sender, _approve);
    }

    /// @notice Integrates approved fragments into the Chronicle's narrative, evolving its state.
    /// @dev Requires a Catalyst token amount for "fusion" cost. This function marks fragments as fused.
    ///      The actual update to the Chronicle's `currentNarrativeURI` would typically happen off-chain
    ///      or via a separate governance/oracle call after this.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _fragmentIndices The indices of the approved fragments to fuse.
    /// @param _fusionCatalystAmount The amount of Catalyst tokens required for fusion.
    function fuseFragments(uint256 _chronicleId, uint256[] memory _fragmentIndices, uint256 _fusionCatalystAmount) public pausable nonReentrant {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.createdAt != 0, "ChronicleForge: Chronicle does not exist");
        require(_fusionCatalystAmount > 0, "ChronicleForge: Fusion Catalyst amount must be greater than zero");
        require(catalystToken.transferFrom(msg.sender, address(this), _fusionCatalystAmount), "ChronicleForge: Catalyst token transfer failed for fusion");

        string[] memory fusedFragmentURIs = new string[](_fragmentIndices.length); // For event logging
        for (uint256 i = 0; i < _fragmentIndices.length; i++) {
            uint256 fragmentIndex = _fragmentIndices[i];
            Fragment storage fragment = chronicleFragments[_chronicleId][fragmentIndex];
            require(fragment.isApproved && !fragment.isFused, "ChronicleForge: Fragment not approved or already fused");
            fragment.isFused = true;
            fusedFragmentURIs[i] = fragment.fragmentURI;
        }

        // The actual update to chronicle.currentNarrativeURI would likely be triggered by an off-chain
        // service based on this event, or require a follow-up 'updateChronicleURI' call by governance/owner.
        // For demonstration, we'll emit a suggested new URI.
        string memory newSuggestedURI = string(abi.encodePacked(chronicle.currentNarrativeURI, "-evolved-", Strings.toString(block.timestamp)));

        emit FragmentsFused(_chronicleId, _fragmentIndices, newSuggestedURI);
    }

    /// @notice Removes a fragment, typically if it's voted against or deemed inappropriate by governance.
    /// @dev Can only be called by the contract owner, or via a governance proposal.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _fragmentIndex The index of the fragment to retire.
    function retireFragment(uint256 _chronicleId, uint256 _fragmentIndex) public pausable onlyOwner {
        Fragment storage fragment = chronicleFragments[_chronicleId][_fragmentIndex];
        require(fragment.submittedAtBlock != 0, "ChronicleForge: Fragment does not exist");
        require(!fragment.isFused, "ChronicleForge: Cannot retire a fused fragment");
        require(!fragment.isRetired, "ChronicleForge: Fragment already retired");

        fragment.isRetired = true;
        emit FragmentRetired(_chronicleId, _fragmentIndex);
    }

    // --- III. Impact Tracking & Verification ---

    /// @notice Designated oracle submits proof of real-world impact for a Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _proofURI The URI to the verifiable proof document/data (e.g., IPFS link to a report).
    /// @param _proposedImpactPoints The impact points suggested by the oracle. Can be positive or negative.
    function submitImpactProof(uint254 _chronicleId, string memory _proofURI, int256 _proposedImpactPoints) public pausable onlyOracle {
        require(chronicles[_chronicleId].createdAt != 0, "ChronicleForge: Chronicle does not exist");
        require(bytes(_proofURI).length > 0, "ChronicleForge: Proof URI cannot be empty");

        ImpactProof storage newProof = chronicleImpactProofs[_chronicleId].push();
        newProof.proofURI = _proofURI;
        newProof.submitter = msg.sender;
        newProof.proposedImpactPoints = _proposedImpactPoints;
        newProof.submittedAt = block.timestamp;
        newProof.isVerified = false;
        newProof.isApplied = false;

        emit ImpactProofSubmitted(_chronicleId, chronicleImpactProofs[_chronicleId].length - 1, msg.sender, _proposedImpactPoints);
    }

    /// @notice Governance or a committee verifies submitted impact proofs, adjusting Chronicle impact points.
    /// @dev Only callable by owner/governance.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _proofIndex The index of the impact proof within the Chronicle's array.
    /// @param _isVerified True to verify and apply the impact, false to reject.
    function verifyImpactProof(uint256 _chronicleId, uint256 _proofIndex, bool _isVerified) public pausable onlyOwner { // Can be extended to governance
        Chronicle storage chronicle = chronicles[_chronicleId];
        ImpactProof storage proof = chronicleImpactProofs[_chronicleId][_proofIndex];
        require(proof.submittedAt != 0, "ChronicleForge: Impact proof does not exist");
        require(!proof.isApplied, "ChronicleForge: Impact proof already applied");
        require(!proof.isVerified || !_isVerified, "ChronicleForge: Impact proof already verified as true"); // Prevent re-verification as true

        proof.isVerified = _isVerified;
        if (_isVerified) {
            chronicle.totalImpactPoints += proof.proposedImpactPoints;
            proof.isApplied = true;
        }

        emit ImpactProofVerified(_chronicleId, _proofIndex, _isVerified, proof.proposedImpactPoints);
    }

    /// @notice Retrieves the current total verified impact points for a Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return The total impact points (can be negative).
    function getChronicleImpactPoints(uint256 _chronicleId) public view returns (int256) {
        require(chronicles[_chronicleId].createdAt != 0, "ChronicleForge: Chronicle does not exist");
        return chronicles[_chronicleId].totalImpactPoints;
    }

    // --- IV. Epochs, Staking & Prediction Market ---

    /// @notice Initiates a new prediction epoch for a Chronicle, defining its duration and impact goal.
    /// @dev Can be started by the Chronicle owner or governance.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _duration The duration of the epoch in seconds.
    /// @param _epochGoalImpactPoints The impact point target for this epoch.
    function startNewEpoch(uint256 _chronicleId, uint256 _duration, uint256 _epochGoalImpactPoints) public pausable onlyChronicleOwner(_chronicleId) {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.createdAt != 0, "ChronicleForge: Chronicle does not exist");
        require(_duration > 0, "ChronicleForge: Epoch duration must be positive");
        
        chronicle.lastEpochId++;
        Epoch storage newEpoch = chronicleEpochs[_chronicleId][chronicle.lastEpochId];

        newEpoch.epochGoalImpactPoints = _epochGoalImpactPoints;
        newEpoch.startTime = block.timestamp;
        newEpoch.endTime = block.timestamp + _duration;
        newEpoch.resolved = false;
        newEpoch.actualOutcomeAchieved = false;
        newEpoch.totalStakedForAchieved = 0;
        newEpoch.totalStakedForFailed = 0;

        emit EpochStarted(_chronicleId, chronicle.lastEpochId, _epochGoalImpactPoints, newEpoch.endTime);
    }

    /// @notice Users stake Catalyst tokens on whether an epoch's impact goal will be achieved.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _epochId The ID of the epoch.
    /// @param _predictAchievedGoal True if predicting the goal will be achieved, false otherwise.
    /// @param _amount The amount of Catalyst tokens to stake.
    function stakeOnEpochOutcome(uint256 _chronicleId, uint256 _epochId, bool _predictAchievedGoal, uint256 _amount) public pausable nonReentrant {
        Epoch storage epoch = chronicleEpochs[_chronicleId][_epochId];
        require(epoch.startTime != 0, "ChronicleForge: Epoch does not exist");
        require(block.timestamp < epoch.endTime, "ChronicleForge: Epoch staking period has ended");
        require(!epoch.resolved, "ChronicleForge: Epoch already resolved");
        require(_amount > 0, "ChronicleForge: Stake amount must be greater than zero");
        require(catalystToken.transferFrom(msg.sender, address(this), _amount), "ChronicleForge: Catalyst token transfer failed");

        if (_predictAchievedGoal) {
            epochStakesAchieved[_chronicleId][_epochId][msg.sender] += _amount;
            epoch.totalStakedForAchieved += _amount;
        } else {
            epochStakesFailed[_chronicleId][_epochId][msg.sender] += _amount;
            epoch.totalStakedForFailed += _amount;
        }

        emit EpochStaked(_chronicleId, _epochId, msg.sender, _predictAchievedGoal, _amount);
    }

    /// @notice Oracle/governance resolves the epoch's outcome, distributing rewards to accurate stakers.
    /// @dev Callable only by the designated oracle after the epoch has ended.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _epochId The ID of the epoch.
    /// @param _actualOutcomeAchieved True if the epoch goal was actually achieved (based on Chronicle's totalImpactPoints), false otherwise.
    function resolveEpochOutcome(uint256 _chronicleId, uint256 _epochId, bool _actualOutcomeAchieved) public pausable onlyOracle canResolveEpoch(_chronicleId, _epochId) {
        Epoch storage epoch = chronicleEpochs[_chronicleId][_epochId];
        epoch.actualOutcomeAchieved = _actualOutcomeAchieved;
        epoch.resolved = true;

        emit EpochResolved(_chronicleId, _epochId, _actualOutcomeAchieved, epoch.totalStakedForAchieved, epoch.totalStakedForFailed);
    }

    /// @notice Allows successful stakers to claim their share of the prize pool.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _epochId The ID of the epoch.
    function claimEpochRewards(uint256 _chronicleId, uint256 _epochId) public pausable nonReentrant {
        Epoch storage epoch = chronicleEpochs[_chronicleId][_epochId];
        require(epoch.resolved, "ChronicleForge: Epoch not yet resolved");
        require(!epochClaimed[_chronicleId][_epochId][msg.sender], "ChronicleForge: Rewards already claimed");

        uint256 stakeAmount;
        uint256 winningPool;
        uint256 losingPool;

        // Determine if the staker won and their staked amount
        if (epoch.actualOutcomeAchieved) {
            stakeAmount = epochStakesAchieved[_chronicleId][_epochId][msg.sender];
            winningPool = epoch.totalStakedForAchieved;
            losingPool = epoch.totalStakedForFailed;
            require(stakeAmount > 0, "ChronicleForge: No winning stake found for this epoch outcome");
        } else {
            stakeAmount = epochStakesFailed[_chronuleId][_epochId][msg.sender];
            winningPool = epoch.totalStakedForFailed;
            losingPool = epoch.totalStakedForAchieved;
            require(stakeAmount > 0, "ChronicleForge: No winning stake found for this epoch outcome");
        }
        
        // Calculate reward: winners split their own pool + the losing pool proportionally to their stake.
        uint256 rewardAmount = (stakeAmount * (winningPool + losingPool)) / winningPool;
        
        require(catalystToken.transfer(msg.sender, rewardAmount), "ChronicleForge: Reward transfer failed");
        narrativeKarma[msg.sender] += correctPredictionKarma;
        emit KarmaUpdated(msg.sender, narrativeKarma[msg.sender]);
        
        epochClaimed[_chronicleId][_epochId][msg.sender] = true;
        emit EpochRewardsClaimed(_chronicleId, _epochId, msg.sender, rewardAmount);
    }

    /// @notice Retrieves the total Catalyst staked for a particular outcome in an epoch.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _epochId The ID of the epoch.
    /// @param _forAchievedGoal True to get the pool for 'achieved goal', false for 'failed goal'.
    /// @return The total amount of Catalyst tokens staked for the specified outcome.
    function getEpochPredictionPool(uint256 _chronicleId, uint256 _epochId, bool _forAchievedGoal) public view returns (uint256) {
        Epoch storage epoch = chronicleEpochs[_chronicleId][_epochId];
        require(epoch.startTime != 0, "ChronicleForge: Epoch does not exist");
        if (_forAchievedGoal) {
            return epoch.totalStakedForAchieved;
        } else {
            return epoch.totalStakedForFailed;
        }
    }


    // --- V. Reputation & Governance (DAO-like) ---

    /// @notice Retrieves the Narrative Karma score for a user.
    /// @param _user The address of the user.
    /// @return The Narrative Karma score.
    function getNarrativeKarma(address _user) public view returns (uint256) {
        return narrativeKarma[_user];
    }

    /// @notice Allows users to delegate their voting power to another address.
    /// @dev For this demo, this is a basic delegation. Actual voting power would be calculated based on Karma/Catalyst.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) public {
        require(_delegatee != address(0), "ChronicleForge: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "ChronicleForge: Cannot delegate to self");
        delegates[msg.sender] = _delegatee;
        emit DelegateSet(msg.sender, _delegatee);
    }

    /// @notice Allows users (or those meeting Karma threshold) to propose platform-wide changes or new features.
    /// @dev The _callData should be an encoded function call for this contract (or another whitelisted target).
    /// @param _callData The encoded function call to be executed if the proposal passes.
    /// @param _description A human-readable description of the proposal.
    /// @return The ID of the newly created proposal.
    function proposeGovernanceChange(bytes memory _callData, string memory _description) public pausable returns (uint256) {
        // In a full implementation, require(narrativeKarma[msg.sender] >= minKarmaForProposal)
        require(bytes(_callData).length > 0, "ChronicleForge: Call data cannot be empty");
        require(bytes(_description).length > 0, "ChronicleForge: Description cannot be empty");

        proposals.push(
            Proposal({
                id: nextProposalId,
                proposer: msg.sender,
                description: _description,
                callData: _callData,
                startBlock: block.number,
                endBlock: block.number + proposalVotingPeriodBlocks,
                yesVotes: 0,
                noVotes: 0,
                executed: false,
                hasVoted: new mapping(address => bool) // Initialize the mapping
            })
        );
        uint256 proposalId = nextProposalId;
        nextProposalId++;
        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /// @notice Community members vote on active governance proposals.
    /// @dev Voting power is currently 1-person 1-vote, but could be weighted by Narrative Karma or Catalyst holdings.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _approve True to vote 'yes', false to vote 'no'.
    function voteOnProposal(uint256 _proposalId, bool _approve) public pausable {
        require(_proposalId < proposals.length, "ChronicleForge: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "ChronicleForge: Proposal voting is not active");
        
        address voter = delegates[msg.sender] != address(0) ? delegates[msg.sender] : msg.sender;
        require(!proposal.hasVoted[voter], "ChronicleForge: Already voted on this proposal");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[voter] = true;
        emit ProposalVoted(_proposalId, voter, _approve);
    }

    /// @notice Executes a passed governance proposal.
    /// @dev Callable by anyone after the voting period ends and the proposal has met the passing criteria.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public pausable {
        require(_proposalId < proposals.length, "ChronicleForge: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endBlock, "ChronicleForge: Proposal voting period has not ended");
        require(!proposal.executed, "ChronicleForge: Proposal already executed");
        require(proposal.yesVotes >= proposal.noVotes + minNetVotesForProposalPass, "ChronicleForge: Proposal did not pass");

        // Execute the call data against this contract
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "ChronicleForge: Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Sets global parameters for fragment voting.
    /// @dev Callable only by the contract owner, or via governance proposal.
    /// @param _minVotes The minimum total votes required for a fragment to be considered for fusion/retirement.
    /// @param _voteDuration The duration of fragment voting in blocks.
    function setFragmentVotingParameters(uint256 _minVotes, uint256 _voteDuration) public pausable onlyOwner {
        require(_minVotes > 0, "ChronicleForge: Min votes must be positive");
        require(_voteDuration > 0, "ChronicleForge: Vote duration must be positive");
        minVotesRequiredForFragment = _minVotes;
        fragmentVotingDurationBlocks = _voteDuration;
        emit FragmentVotingParametersConfigured(_minVotes, _voteDuration);
    }

    // --- VI. Platform Configuration & Utility ---

    /// @notice Sets the address of the Catalyst ERC20 token.
    /// @dev Callable only by the contract owner. Essential for initial setup.
    /// @param _catalystAddress The address of the Catalyst token.
    function setCatalystTokenAddress(address _catalystAddress) public onlyOwner {
        require(_catalystAddress != address(0), "ChronicleForge: Catalyst token address cannot be zero");
        address oldAddress = address(catalystToken);
        catalystToken = IERC20(_catalystAddress);
        emit CatalystTokenAddressUpdated(oldAddress, _catalystAddress);
    }

    /// @notice Allows the owner to withdraw accumulated Catalyst fees from the contract.
    /// @dev Used to manage treasury funds collected from fragment contributions and fusion fees.
    /// @param _tokenAddress The address of the token to withdraw (e.g., Catalyst).
    /// @param _to The recipient address.
    /// @param _amount The amount to withdraw.
    function withdrawFees(address _tokenAddress, address _to, uint256 _amount) public onlyOwner nonReentrant {
        require(_to != address(0), "ChronicleForge: Recipient address cannot be zero");
        require(_amount > 0, "ChronicleForge: Amount must be greater than zero");

        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(_to, _amount), "ChronicleForge: Fee withdrawal failed");
        emit FeesWithdrawn(_tokenAddress, _to, _amount);
    }

    /// @notice Sets the trusted oracle address for submitting impact proofs and resolving epochs.
    /// @dev Callable only by the contract owner, or via governance proposal.
    /// @param _newOracle The new oracle address.
    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "ChronicleForge: Oracle address cannot be zero");
        address oldAddress = oracleAddress;
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(oldAddress, _newOracle);
    }

    /// @notice Configures the Karma rewards for specific actions within the Narrative Karma system.
    /// @dev Callable only by the contract owner, or via governance proposal.
    /// @param _fragmentContributionKarma New Karma value for contributing a fused fragment.
    /// @param _correctPredictionKarma New Karma value for a correct epoch prediction.
    function configureNarrativeKarmaSystem(uint256 _fragmentContributionKarma, uint256 _correctPredictionKarma) public onlyOwner {
        fragmentContributionKarma = _fragmentContributionKarma;
        correctPredictionKarma = _correctPredictionKarma;
        emit NarrativeKarmaConfigured(_fragmentContributionKarma, _correctPredictionKarma);
    }

    // --- Pausable Functions ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides ---

    /// @dev Returns the base URI for the token metadata, which is dynamically set per Chronicle.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://chronicleforge/base/"; // Placeholder base URI
    }

    /// @dev Overrides the ERC721 `tokenURI` to return the `currentNarrativeURI` stored in the Chronicle struct.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return chronicles[tokenId].currentNarrativeURI; // Returns the dynamic URI for this specific Chronicle
    }
}
```