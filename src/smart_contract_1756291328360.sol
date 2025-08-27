This smart contract, `ChronicleForgeDAO`, introduces a novel decentralized protocol for collaborative digital artifact creation and evolving reputation. It's designed around three core, interconnected concepts: **Chronicles** (dynamic, evolving NFTs), **Epoch Souls** (non-transferable reputation tokens that unlock advanced features and governance power), and an **AI-Assisted Insight Validation** mechanism that integrates off-chain AI outputs into on-chain decision-making and content evolution.

The protocol encourages continuous, high-quality contributions by rewarding users with Essence tokens and reputation, while allowing the community to collectively build, curate, and validate information and art.

---

## ChronicleForgeDAO Smart Contract: Outline & Function Summary

**Concept Summary:**
ChronicleForgeDAO is a decentralized autonomous organization dedicated to fostering the collaborative creation of dynamic digital artifacts called "Chronicles." These Chronicles are NFTs that evolve over time based on community contributions and validated insights. Users earn "Epoch Souls," which are non-transferable reputation scores, for their valuable interactions, granting them enhanced governance rights and access to advanced protocol features. A key innovation is the AI-Assisted Insight Validation module, which allows users to submit AI-generated insights, have them collectively verified by the community, and use them to shape the evolution of Chronicles. The protocol operates with an "Essence" utility token for transactions, staking, and rewards.

**Core Components:**
1.  **Chronicles (ERC-721):** Dynamic, evolving NFTs representing collaborative digital artifacts. Their attributes change based on contributions and validated insights.
2.  **Epoch Souls (Soulbound Reputation):** Non-transferable reputation scores (represented as tiers and voting weight) that reflect a user's contributions and participation, unlocking specific functionalities and governance power.
3.  **Essence Token (ERC-20):** A utility token used for protocol fees, staking, rewards, and incentive alignment.
4.  **AI-Assisted Insight Validation:** A mechanism for submitting, challenging, and validating AI-generated data relevant to Chronicles, influencing their evolution.
5.  **DAO Governance:** A system for community members (weighted by Epoch Souls) to propose and vote on protocol changes and critical decisions.

---

### Function Categories & Summaries:

**I. Core Setup & Utilities**
1.  `constructor()`: Initializes the DAO, sets epoch duration, and deploys the Essence ERC-20 token.
2.  `updateEpochDuration(uint256 _newDuration)`: DAO-governed function to change the duration of an epoch.
3.  `getCurrentEpoch()`: Returns the current epoch number based on deployment time and epoch duration.
4.  `getEssenceTokenAddress()`: Retrieves the address of the Essence ERC-20 token.
5.  `getEpochSoulTierName(address _user)`: Returns a human-readable name for the user's Epoch Soul tier.

**II. Chronicle Management (Dynamic ERC-721 NFTs)**
6.  `createChronicle(string memory _name, string memory _initialURI, uint256 _creationCost)`: Mints a new Chronicle NFT, requiring an initial Essence payment.
7.  `contributeToChronicle(uint256 _chronicleId, string memory _contributionDataHash, uint256 _essenceStake)`: Allows users to add data/content (referenced by a hash) to a Chronicle, staking Essence. This enhances the Chronicle's evolving attributes and contributes to the user's Epoch Soul score.
8.  `getChronicleDetails(uint256 _chronicleId)`: Fetches all essential metadata, current attributes, and core contribution info for a Chronicle.
9.  `linkChronicles(uint256 _chronicleId1, uint256 _chronicleId2, string memory _linkContext)`: Establishes a verifiable and contextual link between two Chronicles, enriching the knowledge graph. Requires a minimum Epoch Soul tier.
10. `advanceChronicleState(uint256 _chronicleId)`: A function callable by the DAO or a high-tier Epoch Soul to process pending contributions and validated insights for a Chronicle, updating its dynamic attributes for the next epoch.
11. `getChronicleAttribute(uint256 _chronicleId, string memory _attributeName)`: Retrieves the current value of a specific dynamic attribute of a Chronicle.
12. `burnChronicle(uint256 _chronicleId)`: DAO-governed function to permanently remove a Chronicle (e.g., if it's found to be malicious or redundant), redistributing its locked Essence.

**III. Epoch Souls & Reputation (Soulbound Mechanics)**
13. `updateEpochSoulScore(address _user, int256 _scoreChange)`: Internal function used to adjust a user's non-transferable Epoch Soul score based on protocol interactions (contributions, validations, challenges).
14. `getEpochSoulScore(address _user)`: Returns the current reputation score of a user.
15. `delegateEpochSoul(address _delegatee)`: Allows a user to delegate their Epoch Soul's voting power to another address for liquid democracy.
16. `undelegateEpochSoul()`: Revokes any existing Epoch Soul delegation.

**IV. DAO Governance & Proposal System**
17. `proposeDAOAction(string memory _proposalURI, uint256 _requiredEpochSoulScore)`: Enables users with a sufficient Epoch Soul score to submit a new governance proposal (referenced by a URI).
18. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast their vote on an active DAO proposal. Their Epoch Soul score determines their voting weight.
19. `executeProposal(uint256 _proposalId)`: Executes a DAO proposal that has met the voting threshold and passed its cooldown period.

**V. AI-Assisted Insight Validation**
20. `submitInsight(uint256 _chronicleId, string memory _insightHash, string memory _aiModelIdentifier, uint256 _essenceBounty)`: A user (or AI agent) submits a cryptographic hash of an AI-generated insight relevant to a Chronicle, along with the AI model's ID, staking Essence as a reward bounty.
21. `challengeInsight(uint256 _chronicleId, uint256 _insightId, string memory _reasonHash, uint256 _challengeStake)`: Allows users to challenge a submitted insight, staking Essence. This initiates a validation process.
22. `voteOnInsightValidation(uint256 _chronicleId, uint256 _insightId, bool _isValid)`: Reputation-gated function where users vote on the validity of a challenged insight. The system employs a Schelling point-like mechanism where the majority (weighted by Epoch Souls) determines validity.
23. `resolveInsight(uint256 _chronicleId, uint256 _insightId)`: Finalizes the insight validation process. Distributes bounty and stakes based on the outcome, updates relevant Chronicle attributes, and adjusts participants' Epoch Soul scores.

**VI. Essence Token Interaction (Assuming an ERC20 token `EssenceToken` deployed separately or as an internal contract)**
24. `depositEssence(uint256 _amount)`: Allows users to deposit their Essence tokens into the ChronicleForgeDAO for protocol operations (e.g., creation costs, staking).
25. `withdrawEssence(uint256 _amount)`: Allows users to withdraw their available Essence from the protocol.
26. `getAvailableEssence(address _user)`: Checks the amount of Essence a user has deposited and is available for withdrawal or use within the protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For EssenceToken interface

// --- Outline & Function Summary ---
//
// Contract: ChronicleForgeDAO
//
// Concept Summary:
// ChronicleForgeDAO is a decentralized autonomous organization dedicated to fostering the collaborative creation of dynamic digital artifacts called "Chronicles." These Chronicles are NFTs that evolve over time based on community contributions and validated insights. Users earn "Epoch Souls," which are non-transferable reputation scores, for their valuable interactions, granting them enhanced governance rights and access to advanced protocol features. A key innovation is the AI-Assisted Insight Validation module, which allows users to submit AI-generated insights, have them collectively verified by the community, and use them to shape the evolution of Chronicles. The protocol operates with an "Essence" utility token for transactions, staking, and rewards.
//
// Core Components:
// 1.  Chronicles (ERC-721): Dynamic, evolving NFTs representing collaborative digital artifacts. Their attributes change based on contributions and validated insights.
// 2.  Epoch Souls (Soulbound Reputation): Non-transferable reputation scores (represented as tiers and voting weight) that reflect a user's contributions and participation, unlocking specific functionalities and governance power.
// 3.  Essence Token (ERC-20): A utility token used for protocol fees, staking, rewards, and incentive alignment.
// 4.  AI-Assisted Insight Validation: A mechanism for submitting, challenging, and validating AI-generated data relevant to Chronicles, influencing their evolution.
// 5.  DAO Governance: A system for community members (weighted by Epoch Souls) to propose and vote on protocol changes and critical decisions.
//
// --- Function Categories & Summaries: ---
//
// I. Core Setup & Utilities
// 1.  constructor(): Initializes the DAO, sets epoch duration, and deploys the Essence ERC-20 token.
// 2.  updateEpochDuration(uint256 _newDuration): DAO-governed function to change the duration of an epoch.
// 3.  getCurrentEpoch(): Returns the current epoch number based on deployment time and epoch duration.
// 4.  getEssenceTokenAddress(): Retrieves the address of the Essence ERC-20 token.
// 5.  getEpochSoulTierName(address _user): Returns a human-readable name for the user's Epoch Soul tier.
//
// II. Chronicle Management (Dynamic ERC-721 NFTs)
// 6.  createChronicle(string memory _name, string memory _initialURI, uint256 _creationCost): Mints a new Chronicle NFT, requiring an initial Essence payment.
// 7.  contributeToChronicle(uint256 _chronicleId, string memory _contributionDataHash, uint256 _essenceStake): Allows users to add data/content (referenced by a hash) to a Chronicle, staking Essence. This enhances the Chronicle's evolving attributes and contributes to the user's Epoch Soul score.
// 8.  getChronicleDetails(uint256 _chronicleId): Fetches all essential metadata, current attributes, and core contribution info for a Chronicle.
// 9.  linkChronicles(uint256 _chronicleId1, uint256 _chronicleId2, string memory _linkContext): Establishes a verifiable and contextual link between two Chronicles, enriching the knowledge graph. Requires a minimum Epoch Soul tier.
// 10. advanceChronicleState(uint256 _chronicleId): A function callable by the DAO or a high-tier Epoch Soul to process pending contributions and validated insights for a Chronicle, updating its dynamic attributes for the next epoch.
// 11. getChronicleAttribute(uint256 _chronicleId, string memory _attributeName): Retrieves the current value of a specific dynamic attribute of a Chronicle.
// 12. burnChronicle(uint256 _chronicleId): DAO-governed function to permanently remove a Chronicle (e.g., if it's found to be malicious or redundant), redistributing its locked Essence.
//
// III. Epoch Souls & Reputation (Soulbound Mechanics)
// 13. updateEpochSoulScore(address _user, int256 _scoreChange): Internal function used to adjust a user's non-transferable Epoch Soul score based on protocol interactions (contributions, validations, challenges).
// 14. getEpochSoulScore(address _user): Returns the current reputation score of a user.
// 15. delegateEpochSoul(address _delegatee): Allows a user to delegate their Epoch Soul's voting power to another address for liquid democracy.
// 16. undelegateEpochSoul(): Revokes any existing Epoch Soul delegation.
//
// IV. DAO Governance & Proposal System
// 17. proposeDAOAction(string memory _proposalURI, uint256 _requiredEpochSoulScore): Enables users with a sufficient Epoch Soul score to submit a new governance proposal (referenced by a URI).
// 18. voteOnProposal(uint256 _proposalId, bool _support): Allows users to cast their vote on an active DAO proposal. Their Epoch Soul score determines their voting weight.
// 19. executeProposal(uint256 _proposalId): Executes a DAO proposal that has met the voting threshold and passed its cooldown period.
//
// V. AI-Assisted Insight Validation
// 20. submitInsight(uint256 _chronicleId, string memory _insightHash, string memory _aiModelIdentifier, uint256 _essenceBounty): A user (or AI agent) submits a cryptographic hash of an AI-generated insight relevant to a Chronicle, along with the AI model's ID, staking Essence as a reward bounty.
// 21. challengeInsight(uint256 _chronicleId, uint256 _insightId, string memory _reasonHash, uint256 _challengeStake): Allows users to challenge a submitted insight, staking Essence. This initiates a validation process.
// 22. voteOnInsightValidation(uint256 _chronicleId, uint256 _insightId, bool _isValid): Reputation-gated function where users vote on the validity of a challenged insight. The system employs a Schelling point-like mechanism where the majority (weighted by Epoch Souls) determines validity.
// 23. resolveInsight(uint256 _chronicleId, uint256 _insightId): Finalizes the insight validation process. Distributes bounty and stakes based on the outcome, updates relevant Chronicle attributes, and adjusts participants' Epoch Soul scores.
//
// VI. Essence Token Interaction (Assuming an ERC20 token `EssenceToken` deployed separately or as an internal contract)
// 24. depositEssence(uint256 _amount): Allows users to deposit their Essence tokens into the ChronicleForgeDAO for protocol operations (e.g., creation costs, staking).
// 25. withdrawEssence(uint256 _amount): Allows users to withdraw their available Essence from the protocol.
// 26. getAvailableEssence(address _user): Checks the amount of Essence a user has deposited and is available for withdrawal or use within the protocol.

// --- Essence Token Definition (Minimal ERC20 for internal use) ---
// In a real scenario, this would likely be a separate, pre-deployed ERC20 contract.
// For the purpose of this example, we include a minimal implementation to represent it.
contract EssenceToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, 1_000_000_000 * 10**18); // Mint initial supply to deployer
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}


// --- Main ChronicleForgeDAO Contract ---
contract ChronicleForgeDAO is ERC721URIStorage, ReentrancyGuard, Ownable {

    IERC20 public immutable essenceToken;
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public deploymentTime;
    uint256 private _chronicleIdCounter;
    uint256 private _proposalIdCounter;
    uint256 private _insightIdCounter;

    // --- Structs ---

    struct Chronicle {
        uint256 id;
        string name;
        address creator;
        string currentURI;
        uint256 createdAtEpoch;
        mapping(string => string) dynamicAttributes; // Key-value for evolving attributes
        uint256 totalEssenceStaked; // Essence locked in contributions
        uint256 lastAdvancedEpoch;
        bool exists; // To check if chronicle is active
    }

    struct Contribution {
        uint256 chronicleId;
        address contributor;
        string dataHash; // IPFS hash or similar for off-chain data
        uint256 essenceStake;
        uint256 epoch; // Epoch when contribution was made
    }

    struct EpochSoulUser {
        uint256 score; // Reputation score
        address delegatee; // For liquid democracy
        uint256 tier; // Derived from score
    }

    struct Proposal {
        uint256 id;
        string proposalURI; // IPFS hash for proposal details
        address proposer;
        uint256 startEpoch;
        uint256 endEpoch;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        bool executed;
        bool exists;
    }

    enum InsightStatus { Submitted, Challenged, Validated, Rejected }

    struct Insight {
        uint256 id;
        uint256 chronicleId;
        address submitter;
        string insightHash; // Hash of AI-generated insight data (off-chain)
        string aiModelIdentifier; // Identifier for the AI model used
        uint256 essenceBounty; // Reward for valid insight
        InsightStatus status;
        address challenger; // Who challenged it, if any
        string challengeReasonHash; // Reason for challenge (off-chain hash)
        uint256 challengeStake; // Essence staked by challenger
        uint256 validationEndEpoch; // Epoch when validation voting ends
        uint256 validationYesVotes;
        uint256 validationNoVotes;
        mapping(address => bool) hasVotedValidation; // Tracks if an address has voted on validation
        bool exists;
    }

    // --- Mappings & Arrays ---

    mapping(uint256 => Chronicle) public chronicles;
    mapping(address => EpochSoulUser) public epochSoulUsers;
    mapping(address => uint256) public userEssenceDeposits; // User's Essence locked in the protocol
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Insight) public insights;
    mapping(uint256 => Contribution[]) public chronicleContributions; // Contributions to a specific chronicle

    // --- Events ---
    event EpochDurationUpdated(uint256 newDuration);
    event ChronicleCreated(uint256 indexed chronicleId, address indexed creator, string name, string initialURI);
    event ChronicleContributed(uint256 indexed chronicleId, address indexed contributor, string dataHash, uint256 essenceStaked);
    event ChroniclesLinked(uint256 indexed chronicleId1, uint256 indexed chronicleId2, string linkContext);
    event ChronicleStateAdvanced(uint256 indexed chronicleId, uint256 newEpoch);
    event ChronicleBurned(uint256 indexed chronicleId, address indexed burner);
    event EpochSoulScoreUpdated(address indexed user, uint256 newScore);
    event EpochSoulDelegated(address indexed delegator, address indexed delegatee);
    event EpochSoulUndelegated(address indexed delegator);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event InsightSubmitted(uint256 indexed insightId, uint256 indexed chronicleId, address indexed submitter, string insightHash, string aiModelIdentifier, uint256 essenceBounty);
    event InsightChallenged(uint256 indexed insightId, uint256 indexed chronicleId, address indexed challenger, string reasonHash, uint256 challengeStake);
    event InsightValidationVoted(uint256 indexed insightId, address indexed voter, bool isValid, uint256 votingWeight);
    event InsightResolved(uint256 indexed insightId, InsightStatus finalStatus, uint256 essenceDistributed);
    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceWithdrawn(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyDAO() {
        require(_getCurrentEpochSoulScore(_msgSender()) >= getRequiredScoreForTier(3), "ChronicleForgeDAO: Only high-tier Epoch Soul holders can call this DAO function directly (for simplified example)");
        // In a full DAO, this would integrate with a timelock or proper governance module.
        _;
    }

    modifier onlyTier(uint256 _requiredTier) {
        require(epochSoulUsers[_msgSender()].tier >= _requiredTier, "ChronicleForgeDAO: Insufficient Epoch Soul tier");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _epochDurationSeconds) ERC721("Chronicle NFT", "CHRON") Ownable(_msgSender()) {
        epochDuration = _epochDurationSeconds;
        deploymentTime = block.timestamp;
        _chronicleIdCounter = 0;
        _proposalIdCounter = 0;
        _insightIdCounter = 0;

        // Deploy EssenceToken as a minimal internal ERC20 for this example
        // In a real project, this would be an address of an already deployed token
        essenceToken = new EssenceToken("Essence Token", "ESS");

        // Initialize deployer's Epoch Soul
        epochSoulUsers[_msgSender()].score = 1000; // Give deployer a starting reputation
        epochSoulUsers[_msgSender()].tier = _calculateTier(1000);
        emit EpochSoulScoreUpdated(_msgSender(), 1000);
    }

    // --- I. Core Setup & Utilities ---

    function updateEpochDuration(uint256 _newDuration) public onlyDAO {
        require(_newDuration > 0, "Epoch duration must be positive");
        epochDuration = _newDuration;
        emit EpochDurationUpdated(_newDuration);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - deploymentTime) / epochDuration;
    }

    function getEssenceTokenAddress() public view returns (address) {
        return address(essenceToken);
    }

    function getEpochSoulTierName(address _user) public view returns (string memory) {
        uint256 tier = epochSoulUsers[_user].tier;
        if (tier == 0) return "Fledgling";
        if (tier == 1) return "Contributor";
        if (tier == 2) return "Artisan";
        if (tier == 3) return "Architect";
        return "Oracle"; // Highest tier
    }

    // Internal helper to calculate tier based on score
    function _calculateTier(uint256 _score) internal pure returns (uint256) {
        if (_score < 50) return 0; // Fledgling
        if (_score < 200) return 1; // Contributor
        if (_score < 500) return 2; // Artisan
        if (_score < 1000) return 3; // Architect
        return 4; // Oracle
    }

    // Internal helper to get required score for a tier
    function getRequiredScoreForTier(uint256 _tier) public pure returns (uint256) {
        if (_tier == 0) return 0;
        if (_tier == 1) return 50;
        if (_tier == 2) return 200;
        if (_tier == 3) return 500;
        if (_tier == 4) return 1000;
        return type(uint256).max; // For tiers higher than defined
    }

    // --- II. Chronicle Management (Dynamic ERC-721 NFTs) ---

    function createChronicle(string memory _name, string memory _initialURI, uint256 _creationCost) public nonReentrant returns (uint256) {
        require(userEssenceDeposits[_msgSender()] >= _creationCost, "Insufficient Essence deposited");
        
        userEssenceDeposits[_msgSender()] -= _creationCost;
        // Essence token is effectively 'locked' in the protocol here, could be sent to a treasury or burned.
        // For simplicity, we just reduce user's deposit, implying it's used by the protocol.

        _chronicleIdCounter++;
        uint256 newId = _chronicleIdCounter;

        _safeMint(_msgSender(), newId);
        _setTokenURI(newId, _initialURI);

        Chronicle storage newChronicle = chronicles[newId];
        newChronicle.id = newId;
        newChronicle.name = _name;
        newChronicle.creator = _msgSender();
        newChronicle.currentURI = _initialURI;
        newChronicle.createdAtEpoch = getCurrentEpoch();
        newChronicle.lastAdvancedEpoch = getCurrentEpoch();
        newChronicle.totalEssenceStaked = _creationCost; // Initial creation cost also counts as staked
        newChronicle.exists = true;

        // Placeholder for dynamic attribute initialization
        newChronicle.dynamicAttributes["status"] = "nascent";
        newChronicle.dynamicAttributes["creation_epoch"] = Strings.toString(newChronicle.createdAtEpoch);

        updateEpochSoulScore(_msgSender(), 10); // Reward for creating a Chronicle

        emit ChronicleCreated(newId, _msgSender(), _name, _initialURI);
        return newId;
    }

    function contributeToChronicle(
        uint256 _chronicleId,
        string memory _contributionDataHash,
        uint256 _essenceStake
    ) public nonReentrant {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist");
        require(userEssenceDeposits[_msgSender()] >= _essenceStake, "Insufficient Essence deposited for stake");
        require(_essenceStake > 0, "Contribution stake must be positive");

        userEssenceDeposits[_msgSender()] -= _essenceStake;
        chronicles[_chronicleId].totalEssenceStaked += _essenceStake;

        chronicleContributions[_chronicleId].push(
            Contribution({
                chronicleId: _chronicleId,
                contributor: _msgSender(),
                dataHash: _contributionDataHash,
                essenceStake: _essenceStake,
                epoch: getCurrentEpoch()
            })
        );

        updateEpochSoulScore(_msgSender(), 5); // Reward for contributing

        emit ChronicleContributed(_chronicleId, _msgSender(), _contributionDataHash, _essenceStake);
    }

    function getChronicleDetails(uint256 _chronicleId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            address creator,
            string memory currentURI,
            uint256 createdAtEpoch,
            uint256 totalEssenceStaked,
            uint256 lastAdvancedEpoch,
            string[] memory attributeNames,
            string[] memory attributeValues
        )
    {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[_chronicleId];

        id = chronicle.id;
        name = chronicle.name;
        creator = chronicle.creator;
        currentURI = chronicle.currentURI;
        createdAtEpoch = chronicle.createdAtEpoch;
        totalEssenceStaked = chronicle.totalEssenceStaked;
        lastAdvancedEpoch = chronicle.lastAdvancedEpoch;

        // Retrieve dynamic attributes
        // This is a simplified way; in a production setting, you might iterate keys or have a defined schema.
        attributeNames = new string[](2); // Example for known attributes, extend as needed
        attributeValues = new string[](2);
        attributeNames[0] = "status"; attributeValues[0] = chronicle.dynamicAttributes["status"];
        attributeNames[1] = "creation_epoch"; attributeValues[1] = chronicle.dynamicAttributes["creation_epoch"];
        // More attributes would be added dynamically via a setter or based on processed insights/contributions.
    }

    function linkChronicles(
        uint256 _chronicleId1,
        uint256 _chronicleId2,
        string memory _linkContext
    ) public onlyTier(1) { // Requires Contributor tier
        require(chronicles[_chronicleId1].exists, "Chronicle 1 does not exist");
        require(chronicles[_chronicleId2].exists, "Chronicle 2 does not exist");
        require(_chronicleId1 != _chronicleId2, "Cannot link a chronicle to itself");

        // In a real implementation, links could be stored in a mapping (id => id[])
        // For simplicity, we just emit an event and update reputation
        updateEpochSoulScore(_msgSender(), 3); // Reward for linking

        emit ChroniclesLinked(_chronicleId1, _chronicleId2, _linkContext);
    }

    function advanceChronicleState(uint256 _chronicleId) public onlyTier(2) { // Requires Artisan tier to advance state
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.exists, "Chronicle does not exist");
        require(getCurrentEpoch() > chronicle.lastAdvancedEpoch, "Chronicle state already advanced for current epoch");

        // --- Core logic for evolving Chronicle attributes ---
        // 1. Process pending contributions:
        //    - Sum up essence stakes from contributions in previous epoch
        //    - Update Chronicle's `currentURI` if a significant contribution was made (e.g., via DAO vote or weighted consensus)
        //    - Adjust dynamic attributes based on contribution types (e.g., 'quality_score', 'diversity_index')
        // 2. Apply validated insights:
        //    - Fetch all insights related to this chronicle that were validated in the previous epoch.
        //    - Use these insights to update `dynamicAttributes` (e.g., `dynamicAttributes["relevance"] = "high"`,
        //      `dynamicAttributes["concept_tags"] = "AI, decentralization"`)
        //    - This is a complex logic that would often involve off-chain processing or more sophisticated on-chain data structures.
        // For this example, we'll keep the attribute update simple.

        // Example: Update "status" attribute based on total contributions or insights
        if (chronicleContributions[_chronicleId].length > 5) {
            chronicle.dynamicAttributes["status"] = "evolving";
        }
        // Example: Update `currentURI` to reflect a new state, this would typically involve a specific contribution being 'promoted'
        // For demonstration, let's say the currentURI changes to reflect the epoch.
        chronicle.currentURI = string(abi.encodePacked("ipfs://new_uri_for_epoch_", Strings.toString(getCurrentEpoch()), "_chronicle_", Strings.toString(_chronicleId)));
        _setTokenURI(_chronicleId, chronicle.currentURI);


        chronicle.lastAdvancedEpoch = getCurrentEpoch();
        updateEpochSoulScore(_msgSender(), 15); // Reward for advancing a Chronicle's state
        emit ChronicleStateAdvanced(_chronicleId, getCurrentEpoch());
    }

    function getChronicleAttribute(uint256 _chronicleId, string memory _attributeName) public view returns (string memory) {
        require(chronicles[_chronicleId].exists, "Chronicle does not exist");
        return chronicles[_chronicleId].dynamicAttributes[_attributeName];
    }

    function burnChronicle(uint256 _chronicleId) public onlyDAO nonReentrant {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.exists, "Chronicle does not exist");

        // Transfer locked Essence back to DAO treasury or burn, or redistribute
        // For simplicity, we just 'free up' the Essence from the chronicle's record.
        // In a real system, the `totalEssenceStaked` would be moved/burned.
        // For example, essenceToken.transfer(treasuryAddress, chronicle.totalEssenceStaked);

        _burn(_chronicleId); // Burn the ERC721 token
        chronicle.exists = false; // Mark as non-existent
        delete chronicles[_chronicleId]; // Clear storage
        delete chronicleContributions[_chronicleId]; // Clear associated contributions

        emit ChronicleBurned(_chronicleId, _msgSender());
    }

    // --- III. Epoch Souls & Reputation (Soulbound Mechanics) ---

    function _updateEpochSoulScore(address _user, int256 _scoreChange) internal {
        EpochSoulUser storage userSoul = epochSoulUsers[_user];
        uint256 currentScore = userSoul.score;
        uint256 newScore;

        if (_scoreChange > 0) {
            newScore = currentScore + uint256(_scoreChange);
        } else {
            // Prevent score from going below zero
            if (uint256(-_scoreChange) > currentScore) {
                newScore = 0;
            } else {
                newScore = currentScore - uint256(-_scoreChange);
            }
        }
        userSoul.score = newScore;
        userSoul.tier = _calculateTier(newScore); // Recalculate tier
        emit EpochSoulScoreUpdated(_user, newScore);
    }

    function getEpochSoulScore(address _user) public view returns (uint256) {
        return epochSoulUsers[_user].score;
    }

    function delegateEpochSoul(address _delegatee) public {
        require(_delegatee != address(0), "Cannot delegate to zero address");
        require(_delegatee != _msgSender(), "Cannot delegate to self");
        epochSoulUsers[_msgSender()].delegatee = _delegatee;
        emit EpochSoulDelegated(_msgSender(), _delegatee);
    }

    function undelegateEpochSoul() public {
        require(epochSoulUsers[_msgSender()].delegatee != address(0), "No active delegation to undelegate");
        epochSoulUsers[_msgSender()].delegatee = address(0);
        emit EpochSoulUndelegated(_msgSender());
    }

    // --- IV. DAO Governance & Proposal System ---

    function proposeDAOAction(string memory _proposalURI, uint256 _requiredEpochSoulScore) public nonReentrant onlyTier(2) { // Requires Artisan tier
        require(epochSoulUsers[_msgSender()].score >= _requiredEpochSoulScore, "Insufficient Epoch Soul score to propose");

        _proposalIdCounter++;
        uint256 newId = _proposalIdCounter;

        proposals[newId] = Proposal({
            id: newId,
            proposalURI: _proposalURI,
            proposer: _msgSender(),
            startEpoch: getCurrentEpoch(),
            endEpoch: getCurrentEpoch() + 3, // Voting lasts 3 epochs
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            exists: true
        });

        emit ProposalCreated(newId, _msgSender(), _proposalURI);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(getCurrentEpoch() >= proposal.startEpoch, "Voting has not started");
        require(getCurrentEpoch() < proposal.endEpoch, "Voting has ended");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");

        uint256 votingWeight = epochSoulUsers[_msgSender()].score;
        address voter = _msgSender();

        // If delegated, use delegatee's score as voting power.
        if (epochSoulUsers[voter].delegatee != address(0)) {
            voter = epochSoulUsers[voter].delegatee;
            votingWeight = epochSoulUsers[voter].score;
        }

        require(votingWeight > 0, "Epoch Soul score is required to vote");

        if (_support) {
            proposal.yesVotes += votingWeight;
        } else {
            proposal.noVotes += votingWeight;
        }
        proposal.hasVoted[_msgSender()] = true; // Still track original voter

        updateEpochSoulScore(_msgSender(), 1); // Small reward for voting
        emit ProposalVoted(_proposalId, _msgSender(), _support, votingWeight);
    }

    function executeProposal(uint256 _proposalId) public nonReentrant onlyDAO {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(getCurrentEpoch() >= proposal.endEpoch, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        require(totalVotes > 0, "No votes cast on this proposal"); // Prevent division by zero

        // Simple majority rule for execution (e.g., > 50% 'yes' votes)
        // In a complex DAO, quorum and more sophisticated thresholds would apply.
        if (proposal.yesVotes * 100 / totalVotes > 50) {
            // Placeholder for actual execution logic
            // This would involve calling an external contract or internal function based on `_proposalURI` content
            // For example:
            // (bool success, ) = address(this).call(abi.encodeWithSignature("someDaoInternalFunction(uint256)", 123));
            // require(success, "Proposal execution failed");
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal failed
            // No specific event for failure, but `executed` remaining false indicates this.
        }
    }

    // --- V. AI-Assisted Insight Validation ---

    function submitInsight(
        uint256 _chronicleId,
        string memory _insightHash,
        string memory _aiModelIdentifier,
        uint256 _essenceBounty
    ) public nonReentrant onlyTier(1) returns (uint256) { // Requires Contributor tier
        require(chronicles[_chronicleId].exists, "Chronicle does not exist");
        require(userEssenceDeposits[_msgSender()] >= _essenceBounty, "Insufficient Essence deposited for bounty");
        require(_essenceBounty > 0, "Bounty must be positive");

        userEssenceDeposits[_msgSender()] -= _essenceBounty; // Lock bounty

        _insightIdCounter++;
        uint256 newId = _insightIdCounter;

        insights[newId] = Insight({
            id: newId,
            chronicleId: _chronicleId,
            submitter: _msgSender(),
            insightHash: _insightHash,
            aiModelIdentifier: _aiModelIdentifier,
            essenceBounty: _essenceBounty,
            status: InsightStatus.Submitted,
            challenger: address(0),
            challengeReasonHash: "",
            challengeStake: 0,
            validationEndEpoch: 0, // Set when challenged
            validationYesVotes: 0,
            validationNoVotes: 0,
            exists: true
        });

        updateEpochSoulScore(_msgSender(), 2); // Reward for submitting insight
        emit InsightSubmitted(newId, _chronicleId, _msgSender(), _insightHash, _aiModelIdentifier, _essenceBounty);
        return newId;
    }

    function challengeInsight(
        uint256 _chronicleId,
        uint256 _insightId,
        string memory _reasonHash,
        uint256 _challengeStake
    ) public nonReentrant onlyTier(1) { // Requires Contributor tier
        Insight storage insight = insights[_insightId];
        require(insight.exists, "Insight does not exist");
        require(insight.chronicleId == _chronicleId, "Insight does not belong to this chronicle");
        require(insight.status == InsightStatus.Submitted, "Insight cannot be challenged in its current state");
        require(insight.submitter != _msgSender(), "Cannot challenge your own insight");
        require(userEssenceDeposits[_msgSender()] >= _challengeStake, "Insufficient Essence deposited for challenge stake");
        require(_challengeStake > 0, "Challenge stake must be positive");

        userEssenceDeposits[_msgSender()] -= _challengeStake; // Lock challenge stake

        insight.status = InsightStatus.Challenged;
        insight.challenger = _msgSender();
        insight.challengeReasonHash = _reasonHash;
        insight.challengeStake = _challengeStake;
        insight.validationEndEpoch = getCurrentEpoch() + 2; // Validation voting lasts 2 epochs

        updateEpochSoulScore(_msgSender(), 2); // Reward for challenging
        emit InsightChallenged(_insightId, _chronicleId, _msgSender(), _reasonHash, _challengeStake);
    }

    function voteOnInsightValidation(uint256 _chronicleId, uint256 _insightId, bool _isValid) public nonReentrant onlyTier(1) {
        Insight storage insight = insights[_insightId];
        require(insight.exists, "Insight does not exist");
        require(insight.chronicleId == _chronicleId, "Insight does not belong to this chronicle");
        require(insight.status == InsightStatus.Challenged, "Insight is not in challenged state for validation");
        require(getCurrentEpoch() < insight.validationEndEpoch, "Insight validation voting has ended");
        require(!insight.hasVotedValidation[_msgSender()], "Already voted on this insight validation");

        uint256 votingWeight = epochSoulUsers[_msgSender()].score;
        require(votingWeight > 0, "Epoch Soul score is required to vote");

        if (_isValid) {
            insight.validationYesVotes += votingWeight;
        } else {
            insight.validationNoVotes += votingWeight;
        }
        insight.hasVotedValidation[_msgSender()] = true;

        updateEpochSoulScore(_msgSender(), 1); // Small reward for voting on validation
        emit InsightValidationVoted(_insightId, _msgSender(), _isValid, votingWeight);
    }

    function resolveInsight(uint256 _chronicleId, uint256 _insightId) public nonReentrant {
        Insight storage insight = insights[_insightId];
        require(insight.exists, "Insight does not exist");
        require(insight.chronicleId == _chronicleId, "Insight does not belong to this chronicle");
        require(insight.status == InsightStatus.Challenged, "Insight not in a state to be resolved (must be challenged)");
        require(getCurrentEpoch() >= insight.validationEndEpoch, "Validation voting period has not ended");

        uint256 totalValidationVotes = insight.validationYesVotes + insight.validationNoVotes;
        require(totalValidationVotes > 0, "No votes cast for insight validation");

        uint256 distributedEssence = 0;

        if (insight.validationYesVotes > insight.validationNoVotes) {
            // Insight is Validated
            insight.status = InsightStatus.Validated;
            // Reward submitter: bounty + challenger's stake
            distributedEssence = insight.essenceBounty + insight.challengeStake;
            userEssenceDeposits[insight.submitter] += distributedEssence;
            updateEpochSoulScore(insight.submitter, 10); // Major reward for valid insight
            // Punish challenger
            updateEpochSoulScore(insight.challenger, -5); // Penalty for failed challenge

            // Apply insight to chronicle attributes (simplified)
            chronicles[_chronicleId].dynamicAttributes["last_validated_insight_hash"] = insight.insightHash;
            chronicles[_chronicleId].dynamicAttributes["ai_model_used"] = insight.aiModelIdentifier;

        } else {
            // Insight is Rejected (challenged successfully)
            insight.status = InsightStatus.Rejected;
            // Reward challenger: submitter's bounty + challenger's stake (returned)
            distributedEssence = insight.essenceBounty + insight.challengeStake;
            userEssenceDeposits[insight.challenger] += distributedEssence;
            updateEpochSoulScore(insight.challenger, 10); // Major reward for successful challenge
            // Punish submitter
            updateEpochSoulScore(insight.submitter, -5); // Penalty for rejected insight
        }

        emit InsightResolved(_insightId, insight.status, distributedEssence);
    }

    // --- VI. Essence Token Interaction ---

    function depositEssence(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Deposit amount must be positive");
        require(essenceToken.transferFrom(_msgSender(), address(this), _amount), "Essence transfer failed");
        userEssenceDeposits[_msgSender()] += _amount;
        emit EssenceDeposited(_msgSender(), _amount);
    }

    function withdrawEssence(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Withdrawal amount must be positive");
        require(userEssenceDeposits[_msgSender()] >= _amount, "Insufficient available Essence to withdraw");
        userEssenceDeposits[_msgSender()] -= _amount;
        require(essenceToken.transfer(_msgSender(), _amount), "Essence transfer failed");
        emit EssenceWithdrawn(_msgSender(), _amount);
    }

    function getAvailableEssence(address _user) public view returns (uint256) {
        return userEssenceDeposits[_user];
    }
}
```