Here is a Solidity smart contract named `AetheriumNexus` that embodies several advanced, creative, and trendy concepts: a decentralized predictive governance system, a reputation mechanism, and dynamic NFTs whose traits can evolve based on collective foresight and external data. It aims to provide a novel ecosystem for on-chain intelligence and community-driven asset evolution.

This contract deliberately avoids direct copies of well-known open-source projects by combining multiple concepts in a specific, integrated way. For instance, while it uses standard ERC-721, the *dynamic* aspect with oracle integration for trait updates, coupled with a commit-reveal prediction market driving reputation and a liquid-democracy DAO, forms a unique synthesis.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Contract Name: AetheriumNexus

// Purpose: A decentralized platform combining predictive intelligence, dynamic NFTs,
// and reputation-weighted governance. Users commit to predictions about future events,
// earning reputation for accuracy. This reputation influences governance proposals
// and the evolution of unique Dynamic NFTs whose traits are shaped by collective foresight
// and external data.

// Modules:

// 1. Core & Access Control:
//    - Ownable: Standard ownership pattern for administrative control.
//    - Pausable: Emergency pause functionality for system stability.
//    - OracleIntegration: Manages trusted oracle addresses for external data and verification,
//      crucial for prediction market finalization and dNFT trait updates.

// 2. Reputation System:
//    - Manages non-transferable on-chain reputation scores. Reputation is earned for correct
//      predictions and can be lost for incorrect/malicious actions.
//    - Allows users to stake reputation to gain influence and voting power in governance.

// 3. Prediction Market (Commit-Reveal):
//    - Facilitates prediction rounds where users first commit a hashed prediction, then later
//      reveal the actual value. This prevents front-running.
//    - Accuracy in predictions directly impacts a user's reputation score.

// 4. Dynamic NFT (dNFT) Management (ERC-721URIStorage):
//    - Issues unique Non-Fungible Tokens (AetheriumNFTs) whose metadata (traits) are not static
//      but can be programmatically updated.
//    - NFT traits can evolve based on aggregated prediction outcomes and oracle-fed external data,
//      making them truly dynamic representations of "conceptual indices" or "future states."

// 5. Decentralized Governance (DAO):
//    - Implements a reputation-weighted voting system for community-driven proposals
//      (e.g., system upgrades, new prediction topics, fee adjustments).
//    - Features delegation support for a liquid democracy model, allowing users to
//      delegate their voting power to trusted representatives.

// ---

// Function Summary (23 custom functions, excluding standard ERC-721/Ownable functions):

// I. Core & Access Control:
// 1. constructor(): Initializes owner, ERC721 name/symbol, and sets initial NFT minting fee.
// 2. pause(): Pauses contract operations, preventing most state-changing functions (owner only).
// 3. unpause(): Unpauses contract operations (owner only).
// 4. setOracleAddress(address _oracle): Sets/updates the trusted oracle address (owner only).

// II. Reputation System:
// 5. getReputation(address _user): Returns a user's current total reputation points.
// 6. getStakedReputation(address _user): Returns a user's currently staked reputation points.
// 7. stakeReputationForInfluence(uint256 _amount): Stakes reputation points to gain voting power.
// 8. unstakeReputation(uint256 _amount): Unstakes reputation points, returning them to unstaked balance.

// III. Prediction Market:
// 9. startPredictionRound(string memory _topic, uint256 _commitEndTime, uint256 _revealEndTime):
//    Initiates a new prediction round with a specific topic and timeframes (owner/DAO only).
// 10. commitPrediction(uint256 _roundId, bytes32 _predictionHash):
//     User commits a hashed prediction value for a given round, safeguarding against front-running.
// 11. revealPrediction(uint256 _roundId, string memory _predictionValue, string memory _salt):
//     User reveals their actual prediction and salt after the commit phase, before the reveal phase ends.
// 12. callbackOraclePredictionOutcome(uint256 _roundId, string memory _actualOutcome, bytes32 _outcomeProof):
//     Oracle reports the actual outcome to finalize a prediction round, making it available for claims (oracle only).
// 13. claimPredictionReputation(uint256 _roundId, string memory _predictionValue, string memory _salt):
//     Allows users to claim reputation points after a prediction round is finalized, based on their correct prediction.
// 14. getPredictionRoundDetails(uint256 _roundId): Returns comprehensive details of a specific prediction round.

// IV. Dynamic NFT (dNFT) Management (ERC-721URIStorage functions are also implicitly available):
// 15. mintAetheriumNFT(address _to, string memory _initialTraitURI):
//     Mints a new AetheriumNFT to '_to', setting its initial traits URI (user pays a fee).
// 16. getNFTCurrentTraits(uint256 _tokenId): Returns the current traits URI for a given NFT.
// 17. callbackOracleNFTData(uint256 _tokenId, string memory _newTraitURI):
//     Oracle updates the traits URI of an AetheriumNFT, enabling its dynamic evolution (oracle only).

// V. Decentralized Governance (DAO):
// 18. proposeVote(string memory _description, address _target, bytes memory _callData, uint256 _value):
//     Creates a new governance proposal (requires a minimum amount of staked reputation).
// 19. vote(uint256 _proposalId, bool _support): Casts a vote on a proposal using a user's or their delegate's staked reputation.
// 20. executeProposal(uint256 _proposalId): Executes a successful proposal, provided quorum and majority conditions are met.
// 21. getProposalDetails(uint256 _proposalId): Returns comprehensive details of a specific governance proposal.
// 22. delegateReputationForVoting(address _delegatee): Delegates voting power to another address for liquid democracy.
// 23. undelegateReputation(): Removes any existing reputation delegation.

contract AetheriumNexus is Ownable, Pausable, ERC721URIStorage {
    // --- Constants ---
    uint256 public constant NFT_MINT_FEE = 0.01 ether; // Fee to mint an AetheriumNFT
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 1000; // Minimum reputation to propose a vote
    uint256 public constant MIN_STAKED_FOR_VOTE = 1; // Minimum staked reputation to cast a vote
    uint256 public constant PROPOSAL_VOTING_PERIOD_BLOCKS = 1000; // Number of blocks a proposal is open for voting
    uint256 public constant PROPOSAL_MAJORITY_THRESHOLD = 60; // Percentage of 'for' votes required (e.g., 60% for yes)
    uint256 public constant REPUTATION_PER_CORRECT_PREDICTION = 100; // Reputation points awarded for correct prediction
    uint256 public constant REPUTATION_BURN_FOR_INCORRECT_PREDICTION = 10; // Reputation points burned for incorrect prediction

    // --- State Variables ---
    address public oracleAddress; // Address of the trusted oracle
    uint256 private _nextTokenId; // Counter for unique NFT IDs

    // --- Reputation System ---
    mapping(address => uint256) private _reputations; // Total reputation points held by an address
    mapping(address => uint256) private _stakedReputations; // Reputation points staked for governance
    mapping(address => address) private _delegates; // Delegate mapping for liquid democracy (delegator => delegatee)
    uint256 private _totalStakedReputation; // Total reputation staked across all users for quorum calculation

    // --- Prediction Market ---
    struct PredictionRound {
        string topic; // Description of the prediction event
        uint256 commitEndTime; // Timestamp when the commit phase ends
        uint256 revealEndTime; // Timestamp when the reveal phase ends
        string actualOutcome; // The true outcome reported by the oracle
        bool finalized; // True if the round has been finalized by the oracle
        uint256 totalParticipantsCommitted; // Total unique users who committed a prediction
        uint256 correctPredictionsClaimed; // Count of users who correctly claimed reputation
        mapping(address => bytes32) commitments; // user => hashed_prediction_and_salt
        mapping(address => bool) hasCommitted; // user => true if committed for this round
        mapping(address => bool) hasRevealed; // user => true if revealed for this round
        mapping(address => bool) reputationClaimed; // user => true if reputation for this round has been claimed
    }
    PredictionRound[] public predictionRounds; // Array of all prediction rounds
    uint256 public nextPredictionRoundId; // Counter for prediction round IDs

    // --- DAO Governance ---
    struct Proposal {
        string description; // Detailed description of the proposal
        address proposer; // Address of the user who submitted the proposal
        address target; // Target contract address for the execution call
        bytes callData; // Encoded function call data for execution
        uint256 value; // Ether value to send with the execution call
        uint256 startBlock; // Block number when voting starts
        uint256 endBlock; // Block number when voting ends
        uint256 forVotes; // Total reputation points voted 'for'
        uint256 againstVotes; // Total reputation points voted 'against'
        bool executed; // True if the proposal has been executed
        bool canceled; // True if the proposal has been canceled
        mapping(address => bool) hasVoted; // Voter => true if already voted on this proposal
    }
    Proposal[] public proposals; // Array of all governance proposals
    uint256 public nextProposalId; // Counter for proposal IDs

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracle);
    event ReputationMinted(address indexed user, uint256 amount);
    event ReputationBurned(address indexed user, uint256 amount);
    event ReputationStaked(address indexed user, uint256 amount);
    event ReputationUnstaked(address indexed user, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event PredictionRoundStarted(uint256 indexed roundId, string topic, uint256 commitEndTime, uint256 revealEndTime);
    event PredictionCommitted(uint256 indexed roundId, address indexed participant, bytes32 predictionHash);
    event PredictionRevealed(uint256 indexed roundId, address indexed participant, string predictionValue);
    event PredictionRoundFinalized(uint256 indexed roundId, string actualOutcome);
    event PredictionReputationClaimed(uint256 indexed roundId, address indexed participant, bool correctPrediction, uint256 amountChanged);
    event AetheriumNFTMinted(uint256 indexed tokenId, address indexed to, string initialTraitURI);
    event AetheriumNFTTraitUpdated(uint256 indexed tokenId, string newTraitURI);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetheriumNexus: Not the oracle");
        _;
    }

    modifier canOperate() {
        _checkNotPaused();
        _;
    }

    constructor() ERC721("AetheriumNexus", "AENX") Ownable(msg.sender) {
        _nextTokenId = 1; // Start NFT IDs from 1
        nextPredictionRoundId = 0; // Prediction round IDs start from 0
        nextProposalId = 0; // Proposal IDs start from 0
        _totalStakedReputation = 0;
    }

    // --- I. Core & Access Control ---

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "AetheriumNexus: Zero address for oracle");
        oracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    // --- II. Reputation System ---

    // Internal function to mint reputation. Only called by prediction market logic.
    function _mintReputation(address _user, uint256 _amount) internal {
        _reputations[_user] += _amount;
        emit ReputationMinted(_user, _amount);
    }

    // Internal function to burn reputation. Only called by prediction market logic.
    function _burnReputation(address _user, uint256 _amount) internal {
        require(_reputations[_user] >= _amount, "AetheriumNexus: Insufficient reputation to burn");
        // Ensure that burning doesn't cause staked reputation to exceed total reputation
        require(_stakedReputations[_user] <= _reputations[_user] - _amount, "AetheriumNexus: Cannot burn more than unstaked reputation");
        _reputations[_user] -= _amount;
        emit ReputationBurned(_user, _amount);
    }

    function getReputation(address _user) public view returns (uint256) {
        return _reputations[_user];
    }

    function getStakedReputation(address _user) public view returns (uint256) {
        return _stakedReputations[_user];
    }

    function stakeReputationForInfluence(uint256 _amount) public canOperate {
        require(_amount > 0, "AetheriumNexus: Amount must be greater than zero");
        require(_reputations[_msgSender()] >= _stakedReputations[_msgSender()] + _amount, "AetheriumNexus: Insufficient unstaked reputation");

        _stakedReputations[_msgSender()] += _amount;
        _totalStakedReputation += _amount;
        emit ReputationStaked(_msgSender(), _amount);
    }

    function unstakeReputation(uint256 _amount) public canOperate {
        require(_amount > 0, "AetheriumNexus: Amount must be greater than zero");
        require(_stakedReputations[_msgSender()] >= _amount, "AetheriumNexus: Insufficient staked reputation");

        _stakedReputations[_msgSender()] -= _amount;
        _totalStakedReputation -= _amount; // Decrement total staked reputation
        emit ReputationUnstaked(_msgSender(), _amount);
    }

    // --- III. Prediction Market ---

    function startPredictionRound(
        string memory _topic,
        uint256 _commitEndTime,
        uint256 _revealEndTime
    ) public onlyOwner canOperate returns (uint256) {
        // Can be changed to DAO governance later by requiring a successful proposal execution
        require(bytes(_topic).length > 0, "AetheriumNexus: Topic cannot be empty");
        require(_commitEndTime > block.timestamp, "AetheriumNexus: Commit end time must be in the future");
        require(_revealEndTime > _commitEndTime, "AetheriumNexus: Reveal end time must be after commit end time");

        uint256 roundId = nextPredictionRoundId++;
        predictionRounds.push(
            PredictionRound({
                topic: _topic,
                commitEndTime: _commitEndTime,
                revealEndTime: _revealEndTime,
                actualOutcome: "", // Will be set by oracle
                finalized: false,
                totalParticipantsCommitted: 0,
                correctPredictionsClaimed: 0
            })
        );

        emit PredictionRoundStarted(roundId, _topic, _commitEndTime, _revealEndTime);
        return roundId;
    }

    function commitPrediction(uint256 _roundId, bytes32 _predictionHash) public canOperate {
        require(_roundId < predictionRounds.length, "AetheriumNexus: Invalid round ID");
        PredictionRound storage round = predictionRounds[_roundId];
        require(block.timestamp <= round.commitEndTime, "AetheriumNexus: Commit phase has ended");
        require(!round.hasCommitted[_msgSender()], "AetheriumNexus: Already committed for this round");
        require(_predictionHash != bytes32(0), "AetheriumNexus: Prediction hash cannot be empty");

        round.commitments[_msgSender()] = _predictionHash;
        round.hasCommitted[_msgSender()] = true;
        round.totalParticipantsCommitted++;

        emit PredictionCommitted(_roundId, _msgSender(), _predictionHash);
    }

    function revealPrediction(
        uint256 _roundId,
        string memory _predictionValue,
        string memory _salt
    ) public canOperate {
        require(_roundId < predictionRounds.length, "AetheriumNexus: Invalid round ID");
        PredictionRound storage round = predictionRounds[_roundId];
        require(block.timestamp > round.commitEndTime, "AetheriumNexus: Commit phase not ended yet");
        require(block.timestamp <= round.revealEndTime, "AetheriumNexus: Reveal phase has ended");
        require(round.hasCommitted[_msgSender()], "AetheriumNexus: No commitment found for this user");
        require(!round.hasRevealed[_msgSender()], "AetheriumNexus: Already revealed for this round");

        bytes32 expectedHash = keccak256(abi.encodePacked(_predictionValue, _salt));
        require(round.commitments[_msgSender()] == expectedHash, "AetheriumNexus: Hash mismatch");

        // We don't store the revealed prediction directly in the struct mapping to save gas.
        // The value is verified during claimPredictionReputation.
        round.hasRevealed[_msgSender()] = true; // Mark that user has successfully revealed

        emit PredictionRevealed(_roundId, _msgSender(), _predictionValue);
    }

    function callbackOraclePredictionOutcome(
        uint256 _roundId,
        string memory _actualOutcome,
        bytes32 _outcomeProof // Placeholder for verifiable proof (e.g., ZK-proof, oracle signature)
    ) public onlyOracle canOperate {
        require(_roundId < predictionRounds.length, "AetheriumNexus: Invalid round ID");
        PredictionRound storage round = predictionRounds[_roundId];
        require(!round.finalized, "AetheriumNexus: Prediction round already finalized");
        require(block.timestamp > round.revealEndTime, "AetheriumNexus: Reveal phase not ended yet");
        require(bytes(_actualOutcome).length > 0, "AetheriumNexus: Actual outcome cannot be empty");

        // In a real system, `_outcomeProof` would be verified here (e.g., against an oracle's public key).
        // For this example, we assume the oracle is trusted implicitly.

        round.actualOutcome = _actualOutcome;
        round.finalized = true;

        emit PredictionRoundFinalized(_roundId, _actualOutcome);
    }

    // Allows users to claim reputation after a prediction round is finalized.
    function claimPredictionReputation(
        uint256 _roundId,
        string memory _predictionValue,
        string memory _salt
    ) public canOperate {
        require(_roundId < predictionRounds.length, "AetheriumNexus: Invalid round ID");
        PredictionRound storage round = predictionRounds[_roundId];
        require(round.finalized, "AetheriumNexus: Prediction round not finalized yet");
        require(!round.reputationClaimed[_msgSender()], "AetheriumNexus: Reputation already claimed for this round");
        require(round.hasCommitted[_msgSender()], "AetheriumNexus: No commitment found for this user");
        require(round.hasRevealed[_msgSender()], "AetheriumNexus: Must reveal prediction to claim reputation");

        // Verify the original commitment with the provided prediction value and salt
        bytes32 expectedHash = keccak256(abi.encodePacked(_predictionValue, _salt));
        require(round.commitments[_msgSender()] == expectedHash, "AetheriumNexus: Invalid prediction or salt");

        uint256 reputationChange = 0;
        bool isCorrect = false;

        // Check if the prediction was correct
        if (keccak256(abi.encodePacked(_predictionValue)) == keccak256(abi.encodePacked(round.actualOutcome))) {
            _mintReputation(_msgSender(), REPUTATION_PER_CORRECT_PREDICTION);
            round.correctPredictionsClaimed++; // Increment count for correct claims
            reputationChange = REPUTATION_PER_CORRECT_PREDICTION;
            isCorrect = true;
        } else {
            // Optionally burn reputation for incorrect predictions
            if (_reputations[_msgSender()] > 0 && REPUTATION_BURN_FOR_INCORRECT_PREDICTION > 0) {
                 uint256 burnAmount = (_reputations[_msgSender()] < REPUTATION_BURN_FOR_INCORRECT_PREDICTION)
                                     ? _reputations[_msgSender()] : REPUTATION_BURN_FOR_INCORRECT_PREDICTION;
                _burnReputation(_msgSender(), burnAmount);
                reputationChange = burnAmount; // This would be a negative change
            }
        }
        round.reputationClaimed[_msgSender()] = true; // Mark reputation as claimed for this user/round
        emit PredictionReputationClaimed(_roundId, _msgSender(), isCorrect, reputationChange);
    }


    function getPredictionRoundDetails(uint256 _roundId)
        public
        view
        returns (
            string memory topic,
            uint256 commitEndTime,
            uint256 revealEndTime,
            string memory actualOutcome,
            bool finalized,
            uint256 totalParticipantsCommitted,
            uint256 correctPredictionsClaimed
        )
    {
        require(_roundId < predictionRounds.length, "AetheriumNexus: Invalid round ID");
        PredictionRound storage round = predictionRounds[_roundId];
        return (
            round.topic,
            round.commitEndTime,
            round.revealEndTime,
            round.actualOutcome,
            round.finalized,
            round.totalParticipantsCommitted,
            round.correctPredictionsClaimed
        );
    }

    // --- IV. Dynamic NFT (dNFT) Management ---

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://AetheriumNexus_NFT_Metadata/"; // Base URI for NFT metadata (e.g., pointing to a folder)
    }

    function mintAetheriumNFT(address _to, string memory _initialTraitURI) public payable canOperate returns (uint256) {
        require(msg.value >= NFT_MINT_FEE, "AetheriumNexus: Insufficient mint fee");

        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _initialTraitURI);

        // Refund any excess payment
        if (msg.value > NFT_MINT_FEE) {
            payable(_msgSender()).transfer(msg.value - NFT_MINT_FEE);
        }

        emit AetheriumNFTMinted(tokenId, _to, _initialTraitURI);
        return tokenId;
    }

    function getNFTCurrentTraits(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    // Oracle updates the metadata URI, effectively changing the NFT's traits dynamically.
    function callbackOracleNFTData(uint256 _tokenId, string memory _newTraitURI) public onlyOracle canOperate {
        require(_exists(_tokenId), "AetheriumNexus: NFT does not exist");
        _setTokenURI(_tokenId, _newTraitURI);
        emit AetheriumNFTTraitUpdated(_tokenId, _newTraitURI);
    }

    // --- V. Decentralized Governance (DAO) ---

    // Internal helper to get effective voting power, considering delegation.
    function getVotingPower(address _voter) internal view returns (uint256) {
        address delegatee = _delegates[_voter];
        return _stakedReputations[delegatee != address(0) ? delegatee : _voter];
    }

    function proposeVote(
        string memory _description,
        address _target,
        bytes memory _callData,
        uint256 _value
    ) public canOperate returns (uint256) {
        require(
            getReputation(_msgSender()) >= MIN_REPUTATION_FOR_PROPOSAL,
            "AetheriumNexus: Insufficient reputation to propose"
        );
        require(bytes(_description).length > 0, "AetheriumNexus: Description cannot be empty");
        require(_target != address(0), "AetheriumNexus: Target address cannot be zero");

        uint256 proposalId = nextProposalId++;
        proposals.push(
            Proposal({
                description: _description,
                proposer: _msgSender(),
                target: _target,
                callData: _callData,
                value: _value,
                startBlock: block.number,
                endBlock: block.number + PROPOSAL_VOTING_PERIOD_BLOCKS,
                forVotes: 0,
                againstVotes: 0,
                executed: false,
                canceled: false
            })
        );

        emit ProposalCreated(proposalId, _msgSender(), _description);
        return proposalId;
    }

    function vote(uint256 _proposalId, bool _support) public canOperate {
        require(_proposalId < proposals.length, "AetheriumNexus: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.startBlock, "AetheriumNexus: Voting has not started");
        require(block.number <= proposal.endBlock, "AetheriumNexus: Voting has ended");
        require(!proposal.executed, "AetheriumNexus: Proposal already executed");
        require(!proposal.canceled, "AetheriumNexus: Proposal canceled");

        address voter = _msgSender();
        // Resolve delegatee: if voter delegated, use delegatee's address for vote tracking
        address actualVoter = _delegates[voter] != address(0) ? _delegates[voter] : voter;
        uint256 votingPower = _stakedReputations[actualVoter];

        require(votingPower >= MIN_STAKED_FOR_VOTE, "AetheriumNexus: Insufficient staked reputation to vote");
        require(!proposal.hasVoted[actualVoter], "AetheriumNexus: Already voted on this proposal");

        proposal.hasVoted[actualVoter] = true;

        if (_support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }

        emit VoteCast(_proposalId, actualVoter, _support, votingPower);
    }

    function executeProposal(uint256 _proposalId) public payable canOperate {
        require(_proposalId < proposals.length, "AetheriumNexus: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "AetheriumNexus: Proposal already executed");
        require(!proposal.canceled, "AetheriumNexus: Proposal canceled");
        require(block.number > proposal.endBlock, "AetheriumNexus: Voting has not ended yet");

        uint256 totalVotesCast = proposal.forVotes + proposal.againstVotes;
        
        // Quorum check: requires a minimum total staked reputation to have participated
        // For simplicity, we use total staked reputation across ALL users.
        // A more advanced system would use a snapshot of total staked reputation at `startBlock`.
        // Here, we ensure some minimum percentage of _totalStakedReputation participated,
        // or a simpler check if _totalStakedReputation becomes very large.
        // Simplified Quorum: at least 10% of total staked reputation must have voted.
        // This is a dynamic quorum based on live staked reputation.
        require(totalVotesCast >= (_totalStakedReputation * PROPOSAL_QUORUM_PERCENTAGE) / 100, "AetheriumNexus: Proposal did not meet quorum");
        
        // Majority check
        require(
            proposal.forVotes * 100 / totalVotesCast >= PROPOSAL_MAJORITY_THRESHOLD,
            "AetheriumNexus: Proposal did not pass majority vote"
        );

        proposal.executed = true;

        // Execute the proposal by calling the target contract
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "AetheriumNexus: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            string memory description,
            address proposer,
            address target,
            bytes memory callData,
            uint256 value,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed,
            bool canceled
        )
    {
        require(_proposalId < proposals.length, "AetheriumNexus: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.description,
            proposal.proposer,
            proposal.target,
            proposal.callData,
            proposal.value,
            proposal.startBlock,
            proposal.endBlock,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed,
            proposal.canceled
        );
    }

    // Delegates voting power to another address, enabling liquid democracy.
    function delegateReputationForVoting(address _delegatee) public canOperate {
        require(_delegatee != _msgSender(), "AetheriumNexus: Cannot delegate to self");
        _delegates[_msgSender()] = _delegatee;
        emit ReputationDelegated(_msgSender(), _delegatee);
    }

    // Removes any existing reputation delegation.
    function undelegateReputation() public canOperate {
        require(_delegates[_msgSender()] != address(0), "AetheriumNexus: No delegation to remove");
        delete _delegates[_msgSender()];
        emit ReputationDelegated(_msgSender(), address(0)); // Emitting with address(0) to signify undelegation
    }

    // --- ERC-721 Overrides (Standard, implicitly available from ERC721URIStorage) ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Standard ERC-721 functions (e.g., balanceOf, ownerOf, transferFrom, approve, etc.)
    // are inherited from ERC721URIStorage and are implicitly available.

    // Allow direct Ether deposits, e.g., for the contract treasury or for NFT minting.
    receive() external payable {
        // Can be customized to explicitly handle deposits, e.g., sending to a treasury
        // or accepting only for specific functions if needed.
    }
}
```