This smart contract suite, named "DAIRIN" (Decentralized Autonomous Reputation & Influence Network), aims to create a dynamic, self-evolving community where influence is earned through valuable contributions, some of which are validated by an AI oracle. It blends concepts of Soulbound Tokens (SBTs) for reputation, dynamic NFTs for tiered recognition, AI-driven content moderation/validation, and a comprehensive governance system.

---

## **DAIRIN (Decentralized Autonomous Reputation & Influence Network) - Contract Suite**

This suite consists of two primary contracts:
1.  **`DAIRIN_Core.sol`**: The main logic contract for managing influence points, contributions, proposals, bounties, and interacting with the AI Oracle.
2.  **`DAIRIN_InfluenceNFT.sol`**: A custom ERC721 contract representing dynamic, non-transferable Influence Tier NFTs, whose metadata reflects the holder's earned reputation.

---

### **Outline & Function Summary**

**I. `DAIRIN_Core.sol`**

*   **Core Concepts:**
    *   **Influence Points (IP):** Non-transferable, quantifiable measure of a user's value and activity within the network.
    *   **Influence Tiers:** Defined thresholds of IP that grant users different levels of status and voting power, represented by Dynamic NFTs.
    *   **AI Oracle Integration:** Leverages an external AI service (simulated via an interface) to validate certain types of contributions, promoting fair and objective assessment.
    *   **Contribution System:** Users submit various types of contributions (code, content, support), which can be manually approved or AI-validated.
    *   **Decentralized Governance:** IP and Influence Tier NFTs grant voting power for proposals that affect the network's parameters or treasury.
    *   **Bounty System:** A mechanism for the community to request and fund specific tasks, rewarding contributors based on their IP.
    *   **Delegation:** Users can delegate their IP to others for voting purposes.
    *   **Slashing:** A mechanism to penalize malicious behavior by revoking IP.

*   **Function Categories & Summaries:**

    *   **A. Initialization & Admin (7 functions):**
        1.  `constructor()`: Initializes the contract, sets the `owner`, AI Oracle address, and deploys the `DAIRIN_InfluenceNFT` contract.
        2.  `setAIOracleAddress(address _aiOracle)`: Sets or updates the trusted AI Oracle contract address.
        3.  `setInfluenceNFTAddress(address _nftAddress)`: Sets or updates the address of the deployed `DAIRIN_InfluenceNFT` contract.
        4.  `setTierThresholds(uint256[] calldata _thresholds)`: Configures the IP thresholds for each Influence Tier.
        5.  `pause()`: Pauses core contract functionalities in emergencies (owner only).
        6.  `unpause()`: Unpauses the contract (owner only).
        7.  `withdrawTreasury(address _to, uint256 _amount)`: Allows the owner or governance to withdraw ETH from the contract's treasury.

    *   **B. Influence Points (IP) & Tier Management (5 functions):**
        8.  `grantInfluence(address _user, uint256 _amount)`: Grants Influence Points to a user. Callable by owner or successful AI validation.
        9.  `revokeInfluence(address _user, uint256 _amount)`: Revokes Influence Points from a user. Callable by owner or governance.
        10. `claimInfluenceTierNFT()`: Allows a user to claim/mint their Influence Tier NFT based on their current IP.
        11. `delegateInfluence(address _delegatee)`: Delegates a user's current and future IP to another address for voting.
        12. `undelegateInfluence()`: Removes influence delegation.

    *   **C. Contribution & Validation System (3 functions):**
        13. `submitContribution(string calldata _uri, ContributionType _type)`: Users submit a contribution (e.g., link to a code repo, article, support ticket).
        14. `receiveAIValidationResult(uint256 _contributionId, bool _isValid, uint256 _awardedIP)`: Callback function for the AI Oracle to report validation results.
        15. `disputeAIValidation(uint256 _contributionId)`: Allows a user to dispute an AI validation result, triggering a governance vote.

    *   **D. Decentralized Governance (3 functions):**
        16. `submitProposal(string calldata _description, address _target, bytes calldata _callData, uint256 _value)`: Users with sufficient IP can submit a governance proposal.
        17. `voteOnProposal(uint256 _proposalId, bool _support)`: Users vote on proposals using their accumulated IP and Tier benefits.
        18. `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal after the voting period ends.

    *   **E. Bounty System (4 functions):**
        19. `createBounty(string calldata _description, uint256 _rewardAmount, address _rewardToken)`: Creates a new bounty for specific tasks, funded by the treasury.
        20. `submitBountySolution(uint256 _bountyId, string calldata _solutionUri)`: Users submit a solution for an open bounty.
        21. `approveBountySolution(uint256 _bountyId, address _solver)`: Approves a submitted bounty solution (by owner or governance).
        22. `claimBountyReward(uint256 _bountyId)`: Allows the approved solver to claim their bounty reward.

    *   **F. Slashing (1 function):**
        23. `slashInfluence(address _user, uint256 _amount)`: Reduces a user's IP due to malicious or disruptive behavior, decided by governance.

    *   **G. View Functions (6 functions):**
        24. `getInfluencePoints(address _user)`: Returns the current IP of a user.
        25. `getCurrentInfluenceTier(address _user)`: Returns the current Influence Tier of a user based on their IP.
        26. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
        27. `getBountyDetails(uint256 _bountyId)`: Retrieves details of a specific bounty.
        28. `getDelegatedInfluence(address _delegator)`: Returns the address to whom a user has delegated their influence.
        29. `getContributionDetails(uint256 _contributionId)`: Returns the details of a specific contribution.

**II. `DAIRIN_InfluenceNFT.sol`**

*   **Core Concepts:**
    *   **Non-Transferable ERC721:** Acts as a "Soulbound Token" representing reputation, preventing speculative trading.
    *   **Dynamic Metadata:** The `tokenURI` is designed to be dynamic, potentially reflecting current IP, last contribution, or other stats fetched from `DAIRIN_Core`.
    *   **Tier-based Minting:** NFTs are minted by the `DAIRIN_Core` contract only when a user reaches a new Influence Tier.
    *   **Unique Representation:** Each Tier has a unique identifier and potentially different visual representation.

*   **Function Categories & Summaries:**

    *   **A. Initialization & Core (3 functions):**
        1.  `constructor(address _coreContract, string memory _name, string memory _symbol)`: Initializes the ERC721 contract, linking it to the `DAIRIN_Core` contract.
        2.  `mintForTier(address _to, uint256 _tierId)`: Mints a new Influence Tier NFT for a user. Callable only by the `DAIRIN_Core` contract.
        3.  `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for a given token, reflecting the associated influence tier and potentially real-time data from the `DAIRIN_Core`.

    *   **B. Restricted ERC721 Functions (1 function):**
        4.  `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Internal override to prevent all transfers, making the NFTs non-transferable (soulbound).

---

### **Solidity Smart Contract Code**

For brevity and modularity, we'll separate the main logic and the NFT into two files, as is common practice.

**1. `interfaces/IAIOracle.sol`** (Interface for the AI Oracle)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAIOracle {
    /**
     * @dev Requests an AI validation for a specific contribution.
     * @param _callbackContract The address of the DAIRIN_Core contract to call back to.
     * @param _contributionId The ID of the contribution to validate.
     * @param _uri The URI of the contribution content (e.g., IPFS hash).
     * @param _contributionType The type of contribution (e.g., Code, Content).
     */
    function requestValidation(
        address _callbackContract,
        uint256 _contributionId,
        string calldata _uri,
        uint8 _contributionType
    ) external;

    /**
     * @dev Emitted when a validation request is made.
     * @param contributionId The ID of the contribution.
     * @param uri The URI of the contribution.
     */
    event ValidationRequested(uint256 contributionId, string uri);

    /**
     * @dev Emitted when a validation result is received.
     * @param contributionId The ID of the contribution.
     * @param isValid Whether the contribution was deemed valid.
     * @param awardedIP The IP awarded by the AI, if valid.
     */
    event ValidationResultReceived(uint256 contributionId, bool isValid, uint256 awardedIP);
}
```

**2. `DAIRIN_InfluenceNFT.sol`** (The Soulbound, Dynamic NFT)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IDAARINCore {
    function getInfluencePoints(address _user) external view returns (uint256);
    function getCurrentInfluenceTier(address _user) external view returns (uint256);
    function getTierThresholds() external view returns (uint256[] memory);
}

/**
 * @title DAIRIN_InfluenceNFT
 * @dev Represents a non-transferable, dynamic NFT for Influence Tiers in the DAIRIN system.
 *      Metadata dynamically reflects the user's influence.
 */
contract DAIRIN_InfluenceNFT is ERC721, Ownable {
    using Strings for uint256;

    IDAARINCore public DAIRINCore;

    // Mapping to store which tier a tokenId represents (optional, but good for clarity)
    mapping(uint256 => uint256) public tokenIdToTier;

    /**
     * @dev Emitted when a new Influence Tier NFT is minted.
     * @param to The address of the recipient.
     * @param tokenId The ID of the minted NFT.
     * @param tierId The tier level represented by the NFT.
     */
    event InfluenceNFTMinted(address indexed to, uint256 tokenId, uint256 tierId);

    /**
     * @dev Initializes the contract, setting the name, symbol, and linking to the DAIRIN_Core contract.
     * @param _coreContract The address of the DAIRIN_Core contract.
     * @param _name The name of the NFT collection.
     * @param _symbol The symbol of the NFT collection.
     */
    constructor(address _coreContract, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        require(_coreContract != address(0), "DAIRIN_InfluenceNFT: Core contract cannot be zero address");
        DAIRINCore = IDAARINCore(_coreContract);
    }

    /**
     * @dev Allows the DAIRIN_Core contract to mint a new Influence Tier NFT for a user.
     * @param _to The address to mint the NFT to.
     * @param _tierId The ID of the tier this NFT represents.
     * @return The tokenId of the newly minted NFT.
     */
    function mintForTier(address _to, uint256 _tierId) external onlyOwner returns (uint256) {
        // Ensure that the only caller is the DAIRIN_Core contract
        require(msg.sender == address(DAIRINCore), "DAIRIN_InfluenceNFT: Only DAIRIN_Core can mint");
        
        uint256 newItemId = _nextTokenId();
        _safeMint(_to, newItemId);
        tokenIdToTier[newItemId] = _tierId;

        emit InfluenceNFTMinted(_to, newItemId, _tierId);
        return newItemId;
    }

    /**
     * @dev Returns the dynamic metadata URI for a given token ID.
     *      This URI could point to a JSON file on IPFS that dynamically fetches
     *      data from the DAIRIN_Core contract to update the NFT's appearance/properties.
     * @param _tokenId The ID of the token.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        address ownerAddress = ownerOf(_tokenId);
        uint256 currentIP = DAIRINCore.getInfluencePoints(ownerAddress);
        uint256 currentTier = DAIRINCore.getCurrentInfluenceTier(ownerAddress);

        // In a real dApp, this would resolve to an IPFS CID like "ipfs://<CID>/metadata.json"
        // The metadata.json would then dynamically fetch the IP and Tier from DAIRIN_Core
        // and update the image/attributes.
        // For demonstration, we'll return a descriptive string.
        string memory baseURI = "ipfs://dairin-nft-metadata/"; // Placeholder base URI

        return string(
            abi.encodePacked(
                baseURI,
                _tokenId.toString(),
                "-tier",
                currentTier.toString(),
                "-ip",
                currentIP.toString(),
                ".json"
            )
        );
    }

    /**
     * @dev Internal function to increment the token ID counter.
     */
    uint256 private _currentId = 0;
    function _nextTokenId() private returns (uint256) {
        _currentId++;
        return _currentId;
    }

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to prevent transfers, making NFTs soulbound.
     * @param from The address the token is being transferred from.
     * @param to The address the token is being transferred to.
     * @param tokenId The ID of the token being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
        // Prevent transfers if the token is already minted
        if (from != address(0)) {
            revert("DAIRIN_InfluenceNFT: NFTs are non-transferable (soulbound)");
        }
    }
}
```

**3. `DAIRIN_Core.sol`** (The Main Logic Contract)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For bounty rewards

import "./interfaces/IAIOracle.sol";
import "./DAIRIN_InfluenceNFT.sol"; // Import the NFT contract

/**
 * @title DAIRIN_Core
 * @dev The core contract for the Decentralized Autonomous Reputation & Influence Network.
 *      Manages influence points, contributions, proposals, bounties, and interacts with the AI Oracle.
 */
contract DAIRIN_Core is Ownable, ReentrancyGuard, Pausable {

    // --- State Variables ---

    IAIOracle public aiOracle;
    DAIRIN_InfluenceNFT public influenceNFT;

    // Influence Points: user address => IP amount
    mapping(address => uint256) public influencePoints;
    // Delegation: delegator address => delegatee address
    mapping(address => address) public delegatedInfluence;
    // Current influence/voting power including self and delegated from others
    mapping(address => uint256) public totalDelegatedPower;

    // Tier configuration: Tier ID => Min IP required
    uint256[] public tierThresholds; // e.g., [0, 100, 500, 2000] for Tier 0, 1, 2, 3

    // Contributions
    struct Contribution {
        address contributor;
        string uri; // Link to content, code, etc. (e.g., IPFS hash)
        ContributionType cType;
        ContributionState state;
        uint256 timestamp;
        uint256 awardedIP;
        string aiValidationFeedback; // Feedback from AI Oracle
    }
    mapping(uint256 => Contribution) public contributions;
    uint256 public nextContributionId;

    enum ContributionType { Code, Content, CommunitySupport, BugReport, AISuggestedInsight }
    enum ContributionState { PendingAIValidation, PendingManualReview, AIRejected, AIApproved, ManuallyApproved, ManuallyRejected, Disputed }

    // Proposals
    struct Proposal {
        string description;
        address proposer;
        uint256 submittedAt;
        uint256 votingEndsAt;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotePowerAtSubmission; // Snapshot of total delegated power at submission
        ProposalState state;
        address target; // Target contract for execution
        bytes callData; // Calldata for target execution
        uint256 value; // ETH value to send with execution
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    uint256 public nextProposalId;
    uint256 public minInfluenceForProposal; // Minimum IP to submit a proposal
    uint256 public votingPeriodDuration; // Duration in seconds

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    // Bounties
    struct Bounty {
        string description;
        uint256 rewardAmount;
        address rewardToken; // Address of ERC20 token, 0x0 for ETH
        address creator;
        address solver; // Address who submitted the approved solution
        string solutionUri;
        BountyState state;
        uint256 createdAt;
        uint256 approvedAt;
    }
    mapping(uint256 => Bounty) public bounties;
    uint256 public nextBountyId;

    enum BountyState { Open, SolutionSubmitted, Approved, Claimed, Canceled }

    // --- Events ---

    event InfluenceGranted(address indexed user, uint256 amount);
    event InfluenceRevoked(address indexed user, uint256 amount);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event InfluenceUndelegated(address indexed delegator, address indexed previousDelegatee);
    event InfluenceTierNFTClaimed(address indexed user, uint256 tierId, uint256 tokenId);

    event ContributionSubmitted(uint256 indexed contributionId, address indexed contributor, ContributionType cType, string uri);
    event ContributionStateUpdated(uint256 indexed contributionId, ContributionState newState, uint256 awardedIP);
    event AIValidationDisputed(uint256 indexed contributionId, address indexed disputer);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateUpdated(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);

    event BountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, address rewardToken);
    event BountySolutionSubmitted(uint256 indexed bountyId, address indexed solver, string solutionUri);
    event BountySolutionApproved(uint256 indexed bountyId, address indexed solver);
    event BountyClaimed(uint256 indexed bountyId, address indexed solver, uint256 rewardAmount);
    event InfluenceSlashed(address indexed user, uint256 amount);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "DAIRIN_Core: Only trusted AI Oracle can call this");
        _;
    }

    modifier hasMinInfluence(uint256 _requiredIP) {
        require(influencePoints[msg.sender] >= _requiredIP, "DAIRIN_Core: Insufficient influence points");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the DAIRIN_Core contract.
     * @param _aiOracleAddress The address of the trusted AI Oracle contract.
     * @param _minInfluenceForProposal Minimum IP required to submit a proposal.
     * @param _votingPeriodDuration Duration of voting periods in seconds.
     */
    constructor(
        address _aiOracleAddress,
        uint256 _minInfluenceForProposal,
        uint256 _votingPeriodDuration
    ) Ownable(msg.sender) Pausable() {
        require(_aiOracleAddress != address(0), "DAIRIN_Core: AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_aiOracleAddress);

        // Deploy the InfluenceNFT contract directly from here
        influenceNFT = new DAIRIN_InfluenceNFT(address(this), "DAIRIN Influence NFT", "DAIRIN_IFT");

        minInfluenceForProposal = _minInfluenceForProposal;
        votingPeriodDuration = _votingPeriodDuration;

        // Set initial tier thresholds (can be updated later by governance)
        // Example: Tier 0 (0-99 IP), Tier 1 (100-499 IP), Tier 2 (500-1999 IP), Tier 3 (2000+ IP)
        tierThresholds = [0, 100, 500, 2000];
    }

    // --- A. Initialization & Admin Functions ---

    /**
     * @dev Sets or updates the trusted AI Oracle contract address.
     *      Can only be called by the owner.
     * @param _aiOracle The new address of the AI Oracle.
     */
    function setAIOracleAddress(address _aiOracle) external onlyOwner {
        require(_aiOracle != address(0), "DAIRIN_Core: AI Oracle address cannot be zero");
        aiOracle = IAIOracle(_aiOracle);
        emit OwnershipTransferred(address(0), _aiOracle); // Using existing event for simplicity, better custom event
    }

    /**
     * @dev Sets or updates the address of the deployed DAIRIN_InfluenceNFT contract.
     *      Useful if the NFT contract needs to be upgraded or redeployed.
     *      Can only be called by the owner.
     * @param _nftAddress The new address of the DAIRIN_InfluenceNFT contract.
     */
    function setInfluenceNFTAddress(address _nftAddress) external onlyOwner {
        require(_nftAddress != address(0), "DAIRIN_Core: NFT address cannot be zero");
        influenceNFT = DAIRIN_InfluenceNFT(_nftAddress);
    }

    /**
     * @dev Configures the IP thresholds for each Influence Tier.
     *      Must be an ordered array, lowest to highest.
     *      Can only be called by the owner initially, later via governance.
     * @param _thresholds An array of IP values defining the start of each tier.
     */
    function setTierThresholds(uint256[] calldata _thresholds) external onlyOwner whenNotPaused {
        require(_thresholds.length > 0, "DAIRIN_Core: Thresholds cannot be empty");
        for (uint i = 0; i < _thresholds.length - 1; i++) {
            require(_thresholds[i] < _thresholds[i+1], "DAIRIN_Core: Thresholds must be strictly increasing");
        }
        tierThresholds = _thresholds;
    }

    /**
     * @dev Pauses core contract functionalities in emergencies.
     *      Only callable by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *      Only callable by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner or successful governance proposal to withdraw ETH from the contract's treasury.
     * @param _to The address to send the ETH to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawTreasury(address _to, uint256 _amount) external onlyOwner nonReentrant whenNotPaused {
        require(address(this).balance >= _amount, "DAIRIN_Core: Insufficient treasury balance");
        (bool success,) = _to.call{value: _amount}("");
        require(success, "DAIRIN_Core: ETH transfer failed");
    }

    // --- B. Influence Points (IP) & Tier Management Functions ---

    /**
     * @dev Grants Influence Points to a user.
     *      Callable by the owner, or internally upon successful AI validation.
     * @param _user The address to grant IP to.
     * @param _amount The amount of IP to grant.
     */
    function grantInfluence(address _user, uint256 _amount) public onlyOwner whenNotPaused {
        // Can be extended to allow other roles (e.g., successful AI validation)
        require(_user != address(0), "DAIRIN_Core: Cannot grant to zero address");
        influencePoints[_user] += _amount;
        // Update total delegated power for delegatee if _user is delegating
        if (delegatedInfluence[_user] != address(0) && delegatedInfluence[_user] != _user) {
            totalDelegatedPower[delegatedInfluence[_user]] += _amount;
        } else {
            totalDelegatedPower[_user] += _amount; // User's own direct power
        }
        emit InfluenceGranted(_user, _amount);
    }

    /**
     * @dev Revokes Influence Points from a user.
     *      Callable by the owner or a successful governance proposal.
     * @param _user The address to revoke IP from.
     * @param _amount The amount of IP to revoke.
     */
    function revokeInfluence(address _user, uint256 _amount) public onlyOwner whenNotPaused {
        // Can be extended to allow governance decisions
        require(_user != address(0), "DAIRIN_Core: Cannot revoke from zero address");
        require(influencePoints[_user] >= _amount, "DAIRIN_Core: User has less IP than requested to revoke");
        influencePoints[_user] -= _amount;
        // Update total delegated power
        if (delegatedInfluence[_user] != address(0) && delegatedInfluence[_user] != _user) {
            totalDelegatedPower[delegatedInfluence[_user]] -= _amount;
        } else {
            totalDelegatedPower[_user] -= _amount;
        }
        emit InfluenceRevoked(_user, _amount);
    }

    /**
     * @dev Allows a user to claim/mint their Influence Tier NFT based on their current IP.
     *      Will mint the highest tier NFT they qualify for. If they already have an NFT,
     *      it will update its metadata via `tokenURI` in `DAIRIN_InfluenceNFT`.
     */
    function claimInfluenceTierNFT() external whenNotPaused {
        uint256 currentIP = influencePoints[msg.sender];
        uint256 currentTierId = getCurrentInfluenceTier(msg.sender);

        // Check if user already owns an NFT
        uint256 existingTokenId = 0;
        try influenceNFT.tokenOfOwnerByIndex(msg.sender, 0) returns (uint256 tokenId) {
            existingTokenId = tokenId;
        } catch {} // No NFT owned yet

        if (existingTokenId == 0) {
            // User does not have an NFT, mint one for their current tier
            uint256 tokenId = influenceNFT.mintForTier(msg.sender, currentTierId);
            emit InfluenceTierNFTClaimed(msg.sender, currentTierId, tokenId);
        } else {
            // User already has an NFT, its metadata will dynamically update via tokenURI
            // No need to mint a new one, just confirm they're aware
            emit InfluenceTierNFTClaimed(msg.sender, currentTierId, existingTokenId); // Re-emit for clarity
        }
    }

    /**
     * @dev Delegates a user's current and future Influence Points to another address for voting.
     *      A user can only delegate to one address at a time.
     * @param _delegatee The address to delegate influence to.
     */
    function delegateInfluence(address _delegatee) external whenNotPaused {
        require(msg.sender != _delegatee, "DAIRIN_Core: Cannot delegate to self");
        require(delegatedInfluence[msg.sender] == address(0) || delegatedInfluence[msg.sender] == msg.sender,
                "DAIRIN_Core: Already delegated or self-managed");

        // Remove sender's IP from their own totalDelegatedPower if they had it
        totalDelegatedPower[msg.sender] -= influencePoints[msg.sender];

        // Assign delegation
        delegatedInfluence[msg.sender] = _delegatee;
        // Add sender's IP to the delegatee's total delegated power
        totalDelegatedPower[_delegatee] += influencePoints[msg.sender];

        emit InfluenceDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Removes influence delegation, returning voting power to the caller.
     */
    function undelegateInfluence() external whenNotPaused {
        require(delegatedInfluence[msg.sender] != address(0) && delegatedInfluence[msg.sender] != msg.sender,
                "DAIRIN_Core: Not currently delegated");

        address previousDelegatee = delegatedInfluence[msg.sender];
        // Remove sender's IP from the previous delegatee's total delegated power
        totalDelegatedPower[previousDelegatee] -= influencePoints[msg.sender];

        // Clear delegation
        delegatedInfluence[msg.sender] = address(0); // or msg.sender to denote self-managed

        // Add sender's IP back to their own totalDelegatedPower
        totalDelegatedPower[msg.sender] += influencePoints[msg.sender];

        emit InfluenceUndelegated(msg.sender, previousDelegatee);
    }

    // --- C. Contribution & Validation System Functions ---

    /**
     * @dev Allows users to submit a contribution for evaluation.
     *      Some contribution types may automatically trigger AI validation.
     * @param _uri The URI (e.g., IPFS hash) pointing to the contribution content.
     * @param _type The type of contribution (e.g., Code, Content).
     */
    function submitContribution(string calldata _uri, ContributionType _type) external whenNotPaused {
        uint256 id = nextContributionId++;
        contributions[id] = Contribution({
            contributor: msg.sender,
            uri: _uri,
            cType: _type,
            state: ContributionState.PendingAIValidation, // Default to AI validation
            timestamp: block.timestamp,
            awardedIP: 0,
            aiValidationFeedback: ""
        });

        // Request AI validation immediately for relevant types
        aiOracle.requestValidation(address(this), id, _uri, uint8(_type));

        emit ContributionSubmitted(id, msg.sender, _type, _uri);
    }

    /**
     * @dev Callback function invoked by the trusted AI Oracle to report validation results.
     *      This function updates the contribution state and potentially grants IP.
     * @param _contributionId The ID of the contribution validated.
     * @param _isValid True if the AI deemed the contribution valid, false otherwise.
     * @param _awardedIP The amount of IP the AI suggests to award if valid.
     */
    function receiveAIValidationResult(uint256 _contributionId, bool _isValid, uint256 _awardedIP)
        external
        onlyAIOracle
        nonReentrant
        whenNotPaused
    {
        require(_contributionId < nextContributionId, "DAIRIN_Core: Invalid contribution ID");
        Contribution storage c = contributions[_contributionId];
        require(c.state == ContributionState.PendingAIValidation, "DAIRIN_Core: Contribution not awaiting AI validation");

        if (_isValid) {
            c.state = ContributionState.AIApproved;
            c.awardedIP = _awardedIP;
            grantInfluence(c.contributor, _awardedIP); // Grant IP upon AI approval (internal call)
        } else {
            c.state = ContributionState.AIRejected;
            c.awardedIP = 0; // Ensure no IP is awarded
            // In a real system, AI might provide feedback string. For now, empty.
            c.aiValidationFeedback = "AI rejected contribution.";
        }
        emit ContributionStateUpdated(_contributionId, c.state, c.awardedIP);
    }

    /**
     * @dev Allows a user to dispute an AI validation result, triggering a governance vote.
     * @param _contributionId The ID of the contribution to dispute.
     */
    function disputeAIValidation(uint256 _contributionId)
        external
        hasMinInfluence(minInfluenceForProposal) // Requires min IP to dispute
        whenNotPaused
    {
        require(_contributionId < nextContributionId, "DAIRIN_Core: Invalid contribution ID");
        Contribution storage c = contributions[_contributionId];
        require(c.contributor == msg.sender, "DAIRIN_Core: Only contributor can dispute");
        require(c.state == ContributionState.AIApproved || c.state == ContributionState.AIRejected,
                "DAIRIN_Core: Contribution not in AI-validated state");

        c.state = ContributionState.Disputed;

        // Automatically create a governance proposal for this dispute
        string memory description = string(abi.encodePacked("Dispute AI validation for contribution ID: ", uint256(_contributionId).toString()));
        bytes memory callData = abi.encodeWithSelector(
            this.handleDisputedContribution.selector,
            _contributionId
        );
        submitProposal(description, address(this), callData, 0); // No ETH value for this proposal

        emit AIValidationDisputed(_contributionId, msg.sender);
        emit ContributionStateUpdated(_contributionId, ContributionState.Disputed, 0);
    }

    /**
     * @dev Internal function called by a governance proposal to handle disputed contributions.
     *      This would be part of the `executeProposal` `callData`.
     * @param _contributionId The ID of the disputed contribution.
     */
    function handleDisputedContribution(uint256 _contributionId) external onlyOwner {
        // This function would be callable only by the contract itself via proposal execution.
        // It demonstrates how governance can override AI decisions.
        // The actual logic (e.g., manual award IP, change state) would be implemented here
        // based on the governance vote.
        require(_contributionId < nextContributionId, "DAIRIN_Core: Invalid contribution ID");
        Contribution storage c = contributions[_contributionId];
        require(c.state == ContributionState.Disputed, "DAIRIN_Core: Contribution not in disputed state");

        // Example: If governance voted to approve the disputed AI-rejected contribution
        // This logic depends on the specific governance outcome encoded in the proposal.
        // For simplicity, let's assume a successful dispute means it's manually approved.
        c.state = ContributionState.ManuallyApproved;
        // Optionally, define a fixed IP for manual approvals or allow it in proposal
        uint256 ipToAward = 100; // Example fixed IP
        c.awardedIP = ipToAward;
        grantInfluence(c.contributor, ipToAward);

        emit ContributionStateUpdated(_contributionId, c.state, c.awardedIP);
    }


    // --- D. Decentralized Governance Functions ---

    /**
     * @dev Allows users with sufficient Influence Points to submit a governance proposal.
     * @param _description A detailed description of the proposal.
     * @param _target The target contract address for the proposal's execution.
     * @param _callData The calldata to be executed on the target contract if the proposal passes.
     * @param _value ETH value to send with the execution.
     */
    function submitProposal(string calldata _description, address _target, bytes calldata _callData, uint256 _value)
        public
        hasMinInfluence(minInfluenceForProposal)
        whenNotPaused
    {
        uint256 id = nextProposalId++;
        proposals[id] = Proposal({
            description: _description,
            proposer: msg.sender,
            submittedAt: block.timestamp,
            votingEndsAt: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            totalVotePowerAtSubmission: totalDelegatedPower[msg.sender], // Snapshot of proposer's power
            state: ProposalState.Active,
            target: _target,
            callData: _callData,
            value: _value
        });
        emit ProposalSubmitted(id, msg.sender, _description);
    }

    /**
     * @dev Allows users to vote on proposals using their accumulated Influence Points and Tier benefits.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        require(_proposalId < nextProposalId, "DAIRIN_Core: Invalid proposal ID");
        Proposal storage p = proposals[_proposalId];
        require(p.state == ProposalState.Active, "DAIRIN_Core: Proposal not active");
        require(block.timestamp <= p.votingEndsAt, "DAIRIN_Core: Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "DAIRIN_Core: Already voted on this proposal");

        uint256 voterPower = influencePoints[msg.sender];
        // If delegated, use the delegatee's power, otherwise own power
        address actualVoter = delegatedInfluence[msg.sender] == address(0) ? msg.sender : delegatedInfluence[msg.sender];
        if (actualVoter == msg.sender) { // If self-managing or no delegation from others
            voterPower = influencePoints[msg.sender];
        } else { // If user has delegated
            voterPower = 0; // Delegated, so this user's direct vote counts as 0
            require(msg.sender == actualVoter, "DAIRIN_Core: Voter is not the delegatee. Only delegatee can vote on behalf.");
            // Or, more simply, just check totalDelegatedPower[msg.sender]
            voterPower = totalDelegatedPower[msg.sender];
        }

        // Simpler for voting power: always use the total delegated power of the voter
        // This implies if you delegated, you can't vote directly. If someone delegated to you, you vote for them.
        voterPower = totalDelegatedPower[msg.sender];
        require(voterPower > 0, "DAIRIN_Core: Voter has no influence power");

        if (_support) {
            p.votesFor += voterPower;
        } else {
            p.votesAgainst += voterPower;
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully passed proposal after the voting period ends.
     *      Anyone can call this, but it will only succeed if the conditions are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        require(_proposalId < nextProposalId, "DAIRIN_Core: Invalid proposal ID");
        Proposal storage p = proposals[_proposalId];
        require(p.state == ProposalState.Active, "DAIRIN_Core: Proposal not active");
        require(block.timestamp > p.votingEndsAt, "DAIRIN_Core: Voting period not ended");

        // Simplified quorum and majority for example
        // In a real DAO, this would be more complex (e.g., based on total token supply, quorum % etc.)
        uint256 totalVotes = p.votesFor + p.votesAgainst;
        uint256 requiredQuorum = p.totalVotePowerAtSubmission / 10; // 10% quorum of snapshot
        uint256 majorityThreshold = p.votesFor * 100 / totalVotes; // percentage of 'for' votes

        if (totalVotes >= requiredQuorum && majorityThreshold >= 51) { // 51% simple majority
            p.state = ProposalState.Succeeded;
            // Execute the proposal's payload
            (bool success,) = p.target.call{value: p.value}(p.callData);
            require(success, "DAIRIN_Core: Proposal execution failed");
            p.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            p.state = ProposalState.Failed;
        }
        emit ProposalStateUpdated(_proposalId, p.state);
    }

    // --- E. Bounty System Functions ---

    /**
     * @dev Creates a new bounty for specific tasks, funded by the contract's treasury.
     *      Can be called by the owner or via governance.
     * @param _description A detailed description of the bounty task.
     * @param _rewardAmount The amount of reward for completing the bounty.
     * @param _rewardToken The address of the ERC20 token for the reward (0x0 for ETH).
     */
    function createBounty(string calldata _description, uint256 _rewardAmount, address _rewardToken)
        external
        payable // Allow ETH funding if rewardToken is 0x0
        onlyOwner // For simplicity, only owner can create, can be extended to governance
        whenNotPaused
    {
        if (_rewardToken == address(0)) {
            require(msg.value == _rewardAmount, "DAIRIN_Core: ETH amount must match reward");
        } else {
            // For ERC20, the contract must have been approved to pull tokens or already hold them
            // In a real app, you'd likely transferFrom creator here or have a deposit function.
            // For now, assume contract already has it or it's funded by governance proposals.
            require(msg.value == 0, "DAIRIN_Core: Cannot send ETH with ERC20 bounty");
        }

        uint256 id = nextBountyId++;
        bounties[id] = Bounty({
            description: _description,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            creator: msg.sender,
            solver: address(0),
            solutionUri: "",
            state: BountyState.Open,
            createdAt: block.timestamp,
            approvedAt: 0
        });
        emit BountyCreated(id, msg.sender, _rewardAmount, _rewardToken);
    }

    /**
     * @dev Allows users to submit a solution for an open bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionUri The URI (e.g., IPFS hash) pointing to the solution.
     */
    function submitBountySolution(uint256 _bountyId, string calldata _solutionUri) external whenNotPaused {
        require(_bountyId < nextBountyId, "DAIRIN_Core: Invalid bounty ID");
        Bounty storage b = bounties[_bountyId];
        require(b.state == BountyState.Open, "DAIRIN_Core: Bounty not open for solutions");
        require(bytes(_solutionUri).length > 0, "DAIRIN_Core: Solution URI cannot be empty");

        b.solver = msg.sender;
        b.solutionUri = _solutionUri;
        b.state = BountyState.SolutionSubmitted;
        emit BountySolutionSubmitted(_bountyId, msg.sender, _solutionUri);
    }

    /**
     * @dev Approves a submitted bounty solution. Only callable by the owner or governance.
     * @param _bountyId The ID of the bounty.
     * @param _solver The address of the solver whose solution is being approved.
     */
    function approveBountySolution(uint256 _bountyId, address _solver) external onlyOwner whenNotPaused {
        require(_bountyId < nextBountyId, "DAIRIN_Core: Invalid bounty ID");
        Bounty storage b = bounties[_bountyId];
        require(b.state == BountyState.SolutionSubmitted, "DAIRIN_Core: Bounty not in solution submitted state");
        require(b.solver == _solver, "DAIRIN_Core: Solver does not match submitted solution");

        b.state = BountyState.Approved;
        b.approvedAt = block.timestamp;
        emit BountySolutionApproved(_bountyId, _solver);
    }

    /**
     * @dev Allows the approved solver to claim their bounty reward.
     * @param _bountyId The ID of the bounty.
     */
    function claimBountyReward(uint256 _bountyId) external nonReentrant whenNotPaused {
        require(_bountyId < nextBountyId, "DAIRIN_Core: Invalid bounty ID");
        Bounty storage b = bounties[_bountyId];
        require(b.state == BountyState.Approved, "DAIRIN_Core: Bounty not approved");
        require(b.solver == msg.sender, "DAIRIN_Core: Only the approved solver can claim");

        b.state = BountyState.Claimed;

        if (b.rewardToken == address(0)) {
            // ETH reward
            (bool success,) = msg.sender.call{value: b.rewardAmount}("");
            require(success, "DAIRIN_Core: ETH reward transfer failed");
        } else {
            // ERC20 token reward
            IERC20 rewardToken = IERC20(b.rewardToken);
            require(rewardToken.transfer(msg.sender, b.rewardAmount), "DAIRIN_Core: ERC20 reward transfer failed");
        }
        emit BountyClaimed(_bountyId, msg.sender, b.rewardAmount);
    }

    // --- F. Slashing Functions ---

    /**
     * @dev Reduces a user's Influence Points due to malicious or disruptive behavior.
     *      This would typically be enacted by a successful governance proposal.
     * @param _user The address of the user to slash.
     * @param _amount The amount of IP to slash.
     */
    function slashInfluence(address _user, uint256 _amount) public onlyOwner whenNotPaused {
        // In a full DAO, this would be triggered by a successful governance proposal.
        // For simplicity, currently only owner can initiate.
        require(_user != address(0), "DAIRIN_Core: Cannot slash zero address");
        require(influencePoints[_user] >= _amount, "DAIRIN_Core: User has less IP than requested to slash");

        influencePoints[_user] -= _amount;
        // Update total delegated power
        if (delegatedInfluence[_user] != address(0) && delegatedInfluence[_user] != _user) {
            totalDelegatedPower[delegatedInfluence[_user]] -= _amount;
        } else {
            totalDelegatedPower[_user] -= _amount;
        }
        emit InfluenceSlashed(_user, _amount);
    }

    // --- G. View Functions ---

    /**
     * @dev Returns the current Influence Points of a user.
     * @param _user The address of the user.
     * @return The IP amount.
     */
    function getInfluencePoints(address _user) public view returns (uint256) {
        return influencePoints[_user];
    }

    /**
     * @dev Returns the current Influence Tier of a user based on their IP.
     * @param _user The address of the user.
     * @return The tier ID (0-indexed).
     */
    function getCurrentInfluenceTier(address _user) public view returns (uint256) {
        uint256 currentIP = influencePoints[_user];
        uint256 currentTier = 0;
        for (uint i = 0; i < tierThresholds.length; i++) {
            if (currentIP >= tierThresholds[i]) {
                currentTier = i;
            } else {
                break; // Thresholds are sorted, so we found the highest applicable tier
            }
        }
        return currentTier;
    }

    /**
     * @dev Returns the configured tier thresholds.
     */
    function getTierThresholds() public view returns (uint256[] memory) {
        return tierThresholds;
    }


    /**
     * @dev Retrieves details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        string memory description,
        address proposer,
        uint256 submittedAt,
        uint256 votingEndsAt,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 totalVotePowerAtSubmission,
        ProposalState state,
        address target,
        bytes memory callData,
        uint256 value
    ) {
        require(_proposalId < nextProposalId, "DAIRIN_Core: Invalid proposal ID");
        Proposal storage p = proposals[_proposalId];
        return (
            p.description,
            p.proposer,
            p.submittedAt,
            p.votingEndsAt,
            p.votesFor,
            p.votesAgainst,
            p.totalVotePowerAtSubmission,
            p.state,
            p.target,
            p.callData,
            p.value
        );
    }

    /**
     * @dev Retrieves details of a specific bounty.
     * @param _bountyId The ID of the bounty.
     * @return bounty details.
     */
    function getBountyDetails(uint256 _bountyId) public view returns (
        string memory description,
        uint256 rewardAmount,
        address rewardToken,
        address creator,
        address solver,
        string memory solutionUri,
        BountyState state,
        uint256 createdAt,
        uint256 approvedAt
    ) {
        require(_bountyId < nextBountyId, "DAIRIN_Core: Invalid bounty ID");
        Bounty storage b = bounties[_bountyId];
        return (
            b.description,
            b.rewardAmount,
            b.rewardToken,
            b.creator,
            b.solver,
            b.solutionUri,
            b.state,
            b.createdAt,
            b.approvedAt
        );
    }

    /**
     * @dev Returns the address to whom a user has delegated their influence.
     *      Returns the user's own address if they have not delegated or if they self-manage.
     * @param _delegator The address of the user whose delegation status is being queried.
     * @return The address of the delegatee.
     */
    function getDelegatedInfluence(address _delegator) public view returns (address) {
        if (delegatedInfluence[_delegator] == address(0)) {
            return _delegator; // Not delegated, so effectively delegates to self
        }
        return delegatedInfluence[_delegator];
    }

    /**
     * @dev Returns the details of a specific contribution.
     * @param _contributionId The ID of the contribution.
     * @return contribution details.
     */
    function getContributionDetails(uint256 _contributionId) public view returns (
        address contributor,
        string memory uri,
        ContributionType cType,
        ContributionState state,
        uint256 timestamp,
        uint256 awardedIP,
        string memory aiValidationFeedback
    ) {
        require(_contributionId < nextContributionId, "DAIRIN_Core: Invalid contribution ID");
        Contribution storage c = contributions[_contributionId];
        return (
            c.contributor,
            c.uri,
            c.cType,
            c.state,
            c.timestamp,
            c.awardedIP,
            c.aiValidationFeedback
        );
    }
}
```