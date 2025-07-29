This smart contract, `SynapseNexus`, is designed as a decentralized innovation hub. It integrates several advanced concepts: **dynamic NFTs for researcher reputation**, **AI-augmented project evaluation** via a trusted oracle, and **tokenized intellectual property (IP)** for successful research outcomes. It aims to foster R&D by providing a transparent, on-chain mechanism for project funding, review, and IP management, distinct from existing open-source projects by its specific combination of features and unique "Proof-of-AI-Assisted-Review" mechanism.

---

## Contract Outline

**I. Core Infrastructure & Access Control**
    - `constructor`: Initializes the main contract, setting addresses for custom NFT contracts and the AI Oracle.
    - `pauseContract`, `unpauseContract`: Emergency pause functionality inherited from OpenZeppelin's `Pausable`.
    - `setGovernanceAddress`: Allows the current governance (owner) to transfer ownership.
    - `setAIOracleAddress`: Sets the address of the trusted AI Oracle.
    - `addApprovedReviewer`, `removeApprovedReviewer`: Manages a whitelist of addresses authorized to submit human reviews.

**II. Researcher Profiles & Reputation (Dynamic ERC721 - `SynapseNexusResearcherNFT`)**
    - `registerResearcher`: Mints a unique Researcher Profile NFT for a new user, establishing their on-chain identity.
    - `updateResearcherProfile`: Allows a researcher to update their public profile metadata (e.g., contact info CID).
    - `getResearcherProfile`: Retrieves detailed information about a specific researcher's profile.
    - `_updateResearcherNFTStats` (Internal to `SynapseNexusResearcherNFT`): Dynamically updates a Researcher NFT's reputation score and successful project count based on on-chain activities (called by `SynapseNexus`).
    - `tokenURI` (Overridden in `SynapseNexusResearcherNFT`): Provides metadata for the dynamic NFT, reflecting updated stats.

**III. Project Submission & Funding**
    - `submitResearchProposal`: Allows a registered researcher to propose a new R&D project with a funding goal and deadline.
    - `fundProject`: Enables users to contribute Ether towards a project's funding goal.
    - `withdrawFunding`: Allows the project proposer to withdraw collected funds once the project is approved.
    - `cancelProject`: Allows the project proposer or governance to cancel a project before it's approved.
    - `refundFailedProject`: Enables funders to claim back their contributions if a project fails (e.g., funding goal not met by deadline, or cancelled).

**IV. AI-Augmented Review & Evaluation**
    - `requestAIReview`: Triggers a conceptual request to the off-chain AI oracle for an automated project proposal review.
    - `receiveAIReview`: A callback function, callable only by the trusted AI Oracle, to submit the AI's review score and report CID.
    - `submitHumanReview`: Allows approved human reviewers to submit their assessment and rating for a project.
    - `evaluateProjectForApproval`: A public function that can be called by anyone to trigger the internal project evaluation process based on funding, AI score, and human reviews.

**V. Project Completion & IP Management (ERC721 - `SynapseNexusProjectIP`)**
    - `submitProjectOutcome`: Allows the researcher to submit the final results or outcome of their completed project (e.g., an IPFS CID to a research paper).
    - `verifyProjectOutcome`: Governance function to officially verify the submitted project outcome. Upon verification, the IP NFT is minted and researcher's stats updated.
    - `mintProjectIP` (Internal to `SynapseNexusProjectIP`): Mints a unique ERC721 NFT representing the intellectual property of a successfully completed and verified project (called by `SynapseNexus`).
    - `grantIPLicense` (Accessed via `projectIPNFT`): Allows the IP NFT holder to grant a timed license for commercial or research use, receiving a fee.
    - `revokeIPLicense` (Accessed via `projectIPNFT`): Allows the IP NFT holder to revoke an active license.
    - `distributeIPRoyalties` (Accessed via `projectIPNFT`): Allows the IP NFT holder to withdraw accumulated license fees.

**VI. Dispute Resolution & Governance**
    - `raiseDispute`: Allows any user to raise a dispute concerning a project's status or outcome.
    - `resolveDispute`: A governance function to officially resolve a raised dispute, determining the project's fate.

**VII. Views & Utilities**
    - `getProjectDetails`: Retrieves comprehensive information about a specific project.
    - `getProjectStatus`: Returns the current status (enum) of a specific project.
    - `getProjectFunderAmount`: Retrieves the amount a specific funder contributed to a project.

---

## Source Code

This solution is split into three files for modularity:
1.  `SynapseNexusResearcherNFT.sol`: Manages researcher profile NFTs.
2.  `SynapseNexusProjectIP.sol`: Manages intellectual property NFTs and licensing.
3.  `SynapseNexus.sol`: The main hub contract coordinating all functionalities.

**1. `SynapseNexusResearcherNFT.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SynapseNexusResearcherNFT
 * @dev ERC721 contract for representing researcher profiles as dynamic NFTs.
 *      Their metadata (reputation, successful projects) can be updated on-chain,
 *      which an off-chain metadata resolver would reflect.
 */
contract SynapseNexusResearcherNFT is ERC721URIStorage, Ownable {
    // Struct to hold dynamic researcher data
    struct ResearcherData {
        string name;
        string contactInfoCID; // IPFS CID for detailed contact/bio
        uint256 successfulProjects;
        uint256 reputationScore; // Cumulative score based on successful projects, reviews, etc.
    }

    // Mapping from token ID to researcher data
    mapping(uint256 => ResearcherData) public researcherProfiles;
    // Mapping from researcher address to their profile token ID for quick lookup
    mapping(address => uint256) public researcherProfileId;

    // Events for tracking researcher profile changes
    event ResearcherProfileCreated(uint256 indexed profileId, address indexed owner, string name, string contactInfoCID);
    event ResearcherProfileUpdated(uint256 indexed profileId, string newContactInfoCID);
    event ResearcherStatsUpdated(uint256 indexed profileId, uint256 successfulProjects, uint256 reputationScore);

    /**
     * @dev Constructor to initialize the ERC721 and set the owner (which will be the main SynapseNexus contract).
     * @param _owner The address of the SynapseNexus contract.
     */
    constructor(address _owner) ERC721("SynapseNexusResearcher", "SNRN") Ownable(_owner) {}

    /**
     * @dev Modifier to restrict calls only from the main SynapseNexus contract.
     */
    modifier onlySynapseNexus() {
        require(msg.sender == owner(), "SNRN: Only SynapseNexus can call");
        _;
    }

    /**
     * @dev Overrides the base URI for token metadata.
     *      This would ideally point to a metadata server that resolves dynamic attributes
     *      based on the on-chain data stored in `researcherProfiles`.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://api.synapsenexus.com/researcher_nft/";
    }

    /**
     * @dev Mints a new Researcher Profile NFT for a given address.
     *      Only callable by the main SynapseNexus contract.
     * @param _to The address to mint the NFT to.
     * @param _name The public name of the researcher.
     * @param _contactInfoCID IPFS CID for detailed contact information or bio.
     * @return The ID of the newly minted NFT.
     */
    function mint(address _to, string memory _name, string memory _contactInfoCID)
        external
        onlySynapseNexus
        returns (uint256)
    {
        require(researcherProfileId[_to] == 0, "SNRN: Address already has a profile NFT");
        uint256 newItemId = totalSupply() + 1; // Simple incrementing ID for new tokens
        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, ""); // URI will be resolved by an external service using _baseURI + ID

        researcherProfiles[newItemId] = ResearcherData({
            name: _name,
            contactInfoCID: _contactInfoCID,
            successfulProjects: 0,
            reputationScore: 0
        });
        researcherProfileId[_to] = newItemId; // Map address to token ID

        emit ResearcherProfileCreated(newItemId, _to, _name, _contactInfoCID);
        return newItemId;
    }

    /**
     * @dev Updates the contact information CID for a specific researcher profile.
     *      Only callable by the main SynapseNexus contract.
     * @param _profileId The ID of the researcher's NFT.
     * @param _newContactInfoCID The new IPFS CID for contact information.
     */
    function updateProfile(uint256 _profileId, string memory _newContactInfoCID) external onlySynapseNexus {
        require(_exists(_profileId), "SNRN: Profile NFT does not exist");
        researcherProfiles[_profileId].contactInfoCID = _newContactInfoCID;
        emit ResearcherProfileUpdated(_profileId, _newContactInfoCID);
    }

    /**
     * @dev Dynamically updates the successful projects and reputation score of a researcher's NFT.
     *      This function makes the NFT "dynamic" as its underlying data changes based on on-chain actions.
     *      Only callable by the main SynapseNexus contract.
     * @param _profileId The ID of the researcher's NFT.
     * @param _successfulProjects The new count of successful projects.
     * @param _reputationScore The new cumulative reputation score.
     */
    function updateStats(uint256 _profileId, uint256 _successfulProjects, uint256 _reputationScore)
        external
        onlySynapseNexus
    {
        require(_exists(_profileId), "SNRN: Profile NFT does not exist");
        researcherProfiles[_profileId].successfulProjects = _successfulProjects;
        researcherProfiles[_profileId].reputationScore = _reputationScore;
        // In a real dNFT, this would trigger an update for metadata resolvers.
        emit ResearcherStatsUpdated(_profileId, _successfulProjects, _reputationScore);
    }
}
```

**2. `SynapseNexusProjectIP.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title SynapseNexusProjectIP
 * @dev ERC721 contract for tokenizing intellectual property (IP) of completed projects.
 *      Allows granting and revoking licenses, and distributing collected royalties.
 */
contract SynapseNexusProjectIP is ERC721URIStorage, Ownable {
    // Struct to represent an IP license
    struct IPLicense {
        address licensee;
        uint256 fee; // in wei
        uint256 duration; // in seconds
        uint256 grantedAt;
        bool active;
    }

    // Mapping from IP token ID to its associated IPFS CID
    mapping(uint256 => string) public ipCID;
    // Mapping from IP token ID to a list of granted licenses
    mapping(uint256 => IPLicense[]) public licenses;
    // Mapping from IP token ID to collected license fees awaiting distribution
    mapping(uint256 => uint256) public ipCollectedFees;

    // Events for tracking IP and license actions
    event IPTokenMinted(uint256 indexed ipTokenId, address indexed owner, string ipCID);
    event IPLicenseGranted(uint256 indexed ipTokenId, address indexed licensee, uint256 fee, uint256 duration);
    event IPLicenseRevoked(uint256 indexed ipTokenId, address indexed licensee);
    event RoyaltiesDistributed(uint256 indexed ipTokenId, uint256 amount);

    /**
     * @dev Constructor to initialize the ERC721 and set the owner (which will be the main SynapseNexus contract).
     * @param _owner The address of the SynapseNexus contract.
     */
    constructor(address _owner) ERC721("SynapseNexusProjectIP", "SNPI") Ownable(_owner) {}

    /**
     * @dev Modifier to restrict calls only from the main SynapseNexus contract.
     */
    modifier onlySynapseNexus() {
        require(msg.sender == owner(), "SNPI: Only SynapseNexus can call");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is the owner or an approved operator of the given token ID.
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "SNPI: Not owner or approved for IP");
        _;
    }

    /**
     * @dev Overrides the base URI for token metadata.
     *      For IP NFTs, the token URI directly points to the IPFS CID of the IP itself.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Standard IPFS URI prefix
    }

    /**
     * @dev Mints a new Project IP NFT.
     *      Only callable by the main SynapseNexus contract after project verification.
     * @param _to The address to mint the NFT to (typically the project proposer).
     * @param _ipCID The IPFS CID representing the intellectual property.
     * @return The ID of the newly minted IP NFT.
     */
    function mintIP(address _to, string memory _ipCID) external onlySynapseNexus returns (uint256) {
        uint256 newItemId = totalSupply() + 1;
        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, _ipCID); // Set IPFS CID as token URI directly
        ipCID[newItemId] = _ipCID; // Store for internal lookup

        emit IPTokenMinted(newItemId, _to, _ipCID);
        return newItemId;
    }

    /**
     * @dev Grants a new license for the specified IP NFT.
     *      Callable by the owner of the IP NFT.
     *      The `msg.value` (license fee) is collected by the contract and held for the IP owner.
     * @param _ipTokenId The ID of the IP NFT.
     * @param _licensee The address of the party receiving the license.
     * @param _licenseFee The fee required for this license (in wei).
     * @param _duration The duration of the license in seconds.
     */
    function grantLicense(uint256 _ipTokenId, address _licensee, uint256 _licenseFee, uint256 _duration)
        external
        onlyOwnerOf(_ipTokenId)
        payable
    {
        require(msg.value == _licenseFee, "SNPI: Insufficient license fee provided");
        
        licenses[_ipTokenId].push(
            IPLicense({
                licensee: _licensee,
                fee: _licenseFee,
                duration: _duration,
                grantedAt: block.timestamp,
                active: true
            })
        );
        ipCollectedFees[_ipTokenId] += msg.value; // Accumulate fees for this IP
        emit IPLicenseGranted(_ipTokenId, _licensee, _licenseFee, _duration);
    }

    /**
     * @dev Revokes an active license for the specified IP NFT.
     *      Callable by the owner of the IP NFT.
     * @param _ipTokenId The ID of the IP NFT.
     * @param _licensee The address of the licensee whose license is to be revoked.
     */
    function revokeLicense(uint256 _ipTokenId, address _licensee) external onlyOwnerOf(_ipTokenId) {
        bool found = false;
        for (uint256 i = 0; i < licenses[_ipTokenId].length; i++) {
            if (licenses[_ipTokenId][i].licensee == _licensee && licenses[_ipTokenId][i].active) {
                licenses[_ipTokenId][i].active = false; // Mark as inactive
                found = true;
                break;
            }
        }
        require(found, "SNPI: Active license not found for this licensee");
        emit IPLicenseRevoked(_ipTokenId, _licensee);
    }

    /**
     * @dev Distributes accumulated license fees for a specific IP NFT to its owner.
     *      Callable by the owner of the IP NFT.
     *      Ensures that only fees collected for *this* IP are sent.
     * @param _ipTokenId The ID of the IP NFT.
     */
    function distributeRoyalties(uint256 _ipTokenId) external onlyOwnerOf(_ipTokenId) {
        require(ipCollectedFees[_ipTokenId] > 0, "SNPI: No fees to distribute for this IP");
        
        uint256 amount = ipCollectedFees[_ipTokenId];
        ipCollectedFees[_ipTokenId] = 0; // Reset collected fees after distribution
        
        // Transfer collected fees to the current IP owner
        payable(ownerOf(_ipTokenId)).transfer(amount);
        emit RoyaltiesDistributed(_ipTokenId, amount);
    }
}
```

**3. `SynapseNexus.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Import our custom NFT contracts
import "./SynapseNexusResearcherNFT.sol";
import "./SynapseNexusProjectIP.sol";

/**
 * @title IAIOracle
 * @dev Interface for the AI Oracle contract. Defines the function that the oracle
 *      will call to submit AI review results to SynapseNexus.
 */
interface IAIOracle {
    function receiveAIReview(uint256 _projectId, string calldata _aiReviewCID, uint256 _aiScore) external;
}

// Custom Errors for gas efficiency and clarity
error SN_InvalidProjectState();
error SN_FundingGoalNotMet();
error SN_ProjectAlreadyExists(); // Not strictly used with `nextProjectId` but good to have.
error SN_ProjectNotFound();
error SN_NotProjectProposer();
error SN_FundingNotReleased();
error SN_AlreadyReviewed(); // Not strictly used with current review logic
error SN_NotApprovedReviewer();
error SN_ProjectNotApproved();
error SN_OutcomeNotVerified();
error SN_CannotRefundYet();
error SN_NoFundsToRefund();
error SN_ProjectFinished(); // Not strictly used, replaced by other states.
error SN_CannotCancelApprovedProject();
error SN_DisputeNotFound();
error SN_NotDisputeResolver(); // Not strictly used with `onlyOwner`
error SN_ResearcherNotRegistered();

/**
 * @title SynapseNexus
 * @dev The main smart contract for a decentralized AI-Augmented Innovation Hub.
 *      Manages researcher profiles (Dynamic NFTs), project submission, funding,
 *      AI & human reviews, IP tokenization, and dispute resolution.
 */
contract SynapseNexus is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---

    SynapseNexusResearcherNFT public researcherNFT; // Instance of the Researcher NFT contract
    SynapseNexusProjectIP public projectIPNFT;     // Instance of the Project IP NFT contract
    address public aiOracleAddress;                 // Address of the trusted AI Oracle

    // Enum to define the various states a project can be in
    enum ProjectStatus {
        Proposed,         // Initial state, awaiting funding and review
        AwaitingReview,   // Funding started, awaiting AI/Human review or full funding
        UnderReview,      // AI/Human reviews are actively ongoing
        Approved,         // Sufficiently funded and positively reviewed
        InProgress,       // Funds released to researcher, work commenced
        OutcomeSubmitted, // Researcher submitted outcome/results
        OutcomeVerified,  // Outcome verified by governance/verifiers
        Completed,        // Project fully finished, IP minted
        Failed,           // Did not meet funding, cancelled, or outcome rejected
        Disputed          // Project is under dispute resolution
    }

    // Struct to hold all relevant data for a research project
    struct Project {
        uint256 projectId;
        uint256 researcherProfileId; // Link to the researcher's NFT profile
        address proposer;
        string title;
        string descriptionCID; // IPFS CID for detailed proposal description
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 fundingDeadline;
        ProjectStatus status;
        string aiReviewCID; // IPFS CID for AI review report
        uint256 aiScore; // AI's assessment score (e.g., 0-100)
        uint256 humanReviewCount;
        uint256 totalHumanRating; // Sum of all human ratings (e.g., 1-5)
        string outcomeCID; // IPFS CID for project outcome/results
        uint256 ipTokenId; // ID of the minted Project IP NFT (0 if not minted)
        mapping(address => uint256) funders; // How much each funder contributed
        bool fundWithdrawalAttempted; // To prevent multiple fund withdrawals by proposer
    }

    uint256 public nextProjectId; // Counter for unique project IDs
    mapping(uint256 => Project) public projects; // Mapping from project ID to Project struct
    mapping(uint256 => address[]) public projectFundersList; // List of unique funders per project for refunds

    // For human reviewers
    address[] public approvedReviewers; // List of addresses approved to review projects
    mapping(address => bool) public isApprovedReviewer; // Quick lookup for approved reviewers

    // Dispute management
    struct Dispute {
        uint256 projectId;
        address raiser;
        string reasonCID; // IPFS CID for the reason/details of the dispute
        bool resolved;
        bool resultApproved; // True if dispute resolved in favor of initial state/proposer, false if not
    }
    uint256 public nextDisputeId; // Counter for unique dispute IDs
    mapping(uint256 => Dispute) public disputes; // Mapping from dispute ID to Dispute struct

    // --- Events ---
    event ResearcherRegistered(uint256 indexed profileId, address indexed researcherAddress, string name);
    event ResearchProposalSubmitted(uint256 indexed projectId, uint256 indexed researcherProfileId, string title, uint256 fundingGoal, uint256 deadline);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount, uint256 currentFunding);
    event ProjectFundingWithdrawn(uint256 indexed projectId, address indexed researcher, uint256 amount);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);
    event AIReviewReceived(uint256 indexed projectId, string aiReviewCID, uint256 aiScore);
    event HumanReviewSubmitted(uint256 indexed projectId, address indexed reviewer, uint256 rating);
    event ProjectApproved(uint256 indexed projectId);
    event ProjectOutcomeSubmitted(uint256 indexed projectId, string outcomeCID);
    event ProjectOutcomeVerified(uint256 indexed projectId);
    event ProjectIPMinted(uint256 indexed projectId, uint256 indexed ipTokenId);
    event ProjectCancelled(uint256 indexed projectId);
    event FundsRefunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed projectId, address indexed raiser);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed projectId, bool resultApproved);

    // --- Constructor ---
    /**
     * @dev Initializes the SynapseNexus contract, setting up references to the
     *      Researcher NFT, Project IP NFT, and AI Oracle contracts.
     * @param _researcherNFTAddress The address of the deployed SynapseNexusResearcherNFT contract.
     * @param _projectIPNFTAddress The address of the deployed SynapseNexusProjectIP contract.
     * @param _aiOracleAddress The address of the trusted AI Oracle contract.
     */
    constructor(address _researcherNFTAddress, address _projectIPNFTAddress, address _aiOracleAddress) Ownable(msg.sender) {
        require(_researcherNFTAddress != address(0), "SN: Invalid Researcher NFT address");
        require(_projectIPNFTAddress != address(0), "SN: Invalid Project IP NFT address");
        require(_aiOracleAddress != address(0), "SN: Invalid AI Oracle address");

        researcherNFT = SynapseNexusResearcherNFT(_researcherNFTAddress);
        projectIPNFT = SynapseNexusProjectIP(_projectIPNFTAddress);
        aiOracleAddress = _aiOracleAddress;

        // Add deployer as an initial approved reviewer (for testing/setup purposes)
        addApprovedReviewer(msg.sender);
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Callable only by the contract owner (governance).
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, re-enabling operations.
     *      Callable only by the contract owner (governance).
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Transfers ownership (governance) of the contract.
     *      Callable only by the current owner.
     * @param newGovernance The address of the new governance entity.
     */
    function setGovernanceAddress(address newGovernance) external onlyOwner {
        _transferOwnership(newGovernance);
    }

    /**
     * @dev Sets or updates the address of the trusted AI Oracle contract.
     *      Callable only by the contract owner (governance).
     * @param _newOracleAddress The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "SN: Invalid new oracle address");
        aiOracleAddress = _newOracleAddress;
    }

    /**
     * @dev Adds an address to the list of approved human reviewers.
     *      Callable only by the contract owner (governance).
     * @param _reviewer The address to approve.
     */
    function addApprovedReviewer(address _reviewer) public onlyOwner {
        require(!isApprovedReviewer[_reviewer], "SN: Reviewer already approved");
        approvedReviewers.push(_reviewer);
        isApprovedReviewer[_reviewer] = true;
    }

    /**
     * @dev Removes an address from the list of approved human reviewers.
     *      Callable only by the contract owner (governance).
     * @param _reviewer The address to remove.
     */
    function removeApprovedReviewer(address _reviewer) public onlyOwner {
        require(isApprovedReviewer[_reviewer], "SN: Reviewer not approved");
        isApprovedReviewer[_reviewer] = false;
        // Simple array removal (less efficient for very large arrays, but acceptable here)
        for (uint i = 0; i < approvedReviewers.length; i++) {
            if (approvedReviewers[i] == _reviewer) {
                approvedReviewers[i] = approvedReviewers[approvedReviewers.length - 1];
                approvedReviewers.pop();
                break;
            }
        }
    }

    // --- II. Researcher Profiles & Reputation (Dynamic ERC721) ---

    /**
     * @dev Registers a new researcher by minting a unique Researcher Profile NFT.
     *      Each address can only register one profile.
     * @param _name The public name of the researcher.
     * @param _contactInfoCID IPFS CID for detailed contact information or bio.
     * @return The ID of the newly created researcher profile NFT.
     */
    function registerResearcher(string calldata _name, string calldata _contactInfoCID)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 profileId = researcherNFT.researcherProfileId(msg.sender);
        if (profileId == 0) revert SN_ResearcherNotRegistered(); // If it's 0, it means no profile exists for msg.sender

        // Mint a new researcher NFT via the dedicated contract
        profileId = researcherNFT.mint(msg.sender, _name, _contactInfoCID);
        emit ResearcherRegistered(profileId, msg.sender, _name);
        return profileId;
    }

    /**
     * @dev Allows a researcher to update the contact information associated with their profile NFT.
     * @param _profileId The ID of the researcher's NFT.
     * @param _newContactInfoCID The new IPFS CID for contact information.
     */
    function updateResearcherProfile(uint256 _profileId, string calldata _newContactInfoCID) external whenNotPaused {
        require(researcherNFT.ownerOf(_profileId) == msg.sender, "SN: Not your researcher profile");
        researcherNFT.updateProfile(_profileId, _newContactInfoCID);
    }

    /**
     * @dev Retrieves the detailed profile information for a given researcher NFT ID.
     * @param _profileId The ID of the researcher's NFT.
     * @return name The researcher's name.
     * @return contactInfoCID IPFS CID of their contact/bio.
     * @return successfulProjects The count of their successful projects.
     * @return reputationScore Their cumulative reputation score.
     */
    function getResearcherProfile(uint256 _profileId)
        external
        view
        returns (string memory name, string memory contactInfoCID, uint256 successfulProjects, uint256 reputationScore)
    {
        SynapseNexusResearcherNFT.ResearcherData memory data = researcherNFT.researcherProfiles(_profileId);
        return (data.name, data.contactInfoCID, data.successfulProjects, data.reputationScore);
    }

    // --- III. Project Submission & Funding ---

    /**
     * @dev Allows a registered researcher to submit a new R&D project proposal.
     * @param _title The title of the research project.
     * @param _descriptionCID IPFS CID pointing to the full project description.
     * @param _fundingGoal The target funding amount in wei.
     * @param _fundingDurationDays The duration (in days) for the funding period.
     * @return The ID of the newly submitted project.
     */
    function submitResearchProposal(
        string calldata _title,
        string calldata _descriptionCID,
        uint256 _fundingGoal,
        uint256 _fundingDurationDays // Duration in days for funding deadline
    ) external whenNotPaused returns (uint256) {
        uint256 researcherProfileId = researcherNFT.researcherProfileId(msg.sender);
        if (researcherProfileId == 0) revert SN_ResearcherNotRegistered(); // Ensure proposer is a registered researcher

        uint256 newProjectId = nextProjectId++;
        projects[newProjectId] = Project({
            projectId: newProjectId,
            researcherProfileId: researcherProfileId,
            proposer: msg.sender,
            title: _title,
            descriptionCID: _descriptionCID,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            fundingDeadline: block.timestamp + (_fundingDurationDays * 1 days), // Calculate deadline
            status: ProjectStatus.Proposed,
            aiReviewCID: "",
            aiScore: 0,
            humanReviewCount: 0,
            totalHumanRating: 0,
            outcomeCID: "",
            ipTokenId: 0,
            fundWithdrawalAttempted: false
        });

        emit ResearchProposalSubmitted(newProjectId, researcherProfileId, _title, _fundingGoal, projects[newProjectId].fundingDeadline);
        return newProjectId;
    }

    /**
     * @dev Allows users to contribute Ether to a project's funding goal.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        require(project.status <= ProjectStatus.UnderReview, "SN: Project not in fundable state"); // Can fund up to UnderReview
        require(block.timestamp < project.fundingDeadline, "SN: Funding period for project has ended");
        require(msg.value > 0, "SN: Funding amount must be greater than zero");

        project.currentFunding += msg.value;
        if (project.funders[msg.sender] == 0) { // If first time funding this project by this sender
             projectFundersList[_projectId].push(msg.sender); // Add funder to list for potential refunds
        }
        project.funders[msg.sender] += msg.value;

        // Transition status if enough funds are met and not already under review
        if (project.currentFunding >= project.fundingGoal && project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.AwaitingReview; // Ready for reviews once funded
            emit ProjectStatusUpdated(_projectId, ProjectStatus.AwaitingReview);
        } else if (project.status == ProjectStatus.Proposed) {
            // If it received first funding, but not yet full, just update status
            project.status = ProjectStatus.AwaitingReview;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.AwaitingReview);
        }

        emit ProjectFunded(_projectId, msg.sender, msg.value, project.currentFunding);
    }

    /**
     * @dev Allows the project proposer to withdraw collected funds once the project is approved.
     * @param _projectId The ID of the project to withdraw funds from.
     */
    function withdrawFunding(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        if (project.proposer != msg.sender) revert SN_NotProjectProposer();
        if (project.status != ProjectStatus.Approved) revert SN_ProjectNotApproved();
        if (project.currentFunding < project.fundingGoal) revert SN_FundingGoalNotMet(); // Should be caught by ProjectNotApproved
        if (project.fundWithdrawalAttempted) revert SN_FundingNotReleased(); // Prevent multiple withdrawals

        project.fundWithdrawalAttempted = true; // Mark attempt to prevent re-entrancy issues if transfer fails

        // Transfer funds to the proposer
        uint256 amountToTransfer = project.currentFunding;
        project.currentFunding = 0; // Reset as funds are transferred
        
        (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
        require(success, "SN: Funding transfer failed");

        project.status = ProjectStatus.InProgress;
        emit ProjectFundingWithdrawn(_projectId, msg.sender, amountToTransfer);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.InProgress);
    }

    /**
     * @dev Allows the project proposer or governance to cancel a project.
     *      Cannot cancel projects that are already approved or beyond.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        require(project.proposer == msg.sender || msg.sender == owner(), "SN: Not authorized to cancel project");
        if (project.status >= ProjectStatus.Approved) revert SN_CannotCancelApprovedProject();

        project.status = ProjectStatus.Failed;
        emit ProjectCancelled(_projectId);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Failed);
    }

    /**
     * @dev Allows a funder to claim a refund if a project fails (e.g., funding goal not met by deadline, or cancelled).
     * @param _projectId The ID of the project.
     */
    function refundFailedProject(uint256 _projectId) external whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();

        // Automatically set project to Failed if deadline passed and funding goal not met
        if (block.timestamp >= project.fundingDeadline && project.currentFunding < project.fundingGoal && project.status < ProjectStatus.Approved) {
            project.status = ProjectStatus.Failed;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Failed);
        }
        
        require(project.status == ProjectStatus.Failed, "SN: Project is not in a failed state for refunds");

        uint256 amountToRefund = project.funders[msg.sender];
        if (amountToRefund == 0) revert SN_NoFundsToRefund();

        project.funders[msg.sender] = 0; // Clear amount for this specific funder to prevent multiple refunds

        (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
        require(success, "SN: Refund transfer failed");

        emit FundsRefunded(_projectId, msg.sender, amountToRefund);
    }

    // --- IV. AI-Augmented Review & Evaluation ---

    /**
     * @dev Triggers a conceptual request for an AI review of a project proposal.
     *      In a real system, this would interact with an off-chain oracle service.
     * @param _projectId The ID of the project to review.
     */
    function requestAIReview(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        require(project.proposer == msg.sender || msg.sender == owner(), "SN: Only proposer or governance can request AI review");
        require(project.status == ProjectStatus.AwaitingReview || project.status == ProjectStatus.UnderReview, "SN: Project not in reviewable state");
        require(bytes(project.aiReviewCID).length == 0, "SN: AI review already requested/received");

        // Set status to UnderReview to indicate that reviews are pending.
        project.status = ProjectStatus.UnderReview;
        emit ProjectStatusUpdated(_projectId, ProjectStatus.UnderReview);
        // In a live system, this might trigger an off-chain oracle to pick up the review request.
        // For example: IAIOracle(aiOracleAddress).requestReviewOffChain(_projectId, project.descriptionCID);
    }

    /**
     * @dev Callback function used by the trusted AI Oracle to submit its review results.
     *      Only callable by the designated `aiOracleAddress`.
     * @param _projectId The ID of the project being reviewed.
     * @param _aiReviewCID IPFS CID for the detailed AI review report.
     * @param _aiScore The AI's assessment score (e.g., 0-100).
     */
    function receiveAIReview(uint256 _projectId, string calldata _aiReviewCID, uint256 _aiScore) external {
        require(msg.sender == aiOracleAddress, "SN: Only trusted AI Oracle can call this function");
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        require(project.status == ProjectStatus.UnderReview || project.status == ProjectStatus.AwaitingReview, "SN: Project not in review state");
        require(bytes(project.aiReviewCID).length == 0, "SN: AI review already received");

        project.aiReviewCID = _aiReviewCID;
        project.aiScore = _aiScore;
        
        emit AIReviewReceived(_projectId, _aiReviewCID, _aiScore);

        // If both AI and human reviews (at least one for human) are available, attempt approval
        if (project.humanReviewCount > 0) {
             _evaluateAndApproveProject(_projectId);
        }
    }

    /**
     * @dev Allows an approved human reviewer to submit their assessment of a project.
     * @param _projectId The ID of the project being reviewed.
     * @param _reviewCID IPFS CID for the detailed human review report.
     * @param _rating The human reviewer's rating (e.g., 1 to 5).
     */
    function submitHumanReview(uint256 _projectId, string calldata _reviewCID, uint256 _rating) external whenNotPaused {
        require(isApprovedReviewer[msg.sender], "SN: You are not an approved reviewer");
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        require(project.status == ProjectStatus.AwaitingReview || project.status == ProjectStatus.UnderReview, "SN: Project not in reviewable state");
        require(_rating >=1 && _rating <= 5, "SN: Rating must be between 1 and 5"); // Example rating scale

        // Update human review counts and total rating
        project.humanReviewCount++;
        project.totalHumanRating += _rating;
        // In a more complex system, you might store individual reviews and prevent multiple reviews from one person.
        
        emit HumanReviewSubmitted(_projectId, msg.sender, _rating);

        // If AI review is available, and a human review submitted, attempt approval
        if (bytes(project.aiReviewCID).length > 0) {
             _evaluateAndApproveProject(_projectId);
        }
    }

    /**
     * @dev Internal function to evaluate a project for approval based on funding, AI score, and human reviews.
     * @param _projectId The ID of the project to evaluate.
     */
    function _evaluateAndApproveProject(uint256 _projectId) internal {
        Project storage project = projects[_projectId];

        // First, check funding status and deadline
        if (block.timestamp >= project.fundingDeadline && project.currentFunding < project.fundingGoal) {
            project.status = ProjectStatus.Failed;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Failed);
            return; // Project failed due to insufficient funding/deadline
        }
        
        if (project.currentFunding < project.fundingGoal) {
            return; // Not fully funded yet, cannot approve
        }

        // Approval logic: Requires sufficient AI score, at least one human review, and average human rating.
        // This threshold can be adjusted based on desired strictness.
        if (project.aiScore >= 70 && project.humanReviewCount > 0 && (project.totalHumanRating / project.humanReviewCount) >= 3) {
            project.status = ProjectStatus.Approved;
            emit ProjectApproved(_projectId);
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Approved);
        }
    }

    /**
     * @dev Callable by anyone to trigger a re-evaluation of a project for approval.
     *      Useful if conditions (like funding) change or deadline passes.
     * @param _projectId The ID of the project to re-evaluate.
     */
    function evaluateProjectForApproval(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        require(project.status < ProjectStatus.Approved, "SN: Project already approved or beyond approval stage");
        
        _evaluateAndApproveProject(_projectId);
    }

    // --- V. Project Completion & IP Management (ERC721) ---

    /**
     * @dev Allows the researcher to submit the final outcome or results of their project.
     * @param _projectId The ID of the project.
     * @param _outcomeCID IPFS CID pointing to the project's outcome (e.g., research paper, code).
     */
    function submitProjectOutcome(uint256 _projectId, string calldata _outcomeCID) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        if (project.proposer != msg.sender) revert SN_NotProjectProposer();
        require(project.status == ProjectStatus.InProgress, "SN: Project not in progress state");
        
        project.outcomeCID = _outcomeCID;
        project.status = ProjectStatus.OutcomeSubmitted;
        emit ProjectOutcomeSubmitted(_projectId, _outcomeCID);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.OutcomeSubmitted);
    }

    /**
     * @dev Governance function to officially verify the submitted project outcome.
     *      Upon verification, the Project IP NFT is minted, and the researcher's profile stats are updated.
     * @param _projectId The ID of the project whose outcome is to be verified.
     */
    function verifyProjectOutcome(uint256 _projectId) external onlyOwner whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        require(project.status == ProjectStatus.OutcomeSubmitted, "SN: Project outcome not submitted");
        require(bytes(project.outcomeCID).length > 0, "SN: Project outcome CID is empty");

        project.status = ProjectStatus.OutcomeVerified;
        emit ProjectOutcomeVerified(_projectId);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.OutcomeVerified);
        
        // After verification, proceed to complete the project and mint the IP NFT
        _completeProjectAndMintIP(_projectId);
    }

    /**
     * @dev Internal function to finalize a project, mint its IP NFT, and update researcher's stats.
     * @param _projectId The ID of the project to finalize.
     */
    function _completeProjectAndMintIP(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.OutcomeVerified, "SN: Project outcome not verified");

        // Mint Project IP NFT through the dedicated contract
        uint256 ipId = projectIPNFT.mintIP(project.proposer, project.outcomeCID);
        project.ipTokenId = ipId;
        project.status = ProjectStatus.Completed;

        // Update researcher's dynamic NFT stats (successful projects, reputation)
        SynapseNexusResearcherNFT.ResearcherData memory researcherData = researcherNFT.researcherProfiles(project.researcherProfileId);
        researcherNFT.updateStats(
            project.researcherProfileId,
            researcherData.successfulProjects + 1, // Increment successful projects count
            researcherData.reputationScore + 100   // Add a fixed reputation bonus
        );

        emit ProjectIPMinted(_projectId, ipId);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Completed);
    }

    /**
     * @dev Forwards a request to grant an IP license to the `SynapseNexusProjectIP` contract.
     *      The caller must be the owner of the IP NFT.
     * @param _ipTokenId The ID of the IP NFT.
     * @param _licensee The address of the party receiving the license.
     * @param _licenseFee The fee for the license (in wei).
     * @param _duration The duration of the license in seconds.
     */
    function grantIPLicense(uint256 _ipTokenId, address _licensee, uint256 _licenseFee, uint256 _duration) external payable whenNotPaused {
        projectIPNFT.grantLicense{value: msg.value}(_ipTokenId, _licensee, _licenseFee, _duration);
    }

    /**
     * @dev Forwards a request to revoke an IP license to the `SynapseNexusProjectIP` contract.
     *      The caller must be the owner of the IP NFT.
     * @param _ipTokenId The ID of the IP NFT.
     * @param _licensee The address of the licensee whose license is to be revoked.
     */
    function revokeIPLicense(uint256 _ipTokenId, address _licensee) external whenNotPaused {
        projectIPNFT.revokeLicense(_ipTokenId, _licensee);
    }

    /**
     * @dev Forwards a request to distribute accumulated IP license royalties to the `SynapseNexusProjectIP` contract.
     *      The caller must be the owner of the IP NFT.
     * @param _ipTokenId The ID of the IP NFT.
     */
    function distributeIPRoyalties(uint256 _ipTokenId) external whenNotPaused {
        projectIPNFT.distributeRoyalties(_ipTokenId);
    }

    // --- VI. Dispute Resolution & Governance ---

    /**
     * @dev Allows any user to raise a dispute regarding a project.
     *      Sets the project status to `Disputed`, pausing its progression.
     * @param _projectId The ID of the project the dispute is about.
     * @param _reasonCID IPFS CID for the detailed reason for the dispute.
     */
    function raiseDispute(uint256 _projectId, string calldata _reasonCID) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        // Prevent disputes on projects already completed or explicitly failed
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Failed, "SN: Cannot raise dispute for completed or failed projects");

        uint256 newDisputeId = nextDisputeId++;
        disputes[newDisputeId] = Dispute({
            projectId: _projectId,
            raiser: msg.sender,
            reasonCID: _reasonCID,
            resolved: false,
            resultApproved: false
        });
        project.status = ProjectStatus.Disputed; // Pause project progression
        emit DisputeRaised(newDisputeId, _projectId, msg.sender);
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Disputed);
    }

    /**
     * @dev Governance function to officially resolve a raised dispute.
     *      Determines the new status of the project based on the resolution outcome.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isApprovedOutcome A boolean indicating the resolution:
     *      - `true`: The original project outcome/state is approved (dispute rejected).
     *      - `false`: The dispute is upheld (e.g., project fails, or requires correction).
     */
    function resolveDispute(uint256 _disputeId, bool _isApprovedOutcome) external onlyOwner whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        // Using projectId == 0 check, as it implies a non-existent dispute for a fresh mapping
        if (dispute.projectId == 0) revert SN_DisputeNotFound(); 
        require(!dispute.resolved, "SN: Dispute already resolved");

        dispute.resolved = true;
        dispute.resultApproved = _isApprovedOutcome; 

        Project storage project = projects[dispute.projectId];
        if (_isApprovedOutcome) {
            // If the original project outcome is approved, revert its status to allow it to proceed.
            // Simplified: If it was disputed, assume it was awaiting outcome verification.
            if (project.status == ProjectStatus.Disputed) {
                 project.status = ProjectStatus.OutcomeSubmitted; // Back to being verifiable
            }
        } else {
            // If the dispute is upheld (original outcome rejected), the project fails.
            project.status = ProjectStatus.Failed;
            // Additional logic could be added here, e.g., triggering refunds if IP was not minted.
        }
        
        emit DisputeResolved(_disputeId, dispute.projectId, _isApprovedOutcome);
        emit ProjectStatusUpdated(dispute.projectId, project.status);
    }

    // --- VII. Views & Utilities ---

    /**
     * @dev Retrieves comprehensive details of a specific project.
     * @param _projectId The ID of the project to query.
     * @return All fields of the `Project` struct.
     */
    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            uint256 projectId,
            uint256 researcherProfileId,
            address proposer,
            string memory title,
            string memory descriptionCID,
            uint256 fundingGoal,
            uint256 currentFunding,
            uint256 fundingDeadline,
            ProjectStatus status,
            string memory aiReviewCID,
            uint256 aiScore,
            uint256 humanReviewCount,
            uint256 totalHumanRating,
            string memory outcomeCID,
            uint256 ipTokenId
        )
    {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();

        return (
            project.projectId,
            project.researcherProfileId,
            project.proposer,
            project.title,
            project.descriptionCID,
            project.fundingGoal,
            project.currentFunding,
            project.fundingDeadline,
            project.status,
            project.aiReviewCID,
            project.aiScore,
            project.humanReviewCount,
            project.totalHumanRating,
            project.outcomeCID,
            project.ipTokenId
        );
    }

    /**
     * @dev Retrieves the current status of a specific project.
     * @param _projectId The ID of the project to query.
     * @return The `ProjectStatus` enum value.
     */
    function getProjectStatus(uint256 _projectId) external view returns (ProjectStatus) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        return project.status;
    }

    /**
     * @dev Retrieves the amount a specific funder has contributed to a project.
     * @param _projectId The ID of the project.
     * @param _funder The address of the funder.
     * @return The amount contributed by the funder in wei.
     */
    function getProjectFunderAmount(uint256 _projectId, address _funder) external view returns (uint256) {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert SN_ProjectNotFound();
        return project.funders[_funder];
    }
}
```