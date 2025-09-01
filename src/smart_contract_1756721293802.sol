This smart contract, "GenesisForge: Dynamic AI Co-Authored IP Protocol," envisions a decentralized ecosystem for managing intellectual property that is inherently dynamic, collaboratively governed, and deeply integrated with AI contributions. It moves beyond static NFTs by allowing digital assets to evolve, be fractionalized for community ownership, and establish on-chain licensing models, while also pioneering a conceptual framework for AI co-authorship and content origin verification.

---

**Contract Name:** GenesisForge: Dynamic AI Co-Authored IP Protocol

**Concept:** This contract establishes a decentralized protocol for managing "Dynamic AI Co-Authored Intellectual Property" (DAI-P). It allows for the creation of unique digital assets (IPs) which are represented as NFTs, but with advanced features:
1.  **Dynamic Metadata:** IPs can evolve over time through community proposals and voting, reflecting new versions or modifications.
2.  **Fractionalized Ownership:** IPs can be fractionalized into fungible "IP Shares" (ERC20 tokens) for distributed ownership and participatory governance.
3.  **AI Co-Authorship & Reputation:** Integrates a mechanism to recognize and track contributions from "AI agents," assigning them reputation scores that can grow over time.
4.  **On-Chain Licensing & Royalties:** Manages commercial licenses for IPs and distributes royalties to IP Share holders based on reported usage, employing a gas-efficient, pull-based distribution system.
5.  **Content Origin Prover (Simulated ZKP-like):** A conceptual framework for cryptographically proving the derivation or origin of content from a registered IP, simulating advanced cryptographic verification (like Zero-Knowledge Proofs).

---

### Outline and Function Summary

**I. Core IP Management (Dynamic NFT & Fractionalization)**
1.  `createInitialIPAsset(string calldata _initialMetadataURI)`: Mints a new unique IP (represented by an ID) with initial metadata. The creator is initially the sole owner.
2.  `updateIPMetadata(uint256 _ipId, string calldata _newMetadataURI)`: **(Internal)** Updates an IP's metadata, typically called after a successful evolution vote or by the creator for initial non-fractionalized IPs.
3.  `fractionalizeIP(uint256 _ipId, uint256 _totalShares, string calldata _shareName, string calldata _shareSymbol)`: Converts a full IP into fungible "IP Shares" by deploying a new ERC20 token contract. All shares are minted to the fractionalizer.
4.  `redeemIPFromShares(uint256 _ipId, address _to)`: Reconstitutes the full IP (transferring sole ownership) from all outstanding IP Shares. Requires the caller to hold all shares, which are then effectively burned.
5.  `transferIPShare(uint256 _ipId, address _to, uint256 _amount)`: Transfers a specified amount of IP Shares for a given IP. Automatically updates the sender's royalty claim point.
6.  `approveIPShare(uint256 _ipId, address _spender, uint256 _amount)`: Approves a spender to transfer IP Shares on behalf of the owner.
7.  `balanceOfIPShare(uint256 _ipId, address _account)`: Returns the IP Share balance of an account for a specific IP. Handles both fractionalized and non-fractionalized states.

**II. IP Evolution & Governance**
8.  `proposeIPEvolution(uint256 _ipId, string calldata _newMetadataURI, uint256 _votingDurationSeconds)`: Allows IP Share holders to submit a proposal for evolving an IP (e.g., a new version, modification).
9.  `voteOnIPEvolution(uint256 _ipId, uint256 _proposalId, bool _for)`: IP Share holders cast votes on active evolution proposals based on their share holdings.
10. `executeIPEvolution(uint256 _ipId, uint256 _proposalId)`: Executes a successful proposal (after the voting period ends), updating the IP's metadata.
11. `depositAIContribution(uint256 _ipId, uint256 _proposalId, bytes32 _contributionHash, address _aiAgentAddress)`: Simulates an AI agent contributing to an evolution proposal, leading to reputation gain for the AI.

**III. Licensing & Royalties**
12. `setLicenseTerms(uint256 _ipId, string calldata _licenseType, uint256 _feePerUnit, address _currency, uint256 _validityDurationSeconds)`: IP owners/governance define specific licensing terms (e.g., commercial, non-commercial) for an IP.
13. `requestIPLicense(uint256 _ipId, string calldata _licenseType, uint256 _units)`: Users formally request a license for a specific IP, specifying desired usage units.
14. `grantIPLicense(uint256 _ipId, uint256 _requestId)`: Approves a license request, handling payment of associated fees (ETH or ERC20). ETH payments contribute to the IP's royalty pool.
15. `reportIPUsage(uint256 _licenseId, uint256 _unitsUsed, uint256 _additionalFee)`: An authorized oracle reports commercial usage of a licensed IP, and any associated `_additionalFee` (in ETH) is added to the IP's royalty pool.
16. `distributeRoyalties(uint256 _ipId)`: Triggers an update of the `cumulativeRoyaltyPerShare` for an IP, making new revenue claimable by shareholders. Callable by anyone.
17. `withdrawRoyalties(uint256 _ipId)`: Allows IP Share holders to withdraw their proportional share of accumulated earnings (in ETH) from the IP's royalty pool.
18. `getClaimableRoyalties(uint256 _ipId, address _user)`: Calculates the amount of royalties (in ETH) a specific user can claim at the current time.

**IV. AI Agent Reputation & "Content Origin Prover" (Advanced Concepts)**
19. `registerAIContributor(address _aiAgentAddress, string calldata _name)`: The contract owner registers an external AI agent for reputation tracking within the protocol.
20. `getAIContributionReputation(address _aiAgentAddress)`: Returns the current reputation score of a registered AI agent.
21. `submitContentOriginProof(uint256 _ipId, bytes32[] calldata _derivationHashes, bytes32 _finalContentHash)`: A user submits a proof (a sequence of hashes) demonstrating content derivation from a registered IP. This simulates a Zero-Knowledge Proof (ZKP) verification.
22. `challengeContentOriginProof(uint256 _ipId, address _prover, bytes32 _finalContentHash)`: Allows others to challenge a submitted content origin proof, triggering a dispute flag.

**V. Administrative / Utility**
23. `setOracleAddress(address _newOracleAddress)`: Admin function to update the address of the trusted oracle responsible for reporting IP usage.
24. `pauseContract()`: Emergency function (callable by owner) to pause critical contract operations (e.g., IP creation, voting, licensing).
25. `unpauseContract()`: Unpauses the contract, allowing operations to resume.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom IP Share ERC20 contract for fractionalized ownership
contract IPShares is ERC20 {
    uint256 public immutable ipId;

    // The owner parameter here refers to the initial holder of all minted shares
    constructor(uint256 _ipId, string memory _name, string memory _symbol, uint256 _initialSupply, address _owner) ERC20(_name, _symbol) {
        require(_owner != address(0), "IPShares: Owner address cannot be zero");
        ipId = _ipId;
        _mint(_owner, _initialSupply); // Mint all initial shares to the specified _owner
    }
    
    // Minimal ERC20 implementation, more advanced features (like hooks for pausing)
    // would be added if direct control from GenesisForge was required for these tokens.
}

contract GenesisForge is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Provides overflow/underflow protection for arithmetic operations

    // --- State Variables ---

    Counters.Counter private _ipIds; // Counter for unique IP asset IDs
    Counters.Counter private _licenseRequestIds; // Counter for license request IDs
    Counters.Counter private _activeLicenseIds; // Counter for active license IDs

    // Scaling factor for royalty calculations to maintain precision (e.g., 10^18, similar to WAD in DeFi)
    uint256 private constant RAY = 1e18; 

    // Represents a unique Intellectual Property Asset
    struct IPAsset {
        uint256 id;
        address creator; // The original creator or the current sole owner if not fractionalized
        string currentMetadataURI; // URI pointing to the current (latest) metadata/content
        address ipShareTokenAddress; // Address of the deployed IPShares contract, address(0) if not fractionalized
        bool isActive; // True if the IP is active and can be used/governed

        uint256 totalRevenueEarned; // Total ETH collected for this IP, pending distribution
        uint256 cumulativeRoyaltyPerShare; // Accumulated royalty per share, scaled by RAY, reflecting total earnings distributed per share
        mapping(address => uint256) lastClaimedCumulativeRoyaltyPerShare; // User's last claim point, scaled by RAY, to track what they've already claimed
    }
    mapping(uint256 => IPAsset) public ipAssets; // ipId => IPAsset details

    // Represents a proposal for IP evolution
    struct EvolutionProposal {
        uint256 proposalId;
        uint256 ipId;
        address proposer;
        string newMetadataURI; // The proposed new metadata/content URI
        uint256 submissionTimestamp;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this specific proposal
        bool isExecuted; // True if the proposal has been executed
        bool isApproved; // True if the proposal passed the vote
    }
    mapping(uint256 => mapping(uint256 => EvolutionProposal)) public ipEvolutionProposals; // ipId => proposalId => Proposal details
    mapping(uint256 => Counters.Counter) private _ipProposalCounters; // Counters for proposals unique to each IP

    // Represents defined licensing terms for an IP
    struct LicenseTerms {
        string licenseType; // e.g., "Commercial-Tier1", "Non-Commercial", "Research"
        uint256 feePerUnit; // Fee for each unit of usage, in the specified currency
        address currency; // Address of ERC20 token for payment, or address(0) for ETH
        uint256 validityDurationSeconds; // How long the license is valid once granted
        bool isActive; // True if these license terms are currently active
    }
    mapping(uint256 => mapping(string => LicenseTerms)) public ipLicenseTerms; // ipId => licenseType string => LicenseTerms details

    // Represents a user's request for a license
    struct LicenseRequest {
        uint256 requestId;
        uint256 ipId;
        address requester;
        string licenseType; // The type of license requested
        uint256 requestedUnits; // Number of units requested
        uint256 requestTimestamp;
        bool isApproved; // True if the request has been approved
        uint256 activeLicenseId; // Points to the active license if approved (0 if not yet granted)
    }
    mapping(uint256 => LicenseRequest) public licenseRequests; // requestId => LicenseRequest details

    // Represents an active, granted license
    struct ActiveLicense {
        uint256 licenseId;
        uint256 ipId;
        address licensee;
        string licenseType;
        uint256 grantTimestamp;
        uint256 expirationTimestamp;
        uint256 unitsGranted; // Total units granted by this license
        uint256 unitsUsed; // Units reported as used by the oracle
        bool isActive; // True if the license is currently active
        uint256 totalPaid; // Total amount paid upfront for this license
    }
    mapping(uint256 => ActiveLicense) public activeLicenses; // licenseId => ActiveLicense details

    // AI Contributor Reputation tracking
    struct AIContributor {
        string name; // Human-readable name for the AI agent
        uint256 reputationScore; // Accumulated reputation score
        uint256 lastContributionTimestamp; // Timestamp of the last recorded contribution
        bool isRegistered; // True if the AI agent is registered
    }
    mapping(address => AIContributor) public aiContributors; // AI agent address => AIContributor details

    // Content Origin Proofs (Simplified simulation of ZKP verification)
    struct ContentOriginProof {
        uint256 ipId;
        address prover; // Address that submitted the proof
        bytes32[] derivationHashes; // Sequence of hashes representing the derivation path
        bytes32 finalContentHash; // Hash of the final derived content
        uint256 submissionTimestamp;
        bool isValid; // Result of the (simulated) verification
        bool isChallenged; // True if the proof has been challenged
    }
    mapping(uint256 => mapping(bytes32 => ContentOriginProof)) public contentOriginProofs; // ipId => finalContentHash => Proof details

    address public oracleAddress; // Address of the trusted oracle for usage reporting
    bool public paused; // Global pause flag for emergency situations

    // --- Events ---
    event IPAssetCreated(uint256 indexed ipId, address indexed creator, string initialMetadataURI);
    event IPMetadataUpdated(uint256 indexed ipId, string newMetadataURI);
    event IPFractionalized(uint256 indexed ipId, address indexed ipShareTokenAddress, uint256 totalShares);
    event IPRedeemed(uint256 indexed ipId, address indexed redeemer);
    event IPShareTransferred(uint256 indexed ipId, address indexed from, address indexed to, uint256 amount);

    event EvolutionProposalSubmitted(uint256 indexed ipId, uint256 indexed proposalId, address indexed proposer, string newMetadataURI);
    event VoteCast(uint256 indexed ipId, uint256 indexed proposalId, address indexed voter, bool _for);
    event EvolutionExecuted(uint256 indexed ipId, uint256 indexed proposalId, bool approved);
    event AIContributionDeposited(uint256 indexed ipId, uint256 indexed proposalId, address indexed aiAgent, bytes32 contributionHash);
    event AIContributorRegistered(address indexed aiAgentAddress, string name);

    event LicenseTermsSet(uint256 indexed ipId, string licenseType, uint256 feePerUnit, address currency);
    event LicenseRequested(uint256 indexed requestId, uint256 indexed ipId, address indexed requester, string licenseType, uint256 requestedUnits);
    event LicenseGranted(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 totalPaid);
    event IPUsageReported(uint256 indexed licenseId, uint256 unitsUsed, uint256 additionalRevenue);
    event RoyaltiesDistributed(uint256 indexed ipId, uint256 newRevenueAdded, uint256 cumulativeRoyaltyPerShare); // Triggered when cumulative royalty is updated
    event RoyaltiesWithdrawn(uint256 indexed ipId, address indexed receiver, uint256 amount);
    event ClaimableRoyaltiesCalculated(uint256 indexed ipId, address indexed user, uint256 claimableAmount);

    event ContentOriginProofSubmitted(uint256 indexed ipId, address indexed prover, bytes32 finalContentHash, bool isValid);
    event ContentOriginProofChallenged(uint256 indexed ipId, address indexed challenger, bytes32 finalContentHash);

    event OracleAddressUpdated(address indexed newOracleAddress);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "GenesisForge: Only oracle can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "GenesisForge: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "GenesisForge: Contract is not paused");
        _;
    }

    constructor(address _initialOracleAddress) Ownable(msg.sender) {
        require(_initialOracleAddress != address(0), "GenesisForge: Oracle address cannot be zero");
        oracleAddress = _initialOracleAddress;
        paused = false;
    }

    // --- I. Core IP Management ---

    /**
     * @notice Mints a new unique IP asset with initial metadata. The creator becomes the initial sole owner.
     * @param _initialMetadataURI URI pointing to the initial metadata/content of the IP.
     * @return The ID of the newly created IP asset.
     */
    function createInitialIPAsset(string calldata _initialMetadataURI) external whenNotPaused returns (uint256) {
        _ipIds.increment();
        uint256 newIpId = _ipIds.current();

        ipAssets[newIpId] = IPAsset({
            id: newIpId,
            creator: msg.sender, // Initial sole owner
            currentMetadataURI: _initialMetadataURI,
            ipShareTokenAddress: address(0), // Not yet fractionalized
            isActive: true,
            totalRevenueEarned: 0,
            cumulativeRoyaltyPerShare: 0
        });

        emit IPAssetCreated(newIpId, msg.sender, _initialMetadataURI);
        return newIpId;
    }

    /**
     * @notice Allows authorized entities (e.g., after an evolution vote or initial creator) to update an IP's metadata.
     * @dev This function is `internal` and primarily called by `executeIPEvolution` or directly by the creator if the IP is not fractionalized.
     * @param _ipId The ID of the IP to update.
     * @param _newMetadataURI The new URI pointing to the updated metadata/content.
     */
    function updateIPMetadata(uint256 _ipId, string calldata _newMetadataURI) internal whenNotPaused {
        require(ipAssets[_ipId].isActive, "GenesisForge: IP is not active");
        // Authority check: either the contract itself (e.g., after evolution) or the creator (if not fractionalized)
        require(msg.sender == ipAssets[_ipId].creator || address(this) == msg.sender, "GenesisForge: Unauthorized to update metadata");

        ipAssets[_ipId].currentMetadataURI = _newMetadataURI;
        emit IPMetadataUpdated(_ipId, _newMetadataURI);
    }

    /**
     * @notice Fractionalizes an IP asset into fungible "IP Shares" (ERC20 tokens).
     * @dev Deploys a new IPShares contract and mints all shares to the fractionalizer.
     *      Only the current sole owner (creator) can fractionalize an unfractionalized IP.
     * @param _ipId The ID of the IP to fractionalize.
     * @param _totalShares The total number of IP Shares to mint.
     * @param _shareName The name for the new ERC20 token.
     * @param _shareSymbol The symbol for the new ERC20 token.
     */
    function fractionalizeIP(uint256 _ipId, uint256 _totalShares, string calldata _shareName, string calldata _shareSymbol) external whenNotPaused nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");
        require(ip.ipShareTokenAddress == address(0), "GenesisForge: IP already fractionalized");
        require(ip.creator == msg.sender, "GenesisForge: Only the creator can fractionalize an un-fractionalized IP");
        require(_totalShares > 0, "GenesisForge: Total shares must be greater than zero");

        // Ensure all prior revenue is distributed and withdrawn before fractionalization
        require(getClaimableRoyalties(_ipId, msg.sender) == 0 && ip.totalRevenueEarned == 0, "GenesisForge: Withdraw existing royalties before fractionalizing.");

        // Deploy new IPShares contract and mint all shares to the fractionalizer (who is the creator here)
        IPShares newShares = new IPShares(_ipId, _shareName, _shareSymbol, _totalShares, msg.sender);
        ip.ipShareTokenAddress = address(newShares);

        // Reset cumulative royalty for the newly fractionalized IP
        ip.cumulativeRoyaltyPerShare = 0; 
        ip.lastClaimedCumulativeRoyaltyPerShare[msg.sender] = 0; // The creator starts fresh with these shares

        emit IPFractionalized(_ipId, address(newShares), _totalShares);
    }

    /**
     * @notice Reconstitutes the full IP asset from all outstanding IP Shares.
     * @dev Requires the caller to hold all IP Shares of the specified IP. All shares are effectively removed.
     * @param _ipId The ID of the IP to redeem.
     * @param _to The address to transfer the full IP ownership to.
     */
    function redeemIPFromShares(uint256 _ipId, address _to) external whenNotPaused nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");
        require(ip.ipShareTokenAddress != address(0), "GenesisForge: IP is not fractionalized");
        require(_to != address(0), "GenesisForge: Cannot redeem to zero address");

        IPShares ipShareContract = IPShares(ip.ipShareTokenAddress);
        uint256 currentTotalShares = ipShareContract.totalSupply();
        require(ipShareContract.balanceOf(msg.sender) == currentTotalShares, "GenesisForge: Must hold all shares to redeem");
        
        // Ensure all prior revenue is distributed and withdrawn by the redeemer
        require(getClaimableRoyalties(_ipId, msg.sender) == 0 && ip.totalRevenueEarned == 0, "GenesisForge: Withdraw existing royalties before redeeming IP.");

        // Transfer all shares to `address(this)` and then burn them from the contract.
        // This effectively removes them from circulation.
        ipShareContract.transferFrom(msg.sender, address(this), currentTotalShares);
        ipShareContract.burn(currentTotalShares); // Burn function from OpenZeppelin ERC20

        // Mark the IPShares contract address as no longer associated with this IP
        ip.ipShareTokenAddress = address(0);
        
        // Transfer full IP ownership to _to by making them the new `creator` (sole owner)
        ip.creator = _to; 
        ip.cumulativeRoyaltyPerShare = 0; // Reset cumulative royalty for the IP
        delete ip.lastClaimedCumulativeRoyaltyPerShare[msg.sender]; // Clear the redeemer's claim point
        
        emit IPRedeemed(_ipId, _to);
    }

    /**
     * @notice Transfers a specified amount of IP Shares for a given IP.
     * @dev This directly interacts with the deployed IPShares ERC20 contract.
     *      Crucially, it updates the sender's royalty claim point before transfer to prevent royalty loss.
     * @param _ipId The ID of the IP whose shares are being transferred.
     * @param _to The recipient address.
     * @param _amount The amount of shares to transfer.
     */
    function transferIPShare(uint256 _ipId, address _to, uint256 _amount) external whenNotPaused returns (bool) {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");
        require(ip.ipShareTokenAddress != address(0), "GenesisForge: IP is not fractionalized");
        require(_to != address(0), "GenesisForge: Transfer to zero address");

        // Calculate and implicitly "claim" any pending royalties for the sender BEFORE transferring shares.
        // This updates their `lastClaimedCumulativeRoyaltyPerShare` to the current `cumulativeRoyaltyPerShare`.
        // Funds are only withdrawn explicitly via `withdrawRoyalties`.
        _updateLastClaimedCumulativeRoyaltyPerShare(_ipId, msg.sender);
        
        IPShares ipShareContract = IPShares(ip.ipShareTokenAddress);
        require(ipShareContract.transfer(_to, _amount), "GenesisForge: IP Share transfer failed");

        emit IPShareTransferred(_ipId, msg.sender, _to, _amount);
        return true;
    }

    /**
     * @notice Approves a spender to transfer IP Shares on behalf of the owner.
     * @dev This directly interacts with the deployed IPShares ERC20 contract.
     * @param _ipId The ID of the IP whose shares are being approved.
     * @param _spender The address to approve.
     * @param _amount The amount of shares to approve.
     */
    function approveIPShare(uint256 _ipId, address _spender, uint256 _amount) external whenNotPaused returns (bool) {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");
        require(ip.ipShareTokenAddress != address(0), "GenesisForge: IP is not fractionalized");

        IPShares ipShareContract = IPShares(ip.ipShareTokenAddress);
        require(ipShareContract.approve(_spender, _amount), "GenesisForge: IP Share approval failed");
        return true;
    }

    /**
     * @notice Returns the IP Share balance of an account for a specific IP.
     * @param _ipId The ID of the IP.
     * @param _account The address of the account.
     * @return The balance of IP Shares. Returns 1 if `_account` is the sole creator of a non-fractionalized IP, otherwise 0.
     */
    function balanceOfIPShare(uint256 _ipId, address _account) public view returns (uint256) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.ipShareTokenAddress != address(0)) {
            // If fractionalized, query the ERC20 contract
            IPShares ipShareContract = IPShares(ip.ipShareTokenAddress);
            return ipShareContract.balanceOf(_account);
        } else {
            // If not fractionalized, the creator is considered the sole "owner"
            return (_account == ip.creator) ? 1 : 0;
        }
    }

    // --- II. IP Evolution & Governance ---

    /**
     * @notice Allows IP Share holders to submit a proposal for evolving an IP.
     * @dev Proposer must hold at least 1 share.
     * @param _ipId The ID of the IP to propose evolution for.
     * @param _newMetadataURI The URI pointing to the proposed new metadata/content.
     * @param _votingDurationSeconds How long the voting period will last from submission.
     * @return The ID of the new proposal.
     */
    function proposeIPEvolution(uint256 _ipId, string calldata _newMetadataURI, uint256 _votingDurationSeconds) external whenNotPaused returns (uint256) {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");
        require(balanceOfIPShare(_ipId, msg.sender) > 0, "GenesisForge: Must hold IP shares to propose");
        require(_votingDurationSeconds > 0, "GenesisForge: Voting duration must be positive");

        _ipProposalCounters[_ipId].increment();
        uint256 proposalId = _ipProposalCounters[_ipId].current();

        ipEvolutionProposals[_ipId][proposalId] = EvolutionProposal({
            proposalId: proposalId,
            ipId: _ipId,
            proposer: msg.sender,
            newMetadataURI: _newMetadataURI,
            submissionTimestamp: block.timestamp,
            votingEndTime: block.timestamp.add(_votingDurationSeconds),
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false,
            isApproved: false
        });

        emit EvolutionProposalSubmitted(_ipId, proposalId, msg.sender, _newMetadataURI);
        return proposalId;
    }

    /**
     * @notice Allows IP Share holders to vote on active evolution proposals.
     * @param _ipId The ID of the IP.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a "yes" vote, false for a "no" vote.
     */
    function voteOnIPEvolution(uint256 _ipId, uint256 _proposalId, bool _for) external whenNotPaused {
        IPAsset storage ip = ipAssets[_ipId];
        EvolutionProposal storage proposal = ipEvolutionProposals[_ipId][_proposalId];

        require(ip.isActive, "GenesisForge: IP is not active");
        require(proposal.ipId == _ipId, "GenesisForge: Invalid proposal ID for this IP");
        require(block.timestamp <= proposal.votingEndTime, "GenesisForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "GenesisForge: Already voted on this proposal");

        uint256 voterShares = balanceOfIPShare(_ipId, msg.sender);
        require(voterShares > 0, "GenesisForge: Must hold IP shares to vote");

        if (_for) {
            proposal.votesFor = proposal.votesFor.add(voterShares);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterShares);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_ipId, _proposalId, msg.sender, _for);
    }

    /**
     * @notice Executes a successful evolution proposal, updating the IP's metadata.
     * @dev Can be called by anyone after the voting period ends.
     * @param _ipId The ID of the IP.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeIPEvolution(uint256 _ipId, uint256 _proposalId) external whenNotPaused nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        EvolutionProposal storage proposal = ipEvolutionProposals[_ipId][_proposalId];

        require(ip.isActive, "GenesisForge: IP is not active");
        require(proposal.ipId == _ipId, "GenesisForge: Invalid proposal ID for this IP");
        require(block.timestamp > proposal.votingEndTime, "GenesisForge: Voting period not ended yet");
        require(!proposal.isExecuted, "GenesisForge: Proposal already executed");

        bool approved = proposal.votesFor > proposal.votesAgainst;
        proposal.isApproved = approved;
        proposal.isExecuted = true;

        if (approved) {
            // Update the IP metadata (internal call, msg.sender will be this contract)
            updateIPMetadata(_ipId, proposal.newMetadataURI);
        }

        emit EvolutionExecuted(_ipId, _proposalId, approved);
    }

    /**
     * @notice Simulates an AI agent depositing "contribution" (e.g., a hash of new content) for a proposal.
     * @dev This can be used to track AI's involvement and potentially reward them with reputation.
     * @param _ipId The ID of the IP.
     * @param _proposalId The ID of the proposal the AI is contributing to.
     * @param _contributionHash A hash representing the AI's contribution.
     * @param _aiAgentAddress The registered address of the AI agent.
     */
    function depositAIContribution(uint256 _ipId, uint256 _proposalId, bytes32 _contributionHash, address _aiAgentAddress) external whenNotPaused {
        require(ipAssets[_ipId].isActive, "GenesisForge: IP is not active");
        require(ipEvolutionProposals[_ipId][_proposalId].ipId == _ipId, "GenesisForge: Invalid proposal ID");
        require(aiContributors[_aiAgentAddress].isRegistered, "GenesisForge: AI Agent not registered");

        // Simple reputation gain mechanism
        aiContributors[_aiAgentAddress].reputationScore = aiContributors[_aiAgentAddress].reputationScore.add(10);
        aiContributors[_aiAgentAddress].lastContributionTimestamp = block.timestamp;

        // In a real system, there might be more complex verification of the contribution
        // and its relevance to the proposal. This is a simplified simulation.

        emit AIContributionDeposited(_ipId, _proposalId, _aiAgentAddress, _contributionHash);
    }

    // --- III. Licensing & Royalties ---

    /**
     * @notice Allows the IP owner (creator or governance via vote) to set specific licensing terms for an IP.
     * @dev Callable by the IP's creator (if non-fractionalized) or any IP share holder (if fractionalized).
     *      In a full DAO, this might require a governance proposal and vote.
     * @param _ipId The ID of the IP.
     * @param _licenseType A descriptive string for the license type (e.g., "Commercial-SmallScale", "Research").
     * @param _feePerUnit The fee (in `_currency`) for each unit of usage.
     * @param _currency The ERC20 token address used for payment, or address(0) for ETH.
     * @param _validityDurationSeconds How long the license will be active once granted.
     */
    function setLicenseTerms(
        uint256 _ipId,
        string calldata _licenseType,
        uint256 _feePerUnit,
        address _currency,
        uint256 _validityDurationSeconds
    ) external whenNotPaused {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");
        require(balanceOfIPShare(_ipId, msg.sender) > 0, "GenesisForge: Must hold IP shares to set license terms");

        ipLicenseTerms[_ipId][_licenseType] = LicenseTerms({
            licenseType: _licenseType,
            feePerUnit: _feePerUnit,
            currency: _currency,
            validityDurationSeconds: _validityDurationSeconds,
            isActive: true
        });

        emit LicenseTermsSet(_ipId, _licenseType, _feePerUnit, _currency);
    }

    /**
     * @notice Users request a license for a specific IP.
     * @param _ipId The ID of the IP.
     * @param _licenseType The type of license requested (must match existing terms).
     * @param _units The number of usage units being requested/paid for upfront.
     * @return The ID of the license request.
     */
    function requestIPLicense(uint256 _ipId, string calldata _licenseType, uint256 _units) external whenNotPaused returns (uint256) {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");
        LicenseTerms storage terms = ipLicenseTerms[_ipId][_licenseType];
        require(terms.isActive, "GenesisForge: License terms not active or do not exist");
        require(_units > 0, "GenesisForge: Must request at least one unit");

        _licenseRequestIds.increment();
        uint256 requestId = _licenseRequestIds.current();

        licenseRequests[requestId] = LicenseRequest({
            requestId: requestId,
            ipId: _ipId,
            requester: msg.sender,
            licenseType: _licenseType,
            requestedUnits: _units,
            requestTimestamp: block.timestamp,
            isApproved: false,
            activeLicenseId: 0
        });

        emit LicenseRequested(requestId, _ipId, msg.sender, _licenseType, _units);
        return requestId;
    }

    /**
     * @notice Approves a license request, requiring payment if applicable.
     * @dev Callable by IP owners/governance. Handles payment of fees. ETH payments directly accrue to IP revenue.
     * @param _ipId The ID of the IP.
     * @param _requestId The ID of the license request to approve.
     */
    function grantIPLicense(uint256 _ipId, uint256 _requestId) external payable whenNotPaused nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        LicenseRequest storage request = licenseRequests[_requestId];
        LicenseTerms storage terms = ipLicenseTerms[_ipId][request.licenseType];

        require(ip.isActive, "GenesisForge: IP is not active");
        require(request.ipId == _ipId, "GenesisForge: Invalid request ID for this IP");
        require(!request.isApproved, "GenesisForge: Request already approved");
        require(balanceOfIPShare(_ipId, msg.sender) > 0, "GenesisForge: Must hold IP shares to grant licenses"); // Governance role
        require(terms.isActive, "GenesisForge: License terms no longer active");

        uint256 totalFee = terms.feePerUnit.mul(request.requestedUnits);

        if (terms.currency == address(0)) { // ETH payment
            require(msg.value >= totalFee, "GenesisForge: Insufficient ETH provided");
            if (msg.value > totalFee) {
                // Return any excess ETH
                (bool success, ) = payable(msg.sender).call{value: msg.value.sub(totalFee)}("");
                require(success, "GenesisForge: Failed to return excess ETH");
            }
        } else { // ERC20 payment
            require(msg.value == 0, "GenesisForge: Do not send ETH for ERC20 payment");
            IERC20 erc20 = IERC20(terms.currency);
            require(erc20.transferFrom(request.requester, address(this), totalFee), "GenesisForge: ERC20 transfer failed");
            // For simplicity, this contract only handles ETH royalties. ERC20 fees are collected
            // but would require separate accounting or conversion to ETH to be part of the `totalRevenueEarned`.
        }

        request.isApproved = true;

        _activeLicenseIds.increment();
        uint256 activeLicenseId = _activeLicenseIds.current();

        activeLicenses[activeLicenseId] = ActiveLicense({
            licenseId: activeLicenseId,
            ipId: _ipId,
            licensee: request.requester,
            licenseType: request.licenseType,
            grantTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp.add(terms.validityDurationSeconds),
            unitsGranted: request.requestedUnits,
            unitsUsed: 0,
            isActive: true,
            totalPaid: totalFee
        });
        request.activeLicenseId = activeLicenseId;

        // If ETH was paid, add it to the IP's revenue pool and update cumulative royalty
        if (terms.currency == address(0)) {
            ip.totalRevenueEarned = ip.totalRevenueEarned.add(totalFee);
            _updateCumulativeRoyaltyPerShare(_ipId); // Update cumulative royalty per share immediately
        }

        emit LicenseGranted(activeLicenseId, _ipId, request.requester, totalFee);
    }

    /**
     * @notice An authorized oracle reports commercial usage of a licensed IP.
     * @dev This function adds `_additionalFee` (assumed ETH) to the IP's revenue pool.
     * @param _licenseId The ID of the active license.
     * @param _unitsUsed The number of units used during the reporting period.
     * @param _additionalFee The fee associated with this additional usage, if any (in ETH).
     */
    function reportIPUsage(uint256 _licenseId, uint256 _unitsUsed, uint256 _additionalFee) external onlyOracle whenNotPaused nonReentrant {
        ActiveLicense storage license = activeLicenses[_licenseId];
        IPAsset storage ip = ipAssets[license.ipId];

        require(license.isActive, "GenesisForge: License is not active");
        require(ip.isActive, "GenesisForge: IP is not active");
        require(block.timestamp <= license.expirationTimestamp, "GenesisForge: License has expired");
        
        license.unitsUsed = license.unitsUsed.add(_unitsUsed);
        
        // Add additional fee to IP's total revenue pool. Assumes _additionalFee is in ETH.
        // In a real scenario, the oracle would need to ensure these funds are sent to the contract.
        // For demonstration, we assume the oracle has a mechanism to deposit these funds.
        // As contract balance is not explicitly checked for this `_additionalFee`, it implies
        // this is more of an accounting entry until a real deposit mechanism is integrated.
        ip.totalRevenueEarned = ip.totalRevenueEarned.add(_additionalFee);

        _updateCumulativeRoyaltyPerShare(_ipId); // Update cumulative royalty per share immediately
        
        emit IPUsageReported(_licenseId, _unitsUsed, _additionalFee);
    }

    /**
     * @dev Internal function to update the cumulative royalty per share for an IP whenever new revenue is added
     *      or a distribution is triggered. This avoids expensive iteration over all shareholders.
     * @param _ipId The ID of the IP.
     */
    function _updateCumulativeRoyaltyPerShare(uint256 _ipId) internal {
        IPAsset storage ip = ipAssets[_ipId];
        uint256 totalOutstandingShares;

        if (ip.ipShareTokenAddress != address(0)) {
            totalOutstandingShares = IPShares(ip.ipShareTokenAddress).totalSupply();
        } else {
            totalOutstandingShares = 1; // Sole owner, conceptually 1 share.
        }

        if (totalOutstandingShares > 0 && ip.totalRevenueEarned > 0) {
            uint256 revenueToAdd = ip.totalRevenueEarned;
            ip.totalRevenueEarned = 0; // Reset as this revenue is now accounted for in the cumulative value

            // Calculate the per-share royalty for this new revenue and add it to the cumulative total
            ip.cumulativeRoyaltyPerShare = ip.cumulativeRoyaltyPerShare.add(
                revenueToAdd.mul(RAY).div(totalOutstandingShares)
            );
            emit RoyaltiesDistributed(_ipId, revenueToAdd, ip.cumulativeRoyaltyPerShare);
        }
    }

    /**
     * @dev Internal function to update a user's `lastClaimedCumulativeRoyaltyPerShare` to the current value.
     *      This is called before any share transfers to ensure they acknowledge their due up to that point.
     *      It prevents new share buyers from claiming old royalties.
     * @param _ipId The ID of the IP.
     * @param _user The address of the user whose claim point is to be updated.
     */
    function _updateLastClaimedCumulativeRoyaltyPerShare(uint256 _ipId, address _user) internal {
        IPAsset storage ip = ipAssets[_ipId];
        // This effectively "claims" the royalties by updating the user's checkpoint
        ip.lastClaimedCumulativeRoyaltyPerShare[_user] = ip.cumulativeRoyaltyPerShare;
    }

    /**
     * @notice Triggers a royalty distribution event, updating the cumulative royalty per share for an IP.
     * @dev Can be called by anyone. This ensures that any `totalRevenueEarned` is processed into
     *      `cumulativeRoyaltyPerShare` so it becomes claimable.
     * @param _ipId The ID of the IP to trigger distribution for.
     */
    function distributeRoyalties(uint256 _ipId) external whenNotPaused {
        _updateCumulativeRoyaltyPerShare(_ipId);
    }

    /**
     * @notice Calculates the amount of royalties a specific user can claim for a given IP.
     * @param _ipId The ID of the IP.
     * @param _user The address of the user.
     * @return The amount of royalties (in ETH for simplicity) claimable by the user.
     */
    function getClaimableRoyalties(uint256 _ipId, address _user) public view returns (uint256) {
        IPAsset storage ip = ipAssets[_ipId];
        uint256 userShares = balanceOfIPShare(_ipId, _user);

        if (userShares == 0 || ip.cumulativeRoyaltyPerShare == ip.lastClaimedCumulativeRoyaltyPerShare[_user]) {
            return 0; // No shares or no new royalties to claim
        }

        // Calculate the difference in cumulative royalty per share since last claim
        uint256 unpaidAccumulatedRoyaltyPerShare = ip.cumulativeRoyaltyPerShare.sub(ip.lastClaimedCumulativeRoyaltyPerShare[_user]);
        // Multiply by user's shares and scale down
        return userShares.mul(unpaidAccumulatedRoyaltyPerShare).div(RAY);
    }

    /**
     * @notice Allows IP Share holders to withdraw their share of accumulated earnings.
     * @dev Calculates the proportional share based on current holdings and the cumulative royalty per share model.
     *      Assumes royalties are paid in ETH.
     * @param _ipId The ID of the IP to withdraw royalties from.
     */
    function withdrawRoyalties(uint256 _ipId) external payable whenNotPaused nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.isActive, "GenesisForge: IP is not active");

        // Ensure the cumulative royalty per share is up-to-date before calculating claimable amount
        _updateCumulativeRoyaltyPerShare(_ipId);

        uint256 claimableAmount = getClaimableRoyalties(_ipId, msg.sender);
        require(claimableAmount > 0, "GenesisForge: No withdrawable royalties for this user");
        
        // Before transferring funds, update the user's last claimed point to the current cumulative value
        // This prevents them from claiming the same funds again.
        ip.lastClaimedCumulativeRoyaltyPerShare[msg.sender] = ip.cumulativeRoyaltyPerShare;
        
        // Transfer funds (assuming ETH)
        (bool success, ) = payable(msg.sender).call{value: claimableAmount}("");
        require(success, "GenesisForge: ETH transfer failed");

        emit RoyaltiesWithdrawn(_ipId, msg.sender, claimableAmount);
    }

    // --- IV. AI Agent Reputation & "Content Origin Prover" ---

    /**
     * @notice Registers an external AI agent with a unique ID for reputation tracking.
     * @dev Only the contract owner can register new AI contributors.
     * @param _aiAgentAddress The unique address representing the AI agent.
     * @param _name A human-readable name for the AI agent.
     */
    function registerAIContributor(address _aiAgentAddress, string calldata _name) external onlyOwner whenNotPaused {
        require(_aiAgentAddress != address(0), "GenesisForge: AI agent address cannot be zero");
        require(!aiContributors[_aiAgentAddress].isRegistered, "GenesisForge: AI Agent already registered");

        aiContributors[_aiAgentAddress] = AIContributor({
            name: _name,
            reputationScore: 0,
            lastContributionTimestamp: block.timestamp,
            isRegistered: true
        });

        emit AIContributorRegistered(_aiAgentAddress, _name);
    }

    /**
     * @notice Returns the current reputation score of an AI agent.
     * @param _aiAgentAddress The address of the AI agent.
     * @return The reputation score.
     */
    function getAIContributionReputation(address _aiAgentAddress) public view returns (uint256) {
        return aiContributors[_aiAgentAddress].reputationScore;
    }

    /**
     * @notice A user submits a proof (e.g., hash sequence) demonstrating content derivation from a registered IP.
     * @dev This simulates a ZKP-like verification where `_verifyDerivationProof` is an internal stub.
     *      The `_derivationHashes` conceptually represent a proof chain or commitment, linking to the original IP.
     * @param _ipId The ID of the original IP.
     * @param _derivationHashes A sequence of hashes demonstrating the derivation path. Can be empty if direct match to current IP.
     * @param _finalContentHash The hash of the final derived content.
     */
    function submitContentOriginProof(uint256 _ipId, bytes32[] calldata _derivationHashes, bytes32 _finalContentHash) external whenNotPaused {
        require(ipAssets[_ipId].isActive, "GenesisForge: Original IP is not active");
        
        // If derivation hashes are empty, the final content hash must directly match the current IP metadata hash
        if (_derivationHashes.length == 0) {
            bytes32 originalRootHash = keccak256(abi.encodePacked(ipAssets[_ipId].currentMetadataURI));
            require(originalRootHash == _finalContentHash, "GenesisForge: Empty derivation requires direct match to original IP hash.");
        }

        // Simulate ZKP verification using a simplified hash chain logic
        bool isValid = _verifyDerivationProof(_ipId, _derivationHashes, _finalContentHash);

        contentOriginProofs[_ipId][_finalContentHash] = ContentOriginProof({
            ipId: _ipId,
            prover: msg.sender,
            derivationHashes: _derivationHashes,
            finalContentHash: _finalContentHash,
            submissionTimestamp: block.timestamp,
            isValid: isValid,
            isChallenged: false
        });

        emit ContentOriginProofSubmitted(_ipId, msg.sender, _finalContentHash, isValid);
    }

    /**
     * @dev Internal function to simulate ZKP-like verification of content derivation.
     *      In a real system, this would involve complex cryptographic checks, a dedicated ZKP verifier contract,
     *      or an oracle call to an off-chain verifier.
     *      For this contract, it implements a simple hash chain logic: it concatenates the root hash (from IP metadata)
     *      with each hash in `_derivationHashes` to build a final hash, which must match `_finalContentHash`.
     * @param _ipId The ID of the original IP.
     * @param _derivationHashes A sequence of hashes representing the derivation steps.
     * @param _finalContentHash The hash of the final derived content to verify against.
     * @return True if the simulated derivation proof is valid, false otherwise.
     */
    function _verifyDerivationProof(uint256 _ipId, bytes32[] calldata _derivationHashes, bytes32 _finalContentHash) internal view returns (bool) {
        bytes32 rootHash = keccak256(abi.encodePacked(ipAssets[_ipId].currentMetadataURI));

        if (_derivationHashes.length == 0) {
            return rootHash == _finalContentHash; // Direct match if no derivation steps
        }

        bytes32 currentChainHash = rootHash;
        for (uint i = 0; i < _derivationHashes.length; i++) {
            currentChainHash = keccak256(abi.encodePacked(currentChainHash, _derivationHashes[i]));
        }

        return currentChainHash == _finalContentHash;
    }

    /**
     * @notice Allows others to challenge a submitted proof of origin.
     * @dev A challenge flags the proof. In a full system, this would trigger a dispute resolution mechanism
     *      (e.g., arbitration, community vote, slashing of collateral). For this example, it only marks the proof as challenged.
     * @param _ipId The ID of the original IP.
     * @param _prover The address of the original prover.
     * @param _finalContentHash The hash of the content for which the proof was submitted.
     */
    function challengeContentOriginProof(uint256 _ipId, address _prover, bytes32 _finalContentHash) external whenNotPaused {
        ContentOriginProof storage proof = contentOriginProofs[_ipId][_finalContentHash];
        require(proof.ipId == _ipId, "GenesisForge: No such proof exists for this IP and content hash.");
        require(proof.prover == _prover, "GenesisForge: Prover mismatch.");
        require(!proof.isChallenged, "GenesisForge: Proof already challenged.");
        
        proof.isChallenged = true;
        
        emit ContentOriginProofChallenged(_ipId, msg.sender, _finalContentHash);
    }


    // --- V. Administrative / Utility ---

    /**
     * @notice Admin function to set the address of the usage reporting oracle.
     * @dev Only the contract owner can call this.
     * @param _newOracleAddress The new address for the oracle.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner whenNotPaused {
        require(_newOracleAddress != address(0), "GenesisForge: New oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /**
     * @notice Emergency function to pause critical contract operations.
     * @dev Only the contract owner can call this. Prevents new IP creation, fractionalization,
     *      voting, and licensing actions, ensuring stability during unforeseen issues.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only the contract owner can call this. Re-enables all paused contract operations.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Fallback function to receive ETH
    receive() external payable {
        // This allows the contract to receive ETH, which is crucial for handling royalty payments.
        // Any ETH sent directly to the contract (not via a specific function) will be received here.
    }
}
```