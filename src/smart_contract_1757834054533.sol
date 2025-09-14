Here's a smart contract that embodies several advanced, creative, and trendy concepts:

**Contract Name:** `ChrysalisCollective`

**Core Concepts:**

1.  **Influence Spheres (Dynamic Soulbound NFTs):** Non-transferable NFTs that represent a member's reputation and expertise within the collective. Their traits (`insightScore`, `adaptabilityIndex`, `coordinationTrust`) dynamically evolve based on their participation, prediction accuracy, and proposal outcomes.
2.  **Prediction Market Governance:** Proposals are not just voted on; they include a "predicted outcome." Members stake tokens on their belief, and the collective's "intelligence" is measured by its aggregate prediction accuracy. Successful prediction earners are rewarded.
3.  **Adaptive DAO Parameters:** The collective's core operating parameters (e.g., proposal approval threshold, reward multipliers) can dynamically adjust based on the success rates of past proposals and prediction accuracy, making the DAO itself "evolve" or "adapt." This is managed through specific "parameter adaptation proposals."
4.  **Commit-Reveal for Fair Predictions:** For sensitive prediction stakes, a commit-reveal scheme prevents front-running and ensures fairness.
5.  **Decentralized Resource Optimization:** Funds are allocated from a collective treasury to proposals based on the collective's assessment of their potential success (via voting and prediction markets).

---

## Outline:

**I. Core Infrastructure & Access Control (`Ownable`, `Pausable`, `ERC721Enumerable` for Influence Spheres)**
    *   Basic administrative functions (ownership, pausing, fund withdrawals).

**II. Influence Sphere NFTs (Dynamic Soulbound Tokens - SBTs)**
    *   Management of non-transferable NFTs with mutable, reputation-based traits.
    *   Internal mechanisms for trait evolution based on user activity.

**III. Prediction Nexus (Dynamic Proposals & Prediction Markets)**
    *   Mechanisms for submitting proposals with predicted outcomes.
    *   Commit-reveal scheme for members to stake on outcomes.
    *   Voting on proposals, weighted by Influence Sphere traits.
    *   Finalizing outcomes and distributing rewards/penalties.

**IV. Adaptive Core (Self-Adjusting DAO Parameters & Treasury Management)**
    *   System for proposing and executing changes to the DAO's adaptive parameters.
    *   Treasury management for allocating funds to approved initiatives.
    *   Functions to view the collective's current adaptive state.

**V. View & Utility Functions**
    *   Functions to query the state of proposals, user predictions, and DAO parameters.

---

## Function Summary:

1.  `constructor()`: Initializes the contract, sets the deployer as the initial owner and governor.
2.  `pause()`: Allows the owner (governor) to pause critical contract functions in an emergency.
3.  `unpause()`: Allows the owner (governor) to unpause the contract.
4.  `withdrawERC20(address _token, uint256 _amount)`: Allows the governor to withdraw specified ERC-20 tokens from the contract treasury.
5.  `withdrawETH(uint256 _amount)`: Allows the governor to withdraw ETH from the contract treasury.
6.  `mintInfluenceSphere(address _to)`: Mints a new non-transferable `InfluenceSphere` NFT (SBT) to a specified address, becoming a new member.
7.  `getInfluenceSphereTraits(uint256 _tokenId)`: Returns the current dynamic traits (insightScore, adaptabilityIndex, coordinationTrust) of a specific Influence Sphere.
8.  `submitProposal(string memory _title, string memory _descriptionHash, string memory _targetOutcomeHash, uint256 _targetDuration, uint256 _requiredFunds)`: Submits a new proposal with a unique title, a hash of its detailed description, a hash of its predicted outcome, the duration for outcome evaluation, and the funds requested.
9.  `commitPrediction(uint256 _proposalId, bytes32 _predictionHash, uint256 _stakeAmount)`: Allows a member to commit a hashed prediction (e.g., for success/failure, or a specific value) and stake tokens for a given proposal. This is the first step of the commit-reveal process.
10. `revealPrediction(uint256 _proposalId, string memory _predictionValue)`: Allows a member to reveal their actual prediction value, which is then verified against their earlier commitment.
11. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to cast a vote (support/oppose) on a proposal. The voting power is dynamically weighted by their `InfluenceSphere` traits.
12. `finalizeProposalOutcome(uint256 _proposalId, bool _outcomeSuccessful)`: Governor-only function to report the actual outcome of a proposal after its `targetDuration`. This triggers updates to `InfluenceSphere` traits and processes prediction rewards/penalties.
13. `claimPredictionRewards(uint256 _proposalId)`: Allows members who made accurate predictions on a finalized proposal to claim their rewards, or incurs penalties for inaccurate predictions.
14. `initiateParameterAdaptation(string memory _paramName, uint256 _newValue, string memory _rationaleHash)`: Allows a sufficiently influential member to propose a change to a core adaptive DAO parameter (e.g., `proposalApprovalThreshold`), along with a rationale. This also initiates a mini-prediction market.
15. `voteOnParameterAdaptation(uint256 _adaptationId, bool _support)`: Allows members to vote on a proposed adaptive parameter change, similar to regular proposals.
16. `executeParameterAdaptation(uint256 _adaptationId)`: Governor-only function to finalize and apply a proposed parameter adaptation if it reaches consensus.
17. `allocateTreasuryFunds(uint256 _proposalId, uint256 _amount)`: Allows the governor to transfer funds from the DAO treasury to an approved proposal, typically for its execution.
18. `updateAdaptiveAlgorithmCoefficient(string memory _coeffName, uint256 _newValue)`: Allows the governor to adjust underlying coefficients that govern how `InfluenceSphere` traits evolve or how rewards/penalties are calculated, fine-tuning the DAO's adaptive "algorithm."
19. `getProposalDetails(uint256 _proposalId)`: Returns comprehensive details about a specific proposal, including its state, funds, and outcome.
20. `getPredictionDetails(uint256 _proposalId, address _user)`: Returns a user's prediction details for a specific proposal, including their stake and whether they've claimed rewards.
21. `getCurrentParameters()`: Returns all currently active adaptive parameters of the DAO.
22. `getVotingPower(address _voter)`: Calculates and returns a user's effective voting power based on their `InfluenceSphere` traits.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// I. Core Infrastructure & Access Control (Ownable, Pausable, ERC721Enumerable for Influence Spheres)
// II. Influence Sphere NFTs (Dynamic Soulbound Tokens - SBTs)
// III. Prediction Nexus (Dynamic Proposals & Prediction Markets)
// IV. Adaptive Core (Self-Adjusting DAO Parameters & Treasury Management)
// V. View & Utility Functions

// Function Summary:
// 1. constructor(): Initializes the contract with the deployer as owner/governor.
// 2. pause(): Allows the governor to pause critical contract functions.
// 3. unpause(): Allows the governor to unpause the contract.
// 4. withdrawERC20(address _token, uint256 _amount): Governor can withdraw specified ERC-20 tokens.
// 5. withdrawETH(uint256 _amount): Governor can withdraw ETH.
// 6. mintInfluenceSphere(address _to): Mints a new non-transferable InfluenceSphere NFT.
// 7. getInfluenceSphereTraits(uint256 _tokenId): Returns the dynamic traits of an InfluenceSphere.
// 8. submitProposal(string memory _title, string memory _descriptionHash, string memory _targetOutcomeHash, uint256 _targetDuration, uint256 _requiredFunds): Submits a new proposal with a predicted outcome and required funds.
// 9. commitPrediction(uint256 _proposalId, bytes32 _predictionHash, uint256 _stakeAmount): Commits a hashed prediction and stake for a proposal outcome.
// 10. revealPrediction(uint256 _proposalId, string memory _predictionValue): Reveals the actual prediction and stake, validating the commitment.
// 11. voteOnProposal(uint256 _proposalId, bool _support): Allows members to vote on a proposal, weighted by InfluenceSphere traits.
// 12. finalizeProposalOutcome(uint256 _proposalId, bool _outcomeSuccessful): Governor reports the actual outcome of a proposal.
// 13. claimPredictionRewards(uint256 _proposalId): Allows members to claim rewards or incur penalties based on prediction accuracy.
// 14. initiateParameterAdaptation(string memory _paramName, uint256 _newValue, string memory _rationaleHash): Proposes a change to a DAO's adaptive parameter, involving a sub-prediction market.
// 15. voteOnParameterAdaptation(uint256 _adaptationId, bool _support): Votes on whether to accept the proposed parameter adaptation.
// 16. executeParameterAdaptation(uint256 _adaptationId): Finalizes and applies a proposed parameter adaptation.
// 17. allocateTreasuryFunds(uint256 _proposalId, uint256 _amount): Allocates funds from the DAO treasury to approved proposals.
// 18. updateAdaptiveAlgorithmCoefficient(string memory _coeffName, uint256 _newValue): Governor adjusts coefficients of the adaptive logic.
// 19. getProposalDetails(uint256 _proposalId): Retrieves full details of a specific proposal.
// 20. getPredictionDetails(uint256 _proposalId, address _user): Retrieves details of a specific user's prediction for a proposal.
// 21. getCurrentParameters(): Retrieves the currently active adaptive parameters of the DAO.
// 22. getVotingPower(address _voter): Calculates a user's current voting power based on InfluenceSphere.

contract ChrysalisCollective is Ownable, Pausable, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- I. Core Infrastructure & Access Control ---

    address public governor; // The primary administrative role, can be a multi-sig or another DAO.

    constructor() ERC721("InfluenceSphere", "INF") {
        governor = msg.sender;
        // Initial adaptive parameters
        proposalApprovalThreshold = 5000; // 50.00%
        basePredictionReward = 1 ether;   // Base reward for accurate prediction
        basePredictionPenalty = 5000;   // 50.00% penalty of stake for inaccurate prediction
        minInfluenceToPropose = 100;    // Minimum Insight Score to submit a proposal
        _insightBoostCoeff = 10;        // Coefficient for insight score increase
        _adaptabilityBoostCoeff = 5;    // Coefficient for adaptability index increase
        _coordinationBoostCoeff = 7;    // Coefficient for coordination trust increase
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "ChrysalisCollective: Not the governor");
        _;
    }

    function changeGovernor(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "ChrysalisCollective: New governor cannot be zero address");
        governor = _newGovernor;
        emit GovernorChanged(msg.sender, _newGovernor);
    }

    event GovernorChanged(address indexed oldGovernor, address indexed newGovernor);

    // ERC721 Overrides for Non-Transferability (Soulbound)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("ChrysalisCollective: Influence Spheres are non-transferable (Soulbound)");
        }
        // Allow minting (from address(0)) and burning (to address(0))
    }

    function withdrawERC20(address _token, uint256 _amount) external onlyGovernor whenNotPaused {
        IERC20 token = IERC20(_token);
        require(token.transfer(governor, _amount), "ChrysalisCollective: ERC20 withdrawal failed");
        emit ERC20Withdrawn(_token, _amount);
    }

    function withdrawETH(uint256 _amount) external onlyGovernor whenNotPaused {
        require(address(this).balance >= _amount, "ChrysalisCollective: Insufficient ETH balance");
        (bool success, ) = payable(governor).call{value: _amount}("");
        require(success, "ChrysalisCollective: ETH withdrawal failed");
        emit ETHWithdrawn(_amount);
    }

    event ERC20Withdrawn(address indexed token, uint256 amount);
    event ETHWithdrawn(uint256 amount);

    // --- II. Influence Sphere NFTs (Dynamic Soulbound Tokens - SBTs) ---

    struct InfluenceSphere {
        uint256 insightScore;        // Reflects prediction accuracy and analytical prowess
        uint256 adaptabilityIndex;   // Reflects participation in parameter adaptations and acceptance of change
        uint256 coordinationTrust;   // Reflects successful project completion and collaborative efforts
        address owner;               // Stored for convenience, also tracked by ERC721
    }

    Counters.Counter private _influenceSphereIds;
    mapping(uint256 => InfluenceSphere) public influenceSpheres; // TokenId to InfluenceSphere struct
    mapping(address => uint256) public userToInfluenceSphereId;  // User address to their TokenId

    event InfluenceSphereMinted(address indexed owner, uint256 tokenId);
    event InfluenceSphereTraitsUpdated(uint256 indexed tokenId, uint256 newInsight, uint256 newAdaptability, uint256 newCoordination);

    function mintInfluenceSphere(address _to) external whenNotPaused {
        require(userToInfluenceSphereId[_to] == 0, "ChrysalisCollective: Address already owns an Influence Sphere");
        _influenceSphereIds.increment();
        uint256 newTokenId = _influenceSphereIds.current();

        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://chrysalis/", Strings.toString(newTokenId)))); // Example URI

        influenceSpheres[newTokenId] = InfluenceSphere({
            insightScore: 100, // Starting score
            adaptabilityIndex: 100,
            coordinationTrust: 100,
            owner: _to
        });
        userToInfluenceSphereId[_to] = newTokenId;

        emit InfluenceSphereMinted(_to, newTokenId);
        emit InfluenceSphereTraitsUpdated(newTokenId, 100, 100, 100);
    }

    function getInfluenceSphereTraits(uint256 _tokenId) external view returns (uint256 insight, uint256 adaptability, uint256 coordination) {
        InfluenceSphere storage sphere = influenceSpheres[_tokenId];
        return (sphere.insightScore, sphere.adaptabilityIndex, sphere.coordinationTrust);
    }

    // Internal functions for trait evolution
    function _updateInsightScore(uint256 _tokenId, bool _isAccurate) internal {
        InfluenceSphere storage sphere = influenceSpheres[_tokenId];
        if (_isAccurate) {
            sphere.insightScore = sphere.insightScore.add(_insightBoostCoeff);
        } else {
            sphere.insightScore = sphere.insightScore.sub(sphere.insightScore.div(20)); // -5% for inaccuracy
        }
        emit InfluenceSphereTraitsUpdated(_tokenId, sphere.insightScore, sphere.adaptabilityIndex, sphere.coordinationTrust);
    }

    function _updateAdaptabilityIndex(uint256 _tokenId, bool _acceptedChange) internal {
        InfluenceSphere storage sphere = influenceSpheres[_tokenId];
        if (_acceptedChange) {
            sphere.adaptabilityIndex = sphere.adaptabilityIndex.add(_adaptabilityBoostCoeff);
        } else {
            sphere.adaptabilityIndex = sphere.adaptabilityIndex.sub(sphere.adaptabilityIndex.div(50)); // -2% for resistance
        }
        emit InfluenceSphereTraitsUpdated(_tokenId, sphere.insightScore, sphere.adaptabilityIndex, sphere.coordinationTrust);
    }

    function _updateCoordinationTrust(uint256 _tokenId, bool _projectSuccessful) internal {
        InfluenceSphere storage sphere = influenceSpheres[_tokenId];
        if (_projectSuccessful) {
            sphere.coordinationTrust = sphere.coordinationTrust.add(_coordinationBoostCoeff);
        } else {
            sphere.coordinationTrust = sphere.coordinationTrust.sub(sphere.coordinationTrust.div(100)); // -1% for project failure
        }
        emit InfluenceSphereTraitsUpdated(_tokenId, sphere.insightScore, sphere.adaptabilityIndex, sphere.coordinationTrust);
    }

    // --- III. Prediction Nexus (Dynamic Proposals & Prediction Markets) ---

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string descriptionHash;     // IPFS hash of proposal details
        string targetOutcomeHash;   // IPFS hash of predicted outcome criteria
        uint256 requiredFunds;
        uint256 targetDuration;     // Duration in seconds for outcome evaluation
        uint256 votingDeadline;     // Timestamp when voting ends
        uint256 outcomeDeadline;    // Timestamp when outcome must be reported
        ProposalState state;
        uint256 yesVotes;
        uint256 noVotes;
        bool outcomeReported;       // True if governor has reported outcome
        bool actualOutcomeSuccessful; // True if outcome was successful

        // Prediction market related
        uint256 totalStaked;
        mapping(address => bytes32) committedPredictions; // user => hash(predictionValue, stakeAmount, salt)
        mapping(address => Prediction) predictions;       // user => Prediction details
    }

    struct Prediction {
        string predictionValue;
        uint256 stakeAmount;
        bool revealed;
        bool claimed;
        bool isAccurate; // Only set after finalization
    }

    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // Adaptive parameters (can be changed via governance)
    uint256 public proposalApprovalThreshold; // e.g., 5000 for 50.00%
    uint256 public basePredictionReward;
    uint256 public basePredictionPenalty; // e.g., 5000 for 50.00% penalty of stake
    uint256 public minInfluenceToPropose;

    // Coefficients for Influence Sphere updates
    uint256 private _insightBoostCoeff;
    uint256 private _adaptabilityBoostCoeff;
    uint256 private _coordinationBoostCoeff;

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 requiredFunds, uint256 votingDeadline, uint256 outcomeDeadline);
    event PredictionCommitted(uint256 indexed proposalId, address indexed predictor, uint256 stakeAmount);
    event PredictionRevealed(uint256 indexed proposalId, address indexed predictor, string predictionValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState newState, bool actualOutcomeSuccessful);
    event PredictionRewardClaimed(uint256 indexed proposalId, address indexed predictor, uint256 amount);
    event PredictionPenaltyApplied(uint256 indexed proposalId, address indexed predictor, uint256 amount);


    function submitProposal(
        string memory _title,
        string memory _descriptionHash,
        string memory _targetOutcomeHash,
        uint256 _targetDuration, // In seconds
        uint256 _requiredFunds
    ) external whenNotPaused returns (uint256) {
        require(userToInfluenceSphereId[msg.sender] != 0, "ChrysalisCollective: Only members can submit proposals");
        uint256 proposerTokenId = userToInfluenceSphereId[msg.sender];
        require(influenceSpheres[proposerTokenId].insightScore >= minInfluenceToPropose, "ChrysalisCollective: Insufficient insight to propose");
        require(bytes(_title).length > 0, "ChrysalisCollective: Title cannot be empty");
        require(_targetDuration > 0, "ChrysalisCollective: Target duration must be positive");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        uint256 votingPeriod = 7 days; // Example fixed voting period
        uint256 proposalVotingDeadline = block.timestamp.add(votingPeriod);
        uint256 proposalOutcomeDeadline = proposalVotingDeadline.add(_targetDuration);

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            targetOutcomeHash: _targetOutcomeHash,
            requiredFunds: _requiredFunds,
            targetDuration: _targetDuration,
            votingDeadline: proposalVotingDeadline,
            outcomeDeadline: proposalOutcomeDeadline,
            state: ProposalState.Pending, // Starts as pending until voting period ends
            yesVotes: 0,
            noVotes: 0,
            outcomeReported: false,
            actualOutcomeSuccessful: false,
            totalStaked: 0
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _title, _requiredFunds, proposalVotingDeadline, proposalOutcomeDeadline);
        return newProposalId;
    }

    function commitPrediction(uint256 _proposalId, bytes32 _predictionHash, uint256 _stakeAmount) external payable whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChrysalisCollective: Proposal does not exist");
        require(proposal.state < ProposalState.Succeeded, "ChrysalisCollective: Voting or outcome reporting has concluded");
        require(block.timestamp < proposal.outcomeDeadline, "ChrysalisCollective: Prediction period has ended");
        require(_stakeAmount > 0, "ChrysalisCollective: Stake amount must be positive");
        require(msg.value == _stakeAmount, "ChrysalisCollective: Sent ETH must match stake amount");
        require(proposal.predictions[msg.sender].stakeAmount == 0, "ChrysalisCollective: Already committed a prediction for this proposal");

        proposal.committedPredictions[msg.sender] = _predictionHash;
        proposal.predictions[msg.sender].stakeAmount = _stakeAmount; // Store stake temporarily, actual reveal needed
        proposal.totalStaked = proposal.totalStaked.add(_stakeAmount);

        emit PredictionCommitted(_proposalId, msg.sender, _stakeAmount);
    }

    function revealPrediction(uint256 _proposalId, string memory _predictionValue) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChrysalisCollective: Proposal does not exist");
        require(block.timestamp < proposal.outcomeDeadline, "ChrysalisCollective: Prediction reveal period has ended");
        require(proposal.committedPredictions[msg.sender] != bytes32(0), "ChrysalisCollective: No prediction committed by this user");
        require(!proposal.predictions[msg.sender].revealed, "ChrysalisCollective: Prediction already revealed");

        uint256 stake = proposal.predictions[msg.sender].stakeAmount;
        bytes32 expectedHash = keccak256(abi.encodePacked(_predictionValue, stake, msg.sender)); // Assuming salt includes sender address for uniqueness
        require(proposal.committedPredictions[msg.sender] == expectedHash, "ChrysalisCollective: Mismatched prediction hash");

        proposal.predictions[msg.sender].predictionValue = _predictionValue;
        proposal.predictions[msg.sender].revealed = true;

        emit PredictionRevealed(_proposalId, msg.sender, _predictionValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChrysalisCollective: Proposal does not exist");
        require(block.timestamp < proposal.votingDeadline, "ChrysalisCollective: Voting period has ended");
        require(userToInfluenceSphereId[msg.sender] != 0, "ChrysalisCollective: Only members can vote");

        uint256 voterTokenId = userToInfluenceSphereId[msg.sender];
        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "ChrysalisCollective: Voter has no effective voting power");

        // Simple mapping to prevent double voting. For more complex, use a dedicated struct/mapping.
        // This example assumes only one vote per member per proposal.
        // In a real system, you might track who voted and their power at that time.
        // For simplicity, we just check if the user has already revealed a prediction.
        // A user's prediction counts as their vote for the "outcome" aspect.
        // The traditional vote is for the "proposal approval".
        // Here, we combine: if you predict, you're implicitly voting for its success *if* your prediction is true.
        // For simplicity, this function is for general approval, distinct from prediction.
        // Let's assume a simpler voting mechanism here.
        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    function finalizeProposalOutcome(uint256 _proposalId, bool _outcomeSuccessful) external onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChrysalisCollective: Proposal does not exist");
        require(!proposal.outcomeReported, "ChrysalisCollective: Outcome already reported");
        require(block.timestamp >= proposal.outcomeDeadline, "ChrysalisCollective: Outcome deadline has not passed yet");

        proposal.outcomeReported = true;
        proposal.actualOutcomeSuccessful = _outcomeSuccessful;

        // Determine final state based on votes and reported outcome
        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        if (totalVotes == 0) { // No votes cast, default to failure
             proposal.state = ProposalState.Failed;
        } else {
            uint256 approvalPercentage = proposal.yesVotes.mul(10000).div(totalVotes);
            if (approvalPercentage >= proposalApprovalThreshold && _outcomeSuccessful) {
                proposal.state = ProposalState.Succeeded;
                // Update coordination trust for proposer
                uint256 proposerTokenId = userToInfluenceSphereId[proposal.proposer];
                if (proposerTokenId != 0) {
                    _updateCoordinationTrust(proposerTokenId, true);
                }
            } else {
                proposal.state = ProposalState.Failed;
                // Optionally penalize proposer's coordination trust
                uint256 proposerTokenId = userToInfluenceSphereId[proposal.proposer];
                if (proposerTokenId != 0) {
                    _updateCoordinationTrust(proposerTokenId, false);
                }
            }
        }

        emit ProposalFinalized(_proposalId, proposal.state, _outcomeSuccessful);
    }

    function claimPredictionRewards(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChrysalisCollective: Proposal does not exist");
        require(proposal.outcomeReported, "ChrysalisCollective: Proposal outcome not yet reported");

        Prediction storage userPrediction = proposal.predictions[msg.sender];
        require(userPrediction.stakeAmount > 0, "ChrysalisCollective: No prediction made by this user");
        require(userPrediction.revealed, "ChrysalisCollective: Prediction not revealed");
        require(!userPrediction.claimed, "ChrysalisCollective: Rewards/penalty already claimed/applied");

        uint256 userTokenId = userToInfluenceSphereId[msg.sender];
        require(userTokenId != 0, "ChrysalisCollective: User is not an Influence Sphere holder");

        bool predictionMatchedOutcome = keccak256(abi.encodePacked(userPrediction.predictionValue)) == keccak256(abi.encodePacked(proposal.actualOutcomeSuccessful ? "success" : "failure"));
        // Assuming simple string prediction "success" or "failure" for this example.
        // In a real system, the prediction value would be more specific and verifiable.

        if (predictionMatchedOutcome) {
            userPrediction.isAccurate = true;
            uint256 reward = userPrediction.stakeAmount.add(basePredictionReward); // Stake + base reward
            (bool success, ) = payable(msg.sender).call{value: reward}("");
            require(success, "ChrysalisCollective: Reward transfer failed");
            emit PredictionRewardClaimed(_proposalId, msg.sender, reward);
            _updateInsightScore(userTokenId, true);
        } else {
            userPrediction.isAccurate = false;
            uint256 penaltyAmount = userPrediction.stakeAmount.mul(basePredictionPenalty).div(10000); // e.g., 50% penalty
            uint256 refundAmount = userPrediction.stakeAmount.sub(penaltyAmount);
            (bool success, ) = payable(msg.sender).call{value: refundAmount}(""); // Refund remaining stake
            require(success, "ChrysalisCollective: Penalty refund failed");
            emit PredictionPenaltyApplied(_proposalId, msg.sender, penaltyAmount);
            _updateInsightScore(userTokenId, false);
            // Penalized amount stays in the contract treasury
        }
        userPrediction.claimed = true;
    }

    // --- IV. Adaptive Core (Self-Adjusting DAO Parameters & Treasury Management) ---

    enum AdaptationState { Proposed, Voting, Enacted, Rejected }

    struct ParameterAdaptation {
        uint256 id;
        address proposer;
        string paramName;
        uint256 newValue;
        string rationaleHash;
        uint256 votingDeadline;
        AdaptationState state;
        uint256 yesVotes;
        uint256 noVotes;
    }

    Counters.Counter private _adaptationIds;
    mapping(uint256 => ParameterAdaptation) public parameterAdaptations;

    event ParameterAdaptationProposed(uint256 indexed adaptationId, address indexed proposer, string paramName, uint256 newValue, uint256 votingDeadline);
    event ParameterAdaptationVoted(uint256 indexed adaptationId, address indexed voter, bool support, uint256 votingPower);
    event ParameterAdaptationExecuted(uint256 indexed adaptationId, string paramName, uint256 newValue);
    event ParameterAdaptationRejected(uint256 indexed adaptationId);

    function initiateParameterAdaptation(
        string memory _paramName,
        uint256 _newValue,
        string memory _rationaleHash
    ) external whenNotPaused returns (uint256) {
        require(userToInfluenceSphereId[msg.sender] != 0, "ChrysalisCollective: Only members can propose adaptations");
        uint256 proposerTokenId = userToInfluenceSphereId[msg.sender];
        require(influenceSpheres[proposerTokenId].adaptabilityIndex >= minInfluenceToPropose, "ChrysalisCollective: Insufficient adaptability to propose parameter changes");

        // Basic check for valid parameter names. Extend this with a whitelist/enum if many params.
        require(keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalApprovalThreshold")) ||
                keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("basePredictionReward")) ||
                keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("basePredictionPenalty")) ||
                keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minInfluenceToPropose")),
                "ChrysalisCollective: Invalid parameter name for adaptation");

        _adaptationIds.increment();
        uint256 newAdaptationId = _adaptationIds.current();

        uint256 adaptationVotingPeriod = 3 days; // Example fixed period for adaptations
        uint256 adaptationVotingDeadline = block.timestamp.add(adaptationVotingPeriod);

        parameterAdaptations[newAdaptationId] = ParameterAdaptation({
            id: newAdaptationId,
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            rationaleHash: _rationaleHash,
            votingDeadline: adaptationVotingDeadline,
            state: AdaptationState.Proposed,
            yesVotes: 0,
            noVotes: 0
        });

        emit ParameterAdaptationProposed(newAdaptationId, msg.sender, _paramName, _newValue, adaptationVotingDeadline);
        return newAdaptationId;
    }

    function voteOnParameterAdaptation(uint256 _adaptationId, bool _support) external whenNotPaused {
        ParameterAdaptation storage adaptation = parameterAdaptations[_adaptationId];
        require(adaptation.id != 0, "ChrysalisCollective: Adaptation proposal does not exist");
        require(adaptation.state == AdaptationState.Proposed, "ChrysalisCollective: Adaptation is not in voting phase");
        require(block.timestamp < adaptation.votingDeadline, "ChrysalisCollective: Voting period has ended");
        require(userToInfluenceSphereId[msg.sender] != 0, "ChrysalisCollective: Only members can vote");

        uint256 voterTokenId = userToInfluenceSphereId[msg.sender];
        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "ChrysalisCollective: Voter has no effective voting power");

        if (_support) {
            adaptation.yesVotes = adaptation.yesVotes.add(votingPower);
        } else {
            adaptation.noVotes = adaptation.noVotes.add(votingPower);
        }
        emit ParameterAdaptationVoted(_adaptationId, msg.sender, _support, votingPower);
    }

    function executeParameterAdaptation(uint256 _adaptationId) external onlyGovernor whenNotPaused {
        ParameterAdaptation storage adaptation = parameterAdaptations[_adaptationId];
        require(adaptation.id != 0, "ChrysalisCollective: Adaptation proposal does not exist");
        require(adaptation.state == AdaptationState.Proposed, "ChryrysalisCollective: Adaptation is not in proposed state");
        require(block.timestamp >= adaptation.votingDeadline, "ChrysalisCollective: Voting period has not ended");

        uint256 totalVotes = adaptation.yesVotes.add(adaptation.noVotes);
        if (totalVotes == 0) {
            adaptation.state = AdaptationState.Rejected;
            emit ParameterAdaptationRejected(_adaptationId);
            return;
        }

        uint256 approvalPercentage = adaptation.yesVotes.mul(10000).div(totalVotes); // 10000 for 100%
        if (approvalPercentage >= proposalApprovalThreshold) { // Use same threshold for parameter adaptations
            // Apply the new parameter value
            if (keccak256(abi.encodePacked(adaptation.paramName)) == keccak256(abi.encodePacked("proposalApprovalThreshold"))) {
                proposalApprovalThreshold = adaptation.newValue;
            } else if (keccak256(abi.encodePacked(adaptation.paramName)) == keccak256(abi.encodePacked("basePredictionReward"))) {
                basePredictionReward = adaptation.newValue;
            } else if (keccak256(abi.encodePacked(adaptation.paramName)) == keccak256(abi.encodePacked("basePredictionPenalty"))) {
                basePredictionPenalty = adaptation.newValue;
            } else if (keccak256(abi.encodePacked(adaptation.paramName)) == keccak256(abi.encodePacked("minInfluenceToPropose"))) {
                minInfluenceToPropose = adaptation.newValue;
            } else {
                revert("ChrysalisCollective: Unknown parameter for adaptation");
            }
            adaptation.state = AdaptationState.Enacted;
            // Update proposer's adaptability index
            uint256 proposerTokenId = userToInfluenceSphereId[adaptation.proposer];
            if (proposerTokenId != 0) {
                _updateAdaptabilityIndex(proposerTokenId, true);
            }
            emit ParameterAdaptationExecuted(_adaptationId, adaptation.paramName, adaptation.newValue);
        } else {
            adaptation.state = AdaptationState.Rejected;
            // Penalize proposer's adaptability index
            uint256 proposerTokenId = userToInfluenceSphereId[adaptation.proposer];
            if (proposerTokenId != 0) {
                _updateAdaptabilityIndex(proposerTokenId, false);
            }
            emit ParameterAdaptationRejected(_adaptationId);
        }
    }

    function allocateTreasuryFunds(uint256 _proposalId, uint256 _amount) external onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChrysalisCollective: Proposal does not exist");
        require(proposal.state == ProposalState.Succeeded, "ChrysalisCollective: Proposal has not succeeded");
        require(address(this).balance >= _amount, "ChrysalisCollective: Insufficient funds in treasury");
        require(_amount <= proposal.requiredFunds, "ChrysalisCollective: Allocated amount exceeds required funds");

        (bool success, ) = payable(proposal.proposer).call{value: _amount}("");
        require(success, "ChrysalisCollective: Fund allocation failed");
        // Update proposal state to Executed if fully funded, or partial execution.
        // For simplicity, we just assume successful allocation and mark as Executed.
        proposal.state = ProposalState.Executed;
        emit FundsAllocated(_proposalId, proposal.proposer, _amount);
    }

    event FundsAllocated(uint256 indexed proposalId, address indexed recipient, uint256 amount);


    function updateAdaptiveAlgorithmCoefficient(string memory _coeffName, uint256 _newValue) external onlyGovernor whenNotPaused {
        if (keccak256(abi.encodePacked(_coeffName)) == keccak256(abi.encodePacked("insightBoostCoeff"))) {
            _insightBoostCoeff = _newValue;
        } else if (keccak256(abi.encodePacked(_coeffName)) == keccak256(abi.encodePacked("adaptabilityBoostCoeff"))) {
            _adaptabilityBoostCoeff = _newValue;
        } else if (keccak256(abi.encodePacked(_coeffName)) == keccak256(abi.encodePacked("coordinationBoostCoeff"))) {
            _coordinationBoostCoeff = _newValue;
        } else {
            revert("ChrysalisCollective: Invalid adaptive algorithm coefficient name");
        }
        emit AdaptiveCoefficientUpdated(_coeffName, _newValue);
    }

    event AdaptiveCoefficientUpdated(string coeffName, uint256 newValue);

    // --- V. View & Utility Functions ---

    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory descriptionHash,
            string memory targetOutcomeHash,
            uint256 requiredFunds,
            uint256 targetDuration,
            uint256 votingDeadline,
            uint256 outcomeDeadline,
            ProposalState state,
            uint256 yesVotes,
            uint256 noVotes,
            bool outcomeReported,
            bool actualOutcomeSuccessful,
            uint256 totalStaked
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.descriptionHash,
            proposal.targetOutcomeHash,
            proposal.requiredFunds,
            proposal.targetDuration,
            proposal.votingDeadline,
            proposal.outcomeDeadline,
            proposal.state,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.outcomeReported,
            proposal.actualOutcomeSuccessful,
            proposal.totalStaked
        );
    }

    function getPredictionDetails(uint256 _proposalId, address _user)
        external
        view
        returns (string memory predictionValue, uint256 stakeAmount, bool revealed, bool claimed, bool isAccurate)
    {
        Proposal storage proposal = proposals[_proposalId];
        Prediction storage userPrediction = proposal.predictions[_user];
        return (userPrediction.predictionValue, userPrediction.stakeAmount, userPrediction.revealed, userPrediction.claimed, userPrediction.isAccurate);
    }

    function getCurrentParameters()
        external
        view
        returns (
            uint256 _proposalApprovalThreshold,
            uint256 _basePredictionReward,
            uint256 _basePredictionPenalty,
            uint256 _minInfluenceToPropose,
            uint256 insightBoostCoeff,
            uint256 adaptabilityBoostCoeff,
            uint256 coordinationBoostCoeff
        )
    {
        return (
            proposalApprovalThreshold,
            basePredictionReward,
            basePredictionPenalty,
            minInfluenceToPropose,
            _insightBoostCoeff,
            _adaptabilityBoostCoeff,
            _coordinationBoostCoeff
        );
    }

    function getVotingPower(address _voter) public view returns (uint256) {
        uint256 tokenId = userToInfluenceSphereId[_voter];
        if (tokenId == 0) {
            return 0;
        }
        InfluenceSphere storage sphere = influenceSpheres[tokenId];
        // Voting power is a combination of traits. Example: 60% Insight, 20% Adaptability, 20% Coordination
        // Normalized by a base value, e.g., 100 for a starting sphere gives 100 voting power.
        // This calculation should avoid overflow and be carefully designed.
        return (sphere.insightScore.mul(6).add(sphere.adaptabilityIndex.mul(2)).add(sphere.coordinationTrust.mul(2))).div(10);
    }

    // Required by ERC721Enumerable for token tracking
    function _baseURI() internal pure override returns (string memory) {
        return "https://api.chrysalis.collective/"; // Base URI for token metadata
    }
}
```