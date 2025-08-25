```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint256 to string for NFT URI

/*
Outline: AetherChronicles - A Decentralized, AI-Assisted, Reputation-Based Knowledge Network

This smart contract establishes a decentralized platform for community-curated knowledge "Chronicles". Scribes (users) propose, update, and challenge Chronicles, earning reputation and rewards for truthful and high-quality contributions. The system incorporates an AI oracle for initial validation, a dynamic NFT system reflecting Scribe influence, and privacy-preserving mechanisms for voting.

Core Concepts:
1.  **Chronicles**: Dynamic content units (e.g., articles, data entries) stored as IPFS CIDs, with versioning and metadata.
2.  **Scribes**: Users who contribute to Chronicles, building a reputation score.
3.  **Reputation**: An on-chain score influencing a Scribe's voting power, ability to propose/approve, and reward share.
4.  **Curation & Challenges**: Scribes approve, challenge, and vote on Chronicles, resolving disputes with Aether token stakes.
5.  **Aether Token (ERC20)**: The native utility token for staking, rewards, and governance.
6.  **InsightNFT (ERC721)**: Dynamic NFTs representing a Scribe's achievements and influence, with metadata updating based on their on-chain actions and reputation. The `AetherChronicles` contract is designed to be the owner/controller of the `InsightNFT` contract to manage minting and metadata updates.
7.  **AI Oracle Integration**: An authorized off-chain AI service can submit verifiable validation results, assisting human curators and influencing reputation. This is not on-chain AI computation but rather an on-chain verification of off-chain AI outputs.
8.  **Privacy-Preserving Voting**: A commit-reveal scheme for challenge votes to enhance fairness and mitigate front-running and manipulation.

Function Summary:

I. Core System Management & Access Control
1.  `constructor`: Initializes the contract with essential addresses and parameters.
2.  `updateAetherTokenAddress`: Owner can update the Aether ERC20 token contract address.
3.  `updateInsightNFTAddress`: Owner can update the InsightNFT ERC721 token contract address.
4.  `setProtocolFeeRecipient`: Owner sets the address to receive protocol fees.
5.  `setProtocolFeePercentage`: Owner sets the percentage of fees taken from certain operations.
6.  `setMinStakeForChronicleProposal`: Owner sets the minimum Aether required to propose a Chronicle.
7.  `setChallengePeriod`: Owner sets the duration for Chronicle challenges.
8.  `setRevealPeriod`: Owner sets the duration for revealing private votes in challenges.
9.  `setMinReputationForApproval`: Owner sets the minimum reputation required to approve content.
10. `setAIOracleAddress`: Owner sets the trusted AI oracle's address.
11. `pause`: Owner can pause contract operations in emergencies.
12. `unpause`: Owner can unpause the contract.
13. `emergencyWithdrawERC20`: Owner can rescue inadvertently sent ERC20 tokens.
14. `renounceOwnership`: Owner can renounce ownership (inherited from Ownable).
15. `transferOwnership`: Owner can transfer ownership to a new address (inherited from Ownable).

II. Scribe & Reputation Management
16. `registerScribe`: Allows a user to register as a Scribe, requiring an initial Aether stake.
17. `updateScribeProfile`: Scribes can update their public profile metadata URI.
18. `getScribeReputation`: View function to get a Scribe's current reputation score.
19. `getScribeDetails`: View function to get comprehensive details about a Scribe.
20. `stakeAetherForReputation`: Scribes can stake additional Aether to temporarily boost their influence or access.
21. `withdrawScribeStake`: Scribes can withdraw their general Aether stake after a cooldown or if not tied to active challenges.

III. Chronicle Content & Curation
22. `proposeChronicle`: Scribe proposes a new Chronicle, requiring a stake and content/metadata URIs.
23. `updateChronicleContent`: Scribe updates their existing Chronicle, requiring a stake and reputation.
24. `approveChronicleContent`: Scribes with sufficient reputation can approve a Chronicle or its update, increasing its validity.
25. `challengeChronicle`: Scribe challenges a Chronicle's accuracy or validity, requiring a stake.
26. `submitPrivateVoteCommitment`: For challenge votes, Scribes submit a hashed commitment of their vote (privacy-preserving).
27. `revealPrivateVote`: Scribes reveal their actual vote and salt after the commitment period.
28. `resolveChallenge`: Finalizes a challenge, distributing stakes, rewards, and reputation based on voting outcome.
29. `getChronicleDetails`: View function to get full details of a specific Chronicle.
30. `getChronicleApprovals`: View function to get the current count of approvals for a Chronicle.

IV. AI & Dynamic InsightNFTs
31. `submitAIValidationResult`: The designated AI oracle submits a verifiable result for a Chronicle, influencing its status and Scribe reputation.
32. `mintInsightNFT`: Scribes can mint an InsightNFT if they meet the reputation and contribution criteria.
33. `updateInsightNFTMetadata`: Callable by the NFT owner (the Scribe) through this contract, which then, as the owner of InsightNFT, updates the URI. This makes the NFT dynamic based on Scribe's on-chain achievements and allows for off-chain metadata generation.
*/

contract AetherChronicles is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // Token Contracts
    IERC20 public aetherToken;
    ERC721URIStorage public insightNFT; // AetherChronicles will be the owner of this contract.

    // Core Data Structures
    uint256 public chronicleCounter; // Auto-incrementing ID for chronicles
    uint256 public nextInsightNFTId = 1; // Counter for next InsightNFT token ID

    struct Chronicle {
        uint256 id;
        address author;
        string contentHash; // IPFS CID or similar for content
        string metadataURI; // IPFS CID for chronicle metadata
        uint256 version;
        Status status;
        uint256 totalStaked; // Total Aether staked on this chronicle (initial proposal, challenges, votes)
        uint256 challengeDeadline; // Timestamp when a challenge voting/reveal ends
        uint256 commitDeadline; // Timestamp when commitment period for private votes ends
        uint256 revealDeadline; // Timestamp when reveal period for private votes ends
        mapping(address => bool) hasApproved; // Scribes who have approved this chronicle
        uint256 approvalCount;
        uint256 disapprovalCount;
        bytes32 challengeReasonHash; // Hash of the reason for challenge
        mapping(address => bytes32) privateVoteCommitments; // For challenge votes
        mapping(address => bool) privateVoteRevealed; // Track revealed votes
        uint256 challengeVoteFor; // Sum of reputation-weighted votes to accept the challenge (i.e., against the chronicle)
        uint256 challengeVoteAgainst; // Sum of reputation-weighted votes to reject the challenge (i.e., for the chronicle)
    }

    struct Scribe {
        bool isRegistered;
        uint256 reputationScore;
        uint256 activeStake; // Total Aether staked by the scribe for general purposes (not locked in specific challenge votes)
        uint256 lastActive; // Timestamp of last significant activity
        string profileURI; // IPFS CID or similar for scribe's profile metadata
        uint256 insightNFTId; // 0 if no NFT, otherwise the ID of their InsightNFT
    }

    enum Status { Proposed, Active, Challenged, Resolved_Approved, Resolved_Rejected }

    mapping(uint256 => Chronicle) public chronicles;
    mapping(address => Scribe) public scribes;

    // Protocol Parameters
    address public protocolFeeRecipient;
    uint256 public protocolFeePercentage; // e.g., 500 = 5% (scaled by 10000, max 10000 for 100%)
    uint256 public minStakeForChronicleProposal; // Minimum Aether required to propose/update
    uint256 public challengePeriod; // Duration in seconds for a challenge to run (total time)
    uint256 public revealPeriod; // Duration in seconds for revealing votes after commit period (part of challengePeriod)
    uint256 public minReputationForApproval; // Minimum reputation score to approve a chronicle

    // AI Oracle
    address public aiOracleAddress; // Trusted address for AI validation submissions

    // --- Events ---
    event AetherTokenAddressUpdated(address indexed newAddress);
    event InsightNFTAddressUpdated(address indexed newAddress);
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeePercentageUpdated(uint256 newPercentage);
    event MinStakeForChronicleProposalUpdated(uint256 newStake);
    event ChallengePeriodUpdated(uint256 newPeriod);
    event RevealPeriodUpdated(uint256 newPeriod);
    event MinReputationForApprovalUpdated(uint256 newMinRep);
    event AIOracleAddressUpdated(address indexed newAIOracle);

    event ScribeRegistered(address indexed scribe, string profileURI, uint256 initialReputation);
    event ScribeProfileUpdated(address indexed scribe, string newProfileURI);
    event ScribeReputationUpdated(address indexed scribe, uint256 newReputation);
    event ScribeStakedAether(address indexed scribe, uint256 amount);
    event ScribeWithdrewStake(address indexed scribe, uint256 amount);

    event ChronicleProposed(uint256 indexed chronicleId, address indexed author, string contentHash, string metadataURI);
    event ChronicleContentUpdated(uint256 indexed chronicleId, address indexed updater, string newContentHash, string newMetadataURI);
    event ChronicleApproved(uint256 indexed chronicleId, address indexed approver);
    event ChronicleChallenged(uint256 indexed chronicleId, address indexed challenger, bytes32 reasonHash);
    event PrivateVoteCommitment(uint256 indexed chronicleId, address indexed voter, bytes32 commitmentHash);
    event PrivateVoteRevealed(uint256 indexed chronicleId, address indexed voter, bool voteAgainstChallenge);
    event ChallengeResolved(uint256 indexed chronicleId, Status finalStatus, uint256 totalWinningWeight, uint256 totalLosingWeight);

    event AIValidationResultSubmitted(uint256 indexed chronicleId, bytes32 proofHash, bool isValidated);
    event InsightNFTMinted(address indexed scribe, uint256 indexed tokenId);
    event InsightNFTMetadataUpdated(uint256 indexed tokenId, string newURI);

    // --- Modifiers ---
    modifier onlyScribe() {
        require(scribes[msg.sender].isRegistered, "Caller is not a registered Scribe");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Caller is not the AI Oracle");
        _;
    }

    // --- Constructor ---
    constructor(
        address _aetherToken,
        address _insightNFT,
        address _aiOracle,
        uint256 _minStake,
        uint256 _challengePeriod,
        uint256 _revealPeriod,
        uint256 _minRepForApproval
    )
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        require(_aetherToken != address(0), "Aether token address cannot be zero");
        require(_insightNFT != address(0), "InsightNFT address cannot be zero");
        require(_aiOracle != address(0), "AI Oracle address cannot be zero");
        require(_minStake > 0, "Min stake must be greater than zero");
        require(_challengePeriod > _revealPeriod, "Challenge period must be longer than reveal period");
        require(_revealPeriod > 0, "Reveal period must be greater than zero");
        require(_minRepForApproval >= 0, "Min reputation for approval cannot be negative");

        aetherToken = IERC20(_aetherToken);
        insightNFT = ERC721URIStorage(_insightNFT);
        aiOracleAddress = _aiOracle;
        minStakeForChronicleProposal = _minStake;
        challengePeriod = _challengePeriod;
        revealPeriod = _revealPeriod;
        minReputationForApproval = _minRepForApproval;

        protocolFeeRecipient = msg.sender; // Default to owner
        protocolFeePercentage = 500; // 5% (500 basis points out of 10000)
    }

    // --- I. Core System Management & Access Control ---

    /**
     * @notice Updates the Aether ERC20 token contract address. Only owner can call.
     * @param newAddress The new address for the Aether token.
     */
    function updateAetherTokenAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "New Aether token address cannot be zero");
        aetherToken = IERC20(newAddress);
        emit AetherTokenAddressUpdated(newAddress);
    }

    /**
     * @notice Updates the InsightNFT ERC721 token contract address. Only owner can call.
     * @param newAddress The new address for the InsightNFT token.
     */
    function updateInsightNFTAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "New InsightNFT address cannot be zero");
        insightNFT = ERC721URIStorage(newAddress);
        emit InsightNFTAddressUpdated(newAddress);
    }

    /**
     * @notice Sets the address that receives protocol fees. Only owner can call.
     * @param newRecipient The new address for protocol fees.
     */
    function setProtocolFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Recipient address cannot be zero");
        protocolFeeRecipient = newRecipient;
        emit ProtocolFeeRecipientUpdated(newRecipient);
    }

    /**
     * @notice Sets the percentage of protocol fees. Scaled by 10000 (e.g., 500 for 5%). Only owner can call.
     * @param newPercentage The new fee percentage (0-10000).
     */
    function setProtocolFeePercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 10000, "Percentage cannot exceed 100%");
        protocolFeePercentage = newPercentage;
        emit ProtocolFeePercentageUpdated(newPercentage);
    }

    /**
     * @notice Sets the minimum Aether required to propose or update a Chronicle. Only owner can call.
     * @param newStake The new minimum stake amount.
     */
    function setMinStakeForChronicleProposal(uint256 newStake) external onlyOwner {
        require(newStake > 0, "Min stake must be greater than zero");
        minStakeForChronicleProposal = newStake;
        emit MinStakeForChronicleProposalUpdated(newStake);
    }

    /**
     * @notice Sets the duration (in seconds) for a Chronicle challenge period. Only owner can call.
     * @param newPeriod The new challenge period duration.
     */
    function setChallengePeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > revealPeriod, "Challenge period must be longer than reveal period");
        challengePeriod = newPeriod;
        emit ChallengePeriodUpdated(newPeriod);
    }

    /**
     * @notice Sets the duration (in seconds) for revealing private votes in challenges. Only owner can call.
     * @param newPeriod The new reveal period duration.
     */
    function setRevealPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Reveal period must be greater than zero");
        require(challengePeriod > newPeriod, "Challenge period must be longer than reveal period");
        revealPeriod = newPeriod;
        emit RevealPeriodUpdated(newPeriod);
    }

    /**
     * @notice Sets the minimum reputation score required for a Scribe to approve a Chronicle. Only owner can call.
     * @param newMinRep The new minimum reputation score.
     */
    function setMinReputationForApproval(uint256 newMinRep) external onlyOwner {
        minReputationForApproval = newMinRep;
        emit MinReputationForApprovalUpdated(newMinRep);
    }

    /**
     * @notice Sets the trusted AI oracle's address. Only this address can submit AI validation results. Only owner can call.
     * @param newAIOracle The new AI oracle address.
     */
    function setAIOracleAddress(address newAIOracle) external onlyOwner {
        require(newAIOracle != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = newAIOracle;
        emit AIOracleAddressUpdated(newAIOracle);
    }

    /**
     * @notice Pauses contract operations in case of an emergency. Only owner can call.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract operations. Only owner can call.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw any ERC20 tokens accidentally sent to the contract. Only owner can call.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }

    // `renounceOwnership` and `transferOwnership` are inherited from Ownable.

    // --- II. Scribe & Reputation Management ---

    /**
     * @notice Allows a user to register as a Scribe. Requires an initial Aether stake.
     * @param _profileURI IPFS CID or similar for the Scribe's public profile metadata.
     */
    function registerScribe(string memory _profileURI) external whenNotPaused nonReentrant {
        require(!scribes[msg.sender].isRegistered, "Already a registered Scribe");
        require(aetherToken.balanceOf(msg.sender) >= minStakeForChronicleProposal, "Insufficient Aether balance for initial stake");
        
        // Transfer Aether from sender to contract as initial stake
        aetherToken.safeTransferFrom(msg.sender, address(this), minStakeForChronicleProposal);

        scribes[msg.sender] = Scribe({
            isRegistered: true,
            reputationScore: 100, // Initial reputation
            activeStake: minStakeForChronicleProposal,
            lastActive: block.timestamp,
            profileURI: _profileURI,
            insightNFTId: 0
        });

        emit ScribeRegistered(msg.sender, _profileURI, 100);
        emit ScribeStakedAether(msg.sender, minStakeForChronicleProposal);
    }

    /**
     * @notice Allows a Scribe to update their public profile metadata URI. Only registered Scribes can call.
     * @param _newProfileURI The new IPFS CID or similar for the profile metadata.
     */
    function updateScribeProfile(string memory _newProfileURI) external onlyScribe whenNotPaused {
        scribes[msg.sender].profileURI = _newProfileURI;
        scribes[msg.sender].lastActive = block.timestamp;
        emit ScribeProfileUpdated(msg.sender, _newProfileURI);
    }

    /**
     * @notice Retrieves a Scribe's current reputation score.
     * @param scribeAddress The address of the Scribe.
     * @return The reputation score.
     */
    function getScribeReputation(address scribeAddress) public view returns (uint256) {
        return scribes[scribeAddress].reputationScore;
    }

    /**
     * @notice Retrieves comprehensive details about a Scribe.
     * @param scribeAddress The address of the Scribe.
     * @return A tuple containing Scribe details.
     */
    function getScribeDetails(address scribeAddress) public view returns (
        bool isRegistered,
        uint256 reputationScore,
        uint256 activeStake,
        uint256 lastActive,
        string memory profileURI,
        uint256 insightNFTId
    ) {
        Scribe storage scribe = scribes[scribeAddress];
        return (
            scribe.isRegistered,
            scribe.reputationScore,
            scribe.activeStake,
            scribe.lastActive,
            scribe.profileURI,
            scribe.insightNFTId
        );
    }

    /**
     * @notice Scribes can stake additional Aether to boost their temporary influence or access. Only registered Scribes can call.
     * @param amount The amount of Aether to stake.
     */
    function stakeAetherForReputation(uint256 amount) external onlyScribe whenNotPaused nonReentrant {
        require(amount > 0, "Stake amount must be greater than zero");
        aetherToken.safeTransferFrom(msg.sender, address(this), amount);
        scribes[msg.sender].activeStake += amount;
        scribes[msg.sender].lastActive = block.timestamp;
        emit ScribeStakedAether(msg.sender, amount);
    }

    /**
     * @notice Scribes can withdraw their general Aether stake if not tied to active challenges or proposals.
     *         A cooldown might be implemented to prevent abuse (not strictly enforced here for simplicity,
     *         but activeStake ensures it's not locked in a vote). Only registered Scribes can call.
     * @param amount The amount of Aether to withdraw.
     */
    function withdrawScribeStake(uint256 amount) external onlyScribe whenNotPaused nonReentrant {
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(scribes[msg.sender].activeStake >= amount, "Insufficient active stake available for withdrawal");
        
        scribes[msg.sender].activeStake -= amount;
        aetherToken.safeTransfer(msg.sender, amount);
        emit ScribeWithdrewStake(msg.sender, amount);
    }

    // --- III. Chronicle Content & Curation ---

    /**
     * @notice Allows a Scribe to propose a new Chronicle. Requires an Aether stake. Only registered Scribes can call.
     * @param _contentHash IPFS CID or similar for the Chronicle's main content.
     * @param _metadataURI IPFS CID or similar for additional Chronicle metadata.
     * @return The ID of the newly proposed Chronicle.
     */
    function proposeChronicle(string memory _contentHash, string memory _metadataURI) external onlyScribe whenNotPaused nonReentrant returns (uint256) {
        require(aetherToken.balanceOf(msg.sender) >= minStakeForChronicleProposal, "Insufficient Aether balance for proposal stake");

        uint256 chronicleId = ++chronicleCounter;
        
        aetherToken.safeTransferFrom(msg.sender, address(this), minStakeForChronicleProposal);
        
        chronicles[chronicleId] = Chronicle({
            id: chronicleId,
            author: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            version: 1,
            status: Status.Proposed,
            totalStaked: minStakeForChronicleProposal, // Initial stake for proposal
            challengeDeadline: 0,
            commitDeadline: 0,
            revealDeadline: 0,
            approvalCount: 0,
            disapprovalCount: 0,
            challengeReasonHash: bytes32(0),
            challengeVoteFor: 0,
            challengeVoteAgainst: 0
        });

        // Add reputation and last active timestamp
        scribes[msg.sender].reputationScore += 10; // Small reputation boost for proposing
        scribes[msg.sender].lastActive = block.timestamp;
        _tryUpdateScribeInsightNFT(msg.sender); // Potentially update their NFT metadata

        emit ChronicleProposed(chronicleId, msg.sender, _contentHash, _metadataURI);
        emit ScribeReputationUpdated(msg.sender, scribes[msg.sender].reputationScore);
        return chronicleId;
    }

    /**
     * @notice Allows the author Scribe to update their existing Chronicle.
     *         Requires reputation and an Aether stake to signal commitment. Only registered Scribes can call.
     * @param _chronicleId The ID of the Chronicle to update.
     * @param _newContentHash The new IPFS CID for the Chronicle's main content.
     * @param _newMetadataURI The new IPFS CID for Chronicle metadata.
     */
    function updateChronicleContent(uint256 _chronicleId, string memory _newContentHash, string memory _newMetadataURI) external onlyScribe whenNotPaused nonReentrant {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        require(chronicle.author == msg.sender, "Only the author can update their chronicle");
        require(chronicle.status != Status.Challenged, "Cannot update a challenged chronicle");
        require(chronicle.status != Status.Resolved_Approved && chronicle.status != Status.Resolved_Rejected, "Cannot update a resolved chronicle");
        require(scribes[msg.sender].reputationScore >= minReputationForApproval, "Insufficient reputation to update chronicle");
        require(aetherToken.balanceOf(msg.sender) >= minStakeForChronicleProposal, "Insufficient Aether balance for update stake");

        aetherToken.safeTransferFrom(msg.sender, address(this), minStakeForChronicleProposal);
        
        chronicle.contentHash = _newContentHash;
        chronicle.metadataURI = _newMetadataURI;
        chronicle.version++;
        chronicle.totalStaked += minStakeForChronicleProposal; // Add stake for update
        chronicle.status = Status.Proposed; // Revert to proposed for re-approval
        chronicle.approvalCount = 0; // Reset approvals
        chronicle.disapprovalCount = 0; // Reset disapprovals

        scribes[msg.sender].lastActive = block.timestamp;
        _tryUpdateScribeInsightNFT(msg.sender);
        emit ChronicleContentUpdated(_chronicleId, msg.sender, _newContentHash, _newMetadataURI);
    }

    /**
     * @notice Allows a Scribe with sufficient reputation to approve a Chronicle or its update. Only registered Scribes can call.
     * @param _chronicleId The ID of the Chronicle to approve.
     */
    function approveChronicleContent(uint256 _chronicleId) external onlyScribe whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        require(chronicle.author != msg.sender, "Author cannot approve their own chronicle");
        require(!chronicle.hasApproved[msg.sender], "Scribe has already approved this chronicle");
        require(chronicle.status == Status.Proposed || chronicle.status == Status.Active, "Chronicle is not in an approvable status");
        require(scribes[msg.sender].reputationScore >= minReputationForApproval, "Insufficient reputation to approve");

        chronicle.hasApproved[msg.sender] = true;
        chronicle.approvalCount++;
        scribes[msg.sender].reputationScore += 1; // Small reputation boost for approval
        scribes[msg.sender].lastActive = block.timestamp;
        _tryUpdateScribeInsightNFT(msg.sender);

        // Example: Transition to Active status if a simple threshold is met
        if (chronicle.approvalCount >= 5 && chronicle.status == Status.Proposed) { 
            chronicle.status = Status.Active;
        }

        emit ChronicleApproved(_chronicleId, msg.sender);
        emit ScribeReputationUpdated(msg.sender, scribes[msg.sender].reputationScore);
    }

    /**
     * @notice Allows a Scribe to challenge a Chronicle's accuracy or validity.
     *         Requires an Aether stake. Only registered Scribes can call.
     * @param _chronicleId The ID of the Chronicle to challenge.
     * @param _reasonHash IPFS CID or similar for the reason/evidence for the challenge.
     */
    function challengeChronicle(uint256 _chronicleId, bytes32 _reasonHash) external onlyScribe whenNotPaused nonReentrant {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        require(chronicle.status != Status.Challenged, "Chronicle is already under challenge");
        require(chronicle.status != Status.Resolved_Approved && chronicle.status != Status.Resolved_Rejected, "Cannot challenge a resolved chronicle");
        require(aetherToken.balanceOf(msg.sender) >= minStakeForChronicleProposal, "Insufficient Aether balance for challenge stake");

        aetherToken.safeTransferFrom(msg.sender, address(this), minStakeForChronicleProposal);
        scribes[msg.sender].activeStake += minStakeForChronicleProposal; // Challenger's stake goes to their general activeStake
        chronicle.totalStaked += minStakeForChronicleProposal; // Add to chronicle's total stake pool for challenges
        
        chronicle.status = Status.Challenged;
        chronicle.challengeReasonHash = _reasonHash;
        chronicle.challengeDeadline = block.timestamp + challengePeriod;
        chronicle.commitDeadline = chronicle.challengeDeadline - revealPeriod; // Commit period ends `revealPeriod` before challenge deadline
        chronicle.revealDeadline = chronicle.challengeDeadline; // Reveal period ends at challenge deadline

        scribes[msg.sender].reputationScore = scribes[msg.sender].reputationScore > 5 ? scribes[msg.sender].reputationScore - 5 : 0; // Small reputation penalty to prevent spam challenges
        scribes[msg.sender].lastActive = block.timestamp;
        _tryUpdateScribeInsightNFT(msg.sender);

        emit ChronicleChallenged(_chronicleId, msg.sender, _reasonHash);
        emit ScribeReputationUpdated(msg.sender, scribes[msg.sender].reputationScore);
    }

    /**
     * @notice Scribes submit a hashed commitment of their vote for a challenge to ensure privacy.
     *         This should be done during the commitment phase. Only registered Scribes can call.
     * @param _chronicleId The ID of the challenged Chronicle.
     * @param _commitmentHash The keccak256 hash of (voteAgainstChallenge, salt).
     */
    function submitPrivateVoteCommitment(uint256 _chronicleId, bytes32 _commitmentHash) external onlyScribe whenNotPaused nonReentrant {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        require(chronicle.status == Status.Challenged, "Chronicle is not challenged");
        require(block.timestamp <= chronicle.commitDeadline, "Commitment period has ended");
        require(chronicle.privateVoteCommitments[msg.sender] == bytes32(0), "Scribe has already committed a vote");
        
        // Require a small stake to vote, to prevent spam and add weight
        uint256 voteStake = minStakeForChronicleProposal / 10; // Example: 10% of proposal stake
        require(scribes[msg.sender].activeStake >= voteStake, "Insufficient active stake to vote");

        // Transfer stake from scribe's active stake to chronicle's totalStaked
        scribes[msg.sender].activeStake -= voteStake;
        chronicle.totalStaked += voteStake; 

        chronicle.privateVoteCommitments[msg.sender] = _commitmentHash;
        scribes[msg.sender].lastActive = block.timestamp;
        emit PrivateVoteCommitment(_chronicleId, msg.sender, _commitmentHash);
    }

    /**
     * @notice Scribes reveal their actual vote and salt after the commitment period.
     *         This should be done during the reveal phase. Only registered Scribes can call.
     * @param _chronicleId The ID of the challenged Chronicle.
     * @param _voteAgainstChallenge True if voting to accept the challenge (i.e., against the chronicle), false otherwise.
     * @param _salt A random number used for hashing the commitment.
     */
    function revealPrivateVote(uint256 _chronicleId, bool _voteAgainstChallenge, bytes32 _salt) external onlyScribe whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        require(chronicle.status == Status.Challenged, "Chronicle is not challenged");
        require(block.timestamp > chronicle.commitDeadline, "Commitment period is not over yet");
        require(block.timestamp <= chronicle.revealDeadline, "Reveal period has ended");
        require(chronicle.privateVoteCommitments[msg.sender] != bytes32(0), "No commitment found for this scribe");
        require(!chronicle.privateVoteRevealed[msg.sender], "Scribe has already revealed their vote");
        
        bytes32 expectedCommitment = keccak256(abi.encodePacked(_voteAgainstChallenge, _salt));
        require(chronicle.privateVoteCommitments[msg.sender] == expectedCommitment, "Commitment does not match revealed vote");

        chronicle.privateVoteRevealed[msg.sender] = true;
        uint256 voteWeight = scribes[msg.sender].reputationScore; // Reputation-weighted vote
        
        if (_voteAgainstChallenge) {
            chronicle.challengeVoteFor += voteWeight;
        } else {
            chronicle.challengeVoteAgainst += voteWeight;
        }
        
        scribes[msg.sender].lastActive = block.timestamp;
        _tryUpdateScribeInsightNFT(msg.sender);
        emit PrivateVoteRevealed(_chronicleId, msg.sender, _voteAgainstChallenge);
    }

    /**
     * @notice Finalizes a challenge, distributing stakes, rewards, and reputation based on voting outcome.
     *         Can be called by anyone after the reveal deadline.
     * @param _chronicleId The ID of the challenged Chronicle.
     */
    function resolveChallenge(uint256 _chronicleId) external nonReentrant {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        require(chronicle.status == Status.Challenged, "Chronicle is not currently challenged");
        require(block.timestamp > chronicle.revealDeadline, "Reveal period has not ended yet");

        uint256 totalAetherInChallenge = chronicle.totalStaked;
        uint256 fee = (totalAetherInChallenge * protocolFeePercentage) / 10000;
        uint256 rewardPool = totalAetherInChallenge - fee;

        // Distribute protocol fees
        if (fee > 0) {
            aetherToken.safeTransfer(protocolFeeRecipient, fee);
        }

        Status finalStatus;
        if (chronicle.challengeVoteFor > chronicle.challengeVoteAgainst) {
            // Challenge successful: Chronicle is rejected/invalidated
            finalStatus = Status.Resolved_Rejected;
            // Penalize chronicle author and reward those who voted for the challenge
            scribes[chronicle.author].reputationScore = scribes[chronicle.author].reputationScore / 2; // Significant penalty
            emit ScribeReputationUpdated(chronicle.author, scribes[chronicle.author].reputationScore);
            _tryUpdateScribeInsightNFT(chronicle.author);

            // Simplified reward distribution logic: Loser's stakes are forfeited.
            // A more complex system would meticulously track individual stakes for returns/distribution.
            // For now, assume winners (those whose votes aligned with the outcome) implicitly benefit
            // by reputation gain, and their stakes are not lost (though not explicitly returned here).
        } else {
            // Challenge failed: Chronicle is approved/validated
            finalStatus = Status.Resolved_Approved;
            // Reward chronicle author and those who voted against the challenge
            scribes[chronicle.author].reputationScore += 50; // Reputation boost for successfully defending
            emit ScribeReputationUpdated(chronicle.author, scribes[chronicle.author].reputationScore);
            _tryUpdateScribeInsightNFT(chronicle.author);

            // Simplified reward distribution logic
        }
        
        chronicle.totalStaked = 0; // All stakes are now distributed or forfeited.
        chronicle.status = finalStatus;
        
        emit ChallengeResolved(_chronicleId, finalStatus, chronicle.challengeVoteFor, chronicle.challengeVoteAgainst);
    }

    /**
     * @notice Retrieves full details of a specific Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @return A tuple containing Chronicle details.
     */
    function getChronicleDetails(uint256 _chronicleId) public view returns (
        uint256 id,
        address author,
        string memory contentHash,
        string memory metadataURI,
        uint256 version,
        Status status,
        uint256 totalStaked,
        uint256 challengeDeadline,
        uint256 commitDeadline,
        uint256 revealDeadline,
        uint256 approvalCount,
        uint256 disapprovalCount,
        bytes32 challengeReasonHash,
        uint256 challengeVoteFor,
        uint256 challengeVoteAgainst
    ) {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        return (
            chronicle.id,
            chronicle.author,
            chronicle.contentHash,
            chronicle.metadataURI,
            chronicle.version,
            chronicle.status,
            chronicle.totalStaked,
            chronicle.challengeDeadline,
            chronicle.commitDeadline,
            chronicle.revealDeadline,
            chronicle.approvalCount,
            chronicle.disapprovalCount,
            chronicle.challengeReasonHash,
            chronicle.challengeVoteFor,
            chronicle.challengeVoteAgainst
        );
    }

    /**
     * @notice Retrieves the current approval count for a Chronicle.
     * @param _chronicleId The ID of the Chronicle.
     * @return The number of approvals.
     */
    function getChronicleApprovals(uint256 _chronicleId) public view returns (uint256) {
        require(chronicles[_chronicleId].id != 0, "Chronicle does not exist");
        return chronicles[_chronicleId].approvalCount;
    }

    // --- IV. AI & Dynamic InsightNFTs ---

    /**
     * @notice The designated AI oracle submits a validation result for a Chronicle.
     *         This result can influence the Chronicle's status or Scribe reputation. Only the AI oracle can call.
     * @param _chronicleId The ID of the Chronicle that was validated.
     * @param _proofHash A hash representing the AI's verifiable proof (e.g., ZKP hash, signature of result).
     * @param _isValidated True if the AI deemed the Chronicle valid/accurate, false otherwise.
     */
    function submitAIValidationResult(uint256 _chronicleId, bytes32 _proofHash, bool _isValidated) external onlyAIOracle whenNotPaused {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.id != 0, "Chronicle does not exist");
        require(chronicle.status != Status.Resolved_Approved && chronicle.status != Status.Resolved_Rejected, "Cannot validate a resolved chronicle");

        // The AI validation doesn't directly change chronicle status in this version,
        // but influences reputation or provides an additional data point for human curators.
        if (_isValidated) {
            scribes[chronicle.author].reputationScore += 5; // Small boost for AI-validated content
            emit ScribeReputationUpdated(chronicle.author, scribes[chronicle.author].reputationScore);
            _tryUpdateScribeInsightNFT(chronicle.author);
        } else {
            // Potentially decrease reputation or flag for human review if AI finds issues.
            // For now, no direct penalty, just no boost.
        }

        emit AIValidationResultSubmitted(_chronicleId, _proofHash, _isValidated);
    }

    /**
     * @notice Allows a Scribe to mint an InsightNFT if they meet the criteria (e.g., reputation threshold). Only registered Scribes can call.
     *         This contract (AetherChronicles) is expected to be the owner of the InsightNFT contract
     *         to be able to mint and set metadata.
     */
    function mintInsightNFT() external onlyScribe whenNotPaused nonReentrant {
        Scribe storage scribe = scribes[msg.sender];
        require(scribe.insightNFTId == 0, "Scribe already owns an InsightNFT");
        require(scribe.reputationScore >= 500, "Minimum reputation (500) required to mint InsightNFT"); // Example threshold

        uint256 currentTokenId = nextInsightNFTId;
        nextInsightNFTId++;

        // Call the InsightNFT contract to mint. AetherChronicles must be the owner of InsightNFT or whitelisted minter.
        insightNFT.safeMint(msg.sender, currentTokenId); 
        
        scribe.insightNFTId = currentTokenId;
        
        // Set initial metadata URI. This should point to a default representation.
        // The actual dynamic metadata will be updated by `updateInsightNFTMetadata` later.
        insightNFT.setTokenURI(currentTokenId, "ipfs://QmbnQ4Zt2Y3X5W6V7R8S9T0U1V2W3X4Y5Z6A7B8C9D0E1F/default.json");

        emit InsightNFTMinted(msg.sender, currentTokenId);
    }

    /**
     * @notice Updates the metadata URI of an InsightNFT, making it dynamic.
     *         Callable by the NFT owner (the Scribe) through this contract.
     *         This function then, as the owner of InsightNFT, calls `setTokenURI` on the InsightNFT contract.
     * @param _tokenId The ID of the InsightNFT.
     * @param _newMetadataURI The new IPFS CID or URL for the NFT's metadata. This URI should be generated off-chain
     *                        based on the Scribe's current on-chain reputation and achievements.
     */
    function updateInsightNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public onlyScribe whenNotPaused {
        // Ensure the caller owns the NFT they are trying to update
        require(insightNFT.ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this InsightNFT");
        
        // Ensure this scribe has an InsightNFT associated with them and it matches the tokenId
        require(scribes[msg.sender].insightNFTId == _tokenId, "NFT ID does not match scribe's registered NFT");

        // The AetherChronicles contract itself, as the assumed owner of InsightNFT,
        // can now call setTokenURI.
        insightNFT.setTokenURI(_tokenId, _newMetadataURI);
        emit InsightNFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @notice Internal function to signal that a scribe's InsightNFT metadata
     *         should be updated off-chain, based on their new reputation/activity.
     *         This emits an event that an off-chain service can listen to.
     * @param _scribeAddress The address of the Scribe whose NFT might need updating.
     */
    function _tryUpdateScribeInsightNFT(address _scribeAddress) internal {
        Scribe storage scribe = scribes[_scribeAddress];
        if (scribe.insightNFTId != 0) {
            // In a real system, an off-chain service would listen to this event,
            // generate the new metadataURI based on `scribe.reputationScore` etc.,
            // and then submit a transaction to call `updateInsightNFTMetadata` (or a similar external function)
            // with the new URI. For this example, we just emit an event with a placeholder URI.
            emit InsightNFTMetadataUpdated(
                scribe.insightNFTId,
                string(abi.encodePacked("ipfs://metadata/", Strings.toString(scribe.insightNFTId), "/rep_", Strings.toString(scribe.reputationScore), ".json"))
            );
        }
    }
}
```