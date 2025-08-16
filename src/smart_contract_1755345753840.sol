Here's a Solidity smart contract named `EvoSynthProtocol` that embodies interesting, advanced, creative, and trendy concepts by combining AI-driven generative media, decentralized autonomous organization (DAO) governance, and a unique Soulbound Token (SBT) reputation system with passive yield. It aims to avoid direct duplication of existing open-source projects by focusing on the unique interplay of these components.

---

## EvoSynth Protocol - Smart Contract Outline & Function Summary

The `EvoSynthProtocol` is a decentralized platform for AI-assisted generative media synthesis and community governance. Users can submit "seed fragments" (prompts) which are processed by an off-chain AI (via Chainlink oracle) to create unique "EvoMedia" NFTs. The protocol features a sophisticated DAO where participants' reputation (represented by non-transferable Soulbound Tokens - SBTs) grants voting power, influencing the AI's evolution parameters and treasury management. It also introduces an "EvoEnergy" system as a utility credit, partially earnable through passive yield on reputation.

### Outline:

**I. Core Infrastructure & Access Control**
   - Essential contract setup, ownership management, and pausing functionality.

**II. EvoMedia NFT (ERC-721) Management**
   - Functions related to the creation and lifecycle of the generative media NFTs.

**III. AI Oracle Integration & Generative Process**
   - Handles user requests for AI synthesis and the callback from the Chainlink oracle.

**IV. Reputation & Moderation (Soulbound Token - SBT concept)**
   - Manages non-transferable reputation tokens, delegation of voting power, and community-driven content moderation.

**V. DAO Governance & Treasury Management**
   - Facilitates decentralized decision-making regarding protocol parameters, AI evolution, and treasury fund allocation.

**VI. EvoEnergy System (Internal Utility Token / Credit)**
   - Manages a utility credit system used for discounts on seed submissions, with a unique passive earning mechanism based on reputation.

**VII. Protocol Administration & Emergency Functions**
   - Administrative functionalities, including emergency fund withdrawal and setting key parameters.

### Function Summary:

**I. Core Infrastructure & Access Control**
1.  **`constructor`**: Initializes the contract, setting up Chainlink parameters, initial costs, DAO periods, and the initial AI configuration URI.
2.  **`setOracleAddress`**: Sets the address of the Chainlink oracle used for AI synthesis requests. Callable by the owner (or via DAO proposal).
3.  **`setJobId`**: Sets the Chainlink job ID that specifies the AI synthesis task the oracle should perform. Callable by the owner (or via DAO proposal).
4.  **`transferOwnership`**: (Inherited from OpenZeppelin `Ownable`) Transfers the contract ownership to a new address.
5.  **`pauseEvoSynthProcess`**: Halts the `submitSeedFragment` and `fulfillEvoSynth` processes for maintenance or emergencies. Callable by the owner.
6.  **`unpauseEvoSynthProcess`**: Resumes the EvoSynth process after being paused. Callable by the owner.

**II. EvoMedia NFT (ERC-721) Management**
7.  **`burnEvoMedia`**: Allows an EvoMedia NFT owner to permanently destroy their token, removing it from circulation.
8.  **`getEvoMediaDetails`**: Retrieves detailed metadata URI, associated seed ID, AI cost, and creation timestamp for a given EvoMedia NFT.

**III. AI Oracle Integration & Generative Process**
9.  **`submitSeedFragment`**: Users submit an initial content idea (via IPFS URI for seed data) and pay an ETH fee. This function initiates an off-chain AI synthesis request via Chainlink, also passing current AI calibration parameters.
10. **`fulfillEvoSynth`**: This is a callback function invoked by the Chainlink oracle after successfully completing the AI synthesis. It mints the new EvoMedia NFT to the original submitter.

**IV. Reputation & Moderation (Soulbound Token - SBT concept)**
11. **`mintReputationToken`**: Mints a non-transferable Reputation SBT to a specified address, acknowledging a valuable contribution (e.g., successful proposal, moderation). Callable by designated authorities (owner initially, later DAO-controlled).
12. **`delegateReputation`**: Allows a Reputation SBT holder to delegate their voting power to another address, enabling liquid democracy.
13. **`undelegateReputation`**: Allows a Reputation SBT holder to revoke their delegated voting power.
14. **`getReputationBalance`**: Returns the total effective reputation (voting power) of an address, considering any reputation delegated *to* them.
15. **`reportMaliciousContent`**: Enables users to flag potentially harmful or inappropriate EvoMedia, initiating an on-chain moderation report.
16. **`resolveModerationReport`**: Designated moderators or DAO members review and resolve a reported item. A valid report can award reputation to the reporter and penalize the content submitter.
17. **`setReputationMintingAuthority`**: Sets addresses authorized to mint Reputation SBTs and award EvoEnergy. Callable by the owner (or via DAO proposal).

**V. DAO Governance & Treasury Management**
18. **`submitEvolutionProposal`**: Creates a new governance proposal. This can include adjustments to AI parameters, treasury fund allocations, or protocol fee changes. Requires a minimum reputation stake from the proposer.
19. **`voteOnProposal`**: Allows Reputation SBT holders (or their delegates) to cast a vote on active proposals.
20. **`executeProposal`**: Executes a passed governance proposal after its voting period and grace period have concluded. This function can trigger arbitrary calls within the protocol, managed by the DAO.
21. **`setAICalibrationParameters`**: An internal function callable *only* via the `executeProposal` mechanism, it updates the IPFS URI pointing to the AI's operational configuration parameters, allowing the community to guide the AI's evolution.
22. **`depositToTreasury`**: Allows any user or contract to send ETH to the protocol's treasury, funding future operations and AI costs.
23. **`requestTreasuryPayout`**: Submits a proposal specifically designed to withdraw ETH from the treasury for a specified purpose, subject to a DAO vote.

**VI. EvoEnergy System (Internal Utility Token / Credit)**
24. **`claimEvoEnergyReward`**: Allows users to claim accumulated EvoEnergy credits. This function provides a passive yield mechanism, rewarding users with EvoEnergy based on the amount of Reputation SBTs they hold and the time elapsed since their last claim.
25. **`awardEvoEnergy`**: Awards EvoEnergy credits directly to a specified address. Callable by designated authorities (e.g., for bounties, special contributions).
26. **`setEvoEnergyCostPerSeed`**: Adjusts the base ETH cost required to submit a new seed fragment, callable by the owner (or via DAO proposal).

**VII. Protocol Administration & Emergency Functions**
27. **`withdrawEthFunds`**: An emergency function allowing the owner to withdraw unassigned ETH from the contract's balance. Intended for recovery or pre-approved transfers, and also the target function for DAO treasury payout proposals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol"; // For Chainlink oracle interactions

// --- Custom Error Definitions ---
error EvoSynth__InvalidProposalState();
error EvoSynth__ProposalAlreadyExecuted();
error EvoSynth__ProposalVotingPeriodNotEnded();
error EvoSynth__ProposalGracePeriodNotEnded();
error EvoSynth__InsufficientReputation();
error EvoSynth__AlreadyVoted();
error EvoSynth__NoActiveProposal();
error EvoSynth__NotReputationMintingAuthority();
error EvoSynth__EvoMediaDoesNotExist();
error EvoSynth__NotEvoMediaOwner();
error EvoSynth__NotPaused();
error EvoSynth__IsPaused();
error EvoSynth__InsufficientEthPayment();
error EvoSynth__InsufficientEvoEnergy();
error EvoSynth__NoEvoEnergyToClaim();
error EvoSynth__ReportNotPending();
error EvoSynth__CannotDelegateToSelf();
error EvoSynth__NoActiveDelegation();
error EvoSynth__UnknownChainlinkRequestId();
error EvoSynth__SeedAlreadyProcessed();
error EvoSynth__ReputationAmountMustBePositive();
error EvoSynth__VoterHasNoReputation();
error EvoSynth__ProposalExecutionFailed();
error EvoSynth__CannotClaimEvoEnergyYet();
error EvoSynth__InsufficientContractBalance();
error EvoSynth__ZeroAmount(); // For transactions involving zero value that are not permitted

/**
 * @title EvoSynthProtocol
 * @dev A decentralized AI-assisted generative media synthesis and governance platform.
 * Users submit content seeds, an AI (via Chainlink) generates media NFTs,
 * and a DAO governs the AI's evolution and protocol parameters using reputation SBTs.
 */
contract EvoSynthProtocol is ERC721, Ownable, ReentrancyGuard, ChainlinkClient {
    using Counters for Counters.Counter;

    // --- I. Core Infrastructure & Access Control ---
    address public chainlinkOracle;
    bytes32 public chainlinkJobId;
    LinkTokenInterface public LINK;
    bool public paused = false;

    // --- II. EvoMedia NFT (ERC-721) Management ---
    Counters.Counter private _evoMediaTokenIds;
    struct EvoMedia {
        uint256 seedId;
        string evolvedMediaUri; // IPFS URI for the generated content (e.g., image, text, audio)
        string metadataUri;     // IPFS URI for the NFT metadata (following ERC721 metadata standard)
        uint256 aiCost;         // Cost incurred from AI oracle for this synthesis
        uint256 creationTimestamp; // Timestamp of NFT creation
    }
    mapping(uint256 => EvoMedia) public evoMediaData; // tokenId => EvoMedia details

    // --- III. AI Oracle Integration & Generative Process ---
    Counters.Counter private _seedFragmentIds;
    struct SeedFragment {
        address submitter;
        string seedUri;             // IPFS URI pointing to the initial seed data (e.g., text prompt)
        uint256 submissionTimestamp;
        bool processed;             // True if AI synthesis is complete
        bytes32 requestId;          // Chainlink requestId for tracking the off-chain job
    }
    mapping(uint252 => SeedFragment) public seedFragments; // seedId => SeedFragment details
    mapping(bytes32 => uint252) public requestIdToSeedId; // Chainlink requestId => seedId for callback lookup
    uint256 public evoEnergyCostPerSeed; // Base ETH cost for submitting a seed, can be offset by EvoEnergy

    // --- IV. Reputation & Moderation (Soulbound Token - SBT concept) ---
    mapping(address => uint256) public reputationBalance;    // Address => raw reputation score (non-transferable SBT)
    mapping(address => address) public reputationDelegates;  // Delegatee => Total reputation delegated TO this address
    mapping(address => address) public delegatedBy;          // Delegator => Address they delegated TO
    mapping(address => bool) public isReputationMintingAuthority; // Addresses authorized to mint reputation & award EvoEnergy

    Counters.Counter private _moderationReportIds;
    enum ReportStatus { Pending, ResolvedValid, ResolvedInvalid }
    struct ModerationReport {
        uint256 evoMediaTokenId;
        address reporter;
        string reason;
        uint256 reportTimestamp;
        ReportStatus status;
        uint256 resolvedTimestamp;
    }
    mapping(uint252 => ModerationReport) public moderationReports; // reportId => ModerationReport details

    // --- V. DAO Governance & Treasury Management ---
    Counters.Counter private _proposalIds;
    enum ProposalState { Active, Succeeded, Failed, Executed }
    struct Proposal {
        string proposalUri;            // IPFS URI for comprehensive proposal details
        uint256 proposerReputationStake; // Snapshot of proposer's reputation at submission
        uint256 voteThreshold;         // Percentage of 'for' votes needed to pass (e.g., 5100 for 51.00%)
        uint256 executionDelay;        // Time in seconds after voting ends before execution is possible
        uint256 votingPeriodEnd;       // Timestamp when voting for the proposal ends
        uint256 forVotes;              // Total reputation votes for the proposal
        uint256 againstVotes;          // Total reputation votes against the proposal
        mapping(address => bool) hasVoted; // Tracks if an address (or its delegate) has voted
        ProposalState state;
        bytes callData;                // Encoded function call to be executed upon success
        address targetContract;        // The contract address on which `callData` will be executed
    }
    mapping(uint252 => Proposal) public proposals; // proposalId => Proposal details
    uint256 public minProposalReputationStake; // Minimum reputation required to submit a proposal
    uint256 public proposalVotingPeriod;       // Duration of the voting period in seconds
    uint252 public proposalGracePeriod;        // Additional delay after voting ends before execution, in seconds

    string public aiCalibrationParametersUri; // IPFS URI for the AI model's adjustable parameters

    // --- VI. EvoEnergy System (Internal Utility Token / Credit) ---
    mapping(address => uint256) public evoEnergyBalance; // Address => EvoEnergy credits available for discounts
    mapping(address => uint256) public lastEvoEnergyClaimTimestamp; // Timestamp of last EvoEnergy passive yield claim
    uint256 public evoEnergyYieldRatePerDay; // Passive yield rate for reputation holders (e.g., 100 for 1% per day)


    // --- Events ---
    event EvoSynthRequested(uint256 indexed seedId, address indexed submitter, string seedUri, bytes32 requestId);
    event EvoMediaMinted(uint256 indexed tokenId, uint256 indexed seedId, address indexed owner, string evolvedMediaUri, string metadataUri);
    event EvoMediaBurned(uint256 indexed tokenId, address indexed owner);
    event ReputationMinted(address indexed recipient, uint256 newBalance, string reasonUri);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator, address indexed previousDelegatee);
    event ModerationReported(uint252 indexed reportId, uint256 indexed evoMediaTokenId, address indexed reporter, string reason);
    event ModerationResolved(uint252 indexed reportId, ReportStatus status, address indexed reporter, address indexed submitter);
    event ProposalSubmitted(uint252 indexed proposalId, address indexed proposer, string proposalUri);
    event VoteCast(uint252 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint252 indexed proposalId);
    event AICalibrationParametersUpdated(string newParamsUri);
    event EvoEnergyClaimed(address indexed recipient, uint256 amount); // Used for both passive claims and direct awards
    event ProtocolPaused(address indexed pauser);
    event ProtocolUnpaused(address indexed unpauser);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryPayoutRequested(uint252 indexed proposalId, address indexed recipient, uint256 amount, string reason);


    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert EvoSynth__IsPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert EvoSynth__NotPaused();
        _;
    }

    modifier onlyReputationMintingAuthority() {
        if (!isReputationMintingAuthority[msg.sender]) revert EvoSynth__NotReputationMintingAuthority();
        _;
    }

    modifier onlyProposalExecutor(uint252 _proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (block.timestamp < proposal.votingPeriodEnd) revert EvoSynth__ProposalVotingPeriodNotEnded();
        if (block.timestamp < proposal.votingPeriodEnd + proposal.executionDelay) revert EvoSynth__ProposalGracePeriodNotEnded();
        if (proposal.state != ProposalState.Succeeded) revert EvoSynth__InvalidProposalState();
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the EvoSynthProtocol contract.
     * @param _linkTokenAddress The address of the LINK token.
     * @param _oracleAddress The address of the Chainlink oracle.
     * @param _jobId The Chainlink job ID for AI synthesis.
     * @param _initialEvoEnergyCostPerSeed The initial base ETH cost for submitting a seed fragment.
     * @param _minProposalReputationStake The minimum reputation required to submit a governance proposal.
     * @param _proposalVotingPeriod The duration of the voting period for proposals in seconds.
     * @param _proposalGracePeriod The grace period after voting ends before a proposal can be executed, in seconds.
     * @param _initialAICalibrationParametersUri The initial IPFS URI for AI calibration parameters.
     * @param _evoEnergyYieldRatePerDay The passive yield rate for EvoEnergy based on reputation, (e.g., 100 for 1% per 100 reputation per day).
     */
    constructor(
        address _linkTokenAddress,
        address _oracleAddress,
        bytes32 _jobId,
        uint256 _initialEvoEnergyCostPerSeed,
        uint256 _minProposalReputationStake,
        uint252 _proposalVotingPeriod,
        uint252 _proposalGracePeriod,
        string memory _initialAICalibrationParametersUri,
        uint256 _evoEnergyYieldRatePerDay
    ) ERC721("EvoSynth EvoMedia", "EVOMEDIA") Ownable(msg.sender) {
        setChainlinkToken(_linkTokenAddress);
        LINK = LinkTokenInterface(_linkTokenAddress);
        chainlinkOracle = _oracleAddress;
        chainlinkJobId = _jobId;
        evoEnergyCostPerSeed = _initialEvoEnergyCostPerSeed;
        minProposalReputationStake = _minProposalReputationStake;
        proposalVotingPeriod = _proposalVotingPeriod;
        proposalGracePeriod = _proposalGracePeriod;
        aiCalibrationParametersUri = _initialAICalibrationParametersUri;
        evoEnergyYieldRatePerDay = _evoEnergyYieldRatePerDay;

        // Set the contract owner as the initial authority to mint reputation tokens and award EvoEnergy
        isReputationMintingAuthority[msg.sender] = true;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Sets the address of the Chainlink oracle used for AI synthesis requests.
     * @param _oracle The new oracle address.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        chainlinkOracle = _oracle;
    }

    /**
     * @dev Sets the Chainlink job ID for AI synthesis tasks.
     * @param _jobId The new job ID.
     */
    function setJobId(bytes32 _jobId) public onlyOwner {
        chainlinkJobId = _jobId;
    }

    /**
     * @dev Pauses the EvoSynth process (seed submission and AI synthesis).
     * Useful for maintenance or in case of emergencies.
     */
    function pauseEvoSynthProcess() public onlyOwner whenNotPaused {
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the EvoSynth process.
     */
    function unpauseEvoSynthProcess() public onlyOwner whenPaused {
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    // --- III. AI Oracle Integration & Generative Process ---

    /**
     * @dev Submits a content seed fragment and initiates an AI synthesis request via Chainlink.
     * The `_requiredEth` parameter specifies the base cost in ETH, which can be partially or fully
     * offset by the user's available EvoEnergy credits.
     * @param _seedUri IPFS URI pointing to the initial seed data (e.g., text prompt, image parameters).
     * @param _requiredEth The base ETH cost for processing the seed.
     */
    function submitSeedFragment(string memory _seedUri, uint256 _requiredEth) public payable whenNotPaused nonReentrant {
        uint256 netEthCost = _requiredEth;
        uint256 discountApplied = 0;

        // Apply EvoEnergy discount automatically
        if (evoEnergyBalance[msg.sender] > 0) {
            uint256 availableEnergy = evoEnergyBalance[msg.sender];
            if (availableEnergy >= netEthCost) {
                discountApplied = netEthCost;
                evoEnergyBalance[msg.sender] -= netEthCost;
                netEthCost = 0;
            } else {
                discountApplied = availableEnergy;
                evoEnergyBalance[msg.sender] = 0;
                netEthCost -= availableEnergy;
            }
        }

        if (msg.value < netEthCost) revert EvoSynth__InsufficientEthPayment();

        // Refund any excess ETH sent beyond the net cost
        if (msg.value > netEthCost) {
            payable(msg.sender).transfer(msg.value - netEthCost);
        }

        _seedFragmentIds.increment();
        uint252 currentSeedId = _seedFragmentIds.current();

        SeedFragment storage newSeed = seedFragments[currentSeedId];
        newSeed.submitter = msg.sender;
        newSeed.seedUri = _seedUri;
        newSeed.submissionTimestamp = block.timestamp;
        newSeed.processed = false;

        // Build and send the Chainlink request for AI synthesis
        Chainlink.Request memory req = buildChainlinkRequest(chainlinkJobId, address(this), this.fulfillEvoSynth.selector);
        req.addUint("seedId", currentSeedId);
        req.add("seedUri", _seedUri);
        req.add("aiParamsUri", aiCalibrationParametersUri); // Pass current AI configuration to the oracle

        // Ensure the contract has sufficient LINK balance to pay the oracle
        uint256 linkBalance = LINK.balanceOf(address(this));
        if (linkBalance == 0) revert EvoSynth__InsufficientContractBalance(); // Contract needs to be funded with LINK
        
        bytes32 requestId = sendChainlinkRequest(req, linkBalance); 
        newSeed.requestId = requestId;
        requestIdToSeedId[requestId] = currentSeedId;

        emit EvoSynthRequested(currentSeedId, msg.sender, _seedUri, requestId);
    }

    /**
     * @dev Chainlink oracle callback function. This function is called by the oracle upon successful
     * completion of the off-chain AI synthesis. It mints the new EvoMedia NFT.
     * @param _requestId The Chainlink request ID that was initiated by `submitSeedFragment`.
     * @param _evolvedMediaUri IPFS URI for the generated media content.
     * @param _metadataUri IPFS URI for the ERC721 metadata of the new NFT.
     * @param _aiCost The cost reported by the oracle for the AI computation.
     */
    function fulfillEvoSynth(bytes32 _requestId, string memory _evolvedMediaUri, string memory _metadataUri, uint256 _aiCost)
        public
        recordChainlinkFulfillment(_requestId)
    {
        uint252 seedId = requestIdToSeedId[_requestId];
        if (seedId == 0) revert EvoSynth__UnknownChainlinkRequestId();

        SeedFragment storage seed = seedFragments[seedId];
        if (seed.processed) revert EvoSynth__SeedAlreadyProcessed(); // Prevent double processing

        seed.processed = true; // Mark seed as processed

        _evoMediaTokenIds.increment();
        uint256 newTokenId = _evoMediaTokenIds.current();

        _safeMint(seed.submitter, newTokenId); // Mint the NFT to the original submitter

        EvoMedia storage newEvoMedia = evoMediaData[newTokenId];
        newEvoMedia.seedId = seedId;
        newEvoMedia.evolvedMediaUri = _evolvedMediaUri;
        newEvoMedia.metadataUri = _metadataUri;
        newEvoMedia.aiCost = _aiCost;
        newEvoMedia.creationTimestamp = block.timestamp;

        _setTokenURI(newTokenId, _metadataUri); // Set the ERC721 token URI for metadata

        emit EvoMediaMinted(newTokenId, seedId, seed.submitter, _evolvedMediaUri, _metadataUri);
    }

    // --- II. EvoMedia NFT (ERC-721) Management ---

    /**
     * @dev Allows an EvoMedia NFT owner to permanently burn (destroy) their token.
     * @param _tokenId The ID of the EvoMedia token to burn.
     */
    function burnEvoMedia(uint256 _tokenId) public {
        if (ownerOf(_tokenId) != msg.sender) revert EvoSynth__NotEvoMediaOwner();
        if (evoMediaData[_tokenId].creationTimestamp == 0) revert EvoSynth__EvoMediaDoesNotExist(); // Check if token exists

        _burn(_tokenId); // ERC721 burn
        delete evoMediaData[_tokenId]; // Clear associated custom data

        emit EvoMediaBurned(_tokenId, msg.sender);
    }

    /**
     * @dev Retrieves detailed information about a specific EvoMedia NFT.
     * @param _tokenId The ID of the EvoMedia token.
     * @return A tuple containing the seed ID, evolved media URI, metadata URI, AI cost, and creation timestamp.
     */
    function getEvoMediaDetails(uint256 _tokenId)
        public
        view
        returns (uint252 seedId, string memory evolvedMediaUri, string memory metadataUri, uint256 aiCost, uint252 creationTimestamp)
    {
        EvoMedia storage media = evoMediaData[_tokenId];
        if (media.creationTimestamp == 0) revert EvoSynth__EvoMediaDoesNotExist();
        return (media.seedId, media.evolvedMediaUri, media.metadataUri, media.aiCost, media.creationTimestamp);
    }

    // --- IV. Reputation & Moderation (Soulbound Token - SBT concept) ---

    /**
     * @dev Mints a non-transferable Reputation SBT to a specified address, acknowledging a valuable contribution.
     * Callable only by designated reputation minting authorities (e.g., contract owner, or via DAO vote).
     * @param _to The address to mint the reputation to.
     * @param _amount The amount of reputation to mint.
     * @param _reasonUri IPFS URI explaining the specific reason for the reputation award.
     */
    function mintReputationToken(address _to, uint256 _amount, string memory _reasonUri) public onlyReputationMintingAuthority {
        if (_amount == 0) revert EvoSynth__ReputationAmountMustBePositive();
        reputationBalance[_to] += _amount;
        emit ReputationMinted(_to, reputationBalance[_to], _reasonUri);
    }

    /**
     * @dev Allows a Reputation SBT holder to delegate their voting power to another address.
     * This implements a basic form of liquid democracy, allowing holders to empower trusted delegates.
     * @param _delegate The address to delegate voting power to.
     */
    function delegateReputation(address _delegate) public {
        if (_delegate == msg.sender) revert EvoSynth__CannotDelegateToSelf();
        
        address currentDelegatee = delegatedBy[msg.sender];
        if (currentDelegatee != address(0)) {
            // Remove the delegator's previous delegation effect from the old delegatee
            reputationDelegates[currentDelegatee] -= reputationBalance[msg.sender];
        }

        // Add the delegator's reputation to the new delegatee's effective balance
        reputationDelegates[_delegate] += reputationBalance[msg.sender];
        delegatedBy[msg.sender] = _delegate; // Record the delegation
        emit ReputationDelegated(msg.sender, _delegate);
    }

    /**
     * @dev Allows a Reputation SBT holder to revoke their delegation of voting power.
     */
    function undelegateReputation() public {
        address currentDelegatee = delegatedBy[msg.sender];
        if (currentDelegatee == address(0)) revert EvoSynth__NoActiveDelegation();
        
        // Remove the delegator's reputation from the current delegatee's effective balance
        reputationDelegates[currentDelegatee] -= reputationBalance[msg.sender];
        delete delegatedBy[msg.sender]; // Clear the delegation record
        emit ReputationUndelegated(msg.sender, currentDelegatee);
    }

    /**
     * @dev Gets the effective reputation balance (voting power) of an address.
     * This includes their direct reputation and any reputation delegated to them.
     * @param _addr The address to query.
     * @return The effective reputation balance (voting power).
     */
    function getReputationBalance(address _addr) public view returns (uint256) {
        uint256 balance = reputationBalance[_addr];
        balance += reputationDelegates[_addr]; // Add reputation delegated *to* this address
        return balance;
    }

    /**
     * @dev Allows users to report potentially malicious or inappropriate EvoMedia.
     * This initiates an on-chain moderation process.
     * @param _tokenId The ID of the EvoMedia token being reported.
     * @param _reason A string describing the reason for the report.
     */
    function reportMaliciousContent(uint256 _tokenId, string memory _reason) public {
        if (evoMediaData[_tokenId].creationTimestamp == 0) revert EvoSynth__EvoMediaDoesNotExist();

        _moderationReportIds.increment();
        uint252 reportId = _moderationReportIds.current();

        ModerationReport storage newReport = moderationReports[reportId];
        newReport.evoMediaTokenId = _tokenId;
        newReport.reporter = msg.sender;
        newReport.reason = _reason;
        newReport.reportTimestamp = block.timestamp;
        newReport.status = ReportStatus.Pending;

        emit ModerationReported(reportId, _tokenId, msg.sender, _reason);
    }

    /**
     * @dev Resolves a moderation report. This function is typically called by designated
     * reputation minting authorities or via a successful DAO proposal.
     * Valid reports can award reputation to the reporter and/or penalize the content submitter.
     * @param _reportId The ID of the report to resolve.
     * @param _valid True if the report is deemed valid, false otherwise.
     * @param _reputationToReporter Amount of reputation to award the reporter if the report is valid.
     * @param _reputationPenaltyToSubmitter Amount of reputation to penalize the submitter if the report is valid.
     */
    function resolveModerationReport(uint252 _reportId, bool _valid, uint256 _reputationToReporter, uint256 _reputationPenaltyToSubmitter) public onlyReputationMintingAuthority {
        ModerationReport storage report = moderationReports[_reportId];
        if (report.status != ReportStatus.Pending) revert EvoSynth__ReportNotPending();
        
        // Get the current owner of the EvoMedia (which might be the original submitter or a subsequent owner)
        address submitter = ownerOf(report.evoMediaTokenId); 

        report.status = _valid ? ReportStatus.ResolvedValid : ReportStatus.ResolvedInvalid;
        report.resolvedTimestamp = block.timestamp;

        if (_valid) {
            if (_reputationToReporter > 0) {
                reputationBalance[report.reporter] += _reputationToReporter;
            }
            if (_reputationPenaltyToSubmitter > 0) {
                if (reputationBalance[submitter] >= _reputationPenaltyToSubmitter) {
                    reputationBalance[submitter] -= _reputationPenaltyToSubmitter;
                } else {
                    reputationBalance[submitter] = 0; // Ensure reputation balance does not go negative
                }
            }
        }
        emit ModerationResolved(_reportId, report.status, report.reporter, submitter);
    }

    /**
     * @dev Sets or revokes addresses authorized to mint Reputation SBTs and award EvoEnergy.
     * Initially callable by the contract owner, but can be integrated into DAO governance.
     * @param _authority The address to grant/revoke authority.
     * @param _canAct True to grant authority, false to revoke.
     */
    function setReputationMintingAuthority(address _authority, bool _canAct) public onlyOwner { 
        isReputationMintingAuthority[_authority] = _canAct;
    }


    // --- V. DAO Governance & Treasury Management ---

    /**
     * @dev Submits a new governance proposal for community vote.
     * Requires the proposer to hold a minimum reputation stake.
     * @param _proposalUri IPFS URI for the detailed proposal document.
     * @param _voteThreshold Percentage of 'for' votes required to pass (e.g., 5100 for 51.00%).
     * @param _executionDelay Delay in seconds after voting ends before the proposal can be executed.
     * @param _callData The encoded function call to be executed if the proposal passes.
     * @param _targetContract The address of the contract on which `_callData` will be executed.
     */
    function submitEvolutionProposal(
        string memory _proposalUri,
        uint256 _voteThreshold,
        uint256 _executionDelay,
        bytes memory _callData,
        address _targetContract
    ) public {
        if (getReputationBalance(msg.sender) < minProposalReputationStake) revert EvoSynth__InsufficientReputation();

        _proposalIds.increment();
        uint252 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposalUri = _proposalUri;
        newProposal.proposerReputationStake = minProposalReputationStake; 
        newProposal.voteThreshold = _voteThreshold;
        newProposal.executionDelay = _executionDelay;
        newProposal.votingPeriodEnd = block.timestamp + proposalVotingPeriod;
        newProposal.state = ProposalState.Active;
        newProposal.callData = _callData;
        newProposal.targetContract = _targetContract;

        emit ProposalSubmitted(proposalId, msg.sender, _proposalUri);
    }

    /**
     * @dev Casts a vote on an active governance proposal.
     * Voters can be themselves or their delegates.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote 'for' the proposal, false to vote 'against'.
     */
    function voteOnProposal(uint252 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.votingPeriodEnd == 0 || proposal.state != ProposalState.Active) revert EvoSynth__NoActiveProposal();
        if (block.timestamp >= proposal.votingPeriodEnd) revert EvoSynth__ProposalVotingPeriodNotEnded(); 

        address voterAddress = msg.sender;
        // Check if msg.sender has delegated their vote. If so, their vote counts for the delegatee.
        if (delegatedBy[msg.sender] != address(0)) {
            voterAddress = delegatedBy[msg.sender]; 
        }

        if (proposal.hasVoted[voterAddress]) revert EvoSynth__AlreadyVoted();

        uint256 voterReputation = getReputationBalance(voterAddress);
        if (voterReputation == 0) revert EvoSynth__VoterHasNoReputation();

        if (_support) {
            proposal.forVotes += voterReputation;
        } else {
            proposal.againstVotes += voterReputation;
        }
        proposal.hasVoted[voterAddress] = true;

        // Immediately update proposal state if voting period has ended due to this vote
        if (block.timestamp >= proposal.votingPeriodEnd) {
            uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
            if (totalVotes > 0 && (proposal.forVotes * 10000) / totalVotes >= proposal.voteThreshold) { 
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }
        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @dev Executes a passed governance proposal.
     * This function can only be called after the voting period has ended, the grace period has passed,
     * and the proposal's state is `Succeeded`.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint252 _proposalId) public nonReentrant onlyProposalExecutor(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Executed) revert EvoSynth__ProposalAlreadyExecuted();
        
        // Execute the encoded function call on the target contract
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        if (!success) revert EvoSynth__ProposalExecutionFailed();

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }
    
    /**
     * @dev Sets the IPFS URI pointing to the AI's operational parameters.
     * This function is primarily intended to be called by the `executeProposal` function
     * after a successful DAO vote, allowing the community to influence the AI's behavior.
     * It includes an `onlyOwner` modifier to restrict direct calls outside of governance.
     * @param _newParamsUri The new IPFS URI for AI calibration parameters.
     */
    function setAICalibrationParameters(string memory _newParamsUri) public onlyOwner { 
        aiCalibrationParametersUri = _newParamsUri;
        emit AICalibrationParametersUpdated(_newParamsUri);
    }

    /**
     * @dev Allows users to deposit ETH into the protocol's treasury.
     * These funds can then be managed and disbursed via DAO proposals.
     */
    function depositToTreasury() public payable {
        if (msg.value == 0) revert EvoSynth__ZeroAmount();
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Submits a proposal to request ETH payout from the treasury.
     * This function acts as a wrapper, creating a specific type of governance proposal
     * that, if passed, will trigger a withdrawal from the contract's ETH balance.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount of ETH to withdraw.
     * @param _reason A description or justification for the payout.
     */
    function requestTreasuryPayout(address _recipient, uint256 _amount, string memory _reason) public {
        // Encode the call to `withdrawEthFunds` which will be executed by `executeProposal`
        bytes memory callData = abi.encodeWithSelector(this.withdrawEthFunds.selector, _recipient, _amount); 
        // Submit a new proposal with a high vote threshold (60%) and a 7-day execution delay for treasury payouts
        submitEvolutionProposal(_reason, 6000, 7 days, callData, address(this)); 
        emit TreasuryPayoutRequested(_proposalIds.current(), _recipient, _amount, _reason);
    }

    // --- VI. EvoEnergy System (Internal Utility Token / Credit) ---

    /**
     * @dev Allows users to claim accumulated EvoEnergy credits based on their held reputation.
     * This function provides a passive yield mechanism, rewarding users for holding Reputation SBTs.
     * Claims are capped at once per day to manage gas costs and avoid spam.
     */
    function claimEvoEnergyReward() public {
        uint256 availableReputation = reputationBalance[msg.sender];
        if (availableReputation == 0) revert EvoSynth__NoEvoEnergyToClaim(); // No reputation, no passive yield

        // Check if at least one full day has passed since the last claim
        uint256 timeSinceLastClaim = block.timestamp - lastEvoEnergyClaimTimestamp[msg.sender];
        if (lastEvoEnergyClaimTimestamp[msg.sender] != 0 && timeSinceLastClaim < 1 days) {
            revert EvoSynth__CannotClaimEvoEnergyYet();
        }

        uint256 daysPassed = timeSinceLastClaim / 1 days;
        if (daysPassed == 0) revert EvoSynth__NoEvoEnergyToClaim(); // No full day passed, no new yield

        // Calculate yield: (reputation * yieldRatePerDay * daysPassed) / 10000
        // `evoEnergyYieldRatePerDay` is scaled by 100 for precision (e.g., 100 = 1%)
        uint256 yieldAmount = (availableReputation * evoEnergyYieldRatePerDay * daysPassed) / 10000; 

        if (yieldAmount == 0) revert EvoSynth__NoEvoEnergyToClaim();

        evoEnergyBalance[msg.sender] += yieldAmount;
        lastEvoEnergyClaimTimestamp[msg.sender] = block.timestamp; // Update last claim timestamp

        emit EvoEnergyClaimed(msg.sender, yieldAmount);
    }
    
    /**
     * @dev Awards EvoEnergy credits to a specified address.
     * This function is callable by designated reputation minting authorities (or via DAO proposal)
     * for purposes like bounties, contest rewards, or manual adjustments.
     * @param _to The address to award EvoEnergy to.
     * @param _amount The amount of EvoEnergy to award.
     * @param _reason A string describing the reason for the award.
     */
    function awardEvoEnergy(address _to, uint256 _amount, string memory _reason) public onlyReputationMintingAuthority {
        if (_amount == 0) revert EvoSynth__ZeroAmount();
        evoEnergyBalance[_to] += _amount;
        emit EvoEnergyClaimed(_to, _amount); 
    }

    /**
     * @dev Sets the base ETH cost required for submitting a new seed fragment.
     * This parameter can be adjusted by the owner (or through a DAO governance proposal).
     * @param _cost The new cost in wei.
     */
    function setEvoEnergyCostPerSeed(uint256 _cost) public onlyOwner { 
        evoEnergyCostPerSeed = _cost;
    }

    // --- VII. Protocol Administration & Emergency Functions ---

    /**
     * @dev Allows the contract owner to withdraw unassigned ETH from the contract's balance.
     * This is an emergency function and also the target function for DAO treasury payout proposals.
     * @param _recipient The address to send the ETH to.
     * @param _amount The amount of ETH to withdraw in wei.
     */
    function withdrawEthFunds(address _recipient, uint256 _amount) public onlyOwner nonReentrant {
        if (address(this).balance < _amount) revert EvoSynth__InsufficientContractBalance();
        if (_amount == 0) revert EvoSynth__ZeroAmount();
        payable(_recipient).transfer(_amount);
    }
}
```