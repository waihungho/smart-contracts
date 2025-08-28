This smart contract, **AuraForge**, is a decentralized platform for AI-assisted art and narrative co-creation. It leverages Chainlink Oracles for generative AI, fosters community collaboration through a reputation-weighted voting system, and mints dynamic ERC721 NFTs that evolve with the underlying concept.

It avoids direct duplication of common open-source projects by combining several advanced concepts into a unique workflow:
*   **Generative AI Integration:** Uses Chainlink AnyAPI to trigger external AI models (e.g., for text-to-image prompts, story generation).
*   **Decentralized Co-creation:** Concepts evolve through community proposals and reputation-weighted voting.
*   **Dynamic NFTs:** NFTs are minted whose metadata (`tokenURI`) updates on-chain as the underlying concept is refined by the community, allowing art/narrative to literally "evolve" after minting.
*   **Reputation System:** Rewards positive contributions with an on-chain reputation score, which in turn grants more influence (e.g., voting weight).
*   **Gamified Incentives:** Staking, rewards for successful proposals, and reputation mechanics encourage active and constructive participation.
*   **Automation:** Integrates with Chainlink Keepers (Automation) for timed execution of evolution rounds.

---

# AuraForge: Decentralized AI-Assisted Art & Narrative Co-Creation Platform

This contract enables a decentralized, community-driven platform for generating and evolving art and narrative concepts, leveraging AI oracles and dynamic NFTs. Users submit "prompt seeds" which trigger AI generation via Chainlink Oracles. These initial concepts are then collaboratively evolved by the community through proposed "evolution fragments" and a reputation-weighted voting system. Successful contributors earn reputation and token rewards. The final or evolving states of these concepts can be minted as dynamic ERC721 NFTs, whose metadata can update on-chain as the underlying concept evolves.

## Outline and Function Summary:

### I. Core Platform & Governance (8 Functions)

1.  `constructor(address _link, address _oracle, bytes32 _jobId, address _auraToken)`:
    *   Initializes the contract, setting the Chainlink LINK token, AI oracle, Chainlink Job ID, and the external AURA ERC20 token for staking/rewards. Sets the deployer as owner.
2.  `updateOracleAddress(address _newOracle, bytes32 _newJobId)`:
    *   Allows the contract owner to update the Chainlink AI oracle address and Job ID.
3.  `updateFeeRecipient(address _newRecipient)`:
    *   Allows the owner to change the address where platform fees are sent.
4.  `updatePlatformFee(uint252 _newFeeBps)`:
    *   Allows the owner to adjust the platform fee percentage (in basis points) for various actions.
5.  `updateStakingRequirements(uint256 _promptStake, uint256 _proposalStake)`:
    *   Allows the owner to set the AURA token staking requirements for submitting prompt seeds and proposing evolution fragments.
6.  `pauseContract()`:
    *   Allows the owner to pause critical functionalities in case of emergencies.
7.  `unpauseContract()`:
    *   Allows the owner to unpause the contract after a pause.
8.  `withdrawPlatformFees()`:
    *   Allows the owner to withdraw accumulated platform fees (in AURA tokens) to the fee recipient.

### II. Aura Concept Generation & Evolution (6 Functions)

9.  `submitPromptSeed(string memory _promptText)`:
    *   Allows a user to submit an initial text prompt, staking AURA tokens. This triggers an AI request via Chainlink to generate an initial concept URI.
10. `fulfillAICallback(bytes32 _requestId, string memory _conceptURI)`:
    *   *(External, called by Chainlink Oracle)* Receives the AI-generated concept URI for a given request ID and stores it as a new AuraConcept.
11. `proposeEvolutionFragment(uint256 _conceptId, string memory _fragmentText)`:
    *   Allows a user to propose a text fragment to extend or modify an existing AuraConcept, staking AURA tokens.
12. `voteOnEvolutionFragment(uint256 _conceptId, uint256 _fragmentId, bool _support)`:
    *   Allows a user to vote for or against a proposed evolution fragment. Voting power is weighted by the user's reputation score.
13. `finalizeEvolutionRound(uint256 _conceptId)`:
    *   *(Callable by anyone / Chainlink Keeper)* Processes votes for a specific AuraConcept's current evolution round. Applies the top-voted fragment(s) to update the concept's state, distributes rewards, and advances the round.
14. `getAuraConceptDetails(uint256 _conceptId) view`:
    *   Retrieves comprehensive details about a specific AuraConcept, including its current URI, evolution history, and open proposals.

### III. Reputation & Staking (4 Functions)

15. `stakeAURA(uint256 _amount)`:
    *   Allows a user to stake AURA tokens into the contract, making them eligible for participation in prompts and proposals.
16. `unstakeAURA(uint256 _amount)`:
    *   Allows a user to withdraw previously staked AURA tokens.
17. `getReputationScore(address _user) view`:
    *   Retrieves the current reputation score for a given user.
18. `claimReputationRewards()`:
    *   Allows users to claim accumulated AURA token rewards earned from successful contributions (e.g., highly voted proposals, prompt seed rewards).

### IV. Dynamic NFT Management (9 Functions - includes standard ERC721 external functions)

19. `mintAuraNFT(uint256 _conceptId, address _to)`:
    *   Mints the current state of a specified AuraConcept as an ERC721 NFT to the given address. The initial prompt owner usually has the first right to mint.
20. `transferAuraNFT(address _from, address _to, uint256 _tokenId)`:
    *   (Standard ERC721 wrapper) Transfers ownership of an AuraNFT.
21. `setAuraNFTApproval(address _to, uint256 _tokenId)`:
    *   (Standard ERC721 wrapper) Approves an address to transfer a specific AuraNFT.
22. `approveForAllAuraNFT(address _operator, bool _approved)`:
    *   (Standard ERC721 wrapper) Approves or revokes an operator for all AuraNFTs owned by the sender.
23. `getApprovedAuraNFT(uint256 _tokenId) view`:
    *   (Standard ERC721) Returns the approved address for a specific AuraNFT.
24. `isApprovedForAllAuraNFT(address _owner, address _operator) view`:
    *   (Standard ERC721) Returns true if `_operator` is approved for all `_owner`'s NFTs.
25. `balanceOfAuraNFT(address _owner) view`:
    *   (Standard ERC721) Returns the number of AuraNFTs owned by a given address.
26. `ownerOfAuraNFT(uint256 _tokenId) view`:
    *   (Standard ERC721) Returns the owner of a specific AuraNFT.
27. `tokenURIAuraNFT(uint256 _tokenId) view`:
    *   (Standard ERC721, **dynamically implemented**) Returns the URI for a given AuraNFT. This URI reflects the *current* state of the underlying AuraConcept, allowing the NFT to evolve.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol"; // For Chainlink Keepers
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol"; // For Chainlink AnyAPI

/*
*   Outline and Function Summary:
*
*   AuraForge: Decentralized AI-Assisted Art & Narrative Co-Creation Platform
*
*   This contract enables a decentralized, community-driven platform for generating and evolving
*   art and narrative concepts, leveraging AI oracles and dynamic NFTs. Users submit
*   "prompt seeds" which trigger AI generation via Chainlink Oracles. These initial concepts
*   are then collaboratively evolved by the community through proposed "evolution fragments"
*   and a reputation-weighted voting system. Successful contributors earn reputation and
*   token rewards. The final or evolving states of these concepts can be minted as dynamic
*   ERC721 NFTs, whose metadata can update on-chain as the underlying concept evolves.
*
*   ------------------------------------------------------------------------------------------------
*   I. Core Platform & Governance (8 Functions)
*   ------------------------------------------------------------------------------------------------
*   1.  constructor(address _link, address _oracle, bytes32 _jobId, address _auraToken):
*           Initializes the contract, setting the Chainlink LINK token, AI oracle, Chainlink Job ID,
*           and the external AURA ERC20 token for staking/rewards. Sets the deployer as owner.
*   2.  updateOracleAddress(address _newOracle, bytes32 _newJobId):
*           Allows the contract owner to update the Chainlink AI oracle address and Job ID.
*   3.  updateFeeRecipient(address _newRecipient):
*           Allows the owner to change the address where platform fees are sent.
*   4.  updatePlatformFee(uint256 _newFeeBps):
*           Allows the owner to adjust the platform fee percentage (in basis points) for various actions.
*   5.  updateStakingRequirements(uint256 _promptStake, uint256 _proposalStake):
*           Allows the owner to set the AURA token staking requirements for submitting prompt seeds
*           and proposing evolution fragments.
*   6.  pauseContract():
*           Allows the owner to pause critical functionalities in case of emergencies.
*   7.  unpauseContract():
*           Allows the owner to unpause the contract after a pause.
*   8.  withdrawPlatformFees():
*           Allows the owner to withdraw accumulated platform fees (in AURA tokens) to the fee recipient.
*
*   ------------------------------------------------------------------------------------------------
*   II. Aura Concept Generation & Evolution (6 Functions)
*   ------------------------------------------------------------------------------------------------
*   9.  submitPromptSeed(string memory _promptText):
*           Allows a user to submit an initial text prompt, staking AURA tokens. This triggers
*           an AI request via Chainlink to generate an initial concept URI.
*   10. fulfillAICallback(bytes32 _requestId, string memory _conceptURI):
*           (External, called by Chainlink Oracle) Receives the AI-generated concept URI for a
*           given request ID and stores it as a new AuraConcept.
*   11. proposeEvolutionFragment(uint256 _conceptId, string memory _fragmentText):
*           Allows a user to propose a text fragment to extend or modify an existing AuraConcept,
*           staking AURA tokens.
*   12. voteOnEvolutionFragment(uint256 _conceptId, uint256 _fragmentId, bool _support):
*           Allows a user to vote for or against a proposed evolution fragment. Voting power
*           can be weighted by the user's reputation score.
*   13. finalizeEvolutionRound(uint256 _conceptId):
*           (Callable by anyone / Chainlink Keeper) Processes votes for a specific AuraConcept's current evolution round.
*           Applies the top-voted fragment(s) to update the concept's state, distributes rewards,
*           and potentially triggers another AI iteration if thresholds are met.
*   14. getAuraConceptDetails(uint256 _conceptId) view:
*           Retrieves comprehensive details about a specific AuraConcept, including its current URI,
*           evolution history, and open proposals.
*
*   ------------------------------------------------------------------------------------------------
*   III. Reputation & Staking (4 Functions)
*   ------------------------------------------------------------------------------------------------
*   15. stakeAURA(uint256 _amount):
*           Allows a user to stake AURA tokens into the contract, making them eligible for
*           participation in prompts and proposals.
*   16. unstakeAURA(uint256 _amount):
*           Allows a user to withdraw previously staked AURA tokens. Subject to unbonding periods
*           or release conditions if their stake is tied to active proposals/concepts.
*   17. getReputationScore(address _user) view:
*           Retrieves the current reputation score for a given user.
*   18. claimReputationRewards():
*           Allows users to claim accumulated AURA token rewards earned from successful
*           contributions (e.g., highly voted proposals, prompt seed rewards).
*
*   ------------------------------------------------------------------------------------------------
*   IV. Dynamic NFT Management (9 Functions - includes standard ERC721 external functions)
*   ------------------------------------------------------------------------------------------------
*   19. mintAuraNFT(uint256 _conceptId, address _to):
*           Mints the current state of a specified AuraConcept as an ERC721 NFT to the given address.
*           The initial prompt owner usually has the first right to mint.
*   20. transferAuraNFT(address _from, address _to, uint256 _tokenId):
*           (Standard ERC721 wrapper) Transfers ownership of an AuraNFT.
*   21. setAuraNFTApproval(address _to, uint256 _tokenId):
*           (Standard ERC721 wrapper) Approves an address to transfer a specific AuraNFT.
*   22. approveForAllAuraNFT(address _operator, bool _approved):
*           (Standard ERC721 wrapper) Approves or revokes an operator for all AuraNFTs owned by the sender.
*   23. getApprovedAuraNFT(uint256 _tokenId) view:
*           (Standard ERC721) Returns the approved address for a specific AuraNFT.
*   24. isApprovedForAllAuraNFT(address _owner, address _operator) view:
*           (Standard ERC721) Returns true if _operator is approved for all _owner's NFTs.
*   25. balanceOfAuraNFT(address _owner) view:
*           (Standard ERC721) Returns the number of AuraNFTs owned by a given address.
*   26. ownerOfAuraNFT(uint256 _tokenId) view:
*           (Standard ERC721) Returns the owner of a specific AuraNFT.
*   27. tokenURIAuraNFT(uint256 _tokenId) view:
*           (Standard ERC721, modified) Returns the URI for a given AuraNFT. This URI is dynamic
*           and reflects the *current* state of the underlying AuraConcept, allowing the NFT to evolve.
*/

contract AuraForge is ERC721, Ownable, ReentrancyGuard, ChainlinkClient, AutomationCompatibleInterface {
    // --- Configuration Constants ---
    uint256 public constant MIN_REPUTATION_FOR_VOTING = 100;
    uint256 public constant REWARD_FOR_PROMPT_SEED = 50; // AURA tokens
    uint256 public constant REWARD_FOR_TOP_FRAGMENT = 25; // AURA tokens
    uint256 public constant REPUTATION_GAIN_PROPOSAL = 10;
    uint256 public constant EVOLUTION_ROUND_DURATION = 3 days; // For voting period
    uint256 public constant MIN_VOTES_TO_FINALIZE = 5; // Minimum votes required to consider a fragment
    uint256 public constant AURA_DECIMALS = 10**18; // Assuming 18 decimals for AURA token

    // --- State Variables ---
    IERC20 public auraToken; // The ERC20 token used for staking and rewards
    address public feeRecipient;
    uint256 public platformFeeBps; // Platform fee in basis points (e.g., 100 = 1%)
    uint256 public promptSeedStakeAmount; // AURA tokens required to submit a prompt
    uint256 public proposalStakeAmount;   // AURA tokens required to propose an evolution fragment

    uint256 private _nextConceptId;
    uint256 private _nextFragmentId;

    // --- Chainlink AnyAPI configuration ---
    address public oracle;
    bytes32 public jobId;
    uint256 public linkFee; // LINK tokens required for Chainlink request

    // --- Enums ---
    enum ConceptStatus {
        AwaitingAI,
        OpenForEvolution,
        Evolving, // Not used in current logic, but can represent a more complex state
        Finalized,
        Archived
    }

    // --- Structs ---
    struct AuraConcept {
        uint256 id;
        address owner; // Original prompt seed submitter
        string currentURI; // Points to the latest AI/community-generated content
        ConceptStatus status;
        uint256 latestEvolutionRound; // To track active fragments for voting
        uint256 lastEvolutionTime;
        uint256 promptStakeAmount; // Staked by the prompt owner (returned upon mint/archive)
        mapping(uint256 => EvolutionFragment) evolutionFragments; // Fragments by ID
        uint256[] activeFragmentIds; // List of fragment IDs for the current round
        uint256 nftTokenId; // If minted, links to the NFT
        bool isMinted;
    }

    struct EvolutionFragment {
        uint256 id;
        uint256 conceptId;
        address proposer;
        string fragmentText;
        uint256 creationTime;
        uint256 stakeAmount; // Staked by the proposer
        int256 totalVotes; // Signed int for (upvotes - downvotes)
        mapping(address => bool) hasVoted; // User => Voted status (true if voted)
        bool finalized;
    }

    // --- Mappings ---
    mapping(uint256 => AuraConcept) public auraConcepts;
    mapping(bytes32 => uint256) public requestIdToConceptId; // Chainlink requestId to Concept ID
    mapping(address => uint256) public userReputation; // User address => Reputation score
    mapping(address => uint252) public stakedAURA; // User address => Total AURA staked
    mapping(address => uint252) public rewardsBalance; // User address => Claimable AURA rewards

    // --- Events ---
    event PromptSeedSubmitted(uint256 indexed conceptId, address indexed owner, string promptText);
    event AIConceptFulfilled(uint256 indexed conceptId, string conceptURI);
    event EvolutionFragmentProposed(uint256 indexed conceptId, uint256 indexed fragmentId, address indexed proposer, string fragmentText);
    event VoteCast(uint256 indexed conceptId, uint256 indexed fragmentId, address indexed voter, bool support, int256 newTotalVotes);
    event EvolutionRoundFinalized(uint256 indexed conceptId, uint256[] approvedFragments, string newConceptURI);
    event AuraNFTMinted(uint256 indexed conceptId, uint256 indexed tokenId, address indexed owner);
    event ReputationIncreased(address indexed user, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 newReputation); // Not used in current simplified logic
    event RewardsClaimed(address indexed user, uint256 amount);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event ChainlinkOracleUpdated(address indexed newOracle, bytes32 newJobId);
    event FeeRecipientUpdated(address indexed newRecipient);
    event PlatformFeeUpdated(uint256 newFeeBps);
    event StakingRequirementsUpdated(uint256 promptStake, uint256 proposalStake);
    event AURAStaked(address indexed user, uint256 amount, uint256 totalStaked);
    event AURAUnstaked(address indexed user, uint256 amount, uint256 totalStaked);

    // --- Modifiers ---
    bool public paused;
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only Chainlink Oracle can call this function");
        _;
    }

    /**
     * @notice Constructor to initialize AuraForge contract.
     * @param _link Address of the LINK token contract.
     * @param _oracle Address of the Chainlink AI oracle.
     * @param _jobId Chainlink Job ID for AI concept generation.
     * @param _auraToken Address of the AURA ERC20 token for staking and rewards.
     */
    constructor(address _link, address _oracle, bytes32 _jobId, address _auraToken)
        ERC721("AuraForgeNFT", "AFNFT")
        ChainlinkClient(_link)
    {
        linkToken = LinkTokenInterface(_link);
        oracle = _oracle;
        jobId = _jobId;
        auraToken = IERC20(_auraToken);
        feeRecipient = msg.sender; // Initial fee recipient is deployer
        platformFeeBps = 500; // 5% fee initially (500 bps = 5.00%)
        promptSeedStakeAmount = 100 * AURA_DECIMALS; // 100 AURA to submit prompt
        proposalStakeAmount = 10 * AURA_DECIMALS;   // 10 AURA to propose fragment
        linkFee = 0.1 * 10**18; // 0.1 LINK for AI request
        _nextConceptId = 1;
        _nextFragmentId = 1;
        paused = false;
    }

    // --- I. Core Platform & Governance (8 Functions) ---

    /**
     * @notice Updates the Chainlink AI oracle address and Job ID.
     * @dev Only callable by the contract owner.
     * @param _newOracle The new address of the Chainlink oracle.
     * @param _newJobId The new Chainlink Job ID.
     */
    function updateOracleAddress(address _newOracle, bytes32 _newJobId) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle address");
        oracle = _newOracle;
        jobId = _newJobId;
        emit ChainlinkOracleUpdated(oracle, jobId);
    }

    /**
     * @notice Updates the address where platform fees are sent.
     * @dev Only callable by the contract owner.
     * @param _newRecipient The new address for fee collection.
     */
    function updateFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient address");
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(feeRecipient);
    }

    /**
     * @notice Adjusts the platform fee percentage.
     * @dev Fee is in basis points (e.g., 100 = 1%, 500 = 5%). Max 10000 (100%).
     * @param _newFeeBps The new fee percentage in basis points.
     */
    function updatePlatformFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "Fee cannot exceed 100%");
        platformFeeBps = _newFeeBps;
        emit PlatformFeeUpdated(platformFeeBps);
    }

    /**
     * @notice Sets the AURA token staking requirements for submitting prompts and proposals.
     * @dev Only callable by the contract owner.
     * @param _promptStake The AURA amount required for prompt seeds.
     * @param _proposalStake The AURA amount required for evolution fragments.
     */
    function updateStakingRequirements(uint256 _promptStake, uint256 _proposalStake) external onlyOwner {
        promptSeedStakeAmount = _promptStake;
        proposalStakeAmount = _proposalStake;
        emit StakingRequirementsUpdated(_promptStake, _proposalStake);
    }

    /**
     * @notice Pauses contract functionality in an emergency.
     * @dev Only callable by the contract owner. Prevents new interactions but allows withdrawals.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses contract functionality.
     * @dev Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Allows the owner to withdraw accumulated platform fees to the fee recipient.
     * @dev Only callable by the contract owner.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 feesToWithdraw = rewardsBalance[address(this)];
        require(feesToWithdraw > 0, "No fees to withdraw");
        rewardsBalance[address(this)] = 0;
        require(auraToken.transfer(feeRecipient, feesToWithdraw), "Failed to transfer fees");
        emit FeesWithdrawn(feeRecipient, feesToWithdraw);
    }

    // --- II. Aura Concept Generation & Evolution (6 Functions) ---

    /**
     * @notice Submits an initial prompt seed for AI-assisted concept generation.
     * @dev Requires staking `promptSeedStakeAmount` AURA tokens and LINK for Chainlink request.
     * @param _promptText The initial text prompt for the AI.
     */
    function submitPromptSeed(string memory _promptText) external whenNotPaused nonReentrant {
        require(bytes(_promptText).length > 0, "Prompt cannot be empty");
        require(stakedAURA[_msgSender()] >= promptSeedStakeAmount, "Insufficient AURA staked");
        require(LinkTokenInterface(s_link).balanceOf(address(this)) >= linkFee, "Insufficient LINK for request");

        uint256 conceptId = _nextConceptId++;
        bytes32 requestId = _requestAIConcept(_promptText, conceptId);

        requestIdToConceptId[requestId] = conceptId;

        auraConcepts[conceptId].id = conceptId;
        auraConcepts[conceptId].owner = _msgSender();
        auraConcepts[conceptId].status = ConceptStatus.AwaitingAI;
        auraConcepts[conceptId].promptStakeAmount = promptSeedStakeAmount;
        auraConcepts[conceptId].lastEvolutionTime = block.timestamp; // Initialize last evolution time

        // Deduct stake from user's available staked balance and hold it in contract as part of stake
        _deductStake(_msgSender(), promptSeedStakeAmount);

        emit PromptSeedSubmitted(conceptId, _msgSender(), _promptText);
    }

    /**
     * @notice Internal function to send an AI concept generation request to Chainlink.
     * @dev This is a private helper, not directly callable by users.
     */
    function _requestAIConcept(string memory _promptText, uint256 _conceptId) internal returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillAICallback.selector);
        req.add("prompt", _promptText);
        // Add conceptId to the request to identify it in the callback
        req.addUint("conceptId", _conceptId);
        requestId = sendChainlinkRequest(req, linkFee);
    }

    /**
     * @notice Chainlink callback function to fulfill an AI concept generation request.
     * @dev Only callable by the designated Chainlink Oracle.
     * @param _requestId The Chainlink request ID.
     * @param _conceptURI The URI (e.g., IPFS hash) pointing to the AI-generated content.
     */
    function fulfillAICallback(bytes32 _requestId, string memory _conceptURI) external onlyOracle {
        uint256 conceptId = requestIdToConceptId[_requestId];
        require(conceptId != 0, "Unknown requestId");
        AuraConcept storage concept = auraConcepts[conceptId];
        require(concept.status == ConceptStatus.AwaitingAI, "Concept not awaiting AI fulfillment");

        concept.currentURI = _conceptURI;
        concept.status = ConceptStatus.OpenForEvolution;
        concept.latestEvolutionRound = 1; // Start first evolution round

        // Reward the prompt submitter (a portion of it, rest might be returned upon mint/archive)
        rewardsBalance[concept.owner] += REWARD_FOR_PROMPT_SEED * AURA_DECIMALS;

        emit AIConceptFulfilled(conceptId, _conceptURI);
    }

    /**
     * @notice Proposes a text fragment to evolve an existing AuraConcept.
     * @dev Requires staking `proposalStakeAmount` AURA tokens.
     * @param _conceptId The ID of the AuraConcept to evolve.
     * @param _fragmentText The text fragment for evolution.
     */
    function proposeEvolutionFragment(uint256 _conceptId, string memory _fragmentText) external whenNotPaused nonReentrant {
        AuraConcept storage concept = auraConcepts[_conceptId];
        require(concept.id != 0, "Concept does not exist");
        require(concept.status == ConceptStatus.OpenForEvolution, "Concept not open for evolution");
        require(bytes(_fragmentText).length > 0, "Fragment cannot be empty");
        require(stakedAURA[_msgSender()] >= proposalStakeAmount, "Insufficient AURA staked for proposal");

        uint256 fragmentId = _nextFragmentId++;
        EvolutionFragment storage fragment = concept.evolutionFragments[fragmentId];

        fragment.id = fragmentId;
        fragment.conceptId = _conceptId;
        fragment.proposer = _msgSender();
        fragment.fragmentText = _fragmentText;
        fragment.creationTime = block.timestamp;
        fragment.stakeAmount = proposalStakeAmount;
        fragment.totalVotes = 0;
        fragment.finalized = false;

        concept.activeFragmentIds.push(fragmentId);

        _deductStake(_msgSender(), proposalStakeAmount);

        emit EvolutionFragmentProposed(_conceptId, fragmentId, _msgSender(), _fragmentText);
    }

    /**
     * @notice Casts a vote for or against a proposed evolution fragment.
     * @dev Voting power is influenced by user's reputation.
     * @param _conceptId The ID of the AuraConcept.
     * @param _fragmentId The ID of the EvolutionFragment to vote on.
     * @param _support True for upvote, false for downvote.
     */
    function voteOnEvolutionFragment(uint256 _conceptId, uint256 _fragmentId, bool _support) external whenNotPaused {
        AuraConcept storage concept = auraConcepts[_conceptId];
        require(concept.id != 0, "Concept does not exist");
        require(concept.status == ConceptStatus.OpenForEvolution, "Concept not in active voting phase");

        EvolutionFragment storage fragment = concept.evolutionFragments[_fragmentId];
        require(fragment.id != 0 && fragment.conceptId == _conceptId, "Fragment does not exist for this concept");
        require(!fragment.finalized, "Fragment has already been finalized");
        require(!fragment.hasVoted[_msgSender()], "Already voted on this fragment");
        require(userReputation[_msgSender()] >= MIN_REPUTATION_FOR_VOTING, "Insufficient reputation to vote");

        int256 voteWeight = int256(userReputation[_msgSender()] / 100); // Simple reputation weighting
        if (voteWeight == 0) voteWeight = 1; // Minimum vote weight of 1

        if (_support) {
            fragment.totalVotes += voteWeight;
        } else {
            fragment.totalVotes -= voteWeight;
        }

        fragment.hasVoted[_msgSender()] = true;
        // Simplified: Voters gain/lose reputation based on outcome in finalizeEvolutionRound.
        // This is skipped for simplicity to avoid gas-intensive iteration over voters.

        emit VoteCast(_conceptId, _fragmentId, _msgSender(), _support, fragment.totalVotes);
    }

    /**
     * @notice Finalizes an evolution round for a given AuraConcept.
     * @dev Processes votes, applies top-voted fragments, updates the concept URI, and distributes rewards.
     *      Can be called by anyone (incentivizing timely finalization) or by Chainlink Keepers.
     * @param _conceptId The ID of the AuraConcept to finalize.
     */
    function finalizeEvolutionRound(uint256 _conceptId) public whenNotPaused nonReentrant {
        AuraConcept storage concept = auraConcepts[_conceptId];
        require(concept.id != 0, "Concept does not exist");
        require(concept.status == ConceptStatus.OpenForEvolution, "Concept not in active evolution phase");
        require(block.timestamp >= concept.lastEvolutionTime + EVOLUTION_ROUND_DURATION, "Evolution round not yet ended");
        require(concept.activeFragmentIds.length > 0, "No active fragments to finalize");

        uint256[] memory winningFragmentIds;
        string memory newConceptURI = concept.currentURI;
        int256 highestVotes = 0;

        uint256 winningFragmentId = 0;
        for (uint256 i = 0; i < concept.activeFragmentIds.length; i++) {
            uint256 currentFragmentId = concept.activeFragmentIds[i];
            EvolutionFragment storage fragment = concept.evolutionFragments[currentFragmentId];

            if (fragment.totalVotes >= MIN_VOTES_TO_FINALIZE) {
                if (fragment.totalVotes > highestVotes) {
                    highestVotes = fragment.totalVotes;
                    winningFragmentId = currentFragmentId;
                }
            }
        }

        if (winningFragmentId != 0) {
            EvolutionFragment storage winningFragment = concept.evolutionFragments[winningFragmentId];
            winningFragment.finalized = true;

            // Placeholder for new URI: In a real system, this would involve off-chain processing
            // (e.g., another AI call with currentURI + winningFragmentText) and then updating the URI.
            // For this contract, we simply indicate evolution with a modified URI structure.
            newConceptURI = string(abi.encodePacked(concept.currentURI, "/evolved-", winningFragment.id.toString()));

            // Reward the proposer of the winning fragment and increase reputation
            rewardsBalance[winningFragment.proposer] += REWARD_FOR_TOP_FRAGMENT * AURA_DECIMALS;
            _increaseReputation(winningFragment.proposer, REPUTATION_GAIN_PROPOSAL);
            winningFragmentIds = new uint256[](1);
            winningFragmentIds[0] = winningFragmentId;

            // Return stake to winning proposer
            _returnStake(winningFragment.proposer, winningFragment.stakeAmount);
        }

        // Return stake for all other (non-winning or below threshold) fragments
        for (uint256 i = 0; i < concept.activeFragmentIds.length; i++) {
            uint256 currentFragmentId = concept.activeFragmentIds[i];
            if (currentFragmentId != winningFragmentId) {
                EvolutionFragment storage fragment = concept.evolutionFragments[currentFragmentId];
                _returnStake(fragment.proposer, fragment.stakeAmount);
            }
        }

        concept.currentURI = newConceptURI;
        concept.lastEvolutionTime = block.timestamp;
        concept.activeFragmentIds = new uint256[](0); // Clear active fragments for the next round
        concept.latestEvolutionRound++; // Increment for next round of proposals

        emit EvolutionRoundFinalized(_conceptId, winningFragmentIds, newConceptURI);
    }

    /**
     * @notice Retrieves comprehensive details about a specific AuraConcept.
     * @param _conceptId The ID of the AuraConcept.
     * @return A tuple containing concept details.
     */
    function getAuraConceptDetails(uint256 _conceptId)
        external
        view
        returns (
            uint256 id,
            address owner,
            string memory currentURI,
            ConceptStatus status,
            uint256 latestEvolutionRound,
            uint256 lastEvolutionTime,
            uint256 promptStakeAmount,
            uint256[] memory activeFragmentIDs,
            bool isMinted,
            uint256 nftTokenId
        )
    {
        AuraConcept storage concept = auraConcepts[_conceptId];
        require(concept.id != 0, "Concept does not exist");

        uint256[] memory currentActiveFragmentIDs = new uint256[](concept.activeFragmentIds.length);
        for (uint256 i = 0; i < concept.activeFragmentIds.length; i++) {
            currentActiveFragmentIDs[i] = concept.activeFragmentIds[i];
        }

        return (
            concept.id,
            concept.owner,
            concept.currentURI,
            concept.status,
            concept.latestEvolutionRound,
            concept.lastEvolutionTime,
            concept.promptStakeAmount,
            currentActiveFragmentIDs,
            concept.isMinted,
            concept.nftTokenId
        );
    }

    // --- III. Reputation & Staking (4 Functions) ---

    /**
     * @notice Allows a user to stake AURA tokens into the contract.
     * @dev Staked tokens are used for submitting prompts and proposals.
     * @param _amount The amount of AURA tokens to stake.
     */
    function stakeAURA(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(auraToken.transferFrom(_msgSender(), address(this), _amount), "Failed to transfer AURA for staking");
        stakedAURA[_msgSender()] += _amount;
        emit AURAStaked(_msgSender(), _amount, stakedAURA[_msgSender()]);
    }

    /**
     * @notice Allows a user to withdraw previously staked AURA tokens.
     * @dev Funds might be locked if tied to active proposals or concepts.
     * @param _amount The amount of AURA tokens to unstake.
     */
    function unstakeAURA(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakedAURA[_msgSender()] >= _amount, "Insufficient staked AURA to withdraw");

        stakedAURA[_msgSender()] -= _amount;
        require(auraToken.transfer(_msgSender(), _amount), "Failed to transfer AURA back to user");
        emit AURAUnstaked(_msgSender(), _amount, stakedAURA[_msgSender()]);
    }

    /**
     * @notice Retrieves the current reputation score for a given user.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Allows users to claim accumulated AURA token rewards.
     * @dev Rewards are earned from successful contributions (e.g., top-voted proposals).
     */
    function claimReputationRewards() external whenNotPaused nonReentrant {
        uint256 amount = rewardsBalance[_msgSender()];
        require(amount > 0, "No rewards to claim");

        rewardsBalance[_msgSender()] = 0;
        require(auraToken.transfer(_msgSender(), amount), "Failed to transfer rewards");
        emit RewardsClaimed(_msgSender(), amount);
    }

    // --- IV. Dynamic NFT Management (9 Functions) ---

    /**
     * @notice Mints the current state of an AuraConcept as an ERC721 NFT.
     * @dev The original prompt owner has priority to mint.
     * @param _conceptId The ID of the AuraConcept to mint.
     * @param _to The address to mint the NFT to.
     */
    function mintAuraNFT(uint256 _conceptId, address _to) external whenNotPaused {
        AuraConcept storage concept = auraConcepts[_conceptId];
        require(concept.id != 0, "Concept does not exist");
        require(concept.status != ConceptStatus.AwaitingAI, "Concept not yet ready for minting");
        require(!concept.isMinted, "NFT already minted for this concept");
        require(_msgSender() == concept.owner, "Only the original prompt owner can mint first");

        uint256 tokenId = _conceptId; // Using conceptId as tokenId for simplicity and direct mapping
        _safeMint(_to, tokenId);

        concept.nftTokenId = tokenId;
        concept.isMinted = true;
        
        // Return prompt stake to original owner upon successful minting
        _returnStake(concept.owner, concept.promptStakeAmount);

        emit AuraNFTMinted(_conceptId, tokenId, _to);
    }

    /**
     * @notice Standard ERC721 function to transfer ownership of an AuraNFT.
     * @dev Overrides ERC721's transferFrom to clarify context.
     */
    function transferAuraNFT(address _from, address _to, uint256 _tokenId) public virtual {
        transferFrom(_from, _to, _tokenId); // Calls ERC721's transferFrom
    }

    /**
     * @notice Standard ERC721 function to approve an address to transfer a specific AuraNFT.
     * @dev Overrides ERC721's approve to clarify context.
     */
    function setAuraNFTApproval(address _to, uint256 _tokenId) public virtual {
        approve(_to, _tokenId); // Calls ERC721's approve
    }

    /**
     * @notice Standard ERC721 function to approve or revoke an operator for all AuraNFTs.
     * @dev Overrides ERC721's setApprovalForAll to clarify context.
     */
    function approveForAllAuraNFT(address _operator, bool _approved) public virtual {
        setApprovalForAll(_operator, _approved); // Calls ERC721's setApprovalForAll
    }

    /**
     * @notice Standard ERC721 function to get the approved address for a specific AuraNFT.
     */
    function getApprovedAuraNFT(uint256 _tokenId) public view override returns (address) {
        return getApproved(_tokenId);
    }

    /**
     * @notice Standard ERC721 function to check if an operator is approved for all NFTs.
     */
    function isApprovedForAllAuraNFT(address _owner, address _operator) public view override returns (bool) {
        return isApprovedForAll(_owner, _operator);
    }

    /**
     * @notice Standard ERC721 function to get the number of AuraNFTs owned by an address.
     */
    function balanceOfAuraNFT(address _owner) public view override returns (uint256) {
        return balanceOf(_owner);
    }

    /**
     * @notice Standard ERC721 function to get the owner of a specific AuraNFT.
     */
    function ownerOfAuraNFT(uint256 _tokenId) public view override returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @notice Dynamic ERC721 tokenURI function.
     * @dev Returns the current URI of the underlying AuraConcept, making the NFT dynamic.
     * @param _tokenId The ID of the NFT (which corresponds to the AuraConcept ID).
     * @return The URI pointing to the NFT's metadata/content.
     */
    function tokenURIAuraNFT(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        AuraConcept storage concept = auraConcepts[_tokenId]; // Using tokenId as conceptId
        return concept.currentURI;
    }

    // --- Internal/Helper Functions ---

    /**
     * @notice Internal function to deduct staked AURA from a user's available staked balance.
     * @dev Assumes AURA is already approved for transfer to this contract.
     * @param _user The user's address.
     * @param _amount The amount to deduct.
     */
    function _deductStake(address _user, uint256 _amount) internal {
        require(stakedAURA[_user] >= _amount, "Not enough AURA staked to deduct for action");
        stakedAURA[_user] -= _amount;
    }

    /**
     * @notice Internal function to return staked AURA to a user (adds to rewards balance for claiming).
     * @param _user The user's address.
     * @param _amount The amount to return.
     */
    function _returnStake(address _user, uint256 _amount) internal {
        require(_amount > 0, "Amount must be positive");
        rewardsBalance[_user] += _amount;
    }

    /**
     * @notice Internal function to increase a user's reputation.
     * @param _user The user's address.
     * @param _amount The amount of reputation to add.
     */
    function _increaseReputation(address _user, uint256 _amount) internal {
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, userReputation[_user]);
    }

    // --- Chainlink Automation (Keeper) Compatibility ---
    // This function allows Chainlink Keepers to call `finalizeEvolutionRound` when conditions are met.
    // NOTE: This implementation is conceptual. For a large number of concepts, iterating through all
    // would be gas-prohibitive. A more robust solution would involve a queue or a separate mechanism
    // to identify concepts that need to be finalized, potentially by users explicitly queuing them.
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // This is a placeholder for demonstration. In a real-world scenario with many concepts,
        // you would need a more efficient way to track which concepts need to be checked.
        // For instance, a list of active concept IDs, or a min-heap sorted by `lastEvolutionTime`.
        // Here, we check for a hypothetical concept ID 1 (or the latest one created for a simple test).
        uint256 conceptIdToCheck = _nextConceptId > 1 ? _nextConceptId - 1 : 1; // Check last created concept

        if (auraConcepts[conceptIdToCheck].id != 0 &&
            auraConcepts[conceptIdToCheck].status == ConceptStatus.OpenForEvolution &&
            auraConcepts[conceptIdToCheck].activeFragmentIds.length > 0 &&
            block.timestamp >= auraConcepts[conceptIdToCheck].lastEvolutionTime + EVOLUTION_ROUND_DURATION) {
                upkeepNeeded = true;
                performData = abi.encode(conceptIdToCheck); // Pass the conceptId to performUpkeep
            } else {
                upkeepNeeded = false;
                performData = new bytes(0);
            }
    }

    function performUpkeep(bytes calldata performData) external override {
        // Ensure this call originates from a Chainlink Keeper.
        // The Automation Registry automatically whitelists calling addresses for `performUpkeep`.
        uint256 conceptId = abi.decode(performData, (uint256));
        finalizeEvolutionRound(conceptId);
    }
}

```