This smart contract, named "AetherFlow," presents a novel decentralized platform for managing, monetizing, and fractionalizing digital intellectual property (IP). It integrates several advanced and creative concepts:

*   **AI-Driven Valuation (Simulated):** Leverages a hypothetical Chainlink AI oracle to assess IP originality and value, influencing licensing and fractional share pricing.
*   **Fractionalized IP Ownership (ERC-1155):** Allows creators to divide their unique IP (represented by an ERC-721 NFT) into numerous, tradeable ERC-1155 fractional shares, enabling broader investment and shared royalties.
*   **Dynamic Royalty Distribution:** Programmable royalty splits for creators, fractional holders, community curators, and a platform fund, adapting to IP performance.
*   **Gamified Curation & Endorsement:** Users can stake tokens to "endorse" creative works, earning rewards if the IP generates revenue, fostering community-driven promotion.
*   **On-Chain IP Dispute Resolution:** A simplified voting mechanism for infringement claims, with the option to challenge outcomes, aiming for transparent conflict resolution.
*   **Flexible Licensing Agreements:** Creators can define custom license types with static or dynamic (oracle-influenced) fees and durations.
*   **Zero-Knowledge Proof (ZKP) Interface:** A placeholder for future integration of ZKPs to assert IP originality privately.

The goal is to create a vibrant, self-sustaining ecosystem where creators are empowered, community members are incentivized, and intellectual property is managed transparently and innovatively on the blockchain.

---

**Outline and Function Summary:**

**I. Core IP Management (ERC-721 for primary ownership):**
1.  `registerCreativeWork`: Allows a creator to register a new IP, minting an ERC-721 NFT for full ownership.
2.  `updateWorkMetadata`: Enables the creator to update the metadata URI of their registered IP.
3.  `requestAIValuation`: Triggers a hypothetical AI oracle call to assess the IP's value or originality.
4.  `getAIValluation`: Retrieves the AI valuation score for a given IP.
5.  `setIPVisibility`: Sets the public/private/restricted status of an IP, including whitelisting for restricted access.
6.  `transferIPOwnership`: Transfers the full ERC-721 ownership of an IP to another address.
7.  `revokeIPRegistration`: Allows the creator to burn their IP NFT and remove it from the platform (if no active licenses/fractions).
8.  `submitZKPForOriginality`: Placeholder for submitting a Zero-Knowledge Proof to assert originality without revealing sensitive data.

**II. Fractionalization & Licensing (ERC-1155 for shares & custom licensing):**
9.  `createFractionalShares`: Allows the IP owner to fractionalize their IP into multiple ERC-1155 tokens.
10. `buyFractionalShare`: Enables users to purchase fractional shares of an IP from the owner (simplified marketplace).
11. `sellFractionalShare`: Enables users to sell their fractional shares of an IP back to the owner (simplified marketplace).
12. `createLicensingAgreement`: Defines the terms, type, and fees for using a specific IP.
13. `purchaseLicense`: Allows users to acquire a license for an IP based on predefined terms.
14. `renewLicense`: Extends an existing license agreement.
15. `setDynamicLicenseFee`: Sets a license fee to be dynamic, potentially based on an oracle's input.

**III. Royalty Distribution & Fund Management:**
16. `setRoyaltySplits`: Configures how royalties from an IP are distributed (creator, fractional holders, curators, fund).
17. `distributeRoyalties`: Triggers the distribution of accumulated royalties for a specific IP into respective pools.
18. `depositToFund`: Allows external parties to deposit funds into the AetherFlow DAO treasury.
19. `withdrawFromFund`: Allows the DAO (via `onlyOwner` initially) to withdraw funds from the treasury.
20. `allocateFundForPromotion`: Allocates a portion of the fund to promote a specific IP.

**IV. Curation & Gamification:**
21. `stakeForEndorsement`: Users can stake tokens (ETH) to endorse an IP, becoming a "curator" and gaining eligibility for rewards.
22. `claimEndorsementRewards`: Curators can claim rewards from the curator pool if their endorsed IP performs well (simplified).
23. `reportInfringement`: Allows users to report potential IP infringement, creating an on-chain dispute.
24. `voteOnInfringementClaim`: Enables token holders (or designated voters) to cast votes on infringement claims.
25. `challengeInfringementVote`: Allows challenging an infringement vote outcome by staking a bond, potentially triggering higher arbitration.
26. `resolveDispute`: Public function to finalize a dispute's outcome after the voting period.

**V. Platform Settings & Administration:**
27. `setAIVerifierAddress`: Sets the address of the AI valuation oracle contract.
28. `setPlatformFeeRecipient`: Sets the address that receives platform fees.
29. `setPlatformFeePercentage`: Sets the percentage of royalties/licenses taken as platform fee (in basis points).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety if not relying on 0.8+ default

// Interface for a hypothetical Chainlink AI Oracle
interface IChainlinkOracle {
    // A function that a Chainlink node would call to request AI analysis off-chain
    function requestAiValuation(uint256 ipId, string memory ipfsHash) external returns (bytes32 requestId);
    
    // A hypothetical function to retrieve a dynamic fee from an oracle (for license pricing)
    // function getDynamicFee(uint256 oracleId) external view returns (uint256);
}

/**
 * @title AetherFlow - Decentralized Intellectual Property & Creative Economy
 * @dev This contract provides a platform for creators to register, fractionalize, license, and monetize
 *      their unique digital intellectual property. It integrates concepts like AI-driven valuation (simulated),
 *      dynamic royalty distribution, gamified community curation, and on-chain dispute resolution.
 *
 * Outline and Function Summary:
 *
 * I. Core IP Management (ERC-721 for primary ownership):
 *    1.  `registerCreativeWork`: Allows a creator to register a new IP, minting an ERC-721 NFT for full ownership.
 *    2.  `updateWorkMetadata`: Enables the creator to update the metadata URI of their registered IP.
 *    3.  `requestAIValuation`: Triggers a hypothetical AI oracle call to assess the IP's value or originality.
 *    4.  `getAIValluation`: Retrieves the AI valuation score for a given IP.
 *    5.  `setIPVisibility`: Sets the public/private/restricted status of an IP, including whitelisting for restricted access.
 *    6.  `transferIPOwnership`: Transfers the full ERC-721 ownership of an IP to another address.
 *    7.  `revokeIPRegistration`: Allows the creator to burn their IP NFT and remove it from the platform (if no active licenses/fractions).
 *    8.  `submitZKPForOriginality`: Placeholder for submitting a Zero-Knowledge Proof to assert originality without revealing sensitive data.
 *
 * II. Fractionalization & Licensing (ERC-1155 for shares & custom licensing):
 *    9.  `createFractionalShares`: Allows the IP owner to fractionalize their IP into multiple ERC-1155 tokens.
 *    10. `buyFractionalShare`: Enables users to purchase fractional shares of an IP from the owner (simplified marketplace).
 *    11. `sellFractionalShare`: Enables users to sell their fractional shares of an IP back to the owner (simplified marketplace).
 *    12. `createLicensingAgreement`: Defines the terms, type, and fees for using a specific IP.
 *    13. `purchaseLicense`: Allows users to acquire a license for an IP based on predefined terms.
 *    14. `renewLicense`: Extends an existing license agreement.
 *    15. `setDynamicLicenseFee`: Sets a license fee to be dynamic, potentially based on an oracle's input.
 *
 * III. Royalty Distribution & Fund Management:
 *    16. `setRoyaltySplits`: Configures how royalties from an IP are distributed (creator, fractional holders, curators, fund).
 *    17. `distributeRoyalties`: Triggers the distribution of accumulated royalties for a specific IP into respective pools.
 *    18. `depositToFund`: Allows external parties to deposit funds into the AetherFlow DAO treasury.
 *    19. `withdrawFromFund`: Allows the DAO (via `onlyOwner` initially) to withdraw funds from the treasury.
 *    20. `allocateFundForPromotion`: Allocates a portion of the fund to promote a specific IP.
 *
 * IV. Curation & Gamification:
 *    21. `stakeForEndorsement`: Users can stake tokens (ETH) to endorse an IP, becoming a "curator" and gaining eligibility for rewards.
 *    22. `claimEndorsementRewards`: Curators can claim rewards from the curator pool if their endorsed IP performs well (simplified).
 *    23. `reportInfringement`: Allows users to report potential IP infringement, creating an on-chain dispute.
 *    24. `voteOnInfringementClaim`: Enables token holders (or designated voters) to cast votes on infringement claims.
 *    25. `challengeInfringementVote`: Allows challenging an infringement vote outcome by staking a bond, potentially triggering higher arbitration.
 *    26. `resolveDispute`: Public function to finalize a dispute's outcome after the voting period.
 *
 * V. Platform Settings & Administration:
 *    27. `setAIVerifierAddress`: Sets the address of the AI valuation oracle contract.
 *    28. `setPlatformFeeRecipient`: Sets the address that receives platform fees.
 *    29. `setPlatformFeePercentage`: Sets the percentage of royalties/licenses taken as platform fee (in basis points).
 */
contract AetherFlow is ERC721Burnable, ERC1155, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256; // Explicit SafeMath for clarity, though 0.8+ handles overflows

    // --- Enums and Structs ---

    enum IPVisibility { Public, Private, Restricted }
    enum DisputeStatus { Open, Voting, Resolved, Challenged }
    enum LicenseType { Basic, Commercial, Exclusive }

    struct CreativeWork {
        uint256 ipId; // Unique ID for the IP
        address creator; // Current ERC-721 owner
        string metadataURI; // IPFS hash or similar for primary asset metadata
        IPVisibility visibility;
        uint256 fractionalTokenId; // ERC-1155 ID for fractional shares, 0 if not fractionalized
        uint256 aiValuationScore; // Hypothetical AI-driven score (0 if not requested/fulfilled)
        bool aiValuationRequested;
        uint256 createdAt;
        mapping(address => bool) whitelistedAccess; // For Restricted visibility
        EnumerableSet.AddressSet curators; // Addresses that have endorsed this IP
    }

    struct RoyaltySplit {
        uint8 creatorPercent;
        uint8 fractionalHoldersPercent;
        uint8 curatorPoolPercent; // Shared among endorsing curators
        uint8 platformFundPercent; // For the DAO/platform treasury
    }

    struct LicenseAgreement {
        uint256 licenseId; // Unique ID for the license
        uint256 ipId;
        address licensee; // Address of the party holding the license
        LicenseType licenseType;
        string termsURI; // IPFS hash for detailed terms
        uint256 feeAmount; // Base fee for the license
        uint256 expiresAt; // Timestamp when license expires, 0 for perpetual
        bool dynamicFeeEnabled;
        uint256 dynamicFeeOracleId; // Reference to an oracle for dynamic pricing (e.g., Chainlink job ID)
    }

    struct Dispute {
        uint256 disputeId;
        uint256 ipId;
        address reporter;
        address accused; // If an infringement claim
        string evidenceURI; // IPFS hash of evidence
        DisputeStatus status;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Track who voted
        uint256 resolutionDeadline;
        bool outcome; // True for infringed/valid, false for not
    }

    // --- State Variables ---

    Counters.Counter private _ipIds;
    Counters.Counter private _licenseIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _erc1155FractionalTokenIds; // For unique fractional share IDs (one per IP)

    mapping(uint256 => CreativeWork) public creativeWorks;
    mapping(uint256 => RoyaltySplit) public ipRoyaltySplits; // ipId => RoyaltySplit
    mapping(uint256 => mapping(address => uint256)) public ipRoyaltyPools; // ipId => address (share holder/pool) => amount
    mapping(uint256 => uint256) public totalRoyaltiesCollected; // ipId => total accumulated from revenue

    mapping(address => EnumerableSet.UintSet) public endorsedIPs; // curator => set of ipIds they've endorsed
    mapping(uint256 => mapping(address => uint256)) public endorsementStakes; // ipId => curator => stake amount
    uint256 public endorsementStakeMinimum = 1 ether; // Minimum stake for endorsement (e.g., 1 ETH)

    mapping(uint256 => LicenseAgreement) public licenses;
    mapping(uint256 => EnumerableSet.UintSet) public ipLicenses; // ipId => set of licenseIds associated with it

    mapping(uint256 => Dispute) public disputes;
    // For simplified voting power, can be extended to token-weighted voting
    // mapping(address => uint256) public disputeVotingPower; 

    address public aiVerifierOracle; // Address of the AI oracle contract
    address public platformFeeRecipient; // Address to receive platform fees
    uint256 public platformFeePercentage = 500; // 5.00% (500 basis points out of 10,000)

    address public aetherFlowFundAddress; // Address for the DAO/platform fund treasury

    // Base URI for ERC-1155 fractional shares
    string private _erc1155BaseURI;

    // --- Events ---
    event IPRegistered(uint256 indexed ipId, address indexed creator, string metadataURI);
    event IPMetadataUpdated(uint256 indexed ipId, string newMetadataURI);
    event AIValuationRequested(uint256 indexed ipId, bytes32 indexed requestId);
    event AIValuationFulfilled(uint256 indexed ipId, uint256 score); // Hypothetical, would be from oracle callback
    event IPVisibilityChanged(uint256 indexed ipId, IPVisibility newVisibility);
    event IPOwnershipTransferred(uint256 indexed ipId, address indexed from, address indexed to);
    event IPRevoked(uint256 indexed ipId);
    event ZKPOriginalitySubmitted(uint256 indexed ipId, address indexed submitter);

    event FractionalSharesCreated(uint256 indexed ipId, uint256 fractionalTokenId, uint256 totalShares);
    event FractionalSharePurchased(uint256 indexed ipId, uint256 indexed fractionalTokenId, address indexed buyer, uint256 amount, uint256 totalPrice);
    event FractionalShareSold(uint256 indexed ipId, uint256 indexed fractionalTokenId, address indexed seller, uint256 amount, uint256 totalPrice);
    event LicenseCreated(uint256 indexed ipId, uint256 indexed licenseId, address indexed creator, LicenseType licenseType, uint256 feeAmount);
    event LicensePurchased(uint256 indexed licenseId, address indexed licensee, uint256 ipId, uint256 amountPaid);
    event LicenseRenewed(uint256 indexed licenseId, uint256 newExpiresAt);
    event DynamicLicenseFeeSet(uint256 indexed licenseId, bool enabled, uint256 oracleId);

    event RoyaltySplitsSet(uint256 indexed ipId, uint8 creator, uint8 fractionalHolders, uint8 curatorPool, uint8 platformFund);
    event RoyaltiesDistributed(uint256 indexed ipId, uint256 distributedAmount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event FundsAllocatedForPromotion(uint256 indexed ipId, uint256 amount, string purposeURI);

    event EndorsementStaked(uint256 indexed ipId, address indexed curator, uint256 amount);
    event EndorsementRewardsClaimed(uint256 indexed ipId, address indexed curator, uint256 amount);
    event InfringementReported(uint256 indexed disputeId, uint256 indexed ipId, address indexed reporter);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed voter, bool voteFor);
    event DisputeResolved(uint256 indexed disputeId, bool outcome);
    event DisputeChallenged(uint256 indexed disputeId, address indexed challenger);


    // --- Constructor ---

    constructor(address _platformFeeRecipient, address _aetherFlowFundAddress)
        ERC721("AetherFlow IP", "AFIP") // Initialize ERC-721 for individual IP ownership
        ERC1155("https://aetherflow.io/fractional/{id}.json") // Base URI for ERC-1155 fractional shares
        Ownable(msg.sender) // Owner for initial setup, can be transferred to a DAO
    {
        require(_platformFeeRecipient != address(0), "Invalid platform fee recipient");
        require(_aetherFlowFundAddress != address(0), "Invalid AetherFlow fund address");
        platformFeeRecipient = _platformFeeRecipient;
        aetherFlowFundAddress = _aetherFlowFundAddress;
        _erc1155BaseURI = "https://aetherflow.io/fractional/{id}.json"; // Default URI for fractional shares
    }

    // --- Modifiers ---

    modifier onlyIPCreator(uint256 _ipId) {
        require(creativeWorks[_ipId].creator == _msgSender(), "Not the IP creator");
        _;
    }

    modifier onlyIPOwner(uint256 _ipId) {
        require(ownerOf(_ipId) == _msgSender(), "Not the IP owner");
        _;
    }

    modifier onlyAIVerifierOracle() {
        require(_msgSender() == aiVerifierOracle, "Only AI Verifier Oracle can call this");
        _;
    }

    // --- I. Core IP Management ---

    /**
     * @dev Registers a new creative work as an ERC-721 NFT.
     * @param _metadataURI IPFS hash or URL pointing to the metadata of the creative work.
     * @param _initialVisibility Initial visibility setting for the IP.
     * @return The unique ID of the registered IP.
     */
    function registerCreativeWork(string calldata _metadataURI, IPVisibility _initialVisibility)
        external
        returns (uint256)
    {
        _ipIds.increment();
        uint256 newIpId = _ipIds.current();

        _mint(_msgSender(), newIpId); // Mint ERC-721 to the creator

        creativeWorks[newIpId] = CreativeWork({
            ipId: newIpId,
            creator: _msgSender(),
            metadataURI: _metadataURI,
            visibility: _initialVisibility,
            fractionalTokenId: 0, // Not fractionalized yet
            aiValuationScore: 0,
            aiValuationRequested: false,
            createdAt: block.timestamp,
            curators: EnumerableSet.AddressSet(0) // Initialize EnumerableSet
        });

        // Set default royalty splits
        ipRoyaltySplits[newIpId] = RoyaltySplit({
            creatorPercent: 70, // 70%
            fractionalHoldersPercent: 15, // 15%
            curatorPoolPercent: 10, // 10%
            platformFundPercent: 5 // 5%
        });

        emit IPRegistered(newIpId, _msgSender(), _metadataURI);
        return newIpId;
    }

    /**
     * @dev Updates the metadata URI for a registered creative work.
     * @param _ipId The ID of the creative work.
     * @param _newMetadataURI The new IPFS hash or URL for the metadata.
     */
    function updateWorkMetadata(uint256 _ipId, string calldata _newMetadataURI)
        external
        onlyIPCreator(_ipId)
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(bytes(_newMetadataURI).length > 0, "Metadata URI cannot be empty");
        creativeWorks[_ipId].metadataURI = _newMetadataURI;
        _setTokenURI(_ipId, _newMetadataURI); // Update ERC-721 token URI
        emit IPMetadataUpdated(_ipId, _newMetadataURI);
    }

    /**
     * @dev Requests an AI valuation for a creative work via a hypothetical oracle.
     *      The actual fulfillment would be an external call back into this contract
     *      by the Chainlink node after the AI analysis is complete.
     * @param _ipId The ID of the creative work.
     */
    function requestAIValuation(uint256 _ipId) external onlyIPCreator(_ipId) {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(aiVerifierOracle != address(0), "AI Verifier Oracle not set");
        require(!creativeWorks[_ipId].aiValuationRequested, "AI valuation already requested");

        creativeWorks[_ipId].aiValuationRequested = true;
        bytes32 requestId = IChainlinkOracle(aiVerifierOracle).requestAiValuation(_ipId, creativeWorks[_ipId].metadataURI);

        emit AIValuationRequested(_ipId, requestId);
    }

    /**
     * @dev Mock function to fulfill an AI valuation request. In a real scenario, this would be
     *      a callback from a Chainlink node or similar oracle service (e.g., ChainlinkClient contract).
     *      For this example, it's an internal mock, but conceptually it shows the update.
     * @param _ipId The ID of the creative work.
     * @param _valuationScore The AI-determined valuation score.
     */
    function _fulfillAIValuation(uint256 _ipId, uint256 _valuationScore) internal {
        // In a real scenario, this would be an external function callable only by the oracle,
        // using the Chainlink's `fulfill` pattern. For this example, it's an internal mock.
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(creativeWorks[_ipId].aiValuationRequested, "AI valuation not requested or already fulfilled");
        creativeWorks[_ipId].aiValuationScore = _valuationScore;
        creativeWorks[_ipId].aiValuationRequested = false; // Reset for potential re-evaluation
        emit AIValuationFulfilled(_ipId, _valuationScore);
    }

    /**
     * @dev Gets the AI valuation score for a given IP.
     * @param _ipId The ID of the creative work.
     * @return The AI valuation score.
     */
    function getAIValluation(uint256 _ipId) external view returns (uint256) {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        return creativeWorks[_ipId].aiValuationScore;
    }

    /**
     * @dev Sets the visibility of a creative work. Only the creator can change this.
     * @param _ipId The ID of the creative work.
     * @param _newVisibility The new visibility status.
     * @param _whitelistedAddresses Addresses to whitelist if visibility is 'Restricted'.
     */
    function setIPVisibility(uint256 _ipId, IPVisibility _newVisibility, address[] calldata _whitelistedAddresses)
        external
        onlyIPCreator(_ipId)
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        creativeWorks[_ipId].visibility = _newVisibility;
        if (_newVisibility == IPVisibility.Restricted) {
            for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
                creativeWorks[_ipId].whitelistedAccess[_whitelistedAddresses[i]] = true;
            }
        }
        emit IPVisibilityChanged(_ipId, _newVisibility);
    }

    /**
     * @dev Allows the owner of the ERC-721 IP to transfer full ownership.
     *      This overrides the default ERC721 `transferFrom` to also update the `creator` field.
     * @param _from The current owner.
     * @param _to The new owner.
     * @param _ipId The ID of the creative work.
     */
    function transferIPOwnership(address _from, address _to, uint256 _ipId)
        public // Can be called by current ERC-721 owner or approved address
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(_from == ownerOf(_ipId), "Caller not current IP owner");
        require(_to != address(0), "Cannot transfer to zero address");

        super.transferFrom(_from, _to, _ipId); // ERC721 `transferFrom` handles ownership/approval checks
        creativeWorks[_ipId].creator = _to; // Also update the creator mapping within our struct
        emit IPOwnershipTransferred(_ipId, _from, _to);
    }

    /**
     * @dev Allows the creator to revoke their IP registration by burning the ERC-721 NFT.
     *      This effectively removes the IP from the platform's active registry.
     *      Requires no outstanding licenses or fractional shares.
     * @param _ipId The ID of the creative work.
     */
    function revokeIPRegistration(uint256 _ipId)
        external
        onlyIPCreator(_ipId)
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(ipLicenses[_ipId].length() == 0, "Cannot revoke IP with active licenses");
        require(creativeWorks[_ipId].fractionalTokenId == 0, "Cannot revoke IP with fractional shares outstanding");

        _burn(_ipId); // Burn the ERC-721 NFT
        delete creativeWorks[_ipId]; // Remove from mapping

        emit IPRevoked(_ipId);
    }

    /**
     * @dev Placeholder function for submitting a Zero-Knowledge Proof (ZKP) to assert originality
     *      without revealing sensitive details of the IP (e.g., specific hash until dispute).
     *      Full ZKP verification on-chain is complex and would require a dedicated verifier contract.
     * @param _ipId The ID of the creative work.
     * @param _proof The actual ZKP bytes (e.g., Groth16 proof).
     */
    function submitZKPForOriginality(uint256 _ipId, bytes calldata _proof)
        external
        onlyIPCreator(_ipId)
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        // In a real implementation, this would involve calling a ZKP verifier contract:
        // require(verifierContract.verifyProof(_proof, _publicInputs), "Invalid ZKP");
        // For this example, we just log the submission and check for non-empty proof.
        require(bytes(_proof).length > 0, "ZKP proof cannot be empty");
        // Could store the proof hash or details in creativeWorks[_ipId] or a separate mapping
        // e.g., creativeWorks[_ipId].originalityProofHash = keccak256(_proof);

        emit ZKPOriginalitySubmitted(_ipId, _msgSender());
    }


    // --- II. Fractionalization & Licensing ---

    /**
     * @dev Allows the IP owner to fractionalize their IP into a specified number of ERC-1155 tokens.
     *      Each fractional token represents a share of future royalties and potential governance.
     * @param _ipId The ID of the creative work to fractionalize.
     * @param _totalShares The total number of fractional shares to create.
     */
    function createFractionalShares(uint256 _ipId, uint256 _totalShares)
        external
        onlyIPOwner(_ipId)
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(_totalShares > 0, "Must create at least one share");
        require(creativeWorks[_ipId].fractionalTokenId == 0, "IP already fractionalized");

        _erc1155FractionalTokenIds.increment();
        uint256 newFractionalTokenId = _erc1155FractionalTokenIds.current();

        creativeWorks[_ipId].fractionalTokenId = newFractionalTokenId;

        // Mint all shares to the IP owner initially
        _mint(_msgSender(), newFractionalTokenId, _totalShares, "");

        emit FractionalSharesCreated(_ipId, newFractionalTokenId, _totalShares);
    }

    /**
     * @dev Allows users to purchase fractional shares. This is a very simplified marketplace.
     *      Requires the IP to be fractionalized and the owner to have listed shares.
     *      It assumes the IP owner is selling these initial shares directly from their balance.
     * @param _ipId The ID of the creative work.
     * @param _amount The number of fractional shares to purchase.
     * @param _pricePerShare The agreed-upon price per share.
     */
    function buyFractionalShare(uint256 _ipId, uint256 _amount, uint256 _pricePerShare)
        external
        payable
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(creativeWorks[_ipId].fractionalTokenId != 0, "IP not fractionalized");
        require(_amount > 0, "Must purchase at least one share");
        require(_pricePerShare > 0, "Price per share must be positive");

        uint256 fractionalTokenId = creativeWorks[_ipId].fractionalTokenId;
        address ipOwner = ownerOf(_ipId); // The ERC-721 owner is the initial seller of fractions

        uint256 totalCost = _amount.mul(_pricePerShare);
        require(msg.value >= totalCost, "Incorrect payment amount or insufficient funds");

        // Transfer funds to the IP owner
        payable(ipOwner).transfer(totalCost);

        // Transfer ERC-1155 shares from IP owner to buyer
        _safeTransferFrom(ipOwner, _msgSender(), fractionalTokenId, _amount, "");

        // Refund any excess payment
        if (msg.value > totalCost) {
            payable(_msgSender()).transfer(msg.value.sub(totalCost));
        }

        emit FractionalSharePurchased(_ipId, fractionalTokenId, _msgSender(), _amount, totalCost);
    }

    /**
     * @dev Allows a holder of fractional shares to sell them.
     *      This is a very simplified marketplace, assuming direct sale to the IP owner (mocked as the buyer).
     *      In a real system, funds would come from an actual buyer or a liquidity pool.
     * @param _ipId The ID of the creative work.
     * @param _amount The number of fractional shares to sell.
     * @param _pricePerShare The price per share the seller expects.
     */
    function sellFractionalShare(uint256 _ipId, uint256 _amount, uint256 _pricePerShare)
        external
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(creativeWorks[_ipId].fractionalTokenId != 0, "IP not fractionalized");
        require(_amount > 0, "Must sell at least one share");
        require(_pricePerShare > 0, "Price per share must be positive");

        uint256 fractionalTokenId = creativeWorks[_ipId].fractionalTokenId;
        require(balanceOf(_msgSender(), fractionalTokenId) >= _amount, "Insufficient fractional shares");

        address ipOwner = ownerOf(_ipId); // The ERC-721 owner is the potential buyer here (simplified)
        uint256 totalRevenue = _amount.mul(_pricePerShare);

        // This assumes the IP owner (or another designated buyer) implicitly sends funds.
        // In a real marketplace, this would interact with an order book or AMM to execute a trade.
        // For simplicity, we just simulate the share transfer and emit the event.
        // Funds exchange would be external to this function call.

        // Transfer ERC-1155 shares from seller back to IP owner (simplified)
        _safeTransferFrom(_msgSender(), ipOwner, fractionalTokenId, _amount, "");

        emit FractionalShareSold(_ipId, fractionalTokenId, _msgSender(), _amount, totalRevenue);
    }

    /**
     * @dev Defines a new licensing agreement for a creative work.
     * @param _ipId The ID of the creative work.
     * @param _licensee The address of the intended licensee (address(0) for general availability).
     * @param _licenseType The type of license (e.g., Basic, Commercial, Exclusive).
     * @param _termsURI IPFS hash or URL for the detailed license terms document.
     * @param _feeAmount The base fee for acquiring this license.
     * @param _durationDays The duration of the license in days (0 for perpetual).
     * @return The unique ID of the created license.
     */
    function createLicensingAgreement(
        uint256 _ipId,
        address _licensee,
        LicenseType _licenseType,
        string calldata _termsURI,
        uint256 _feeAmount,
        uint256 _durationDays
    ) external onlyIPOwner(_ipId) returns (uint256) {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(bytes(_termsURI).length > 0, "Terms URI cannot be empty");
        require(_feeAmount > 0, "License fee must be positive");

        _licenseIds.increment();
        uint256 newLicenseId = _licenseIds.current();

        uint256 expiresAt = (_durationDays == 0) ? 0 : block.timestamp.add(_durationDays.mul(1 days));

        licenses[newLicenseId] = LicenseAgreement({
            licenseId: newLicenseId,
            ipId: _ipId,
            licensee: _licensee,
            licenseType: _licenseType,
            termsURI: _termsURI,
            feeAmount: _feeAmount,
            expiresAt: expiresAt,
            dynamicFeeEnabled: false,
            dynamicFeeOracleId: 0
        });
        ipLicenses[_ipId].add(newLicenseId);

        emit LicenseCreated(_ipId, newLicenseId, _msgSender(), _licenseType, _feeAmount);
        return newLicenseId;
    }

    /**
     * @dev Allows a party to purchase a specific license agreement.
     * @param _licenseId The ID of the license agreement to purchase.
     */
    function purchaseLicense(uint256 _licenseId) external payable {
        LicenseAgreement storage license = licenses[_licenseId];
        require(license.ipId != 0, "License does not exist");
        require(license.licensee == address(0) || license.licensee == _msgSender(), "License not available or for another party");
        require(license.expiresAt == 0 || block.timestamp < license.expiresAt, "License has expired");

        uint256 effectiveFee = license.feeAmount;
        if (license.dynamicFeeEnabled) {
            // Simulate dynamic fee from oracle (not implemented fully here).
            // In a real scenario, it would call an oracle:
            // effectiveFee = IChainlinkOracle(aiVerifierOracle).getDynamicFee(license.dynamicFeeOracleId);
            effectiveFee = license.feeAmount.mul(2); // Mock dynamic increase
        }

        require(msg.value >= effectiveFee, "Insufficient payment for license");

        uint256 platformFee = msg.value.mul(platformFeePercentage).div(10000);
        uint256 creatorRevenue = msg.value.sub(platformFee);

        // Transfer fees
        payable(platformFeeRecipient).transfer(platformFee);
        payable(ownerOf(license.ipId)).transfer(creatorRevenue); // Send revenue to current IP owner

        license.licensee = _msgSender(); // Assign license to the purchaser

        emit LicensePurchased(_licenseId, _msgSender(), license.ipId, msg.value);

        // Accumulate revenue for royalty distribution
        _accumulateRoyalties(license.ipId, creatorRevenue);
    }

    /**
     * @dev Renews an existing license agreement.
     * @param _licenseId The ID of the license to renew.
     * @param _additionalDurationDays The number of additional days to extend the license.
     */
    function renewLicense(uint256 _licenseId, uint256 _additionalDurationDays)
        external
        payable
    {
        LicenseAgreement storage license = licenses[_licenseId];
        require(license.ipId != 0, "License does not exist");
        require(license.licensee == _msgSender(), "Only the licensee can renew");
        require(_additionalDurationDays > 0, "Must add duration");
        require(block.timestamp < license.expiresAt || license.expiresAt == 0, "License cannot be renewed after expiry");


        uint256 renewalFee = license.feeAmount; // Could be a separate renewal fee or dynamic
        require(msg.value >= renewalFee, "Insufficient payment for renewal");

        uint256 platformFee = msg.value.mul(platformFeePercentage).div(10000);
        uint256 creatorRevenue = msg.value.sub(platformFee);

        payable(platformFeeRecipient).transfer(platformFee);
        payable(ownerOf(license.ipId)).transfer(creatorRevenue);

        license.expiresAt = (license.expiresAt == 0) ?
            block.timestamp.add(_additionalDurationDays.mul(1 days)) : // If perpetual (0), start from now
            license.expiresAt.add(_additionalDurationDays.mul(1 days)); // Extend from current expiry

        emit LicenseRenewed(_licenseId, license.expiresAt);

        // Accumulate revenue for royalty distribution
        _accumulateRoyalties(license.ipId, creatorRevenue);
    }

    /**
     * @dev Sets a license to use a dynamic fee, potentially via an oracle.
     * @param _licenseId The ID of the license.
     * @param _enabled True to enable dynamic fees, false to disable.
     * @param _dynamicFeeOracleId An ID for the oracle to query for dynamic pricing (e.g., Chainlink job ID).
     */
    function setDynamicLicenseFee(uint256 _licenseId, bool _enabled, uint256 _dynamicFeeOracleId)
        external
        onlyIPOwner(licenses[_licenseId].ipId)
    {
        LicenseAgreement storage license = licenses[_licenseId];
        require(license.ipId != 0, "License does not exist");

        license.dynamicFeeEnabled = _enabled;
        license.dynamicFeeOracleId = _dynamicFeeOracleId;

        emit DynamicLicenseFeeSet(_licenseId, _enabled, _dynamicFeeOracleId);
    }

    // --- III. Royalty Distribution & Fund Management ---

    /**
     * @dev Sets the royalty distribution percentages for a specific IP.
     *      Percentages must sum up to 100.
     * @param _ipId The ID of the creative work.
     * @param _creator Percent for the IP creator/owner.
     * @param _fractionalHolders Percent for fractional share holders.
     * @param _curatorPool Percent for the curator pool.
     * @param _platformFund Percent for the AetherFlow platform fund.
     */
    function setRoyaltySplits(
        uint256 _ipId,
        uint8 _creator,
        uint8 _fractionalHolders,
        uint8 _curatorPool,
        uint8 _platformFund
    ) external onlyIPOwner(_ipId) {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(_creator.add(_fractionalHolders).add(_curatorPool).add(_platformFund) == 100, "Royalty percentages must sum to 100");
        ipRoyaltySplits[_ipId] = RoyaltySplit({
            creatorPercent: _creator,
            fractionalHoldersPercent: _fractionalHolders,
            curatorPoolPercent: _curatorPool,
            platformFundPercent: _platformFund
        });
        emit RoyaltySplitsSet(_ipId, _creator, _fractionalHolders, _curatorPool, _platformFund);
    }

    /**
     * @dev Distributes accumulated royalties for a given IP.
     *      Can be called by anyone, and pulls from the internal royalty pool.
     *      Funds are moved to specific pools within the contract to be claimed later.
     * @param _ipId The ID of the creative work.
     */
    function distributeRoyalties(uint256 _ipId) external {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        uint256 amountToDistribute = totalRoyaltiesCollected[_ipId];
        require(amountToDistribute > 0, "No royalties to distribute for this IP");

        RoyaltySplit storage splits = ipRoyaltySplits[_ipId];
        address ipOwner = ownerOf(_ipId);

        // Calculate distribution amounts
        uint256 creatorShare = amountToDistribute.mul(splits.creatorPercent).div(100);
        uint256 fractionalHoldersShare = amountToDistribute.mul(splits.fractionalHoldersPercent).div(100);
        uint256 curatorPoolShare = amountToDistribute.mul(splits.curatorPoolPercent).div(100);
        uint256 platformFundShare = amountToDistribute.mul(splits.platformFundPercent).div(100);

        // Distribute to Creator/IP Owner's claimable pool
        if (creatorShare > 0) {
            ipRoyaltyPools[_ipId][ipOwner] = ipRoyaltyPools[_ipId][ipOwner].add(creatorShare);
        }

        // Distribute to Fractional Holders' claimable pool (if fractionalized)
        if (fractionalHoldersShare > 0 && creativeWorks[_ipId].fractionalTokenId != 0) {
            // This is a simplified distribution. In reality, fractional holders would claim pro-rata.
            // For now, we accumulate it in a general contract pool for fractional claims.
            // A `claimFractionalRoyalties` function would be needed to distribute this.
            ipRoyaltyPools[_ipId][address(this)] = ipRoyaltyPools[_ipId][address(this)].add(fractionalHoldersShare); 
        }

        // Distribute to Curator Pool's claimable pool
        if (curatorPoolShare > 0) {
            // Similar to fractional holders, this accumulates for all curators to claim.
            ipRoyaltyPools[_ipId][address(this)] = ipRoyaltyPools[_ipId][address(this)].add(curatorPoolShare); 
        }

        // Distribute to Platform Fund's claimable pool
        if (platformFundShare > 0) {
            ipRoyaltyPools[_ipId][aetherFlowFundAddress] = ipRoyaltyPools[_ipId][aetherFlowFundAddress].add(platformFundShare);
        }

        totalRoyaltiesCollected[_ipId] = 0; // Reset collected amount for this IP

        emit RoyaltiesDistributed(_ipId, amountToDistribute);
    }

    /**
     * @dev Allows anyone to deposit funds into the AetherFlow platform treasury.
     * @param _purposeURI IPFS hash or URL detailing the purpose of the deposit.
     */
    function depositToFund(string calldata _purposeURI) external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        // Funds are simply held by the contract for now, managed by the owner (DAO in future).
        // No explicit transfer here, as the `receive` function handles incoming ETH
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Allows the AetherFlow DAO (represented by `onlyOwner`) to withdraw funds from the contract treasury.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawFromFund(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient balance in fund");
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Allocates a portion of the AetherFlow fund for promoting a specific IP.
     *      Requires approval by the DAO (represented by `onlyOwner`).
     * @param _ipId The ID of the creative work to promote.
     * @param _amount The amount to allocate for promotion.
     * @param _purposeURI IPFS hash or URL describing the promotion plan.
     */
    function allocateFundForPromotion(uint256 _ipId, uint256 _amount, string calldata _purposeURI)
        external
        onlyOwner // Should be DAO governance in a real system
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(_amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient funds in AetherFlow fund");

        // Transfer funds to a designated promotion service/contract, or directly to creator (if approved).
        // For simplicity, we transfer to the creator's royalty pool for claiming.
        ipRoyaltyPools[_ipId][creativeWorks[_ipId].creator] = ipRoyaltyPools[_ipId][creativeWorks[_ipId].creator].add(_amount);

        emit FundsAllocatedForPromotion(_ipId, _amount, _purposeURI);
    }


    // --- IV. Curation & Gamification ---

    /**
     * @dev Allows users to stake tokens (ETH in this case) to endorse a creative work.
     *      Endorsers become "curators" and are eligible for a share of the curator pool.
     * @param _ipId The ID of the creative work to endorse.
     */
    function stakeForEndorsement(uint256 _ipId) external payable {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(msg.value >= endorsementStakeMinimum, "Stake amount below minimum");

        // Add to list of curators for this IP
        if (!creativeWorks[_ipId].curators.contains(_msgSender())) {
            creativeWorks[_ipId].curators.add(_msgSender());
        }

        // Add stake amount
        endorsementStakes[_ipId][_msgSender()] = endorsementStakes[_ipId][_msgSender()].add(msg.value);
        endorsedIPs[_msgSender()].add(_ipId);

        emit EndorsementStaked(_ipId, _msgSender(), msg.value);
    }

    /**
     * @dev Allows a curator to claim their share of endorsement rewards from an IP's curator pool.
     *      This is a simplified pull model. A real system would calculate pro-rata shares
     *      based on stake amount, duration, and IP performance from the general curator pool for that IP.
     * @param _ipId The ID of the creative work.
     */
    function claimEndorsementRewards(uint256 _ipId) external {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(creativeWorks[_ipId].curators.contains(_msgSender()), "Not an active curator for this IP");

        // Simplified: calculate share from total curator pool based on individual's stake vs total stake
        uint256 totalCuratorStakeForIP = 0;
        address[] memory currentCurators = creativeWorks[_ipId].curators.values();
        for (uint256 i = 0; i < currentCurators.length; i++) {
            totalCuratorStakeForIP = totalCuratorStakeForIP.add(endorsementStakes[_ipId][currentCurators[i]]);
        }
        require(totalCuratorStakeForIP > 0, "No active stakes for this IP to calculate share");

        uint256 curatorPoolForIP = ipRoyaltyPools[_ipId][address(this)]; // Total accumulated for curators
        require(curatorPoolForIP > 0, "No curator rewards available for this IP");

        // Calculate proportional share
        uint256 myStake = endorsementStakes[_ipId][_msgSender()];
        uint256 claimableAmount = curatorPoolForIP.mul(myStake).div(totalCuratorStakeForIP);

        require(claimableAmount > 0, "No claimable rewards for your stake in this IP");

        // Deduct from general curator pool and transfer
        ipRoyaltyPools[_ipId][address(this)] = ipRoyaltyPools[_ipId][address(this)].sub(claimableAmount);
        payable(_msgSender()).transfer(claimableAmount);

        emit EndorsementRewardsClaimed(_ipId, _msgSender(), claimableAmount);
    }

    /**
     * @dev Allows any user to report a potential IP infringement.
     * @param _ipId The ID of the infringed creative work.
     * @param _accused The address accused of infringement (can be address(0) if unknown).
     * @param _evidenceURI IPFS hash or URL pointing to evidence of infringement.
     * @return The unique ID of the created dispute.
     */
    function reportInfringement(uint256 _ipId, address _accused, string calldata _evidenceURI)
        external
        returns (uint256)
    {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        require(bytes(_evidenceURI).length > 0, "Evidence URI cannot be empty");

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            disputeId: newDisputeId,
            ipId: _ipId,
            reporter: _msgSender(),
            accused: _accused,
            evidenceURI: _evidenceURI,
            status: DisputeStatus.Open,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            resolutionDeadline: block.timestamp.add(7 days), // 7 days for voting
            outcome: false // Default to false
        });

        emit InfringementReported(newDisputeId, _ipId, _msgSender());
        return newDisputeId;
    }

    /**
     * @dev Allows eligible parties (e.g., token holders, DAO members) to vote on an infringement claim.
     *      Simplified: anyone can vote with 1 unit of voting power.
     * @param _disputeId The ID of the dispute.
     * @param _voteFor True for 'infringed', false for 'not infringed'.
     */
    function voteOnInfringementClaim(uint256 _disputeId, bool _voteFor) external {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.Open, "Dispute not in open status");
        require(block.timestamp <= dispute.resolutionDeadline, "Voting period has ended");
        require(!dispute.hasVoted[_msgSender()], "Already voted on this dispute");

        if (_voteFor) {
            dispute.totalVotesFor++;
        } else {
            dispute.totalVotesAgainst++;
        }
        dispute.hasVoted[_msgSender()] = true;
        // disputeVotingPower[_msgSender()]++; // Can be used for weighted voting

        emit DisputeVoteCast(_disputeId, _msgSender(), _voteFor);
    }

    /**
     * @dev Resolves a dispute based on the vote outcome.
     *      Can be called by anyone after the voting deadline.
     * @param _disputeId The ID of the dispute.
     */
    function resolveDispute(uint256 _disputeId) public {
        _resolveDispute(_disputeId);
    }

    function _resolveDispute(uint256 _disputeId) internal {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.Open, "Dispute not in open status");
        require(block.timestamp > dispute.resolutionDeadline, "Voting period not over yet");

        if (dispute.totalVotesFor > dispute.totalVotesAgainst) {
            dispute.outcome = true; // Infringement confirmed
        } else {
            dispute.outcome = false; // No infringement or insufficient votes
        }
        dispute.status = DisputeStatus.Resolved;

        // Implement consequences: e.g., fine accused, reward reporter,
        // (e.g., by transferring ETH from contract or burning tokens)
        // if (dispute.outcome) { payable(dispute.reporter).transfer(rewardAmount); }

        emit DisputeResolved(_disputeId, dispute.outcome);
    }


    /**
     * @dev Allows a party to challenge a dispute's vote outcome by staking a bond,
     *      potentially triggering a higher-level arbitration.
     * @param _disputeId The ID of the dispute to challenge.
     */
    function challengeInfringementVote(uint256 _disputeId) external payable {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.disputeId != 0, "Dispute does not exist");
        require(dispute.status == DisputeStatus.Resolved, "Dispute not yet resolved");
        require(msg.value >= 1 ether, "Challenge requires minimum stake (1 ETH)"); // Example stake amount

        dispute.status = DisputeStatus.Challenged;
        // In a real system, this would trigger a new phase, potentially with a Kleros-like setup.
        // The stake would be held, and a new round of voting/arbitration would commence.

        emit DisputeChallenged(_disputeId, _msgSender());
    }

    // --- V. Platform Settings & Administration ---

    /**
     * @dev Sets the address of the AI valuation oracle contract.
     *      Only the contract owner can set this.
     * @param _newAddress The address of the new AI oracle.
     */
    function setAIVerifierAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "AI Verifier Address cannot be zero");
        aiVerifierOracle = _newAddress;
    }

    /**
     * @dev Sets the recipient for platform fees.
     *      Only the contract owner can set this.
     * @param _newRecipient The new address to receive platform fees.
     */
    function setPlatformFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Platform Fee Recipient cannot be zero");
        platformFeeRecipient = _newRecipient;
    }

    /**
     * @dev Sets the percentage of royalties/licenses taken as a platform fee.
     *      Value is in basis points (e.g., 500 for 5%).
     *      Only the contract owner can set this.
     * @param _newPercentage The new platform fee percentage.
     */
    function setPlatformFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 10000, "Fee percentage cannot exceed 100%"); // 10000 basis points = 100%
        platformFeePercentage = _newPercentage;
    }

    // --- Internal Royalty Accumulation ---

    /**
     * @dev Internal function to accumulate royalties from various revenue streams (licenses, external sales, etc.).
     * @param _ipId The ID of the creative work.
     * @param _amount The amount of royalties to accumulate.
     */
    function _accumulateRoyalties(uint256 _ipId, uint256 _amount) internal {
        require(creativeWorks[_ipId].ipId != 0, "IP does not exist");
        totalRoyaltiesCollected[_ipId] = totalRoyaltiesCollected[_ipId].add(_amount);
    }

    // --- ERC-1155 Required Functions ---

    /**
     * @dev See {ERC1155-_uri}.
     *      Returns the URI for fractional shares.
     */
    function uri(uint256) public view override returns (string memory) {
        return _erc1155BaseURI;
    }

    // Fallback and Receive functions

    /**
     * @dev The `receive` function is called when the contract receives ETH without any data.
     *      This allows direct deposits to the contract, contributing to the AetherFlow fund.
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```