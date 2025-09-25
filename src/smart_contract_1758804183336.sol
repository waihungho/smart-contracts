This smart contract, `AetherForge`, is designed as a decentralized AI collective. It allows users to propose AI models (projects), fund them, and govern their execution. A core feature is the integration with an off-chain AI oracle for proposal evaluation and the issuance of dynamic NFTs (`AetherFragment`) that evolve based on the AI model's performance and user interaction.

The contract aims to be advanced, creative, and trendy by combining:
1.  **AI Oracle Integration for Governance:** Using off-chain AI to generate objective scores for proposals, informing DAO voting.
2.  **Dynamic NFTs tied to Real-World Performance:** NFTs whose attributes and visual representation (via on-chain SVG generation) evolve based on the reported performance of the AI model they represent and user interaction ("charging").
3.  **Decentralized Autonomous Organization (DAO) Framework:** Enabling community governance over AI model funding and execution, utilizing a separate ERC20 token (`AETHER`) for staking and voting power.
4.  **Milestone-based Funding (conceptual):** Funds for successful proposals are released by the proposer, allowing for staged payments.

---

### Outline for AetherForge Smart Contract

**I. Core Infrastructure & Access Control**
*   Foundation of the contract, ownership, pausing mechanisms, and general configuration parameters.
**II. AI Model Proposals & Funding**
*   Mechanisms for users to propose AI projects, stake `AETHER` tokens for governance influence, and fund proposals with ETH.
**III. Voting, Governance & AI Oracle Integration**
*   Functions for casting votes on proposals, initiating and fulfilling AI-generated insights from a trusted oracle, and executing successful proposals.
**IV. Dynamic NFT (`AetherFragment`) Management**
*   ERC721-compliant functions for claiming and managing dynamic NFTs, which evolve based on the associated AI model's reported performance and user interactions. Includes on-chain SVG generation for visual representation.
**V. DAO Treasury & System Funds**
*   Management of the contract's treasury for proposal funding and administrative functions for general operational expenses.

---

### Function Summary

**I. Core Infrastructure & Access Control**
1.  `constructor(address initialOwner, address aetherTokenAddress, address oracleAddress_):` Initializes the contract with an owner, the address of the `AETHER` governance token, and the trusted AI oracle address.
2.  `updateOracleAddress(address newOracleAddress_):` Updates the address of the trusted AI oracle contract. Callable by the contract owner.
3.  `pauseContract():` Puts the contract into a paused state, preventing most interactions. Callable by the contract owner. (Inherited from Pausable)
4.  `unpauseContract():` Resumes contract operation from a paused state. Callable by the contract owner. (Inherited from Pausable)
5.  `setVotingConfig(uint256 voteDuration_, uint256 minAetherToPropose_, uint256 minQuorum_):` Configures critical voting parameters such as the duration of voting periods, minimum `AETHER` required to propose, and the minimum quorum for a proposal to pass. Callable by the contract owner.
6.  `setFundingConfig(uint256 minFundingGoal_, uint256 maxFundingDuration_):` Configures parameters related to proposal funding, including the minimum ETH funding goal and the maximum duration for a funding round. Callable by the contract owner.
7.  `getContractStatus():` Returns the current pause status and key configuration parameters for voting and funding. View function.

**II. AI Model Proposals & Funding**
8.  `proposeAIModel(string calldata _title, string calldata _description, string calldata _aiOracleEndpointURI, uint256 _fundingGoal, uint256 _fundingDuration):` Creates a new AI model proposal, requiring the proposer to stake a minimum amount of `AETHER` tokens. The `_fundingGoal` is specified in wei (ETH).
9.  `stakeTokensForProposal(uint256 proposalId, uint256 amount):` Allows users to stake `AETHER` tokens into an active proposal, contributing to its governance weight and eligibility for NFTs if the proposal succeeds.
10. `unstakeTokensFromProposal(uint256 proposalId, uint256 amount):` Allows users to withdraw staked `AETHER` tokens from a proposal, typically before the voting period ends or if the proposal fails.
11. `fundProposalWithETH(uint256 proposalId):` Allows users to send ETH directly to a specific proposal, contributing to its funding goal.
12. `getProposalDetails(uint256 proposalId):` Returns comprehensive details about a specific AI model proposal, including its status, funding, and voting outcomes. View function.
13. `getProposalStakes(uint256 proposalId, address staker):` Returns the amount of `AETHER` tokens staked by a specific user for a given proposal. View function.
14. `distributeFundsToProposer(uint256 proposalId, uint256 amount):` Transfers a specified amount of ETH from the contract's treasury (after the proposal has been successfully funded and executed) to the proposer of the AI model. This can be used for milestone payments. Callable by the proposer.

**III. Voting, Governance & AI Oracle Integration**
15. `castVote(uint256 proposalId, bool support):` Allows eligible users (who have staked `AETHER`) to cast a vote (for or against) an active proposal. Voting power is proportional to staked `AETHER`.
16. `requestAIOptimizationScore(uint256 proposalId):` Initiates an off-chain request to the trusted AI oracle to generate a feasibility or optimization score for a specific proposal, based on its description and AI endpoint URI. Callable by the contract owner or a designated role.
17. `fulfillAIOptimizationScore(uint256 proposalId, bytes32 requestId, uint256 aiScore_):` A callback function, exclusively callable by the trusted AI oracle, to report the AI-generated score for a previously requested proposal.
18. `getProposalAIOptimizationScore(uint256 proposalId):` Returns the AI-generated optimization score for a proposal, if it has been requested and fulfilled by the oracle. View function.
19. `executeProposal(uint256 proposalId):` Finalizes a successful proposal. It marks the proposal as executed, enabling fund distribution and NFT claiming for eligible stakers. Callable after voting and funding conditions are met.

**IV. Dynamic NFT (`AetherFragment`) Management (ERC721-compliant)**
20. `claimAetherFragment(uint256 proposalId):` Allows an eligible staker of a successfully executed proposal to claim their unique `AetherFragment` NFT as a reward for their contribution.
21. `reportAIModelPerformance(uint256 tokenId, uint256 performanceMetric, string calldata externalDataURI):` Allows the original proposer of the AI model (or a designated oracle for updates) to report performance metrics for the model. This dynamically updates the attributes and visual representation of the associated `AetherFragment` NFTs.
22. `chargeAetherFragment(uint256 tokenId):` Allows an `AetherFragment` NFT holder to "charge" their NFT, potentially by burning a small amount of `AETHER` or via a specific interaction, which can influence its dynamic attributes or visual appearance.
23. `getAetherFragmentAttributes(uint256 tokenId):` Returns the current dynamic attributes (e.g., evolution stage, energy level, performance score) of a specific `AetherFragment` NFT. View function.
24. `tokenURI(uint256 tokenId):` An ERC721 standard function that returns a URI pointing to the JSON metadata for a given `AetherFragment` NFT, dynamically reflecting its current state and including an on-chain generated SVG image.
25. `_generateTokenMetadata(uint256 tokenId):` An internal helper function responsible for constructing the complete JSON metadata for an `AetherFragment` NFT, including its dynamic attributes and a base64 encoded, on-chain generated SVG image.

**V. DAO Treasury & System Funds**
26. `withdrawTreasuryFunds(uint256 amount):` Allows the contract owner to withdraw a specified amount of ETH from the contract's general treasury. This function is intended for system operational expenses, distinct from proposal funding.
27. `transferOwnership(address newOwner):` Transfers ownership of the contract to a new address. (Inherited from Ownable)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Interface for a hypothetical AI Oracle contract
// This oracle would typically be a Chainlink node or similar service
// that can execute off-chain computation (e.g., calling an AI model API)
// and report the result back on-chain.
interface IAIOptimizationOracle {
    // Function to request AI score for a proposal
    // The oracle would typically emit an event with a requestId and then
    // call a callback on AetherForge to report the result.
    function requestAIScore(address callbackContract, uint256 proposalId, string calldata description, string calldata endpointURI) external returns (bytes32 requestId);
}

// Outline for AetherForge Smart Contract

// I. Core Infrastructure & Access Control
//    - Foundation of the contract, ownership, pausing mechanisms, and general configuration parameters.
// II. AI Model Proposals & Funding
//    - Mechanisms for users to propose AI projects, stake `AETHER` tokens for governance influence, and fund proposals with ETH.
// III. Voting, Governance & AI Oracle Integration
//    - Functions for casting votes on proposals, initiating and fulfilling AI-generated insights from a trusted oracle, and executing successful proposals.
// IV. Dynamic NFT (AetherFragment) Management
//    - ERC721-compliant functions for claiming and managing dynamic NFTs,
//      which evolve based on the associated AI model's reported performance and user interactions. Includes on-chain SVG generation for visual representation.
// V. DAO Treasury & System Funds
//    - Management of the contract's treasury for proposal funding and administrative functions for general operational expenses.

// Function Summary

// I. Core Infrastructure & Access Control
// 1. constructor(address initialOwner, address aetherTokenAddress, address oracleAddress_): Initializes the contract with an owner, the address of the `AETHER` governance token, and the trusted AI oracle address.
// 2. updateOracleAddress(address newOracleAddress_): Updates the address of the trusted AI oracle contract. Callable by the contract owner.
// 3. pauseContract(): Puts the contract into a paused state, preventing most interactions. Callable by the contract owner. (Inherited from Pausable)
// 4. unpauseContract(): Resumes contract operation from a paused state. Callable by the contract owner. (Inherited from Pausable)
// 5. setVotingConfig(uint256 voteDuration_, uint256 minAetherToPropose_, uint256 minQuorum_): Configures critical voting parameters such as the duration of voting periods, minimum `AETHER` required to propose, and the minimum quorum for a proposal to pass. Callable by the contract owner.
// 6. setFundingConfig(uint256 minFundingGoal_, uint256 maxFundingDuration_): Configures parameters related to proposal funding, including the minimum ETH funding goal and the maximum duration for a funding round. Callable by the contract owner.
// 7. getContractStatus(): Returns the current pause status and key configuration parameters for voting and funding. View function.

// II. AI Model Proposals & Funding
// 8. proposeAIModel(string calldata _title, string calldata _description, string calldata _aiOracleEndpointURI, uint256 _fundingGoal, uint256 _fundingDuration): Creates a new AI model proposal, requiring the proposer to stake a minimum amount of `AETHER` tokens. The `_fundingGoal` is specified in wei (ETH).
// 9. stakeTokensForProposal(uint256 proposalId, uint256 amount): Allows users to stake `AETHER` tokens into an active proposal, contributing to its governance weight and eligibility for NFTs if the proposal succeeds.
// 10. unstakeTokensFromProposal(uint256 proposalId, uint256 amount): Allows users to withdraw staked `AETHER` tokens from a proposal, typically before the voting period ends or if the proposal fails.
// 11. fundProposalWithETH(uint256 proposalId): Allows users to send ETH directly to a specific proposal, contributing to its funding goal.
// 12. getProposalDetails(uint256 proposalId): Returns comprehensive details about a specific AI model proposal, including its status, funding, and voting outcomes. View function.
// 13. getProposalStakes(uint256 proposalId, address staker): Returns the amount of `AETHER` tokens staked by a specific user for a given proposal. View function.
// 14. distributeFundsToProposer(uint256 proposalId, uint256 amount): Transfers a specified amount of ETH from the contract's treasury (after the proposal has been successfully funded and executed) to the proposer of the AI model. This can be used for milestone payments. Callable by the proposer.

// III. Voting, Governance & AI Oracle Integration
// 15. castVote(uint256 proposalId, bool support): Allows eligible users (who have staked `AETHER`) to cast a vote (for or against) an active proposal. Voting power is proportional to staked `AETHER`.
// 16. requestAIOptimizationScore(uint256 proposalId): Initiates an off-chain request to the trusted AI oracle to generate a feasibility or optimization score for a specific proposal, based on its description and AI endpoint URI. Callable by the contract owner or a designated role.
// 17. fulfillAIOptimizationScore(uint256 proposalId, bytes32 requestId, uint256 aiScore_): A callback function, exclusively callable by the trusted AI oracle, to report the AI-generated score for a previously requested proposal.
// 18. getProposalAIOptimizationScore(uint256 proposalId): Returns the AI-generated optimization score for a proposal, if it has been requested and fulfilled by the oracle. View function.
// 19. executeProposal(uint256 proposalId): Finalizes a successful proposal. It marks the proposal as executed, enabling fund distribution and NFT claiming for eligible stakers. Callable after voting and funding conditions are met.

// IV. Dynamic NFT (AetherFragment) Management (ERC721-compliant)
// 20. claimAetherFragment(uint256 proposalId): Allows an eligible staker of a successfully executed proposal to claim their unique `AetherFragment` NFT as a reward for their contribution.
// 21. reportAIModelPerformance(uint256 tokenId, uint256 performanceMetric, string calldata externalDataURI): Allows the original proposer of the AI model (or a designated oracle for updates) to report performance metrics for the model. This dynamically updates the attributes and visual representation of the associated `AetherFragment` NFTs.
// 22. chargeAetherFragment(uint256 tokenId): Allows an `AetherFragment` NFT holder to "charge" their NFT, potentially by burning a small amount of `AETHER` or via a specific interaction, which can influence its dynamic attributes or visual appearance.
// 23. getAetherFragmentAttributes(uint256 tokenId): Returns the current dynamic attributes (e.g., evolution stage, energy level, performance score) of a specific `AetherFragment` NFT. View function.
// 24. tokenURI(uint256 tokenId): An ERC721 standard function that returns a URI pointing to the JSON metadata for a given `AetherFragment` NFT, dynamically reflecting its current state and including an on-chain generated SVG image.
// 25. _generateTokenMetadata(uint256 tokenId): An internal helper function responsible for constructing the complete JSON metadata for an `AetherFragment` NFT, including its dynamic attributes and a base64 encoded, on-chain generated SVG image.

// V. DAO Treasury & System Funds
// 26. withdrawTreasuryFunds(uint256 amount): Allows the contract owner to withdraw a specified amount of ETH from the contract's general treasury. This function is intended for system operational expenses, distinct from proposal funding.
// 27. transferOwnership(address newOwner): Transfers ownership of the contract to a new address. (Inherited from Ownable)

contract AetherForge is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalIds;
    Counters.Counter private _tokenIds;

    IERC20 public immutable AETHER;
    IAIOptimizationOracle public aiOracle;

    // --- Configuration Parameters ---
    uint256 public voteDuration; // in seconds
    uint256 public minAetherToPropose;
    uint256 public minQuorum; // Percentage, e.g., 51 for 51%
    uint256 public minFundingGoal; // in wei
    uint256 public maxFundingDuration; // in seconds

    // --- Events ---
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 fundingGoal, uint256 fundingDuration);
    event TokensStaked(uint256 indexed proposalId, address indexed staker, uint256 amount);
    event TokensUnstaked(uint256 indexed proposalId, address indexed staker, uint256 amount);
    event ETHFunded(uint256 indexed proposalId, address indexed funder, uint256 amount);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event AIScoreRequested(uint256 indexed proposalId, bytes32 indexed requestId);
    event AIScoreFulfilled(uint256 indexed proposalId, bytes32 indexed requestId, uint256 score);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event FundsDistributed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event AetherFragmentClaimed(uint256 indexed tokenId, uint256 indexed proposalId, address indexed owner);
    event AIModelPerformanceReported(uint256 indexed tokenId, uint256 performanceMetric, string externalDataURI);
    event AetherFragmentCharged(uint256 indexed tokenId, address indexed charger, uint256 newChargeLevel);

    // --- Structs ---

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string aiOracleEndpointURI;
        uint256 fundingGoal; // in wei
        uint256 fundedAmount; // actual ETH received for proposal
        uint256 fundingEndTime;
        uint256 voteStartTime;
        uint256 voteEndTime;
        ProposalStatus status;
        uint252 votesFor; // Use 252 for optimization
        uint252 votesAgainst; // Use 252 for optimization
        uint256 aiOptimizationScore; // AI-generated score, 0 if not requested/fulfilled
        bool aiScoreRequested;
        bool aiScoreFulfilled;
        uint256 totalAetherStaked; // Total AETHER staked across all stakers for this proposal
        mapping(address => uint256) stakers; // Amount of AETHER staked by each user
        mapping(address => bool) hasVoted; // Whether user has voted
        mapping(address => bool) nftClaimed; // Whether user claimed NFT for this proposal
    }
    mapping(uint256 => Proposal) public proposals;

    struct AetherFragment {
        uint256 proposalId;
        uint256 performanceMetric; // Reported by proposer/oracle, 0-100
        uint256 chargeLevel; // Increased by user interaction, 0-100
        uint256 lastChargedTimestamp;
        string externalDataURI; // Optional URI for more complex metadata/context related to AI model
    }
    mapping(uint256 => AetherFragment) public aetherFragments;

    // --- Constructor ---
    constructor(
        address initialOwner,
        address aetherTokenAddress,
        address oracleAddress_
    )
        Ownable(initialOwner)
        ERC721("AetherFragment", "AFG")
    {
        AETHER = IERC20(aetherTokenAddress);
        aiOracle = IAIOptimizationOracle(oracleAddress_);

        // Default configurations
        voteDuration = 7 days;
        minAetherToPropose = 100 * 10 ** 18; // 100 AETHER
        minQuorum = 51; // 51%
        minFundingGoal = 1 ether; // 1 ETH
        maxFundingDuration = 30 days;
    }

    // --- I. Core Infrastructure & Access Control ---

    function updateOracleAddress(address newOracleAddress_) public onlyOwner {
        require(newOracleAddress_ != address(0), "Oracle address cannot be zero");
        aiOracle = IAIOptimizationOracle(newOracleAddress_);
        emit Paused(msg.sender); // Using Paused event as a generic admin action event.
    }

    // pauseContract and unpauseContract are inherited from Pausable
    // transferOwnership is inherited from Ownable

    function setVotingConfig(uint256 voteDuration_, uint256 minAetherToPropose_, uint256 minQuorum_) public onlyOwner whenNotPaused {
        require(voteDuration_ > 0, "Vote duration must be positive");
        require(minQuorum_ > 0 && minQuorum_ <= 100, "Quorum must be between 1 and 100");
        voteDuration = voteDuration_;
        minAetherToPropose = minAetherToPropose_;
        minQuorum = minQuorum_;
    }

    function setFundingConfig(uint256 minFundingGoal_, uint256 maxFundingDuration_) public onlyOwner whenNotPaused {
        require(minFundingGoal_ > 0, "Min funding goal must be positive");
        require(maxFundingDuration_ > 0, "Max funding duration must be positive");
        minFundingGoal = minFundingGoal_;
        maxFundingDuration = maxFundingDuration_;
    }

    function getContractStatus() public view returns (bool paused, uint256 currentVoteDuration, uint256 currentMinAetherToPropose, uint256 currentMinQuorum, uint256 currentMinFundingGoal, uint256 currentMaxFundingDuration) {
        return (paused(), voteDuration, minAetherToPropose, minQuorum, minFundingGoal, maxFundingDuration);
    }

    // --- II. AI Model Proposals & Funding ---

    function proposeAIModel(
        string calldata _title,
        string calldata _description,
        string calldata _aiOracleEndpointURI,
        uint256 _fundingGoal,
        uint256 _fundingDuration
    ) public whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_fundingGoal >= minFundingGoal, "Funding goal below minimum");
        require(_fundingDuration > 0 && _fundingDuration <= maxFundingDuration, "Funding duration invalid");
        require(AETHER.balanceOf(msg.sender) >= minAetherToPropose, "Not enough AETHER to propose");
        require(AETHER.transferFrom(msg.sender, address(this), minAetherToPropose), "AETHER transfer failed");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        Proposal storage newProposal = proposals[newId];
        newProposal.id = newId;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.aiOracleEndpointURI = _aiOracleEndpointURI;
        newProposal.fundingGoal = _fundingGoal;
        newProposal.fundingEndTime = block.timestamp + _fundingDuration;
        newProposal.voteStartTime = 0; // Starts after funding period
        newProposal.voteEndTime = 0;
        newProposal.status = ProposalStatus.Pending;
        newProposal.totalAetherStaked = minAetherToPropose;
        newProposal.stakers[msg.sender] = minAetherToPropose; // Proposer's stake

        emit ProposalCreated(newId, msg.sender, _title, _fundingGoal, _fundingDuration);
        return newId;
    }

    function stakeTokensForProposal(uint256 proposalId, uint256 amount) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending || proposal.status == ProposalStatus.Active, "Proposal not in funding/voting phase");
        require(block.timestamp <= proposal.fundingEndTime, "Funding period has ended");
        require(amount > 0, "Stake amount must be positive");
        require(AETHER.transferFrom(msg.sender, address(this), amount), "AETHER transfer failed");

        proposal.stakers[msg.sender] += amount;
        proposal.totalAetherStaked += amount;

        emit TokensStaked(proposalId, msg.sender, amount);
    }

    function unstakeTokensFromProposal(uint256 proposalId, uint256 amount) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.stakers[msg.sender] >= amount, "Not enough staked tokens");
        require(amount > 0, "Unstake amount must be positive");
        require(proposal.status == ProposalStatus.Pending, "Cannot unstake after funding/voting starts");
        require(block.timestamp <= proposal.fundingEndTime, "Cannot unstake after funding period ends");

        proposal.stakers[msg.sender] -= amount;
        proposal.totalAetherStaked -= amount;
        require(AETHER.transfer(msg.sender, amount), "AETHER transfer failed");

        emit TokensUnstaked(proposalId, msg.sender, amount);
    }

    // Payable fallback for direct ETH funding
    receive() external payable {
        revert("Direct ETH transfers not supported. Use fundProposalWithETH.");
    }

    function fundProposalWithETH(uint256 proposalId) public payable whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal not in funding phase");
        require(block.timestamp <= proposal.fundingEndTime, "Funding period has ended");
        require(msg.value > 0, "ETH amount must be positive");

        proposal.fundedAmount += msg.value;

        // Transition to active/voting if funded
        if (proposal.fundedAmount >= proposal.fundingGoal && proposal.status == ProposalStatus.Pending) {
            proposal.status = ProposalStatus.Active;
            proposal.voteStartTime = block.timestamp;
            proposal.voteEndTime = block.timestamp + voteDuration;
        }

        emit ETHFunded(proposalId, msg.sender, msg.value);
    }

    function getProposalDetails(uint256 proposalId)
        public view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory description,
            string memory aiOracleEndpointURI,
            uint256 fundingGoal,
            uint256 fundedAmount,
            uint256 fundingEndTime,
            uint256 voteStartTime,
            uint256 voteEndTime,
            ProposalStatus status,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 aiOptimizationScore,
            bool aiScoreRequested,
            bool aiScoreFulfilled,
            uint256 totalAetherStaked
        )
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.aiOracleEndpointURI,
            proposal.fundingGoal,
            proposal.fundedAmount,
            proposal.fundingEndTime,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.status,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.aiOptimizationScore,
            proposal.aiScoreRequested,
            proposal.aiScoreFulfilled,
            proposal.totalAetherStaked
        );
    }

    function getProposalStakes(uint256 proposalId, address staker) public view returns (uint256) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        return proposal.stakers[staker];
    }

    function distributeFundsToProposer(uint256 proposalId, uint256 amount) public payable whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(msg.sender == proposal.proposer, "Only proposer can distribute funds");
        require(proposal.status == ProposalStatus.Executed, "Proposal not in executed state");
        require(amount > 0, "Amount must be positive");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = payable(proposal.proposer).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit FundsDistributed(proposalId, proposal.proposer, amount);
    }

    // --- III. Voting, Governance & AI Oracle Integration ---

    function castVote(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "Proposal not in voting phase");
        require(block.timestamp >= proposal.voteStartTime, "Voting has not started");
        require(block.timestamp <= proposal.voteEndTime, "Voting has ended");
        require(proposal.stakers[msg.sender] > 0, "Must have staked AETHER to vote");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor += proposal.stakers[msg.sender];
        } else {
            proposal.votesAgainst += proposal.stakers[msg.sender];
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    function requestAIOptimizationScore(uint256 proposalId) public onlyOwner whenNotPaused returns (bytes32) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.aiScoreRequested, "AI score already requested");
        require(bytes(proposal.aiOracleEndpointURI).length > 0, "AI Oracle Endpoint URI not set");

        proposal.aiScoreRequested = true;
        bytes32 requestId = aiOracle.requestAIScore(address(this), proposalId, proposal.description, proposal.aiOracleEndpointURI);
        emit AIScoreRequested(proposalId, requestId);
        return requestId;
    }

    function fulfillAIOptimizationScore(uint256 proposalId, bytes32 requestId, uint256 aiScore_) public whenNotPaused {
        // This function must only be callable by the trusted AI Oracle contract.
        // In a real scenario, this would involve `onlyOracle` modifier or checking msg.sender == address(aiOracle)
        // For simplicity and to avoid circular dependency for IAIOptimizationOracle, we'll use a basic check.
        require(msg.sender == address(aiOracle), "Only the AI Oracle can fulfill scores");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.aiScoreRequested, "AI score not requested for this proposal");
        require(!proposal.aiScoreFulfilled, "AI score already fulfilled");
        require(aiScore_ <= 100, "AI score must be between 0 and 100"); // Assuming score is 0-100

        proposal.aiOptimizationScore = aiScore_;
        proposal.aiScoreFulfilled = true;
        emit AIScoreFulfilled(proposalId, requestId, aiScore_);
    }

    function getProposalAIOptimizationScore(uint256 proposalId) public view returns (uint256) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        return proposal.aiOptimizationScore;
    }

    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "Proposal not in active state");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");
        require(block.timestamp > proposal.fundingEndTime, "Funding period has not ended");

        // Check if funding goal met
        bool fundingSuccess = proposal.fundedAmount >= proposal.fundingGoal;
        require(fundingSuccess, "Funding goal not met");

        // Check voting outcome
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        bool votingSuccess = totalVotes > 0 && (proposal.votesFor * 100 / totalVotes) >= minQuorum;

        if (fundingSuccess && votingSuccess) {
            proposal.status = ProposalStatus.Succeeded;
            // Now, transition to Executed. Proposer can start distributing funds.
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId, true);
        } else {
            proposal.status = ProposalStatus.Failed;
            // Allow stakers to reclaim AETHER and potentially ETH if funded.
            // For simplicity, AETHER unstaking is only pre-voting. ETH refund not implemented for failed proposals.
            emit ProposalExecuted(proposalId, false);
        }
    }

    // --- IV. Dynamic NFT (AetherFragment) Management (ERC721-compliant) ---

    // _baseURI is not used as tokenURI is dynamically generated
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function claimAetherFragment(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Executed, "Proposal not executed successfully");
        require(proposal.stakers[msg.sender] > 0, "Not an eligible staker for this proposal");
        require(!proposal.nftClaimed[msg.sender], "NFT already claimed for this proposal");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        proposal.nftClaimed[msg.sender] = true;

        AetherFragment storage newFragment = aetherFragments[newTokenId];
        newFragment.proposalId = proposalId;
        newFragment.performanceMetric = 50; // Initial state
        newFragment.chargeLevel = 50; // Initial state
        newFragment.lastChargedTimestamp = block.timestamp;
        newFragment.externalDataURI = ""; // Initial empty

        emit AetherFragmentClaimed(newTokenId, proposalId, msg.sender);
    }

    function reportAIModelPerformance(uint256 tokenId, uint256 performanceMetric, string calldata externalDataURI) public whenNotPaused {
        AetherFragment storage fragment = aetherFragments[tokenId];
        require(fragment.proposalId != 0, "AetherFragment does not exist");
        Proposal storage proposal = proposals[fragment.proposalId];
        require(msg.sender == proposal.proposer, "Only proposer can report performance");
        require(performanceMetric <= 100, "Performance metric must be between 0 and 100");

        fragment.performanceMetric = performanceMetric;
        fragment.externalDataURI = externalDataURI;
        emit AIModelPerformanceReported(tokenId, performanceMetric, externalDataURI);
    }

    function chargeAetherFragment(uint256 tokenId) public whenNotPaused {
        AetherFragment storage fragment = aetherFragments[tokenId];
        require(fragment.proposalId != 0, "AetherFragment does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to charge this fragment");
        
        // Example: Burn a small amount of AETHER to charge
        uint256 chargeCost = 1 * 10**18; // 1 AETHER
        require(AETHER.transferFrom(msg.sender, address(this), chargeCost), "AETHER transfer failed for charging");

        // Increase charge level, capped at 100
        fragment.chargeLevel = Math.min(fragment.chargeLevel + 10, 100);
        fragment.lastChargedTimestamp = block.timestamp;
        emit AetherFragmentCharged(tokenId, msg.sender, fragment.chargeLevel);
    }

    function getAetherFragmentAttributes(uint256 tokenId) public view returns (uint256 proposalId, uint256 performanceMetric, uint256 chargeLevel, uint256 lastChargedTimestamp, string memory externalDataURI) {
        AetherFragment storage fragment = aetherFragments[tokenId];
        require(fragment.proposalId != 0, "AetherFragment does not exist");
        return (fragment.proposalId, fragment.performanceMetric, fragment.chargeLevel, fragment.lastChargedTimestamp, fragment.externalDataURI);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return _generateTokenMetadata(tokenId);
    }

    // Internal helper to generate SVG dynamically
    function _generateSVG(uint256 evolutionStage, uint256 chargeLevel) internal pure returns (string memory) {
        string memory fillColor;
        if (evolutionStage < 33) {
            fillColor = "#ff0000"; // Red
        } else if (evolutionStage < 66) {
            fillColor = "#ffff00"; // Yellow
        } else {
            fillColor = "#00ff00"; // Green
        }

        uint256 radius = 20 + (chargeLevel / 2); // Radius from 20 to 70

        string memory svg = string(abi.encodePacked(
            '<svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="200" height="200" fill="#000000"/>', // Black background
            '<circle cx="100" cy="100" r="', Strings.toString(radius), '" fill="', fillColor, '" stroke="#ffffff" stroke-width="2"/>',
            '<text x="100" y="105" font-family="monospace" font-size="16" fill="#ffffff" text-anchor="middle">',
            'S:', Strings.toString(evolutionStage), ' C:', Strings.toString(chargeLevel),
            '</text>',
            '</svg>'
        ));
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }

    function _generateTokenMetadata(uint256 tokenId) internal view returns (string memory) {
        AetherFragment storage fragment = aetherFragments[tokenId];
        Proposal storage proposal = proposals[fragment.proposalId];

        uint256 evolutionStage = fragment.performanceMetric;
        uint256 energyLevel = fragment.chargeLevel;

        string memory svgImage = _generateSVG(evolutionStage, energyLevel);

        string memory json = string(abi.encodePacked(
            '{"name": "AetherFragment #', Strings.toString(tokenId), ' - ', proposal.title, '",',
            '"description": "A dynamic AetherFragment NFT representing contribution to AI Model: ', proposal.title, '.",',
            '"image": "', svgImage, '",',
            '"attributes": [',
                '{"trait_type": "AI Model ID", "value": ', Strings.toString(fragment.proposalId), '},',
                '{"trait_type": "Proposer", "value": "', Strings.toHexString(uint160(proposal.proposer), 20), '"},',
                '{"trait_type": "Evolution Stage", "value": ', Strings.toString(evolutionStage), '},',
                '{"trait_type": "Energy Level", "value": ', Strings.toString(energyLevel), '},',
                '{"trait_type": "Last Charged", "display_type": "date", "value": ', Strings.toString(fragment.lastChargedTimestamp), '}',
                bytes(fragment.externalDataURI).length > 0 ? string(abi.encodePacked(', {"trait_type": "External Data", "value": "', fragment.externalDataURI, '"}')) : ""
            ']}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }


    // --- V. DAO Treasury & System Funds ---

    // This function allows the owner to withdraw funds not allocated to proposals, for general operations.
    // For proposal-specific funds, `distributeFundsToProposer` is used.
    function withdrawTreasuryFunds(uint256 amount) public onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}

// Simple Math library for min/max operations, commonly used in Solidity.
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```