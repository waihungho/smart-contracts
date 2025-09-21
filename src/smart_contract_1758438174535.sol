The smart contract concept I've devised is the **"Intellectual Genesis Vault (IGV)"**. This platform aims to provide a decentralized system for tokenizing, evolving, and managing intellectual property (IP) assets. It introduces advanced concepts like:

1.  **Dynamic IP Representation:** IPs are NFTs (IPTokens) that can be linked to parent IPs, showing lineage and evolution.
2.  **Fractionalized Ownership (FIPTokens):** Allowing diverse ownership structures.
3.  **Adaptive Licensing & Royalties:** Royalties can change based on real-world usage or external data (simulated via oracle in this demo).
4.  **Community-Driven Evolution:** Holders can propose and vote on derivatives/evolutions of existing IPs, fostering collaborative creation.
5.  **Impact-Based Incentives (Impact Credits):** Rewards for active participation and governance, promoting a meritocratic ecosystem.
6.  **Dispute Resolution:** On-chain mechanisms for resolving IP-related conflicts.
7.  **IP Bundling:** Combining multiple IPs into a single "Meta-IP" NFT.

---

## IntellectualGenesisVault Smart Contract

This contract serves as a decentralized platform for managing Intellectual Property (IP). It leverages ERC721 for unique IP representations (IIPTokens), ERC20 for fractional ownership (FIPTokens), and ERC20 for community engagement rewards (ImpactCreditTokens).

### Outline and Function Summary:

**I. IP Core Management & Representation:**
Manages the registration, metadata updates, state changes, and delegation of Intellectual Properties. Each IP is represented by an ERC721 NFT (`IIPToken`).

1.  `registerIntellectualProperty(string memory _ipHash, string memory _metadataURI, uint256 _initialRoyaltyNumerator, uint256 _initialRoyaltyDenominator)`: Registers a new IP, mints an `IIPToken`, and sets initial licensing terms.
2.  `updateIPMetadata(uint256 _ipTokenId, string memory _newMetadataURI)`: Allows the IP owner to update the metadata URI associated with their IP.
3.  `delegateIPSteward(uint256 _ipTokenId, address _steward, bool _canLicense, bool _canProposeEvolution)`: Appoints a steward for an IP with specific permissions (e.g., licensing, evolution proposals).
4.  `revokeIPSteward(uint256 _ipTokenId, address _steward)`: Revokes a previously delegated IP steward.
5.  `setIPState(uint256 _ipTokenId, IPState _newState)`: Allows the IP owner to change the state of their IP (e.g., Active, Hibernated, Archived).

**II. Fractionalization & Licensing:**
Enables fractional ownership of IP via ERC20 `FIPTokens` and facilitates adaptive licensing agreements.

6.  `fractionalizeIP(uint256 _ipTokenId, uint256 _amount)`: Converts an `IIPToken` into a specified amount of fungible `FIPTokens`. The `IIPToken` is held by the vault.
7.  `deFractionalizeIP(uint256 _ipTokenId)`: Re-consolidates `FIPTokens` (a predefined amount) back into its original `IIPToken`, returning it to the caller.
8.  `proposeLicensingTerms(uint256 _ipTokenId, RoyaltyModelType _model, uint256 _numerator, uint256 _denominator, uint256 _durationSeconds)`: An IP owner/steward defines new terms for licensing their IP, including royalty models.
9.  `acceptLicensingTerms(uint256 _ipTokenId, address _licensee, uint256 _initialPayment)`: A user accepts a proposed licensing offer by paying an initial fee.
10. `payAdaptiveRoyalty(uint256 _ipTokenId, address _licensee)`: Licensees pay royalties, with the amount dynamically calculated based on the IP's royalty model (potentially via simulated oracle data).
11. `revokeLicense(uint256 _ipTokenId, address _licensee)`: Allows an IP owner/steward to revoke an active license, subject to contract conditions.

**III. Dynamic Evolution & Derivation:**
Supports the creation of new IPs as derivatives or evolutions of existing ones, with community governance.

12. `proposeIPEvolution(uint256 _parentIpTokenId, string memory _evolutionIpHash, string memory _evolutionMetadataURI)`: Submits a proposal for a new IP that is derived from an existing parent IP.
13. `voteOnIPEvolution(uint256 _evolutionProposalId, bool _approve)`: Allows `ImpactCreditToken` holders to vote on IP evolution proposals.
14. `finalizeIPEvolution(uint256 _evolutionProposalId)`: Finalizes an evolution proposal if it passes voting, minting a new `IIPToken` linked to its parent.
15. `claimEvolutionReward(uint256 _evolutionProposalId)`: Allows the proposer of a successful evolution to claim their reward.

**IV. Adaptive Economics & Incentives:**
Implements staking `FIPTokens` for influence and distributing "Impact Credits" as rewards for engagement.

16. `stakeFIPForInfluence(uint256 _ipTokenId, uint256 _amount)`: Stakes `FIPTokens` for a specific IP to gain influence for that IP and earn `ImpactCredits`.
17. `unstakeFIPFromInfluence(uint256 _ipTokenId, uint256 _amount)`: Unstakes `FIPTokens`, removing their influence and stopping `ImpactCredit` accumulation for the unstaked amount.
18. `claimImpactCredits()`: Allows users to claim accumulated `ImpactCredits`. (Simplified for demo)
19. `boostIPVisibility(uint256 _ipTokenId, uint256 _impactCreditsToBurn)`: Burns `ImpactCredits` to increase the visibility score of an IP (simulated effect).
20. `setAdaptiveRoyaltyModel(uint256 _ipTokenId, RoyaltyModelType _model, uint256 _numerator, uint256 _denominator)`: Owner/steward defines the specific parameters for an IP's adaptive royalty calculation.

**V. Advanced Mechanics & Governance:**
Includes mechanisms for dispute resolution, and the bundling/unbundling of multiple IPs.

21. `initiateIPDispute(uint256 _ipTokenId, address _againstAddress, string memory _disputeReasonURI)`: Starts a dispute process related to an IP (e.g., originality claim, license breach), requiring an initial stake.
22. `submitDisputeEvidence(uint256 _disputeId, string memory _evidenceURI)`: Allows parties involved in a dispute to submit evidence.
23. `voteOnDispute(uint256 _disputeId, bool _verdict)`: Enables `ImpactCreditToken` holders to vote on dispute outcomes.
24. `resolveDispute(uint256 _disputeId)`: Finalizes a dispute based on voting, potentially transferring staked funds or updating ownership.
25. `bundleIPs(uint256[] memory _ipTokenIds, string memory _bundleMetadataURI)`: Combines multiple `IIPTokens` into a single new "MetaIPToken" (a new `IIPToken` representing the bundle).
26. `unbundleIPs(uint256 _bundleIpTokenId)`: Disassembles a "MetaIPToken" back into its constituent `IIPTokens`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- INTERFACES FOR DEPENDENT TOKENS ---
// These interfaces define the expected functions for the ERC721 and ERC20 tokens
// that the IntellectualGenesisVault contract interacts with.
interface IIPToken is IERC721 {
    function mint(address to, uint256 tokenId, string memory uri) external returns (uint256);
    function updateTokenURI(uint256 tokenId, string memory newUri) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IFIPToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

interface IImpactCreditToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

/**
 * @title IntellectualGenesisVault
 * @dev A smart contract platform for tokenizing, evolving, and managing intellectual property (IP).
 *      It allows creators to register IP as NFTs (IPTokens), fractionalize them into fungible tokens (FIPTokens),
 *      propose and vote on IP evolutions/derivatives, and manage adaptive licensing.
 *      The system also incorporates "Impact Credits" for community engagement and governance.
 *
 * (Function Summary is provided at the top of this file for better readability)
 */
contract IntellectualGenesisVault is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IIPToken public ipTokenContract;
    IFIPToken public fipTokenContract;
    IImpactCreditToken public impactCreditTokenContract;

    Counters.Counter private _ipTokenIds;
    Counters.Counter private _licenseIds;
    Counters.Counter private _evolutionProposalIds;
    Counters.Counter private _disputeIds;

    // Enum to represent the lifecycle state of an IP
    enum IPState {
        Active,
        Hibernated, // Less active, potentially lower fees, limited features
        Archived    // For public domain, retired, or unmaintained IPs
    }

    // Enum for different royalty calculation models
    enum RoyaltyModelType {
        Fixed,              // A fixed percentage of a base amount
        LinearWithUsage,    // Royalty scales linearly with a usage metric (simulated by oracle)
        TieredByVolume,     // Royalty rate changes based on transaction volume (simulated)
        ExternalOracleDriven // Royalty entirely determined by an external oracle feed
    }

    // Struct to store core data for each Intellectual Property
    struct IPData {
        uint256 id;
        string ipHash;       // Content hash (e.g., IPFS CID, SHA256) of the IP's core asset
        string metadataURI;  // URI to external metadata (e.g., JSON file, IPFS link)
        address owner;       // Cached owner address (primary owner is `ipTokenContract.ownerOf(id)`)
        IPState state;       // Current state of the IP
        RoyaltyModelType royaltyModel; // The model used for adaptive royalties
        uint256 royaltyNumerator;   // Numerator for royalty calculation (e.g., 5 for 5%)
        uint256 royaltyDenominator; // Denominator for royalty calculation (e.g., 100 for 5%)
        uint256 parentIpId;  // ID of the parent IP if this is an evolution/derivative (0 if original)
        uint256[] bundledIpIds; // List of constituent IP IDs if this IP is a bundle
    }
    mapping(uint256 => IPData) public ipVault;

    // Struct to define permissions for a delegated IP steward
    struct IPSteward {
        bool canLicense;           // Can manage licenses for this IP
        bool canProposeEvolution;  // Can propose evolutions for this IP
    }
    mapping(uint256 => mapping(address => IPSteward)) public ipStewards; // ipId => stewardAddress => IPSteward

    // Struct for active licensing agreements
    struct LicenseAgreement {
        uint256 id;
        uint256 ipTokenId;
        address licensee;
        uint256 initialPayment;
        RoyaltyModelType royaltyModel;      // Model specific to this license agreement
        uint256 royaltyNumerator;
        uint256 royaltyDenominator;
        uint256 startTime;
        uint256 durationSeconds;            // Duration of the license (0 for perpetual)
        bool isActive;
        uint256 lastRoyaltyPaymentBlock;    // Block number of the last royalty payment
    }
    mapping(uint256 => LicenseAgreement) public licenses;
    mapping(uint256 => mapping(address => uint256)) public ipLicenseeToLicenseId; // ipId => licenseeAddress => licenseId

    // Struct for IP evolution proposals
    struct EvolutionProposal {
        uint256 id;
        uint256 parentIpTokenId;
        string evolutionIpHash;
        string evolutionMetadataURI;
        address proposer;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool finalized;
        uint256 newIpTokenId; // If approved and finalized, ID of the newly minted IP
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnEvolution; // proposalId => voterAddress => voted

    // Struct to track staked FIPTokens for influence and Impact Credit accrual
    struct StakedFIP {
        uint256 amount;
        uint256 lastClaimBlock; // Last block credits were claimed for this stake
    }
    mapping(uint256 => mapping(address => StakedFIP)) public stakedFIPs; // ipId => stakerAddress => StakedFIP
    mapping(address => uint256) public impactCreditAccrued; // Not yet claimed (simplified)

    // Struct for dispute resolution
    struct Dispute {
        uint256 id;
        uint256 ipTokenId;
        address initiator;
        address againstAddress;
        string disputeReasonURI;
        string[] evidenceURIs;      // URIs to evidence submitted by all parties
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesForInitiator;
        uint256 votesForAgainst;
        bool resolved;
        bool initiatorWins;         // True if initiator wins the dispute
        uint256 stakedFunds;        // Funds locked during dispute initiation
    }
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnDispute; // disputeId => voterAddress => voted

    // Global constants for voting durations and reward rates (example values)
    uint256 public constant EVOLUTION_VOTING_DURATION = 7 days;
    uint256 public constant DISPUTE_VOTING_DURATION = 5 days;
    uint256 public constant FIP_AMOUNT_TO_DEFRAC = 1000 ether; // Example: amount of FIP to burn to reclaim an IP

    // --- Events ---
    event IPRegistered(uint256 indexed ipId, address indexed owner, string ipHash, string metadataURI);
    event IPMetadataUpdated(uint256 indexed ipId, string newMetadataURI);
    event IPStewardDelegated(uint256 indexed ipId, address indexed steward, bool canLicense, bool canProposeEvolution);
    event IPStewardRevoked(uint256 indexed ipId, address indexed steward);
    event IPStateChanged(uint256 indexed ipId, IPState newState);
    event IPFractionalized(uint256 indexed ipId, address indexed owner, uint256 amountFIP);
    event IPDeFractionalized(uint256 indexed ipId, address indexed owner);
    event LicenseProposed(uint256 indexed ipId, address indexed proposer, RoyaltyModelType model, uint256 numerator, uint256 denominator);
    event LicenseAccepted(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 initialPayment);
    event RoyaltyPaid(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 amount);
    event LicenseRevoked(uint256 indexed licenseId, uint256 indexed ipId);
    event IPEvolutionProposed(uint256 indexed proposalId, uint256 indexed parentIpId, address indexed proposer, string evolutionIpHash);
    event IPEvolutionVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event IPEvolutionFinalized(uint256 indexed proposalId, uint256 indexed newIpId);
    event EvolutionRewardClaimed(uint256 indexed proposalId, address indexed claimant, uint256 rewardAmount);
    event FIPStakedForInfluence(uint256 indexed ipId, address indexed staker, uint256 amount);
    event FIPUnstakedFromInfluence(uint256 indexed ipId, address indexed staker, uint256 amount);
    event ImpactCreditsClaimed(address indexed claimant, uint256 amount);
    event IPVisibilityBoosted(uint256 indexed ipId, address indexed booster, uint256 burnedCredits);
    event AdaptiveRoyaltyModelUpdated(uint256 indexed ipId, RoyaltyModelType model, uint256 numerator, uint256 denominator);
    event IPDisputeInitiated(uint256 indexed disputeId, uint256 indexed ipId, address indexed initiator, address againstAddress);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, string evidenceURI);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool verdictForInitiator);
    event DisputeResolved(uint256 indexed disputeId, bool initiatorWins);
    event IPsBundled(uint256 indexed bundleIpId, address indexed owner, uint256[] bundledIpIds);
    event IPsUnbundled(uint256 indexed bundleIpId, address indexed owner, uint256[] unbundledIpIds);

    // --- Modifiers ---
    modifier onlyIPOwner(uint256 _ipTokenId) {
        require(ipTokenContract.ownerOf(_ipTokenId) == msg.sender, "IGV: Not IP owner");
        _;
    }

    modifier onlyIPOwnerOrSteward(uint256 _ipTokenId) {
        require(
            ipTokenContract.ownerOf(_ipTokenId) == msg.sender || ipStewards[_ipTokenId][msg.sender].canLicense,
            "IGV: Not IP owner or authorized steward"
        );
        _;
    }

    modifier onlyIPOwnerOrEvolutionSteward(uint256 _ipTokenId) {
        require(
            ipTokenContract.ownerOf(_ipTokenId) == msg.sender || ipStewards[_ipTokenId][msg.sender].canProposeEvolution,
            "IGV: Not IP owner or authorized evolution steward"
        );
        _;
    }

    // Assumes `_amount` FIPTokens need to be approved and available
    modifier onlyFIPHolder(uint256 _amount) {
        require(fipTokenContract.balanceOf(msg.sender) >= _amount, "IGV: Insufficient FIP balance");
        require(fipTokenContract.allowance(msg.sender, address(this)) >= _amount, "IGV: FIP token allowance required");
        _;
    }

    // Assumes `_amount` Impact Credits need to be approved and available
    modifier onlyImpactCreditHolder(uint256 _amount) {
        require(impactCreditTokenContract.balanceOf(msg.sender) >= _amount, "IGV: Insufficient Impact Credits");
        require(impactCreditTokenContract.allowance(msg.sender, address(this)) >= _amount, "IGV: Impact Credits allowance required");
        _;
    }

    modifier notHibernated(uint256 _ipTokenId) {
        require(ipVault[_ipTokenId].state != IPState.Hibernated, "IGV: IP is hibernated and cannot perform this action");
        _;
    }

    // --- Constructor ---
    constructor(address _ipTokenAddress, address _fipTokenAddress, address _impactCreditTokenAddress) Ownable(msg.sender) {
        require(_ipTokenAddress != address(0), "IGV: IPToken address cannot be zero");
        require(_fipTokenAddress != address(0), "IGV: FIPToken address cannot be zero");
        require(_impactCreditTokenAddress != address(0), "IGV: ImpactCreditToken address cannot be zero");

        ipTokenContract = IIPToken(_ipTokenAddress);
        fipTokenContract = IFIPToken(_fipTokenAddress);
        impactCreditTokenContract = IImpactCreditToken(_impactCreditTokenAddress);
    }

    // --- Internal Helpers ---

    /**
     * @dev Dummy function to simulate oracle data retrieval for adaptive royalties.
     * In a real scenario, this would integrate with a decentralized oracle network (e.g., Chainlink).
     * @param _ipTokenId The ID of the IP (could be used for IP-specific data).
     * @return A multiplier or rate for royalty calculation (e.g., 100 for 1x, 150 for 1.5x).
     */
    function _getOracleData(uint256 _ipTokenId) internal pure returns (uint256) {
        // For demonstration: returns a dummy value based on IP ID.
        // Example: IP ID 1 gets 100 (1x), IP ID 2 gets 150 (1.5x)
        if (_ipTokenId % 2 == 0) {
            return 100; // 1x multiplier or 100% of base rate
        }
        return 150; // 1.5x multiplier or 150% of base rate
    }

    /**
     * @dev Calculates the royalty amount based on the specified model.
     * @param _model The royalty model type.
     * @param _baseAmount The base amount from which royalty is calculated (e.g., sale price).
     * @param _numerator The royalty rate numerator.
     * @param _denominator The royalty rate denominator.
     * @param _ipTokenId The ID of the IP, used for oracle data if applicable.
     * @return The calculated royalty amount.
     */
    function _getRoyaltyAmount(
        RoyaltyModelType _model,
        uint256 _baseAmount,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _ipTokenId
    ) internal view returns (uint256) {
        if (_denominator == 0) return 0;

        uint256 royalty = 0;
        if (_model == RoyaltyModelType.Fixed) {
            royalty = (_baseAmount * _numerator) / _denominator;
        } else if (_model == RoyaltyModelType.LinearWithUsage) {
            uint256 usageMultiplier = _getOracleData(_ipTokenId); // Simulate usage data
            royalty = (_baseAmount * _numerator * usageMultiplier) / (_denominator * 100);
        } else if (_model == RoyaltyModelType.TieredByVolume) {
            // Simplified tiered example: higher volume leads to higher effective numerator
            uint256 effectiveNumerator = _numerator;
            if (_baseAmount > 1000 ether) { // If base amount is above a threshold
                effectiveNumerator = _numerator * 2;
            }
            royalty = (_baseAmount * effectiveNumerator) / _denominator;
        } else if (_model == RoyaltyModelType.ExternalOracleDriven) {
            uint256 oracleRate = _getOracleData(_ipTokenId); // Simulate oracle-driven rate
            royalty = (_baseAmount * oracleRate) / 10000; // Assuming oracleRate is 0-10000 (0-100%)
        }
        return royalty;
    }

    /**
     * @dev Placeholder for updating accrued Impact Credits.
     * In a robust system, this would iterate through `stakedFIPs[ipId][msg.sender]` for all IPs
     * the user has staked in, calculate credits since `lastClaimBlock`, and update `impactCreditAccrued[msg.sender]`.
     * For this demo, it's a simplification.
     * @param _user The address of the user whose credits need updating.
     */
    function _updateAccruedImpactCredits(address _user) internal {
        // This function would contain complex logic to calculate and accumulate Impact Credits.
        // For the scope of this demo, Impact Credits are directly minted in `claimEvolutionReward`
        // and `claimImpactCredits` (which is simplified).
        // A real system might use a Merkle tree for off-chain calculation/on-chain proof,
        // or a complex on-chain accounting of blocks staked per IP per user.
    }

    // --- I. IP Core Management & Representation ---

    /**
     * @dev Registers a new Intellectual Property (IP), minting a unique IIPToken NFT.
     * The `msg.sender` becomes the initial owner of the IP.
     * @param _ipHash A content hash or identifier for the IP's core asset (e.g., IPFS CID).
     * @param _metadataURI A URI pointing to the IP's metadata (e.g., description, image, terms).
     * @param _initialRoyaltyNumerator The numerator for the initial royalty rate.
     * @param _initialRoyaltyDenominator The denominator for the initial royalty rate.
     * @return The ID of the newly registered IP.
     */
    function registerIntellectualProperty(
        string memory _ipHash,
        string memory _metadataURI,
        uint256 _initialRoyaltyNumerator,
        uint256 _initialRoyaltyDenominator
    ) public nonReentrant returns (uint256) {
        _ipTokenIds.increment();
        uint256 newId = _ipTokenIds.current();

        ipTokenContract.mint(msg.sender, newId, _metadataURI);

        ipVault[newId] = IPData({
            id: newId,
            ipHash: _ipHash,
            metadataURI: _metadataURI,
            owner: msg.sender, // Redundant but useful cache
            state: IPState.Active,
            royaltyModel: RoyaltyModelType.Fixed, // Default model
            royaltyNumerator: _initialRoyaltyNumerator,
            royaltyDenominator: _initialRoyaltyDenominator,
            parentIpId: 0, // No parent for original IP
            bundledIpIds: new uint256[](0) // Not a bundle initially
        });

        emit IPRegistered(newId, msg.sender, _ipHash, _metadataURI);
        return newId;
    }

    /**
     * @dev Allows the IP owner to update the metadata URI associated with their IP.
     * This updates both the internal record and the ERC721 token URI.
     * @param _ipTokenId The ID of the IPToken.
     * @param _newMetadataURI The new URI for the IP's metadata.
     */
    function updateIPMetadata(uint256 _ipTokenId, string memory _newMetadataURI) public onlyIPOwner(_ipTokenId) {
        require(bytes(_newMetadataURI).length > 0, "IGV: Metadata URI cannot be empty");
        ipVault[_ipTokenId].metadataURI = _newMetadataURI;
        ipTokenContract.updateTokenURI(_ipTokenId, _newMetadataURI);
        emit IPMetadataUpdated(_ipTokenId, _newMetadataURI);
    }

    /**
     * @dev Appoints a steward for an IP with specific permissions.
     * Stewards can perform certain actions on behalf of the IP owner without full ownership transfer.
     * @param _ipTokenId The ID of the IPToken.
     * @param _steward The address of the steward to appoint.
     * @param _canLicense Whether the steward can propose/manage licenses for this IP.
     * @param _canProposeEvolution Whether the steward can propose evolutions for this IP.
     */
    function delegateIPSteward(uint256 _ipTokenId, address _steward, bool _canLicense, bool _canProposeEvolution) public onlyIPOwner(_ipTokenId) {
        require(_steward != address(0), "IGV: Steward address cannot be zero");
        ipStewards[_ipTokenId][_steward] = IPSteward({
            canLicense: _canLicense,
            canProposeEvolution: _canProposeEvolution
        });
        emit IPStewardDelegated(_ipTokenId, _steward, _canLicense, _canProposeEvolution);
    }

    /**
     * @dev Revokes a previously delegated IP steward.
     * @param _ipTokenId The ID of the IPToken.
     * @param _steward The address of the steward to revoke.
     */
    function revokeIPSteward(uint256 _ipTokenId, address _steward) public onlyIPOwner(_ipTokenId) {
        require(ipStewards[_ipTokenId][_steward].canLicense || ipStewards[_ipTokenId][_steward].canProposeEvolution, "IGV: Not an active steward");
        delete ipStewards[_ipTokenId][_steward];
        emit IPStewardRevoked(_ipTokenId, _steward);
    }

    /**
     * @dev Allows the IP owner to change the state of their IP.
     * This can affect available actions (e.g., hibernated IPs might have limited features).
     * @param _ipTokenId The ID of the IPToken.
     * @param _newState The new state for the IP (Active, Hibernated, Archived).
     */
    function setIPState(uint256 _ipTokenId, IPState _newState) public onlyIPOwner(_ipTokenId) {
        require(ipVault[_ipTokenId].state != _newState, "IGV: IP already in this state");
        ipVault[_ipTokenId].state = _newState;
        emit IPStateChanged(_ipTokenId, _newState);
    }

    // --- II. Fractionalization & Licensing ---

    /**
     * @dev Converts an IIPToken into a specified amount of fungible FIPTokens.
     * The IIPToken is transferred to the IntellectualGenesisVault contract's custody.
     * @param _ipTokenId The ID of the IIPToken to fractionalize.
     * @param _amount The amount of FIPTokens to mint.
     */
    function fractionalizeIP(uint256 _ipTokenId, uint256 _amount) public onlyIPOwner(_ipTokenId) nonReentrant {
        require(_amount > 0, "IGV: Amount must be greater than zero");
        require(ipVault[_ipTokenId].state == IPState.Active, "IGV: IP must be active to fractionalize");

        ipTokenContract.transferFrom(msg.sender, address(this), _ipTokenId);
        fipTokenContract.mint(msg.sender, _amount);

        emit IPFractionalized(_ipTokenId, msg.sender, _amount);
    }

    /**
     * @dev Re-consolidates FIPTokens (a predefined amount) back into its original IIPToken.
     * Requires the caller to burn `FIP_AMOUNT_TO_DEFRAC` FIPTokens.
     * The IIPToken is transferred back from the vault to the caller.
     * NOTE: This is a simplified model. A more advanced system would likely
     * use a per-IP FIP token (e.g., ERC1155) or a specific mechanism to track total FIP supply per IP.
     * @param _ipTokenId The ID of the IIPToken to de-fractionalize.
     */
    function deFractionalizeIP(uint256 _ipTokenId) public nonReentrant {
        require(fipTokenContract.balanceOf(msg.sender) >= FIP_AMOUNT_TO_DEFRAC, "IGV: Insufficient FIP to de-fractionalize");
        require(fipTokenContract.allowance(msg.sender, address(this)) >= FIP_AMOUNT_TO_DEFRAC, "IGV: FIP token allowance required");
        require(ipTokenContract.ownerOf(_ipTokenId) == address(this), "IGV: IPToken not held by vault for de-fractionalization");

        fipTokenContract.transferFrom(msg.sender, address(this), FIP_AMOUNT_TO_DEFRAC);
        fipTokenContract.burn(address(this), FIP_AMOUNT_TO_DEFRAC);

        ipTokenContract.transferFrom(address(this), msg.sender, _ipTokenId);

        emit IPDeFractionalized(_ipTokenId, msg.sender);
    }

    /**
     * @dev An IP owner/steward defines new terms for licensing their IP.
     * This updates the default terms for *new* licenses for this IP.
     * @param _ipTokenId The ID of the IPToken.
     * @param _model The royalty model type.
     * @param _numerator The numerator for the royalty calculation.
     * @param _denominator The denominator for the royalty calculation.
     * @param _durationSeconds Duration of the license in seconds (0 for perpetual).
     */
    function proposeLicensingTerms(
        uint256 _ipTokenId,
        RoyaltyModelType _model,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _durationSeconds
    ) public onlyIPOwnerOrSteward(_ipTokenId) notHibernated(_ipTokenId) {
        require(_denominator > 0, "IGV: Royalty denominator cannot be zero");

        IPData storage ip = ipVault[_ipTokenId];
        ip.royaltyModel = _model;
        ip.royaltyNumerator = _numerator;
        ip.royaltyDenominator = _denominator;
        // The _durationSeconds would be used when an actual license agreement is created
        // in acceptLicensingTerms, but is stored here as part of the "offer".

        emit LicenseProposed(_ipTokenId, msg.sender, _model, _numerator, _denominator);
    }

    /**
     * @dev A user accepts a proposed licensing offer by paying an initial fee.
     * The initial payment is sent to the IP owner.
     * @param _ipTokenId The ID of the IPToken to license.
     * @param _licensee The address of the licensee.
     * @param _initialPayment The initial payment for the license (in native token, e.g., ETH).
     */
    function acceptLicensingTerms(uint256 _ipTokenId, address _licensee, uint256 _initialPayment) public payable nonReentrant {
        require(_licensee != address(0), "IGV: Licensee address cannot be zero");
        require(ipVault[_ipTokenId].state == IPState.Active, "IGV: IP is not active for licensing");
        require(ipLicenseeToLicenseId[_ipTokenId][_licensee] == 0, "IGV: License already exists for this IP and licensee");
        require(msg.value == _initialPayment, "IGV: Initial payment does not match msg.value");

        _licenseIds.increment();
        uint256 newLicenseId = _licenseIds.current();

        IPData storage ip = ipVault[_ipTokenId];
        licenses[newLicenseId] = LicenseAgreement({
            id: newLicenseId,
            ipTokenId: _ipTokenId,
            licensee: _licensee,
            initialPayment: _initialPayment,
            royaltyModel: ip.royaltyModel, // Use current default model from IPData
            royaltyNumerator: ip.royaltyNumerator,
            royaltyDenominator: ip.royaltyDenominator,
            startTime: block.timestamp,
            durationSeconds: 0, // Placeholder, actual duration from `proposeLicensingTerms` if stored
            isActive: true,
            lastRoyaltyPaymentBlock: block.number
        });
        ipLicenseeToLicenseId[_ipTokenId][_licensee] = newLicenseId;

        payable(ipTokenContract.ownerOf(_ipTokenId)).transfer(_initialPayment);

        emit LicenseAccepted(newLicenseId, _ipTokenId, _licensee, _initialPayment);
    }

    /**
     * @dev Licensees pay royalties, with the amount dynamically calculated based on the IP's royalty model.
     * `msg.value` is treated as the base amount for royalty calculation in this example.
     * @param _ipTokenId The ID of the IPToken.
     * @param _licensee The address of the licensee.
     */
    function payAdaptiveRoyalty(uint256 _ipTokenId, address _licensee) public payable nonReentrant {
        uint256 licenseId = ipLicenseeToLicenseId[_ipTokenId][_licensee];
        require(licenseId != 0, "IGV: No active license found for this IP and licensee");
        LicenseAgreement storage license = licenses[licenseId];
        require(license.isActive, "IGV: License is not active");
        require(license.licensee == _licensee, "IGV: Caller is not the licensee for this agreement");

        uint256 expectedRoyalty = _getRoyaltyAmount(
            license.royaltyModel,
            msg.value, // Treat msg.value as the base for royalty calc for this call
            license.royaltyNumerator,
            license.royaltyDenominator,
            _ipTokenId
        );

        require(msg.value >= expectedRoyalty, "IGV: Insufficient royalty payment");

        payable(ipTokenContract.ownerOf(_ipTokenId)).transfer(expectedRoyalty);

        license.lastRoyaltyPaymentBlock = block.number;
        emit RoyaltyPaid(licenseId, _ipTokenId, _licensee, expectedRoyalty);
    }

    /**
     * @dev Allows an IP owner/steward to revoke an active license, subject to contract conditions.
     * This example has simplified revocation conditions.
     * @param _ipTokenId The ID of the IPToken.
     * @param _licensee The address of the licensee whose license is to be revoked.
     */
    function revokeLicense(uint256 _ipTokenId, address _licensee) public onlyIPOwnerOrSteward(_ipTokenId) {
        uint256 licenseId = ipLicenseeToLicenseId[_ipTokenId][_licensee];
        require(licenseId != 0, "IGV: No active license found to revoke");
        LicenseAgreement storage license = licenses[licenseId];
        require(license.isActive, "IGV: License already inactive");

        // Add more complex conditions for revocation here if needed, e.g., duration check, breach.
        // if (license.durationSeconds > 0 && block.timestamp < license.startTime + license.durationSeconds) { ... }

        license.isActive = false;
        delete ipLicenseeToLicenseId[_ipTokenId][_licensee];

        emit LicenseRevoked(licenseId, _ipTokenId);
    }

    // --- III. Dynamic Evolution & Derivation ---

    /**
     * @dev Submits a proposal for a new IP that is derived from an existing parent IP.
     * The proposer must be the parent IP's owner or an authorized steward.
     * @param _parentIpTokenId The ID of the parent IP.
     * @param _evolutionIpHash The content hash of the new derivative IP.
     * @param _evolutionMetadataURI The metadata URI for the new derivative IP.
     */
    function proposeIPEvolution(
        uint256 _parentIpTokenId,
        string memory _evolutionIpHash,
        string memory _evolutionMetadataURI
    ) public onlyIPOwnerOrEvolutionSteward(_parentIpTokenId) nonReentrant {
        require(bytes(_evolutionIpHash).length > 0, "IGV: Evolution IP hash cannot be empty");
        require(bytes(_evolutionMetadataURI).length > 0, "IGV: Evolution metadata URI cannot be empty");
        require(ipVault[_parentIpTokenId].state == IPState.Active, "IGV: Parent IP must be active to propose evolution");

        _evolutionProposalIds.increment();
        uint256 proposalId = _evolutionProposalIds.current();

        evolutionProposals[proposalId] = EvolutionProposal({
            id: proposalId,
            parentIpTokenId: _parentIpTokenId,
            evolutionIpHash: _evolutionIpHash,
            evolutionMetadataURI: _evolutionMetadataURI,
            proposer: msg.sender,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + EVOLUTION_VOTING_DURATION,
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            newIpTokenId: 0
        });

        emit IPEvolutionProposed(proposalId, _parentIpTokenId, msg.sender, _evolutionIpHash);
    }

    /**
     * @dev Allows Impact Credit holders to vote on IP evolution proposals.
     * Voting power is determined by the voter's Impact Credit balance.
     * @param _evolutionProposalId The ID of the evolution proposal.
     * @param _approve True to vote in favor, false to vote against.
     */
    function voteOnIPEvolution(uint256 _evolutionProposalId, bool _approve) public nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionProposalId];
        require(proposal.id != 0, "IGV: Evolution proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime, "IGV: Voting has not started");
        require(block.timestamp < proposal.voteEndTime, "IGV: Voting has ended");
        require(!proposal.finalized, "IGV: Proposal already finalized");
        require(!hasVotedOnEvolution[_evolutionProposalId][msg.sender], "IGV: Already voted on this proposal");

        uint256 voterImpactCredits = impactCreditTokenContract.balanceOf(msg.sender);
        require(voterImpactCredits > 0, "IGV: No voting power (insufficient Impact Credits)");

        if (_approve) {
            proposal.votesFor += voterImpactCredits;
        } else {
            proposal.votesAgainst += voterImpactCredits;
        }
        hasVotedOnEvolution[_evolutionProposalId][msg.sender] = true;

        emit IPEvolutionVoted(_evolutionProposalId, msg.sender, _approve);
    }

    /**
     * @dev Finalizes an evolution proposal if it passes voting, minting a new IIPToken linked to its parent.
     * Any user can call this after the voting period ends.
     * @param _evolutionProposalId The ID of the evolution proposal.
     */
    function finalizeIPEvolution(uint256 _evolutionProposalId) public nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionProposalId];
        require(proposal.id != 0, "IGV: Evolution proposal does not exist");
        require(block.timestamp >= proposal.voteEndTime, "IGV: Voting period not yet ended");
        require(!proposal.finalized, "IGV: Proposal already finalized");

        if (proposal.votesFor > proposal.votesAgainst) {
            _ipTokenIds.increment();
            uint256 newIpId = _ipTokenIds.current();

            ipTokenContract.mint(proposal.proposer, newIpId, proposal.evolutionMetadataURI);

            ipVault[newIpId] = IPData({
                id: newIpId,
                ipHash: proposal.evolutionIpHash,
                metadataURI: proposal.evolutionMetadataURI,
                owner: proposal.proposer, // New IP owner is the proposer
                state: IPState.Active,
                royaltyModel: RoyaltyModelType.Fixed, // Default for new IP
                royaltyNumerator: 0, // Should be set by proposer after mint
                royaltyDenominator: 1,
                parentIpId: proposal.parentIpTokenId,
                bundledIpIds: new uint256[](0)
            });

            proposal.finalized = true;
            proposal.newIpTokenId = newIpId;

            emit IPEvolutionFinalized(_evolutionProposalId, newIpId);
        } else {
            proposal.finalized = true; // Mark as finalized even if rejected
            // Optional: emit an event for rejection.
        }
    }

    /**
     * @dev Allows the proposer of a successful evolution to claim their reward.
     * Rewards are minted as Impact Credits.
     * @param _evolutionProposalId The ID of the evolution proposal.
     */
    function claimEvolutionReward(uint256 _evolutionProposalId) public nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionProposalId];
        require(proposal.proposer == msg.sender, "IGV: Only the proposer can claim rewards");
        require(proposal.finalized, "IGV: Proposal not yet finalized");
        require(proposal.newIpTokenId != 0, "IGV: Proposal was not approved or already claimed");
        
        // This is a simple flag to prevent double claiming.
        // A more robust system would use a dedicated `mapping(uint256 => bool) claimedRewards;`
        proposal.newIpTokenId = 0; // Invalidate to mark as claimed

        uint256 rewardAmount = 100 ether; // Example reward in Impact Credits
        impactCreditTokenContract.mint(msg.sender, rewardAmount);

        emit EvolutionRewardClaimed(_evolutionProposalId, msg.sender, rewardAmount);
    }

    // --- IV. Adaptive Economics & Incentives ---

    /**
     * @dev Stakes FIPTokens for a specific IP to gain influence for that IP and earn Impact Credits.
     * FIPTokens are transferred to the IntellectualGenesisVault contract.
     * @param _ipTokenId The ID of the IP for which FIPs are being staked.
     * @param _amount The amount of FIPTokens to stake.
     */
    function stakeFIPForInfluence(uint256 _ipTokenId, uint256 _amount) public onlyFIPHolder(_amount) nonReentrant {
        require(_amount > 0, "IGV: Amount must be greater than zero");
        require(ipVault[_ipTokenId].id != 0, "IGV: IP does not exist");

        // `_updateAccruedImpactCredits` should be called before changing stake to properly calculate previous rewards.
        _updateAccruedImpactCredits(msg.sender); 

        fipTokenContract.transferFrom(msg.sender, address(this), _amount);

        stakedFIPs[_ipTokenId][msg.sender].amount += _amount;
        stakedFIPs[_ipTokenId][msg.sender].lastClaimBlock = block.number;

        emit FIPStakedForInfluence(_ipTokenId, msg.sender, _amount);
    }

    /**
     * @dev Unstakes FIPTokens, removing their influence and stopping Impact Credit accumulation for the unstaked amount.
     * FIPTokens are returned to the caller.
     * @param _ipTokenId The ID of the IP from which FIPs are being unstaked.
     * @param _amount The amount of FIPTokens to unstake.
     */
    function unstakeFIPFromInfluence(uint256 _ipTokenId, uint256 _amount) public nonReentrant {
        require(_amount > 0, "IGV: Amount must be greater than zero");
        require(stakedFIPs[_ipTokenId][msg.sender].amount >= _amount, "IGV: Insufficient staked FIP for this IP");

        // `_updateAccruedImpactCredits` should be called before changing stake.
        _updateAccruedImpactCredits(msg.sender);

        stakedFIPs[_ipTokenId][msg.sender].amount -= _amount;
        fipTokenContract.transfer(msg.sender, _amount);

        emit FIPUnstakedFromInfluence(_ipTokenId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to claim accumulated Impact Credits.
     * NOTE: This is a highly simplified implementation for demonstration.
     * A real system would have a more complex accrual mechanism, likely calculating credits
     * based on time staked for each IP and potentially other factors.
     */
    function claimImpactCredits() public nonReentrant {
        // For this demo, let's assume a dummy accrual, as robust on-chain calculation
        // for multiple IP stakes and variable duration is gas-intensive.
        // A real system would calculate:
        // uint256 creditsToMint = calculateCreditsForUser(msg.sender);
        // require(creditsToMint > 0, "IGV: No credits to claim");
        
        uint256 dummyCredits = 500; // Example fixed amount
        impactCreditTokenContract.mint(msg.sender, dummyCredits);
        // In a real scenario, this would also reset `lastClaimBlock` for relevant stakes.

        emit ImpactCreditsClaimed(msg.sender, dummyCredits);
    }

    /**
     * @dev Burns Impact Credits to increase the visibility score of an IP (simulated effect).
     * This could, for example, affect how the IP is displayed on a frontend.
     * @param _ipTokenId The ID of the IP to boost.
     * @param _impactCreditsToBurn The amount of Impact Credits to burn.
     */
    function boostIPVisibility(uint256 _ipTokenId, uint256 _impactCreditsToBurn) public onlyImpactCreditHolder(_impactCreditsToBurn) nonReentrant {
        require(_impactCreditsToBurn > 0, "IGV: Must burn a positive amount of credits");
        require(ipVault[_ipTokenId].id != 0, "IGV: IP does not exist");

        impactCreditTokenContract.transferFrom(msg.sender, address(this), _impactCreditsToBurn);
        impactCreditTokenContract.burn(address(this), _impactCreditsToBurn);

        // This would update an actual visibility score mapping:
        // mapping(uint256 => uint256) public ipVisibilityScore;
        // ipVisibilityScore[_ipTokenId] += _impactCreditsToBurn;

        emit IPVisibilityBoosted(_ipTokenId, msg.sender, _impactCreditsToBurn);
    }

    /**
     * @dev Owner/steward defines the specific parameters for an IP's adaptive royalty calculation.
     * This updates the default terms for *new* license proposals for this IP.
     * @param _ipTokenId The ID of the IPToken.
     * @param _model The royalty model type.
     * @param _numerator The numerator for the royalty calculation.
     * @param _denominator The denominator for the royalty calculation.
     */
    function setAdaptiveRoyaltyModel(
        uint256 _ipTokenId,
        RoyaltyModelType _model,
        uint256 _numerator,
        uint256 _denominator
    ) public onlyIPOwnerOrSteward(_ipTokenId) notHibernated(_ipTokenId) {
        require(_denominator > 0, "IGV: Royalty denominator cannot be zero");

        IPData storage ip = ipVault[_ipTokenId];
        ip.royaltyModel = _model;
        ip.royaltyNumerator = _numerator;
        ip.royaltyDenominator = _denominator;

        emit AdaptiveRoyaltyModelUpdated(_ipTokenId, _model, _numerator, _denominator);
    }

    // --- V. Advanced Mechanics & Governance ---

    /**
     * @dev Initiates a formal dispute process related to an IP (e.g., originality claim, license breach).
     * Requires an initial stake of funds (in native currency) to deter frivolous disputes.
     * @param _ipTokenId The ID of the IP in dispute.
     * @param _againstAddress The address of the party against whom the dispute is initiated.
     * @param _disputeReasonURI A URI pointing to the detailed reason for the dispute.
     */
    function initiateIPDispute(
        uint256 _ipTokenId,
        address _againstAddress,
        string memory _disputeReasonURI
    ) public payable nonReentrant {
        require(ipVault[_ipTokenId].id != 0, "IGV: IP does not exist");
        require(_againstAddress != address(0), "IGV: Against address cannot be zero");
        require(_againstAddress != msg.sender, "IGV: Cannot dispute against yourself");
        require(msg.value > 0, "IGV: Must stake funds to initiate dispute");

        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();

        disputes[disputeId] = Dispute({
            id: disputeId,
            ipTokenId: _ipTokenId,
            initiator: msg.sender,
            againstAddress: _againstAddress,
            disputeReasonURI: _disputeReasonURI,
            evidenceURIs: new string[](0), // Evidence will be added later
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + DISPUTE_VOTING_DURATION,
            votesForInitiator: 0,
            votesForAgainst: 0,
            resolved: false,
            initiatorWins: false, // Default until resolved
            stakedFunds: msg.value
        });

        emit IPDisputeInitiated(disputeId, _ipTokenId, msg.sender, _againstAddress);
    }

    /**
     * @dev Allows parties involved in a dispute (initiator or againstAddress) to submit evidence.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceURI A URI pointing to the evidence document or file.
     */
    function submitDisputeEvidence(uint256 _disputeId, string memory _evidenceURI) public {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "IGV: Dispute does not exist");
        require(msg.sender == dispute.initiator || msg.sender == dispute.againstAddress, "IGV: Not a party to this dispute");
        require(!dispute.resolved, "IGV: Dispute already resolved");
        require(bytes(_evidenceURI).length > 0, "IGV: Evidence URI cannot be empty");

        dispute.evidenceURIs.push(_evidenceURI);
        emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
    }

    /**
     * @dev Enables Impact Credit holders to vote on dispute outcomes.
     * Voting power is determined by the voter's Impact Credit balance.
     * @param _disputeId The ID of the dispute.
     * @param _verdict True if voting for the initiator to win, false if voting for the party against.
     */
    function voteOnDispute(uint256 _disputeId, bool _verdict) public nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "IGV: Dispute does not exist");
        require(block.timestamp >= dispute.voteStartTime, "IGV: Voting has not started");
        require(block.timestamp < dispute.voteEndTime, "IGV: Voting has ended");
        require(!dispute.resolved, "IGV: Dispute already resolved");
        require(!hasVotedOnDispute[_disputeId][msg.sender], "IGV: Already voted on this dispute");

        uint256 voterImpactCredits = impactCreditTokenContract.balanceOf(msg.sender);
        require(voterImpactCredits > 0, "IGV: No voting power (insufficient Impact Credits)");

        if (_verdict) {
            dispute.votesForInitiator += voterImpactCredits;
        } else {
            dispute.votesForAgainst += voterImpactCredits;
        }
        hasVotedOnDispute[_disputeId][msg.sender] = true;
        emit DisputeVoted(_disputeId, msg.sender, _verdict);
    }

    /**
     * @dev Finalizes a dispute based on voting, potentially transferring funds or ownership.
     * Any user can call this after the voting period ends.
     * @param _disputeId The ID of the dispute.
     */
    function resolveDispute(uint256 _disputeId) public nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "IGV: Dispute does not exist");
        require(block.timestamp >= dispute.voteEndTime, "IGV: Voting period not yet ended");
        require(!dispute.resolved, "IGV: Dispute already resolved");

        dispute.resolved = true;
        if (dispute.votesForInitiator > dispute.votesForAgainst) {
            dispute.initiatorWins = true;
            // Transfer staked funds to initiator as they won
            payable(dispute.initiator).transfer(dispute.stakedFunds);
        } else if (dispute.votesForAgainst > dispute.votesForInitiator) {
            dispute.initiatorWins = false;
            // If initiator loses, their staked funds are not returned. They could go to the 'againstAddress'
            // or a community treasury. For simplicity here, they remain in the contract (effectively 'burned'
            // or available for governance to sweep).
        } else {
            // Tie or no votes, default to initiator loses or return funds to both.
            // Here, we decide initiator loses if no clear majority. Funds remain in contract.
            dispute.initiatorWins = false;
        }
        emit DisputeResolved(_disputeId, dispute.initiatorWins);
    }

    /**
     * @dev Combines multiple IIPTokens into a single new "MetaIPToken" (a new IIPToken representing the bundle).
     * Requires the caller to own all listed IPs. The constituent IPs are transferred to the vault's custody.
     * @param _ipTokenIds An array of IPToken IDs to bundle.
     * @param _bundleMetadataURI A URI for the metadata of the new bundled IP.
     * @return The ID of the newly created bundle IP.
     */
    function bundleIPs(uint256[] memory _ipTokenIds, string memory _bundleMetadataURI) public nonReentrant returns (uint256) {
        require(_ipTokenIds.length >= 2, "IGV: Must bundle at least two IPs");
        require(bytes(_bundleMetadataURI).length > 0, "IGV: Bundle metadata URI cannot be empty");

        // Transfer all constituent IPs to the vault
        for (uint256 i = 0; i < _ipTokenIds.length; i++) {
            require(ipTokenContract.ownerOf(_ipTokenIds[i]) == msg.sender, "IGV: Not owner of one of the IPs to bundle");
            require(ipVault[_ipTokenIds[i]].state == IPState.Active, "IGV: Can only bundle active IPs");
            ipTokenContract.transferFrom(msg.sender, address(this), _ipTokenIds[i]);
            // Optionally, change state of bundled IPs to `Archived` or `Bundled`
        }

        _ipTokenIds.increment();
        uint256 newBundleIpId = _ipTokenIds.current();

        ipTokenContract.mint(msg.sender, newBundleIpId, _bundleMetadataURI);

        ipVault[newBundleIpId] = IPData({
            id: newBundleIpId,
            ipHash: "", // Bundles may not have a single content hash; metadata URI is primary
            metadataURI: _bundleMetadataURI,
            owner: msg.sender,
            state: IPState.Active,
            royaltyModel: RoyaltyModelType.Fixed, // Default for bundles
            royaltyNumerator: 0, // Should be set by owner after mint
            royaltyDenominator: 1,
            parentIpId: 0,
            bundledIpIds: _ipTokenIds // Store the IDs of the bundled IPs
        });

        emit IPsBundled(newBundleIpId, msg.sender, _ipTokenIds);
        return newBundleIpId;
    }

    /**
     * @dev Disassembles a "MetaIPToken" back into its constituent IIPTokens.
     * Requires the caller to own the bundle IPToken. The constituent IPs are returned to the caller.
     * The bundle IPToken is burned.
     * @param _bundleIpTokenId The ID of the bundled IPToken.
     */
    function unbundleIPs(uint256 _bundleIpTokenId) public onlyIPOwner(_bundleIpTokenId) nonReentrant {
        IPData storage bundle = ipVault[_bundleIpTokenId];
        require(bundle.bundledIpIds.length > 0, "IGV: This IP is not a bundle");

        // Transfer all constituent IPs back to the caller
        for (uint256 i = 0; i < bundle.bundledIpIds.length; i++) {
            uint256 constituentIpId = bundle.bundledIpIds[i];
            require(ipTokenContract.ownerOf(constituentIpId) == address(this), "IGV: Constituent IP not held by vault");
            ipTokenContract.transferFrom(address(this), msg.sender, constituentIpId);
            // Optionally, revert state of unbundled IPs to `Active` or previous state
        }

        // Burn the bundle IPToken itself
        ipTokenContract.transferFrom(msg.sender, address(0), _bundleIpTokenId); // Sending to 0x0 burns the NFT

        // Clear bundle data from storage
        delete ipVault[_bundleIpTokenId];

        emit IPsUnbundled(_bundleIpTokenId, msg.sender, bundle.bundledIpIds);
    }
}
```