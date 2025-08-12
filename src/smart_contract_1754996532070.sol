This Solidity smart contract, `AetherForge`, is designed as a sophisticated, multi-faceted platform for an AI-powered creative studio. It incorporates advanced concepts like AI oracle integration, dynamic NFTs, a soulbound token (SBT) reputation system, and a robust decentralized autonomous organization (DAO) for governance.

To fulfill the requirement of "at least 20 functions" within a single smart contract and avoid direct duplication of existing open-source code, this contract internally simulates the core functionalities of ERC-20 (for its native AETH token), ERC-721 (for its dynamic AetherArt NFTs), and ERC-1155 (for its Soulbound Reputation Badges). In a production environment, these would typically be separate, standards-compliant contracts that `AetherForge` would interact with via interfaces. This design choice allows for a self-contained demonstration of complex inter-module logic.

---

**Contract Name:** `AetherForge`

**Outline & Function Summary**

**I. Core Infrastructure & Security**
   1.  `constructor()`: Initializes the contract, setting the deployer as the owner and minting an initial supply of AETH (simulated). Sets initial reputation badge names.
   2.  `setExternalContracts(address _oracle, address _token, address _reputationNFT, address _aetherArtNFT)`: (For a real deployment) Sets the addresses of external oracle, AETH token, reputation NFT, and AetherArt NFT contracts.
   3.  `pauseContract()`: Allows the owner to pause critical operations in case of emergency.
   4.  `unpauseContract()`: Allows the owner to resume operations after a pause.
   5.  `transferOwnership(address _newOwner)`: Transfers contract ownership to a new address.
   6.  `withdrawETH()`: Allows the owner to withdraw accumulated Ether (e.g., for oracle fees).
   7.  `withdrawTokens(address _tokenAddress)`: Allows the owner to withdraw any accidentally sent ERC-20 tokens.

**II. AetherToken ($AETH) - Utility & Governance (Internal Simulation)**
   *(These functions simulate ERC-20 logic internally within `AetherForge` for demonstration.)*
   8.  `mintInitialAETH(address _recipient, uint256 _amount)`: Admin function to mint initial AETH for distribution.
   9.  `transferAETH(address _recipient, uint256 _amount)`: Basic internal AETH transfer.
   10. `stakeAETHForGovernance(uint256 _amount)`: Users stake $AETH to gain voting power and eligibility for rewards within the DAO.
   11. `unstakeAETHFromGovernance(uint256 _amount)`: Users unstake their $AETH from governance.
   12. `delegateVote(address _delegatee)`: Allows a user to delegate their voting power to another address.
   13. `balanceOf(address _user)`: Returns the current simulated AETH balance of a user.

**III. AI Request & Fulfillment (CreativeForge Module)**
   14. `requestAIGeneration(string memory _prompt, uint256 _price)`: Users submit a prompt and pay $AETH to request AI content generation. Generates a unique request ID.
   15. `fulfillAIGeneration(uint256 _requestId, string memory _metadataURI, uint256 _seed, bytes32 _externalJobId)`: Called by the trusted oracle to deliver the AI-generated content's metadata URI. Mints an AetherArt NFT to the requester.
   16. `submitAIContentReview(uint256 _tokenId, uint8 _rating, string memory _comment)`: Users review AI-generated art, contributing to the NFT's reputation and potentially their own.
   17. `claimFailedAIGenerationRefund(uint256 _requestId)`: Allows a user to claim back their AETH if an AI generation request fails or times out.

**IV. Dynamic NFT Management (AetherArt Module - Internal Simulation)**
   *(These functions simulate ERC-721 ownership and metadata, with dynamic updates.)*
   18. `getAetherArtOwner(uint256 _tokenId)`: Returns the owner of a specific AetherArt NFT.
   19. `getAetherArtMetadataURI(uint256 _tokenId)`: Returns the current metadata URI of an AetherArt NFT.
   20. `proposeAetherArtEvolution(uint256 _tokenId, string memory _newMetadataURI, string memory _reason)`: Allows an NFT owner to propose a metadata evolution for their NFT, subject to governance approval.
   21. `approveAetherArtEvolution(uint256 _tokenId, string memory _newMetadataURI)`: Internal function executed by governance to update an AetherArt NFT's metadata, making it dynamic.
   22. `triggerAIArtAnalysis(uint256 _tokenId)`: Requests the AI oracle to analyze an existing AetherArt NFT for new insights or potential evolutions.
   23. `fulfillAIArtAnalysis(uint256 _tokenId, string memory _analysisReportURI, bytes32 _externalJobId)`: Called by the oracle to deliver the AI analysis report for an AetherArt NFT.

**V. Reputation System (AetherReputation - Soulbound Badges - Internal Simulation)**
   *(These functions simulate a non-transferable (soulbound) token system.)*
   24. `mintReputationBadge(address _recipient, uint256 _badgeId, string memory _reason)`: Mints a non-transferable (soulbound) reputation badge to a user based on their contributions.
   25. `revokeReputationBadge(address _recipient, uint256 _badgeId)`: Allows the DAO or owner to revoke a reputation badge (e.g., for malicious activity).
   26. `getUserReputationBadges(address _user)`: Returns a list of badge IDs held by a user.
   27. `calculateUserEffectiveReputation(address _user)`: Calculates a composite reputation score based on held badges, governance stake, and content review history.

**VI. Advanced Governance & DAO Operations**
   28. `proposeGovernanceAction(bytes memory _callData, string memory _description)`: Users can propose arbitrary actions for the DAO to vote on. Requires staked AETH.
   29. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Users vote on open governance proposals using their staked AETH or delegated power.
   30. `queueGovernanceExecution(uint256 _proposalId)`: After a proposal passes its voting period and threshold, it enters a timelock period before execution.
   31. `executeQueuedGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal after its timelock period has passed.
   32. `cancelGovernanceProposal(uint256 _proposalId)`: Allows for the cancellation of a governance proposal under specific conditions (e.g., by owner in emergency or new DAO vote).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Used for type hinting, actual logic is internal
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString conversion

// Interface for a hypothetical Oracle Service that delivers AI results
interface IAIAssistantOracle {
    // This function is expected to be called by AetherForge to request AI generation
    // and then the oracle will call back fulfillAIGeneration on AetherForge.
    // For demonstration, we simulate the request directly by expecting a callback.
    // In a real Chainlink setup, this would use fulfillOracleRequest and pay LINK.
    function fulfillAIGeneration(uint256 _requestId, string calldata _metadataURI, uint256 _seed, bytes32 _externalJobId) external;
    function fulfillAIArtAnalysis(uint256 _tokenId, string calldata _analysisReportURI, bytes32 _externalJobId) external;
}

/**
 * @title AetherForge
 * @dev A novel smart contract representing a Decentralized AI-Powered Creative Studio & Reputation System.
 *      It integrates AI-driven content generation (via oracle), dynamic NFTs that evolve based on
 *      governance and AI analysis, and a soulbound token (SBT) reputation system.
 *
 *      IMPORTANT: For demonstration purposes and to meet the requirement of a high number of functions
 *      within a single contract, this contract contains internal simulations of ERC-20, ERC-721, and
 *      ERC-1155 functionalities. In a real-world scenario, these would typically be separate,
 *      standards-compliant contracts that AetherForge would interact with via interfaces.
 */
contract AetherForge is Ownable, Pausable {

    using Strings for uint256;

    // --- Outline & Function Summary ---
    //
    // I. Core Infrastructure & Security
    //    1. constructor(): Initializes the contract, setting the deployer as the owner and minting initial AETH.
    //    2. setExternalContracts(): (For a real deployment) Sets addresses of external oracle, token, and NFT contracts.
    //    3. pauseContract(): Allows the owner to pause critical operations.
    //    4. unpauseContract(): Allows the owner to resume operations.
    //    5. transferOwnership(): Transfers contract ownership.
    //    6. withdrawETH(): Allows the owner to withdraw accumulated Ether.
    //    7. withdrawTokens(): Allows the owner to withdraw accidentally sent ERC-20 tokens.
    //
    // II. AetherToken ($AETH) - Utility & Governance (Internal Simulation)
    //    8. mintInitialAETH(): Admin function to mint initial AETH.
    //    9. transferAETH(): Basic internal AETH transfer.
    //    10. stakeAETHForGovernance(): Users stake $AETH for voting power.
    //    11. unstakeAETHFromGovernance(): Users unstake their $AETH.
    //    12. delegateVote(): Allows a user to delegate voting power.
    //    13. balanceOf(): Returns a user's simulated AETH balance.
    //
    // III. AI Request & Fulfillment (CreativeForge Module)
    //    14. requestAIGeneration(): Users submit a prompt and pay AETH for AI content.
    //    15. fulfillAIGeneration(): Called by oracle to deliver AI-generated content (mints AetherArt NFT).
    //    16. submitAIContentReview(): Users review AI-generated art.
    //    17. claimFailedAIGenerationRefund(): Allows refund for failed AI generation.
    //
    // IV. Dynamic NFT Management (AetherArt Module - Internal Simulation)
    //    18. getAetherArtOwner(): Returns the owner of an AetherArt NFT.
    //    19. getAetherArtMetadataURI(): Returns current metadata URI of an AetherArt NFT.
    //    20. proposeAetherArtEvolution(): Allows proposing NFT metadata evolution via governance.
    //    21. approveAetherArtEvolution(): Internal function executed by governance to update NFT metadata.
    //    22. triggerAIArtAnalysis(): Requests AI oracle to analyze an existing AetherArt NFT.
    //    23. fulfillAIArtAnalysis(): Called by oracle to deliver AI analysis report.
    //
    // V. Reputation System (AetherReputation - Soulbound Badges - Internal Simulation)
    //    24. mintReputationBadge(): Mints a non-transferable reputation badge.
    //    25. revokeReputationBadge(): Revokes a reputation badge.
    //    26. getUserReputationBadges(): Returns badges held by a user.
    //    27. calculateUserEffectiveReputation(): Calculates a composite reputation score.
    //
    // VI. Advanced Governance & DAO Operations
    //    28. proposeGovernanceAction(): Users propose arbitrary DAO actions.
    //    29. voteOnGovernanceProposal(): Users vote on proposals.
    //    30. queueGovernanceExecution(): Queues a passed proposal for execution after timelock.
    //    31. executeQueuedGovernanceProposal(): Executes a queued proposal.
    //    32. cancelGovernanceProposal(): Allows cancellation of proposals.


    // --- State Variables ---

    // External Contract Addresses (in a real scenario, these would be interfaces like IAIAssistantOracle)
    address public oracleAddress;
    address public aetherTokenAddress; // Placeholder for AETH ERC-20
    address public aetherReputationNFTAddress; // Placeholder for SBT ERC-1155/721
    address public aetherArtNFTAddress; // Placeholder for Dynamic NFT ERC-721

    uint256 public nextRequestId = 1; // Unique ID for AI generation requests
    uint256 public nextAetherArtTokenId = 1; // Unique ID for AetherArt NFTs

    // --- AI Generation Request State ---
    struct AIRequest {
        address requester;
        string prompt;
        uint256 price; // AETH paid
        string metadataURI; // Resulting URI from oracle
        uint256 aetherArtTokenId; // ID of the minted NFT
        uint256 timestamp;
        bool fulfilled;
        bool refunded;
        bytes32 externalJobId; // ID from external oracle system
    }
    mapping(uint256 => AIRequest) public aiRequests;

    // --- AetherToken (AETH) - Internal Simulation ---
    // Note: This is a simplified internal simulation. A real system would use a dedicated ERC-20 contract.
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public stakedAETH;
    mapping(address => address) public voteDelegates;
    uint256 public constant TOTAL_AETH_SUPPLY = 100_000_000 * 10**18; // 100 Million AETH
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 100 * 10**18; // 100 AETH to propose

    // --- AetherArt NFT (Dynamic ERC-721) - Internal Simulation ---
    // Note: This simulates ERC-721 ownership and dynamic metadata. A real system would use a dedicated ERC-721 contract.
    mapping(uint256 => address) private _aetherArtOwners; // tokenId => owner
    mapping(uint256 => string) private _aetherArtMetadataURIs; // tokenId => metadataURI
    mapping(uint256 => uint256) public aetherArtReviewsCount; // tokenId => number of reviews
    mapping(uint256 => uint256) public aetherArtTotalRating; // tokenId => sum of ratings

    // --- AetherReputation (Soulbound Badges - ERC-1155 style) - Internal Simulation ---
    // Note: This simulates a simple soulbound token (SBT) system. A real system might use a dedicated ERC-1155 or ERC-721 contract with non-transferability.
    // badgeId => badge name (e.g., 1 => "Aether Pioneer", 2 => "Top Prompter")
    mapping(uint256 => string) public reputationBadgeNames;
    // user => badgeId => bool (is owned)
    mapping(address => mapping(uint256 => bool)) private _reputationBadgeOwnership;
    // user => list of badge IDs (for easier lookup, though expensive for many badges)
    mapping(address => uint256[]) private _userReputationBadgesList;

    // --- Governance System ---
    struct Proposal {
        string description;
        bytes callData; // Encoded function call to execute if passed
        uint256 proposerStake; // Amount of AETH staked by proposer
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 executionTime; // Time when it can be executed (after timelock)
        bool executed;
        bool cancelled;
        mapping(address => bool) hasVoted; // User has voted on this proposal
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriod = 3 days;
    uint256 public timelockPeriod = 2 days;
    uint256 public proposalThreshold = 5 * 10**18; // 5 AETH stake to propose
    uint256 public minVoteQuorum = 1000 * 10**18; // Minimum total votes (staked AETH) for a proposal to pass

    // --- Events ---
    event AetherTokenMinted(address indexed recipient, uint256 amount);
    event AetherTokenTransferred(address indexed from, address indexed to, uint256 amount);
    event AetherTokenStaked(address indexed user, uint256 amount);
    event AetherTokenUnstaked(address indexed user, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);

    event AIRequestInitiated(uint256 indexed requestId, address indexed requester, string prompt, uint256 price);
    event AIGenerationFulfilled(uint256 indexed requestId, uint256 indexed tokenId, string metadataURI);
    event AIContentReviewed(uint256 indexed tokenId, address indexed reviewer, uint8 rating);
    event AIRequestRefunded(uint256 indexed requestId, address indexed recipient, uint256 amount);
    event AIArtAnalysisRequested(uint256 indexed tokenId);
    event AIArtAnalysisFulfilled(uint256 indexed tokenId, string analysisReportURI);

    event AetherArtMinted(address indexed owner, uint256 indexed tokenId, string metadataURI);
    event AetherArtEvolutionProposed(uint256 indexed proposalId, uint256 indexed tokenId, string newMetadataURI);
    event AetherArtEvolutionApproved(uint256 indexed proposalId, uint256 indexed tokenId, string newMetadataURI);

    event ReputationBadgeMinted(address indexed recipient, uint256 indexed badgeId, string reason);
    event ReputationBadgeRevoked(address indexed recipient, uint256 indexed badgeId);

    event GovernanceProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event GovernanceProposalQueued(uint256 indexed proposalId, uint256 executionTime);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event GovernanceProposalCancelled(uint256 indexed proposalId);


    /**
     * @dev Constructor: Initializes the contract and sets the deployer as owner.
     *      Initializes the simulated AETH supply and sets initial badge names.
     */
    constructor() Ownable(msg.sender) {
        // Mint initial supply to the owner (or a treasury) for simulation
        _balances[msg.sender] = TOTAL_AETH_SUPPLY;
        emit AetherTokenMinted(msg.sender, TOTAL_AETH_SUPPLY);

        // Set initial badge names for Soulbound Tokens (SBTs)
        reputationBadgeNames[1] = "Aether Pioneer";       // Early adopter/contributor
        reputationBadgeNames[2] = "Top Prompter";         // User consistently creates high-quality AI prompts
        reputationBadgeNames[3] = "Aether Curator";       // User provides valuable reviews of generated content
        reputationBadgeNames[4] = "Council Member";       // Active governance participant
        reputationBadgeNames[5] = "AI-Recognized Artist"; // Art recognized by AI analysis as high quality
    }

    // --- I. Core Infrastructure & Security ---

    /**
     * @dev Sets the addresses for external contracts. Only callable by owner.
     *      In a real system, these would be properly typed interfaces (e.g., IERC20, IERC721).
     * @param _oracle The address of the AI assistant oracle contract.
     * @param _token The address of the AetherToken (ERC-20) contract.
     * @param _reputationNFT The address of the AetherReputation (SBT) contract.
     * @param _aetherArtNFT The address of the AetherArt (Dynamic NFT) contract.
     */
    function setExternalContracts(address _oracle, address _token, address _reputationNFT, address _aetherArtNFT) external onlyOwner {
        require(_oracle != address(0) && _token != address(0) && _reputationNFT != address(0) && _aetherArtNFT != address(0), "Zero address not allowed");
        oracleAddress = _oracle;
        aetherTokenAddress = _token;
        aetherReputationNFTAddress = _reputationNFT;
        aetherArtNFTAddress = _aetherArtNFT;
    }

    /**
     * @dev Pauses the contract. Only callable by owner. Inherited from Pausable.
     *      Prevents most state-changing functions from being called.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by owner. Inherited from Pausable.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any Ether sent to the contract.
     *      Useful for collecting oracle fees or mis-sent ETH.
     */
    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    /**
     * @dev Allows the owner to withdraw any ERC-20 tokens accidentally sent to the contract.
     * @param _tokenAddress The address of the ERC-20 token to withdraw.
     */
    function withdrawTokens(address _tokenAddress) external onlyOwner {
        // In a real scenario, this would interact with the actual IERC20.
        // For this simulation, we're assuming direct balance management if `_tokenAddress` is this contract itself,
        // otherwise, it's an external token interaction.
        if (_tokenAddress == address(this)) {
            // This case handles attempts to withdraw AETH (our simulated token)
            // For AETH, balance is tracked internally.
            revert("Cannot withdraw AETH using this function. Use AETH unstake.");
        } else {
            // Handles other ERC-20 tokens accidentally sent
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "No tokens to withdraw");
            token.transfer(owner(), balance);
        }
    }

    // --- II. AetherToken ($AETH) - Utility & Governance (Internal Simulation) ---
    // Note: In a real system, these would be calls to an external ERC-20 contract (e.g., `AetherToken.sol`).
    // This internal simulation is for demonstration purposes within a single contract.

    /**
     * @dev Admin function to mint initial AETH. For demonstration purposes.
     *      In a real ERC-20, this would likely be part of the token contract's constructor or a dedicated minter role.
     * @param _recipient The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mintInitialAETH(address _recipient, uint256 _amount) external onlyOwner {
        require(_balances[_recipient] + _amount <= TOTAL_AETH_SUPPLY, "Exceeds total supply for recipient");
        _balances[_recipient] += _amount;
        emit AetherTokenMinted(_recipient, _amount);
    }

    /**
     * @dev Basic internal AETH transfer function for simulation.
     * @param _recipient The address to send AETH to.
     * @param _amount The amount of AETH to send.
     * @return true if the transfer was successful.
     */
    function transferAETH(address _recipient, uint256 _amount) public whenNotPaused returns (bool) {
        require(_balances[msg.sender] >= _amount, "Insufficient AETH balance");
        _balances[msg.sender] -= _amount;
        _balances[_recipient] += _amount;
        emit AetherTokenTransferred(msg.sender, _recipient, _amount);
        return true;
    }

    /**
     * @dev Allows users to stake AETH to participate in governance and gain voting power.
     *      The AETH is transferred to the contract's balance during staking.
     * @param _amount The amount of AETH to stake.
     */
    function stakeAETHForGovernance(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than zero");
        require(transferAETH(address(this), _amount), "AETH transfer failed for staking"); // Transfer to contract's internal balance
        stakedAETH[msg.sender] += _amount;
        emit AetherTokenStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake their AETH from governance.
     *      The AETH is transferred back to the user from the contract's balance.
     * @param _amount The amount of AETH to unstake.
     */
    function unstakeAETHFromGovernance(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(stakedAETH[msg.sender] >= _amount, "Insufficient staked AETH");
        stakedAETH[msg.sender] -= _amount;
        require(transferAETH(msg.sender, _amount), "AETH transfer failed for unstaking"); // Transfer back to user
        emit AetherTokenUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to delegate their voting power to another address.
     *      Delegated votes are included in governance proposal calculations.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) public whenNotPaused {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        voteDelegates[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Returns the total AETH balance of a user (simulated, including non-staked).
     *      For internal simulation purposes.
     * @param _user The address to query the balance for.
     * @return The AETH balance of the user.
     */
    function balanceOf(address _user) public view returns (uint256) {
        return _balances[_user];
    }

    // --- III. AI Request & Fulfillment (CreativeForge Module) ---

    /**
     * @dev Allows a user to request AI content generation by paying AETH.
     *      The request is stored, and an external oracle is expected to fulfill it off-chain.
     * @param _prompt The creative prompt for the AI.
     * @param _price The AETH price for this AI generation request.
     */
    function requestAIGeneration(string memory _prompt, uint256 _price) public whenNotPaused {
        require(_price > 0, "Price must be greater than zero");
        require(transferAETH(address(this), _price), "AETH payment failed"); // Pay AETH to contract
        uint256 currentRequestId = nextRequestId++;
        aiRequests[currentRequestId] = AIRequest({
            requester: msg.sender,
            prompt: _prompt,
            price: _price,
            metadataURI: "",
            aetherArtTokenId: 0, // Will be set upon fulfillment
            timestamp: block.timestamp,
            fulfilled: false,
            refunded: false,
            externalJobId: bytes32(0)
        });
        emit AIRequestInitiated(currentRequestId, msg.sender, _prompt, _price);
        // In a real Chainlink setup, this would trigger an oracle request here.
        // IAIAssistantOracle(oracleAddress).requestAIData(currentRequestId, _prompt); // Example
    }

    /**
     * @dev Called by the trusted oracle to fulfill an AI generation request.
     *      Mints a new AetherArt NFT (simulated) to the original requester.
     * @param _requestId The ID of the original AI generation request.
     * @param _metadataURI The URI pointing to the AI-generated content's metadata.
     * @param _seed The seed used by the AI (for reproducibility or uniqueness).
     * @param _externalJobId An ID from the external oracle system for tracking.
     */
    function fulfillAIGeneration(uint256 _requestId, string memory _metadataURI, uint256 _seed, bytes32 _externalJobId) external {
        require(msg.sender == oracleAddress, "Caller is not the trusted oracle");
        AIRequest storage req = aiRequests[_requestId];
        require(req.requester != address(0), "Request does not exist");
        require(!req.fulfilled, "Request already fulfilled");
        require(!req.refunded, "Request already refunded");

        req.fulfilled = true;
        req.metadataURI = _metadataURI;
        req.externalJobId = _externalJobId;

        // Mint AetherArt NFT (internal simulation)
        uint256 currentTokenId = nextAetherArtTokenId++;
        _aetherArtOwners[currentTokenId] = req.requester;
        _aetherArtMetadataURIs[currentTokenId] = _metadataURI;
        req.aetherArtTokenId = currentTokenId;

        emit AIGenerationFulfilled(_requestId, currentTokenId, _metadataURI);
        emit AetherArtMinted(req.requester, currentTokenId, _metadataURI);

        // Optional: Mint "Aether Pioneer" badge for first few AI-generated NFTs
        if (currentTokenId <= 10) { // Example condition
            _mintReputationBadge(req.requester, 1, "Early AetherArt Creator"); // Badge ID 1 for "Aether Pioneer"
        }
    }

    /**
     * @dev Allows users to review an AI-generated AetherArt NFT.
     *      Contributes to the NFT's reputation and potentially the reviewer's reputation (e.g., as a curator).
     * @param _tokenId The ID of the AetherArt NFT being reviewed.
     * @param _rating The rating (1-5, where 5 is best).
     * @param _comment An optional comment (off-chain storage recommended for longer text).
     */
    function submitAIContentReview(uint256 _tokenId, uint8 _rating, string memory _comment) public whenNotPaused {
        require(_aetherArtOwners[_tokenId] != address(0), "AetherArt NFT does not exist");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        // Prevent owner from reviewing their own art for basic integrity
        require(_aetherArtOwners[_tokenId] != msg.sender, "Cannot review your own AetherArt");

        aetherArtTotalRating[_tokenId] += _rating;
        aetherArtReviewsCount[_tokenId]++;

        // Simple logic: If a user has submitted a significant number of reviews, consider minting a "Curator" badge.
        // A more robust system would track unique reviews per user and average rating given.
        if (aetherArtReviewsCount[_tokenId] % 5 == 0) { // Every 5th review (example threshold)
             _mintReputationBadge(msg.sender, 3, "Active Aether Curator"); // Badge ID 3 for "Aether Curator"
        }

        emit AIContentReviewed(_tokenId, msg.sender, _rating);
    }

    /**
     * @dev Allows a user to claim a refund if their AI generation request fails or times out.
     * @param _requestId The ID of the request to refund.
     */
    function claimFailedAIGenerationRefund(uint256 _requestId) public whenNotPaused {
        AIRequest storage req = aiRequests[_requestId];
        require(req.requester == msg.sender, "Only requester can claim refund");
        require(!req.fulfilled, "Request was fulfilled");
        require(!req.refunded, "Refund already claimed");
        require(block.timestamp > req.timestamp + 7 days, "Refund not yet available (7-day timeout)"); // Example timeout

        req.refunded = true;
        require(transferAETH(req.requester, req.price), "Refund transfer failed");
        emit AIRequestRefunded(_requestId, req.requester, req.price);
    }

    // --- IV. Dynamic NFT Management (AetherArt Module - Internal Simulation) ---
    // Note: In a real system, these would interact with an external ERC-721 contract
    // that implements dynamic metadata updates. This simulates the ownership and metadata.

    /**
     * @dev Returns the owner of a specific AetherArt NFT.
     * @param _tokenId The ID of the AetherArt NFT.
     * @return The address of the NFT's owner.
     */
    function getAetherArtOwner(uint256 _tokenId) public view returns (address) {
        return _aetherArtOwners[_tokenId];
    }

    /**
     * @dev Returns the current metadata URI of an AetherArt NFT.
     * @param _tokenId The ID of the AetherArt NFT.
     * @return The metadata URI.
     */
    function getAetherArtMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return _aetherArtMetadataURIs[_tokenId];
    }

    /**
     * @dev Allows an AetherArt NFT owner to propose a metadata evolution for their NFT.
     *      This proposal then goes through the DAO governance for approval.
     * @param _tokenId The ID of the AetherArt NFT to propose evolution for.
     * @param _newMetadataURI The new metadata URI to apply if approved.
     * @param _reason A description of why this evolution is proposed.
     */
    function proposeAetherArtEvolution(uint256 _tokenId, string memory _newMetadataURI, string memory _reason) public whenNotPaused {
        require(_aetherArtOwners[_tokenId] == msg.sender, "Only AetherArt owner can propose evolution");
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty");

        // Encode the call to `approveAetherArtEvolution` which will be executed if the proposal passes.
        bytes memory callData = abi.encodeWithSelector(
            this.approveAetherArtEvolution.selector,
            _tokenId,
            _newMetadataURI
        );
        // Create a governance proposal for this specific NFT evolution
        uint256 currentProposalId = _createGovernanceProposal(callData, string(abi.encodePacked("Propose AetherArt Evolution for ID ", _tokenId.toString(), ": ", _reason)));
        
        emit AetherArtEvolutionProposed(currentProposalId, _tokenId, _newMetadataURI);
    }

    /**
     * @dev Internal function to update the AetherArt NFT metadata URI.
     *      This function is designed to be called ONLY by `executeQueuedGovernanceProposal`
     *      after a proposal to evolve the NFT has been approved by the DAO.
     * @param _tokenId The ID of the AetherArt NFT to evolve.
     * @param _newMetadataURI The new metadata URI.
     */
    function approveAetherArtEvolution(uint256 _tokenId, string memory _newMetadataURI) public onlyGovernance {
        require(_aetherArtOwners[_tokenId] != address(0), "AetherArt NFT does not exist");
        _aetherArtMetadataURIs[_tokenId] = _newMetadataURI;
        // Using proposal ID 0 as a placeholder since this is called internally by a generic proposal executor
        emit AetherArtEvolutionApproved(0, _tokenId, _newMetadataURI);
    }

    /**
     * @dev Requests the AI oracle to perform an analysis on an existing AetherArt NFT.
     *      This could be for style classification, sentiment analysis, or generating new insights.
     * @param _tokenId The ID of the AetherArt NFT to analyze.
     */
    function triggerAIArtAnalysis(uint256 _tokenId) public whenNotPaused {
        require(_aetherArtOwners[_tokenId] != address(0), "AetherArt NFT does not exist");
        require(oracleAddress != address(0), "Oracle address not set");

        // In a real Chainlink integration, this would use fulfillOracleRequest and pay Link.
        // For this demo, we'll just emit an event and expect the oracle to call back
        // `fulfillAIArtAnalysis`. The oracle would read `_aetherArtMetadataURIs[_tokenId]`
        // to get the content to analyze.
        IAIAssistantOracle(oracleAddress).fulfillAIArtAnalysis(_tokenId, "", bytes32(0)); // Dummy call to simulate request
        emit AIArtAnalysisRequested(_tokenId);
    }

    /**
     * @dev Called by the trusted oracle to deliver the AI analysis report for an AetherArt NFT.
     *      This report can inform future evolutions or reputation accrual (e.g., if AI deems art a "masterpiece").
     * @param _tokenId The ID of the AetherArt NFT that was analyzed.
     * @param _analysisReportURI The URI pointing to the AI's analysis report.
     * @param _externalJobId An ID from the external oracle system for tracking.
     */
    function fulfillAIArtAnalysis(uint256 _tokenId, string memory _analysisReportURI, bytes32 _externalJobId) external {
        require(msg.sender == oracleAddress, "Caller is not the trusted oracle");
        require(_aetherArtOwners[_tokenId] != address(0), "AetherArt NFT does not exist");

        // Here, the contract could store _analysisReportURI (e.g., in a separate mapping)
        // or trigger further on-chain logic based on the analysis (e.g., auto-mint a badge
        // to the artist if the AI report indicates high quality).
        // For simplicity, we just emit the event and potentially mint a badge.
        emit AIArtAnalysisFulfilled(_tokenId, _analysisReportURI);

        // Example: If AI analysis is positive (conceptually, actual analysis data would be off-chain),
        // mint a "AI-Recognized Artist" badge to the NFT owner.
        _mintReputationBadge(_aetherArtOwners[_tokenId], 5, "AI-Recognized AetherArt Creator"); // Badge ID 5
    }

    // --- V. Reputation System (AetherReputation - Soulbound Badges - Internal Simulation) ---
    // Note: This simulates a simple soulbound token (SBT) system. A real system might use ERC-1155 or ERC-721
    // with non-transferability enforced at the contract level (e.g., overriding _transfer or transferFrom).

    /**
     * @dev Mints a non-transferable (soulbound) reputation badge to a user.
     *      Only callable by owner or via governance.
     * @param _recipient The address to mint the badge to.
     * @param _badgeId The ID of the badge to mint (e.g., 1 for "Aether Pioneer").
     * @param _reason A description of why the badge is minted.
     */
    function mintReputationBadge(address _recipient, uint256 _badgeId, string memory _reason) public onlyGovernanceOrOwner {
        require(reputationBadgeNames[_badgeId].length > 0, "Badge ID does not exist");
        require(!_reputationBadgeOwnership[_recipient][_badgeId], "Recipient already has this badge");

        _reputationBadgeOwnership[_recipient][_badgeId] = true;
        _userReputationBadgesList[_recipient].push(_badgeId); // Add to list for easier lookup

        emit ReputationBadgeMinted(_recipient, _badgeId, _reason);
    }

    /**
     * @dev Revokes a reputation badge from a user. Only callable by owner or via governance.
     * @param _recipient The address from whom to revoke the badge.
     * @param _badgeId The ID of the badge to revoke.
     */
    function revokeReputationBadge(address _recipient, uint256 _badgeId) public onlyGovernanceOrOwner {
        require(_reputationBadgeOwnership[_recipient][_badgeId], "Recipient does not have this badge");

        _reputationBadgeOwnership[_recipient][_badgeId] = false;
        // Remove from list (inefficient for very large lists, but simple for demo)
        uint256[] storage badges = _userReputationBadgesList[_recipient];
        for (uint256 i = 0; i < badges.length; i++) {
            if (badges[i] == _badgeId) {
                badges[i] = badges[badges.length - 1]; // Move last element to current position
                badges.pop(); // Remove last element
                break;
            }
        }
        emit ReputationBadgeRevoked(_recipient, _badgeId);
    }

    /**
     * @dev Internal helper for minting badges, callable by other internal logic (e.g., AI fulfillment).
     *      Checks if the badge exists and if the recipient doesn't already own it before minting.
     */
    function _mintReputationBadge(address _recipient, uint256 _badgeId, string memory _reason) internal {
        if (reputationBadgeNames[_badgeId].length > 0 && !_reputationBadgeOwnership[_recipient][_badgeId]) {
            _reputationBadgeOwnership[_recipient][_badgeId] = true;
            _userReputationBadgesList[_recipient].push(_badgeId);
            emit ReputationBadgeMinted(_recipient, _badgeId, _reason);
        }
    }

    /**
     * @dev Returns a list of badge IDs held by a user.
     * @param _user The address of the user.
     * @return An array of badge IDs.
     */
    function getUserReputationBadges(address _user) public view returns (uint256[] memory) {
        return _userReputationBadgesList[_user];
    }

    /**
     * @dev Calculates a simplistic composite reputation score for a user.
     *      Factors in staked AETH, number of badges, and specific badge ownership.
     *      (This is a simplified example; real reputation systems would be more nuanced and complex).
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function calculateUserEffectiveReputation(address _user) public view returns (uint256) {
        uint256 score = 0;

        // Factor 1: Staked AETH (higher stake = higher reputation)
        score += stakedAETH[_user] / (10**18); // Convert to whole units for score calculation

        // Factor 2: Number of unique badges (each badge adds a base score)
        score += _userReputationBadgesList[_user].length * 10; // Each badge adds 10 points

        // Factor 3: Specific high-value badges (e.g., "Top Prompter", "Council Member")
        if (_reputationBadgeOwnership[_user][2]) { // If "Top Prompter" badge
            score += 20; // Bonus for good prompts
        }
        if (_reputationBadgeOwnership[_user][3]) { // If "Aether Curator" badge
            score += 15; // Bonus for active reviews
        }
        if (_reputationBadgeOwnership[_user][4]) { // If "Council Member" badge
            score += 30; // Significant bonus for governance participation
        }
        if (_reputationBadgeOwnership[_user][5]) { // If "AI-Recognized Artist" badge
            score += 40; // High bonus for AI-validated art
        }

        // Add a bonus for active delegators (if they delegate their vote to someone else)
        if (voteDelegates[_user] != address(0) && voteDelegates[_user] != _user) {
            score += 5; // Small bonus for empowering others in governance
        }

        return score;
    }

    // --- VI. Advanced Governance & DAO Operations ---

    /**
     * @dev Modifier to ensure a function is called either by the contract owner or by a successful governance execution.
     *      This is useful for sensitive functions that can be managed by the DAO.
     */
    modifier onlyGovernanceOrOwner() {
        require(msg.sender == owner() || msg.sender == address(this), "Caller is not owner or governance"); // self-call indicates governance execution
        _;
    }

    /**
     * @dev Modifier to ensure a function is called only by a successful governance execution.
     *      This is typically used for functions that should *only* be called after a DAO vote.
     */
    modifier onlyGovernance() {
        require(msg.sender == address(this), "Caller is not governance"); // self-call indicates governance execution
        _;
    }

    /**
     * @dev Internal helper to create a new governance proposal.
     *      Called by `proposeGovernanceAction` and `proposeAetherArtEvolution`.
     * @param _callData The encoded function call (target and arguments) to be executed if the proposal passes.
     * @param _description A human-readable description of the proposal.
     * @return The ID of the created proposal.
     */
    function _createGovernanceProposal(bytes memory _callData, string memory _description) internal returns (uint256) {
        require(stakedAETH[msg.sender] >= proposalThreshold, "Insufficient staked AETH to propose");
        uint256 currentProposalId = nextProposalId++;
        proposals[currentProposalId] = Proposal({
            description: _description,
            callData: _callData,
            proposerStake: stakedAETH[msg.sender], // Record proposer's stake at time of proposal
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + votingPeriod,
            executionTime: 0,
            executed: false,
            cancelled: false,
            hasVoted: new mapping(address => bool) // Initialize the nested mapping for voters
        });
        emit GovernanceProposalCreated(currentProposalId, _description, msg.sender);
        return currentProposalId;
    }

    /**
     * @dev Allows users to propose arbitrary actions for the DAO to vote on.
     *      Requires a minimum staked AETH as defined by `proposalThreshold`.
     * @param _callData The encoded function call (target and arguments) to be executed if the proposal passes.
     * @param _description A human-readable description of the proposal.
     */
    function proposeGovernanceAction(bytes memory _callData, string memory _description) public whenNotPaused {
        _createGovernanceProposal(_callData, _description);
    }

    /**
     * @dev Allows users to vote on open governance proposals.
     *      Voting power is based on the amount of AETH staked by the voter or their delegate.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (yes), false for 'against' (no).
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");

        address voterEffectiveAddress = msg.sender;
        if (voteDelegates[msg.sender] != address(0)) {
            voterEffectiveAddress = voteDelegates[msg.sender]; // Use delegated voting power
        }

        uint256 votingPower = stakedAETH[voterEffectiveAddress];
        require(votingPower > 0, "No voting power (stake AETH or delegate)");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true; // Mark original voter (not delegate) as having voted

        emit GovernanceVoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @dev After a proposal passes its voting period and reaches quorum/majority, it enters a timelock period.
     *      Anyone can call this function to queue the execution.
     * @param _proposalId The ID of the proposal to queue.
     */
    function queueGovernanceExecution(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended");
        require(proposal.executionTime == 0, "Proposal already queued or executed");
        require(!proposal.cancelled, "Proposal cancelled");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= minVoteQuorum, "Quorum not reached");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass (more against votes)");

        proposal.executionTime = block.timestamp + timelockPeriod;
        emit GovernanceProposalQueued(_proposalId, proposal.executionTime);

        // Optionally, mint a "Council Member" badge to active voters on a passed proposal
        _mintReputationBadge(msg.sender, 4, "Active Governance Contributor"); // Badge ID 4 for "Council Member"
    }

    /**
     * @dev Executes a governance proposal after its timelock period has passed.
     *      Anyone can call this once the conditions are met.
     *      The `callData` encoded in the proposal is executed by this contract.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeQueuedGovernanceProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.executionTime != 0, "Proposal not queued");
        require(block.timestamp >= proposal.executionTime, "Timelock period not over");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");

        // The quorum and vote check is primarily done when queuing, so we just check timelock and status here.

        proposal.executed = true;

        // Execute the proposed call data by making an internal call to this contract.
        // This allows the DAO to call any public function within AetherForge.
        (bool success, bytes memory result) = address(this).call(proposal.callData);
        require(success, string(abi.encodePacked("Proposal execution failed: ", result)));

        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows for the cancellation of a governance proposal, e.g., if conditions change, or a vulnerability is found.
     *      For this demo, only the owner can cancel for simplicity. In a full DAO, this might require a new, urgent vote.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelGovernanceProposal(uint256 _proposalId) public onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(!proposal.executed, "Cannot cancel an executed proposal");
        require(!proposal.cancelled, "Proposal already cancelled");
        require(block.timestamp < proposal.votingEndTime, "Cannot cancel after voting ends unless specific conditions met"); // Or define specific conditions for post-voting cancellation

        proposal.cancelled = true;
        emit GovernanceProposalCancelled(_proposalId);
    }
}
```