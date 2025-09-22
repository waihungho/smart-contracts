This smart contract, named `ChronoNexusProtocol`, is designed to be an advanced, adaptive, and reputation-weighted decentralized autonomous protocol. It combines several cutting-edge concepts into a cohesive system:

1.  **Multi-Asset Management:** Users can deposit various ERC20 tokens and ERC721 NFTs into personal vaults. The protocol itself also maintains a treasury of ERC20s for collective governance use.
2.  **Reputation System:** A non-transferable (soulbound-like) reputation score for users, which directly influences their voting power in governance and unlocks milestones with rewards.
3.  **Decentralized Autonomous Organization (DAO):** A robust governance system allowing users with sufficient reputation to propose and vote on actions, including funding external DeFi strategies or adjusting protocol parameters.
4.  **Adaptive Parameters:** The protocol integrates with an external oracle to fetch off-chain data (e.g., market volatility, protocol health score). Based on this data and predefined on-chain logic, critical protocol parameters (like quorum percentage, reputation decay rate) can dynamically adjust, making the protocol resilient and responsive.
5.  **Dynamic Adaptive NFTs (DNFTs):** The protocol features its own ERC721 NFTs (`ChronoNexusNFT`) whose metadata (and thus visual/functional traits) can be updated by the protocol based on various triggers, such as user reputation milestones, global protocol events, or successful governance proposals.

This combination aims to create a unique, self-evolving, and community-driven ecosystem that transcends typical DeFi or NFT patterns.

---

## ChronoNexusProtocol Smart Contract

**Outline & Function Summary:**

**I. Core Infrastructure & Access Control**
1.  **`constructor()`**: Initializes the contract owner, sets up initial parameters, defines the ChronoNexus NFT contract, and optionally sets a base oracle address.
2.  **`addGuardian(address _guardian)`**: Adds an address to the emergency guardian council. Guardians can pause critical operations. Only callable by the owner.
3.  **`removeGuardian(address _guardian)`**: Removes an address from the guardian council. Only callable by the owner.
4.  **`pauseProtocol(bool _paused)`**: Toggles the protocol's paused state, restricting certain operations. Callable by the owner or any guardian.

**II. Multi-Asset Treasury & User Vaults**
5.  **`depositERC20(address _token, uint256 _amount)`**: Allows users to deposit ERC20 tokens into their personal, non-custodial vault within the protocol.
6.  **`withdrawERC20(address _token, uint256 _amount)`**: Allows users to withdraw their deposited ERC20 tokens from their personal vault.
7.  **`depositERC721(address _nftContract, uint256 _tokenId)`**: Allows users to deposit ERC721 NFTs into their personal, non-custodial vault.
8.  **`withdrawERC721(address _nftContract, uint256 _tokenId)`**: Allows users to withdraw their deposited ERC721 NFTs from their personal vault.
9.  **`transferTreasuryERC20(address _token, uint256 _amount, address _recipient)`**: Protocol's internal function to move ERC20 assets from the DAO's main treasury to a recipient (e.g., a strategy contract). Only callable by successful proposals.

**III. Reputation & Milestone System (Soulbound-like mechanic)**
10. **`awardReputation(address _user, uint256 _amount, string calldata _reason)`**: Awards reputation points to a user. Triggered by internal logic, specific roles, or governance.
11. **`deductReputation(address _user, uint256 _amount, string calldata _reason)`**: Deducts reputation points from a user, typically for malicious behavior as determined by governance.
12. **`getReputation(address _user)`**: Returns the current reputation score of a given user.
13. **`defineReputationMilestone(uint256 _milestoneId, uint256 _threshold, address _rewardToken, uint256 _rewardAmount)`**: Sets up a new reputation milestone with a required score and a token reward. Callable by governance (via proposal).
14. **`claimMilestoneReward(uint256 _milestoneId)`**: Allows users who have met a reputation milestone to claim their associated rewards from the protocol's treasury.

**IV. Decentralized Autonomous Organization (DAO) & Adaptive Strategies**
15. **`submitProposal(string calldata _description, bytes calldata _callData, address _targetContract)`**: Allows users with sufficient reputation to submit a governance proposal, which can involve calling any function on a target contract.
16. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Users cast their vote on an active proposal. Voting power is directly proportional to their reputation score.
17. **`executeProposal(uint256 _proposalId)`**: Executes a proposal once it has passed the voting period and met the quorum/majority requirements.
18. **`registerStrategy(address _strategyContract, string calldata _name, bool _isActive)`**: Registers a new external DeFi strategy contract (e.g., a yield farm, lending pool) that the DAO can interact with. Callable only via successful governance proposal.
19. **`allocateTreasuryToStrategy(uint256 _strategyId, address _token, uint256 _amount)`**: Directs a portion of the DAO's treasury assets to an approved, active strategy contract. Callable only via successful governance proposal.

**V. Dynamic Adaptive NFTs (DNFTs) & Oracle-Driven Parameters**
20. **`mintChronoNexusNFT()`**: Allows a user to mint a unique ChronoNexus NFT. These NFTs are intended to be identity-bound, with metadata that evolves with protocol state or user activity.
21. **`updateChronoNexusNFTMetadata(uint256 _tokenId, string calldata _newBaseURI)`**: Updates the URI for a specific ChronoNexus NFT, allowing its visual/functional traits to change dynamically. Callable by the protocol (e.g., via proposal) or owner.
22. **`setOracleAddress(address _newOracle)`**: Sets the address of the external oracle contract that provides off-chain data (e.g., market volatility, TVL of integrated strategies). Callable by owner or via governance.
23. **`triggerParameterRecalibration()`**: Callable by anyone, this function queries the oracle for relevant data and then programmatically adjusts internal protocol parameters (e.g., proposal quorum, reputation decay rate) based on predefined on-chain logic, making the protocol adaptive.
24. **`getProtocolParameter(string calldata _key)`**: Returns the current value of a specific protocol parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for explicit safety checks

// --- Placeholder for an Oracle Interface ---
// An actual implementation would fetch data from Chainlink, custom feeds, etc.
interface IOracle {
    function getLatestData(string calldata _key) external view returns (uint256);
}

// --- ChronoNexusNFT ERC721 Contract (Minimal for demonstration) ---
// This contract defines the Dynamic NFT. It would be deployed separately.
contract ChronoNexusNFT is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 private _nextTokenId;

    constructor(address _protocolOwner, string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(_protocolOwner) {
        // The ChronoNexusProtocol contract is set as the owner to control minting and metadata updates.
    }

    /**
     * @dev Mints a new ChronoNexus NFT to the specified address.
     * Callable only by the ChronoNexusProtocol contract (the owner).
     * @param _to The address to mint the NFT to.
     */
    function mintTo(address _to) external onlyOwner returns (uint256) {
        _nextTokenId = _nextTokenId.add(1);
        _safeMint(_to, _nextTokenId);
        // Initial URI can be a generic one, to be updated dynamically
        _setTokenURI(_nextTokenId, string(abi.encodePacked("ipfs://initial_metadata/", Strings.toString(_nextTokenId))));
        return _nextTokenId;
    }

    /**
     * @dev Sets the base URI for a specific NFT, enabling dynamic metadata changes.
     * Callable only by the owner (ChronoNexusProtocol). This is key for DNFTs.
     * @param _tokenId The ID of the token to update.
     * @param _newURI The new URI pointing to updated metadata.
     */
    function setTokenURI(uint256 _tokenId, string calldata _newURI) external onlyOwner {
        require(_exists(_tokenId), "ERC721Metadata: URI set of nonexistent token");
        _setTokenURI(_tokenId, _newURI);
    }

    // To make it truly "soulbound" (non-transferable), uncomment these overrides:
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //     revert("ChronoNexusNFT: This NFT is soulbound and cannot be transferred.");
    // }
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
    //     revert("ChronoNexusNFT: This NFT is soulbound and cannot be transferred.");
    // }
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
    //     revert("ChronoNexusNFT: This NFT is soulbound and cannot be transferred.");
    // }
}


/**
 * @title ChronoNexusProtocol
 * @dev An advanced, adaptive, and reputation-weighted decentralized autonomous protocol.
 *      It integrates multi-asset management, a soulbound-like reputation system,
 *      governance-driven dynamic strategies, and dynamic NFTs whose traits can evolve
 *      based on protocol state or user activity, all influenced by oracle-fed data.
 *      This aims to avoid direct duplication of existing open-source patterns by
 *      synthesizing these concepts into a novel, integrated system.
 */
contract ChronoNexusProtocol is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeMath for uint256;

    // --- State Variables ---

    // Access Control
    mapping(address => bool) public guardians;
    uint256 public numGuardians;
    bool public paused;

    // Reputation System
    mapping(address => uint256) private _reputationScores;
    struct Milestone {
        uint256 threshold;
        address rewardToken;
        uint256 rewardAmount;
        mapping(address => bool) claimedRewards; // Track if user claimed this milestone
    }
    mapping(uint256 => Milestone) public reputationMilestones;
    uint256 public nextMilestoneId;

    // User Asset Vaults (Non-custodial by design, assets are held by ChronoNexusProtocol but associated with user)
    mapping(address => mapping(address => uint256)) public userERC20Vaults; // user => tokenAddress => amount
    mapping(address => mapping(address => uint256[])) public userERC721Vaults; // user => nftContract => array of tokenIds

    // DAO Treasury (for assets collectively managed by governance)
    mapping(address => uint256) public protocolERC20Treasury; // tokenAddress => amount

    // Governance & Proposals
    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        uint256 startBlock;
        uint256 endBlock;
        uint256 reputationRequired; // Min reputation to submit
        uint256 yesVotes; // Total reputation voting yes
        uint252 noVotes;  // Total reputation voting no
        mapping(address => bool) hasVoted; // User => Voted status
        bool executed;
        bool canceled;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public constant VOTING_PERIOD_BLOCKS = 10000; // Approx 2-3 days on Ethereum mainnet (assuming 13s blocks)

    // Strategies
    struct StrategyInfo {
        uint256 id;
        address strategyContract;
        string name;
        bool isActive;
    }
    mapping(uint256 => StrategyInfo) public strategies;
    uint256 public nextStrategyId;

    // Adaptive Parameters
    mapping(string => uint256) public protocolParameters; // e.g., "minReputationForProposal", "quorumPercentage"

    // Oracle Integration
    address public oracleAddress;

    // ChronoNexus NFT (Dynamic NFT)
    ChronoNexusNFT public chronoNexusNFT; // An instance of the custom ERC721 for DNFTs

    // --- Events ---
    event ProtocolPaused(bool _paused);
    event GuardianAdded(address indexed _guardian);
    event GuardianRemoved(address indexed _guardian);
    event ERC20Deposited(address indexed _user, address indexed _token, uint256 _amount);
    event ERC20Withdrawn(address indexed _user, address indexed _token, uint256 _amount);
    event ERC721Deposited(address indexed _user, address indexed _nftContract, uint256 _tokenId);
    event ERC721Withdrawn(address indexed _user, address indexed _nftContract, uint256 _tokenId);
    event ReputationAwarded(address indexed _user, uint256 _amount, string _reason);
    event ReputationDeducted(address indexed _user, uint256 _amount, string _reason);
    event MilestoneDefined(uint256 indexed _milestoneId, uint256 _threshold, address _rewardToken, uint256 _rewardAmount);
    event MilestoneClaimed(address indexed _user, uint256 indexed _milestoneId);
    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, string _description);
    event VoteCast(uint256 indexed _proposalId, address indexed _voter, bool _support, uint256 _reputationWeight);
    event ProposalExecuted(uint256 indexed _proposalId);
    event StrategyRegistered(uint256 indexed _strategyId, address _strategyContract, string _name);
    event AssetsAllocatedToStrategy(uint256 indexed _strategyId, address indexed _token, uint256 _amount);
    event ChronoNexusNFTMinted(address indexed _owner, uint256 indexed _tokenId);
    event ChronoNexusNFTMetadataUpdated(uint256 indexed _tokenId, string _newURI);
    event OracleAddressSet(address indexed _newOracle);
    event ParameterRecalibrated(string _key, uint256 _oldValue, uint256 _newValue);


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Pausable: protocol is paused");
        _;
    }

    modifier onlyGuardianOrOwner() {
        require(owner() == _msgSender() || guardians[_msgSender()], "AccessControl: caller is not the owner or a guardian");
        _;
    }

    modifier onlyReputationHolder(uint256 _minReputation) {
        require(_reputationScores[_msgSender()] >= _minReputation, "Reputation: insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(address _initialOracle, address _chronoNexusNFTContract) Ownable(_msgSender()) {
        paused = false;
        oracleAddress = _initialOracle;
        require(_chronoNexusNFTContract != address(0), "Constructor: ChronoNexusNFT contract address cannot be zero.");
        chronoNexusNFT = ChronoNexusNFT(_chronoNexusNFTContract);

        // Set initial protocol parameters
        protocolParameters["minReputationForProposal"] = 100;
        protocolParameters["quorumPercentage"] = 40; // 40% of total *voted* reputation needs to vote 'yes'
        protocolParameters["minVotingPeriodBlocks"] = VOTING_PERIOD_BLOCKS;
        protocolParameters["reputationDecayRatePerBlock"] = 0; // Can be adjusted by governance/oracle
        protocolParameters["baseRewardMultiplier"] = 100; // 100 = 1x
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Adds an address to the emergency guardian council.
     * Guardians can pause the protocol in emergencies.
     * Only callable by the owner.
     * @param _guardian The address to add as a guardian.
     */
    function addGuardian(address _guardian) external onlyOwner {
        require(_guardian != address(0), "Guardian: zero address");
        require(!guardians[_guardian], "Guardian: already a guardian");
        guardians[_guardian] = true;
        numGuardians++;
        emit GuardianAdded(_guardian);
    }

    /**
     * @dev Removes an address from the emergency guardian council.
     * Only callable by the owner.
     * @param _guardian The address to remove as a guardian.
     */
    function removeGuardian(address _guardian) external onlyOwner {
        require(guardians[_guardian], "Guardian: not a guardian");
        guardians[_guardian] = false;
        numGuardians--;
        emit GuardianRemoved(_guardian);
    }

    /**
     * @dev Toggles the protocol's paused state.
     * When paused, critical operations (e.g., deposits, withdrawals, proposal execution) are restricted.
     * Callable by the owner or any guardian.
     * @param _paused The desired paused state (true to pause, false to unpause).
     */
    function pauseProtocol(bool _paused) external onlyGuardianOrOwner {
        paused = _paused;
        emit ProtocolPaused(_paused);
    }

    // --- II. Multi-Asset Treasury & User Vaults ---

    /**
     * @dev Allows users to deposit ERC20 tokens into their personal vault.
     * The contract holds the tokens on behalf of the user, but ownership remains virtualized.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositERC20(address _token, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Deposit: amount must be greater than zero");
        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);
        userERC20Vaults[_msgSender()][_token] = userERC20Vaults[_msgSender()][_token].add(_amount);
        emit ERC20Deposited(_msgSender(), _token, _amount);
    }

    /**
     * @dev Allows users to withdraw their deposited ERC20 tokens from their personal vault.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address _token, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Withdraw: amount must be greater than zero");
        require(userERC20Vaults[_msgSender()][_token] >= _amount, "Withdraw: insufficient balance in vault");
        userERC20Vaults[_msgSender()][_token] = userERC20Vaults[_msgSender()][_token].sub(_amount);
        IERC20(_token).transfer(_msgSender(), _amount);
        emit ERC20Withdrawn(_msgSender(), _token, _amount);
    }

    /**
     * @dev Allows users to deposit ERC721 NFTs into their personal vault.
     * The contract acts as a holder, but the NFT is associated with the user's address.
     * Requires the user to approve this contract for the NFT beforehand.
     * @param _nftContract The address of the ERC721 contract.
     * @param _tokenId The ID of the NFT to deposit.
     */
    function depositERC721(address _nftContract, uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_nftContract != address(0), "Deposit: zero address");
        IERC721(_nftContract).transferFrom(_msgSender(), address(this), _tokenId);

        // Add tokenId to user's vault. Assumes unique token IDs per NFT contract.
        // A more robust solution might use a Set-like structure or check for duplicates.
        userERC721Vaults[_msgSender()][_nftContract].push(_tokenId);
        emit ERC721Deposited(_msgSender(), _nftContract, _tokenId);
    }

    /**
     * @dev Allows users to withdraw their deposited ERC721 NFTs from their personal vault.
     * @param _nftContract The address of the ERC721 contract.
     * @param _tokenId The ID of the NFT to withdraw.
     */
    function withdrawERC721(address _nftContract, uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_nftContract != address(0), "Withdraw: zero address");
        
        uint256[] storage userNfts = userERC721Vaults[_msgSender()][_nftContract];
        bool found = false;
        for (uint256 i = 0; i < userNfts.length; i++) {
            if (userNfts[i] == _tokenId) {
                // Efficient removal: replace with last element and pop
                userNfts[i] = userNfts[userNfts.length - 1];
                userNfts.pop();
                found = true;
                break;
            }
        }
        require(found, "Withdraw: NFT not found in user's vault");
        
        IERC721(_nftContract).transferFrom(address(this), _msgSender(), _tokenId);
        emit ERC721Withdrawn(_msgSender(), _nftContract, _tokenId);
    }

    /**
     * @dev Transfers ERC20 tokens from the protocol's main treasury.
     * This function is designed to be called only through successful governance proposals.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount to transfer.
     * @param _recipient The recipient address.
     */
    function transferTreasuryERC20(address _token, uint256 _amount, address _recipient) external whenNotPaused {
        require(_msgSender() == address(this), "Treasury: only protocol can call via proposal");
        require(protocolERC20Treasury[_token] >= _amount, "Treasury: insufficient balance");
        protocolERC20Treasury[_token] = protocolERC20Treasury[_token].sub(_amount);
        IERC20(_token).transfer(_recipient, _amount);
    }

    // --- III. Reputation & Milestone System ---

    /**
     * @dev Awards reputation points to a user.
     * This can be triggered by the owner, guardians, or by internal calls via proposals.
     * @param _user The address to award reputation to.
     * @param _amount The amount of reputation points to award.
     * @param _reason A description for the reputation award.
     */
    function awardReputation(address _user, uint256 _amount, string calldata _reason) external whenNotPaused {
        require(owner() == _msgSender() || guardians[_msgSender()] || _msgSender() == address(this), "Reputation: unauthorized caller");
        _reputationScores[_user] = _reputationScores[_user].add(_amount);
        emit ReputationAwarded(_user, _amount, _reason);
    }

    /**
     * @dev Deducts reputation points from a user.
     * Intended for governance-determined malicious behavior or inactivity, triggered by privileged roles.
     * @param _user The address to deduct reputation from.
     * @param _amount The amount of reputation points to deduct.
     * @param _reason A description for the reputation deduction.
     */
    function deductReputation(address _user, uint256 _amount, string calldata _reason) external whenNotPaused {
        require(owner() == _msgSender() || guardians[_msgSender()] || _msgSender() == address(this), "Reputation: unauthorized caller");
        _reputationScores[_user] = _reputationScores[_user].sub(_amount, "Reputation: insufficient reputation to deduct");
        emit ReputationDeducted(_user, _amount, _reason);
    }

    /**
     * @dev Returns the current reputation score of a given user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address _user) external view returns (uint256) {
        return _reputationScores[_user];
    }

    /**
     * @dev Defines a new reputation milestone with a required score and a token reward.
     * Callable by governance (via proposal).
     * @param _milestoneId A unique ID for the milestone.
     * @param _threshold The minimum reputation score required to achieve this milestone.
     * @param _rewardToken The address of the ERC20 token to be awarded.
     * @param _rewardAmount The amount of the reward token.
     */
    function defineReputationMilestone(uint256 _milestoneId, uint256 _threshold, address _rewardToken, uint256 _rewardAmount) external whenNotPaused {
        require(_msgSender() == address(this), "Milestone: only protocol can define via proposal");
        require(reputationMilestones[_milestoneId].threshold == 0, "Milestone: ID already in use");
        reputationMilestones[_milestoneId] = Milestone(_threshold, _rewardToken, _rewardAmount);
        emit MilestoneDefined(_milestoneId, _threshold, _rewardToken, _rewardAmount);
    }

    /**
     * @dev Allows users who have met a reputation milestone to claim their associated rewards.
     * The reward tokens are transferred from the protocol's main treasury.
     * @param _milestoneId The ID of the milestone to claim.
     */
    function claimMilestoneReward(uint256 _milestoneId) external whenNotPaused nonReentrant {
        Milestone storage milestone = reputationMilestones[_milestoneId];
        require(milestone.threshold > 0, "Milestone: does not exist");
        require(_reputationScores[_msgSender()] >= milestone.threshold, "Milestone: reputation threshold not met");
        require(!milestone.claimedRewards[_msgSender()], "Milestone: reward already claimed");

        milestone.claimedRewards[_msgSender()] = true;
        // Transfer reward from protocol treasury
        protocolERC20Treasury[milestone.rewardToken] = protocolERC20Treasury[milestone.rewardToken].sub(milestone.rewardAmount, "Milestone: insufficient reward tokens in treasury");
        IERC20(milestone.rewardToken).transfer(_msgSender(), milestone.rewardAmount);
        emit MilestoneClaimed(_msgSender(), _milestoneId);
    }

    // --- IV. Decentralized Autonomous Organization (DAO) & Adaptive Strategies ---

    /**
     * @dev Allows users with sufficient reputation to submit a governance proposal.
     * Proposals can specify any function call on any target contract, enabling flexible governance.
     * @param _description A detailed description of the proposal.
     * @param _callData The encoded function call data for the proposal's action.
     * @param _targetContract The address of the contract to call if the proposal passes.
     */
    function submitProposal(string calldata _description, bytes calldata _callData, address _targetContract)
        external
        whenNotPaused
        onlyReputationHolder(protocolParameters["minReputationForProposal"])
    {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            startBlock: block.number,
            endBlock: block.number.add(protocolParameters["minVotingPeriodBlocks"]),
            reputationRequired: protocolParameters["minReputationForProposal"],
            yesVotes: 0,
            noVotes: 0,
            hasVoted: new mapping(address => bool), // Initialize inner mapping
            executed: false,
            canceled: false
        });
        emit ProposalSubmitted(proposalId, _msgSender(), _description);
    }

    /**
     * @dev Users cast their vote on an active proposal.
     * Voting power is directly proportional to their current reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Vote: proposal does not exist");
        require(block.number >= proposal.startBlock, "Vote: voting not started");
        require(block.number <= proposal.endBlock, "Vote: voting ended");
        require(!proposal.hasVoted[_msgSender()], "Vote: already voted");
        require(!proposal.executed, "Vote: proposal already executed");
        require(!proposal.canceled, "Vote: proposal canceled");

        uint256 voterReputation = _reputationScores[_msgSender()];
        require(voterReputation > 0, "Vote: no reputation to vote");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voterReputation);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterReputation);
        }
        emit VoteCast(_proposalId, _msgSender(), _support, voterReputation);
    }

    /**
     * @dev Executes a proposal once it has passed the voting period and met the quorum/majority requirements.
     * Any user can trigger execution.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "Execute: proposal does not exist");
        require(block.number > proposal.endBlock, "Execute: voting period not ended");
        require(!proposal.executed, "Execute: proposal already executed");
        require(!proposal.canceled, "Execute: proposal canceled");

        uint256 totalReputationVoted = proposal.yesVotes.add(proposal.noVotes);
        require(totalReputationVoted > 0, "Execute: no votes cast");

        // Quorum check: 'yes' votes must meet a percentage of total reputation that *actually voted*.
        uint256 quorumRequiredYesVotes = totalReputationVoted.mul(protocolParameters["quorumPercentage"]).div(100);
        require(proposal.yesVotes >= quorumRequiredYesVotes, "Execute: quorum not met (yes votes below required percentage of total votes)");
        
        // Majority check: 'yes' votes must exceed 'no' votes.
        require(proposal.yesVotes > proposal.noVotes, "Execute: proposal did not pass majority");

        proposal.executed = true;
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Execute: proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Registers a new external DeFi strategy contract that the DAO can interact with.
     * This function is intended to be called via a successful governance proposal.
     * @param _strategyContract The address of the strategy contract.
     * @param _name A descriptive name for the strategy.
     * @param _isActive Initial active status of the strategy.
     */
    function registerStrategy(address _strategyContract, string calldata _name, bool _isActive) external whenNotPaused {
        require(_msgSender() == address(this), "Strategy: only protocol can register via proposal");
        require(_strategyContract != address(0), "Strategy: zero address");
        uint256 strategyId = nextStrategyId++;
        strategies[strategyId] = StrategyInfo(strategyId, _strategyContract, _name, _isActive);
        emit StrategyRegistered(strategyId, _strategyContract, _name);
    }

    /**
     * @dev Directs a portion of the DAO's treasury ERC20 assets to an approved, active strategy contract.
     * This function is intended to be called via a successful governance proposal.
     * @param _strategyId The ID of the registered strategy.
     * @param _token The address of the ERC20 token to allocate.
     * @param _amount The amount of tokens to allocate.
     */
    function allocateTreasuryToStrategy(uint256 _strategyId, address _token, uint256 _amount) external whenNotPaused {
        require(_msgSender() == address(this), "Allocation: only protocol can allocate via proposal");
        StrategyInfo storage strategy = strategies[_strategyId];
        require(strategy.isActive, "Allocation: strategy is not active");
        require(strategy.strategyContract != address(0), "Allocation: strategy not registered or invalid address");
        
        require(protocolERC20Treasury[_token] >= _amount, "Allocation: insufficient tokens in protocol treasury");
        protocolERC20Treasury[_token] = protocolERC20Treasury[_token].sub(_amount);
        IERC20(_token).transfer(strategy.strategyContract, _amount);
        emit AssetsAllocatedToStrategy(_strategyId, _token, _amount);
    }

    // --- V. Dynamic Adaptive NFTs (DNFTs) & Oracle-Driven Parameters ---

    /**
     * @dev Allows a user to mint a unique ChronoNexus NFT.
     * These NFTs are intended to be identity-bound, tied to the user's identity and reputation,
     * with evolving metadata. The actual NFT contract is a separate ERC721.
     */
    function mintChronoNexusNFT() external whenNotPaused nonReentrant {
        uint256 newId = chronoNexusNFT.mintTo(_msgSender()); // Mints to the caller
        emit ChronoNexusNFTMinted(_msgSender(), newId);
    }

    /**
     * @dev Updates the base URI for a specific ChronoNexus NFT, enabling dynamic metadata changes.
     * This function is callable by the protocol itself (e.g., via a proposal, or internal logic).
     * @param _tokenId The ID of the ChronoNexus NFT to update.
     * @param _newBaseURI The new base URI for the NFT, pointing to updated metadata.
     */
    function updateChronoNexusNFTMetadata(uint256 _tokenId, string calldata _newBaseURI) external whenNotPaused {
        // Only the protocol itself (via proposals) or the owner for emergency/initial setup can trigger this
        require(_msgSender() == address(this) || _msgSender() == owner(), "Metadata: unauthorized caller");
        chronoNexusNFT.setTokenURI(_tokenId, _newBaseURI);
        emit ChronoNexusNFTMetadataUpdated(_tokenId, _newBaseURI);
    }

    /**
     * @dev Sets the address of the external oracle contract used for fetching off-chain data.
     * Callable only by the owner or via governance proposal.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyGuardianOrOwner {
        require(_newOracle != address(0), "Oracle: zero address");
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /**
     * @dev Triggers a recalibration of protocol parameters based on oracle data.
     * Anyone can call this function to update parameters, but the logic for adjustment
     * is predefined and relies on the oracle. This makes the protocol "adaptive".
     * Example: adjust `quorumPercentage` based on a "protocolHealthScore" from the oracle,
     * or `reputationDecayRatePerBlock` based on "marketVolatility".
     */
    function triggerParameterRecalibration() external whenNotPaused {
        require(oracleAddress != address(0), "Oracle: oracle address not set");
        IOracle oracle = IOracle(oracleAddress);

        // --- Example Adaptive Logic ---

        // 1. Adjust quorum based on a hypothetical "protocolHealthScore"
        uint256 oldQuorum = protocolParameters["quorumPercentage"];
        // Assume oracle.getLatestData("protocolHealthScore") returns a score from 0-100
        uint256 protocolHealthScore = oracle.getLatestData("protocolHealthScore");
        uint256 newQuorum;
        if (protocolHealthScore < 50) { // e.g., low health -> require higher consensus
            newQuorum = 60;
        } else if (protocolHealthScore > 80) { // e.g., high health -> allow faster decision-making
            newQuorum = 30;
        } else {
            newQuorum = 40; // Default
        }
        if (oldQuorum != newQuorum) {
            protocolParameters["quorumPercentage"] = newQuorum;
            emit ParameterRecalibrated("quorumPercentage", oldQuorum, newQuorum);
        }

        // 2. Adjust reputation decay based on market volatility
        uint256 oldDecayRate = protocolParameters["reputationDecayRatePerBlock"];
        // Assume oracle.getLatestData("marketVolatility") returns a volatility index
        uint256 marketVolatility = oracle.getLatestData("marketVolatility");
        uint256 newDecayRate;
        if (marketVolatility > 1000) { // High volatility -> incentivize active participation/risk awareness
            newDecayRate = 5; // Higher decay
        } else {
            newDecayRate = 1; // Lower decay
        }
        if (oldDecayRate != newDecayRate) {
            protocolParameters["reputationDecayRatePerBlock"] = newDecayRate;
            emit ParameterRecalibrated("reputationDecayRatePerBlock", oldDecayRate, newDecayRate);
        }
        // More adaptive logic can be added here for other parameters (e.g., reward multipliers, strategy risk limits)
    }

    /**
     * @dev Returns the current value of a specific protocol parameter.
     * @param _key The string key of the parameter.
     * @return The current uint256 value of the parameter.
     */
    function getProtocolParameter(string calldata _key) external view returns (uint256) {
        return protocolParameters[_key];
    }

    // --- ERC721Holder requires onERC721Received ---
    /**
     * @dev Standard ERC721 `onERC721Received` hook.
     * Allows this contract to receive ERC721 tokens.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
```