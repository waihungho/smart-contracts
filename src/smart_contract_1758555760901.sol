Here's a Solidity smart contract, `ArtisanForge`, designed with advanced, creative, and trendy concepts like dynamic NFTs, AI-influenced evolution (simulated via oracles), a curatorial DAO, and a reputation system. It aims to provide a unique blend of on-chain governance and off-chain computational art.

The contract features a minimum of 20 functions as requested.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Using OZ Base64 for data URI

// --- Contract Outline: ArtisanForge ---
// A decentralized platform for "Chrono-Art" NFTs – dynamic, time-evolving generative art pieces.
// These NFTs are minted by registered artists, curated by a decentralized autonomous organization (DAO)
// of art enthusiasts, and can have their evolution influenced by community interaction and
// AI-driven parameters (simulated via oracles). The platform incorporates a reputation system
// to reward valuable contributions from artists and curators.

// I. Chrono-Art NFT Management:
//    - Handles the minting of new dynamic art pieces.
//    - Allows artists to update the generative parameters of their art.
//    - Provides a mechanism to advance an NFT's "evolutionary stage," conceptually altering its state.
//    - Defines a global, DAO-governed formula that dictates how art evolves.

// II. AI Integration (Oracle & Influence):
//    - Enables whitelisted external AI models/oracles to submit analysis or "aesthetic scores" for NFTs.
//    - Provides governance functions to manage the whitelist of AI oracle providers.
//    - Allows the DAO to adjust the weight or impact of AI feedback on an art piece's evolution.

// III. Curatorial DAO & Governance:
//    - Implements a basic decentralized governance system where members can propose and vote on actions.
//    - Features liquid democracy, allowing members to delegate their voting power.
//    - Facilitates the execution of successful proposals, which can range from funding artists to altering core contract parameters.

// IV. Reputation & Roles:
//    - System for users to register as artists and for the DAO to assign curator roles.
//    - Tracks and awards reputation points for positive contributions within the platform.
//    - Reputation can be used for voting power, eligibility, or future rewards.

// V. Treasury & Rewards:
//    - Enables users to deposit funds into a communal DAO treasury.
//    - Provides a conceptual mechanism for artists to claim royalties (e.g., from future sales or engagement).
//    - Allows for the distribution of rewards to active and reputable curators.
//    - DAO-controlled withdrawal of treasury funds.

// VI. Read-Only & Utilities:
//    - Functions to query the current state of NFTs (parameters, evolution stage).
//    - Dynamically generates metadata URIs for NFTs, reflecting their current state.
//    - Provides visibility into the global evolution formula, AI feedback, and proposal details.

// --- Function Summary (24 Functions) ---

// I. Chrono-Art NFT Management (4 functions)
// 1.  `mintChronoArtNFT(address _to, string memory _initialParams, string memory _artistBioURI)`: Mints a new dynamic Chrono-Art NFT with initial generative parameters. Callable by registered artists.
// 2.  `updateArtParametersByArtist(uint256 _tokenId, string memory _newParams)`: Allows the artist of a specific NFT to modify its generative parameters within certain conceptual limits.
// 3.  `requestEvolutionTick(uint256 _tokenId)`: Advances a Chrono-Art NFT's evolutionary state by one "tick," potentially altering its visual representation based on the evolution formula and AI feedback.
// 4.  `setEvolutionFormula(string memory _newFormula)`: (Admin/DAO) Sets the global mathematical or algorithmic formula (represented as a string) that dictates how Chrono-Art NFTs evolve.

// II. AI Integration (Oracle & Influence) (3 functions)
// 5.  `submitAIFeedback(uint256 _tokenId, uint256 _score, string memory _feedbackURI)`: (Oracle) Submits an AI-generated score and feedback URI for a specific NFT, influencing its future evolution.
// 6.  `setAIFeedbackOracle(address _oracle, bool _isWhitelisted)`: (Admin/DAO) Whitelists or de-whitelists an address, granting or revoking its permission to submit AI feedback.
// 7.  `adjustAIEvolutionWeight(uint256 _newWeight)`: (Admin/DAO) Adjusts the percentage (0-100%) that AI feedback influences the art's evolution.

// III. Curatorial DAO & Governance (4 functions)
// 8.  `proposeCuratorialAction(address _target, uint256 _value, bytes memory _calldata, string memory _description)`: Allows users with sufficient reputation to create a new governance proposal for the DAO.
// 9.  `voteOnProposal(uint256 _proposalId, bool _support)`: Enables a DAO member (or their delegate) to cast a vote (for or against) on an active proposal.
// 10. `delegateVote(address _delegatee)`: Allows a DAO member to delegate their voting power (based on reputation) to another address.
// 11. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed its voting period and met quorum requirements.

// IV. Reputation & Roles (4 functions)
// 12. `registerArtist()`: Allows any address to formally register themselves as an artist on the platform, potentially gaining initial reputation.
// 13. `grantCuratorRole(address _curator)`: (Admin/DAO) Assigns the curator role to an address, granting them specific permissions and potentially initial reputation.
// 14. `_awardReputation(address _user, uint256 _amount)`: (Internal) Awards reputation points to a user for positive actions or contributions within the platform.
// 15. `getReputation(address _user)`: Retrieves the current reputation score of any given address.

// V. Treasury & Rewards (4 functions)
// 16. `depositFunds()`: Allows any user to deposit ETH into the DAO's collective treasury.
// 17. `claimRoyalties(uint256 _tokenId)`: Allows an artist to claim any accumulated royalties for their specific NFT (conceptual, requires external oracle or marketplace integration for actual accumulation).
// 18. `distributeCuratorRewards(address[] memory _curators, uint256[] memory _amounts)`: (Admin/DAO) Distributes ETH rewards from the treasury to specified curators based on their contributions.
// 19. `withdrawTreasuryFunds(address _to, uint256 _amount)`: (DAO) Allows the DAO to withdraw funds from the treasury to a specified address (via proposal execution or admin).

// VI. Read-Only & Utilities (5 functions)
// 20. `getChronoArtState(uint256 _tokenId)`: Returns an NFT's current generative parameters, evolution stage, artist address, and artist bio URI.
// 21. `getChronoArtURI(uint256 _tokenId)`: Generates and returns the dynamic metadata URI (Base64 encoded JSON) for a Chrono-Art NFT, reflecting its current state.
// 22. `getEvolutionFormula()`: Returns the currently active global evolution formula string.
// 23. `getAIFeedbackForArt(uint256 _tokenId)`: Returns the aggregated AI feedback score and the latest feedback URI for a specific NFT.
// 24. `getProposalState(uint256 _proposalId)`: Returns the current status of a governance proposal, including votes, end block, and execution status.

contract ArtisanForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Chrono-Art NFT Data
    struct ChronoArt {
        address artist;
        string currentParams; // Generative parameters (e.g., JSON string or seed)
        uint256 evolutionStage; // How many 'ticks' it has evolved
        string artistBioURI; // URI to artist's bio/portfolio
        uint256 accumulatedRoyalties; // Conceptual royalties, would be updated externally or via marketplace
        mapping(address => uint256) aiFeedbackScores; // Scores submitted by different oracles
        uint256 totalAiScore; // Sum of all AI scores from active oracles
        string aiFeedbackUri; // Latest AI feedback URI, for richer analysis
    }
    mapping(uint256 => ChronoArt) public chronoArts;
    Counters.Counter private _tokenIdCounter;
    string public evolutionFormula; // Global formula string for art evolution (e.g., "y=mx+c, AI_influence...")

    // AI Oracle Management
    mapping(address => bool) public isAIFeedbackOracle;
    uint256 public aiEvolutionWeight = 50; // Percentage (0-100) how much AI feedback influences evolution

    // Roles & Reputation
    mapping(address => bool) public isArtist;
    mapping(address => bool) public isCurator;
    mapping(address => uint256) public reputationScores;
    uint256 private _totalReputation = 0; // Tracks the sum of all reputation scores for quorum calculation

    // DAO Governance
    struct Proposal {
        address proposer;
        address target; // Address of the contract to call
        uint256 value; // ETH to send with the call
        bytes calldataPayload; // The calldata to execute on the target
        string description;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        mapping(address => bool) hasVoted; // Tracks unique voters
        uint256 creationBlock;
        uint256 endBlock;
        bool executed;
        bool passed; // Whether the proposal has passed
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public constant PROPOSAL_VOTING_PERIOD_BLOCKS = 1000; // Roughly 4-5 hours
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 50; // Percentage of total reputation needed for quorum (e.g., 50 means 50% of _totalReputation)
    uint256 public constant MIN_REPUTATION_TO_PROPOSE = 100; // Minimum reputation to create a proposal

    // Liquid Democracy for voting
    mapping(address => address) public delegates; // `msg.sender` delegates to `_delegatee`
    mapping(address => uint256) public delegatedReputation; // Stores the cumulative reputation delegated *to* an address

    // Treasury (this contract holds the funds)
    address public immutable treasuryAddress;

    // --- Events ---
    event ChronoArtMinted(uint256 indexed tokenId, address indexed artist, string initialParams);
    event ArtParametersUpdated(uint256 indexed tokenId, string newParams);
    event EvolutionTicked(uint256 indexed tokenId, uint256 newStage);
    event EvolutionFormulaUpdated(string newFormula);
    event AIFeedbackSubmitted(uint256 indexed tokenId, address indexed oracle, uint256 score, string feedbackURI);
    event AIFeedbackOracleWhitelisted(address indexed oracle, bool isWhitelisted);
    event AIEvolutionWeightAdjusted(uint256 newWeight);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationPower);
    event DelegationChanged(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ArtistRegistered(address indexed artist);
    event CuratorRoleGranted(address indexed curator);
    event ReputationAwarded(address indexed user, uint256 amount);
    event RoyaltiesClaimed(uint256 indexed tokenId, address indexed artist, uint256 amount);
    event CuratorRewardsDistributed(address indexed distributor, uint256 totalAmount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event TreasuryFundsWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyArtist(uint256 _tokenId) {
        require(_exists(_tokenId), "ArtisanForge: NFT does not exist");
        require(chronoArts[_tokenId].artist == msg.sender, "ArtisanForge: Only the artist can perform this action");
        _;
    }

    modifier onlyAIFeedbackOracle() {
        require(isAIFeedbackOracle[msg.sender], "ArtisanForge: Only whitelisted AI oracles can submit feedback");
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner)
        ERC721("ChronoArt", "CHART")
        Ownable(initialOwner)
    {
        treasuryAddress = address(this); // Contract itself holds treasury funds
        // Initial setup for the owner to be a curator and artist for testing
        isArtist[initialOwner] = true;
        isCurator[initialOwner] = true;
        _awardReputation(initialOwner, 1000); // Give initial reputation to owner
    }

    // --- ERC721 Core Functions (inherited and extended) ---

    // 1. mintChronoArtNFT: Mints a new dynamic Chrono-Art NFT
    function mintChronoArtNFT(address _to, string memory _initialParams, string memory _artistBioURI)
        public
        returns (uint256)
    {
        require(isArtist[msg.sender], "ArtisanForge: Only registered artists can mint Chrono-Art");
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_to, newItemId);
        chronoArts[newItemId].artist = msg.sender;
        chronoArts[newItemId].currentParams = _initialParams;
        chronoArts[newItemId].evolutionStage = 0;
        chronoArts[newItemId].artistBioURI = _artistBioURI;

        emit ChronoArtMinted(newItemId, msg.sender, _initialParams);
        return newItemId;
    }

    // --- Chrono-Art NFT Management ---

    // 2. updateArtParametersByArtist: Allows the artist to modify their NFT's generative parameters within limits.
    function updateArtParametersByArtist(uint256 _tokenId, string memory _newParams)
        public
        onlyArtist(_tokenId)
    {
        // Add logic here to validate _newParams based on current evolutionStage or other rules
        // e.g., require(bytes(_newParams).length < 200, "Params too long");
        // For simplicity, no specific validation logic is added beyond access control.
        chronoArts[_tokenId].currentParams = _newParams;
        emit ArtParametersUpdated(_tokenId, _newParams);
    }

    // 3. requestEvolutionTick: Advances a Chrono-Art NFT's evolutionary state, potentially altering its visual representation.
    function requestEvolutionTick(uint256 _tokenId) public {
        require(_exists(_tokenId), "ArtisanForge: NFT does not exist");
        // This function could have a cooldown, a fee, or be permissioned (e.g., only by curators or governance).
        // For this example, anyone can request a tick to demonstrate the concept.

        chronoArts[_tokenId].evolutionStage++;

        // Conceptual application of AI influence. The actual visual/parameter change happens off-chain
        // using the on-chain data (currentParams, evolutionStage, AI scores, evolutionFormula).
        // For instance, an off-chain renderer would interpret:
        // "newParams = f(currentParams, evolutionStage, totalAiScore * (aiEvolutionWeight/100), evolutionFormula)"
        // No direct on-chain modification to `currentParams` here from AI, only conceptual influence.

        emit EvolutionTicked(_tokenId, chronoArts[_tokenId].evolutionStage);
    }

    // 4. setEvolutionFormula: (Admin/DAO) Sets the global mathematical or algorithmic formula governing art evolution.
    function setEvolutionFormula(string memory _newFormula) public onlyOwner {
        // In a fully decentralized DAO, this function would only be callable via a successful proposal execution.
        // For this example, `onlyOwner` acts as an initial administrative control.
        evolutionFormula = _newFormula;
        emit EvolutionFormulaUpdated(_newFormula);
    }

    // --- AI Integration (Oracle & Influence) ---

    // 5. submitAIFeedback: (Oracle) Submits AI-generated feedback/score for a specific NFT.
    function submitAIFeedback(uint256 _tokenId, uint256 _score, string memory _feedbackURI)
        public
        onlyAIFeedbackOracle
    {
        require(_exists(_tokenId), "ArtisanForge: NFT does not exist");
        require(_score <= 100, "ArtisanForge: AI score cannot exceed 100");

        uint256 currentScoreFromSender = chronoArts[_tokenId].aiFeedbackScores[msg.sender];
        if (currentScoreFromSender > 0) {
            chronoArts[_tokenId].totalAiScore -= currentScoreFromSender; // Remove old score
        }
        chronoArts[_tokenId].aiFeedbackScores[msg.sender] = _score;
        chronoArts[_tokenId].totalAiScore += _score; // Add new score
        chronoArts[_tokenId].aiFeedbackUri = _feedbackURI; // Last one overwrites, or could be stored as an array for history

        emit AIFeedbackSubmitted(_tokenId, msg.sender, _score, _feedbackURI);
    }

    // 6. setAIFeedbackOracle: (Admin/DAO) Whitelists or de-whitelists an address as an AI feedback oracle.
    function setAIFeedbackOracle(address _oracle, bool _isWhitelisted) public onlyOwner {
        // This could also be a DAO proposal.
        isAIFeedbackOracle[_oracle] = _isWhitelisted;
        emit AIFeedbackOracleWhitelisted(_oracle, _isWhitelisted);
    }

    // 7. adjustAIEvolutionWeight: (Admin/DAO) Adjusts how much AI feedback influences the art's evolution (0-100%).
    function adjustAIEvolutionWeight(uint256 _newWeight) public onlyOwner {
        // This could also be a DAO proposal.
        require(_newWeight <= 100, "ArtisanForge: Weight must be between 0 and 100");
        aiEvolutionWeight = _newWeight;
        emit AIEvolutionWeightAdjusted(_newWeight);
    }

    // --- Curatorial DAO & Governance ---

    // 8. proposeCuratorialAction: Creates a new governance proposal for DAO members to vote on.
    function proposeCuratorialAction(address _target, uint256 _value, bytes memory _calldata, string memory _description)
        public
    {
        require(reputationScores[msg.sender] >= MIN_REPUTATION_TO_PROPOSE, "ArtisanForge: Not enough reputation to propose");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        Proposal storage p = proposals[proposalId];
        p.proposer = msg.sender;
        p.target = _target;
        p.value = _value;
        p.calldataPayload = _calldata;
        p.description = _description;
        p.creationBlock = block.number;
        p.endBlock = block.number + PROPOSAL_VOTING_PERIOD_BLOCKS;
        p.executed = false;
        p.passed = false;

        emit ProposalCreated(proposalId, msg.sender, _description, p.endBlock);
    }

    // 9. voteOnProposal: Allows a DAO member to vote on an active proposal.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage p = proposals[_proposalId];
        require(p.creationBlock != 0, "ArtisanForge: Proposal does not exist");
        require(block.number <= p.endBlock, "ArtisanForge: Voting period has ended");
        require(!p.hasVoted[msg.sender], "ArtisanForge: Already voted on this proposal");

        // Determine the actual voter, considering delegation
        address effectiveVoter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        uint256 votePower = reputationScores[effectiveVoter] + delegatedReputation[effectiveVoter];
        require(votePower > 0, "ArtisanForge: Voter has no reputation or delegated power");

        p.hasVoted[msg.sender] = true; // Mark original sender as voted to prevent double-voting
        if (_support) {
            p.voteCountFor += votePower;
        } else {
            p.voteCountAgainst += votePower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, votePower);
    }

    // 10. delegateVote: Delegates voting power to another address.
    function delegateVote(address _delegatee) public {
        require(_delegatee != msg.sender, "ArtisanForge: Cannot delegate to self");

        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee != address(0)) {
            delegatedReputation[currentDelegatee] -= reputationScores[msg.sender];
        }

        delegates[msg.sender] = _delegatee;
        delegatedReputation[_delegatee] += reputationScores[msg.sender];

        emit DelegationChanged(msg.sender, _delegatee);
    }

    // 11. executeProposal: Executes a successfully passed proposal.
    function executeProposal(uint256 _proposalId) public {
        Proposal storage p = proposals[_proposalId];
        require(p.creationBlock != 0, "ArtisanForge: Proposal does not exist");
        require(block.number > p.endBlock, "ArtisanForge: Voting period has not ended yet");
        require(!p.executed, "ArtisanForge: Proposal already executed");

        uint256 totalVotes = p.voteCountFor + p.voteCountAgainst;
        uint256 totalReputationSnapshot = _totalReputation; // Use the tracked total reputation for quorum

        require(totalVotes * 100 >= totalReputationSnapshot * PROPOSAL_QUORUM_PERCENT, "ArtisanForge: Quorum not met");
        require(p.voteCountFor > p.voteCountAgainst, "ArtisanForge: Proposal did not pass");

        p.passed = true;
        p.executed = true;

        // Execute the proposal payload
        (bool success, ) = p.target.call{value: p.value}(p.calldataPayload);
        require(success, "ArtisanForge: Proposal execution failed");

        emit ProposalExecuted(_proposalId, success);
    }

    // --- Reputation & Roles ---

    // 12. registerArtist: Allows an address to register themselves as an artist on the platform.
    function registerArtist() public {
        require(!isArtist[msg.sender], "ArtisanForge: Address is already a registered artist");
        isArtist[msg.sender] = true;
        if (reputationScores[msg.sender] == 0) { // Give a base reputation if none exists
             _awardReputation(msg.sender, 50);
        }
        emit ArtistRegistered(msg.sender);
    }

    // 13. grantCuratorRole: (Admin/DAO) Assigns the curator role to an address.
    function grantCuratorRole(address _curator) public onlyOwner {
        // This could also be a DAO proposal.
        require(!isCurator[_curator], "ArtisanForge: Address is already a curator");
        isCurator[_curator] = true;
        if (reputationScores[_curator] == 0) {
            _awardReputation(_curator, 100); // Give a base reputation if none exists
        }
        emit CuratorRoleGranted(_curator);
    }

    // 14. _awardReputation: (Internal) Awards reputation points to a user for positive actions.
    function _awardReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] += _amount;
        _totalReputation += _amount; // Update total reputation for quorum calculation
        emit ReputationAwarded(_user, _amount);
    }

    // 15. getReputation: Retrieves the current reputation score of an address.
    function getReputation(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    // --- Treasury & Rewards ---

    // 16. depositFunds: Allows anyone to deposit ETH into the DAO treasury.
    function depositFunds() public payable {
        require(msg.value > 0, "ArtisanForge: Must send non-zero ETH");
        // Funds are sent directly to the contract address (treasuryAddress is immutable this contract's address)
        emit FundsDeposited(msg.sender, msg.value);
    }

    // 17. claimRoyalties: Allows an artist to claim accumulated royalties for their NFT (conceptual).
    function claimRoyalties(uint256 _tokenId) public onlyArtist(_tokenId) {
        uint256 amount = chronoArts[_tokenId].accumulatedRoyalties;
        require(amount > 0, "ArtisanForge: No royalties to claim");

        chronoArts[_tokenId].accumulatedRoyalties = 0; // Reset royalties
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ArtisanForge: Royalty transfer failed");

        emit RoyaltiesClaimed(_tokenId, msg.sender, amount);
    }

    // 18. distributeCuratorRewards: (Admin/DAO) Distributes rewards to specified curators.
    function distributeCuratorRewards(address[] memory _curators, uint256[] memory _amounts)
        public
        onlyOwner // Could be made callable via DAO proposal execution
    {
        require(_curators.length == _amounts.length, "ArtisanForge: Array lengths must match");
        uint256 totalAmount = 0;
        for (uint i = 0; i < _curators.length; i++) {
            require(isCurator[_curators[i]], "ArtisanForge: Recipient is not a curator");
            totalAmount += _amounts[i];
        }
        require(address(this).balance >= totalAmount, "ArtisanForge: Insufficient treasury balance");

        for (uint i = 0; i < _curators.length; i++) {
            (bool success, ) = _curators[i].call{value: _amounts[i]}("");
            require(success, "ArtisanForge: Reward transfer failed");
            // Optionally award reputation for receiving rewards, 1 reputation per 1 ETH distributed
            _awardReputation(_curators[i], _amounts[i] / 1 ether);
        }
        emit CuratorRewardsDistributed(msg.sender, totalAmount);
    }

    // 19. withdrawTreasuryFunds: (DAO) Withdraws funds from the treasury to a specified address.
    function withdrawTreasuryFunds(address _to, uint256 _amount) public onlyOwner {
        // In a full DAO, this would exclusively be executed via a successful governance proposal.
        // For this example, `onlyOwner` acts as an initial administrative control.
        require(address(this).balance >= _amount, "ArtisanForge: Insufficient treasury balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ArtisanForge: Withdrawal failed");
        emit TreasuryFundsWithdrawn(_to, _amount);
    }

    // --- Read-Only & Utilities ---

    // 20. getChronoArtState: Returns an NFT's current generative parameters, evolution stage, and artist.
    function getChronoArtState(uint256 _tokenId)
        public
        view
        returns (address artist, string memory currentParams, uint256 evolutionStage, string memory artistBioURI)
    {
        require(_exists(_tokenId), "ArtisanForge: NFT does not exist");
        ChronoArt storage art = chronoArts[_tokenId];
        return (art.artist, art.currentParams, art.evolutionStage, art.artistBioURI);
    }

    // 21. getChronoArtURI: Generates and returns the dynamic metadata URI for a Chrono-Art NFT.
    function getChronoArtURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ArtisanForge: Token does not exist");
        ChronoArt storage art = chronoArts[_tokenId];

        // This URI would typically point to an API endpoint that generates JSON metadata dynamically
        // based on the on-chain state. For demonstration, we'll generate a Base64 data URI directly.
        // A real system would have richer attributes and a proper image URL.
        bytes memory json = abi.encodePacked(
            '{"name": "Chrono-Art #', _tokenId.toString(),
            '", "description": "A dynamic, evolving generative art piece, currently at stage ', art.evolutionStage.toString(),
            '. AI Score: ', art.totalAiScore.toString(),
            '. Parameters: ', art.currentParams,
            '", "image": "ipfs://QmbPlaceholderImageHash", ', // Placeholder IPFS image
            '"attributes": [',
                '{"trait_type": "Artist", "value": "', Strings.toHexString(uint160(art.artist), 20), '"},',
                '{"trait_type": "Evolution Stage", "value": ', art.evolutionStage.toString(), '},',
                '{"trait_type": "AI Influence Weight", "value": ', aiEvolutionWeight.toString(), '}',
            ']}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    // 22. getEvolutionFormula: Returns the currently active global evolution formula string.
    function getEvolutionFormula() public view returns (string memory) {
        return evolutionFormula;
    }

    // 23. getAIFeedbackForArt: Returns the aggregated AI feedback score and URI for a specific NFT.
    function getAIFeedbackForArt(uint256 _tokenId) public view returns (uint256 totalScore, string memory feedbackURI) {
        require(_exists(_tokenId), "ArtisanForge: NFT does not exist");
        return (chronoArts[_tokenId].totalAiScore, chronoArts[_tokenId].aiFeedbackUri);
    }

    // 24. getProposalState: Returns the current status of a governance proposal.
    function getProposalState(uint256 _proposalId)
        public
        view
        returns (
            address proposer,
            uint256 voteFor,
            uint256 voteAgainst,
            uint256 endBlock,
            bool executed,
            bool passed,
            string memory description
        )
    {
        Proposal storage p = proposals[_proposalId];
        require(p.creationBlock != 0, "ArtisanForge: Proposal does not exist");
        return (
            p.proposer,
            p.voteCountFor,
            p.voteCountAgainst,
            p.endBlock,
            p.executed,
            p.passed,
            p.description
        );
    }

    // --- Fallback function to receive ETH ---
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```