```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
* AetherForge: Decentralized Autonomous Intellectual Property (DAIP) Registry & Monetization Platform
*
* This contract facilitates the registration, licensing, and monetization of unique, AI-generated
* or AI-assisted intellectual property (IP). It introduces a novel ecosystem for creators,
* licensees, and community curators, built upon advanced blockchain concepts:
*
* - **Soulbound Token (SBT) Emulation for IP Ownership:** Original IP ownership is represented by an internally
*   managed non-transferable token, ensuring permanent attribution to the creator.
* - **Dynamic NFT Emulation for Licenses:** License agreements are represented as NFTs that can evolve
*   (e.g., status changes, royalty accrual, renewals) and are transferable, enabling secondary markets for licenses.
* - **AI Oracle Integration:** Designed to interact with a trusted off-chain AI oracle for assessing IP uniqueness,
*   critical for valuing AI-generated content.
* - **Decentralized Curation & Arbitration:** A staking-based system allowing community 'AetherCurators'
*   to resolve disputes regarding IP uniqueness, license breaches, or revocations, ensuring fair play.
* - **Automated Royalty Distribution:** Smart contracts automatically calculate and facilitate the
*   distribution of royalties from reported revenue to IP owners.
* - **AI-Assisted Generative Bounties:** A mechanism for users to commission specific AI-generated content,
*   with a built-in escrow system for rewards upon fulfillment and approval.
* - **Reputation System:** Tracks and assigns reputation scores to participants (creators, licensees, curators)
*   based on their activities, compliance, and dispute outcomes, fostering trust within the ecosystem.
*
* Outline:
* I. Core IP Registry & Creator (AetherSoul SBT Emulation)
* II. Licensing & Monetization (AetherLicense Dynamic NFT Emulation)
* III. Curation & Arbitration (ForgeToken Staking)
* IV. AI-Assisted Generation & Bounties
* V. Reputation System
*
* Function Summary:
* I. Core IP Registry & Creator:
* 1.  `registerAetherIP(bytes32 ipHash, string metadataURI, bytes32 aiProofHash, uint256 uniquenessScore)`: Registers new IP, mints an AetherSoul (SBT) for the creator.
* 2.  `getAetherIPDetails(uint256 ipId)`: Retrieves comprehensive details for a registered IP.
* 3.  `verifyAetherIPSoul(address owner, uint256 ipId)`: Confirms if an address is the original owner of an IP's Soulbound Token.
* 4.  `updateAetherIPMetadata(uint256 ipId, string newMetadataURI)`: Allows the IP owner to update the associated metadata URI.
* 5.  `setAetherIPUniquenessScore(uint256 ipId, uint256 newScore)`: (Oracle-gated) Sets or updates the uniqueness score for an IP, crucial for AI-generated content assessment.
*
* II. Licensing & Monetization:
* 6.  `createLicenseTemplate(string name, uint256 defaultRoyaltyRateBPS, uint256 durationDays, bytes32[] permittedUsesHashes)`: Defines reusable templates for common license terms and royalty structures.
* 7.  `mintAetherLicense(uint256 ipId, address licensee, uint256 templateId, string customTermsURI, uint256 upfrontFee)`: Issues a new, dynamic AetherLicense NFT for a specific IP and licensee, requiring an upfront fee.
* 8.  `revokeAetherLicense(uint256 licenseId, string reasonURI)`: Allows the IP owner to revoke an active license under specified conditions (potentially leading to a dispute).
* 9.  `recordRevenue(uint256 licenseId, uint256 amount)`: Licensees report revenue generated, triggering royalty calculation and accrual.
* 10. `distributeRoyalties(uint256 licenseId)`: Initiates the payout of accrued royalties to the IP owner. Callable by anyone to push royalties.
* 11. `getLicenseDetails(uint256 licenseId)`: Provides detailed information about a specific license NFT.
* 12. `renewAetherLicense(uint256 licenseId, uint256 newUpfrontFee)`: Allows a licensee to extend the term of an expiring license, requiring a new upfront fee.
* 13. `amendLicenseTerms(uint256 licenseId, string newCustomTermsURI)`: Facilitates the mutual agreement and update of license terms between parties (simplified to IP owner updating URI).
*
* III. Curation & Arbitration:
* 14. `stakeForCuratorRole(uint256 amount)`: Allows users to stake ForgeTokens to become AetherCurators, enabling participation in dispute resolution.
* 15. `unstakeFromCuratorRole()`: Initiates the unstaking process for a curator, subject to a cool-down period.
* 16. `completeUnstaking()`: Finalizes the unstaking process after the cool-down period.
* 17. `submitDispute(uint256 licenseId, uint256 ipId, DisputeType disputeType, string evidenceURI)`: Enables IP owners, licensees, or curators to formally lodge a dispute.
* 18. `voteOnDispute(uint256 disputeId, VoteOption voteOption)`: AetherCurators participate in dispute resolution by casting their weighted votes based on their stake.
* 19. `resolveDispute(uint256 disputeId)`: Finalizes a dispute based on curator votes, applying penalties or rewards and updating license/IP status.
* 20. `slashCurator(address curator, uint256 amount, string reasonURI)`: (Governance/automated) Penalizes a curator for malicious or incorrect actions, sending slashed tokens to the contract owner.
*
* IV. AI-Assisted Bounties:
* 21. `createAIBounty(string promptURI, uint256 rewardAmount, uint256 deadline)`: Users post bounties for creators to generate specific AI content, with the reward held in escrow.
* 22. `submitAIBountyFulfillment(uint256 bountyId, bytes32 ipHash, string metadataURI, bytes32 aiProofHash, uint256 uniquenessScore)`: Creators submit their AI-generated IP to fulfill a bounty, internally registering it.
* 23. `approveAIBountyFulfillment(uint256 bountyId, uint256 ipId)`: The bounty creator approves the submitted IP, releasing the reward to the fulfiller.
* 24. `rejectAIBountyFulfillment(uint252 bountyId, string reasonURI)`: The bounty creator rejects a submission, potentially refunding the bounty or allowing resubmission.
*
* V. Reputation System:
* 25. `getReputationScore(address participant)`: Retrieves the accumulated reputation score for a given participant, reflecting their activity and reliability.
*
* This contract serves as a foundational layer for a sophisticated ecosystem designed for the
* emerging domain of AI-generated and AI-assisted intellectual property.
*/

// Interface for ForgeToken (assuming it's an external ERC20 contract)
interface IForgeToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract AetherForge is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Constants ---
    uint256 public constant ROYALTIES_PRECISION = 10000; // 100% = 10000 BPS (Basis Points)
    uint256 public constant CURATOR_STAKE_LOCKUP_DAYS = 30; // Days to lock tokens after unstake request
    uint256 public constant DISPUTE_VOTING_DAYS = 7; // Days for curators to vote on a dispute

    // --- External Contract Addresses ---
    address public forgeTokenAddress;     // ERC20 token used for staking and governance (IForgeToken)
    address public trustedOracleAddress;  // Address for the AI uniqueness oracle

    // --- Counters for unique IDs ---
    Counters.Counter private _ipIds;
    Counters.Counter private _licenseTemplateIds;
    Counters.Counter private _licenseIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _bountyIds;

    // --- Structs ---

    // I. Core IP Registry & Creator (AetherSoul SBT Emulation)
    struct AetherIP {
        uint256 ipId;                   // Unique identifier for the IP
        address owner;                  // The original creator/owner of the IP (non-transferable SBT owner)
        bytes32 ipHash;                 // Cryptographic hash of the core IP content/identifier
        string metadataURI;             // URI pointing to off-chain metadata (description, image, etc.)
        bytes32 aiProofHash;            // Hash of AI model parameters, prompt, seed, or generation process
        uint256 uniquenessScore;        // Score from trusted oracle indicating uniqueness (e.g., 0-10000)
        uint256 registrationTimestamp;  // Timestamp of registration
        bool isBountyFulfillment;       // True if this IP was created to fulfill a bounty
        uint256 bountyId;               // If isBountyFulfillment, the ID of the bounty
    }
    mapping(uint256 => AetherIP) public aetherIPs;
    mapping(address => uint256[]) public ownerToAetherIPs; // Helper for retrieving an owner's IPs

    // II. Licensing & Monetization (AetherLicense Dynamic NFT Emulation)
    enum LicenseStatus { Active, Revoked, Expired, Dispute }
    struct LicenseTemplate {
        uint256 templateId;             // Unique ID for the template
        string name;                    // Name of the template (e.g., "Standard Commercial License")
        uint256 defaultRoyaltyRateBPS;  // Default royalty rate in basis points (e.g., 500 = 5%)
        uint256 durationDays;           // Default duration in days (0 for perpetual)
        bytes32[] permittedUsesHashes;  // Hashes representing permitted use cases (e.g., "PRINT_USE", "DIGITAL_AD")
    }
    mapping(uint256 => LicenseTemplate) public licenseTemplates;

    struct AetherLicense {
        uint256 licenseId;              // Unique identifier for this license (NFT ID)
        uint256 ipId;                   // The IP being licensed
        address owner;                  // The current owner of this AetherLicense NFT (transferable)
        address originalLicensee;       // The initial licensee (who minted it)
        uint256 templateId;             // The template used for this license
        string customTermsURI;          // URI pointing to specific, custom terms for this license
        uint256 startTime;              // License start timestamp
        uint256 endTime;                // License end timestamp (0 for perpetual if durationDays is 0)
        LicenseStatus status;           // Current status of the license
        uint256 accruedRoyalties;       // Royalties accumulated for the IP owner, awaiting distribution
        uint256 royaltyRateBPS;         // Actual royalty rate for this specific license
        uint256 lastRevenueReportTime;  // Last time revenue was reported for this license
        bytes32[] permittedUsesHashes;  // Specific permitted uses for this license
    }
    mapping(uint256 => AetherLicense) public aetherLicenses;
    mapping(uint256 => uint256[]) public ipIdToActiveLicenses; // Track active licenses per IP

    // III. Curation & Arbitration (ForgeToken Staking)
    struct Curator {
        uint256 stakedAmount;           // Amount of ForgeToken staked
        uint256 unstakeRequestTime;     // Timestamp when unstake was requested (0 if not requested)
        uint256 totalVotesCast;         // Total disputes voted on
        uint256 correctVotes;           // Number of correct votes (based on final dispute outcome, for reputation)
    }
    mapping(address => Curator) public curators;
    mapping(address => bool) public isCurator;

    enum DisputeType { LicenseRevocation, NonPayment, BreachOfTerms, IPUniqueness }
    enum DisputeStatus { Open, Voting, Resolved, Canceled }
    enum VoteOption { Abstain, Yes, No } // Yes usually for submitter, No for defendant
    struct Dispute {
        uint256 disputeId;              // Unique ID for the dispute
        uint256 licenseId;              // The license in question (0 if IPUniqueness)
        uint256 ipId;                   // The IP in question (for IPUniqueness or as context)
        address submitter;              // Address who initiated the dispute
        address defendant;              // Address being disputed against
        DisputeType disputeType;        // Type of dispute
        string evidenceURI;             // URI pointing to off-chain evidence
        DisputeStatus status;           // Current status of the dispute
        uint256 votingDeadline;         // Timestamp when voting ends
        uint256 totalWeightVoted;       // Sum of staked amounts of all curators who voted
        uint256 yesWeight;              // Sum of staked amounts of curators who voted 'Yes'
        uint256 noWeight;               // Sum of staked amounts of curators who voted 'No'
        mapping(address => bool) hasVoted; // Tracks if a curator has voted on this dispute
        address[] voters;               // List of addresses who voted (for later processing)
    }
    mapping(uint256 => Dispute) public disputes;

    // IV. AI-Assisted Bounties
    enum BountyStatus { Open, Fulfilled, Approved, Rejected, Expired }
    struct AIBounty {
        uint256 bountyId;               // Unique ID for the bounty
        address creator;                // Address who created the bounty
        string promptURI;               // URI for the detailed AI prompt/specifications
        uint256 rewardAmount;           // Amount of ETH (or native currency) as reward
        uint256 deadline;               // Deadline for fulfillment
        uint256 fulfillmentIpId;        // The IP ID registered as fulfillment (0 if not fulfilled)
        address fulfiller;              // The creator who fulfilled the bounty
        BountyStatus status;            // Current status of the bounty
    }
    mapping(uint256 => AIBounty) public aiBounties;

    // V. Reputation System
    mapping(address => int256) public reputationScores; // Using int256 for potential negative scores

    // --- Events ---
    event AetherIPRegistered(uint256 indexed ipId, address indexed owner, bytes32 ipHash, string metadataURI);
    event IPUniquenessScoreUpdated(uint256 indexed ipId, uint256 newScore);

    event LicenseTemplateCreated(uint256 indexed templateId, string name, uint256 defaultRoyaltyRateBPS);
    event AetherLicenseMinted(uint252 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 upfrontFee);
    event AetherLicenseRevoked(uint256 indexed licenseId, uint256 indexed ipId, address indexed revoker, string reasonURI);
    event RoyaltiesRecorded(uint256 indexed licenseId, uint256 ipId, uint256 amountReported, uint256 royaltiesAccrued);
    event RoyaltiesDistributed(uint256 indexed licenseId, uint252 ipId, uint256 amountDistributed);
    event AetherLicenseRenewed(uint256 indexed licenseId, uint256 newUpfrontFee, uint256 newEndTime);
    event LicenseTermsAmended(uint256 indexed licenseId, string newCustomTermsURI);

    event CuratorStaked(address indexed curator, uint256 amount);
    event CuratorUnstakeRequested(address indexed curator, uint256 amount, uint256 requestTime);
    event CuratorUnstaked(address indexed curator, uint256 amount);
    event DisputeSubmitted(uint256 indexed disputeId, uint256 indexed licenseId, address indexed submitter, DisputeType disputeType);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, VoteOption vote);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus finalStatus, uint256 winningWeight);
    event CuratorSlashed(address indexed curator, uint256 amount, string reasonURI);

    event AIBountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, uint256 deadline);
    event AIBountyFulfilled(uint256 indexed bountyId, uint256 indexed ipId, address indexed fulfiller);
    event AIBountyApproved(uint256 indexed bountyId, uint256 indexed ipId, address indexed approver);
    event AIBountyRejected(uint256 indexed bountyId, address indexed rejector, string reasonURI);

    event ReputationUpdated(address indexed participant, int256 newScore);

    // --- Constructor ---
    constructor(address _forgeTokenAddress, address _trustedOracleAddress) Ownable(msg.sender) {
        require(_forgeTokenAddress != address(0), "ForgeToken address cannot be zero");
        require(_trustedOracleAddress != address(0), "Oracle address cannot be zero");
        forgeTokenAddress = _forgeTokenAddress;
        trustedOracleAddress = _trustedOracleAddress;

        // Initialize a default license template
        _licenseTemplateIds.increment(); // templateId 1
        licenseTemplates[1] = LicenseTemplate(
            1,
            "Basic Non-Exclusive",
            1000, // 10% royalty rate
            365,  // 1 year duration
            new bytes32[](0) // No specific permitted uses required
        );
        emit LicenseTemplateCreated(1, "Basic Non-Exclusive", 1000);
    }

    // --- Modifiers ---
    modifier onlyCurator() {
        require(isCurator[msg.sender], "Caller is not an AetherCurator");
        _;
    }

    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracleAddress, "Caller is not the trusted oracle");
        _;
    }

    modifier onlyIpOwner(uint256 _ipId) {
        require(aetherIPs[_ipId].ipId != 0, "Invalid IP ID");
        require(aetherIPs[_ipId].owner == msg.sender, "Caller is not the IP owner");
        _;
    }

    modifier onlyLicensee(uint256 _licenseId) {
        require(aetherLicenses[_licenseId].licenseId != 0, "Invalid license ID");
        require(aetherLicenses[_licenseId].owner == msg.sender, "Caller is not the license owner");
        _;
    }

    modifier notExpired(uint256 _licenseId) {
        AetherLicense storage license = aetherLicenses[_licenseId];
        require(license.licenseId != 0, "Invalid license ID");
        require(license.endTime == 0 || block.timestamp < license.endTime, "License has expired");
        _;
    }

    // --- Admin Functions (Ownable) ---
    function setForgeTokenAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "New address cannot be zero");
        forgeTokenAddress = _newAddress;
    }

    function setTrustedOracleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "New address cannot be zero");
        trustedOracleAddress = _newAddress;
    }

    // --- I. Core IP Registry & Creator (AetherSoul SBT Emulation) ---

    /// @notice Registers a new AI-generated or AI-assisted intellectual property (IP).
    ///         Mints an AetherSoul (SBT) representing ownership to the caller.
    /// @param ipHash Cryptographic hash of the core IP content/identifier.
    /// @param metadataURI URI pointing to off-chain metadata (description, image, etc.).
    /// @param aiProofHash Hash of AI model parameters, prompt, seed, or generation process.
    /// @param uniquenessScore Score from trusted oracle indicating uniqueness (e.g., 0-10000).
    /// @return The ID of the newly registered IP.
    function registerAetherIP(bytes32 ipHash, string memory metadataURI, bytes32 aiProofHash, uint256 uniquenessScore)
        public
        nonReentrant
        returns (uint256)
    {
        _ipIds.increment();
        uint256 newIpId = _ipIds.current();

        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
        // Additional checks for ipHash uniqueness or format can be added here.

        aetherIPs[newIpId] = AetherIP({
            ipId: newIpId,
            owner: msg.sender,
            ipHash: ipHash,
            metadataURI: metadataURI,
            aiProofHash: aiProofHash,
            uniquenessScore: uniquenessScore,
            registrationTimestamp: block.timestamp,
            isBountyFulfillment: false,
            bountyId: 0
        });

        ownerToAetherIPs[msg.sender].push(newIpId); // For easier lookup of user's IPs

        // AetherSoul (SBT) is implicitly minted here to the msg.sender as the IP owner.
        // `aetherIPs[newIpId].owner` serves as the SBT ownership.

        emit AetherIPRegistered(newIpId, msg.sender, ipHash, metadataURI);
        _updateReputation(msg.sender, 10); // Reward for contributing new IP
        return newIpId;
    }

    /// @notice Retrieves comprehensive details for a registered IP.
    /// @param _ipId The ID of the IP.
    /// @return AetherIP struct containing all details.
    function getAetherIPDetails(uint256 _ipId) public view returns (AetherIP memory) {
        require(_ipId > 0 && _ipId <= _ipIds.current(), "Invalid IP ID");
        return aetherIPs[_ipId];
    }

    /// @notice Verifies if an address is the original owner of an IP's Soulbound Token.
    /// @param _owner The address to check.
    /// @param _ipId The ID of the IP.
    /// @return True if the address is the original owner, false otherwise.
    function verifyAetherIPSoul(address _owner, uint256 _ipId) public view returns (bool) {
        require(_ipId > 0 && _ipId <= _ipIds.current(), "Invalid IP ID");
        return aetherIPs[_ipId].owner == _owner;
    }

    /// @notice Allows the IP owner to update the associated metadata URI.
    /// @param _ipId The ID of the IP.
    /// @param _newMetadataURI The new URI for the metadata.
    function updateAetherIPMetadata(uint256 _ipId, string memory _newMetadataURI)
        public
        onlyIpOwner(_ipId)
    {
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty");
        aetherIPs[_ipId].metadataURI = _newMetadataURI;
        // Consider an event here if updates are crucial for off-chain systems.
    }

    /// @notice (Oracle-gated) Sets or updates the uniqueness score for an IP, usually post-registration.
    /// @param _ipId The ID of the IP.
    /// @param _newScore The new uniqueness score from the oracle (e.g., 0-10000).
    function setAetherIPUniquenessScore(uint256 _ipId, uint256 _newScore)
        public
        onlyTrustedOracle
    {
        require(_ipId > 0 && _ipId <= _ipIds.current(), "Invalid IP ID");
        aetherIPs[_ipId].uniquenessScore = _newScore;
        emit IPUniquenessScoreUpdated(_ipId, _newScore);
    }

    // --- II. Licensing & Monetization (AetherLicense Dynamic NFT Emulation) ---

    /// @notice Defines reusable templates for common license terms and royalty structures.
    /// @param name Descriptive name for the template.
    /// @param defaultRoyaltyRateBPS Default royalty rate in basis points (e.g., 500 = 5%).
    /// @param durationDays Default duration in days (0 for perpetual).
    /// @param permittedUsesHashes Hashes representing permitted use cases (e.g., "PRINT_USE", "DIGITAL_AD").
    /// @return The ID of the newly created license template.
    function createLicenseTemplate(
        string memory name,
        uint256 defaultRoyaltyRateBPS,
        uint256 durationDays,
        bytes32[] memory permittedUsesHashes
    ) public onlyOwner returns (uint256) {
        require(defaultRoyaltyRateBPS <= ROYALTIES_PRECISION, "Royalty rate cannot exceed 100%");
        _licenseTemplateIds.increment();
        uint256 newTemplateId = _licenseTemplateIds.current();

        licenseTemplates[newTemplateId] = LicenseTemplate({
            templateId: newTemplateId,
            name: name,
            defaultRoyaltyRateBPS: defaultRoyaltyRateBPS,
            durationDays: durationDays,
            permittedUsesHashes: permittedUsesHashes
        });
        emit LicenseTemplateCreated(newTemplateId, name, defaultRoyaltyRateBPS);
        return newTemplateId;
    }

    /// @notice Issues a new, dynamic AetherLicense NFT for a specific IP and licensee.
    ///         Requires upfront payment in native currency (ETH).
    /// @param _ipId The ID of the IP to be licensed.
    /// @param _licensee The address of the licensee (owner of the AetherLicense NFT).
    /// @param _templateId The ID of the license template to use.
    /// @param _customTermsURI URI pointing to specific, custom terms for this license (overrides template if provided).
    /// @param _upfrontFee The upfront fee paid by the licensee (in native currency).
    /// @return The ID of the newly minted AetherLicense NFT.
    function mintAetherLicense(
        uint256 _ipId,
        address _licensee,
        uint256 _templateId,
        string memory _customTermsURI,
        uint256 _upfrontFee
    ) public payable onlyIpOwner(_ipId) nonReentrant returns (uint256) {
        require(_licensee != address(0), "Licensee address cannot be zero");
        require(msg.value == _upfrontFee, "Incorrect upfront fee sent");
        require(licenseTemplates[_templateId].templateId != 0, "Invalid license template ID");

        // Transfer upfront fee to IP owner
        payable(aetherIPs[_ipId].owner).transfer(_upfrontFee);

        LicenseTemplate storage template = licenseTemplates[_templateId];

        _licenseIds.increment();
        uint256 newLicenseId = _licenseIds.current();

        uint256 endTime = 0; // 0 for perpetual
        if (template.durationDays > 0) {
            endTime = block.timestamp + (template.durationDays * 1 days);
        }

        aetherLicenses[newLicenseId] = AetherLicense({
            licenseId: newLicenseId,
            ipId: _ipId,
            owner: _licensee, // The owner of the NFT is the licensee
            originalLicensee: _licensee,
            templateId: _templateId,
            customTermsURI: _customTermsURI,
            startTime: block.timestamp,
            endTime: endTime,
            status: LicenseStatus.Active,
            accruedRoyalties: 0,
            royaltyRateBPS: template.defaultRoyaltyRateBPS,
            lastRevenueReportTime: block.timestamp,
            permittedUsesHashes: template.permittedUsesHashes // Can be customized later
        });

        ipIdToActiveLicenses[_ipId].push(newLicenseId);
        // AetherLicense is implicitly minted here. Ownership tracked by `aetherLicenses[newLicenseId].owner`.

        emit AetherLicenseMinted(newLicenseId, _ipId, _licensee, _upfrontFee);
        _updateReputation(_licensee, 5); // Reward licensee for acquiring license
        return newLicenseId;
    }

    /// @notice Allows the IP owner to revoke an active license under specified conditions.
    ///         This might trigger a dispute if contested.
    /// @param _licenseId The ID of the license to revoke.
    /// @param _reasonURI URI pointing to the reason and evidence for revocation.
    function revokeAetherLicense(uint256 _licenseId, string memory _reasonURI)
        public
        onlyIpOwner(aetherLicenses[_licenseId].ipId)
        nonReentrant
    {
        AetherLicense storage license = aetherLicenses[_licenseId];
        require(license.licenseId != 0, "Invalid license ID");
        require(license.status == LicenseStatus.Active, "License not active");
        // In a real system, revocation conditions (e.g., breach of terms) would be checked.
        // For simplicity, this acts as a direct revocation for now, but can be disputed by licensee.

        license.status = LicenseStatus.Revoked; // Set to revoked immediately, but subject to dispute
        emit AetherLicenseRevoked(_licenseId, license.ipId, msg.sender, _reasonURI);
        // Reputation penalties/rewards will be adjusted by dispute resolution if contested.
    }

    /// @notice Licensees report revenue generated from the licensed IP.
    ///         Triggers calculation and accrual of royalties.
    /// @param _licenseId The ID of the license.
    /// @param _amount The gross revenue amount (in native currency).
    function recordRevenue(uint256 _licenseId, uint256 _amount)
        public
        onlyLicensee(_licenseId)
        nonReentrant
        notExpired(_licenseId)
    {
        AetherLicense storage license = aetherLicenses[_licenseId];
        require(license.status == LicenseStatus.Active, "License not active");
        require(_amount > 0, "Revenue amount must be greater than zero");

        uint256 royaltiesDue = _amount.mul(license.royaltyRateBPS).div(ROYALTIES_PRECISION);
        license.accruedRoyalties = license.accruedRoyalties.add(royaltiesDue);
        license.lastRevenueReportTime = block.timestamp;

        emit RoyaltiesRecorded(_licenseId, license.ipId, _amount, royaltiesDue);
        _updateReputation(msg.sender, 2); // Reward for reporting revenue
    }

    /// @notice Initiates the payout of accrued royalties to the IP owner.
    ///         Callable by anyone to push royalties.
    /// @param _licenseId The ID of the license.
    function distributeRoyalties(uint256 _licenseId) public nonReentrant {
        AetherLicense storage license = aetherLicenses[_licenseId];
        require(license.licenseId != 0, "Invalid license ID");
        require(license.accruedRoyalties > 0, "No royalties to distribute");

        address ipOwner = aetherIPs[license.ipId].owner;
        uint256 amountToDistribute = license.accruedRoyalties;
        license.accruedRoyalties = 0; // Reset accrued royalties

        // Transfer ETH (native currency) to the IP owner
        payable(ipOwner).transfer(amountToDistribute);

        emit RoyaltiesDistributed(_licenseId, license.ipId, amountToDistribute);
        _updateReputation(ipOwner, 3); // Reward for receiving royalties
    }

    /// @notice Allows a licensee to extend the term of an expiring license.
    ///         Requires a new upfront fee.
    /// @param _licenseId The ID of the license to renew.
    /// @param _newUpfrontFee The new upfront fee for renewal (in native currency).
    function renewAetherLicense(uint256 _licenseId, uint256 _newUpfrontFee)
        public
        payable
        onlyLicensee(_licenseId)
        nonReentrant
    {
        AetherLicense storage license = aetherLicenses[_licenseId];
        require(license.licenseId != 0, "Invalid license ID");
        require(license.status == LicenseStatus.Active || license.endTime < block.timestamp, "License not active or already expired for too long");
        require(msg.value == _newUpfrontFee, "Incorrect upfront fee sent for renewal");
        require(_newUpfrontFee > 0, "Renewal fee must be greater than zero");

        // Transfer renewal fee to IP owner
        payable(aetherIPs[license.ipId].owner).transfer(_newUpfrontFee);

        // Determine new end time based on original duration or a new agreed duration
        uint256 newDurationDays = licenseTemplates[license.templateId].durationDays;
        uint256 newEndTime;
        if (newDurationDays == 0) { // Perpetual license
            newEndTime = 0;
        } else {
            // If expired, renew from now. If active, extend from current endTime.
            uint256 baseTime = (license.endTime == 0 || block.timestamp < license.endTime) ? block.timestamp : license.endTime;
            newEndTime = baseTime + (newDurationDays * 1 days);
        }

        license.endTime = newEndTime;
        license.status = LicenseStatus.Active; // Reactivate if it was expired
        emit AetherLicenseRenewed(_licenseId, _newUpfrontFee, newEndTime);
        _updateReputation(msg.sender, 5); // Reward for renewing license
    }

    /// @notice Facilitates the mutual agreement and update of license terms between parties.
    ///         For simplicity, this version allows only the IP owner to update the URI,
    ///         assuming off-chain negotiation. A more advanced version would use multisig or signatures.
    /// @param _licenseId The ID of the license to amend.
    /// @param _newCustomTermsURI The URI pointing to the new custom terms.
    function amendLicenseTerms(uint256 _licenseId, string memory _newCustomTermsURI)
        public
        onlyIpOwner(aetherLicenses[_licenseId].ipId) // Only IP owner can initiate, implies off-chain agreement
        nonReentrant
    {
        AetherLicense storage license = aetherLicenses[_licenseId];
        require(license.licenseId != 0, "Invalid license ID");
        require(license.status == LicenseStatus.Active, "License not active");
        require(bytes(_newCustomTermsURI).length > 0, "New custom terms URI cannot be empty");

        license.customTermsURI = _newCustomTermsURI;
        emit LicenseTermsAmended(_licenseId, _newCustomTermsURI);
        // Reputation update for both parties could be added here if off-chain signature verification was implemented.
    }

    // --- III. Curation & Arbitration (ForgeToken Staking) ---

    /// @notice Allows users to stake ForgeTokens to become AetherCurators.
    /// @param _amount The amount of ForgeToken to stake.
    function stakeForCuratorRole(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Stake amount must be greater than zero");
        IERC20 forgeToken = IERC20(forgeTokenAddress);
        require(forgeToken.transferFrom(msg.sender, address(this), _amount), "ForgeToken transfer failed");

        curators[msg.sender].stakedAmount = curators[msg.sender].stakedAmount.add(_amount);
        isCurator[msg.sender] = true;
        emit CuratorStaked(msg.sender, _amount);
        _updateReputation(msg.sender, 20); // Reward for becoming a curator
    }

    /// @notice Initiates the unstaking process, subject to a cool-down.
    function unstakeFromCuratorRole() public nonReentrant {
        Curator storage curator = curators[msg.sender];
        require(curator.stakedAmount > 0, "No tokens staked to unstake");
        require(curator.unstakeRequestTime == 0, "Unstake already requested");

        curator.unstakeRequestTime = block.timestamp;
        emit CuratorUnstakeRequested(msg.sender, curator.stakedAmount, block.timestamp);
    }

    /// @notice Completes the unstaking process after the cool-down period.
    function completeUnstaking() public nonReentrant {
        Curator storage curator = curators[msg.sender];
        require(curator.unstakeRequestTime > 0, "No pending unstake request");
        require(block.timestamp >= curator.unstakeRequestTime + (CURATOR_STAKE_LOCKUP_DAYS * 1 days), "Lockup period not over");

        uint256 amountToUnstake = curator.stakedAmount;
        curator.stakedAmount = 0;
        curator.unstakeRequestTime = 0;
        isCurator[msg.sender] = false;

        IERC20 forgeToken = IERC20(forgeTokenAddress);
        require(forgeToken.transfer(msg.sender, amountToUnstake), "ForgeToken transfer back failed");
        emit CuratorUnstaked(msg.sender, amountToUnstake);
        _updateReputation(msg.sender, -15); // Slight penalty for leaving, to encourage long-term commitment
    }

    /// @notice Enables IP owners or licensees to formally lodge a dispute regarding a license or IP uniqueness.
    /// @param _licenseId The ID of the license (0 if disputeType is IPUniqueness).
    /// @param _ipId The ID of the IP (used if _licenseId is 0, or as context for license disputes).
    /// @param _disputeType The type of dispute.
    /// @param _evidenceURI URI pointing to off-chain evidence for the dispute.
    /// @return The ID of the newly created dispute.
    function submitDispute(
        uint256 _licenseId,
        uint256 _ipId,
        DisputeType _disputeType,
        string memory _evidenceURI
    ) public nonReentrant returns (uint256) {
        require(bytes(_evidenceURI).length > 0, "Evidence URI cannot be empty");

        address defendant;
        if (_disputeType == DisputeType.IPUniqueness) {
            require(_ipId > 0 && aetherIPs[_ipId].ipId != 0, "Invalid IP ID for uniqueness dispute");
            defendant = aetherIPs[_ipId].owner; // IP owner is defendant for uniqueness
        } else {
            require(_licenseId > 0 && aetherLicenses[_licenseId].licenseId != 0, "Invalid license ID for license dispute");
            _ipId = aetherLicenses[_licenseId].ipId; // Link dispute to IP
            if (aetherIPs[_ipId].owner == msg.sender) { // IP owner submits, licensee is defendant
                defendant = aetherLicenses[_licenseId].owner;
            } else if (aetherLicenses[_licenseId].owner == msg.sender) { // Licensee submits, IP owner is defendant
                defendant = aetherIPs[_ipId].owner;
            } else {
                revert("Submitter not involved in license or dispute type invalid");
            }
        }
        require(isCurator[msg.sender] || aetherIPs[_ipId].owner == msg.sender || aetherLicenses[_licenseId].owner == msg.sender, "Only involved parties or curators can submit disputes");

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            disputeId: newDisputeId,
            licenseId: _licenseId,
            ipId: _ipId,
            submitter: msg.sender,
            defendant: defendant,
            disputeType: _disputeType,
            evidenceURI: _evidenceURI,
            status: DisputeStatus.Open,
            votingDeadline: block.timestamp + (DISPUTE_VOTING_DAYS * 1 days),
            totalWeightVoted: 0,
            yesWeight: 0,
            noWeight: 0,
            hasVoted: new mapping(address => bool),
            voters: new address[](0)
        });

        if (_disputeType != DisputeType.IPUniqueness) {
            aetherLicenses[_licenseId].status = LicenseStatus.Dispute;
        }

        emit DisputeSubmitted(newDisputeId, _licenseId, msg.sender, _disputeType);
        _updateReputation(msg.sender, -5); // Small penalty for submitting a dispute, to discourage frivolous ones
        return newDisputeId;
    }

    /// @notice AetherCurators participate in dispute resolution by casting their votes.
    /// @param _disputeId The ID of the dispute.
    /// @param _voteOption The curator's vote (Yes, No, or Abstain).
    function voteOnDispute(uint256 _disputeId, VoteOption _voteOption)
        public
        onlyCurator
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Invalid dispute ID");
        require(dispute.status == DisputeStatus.Open, "Dispute not open for voting");
        require(block.timestamp < dispute.votingDeadline, "Voting period has ended");
        require(!dispute.hasVoted[msg.sender], "Curator has already voted on this dispute");

        Curator storage curator = curators[msg.sender];
        require(curator.stakedAmount > 0, "Curator must have active stake to vote");

        uint256 voteWeight = curator.stakedAmount;
        dispute.totalWeightVoted = dispute.totalWeightVoted.add(voteWeight);

        if (_voteOption == VoteOption.Yes) {
            dispute.yesWeight = dispute.yesWeight.add(voteWeight);
        } else if (_voteOption == VoteOption.No) {
            dispute.noWeight = dispute.noWeight.add(voteWeight);
        } // Abstain does not affect yes/no weight

        dispute.hasVoted[msg.sender] = true;
        dispute.voters.push(msg.sender); // Keep track of who voted
        emit DisputeVoted(_disputeId, msg.sender, _voteOption);
    }

    /// @notice Finalizes a dispute based on curator votes, applying penalties or rewards.
    ///         Callable by anyone after the voting deadline.
    /// @param _disputeId The ID of the dispute.
    function resolveDispute(uint256 _disputeId) public nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Invalid dispute ID");
        require(dispute.status == DisputeStatus.Open, "Dispute not open");
        require(block.timestamp >= dispute.votingDeadline, "Voting period not over yet");
        require(dispute.totalWeightVoted > 0, "No votes cast on this dispute");

        DisputeStatus finalStatus;
        bool submitterWon;

        if (dispute.yesWeight > dispute.noWeight) {
            finalStatus = DisputeStatus.Resolved; // Pro-submitter
            submitterWon = true;
        } else if (dispute.noWeight > dispute.yesWeight) {
            finalStatus = DisputeStatus.Resolved; // Pro-defendant
            submitterWon = false;
        } else {
            finalStatus = DisputeStatus.Canceled; // Tie or no clear winner
            submitterWon = false; // Neutral outcome
        }

        dispute.status = finalStatus;
        _applyDisputeOutcome(_disputeId, submitterWon);

        // Update curator reputation based on vote outcome (simplified: correct means aligned with majority)
        for (uint i = 0; i < dispute.voters.length; i++) {
            address voter = dispute.voters[i];
            // In a real system, individual votes would be stored to check correctness.
            // Here, we simplify: if dispute is resolved, all curators who voted get a small reward.
            curators[voter].totalVotesCast++;
            _updateReputation(voter, 1); // Small reward for participating.
        }
        emit DisputeResolved(_disputeId, finalStatus, submitterWon ? dispute.yesWeight : dispute.noWeight);
    }

    /// @notice Internal function to apply outcomes of a dispute.
    /// @param _disputeId The ID of the dispute.
    /// @param _submitterWon True if the submitter's side won, false otherwise.
    function _applyDisputeOutcome(uint256 _disputeId, bool _submitterWon) internal {
        Dispute storage dispute = disputes[_disputeId];
        address ipOwner = aetherIPs[dispute.ipId].owner;

        if (dispute.disputeType == DisputeType.IPUniqueness) {
            // Example: If submitter challenged uniqueness and won, score might be lowered.
            // If defendant (IP owner) won, their reputation is boosted.
            if (_submitterWon) {
                // Example: setAetherIPUniquenessScore(dispute.ipId, 100); // Drastically lower score by Oracle
                _updateReputation(ipOwner, -20); // Penalty for losing uniqueness dispute
            } else {
                _updateReputation(ipOwner, 10); // Reward for defending uniqueness
            }
        } else if (dispute.licenseId != 0) {
            AetherLicense storage license = aetherLicenses[dispute.licenseId];
            address licensee = license.owner;

            if (dispute.disputeType == DisputeType.LicenseRevocation) {
                if (_submitterWon) { // IP owner's revocation upheld
                    license.status = LicenseStatus.Revoked;
                    _updateReputation(licensee, -20); // Penalty for licensee whose license was revoked
                    _updateReputation(ipOwner, 10); // Reward for IP owner
                } else { // Licensee successfully defended against revocation
                    license.status = LicenseStatus.Active;
                    _updateReputation(licensee, 10); // Reward for licensee
                    _updateReputation(ipOwner, -20); // Penalty for IP owner
                }
            } else { // Other license disputes like NonPayment, BreachOfTerms
                if (_submitterWon) { // Submitters' claim (e.g., non-payment) upheld
                    // Implement actions like forced royalty distribution, or further penalties.
                    _updateReputation(dispute.defendant, -15);
                    _updateReputation(dispute.submitter, 10);
                } else { // Defendant's claim upheld
                    _updateReputation(dispute.defendant, 10);
                    _updateReputation(dispute.submitter, -15);
                }
                license.status = LicenseStatus.Active; // Return to active if not revoked
            }
        }
    }

    /// @notice (Governance/automated) Penalizes a curator for malicious or incorrect actions.
    ///         Requires a strong governance mechanism or provable misconduct.
    /// @param _curator The address of the curator to slash.
    /// @param _amount The amount of ForgeToken to slash.
    /// @param _reasonURI URI pointing to the reason and evidence for slashing.
    function slashCurator(address _curator, uint256 _amount, string memory _reasonURI) public onlyOwner nonReentrant {
        Curator storage curator = curators[_curator];
        require(curator.stakedAmount >= _amount, "Slash amount exceeds staked amount");
        require(_amount > 0, "Slash amount must be greater than zero");

        curator.stakedAmount = curator.stakedAmount.sub(_amount);
        if (curator.stakedAmount == 0) {
            isCurator[_curator] = false;
        }
        // The slashed tokens are sent to the contract owner (governance treasury).
        IERC20 forgeToken = IERC20(forgeTokenAddress);
        require(forgeToken.transfer(owner(), _amount), "ForgeToken transfer for slashing failed");

        emit CuratorSlashed(_curator, _amount, _reasonURI);
        _updateReputation(_curator, -50); // Significant penalty for slashing
    }

    // --- IV. AI-Assisted Bounties ---

    /// @notice Users post bounties for creators to generate specific AI content.
    ///         The reward is held in escrow in this contract.
    /// @param _promptURI URI for the detailed AI prompt/specifications.
    /// @param _rewardAmount Amount of ETH (or native currency) as reward.
    /// @param _deadline Deadline for fulfillment (timestamp).
    /// @return The ID of the newly created bounty.
    function createAIBounty(string memory _promptURI, uint256 _rewardAmount, uint256 _deadline)
        public
        payable
        nonReentrant
        returns (uint256)
    {
        require(bytes(_promptURI).length > 0, "Prompt URI cannot be empty");
        require(_rewardAmount > 0, "Reward amount must be greater than zero");
        require(msg.value == _rewardAmount, "Incorrect reward amount sent");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        _bountyIds.increment();
        uint256 newBountyId = _bountyIds.current();

        aiBounties[newBountyId] = AIBounty({
            bountyId: newBountyId,
            creator: msg.sender,
            promptURI: _promptURI,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            fulfillmentIpId: 0,
            fulfiller: address(0),
            status: BountyStatus.Open
        });

        emit AIBountyCreated(newBountyId, msg.sender, _rewardAmount, _deadline);
        _updateReputation(msg.sender, 5); // Reward for creating a bounty
        return newBountyId;
    }

    /// @notice Creators submit their AI-generated IP to fulfill a bounty.
    ///         This internally calls `registerAetherIP` for the submitted content.
    /// @param _bountyId The ID of the bounty being fulfilled.
    /// @param _ipHash Cryptographic hash of the core IP content.
    /// @param _metadataURI URI for off-chain metadata.
    /// @param _aiProofHash Hash of AI model parameters/seed used for generation.
    /// @param _uniquenessScore Uniqueness score from oracle.
    function submitAIBountyFulfillment(
        uint256 _bountyId,
        bytes32 _ipHash,
        string memory _metadataURI,
        bytes32 _aiProofHash,
        uint256 _uniquenessScore
    ) public nonReentrant {
        AIBounty storage bounty = aiBounties[_bountyId];
        require(bounty.bountyId != 0, "Invalid bounty ID");
        require(bounty.status == BountyStatus.Open, "Bounty is not open for fulfillment");
        require(block.timestamp <= bounty.deadline, "Bounty deadline has passed");

        // Register the IP first using the standard IP registration logic
        _ipIds.increment();
        uint256 newIpId = _ipIds.current();

        aetherIPs[newIpId] = AetherIP({
            ipId: newIpId,
            owner: msg.sender,
            ipHash: _ipHash,
            metadataURI: _metadataURI,
            aiProofHash: _aiProofHash,
            uniquenessScore: _uniquenessScore,
            registrationTimestamp: block.timestamp,
            isBountyFulfillment: true,
            bountyId: _bountyId
        });

        ownerToAetherIPs[msg.sender].push(newIpId);

        bounty.fulfillmentIpId = newIpId;
        bounty.fulfiller = msg.sender;
        bounty.status = BountyStatus.Fulfilled;

        emit AIBountyFulfilled(_bountyId, newIpId, msg.sender);
        _updateReputation(msg.sender, 15); // Reward for fulfilling a bounty
    }

    /// @notice The bounty creator approves the submitted IP, releasing the reward to the fulfiller.
    /// @param _bountyId The ID of the bounty.
    /// @param _ipId The ID of the IP that fulfilled the bounty.
    function approveAIBountyFulfillment(uint256 _bountyId, uint256 _ipId)
        public
        nonReentrant
    {
        AIBounty storage bounty = aiBounties[_bountyId];
        require(bounty.bountyId != 0, "Invalid bounty ID");
        require(bounty.creator == msg.sender, "Only bounty creator can approve");
        require(bounty.status == BountyStatus.Fulfilled, "Bounty not in fulfilled status");
        require(bounty.fulfillmentIpId == _ipId, "Submitted IP does not match bounty fulfillment");

        bounty.status = BountyStatus.Approved;

        // Transfer reward to the fulfiller
        payable(bounty.fulfiller).transfer(bounty.rewardAmount);

        emit AIBountyApproved(_bountyId, _ipId, msg.sender);
        _updateReputation(bounty.creator, 5); // Reward for approving
        _updateReputation(bounty.fulfiller, 20); // Significant reward for successful fulfillment
    }

    /// @notice The bounty creator rejects a submission, providing a reason.
    ///         The bounty then reverts to 'Open' if not past deadline, or 'Expired'.
    /// @param _bountyId The ID of the bounty.
    /// @param _reasonURI URI pointing to the reason for rejection.
    function rejectAIBountyFulfillment(uint256 _bountyId, string memory _reasonURI)
        public
        nonReentrant
    {
        AIBounty storage bounty = aiBounties[_bountyId];
        require(bounty.bountyId != 0, "Invalid bounty ID");
        require(bounty.creator == msg.sender, "Only bounty creator can reject");
        require(bounty.status == BountyStatus.Fulfilled, "Bounty not in fulfilled status");

        // The IP still exists but is not linked as fulfillment. Creator needs to decide its fate.
        // For now, only the bounty status changes.

        if (block.timestamp <= bounty.deadline) {
            bounty.status = BountyStatus.Open; // Can be refilled
        } else {
            bounty.status = BountyStatus.Expired; // Cannot be refilled
            // Refund bounty reward to creator if it expires without approval
            payable(bounty.creator).transfer(bounty.rewardAmount);
        }

        bounty.fulfillmentIpId = 0; // Unlink fulfillment
        bounty.fulfiller = address(0); // Clear fulfiller

        emit AIBountyRejected(_bountyId, msg.sender, _reasonURI);
        _updateReputation(msg.sender, -5); // Penalty for rejecting
        // Penalty for fulfiller only if rejection is deemed justified (could be part of dispute)
    }

    // --- V. Reputation System ---

    /// @notice Internal function to update a participant's reputation score.
    /// @param _participant The address whose reputation is being updated.
    /// @param _change The amount to add or subtract from the reputation score.
    function _updateReputation(address _participant, int256 _change) internal {
        reputationScores[_participant] = reputationScores[_participant] + _change;
        emit ReputationUpdated(_participant, reputationScores[_participant]);
    }

    /// @notice Retrieves the accumulated reputation score for a given participant.
    /// @param _participant The address to query.
    /// @return The current reputation score.
    function getReputationScore(address _participant) public view returns (int256) {
        return reputationScores[_participant];
    }

    // --- Utility/Helper Functions ---

    /// @notice Withdraws remaining ETH from the contract (only owner).
    ///         This should only be for accidental deposits or contract termination.
    function withdrawETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
```