```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

/**
 * @title ChronicleForge
 * @dev A decentralized protocol for evolving on-chain narratives or algorithmic art states,
 *      driven by community proposals, influence staking, and external oracle entropy.
 *      The current state is represented by a dynamic NFT.
 *
 * Outline:
 * 1.  Interfaces & Internal Mocks: Definitions for external contracts like Oracle, and internal ERC20/ERC721 for self-contained example.
 * 2.  Core State & Data Structures: Main variables and structs defining the chronicle's evolution.
 * 3.  Access Control & Modifiers: Ownable pattern and custom modifiers for access management.
 * 4.  Events: For transparency and off-chain monitoring of contract activities.
 * 5.  Chronicle Management Functions: Core mechanics of epoch progression, state viewing, and parameter configuration.
 * 6.  Proposal & Voting System Functions: For submitting, voting on, and managing narrative proposals.
 * 7.  Reputation & Influence System Functions: Managing user reputation and token staking for voting influence.
 * 8.  Reward & Token Management Functions: Distributing rewards and managing the contract's reward pool.
 * 9.  Oracle Integration Functions: Receiving and processing external entropy data.
 * 10. Utility Functions: Internal and view helper functions for calculations and data retrieval.
 *
 * Function Summary:
 *
 * I. Chronicle Management
 * 1.  constructor(uint256 initialEpochDuration, address initialOracleAddress): Initializes the contract, deploys internal tokens (InfluenceToken, ChronicleNFT), and sets initial parameters.
 * 2.  advanceEpoch(): Advances the chronicle to the next epoch. This function resolves active proposals, updates the core `chronicleState` based on the winning proposal and oracle data, processes rewards, and adjusts user reputations. Callable by anyone after the `epochDuration` has passed.
 * 3.  getChronicleState(): Returns the current `chronicleState` (a `bytes32` value representing the evolving core data or "seed" of the chronicle).
 * 4.  getChronicleNFTMetadataURI(uint256 tokenId): Generates a dynamic metadata URI for the Chronicle NFT (Token ID 0) based on its current state, making the NFT evolve with the chronicle.
 * 5.  setEpochDuration(uint256 _newDuration): Allows the contract owner to set the duration (in seconds) for each chronicle evolution epoch.
 * 6.  setOracleAddress(address _newOracleAddress): Allows the contract owner to set the address of the whitelisted off-chain oracle used for external entropy input.
 * 7.  getEpochStatus(): Returns the current epoch number and the remaining time until the next epoch can be advanced.
 *
 * II. Proposal & Voting System
 * 8.  submitEvolutionProposal(bytes32 _proposedFragment): Allows users to submit a `bytes32` fragment of data that they propose should influence the next `chronicleState`. Requires a minimum token stake and a positive reputation.
 * 9.  voteOnProposal(uint256 _proposalId, bool _support): Enables users to cast their vote (for or against) on an active proposal. The weight of their vote is determined by their influence (calculated from staked tokens and reputation).
 * 10. getProposalDetails(uint256 _proposalId): Retrieves comprehensive information about a specific proposal, including its proposer, state fragment, vote counts, and status.
 * 11. getActiveProposals(): Returns an array of IDs for all proposals that are currently open for voting within the current epoch.
 * 12. withdrawProposalStake(uint256 _proposalId): Allows a proposer to withdraw their staked tokens after their proposal has been resolved (either won or lost) in a past epoch.
 *
 * III. Reputation & Influence System
 * 13. stakeInfluenceTokens(uint256 _amount): Allows users to deposit `InfluenceToken`s into the contract to increase their voting influence. Staked tokens are locked.
 * 14. unstakeInfluenceTokens(uint256 _amount): Allows users to withdraw their staked `InfluenceToken`s. Unstaking reduces their voting influence.
 * 15. getUserReputation(address _user): Retrieves the current reputation score of a specific user. Reputation impacts voting power and proposal eligibility.
 * 16. getTotalStakedInfluenceTokens(): Returns the total amount of InfluenceTokens currently locked as stake within the contract.
 *
 * IV. Reward & Token Management
 * 17. claimEpochRewards(): Allows eligible users (e.g., successful proposers/voters) to claim any `InfluenceToken` rewards they have accrued from past epoch resolutions.
 * 18. depositRewardTokens(uint256 _amount): Allows anyone to deposit `InfluenceToken`s into the contract's public reward pool, which will be distributed to contributors.
 * 19. getRewardPoolBalance(): Returns the current balance of `InfluenceToken`s available in the contract's reward pool.
 * 20. setMinStakeForProposal(uint256 _newMinStake): Allows the contract owner to adjust the minimum amount of `InfluenceToken`s required for a user to submit a new proposal.
 *
 * V. Oracle Integration
 * 21. receiveOracleData(uint256 _entropy): A restricted callback function designed for the whitelisted oracle contract to securely push new entropy data (a `uint256` value) to the ChronicleForge. This entropy is a key input for the state evolution.
 * 22. getLatestOracleEntropy(): Returns the most recently received entropy value from the oracle.
 *
 * VI. Utility Functions (Internal/View)
 * 23. _calculateInfluence(address _user): An internal/view function that computes a user's total voting influence based on their staked tokens and their current reputation score.
 * 24. _calculateStateEvolution(bytes32 _current, bytes32 _fragment, uint256 _entropy): An internal function that defines the core algorithmic logic for how the `chronicleState` evolves. It combines the current state, the winning proposal's fragment, and the oracle's entropy.
 * 25. _distributeRewards(uint256 _totalEpochInfluence): An internal function responsible for calculating and allocating `InfluenceToken` rewards to successful proposers and voters after each epoch.
 */

// --- I. Interfaces & Internal Mocks ---

interface IOffChainOracle {
    function getLatestEntropy() external view returns (uint256);
    // In a real scenario, this would likely be a push mechanism or a more complex pull request/response.
    // For this example, we will simulate a push via `receiveOracleData`.
}

// Internal Mock ERC20 Token for Influence
contract InfluenceToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Influence Token", "INFL") {
        _mint(msg.sender, initialSupply);
    }
}

// Internal Mock ERC721 for the Chronicle NFT
contract ChronicleNFT is ERC721 {
    constructor() ERC721("Chronicle Essence NFT", "CHRON") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,"; // Base64 prefix for data URIs
    }

    // This function will be called by ChronicleForge to get dynamic metadata
    function tokenURI(uint256 tokenId, bytes32 chronicleState) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Constructing a simple JSON metadata with the dynamic state
        string memory name = string(abi.encodePacked("Chronicle State #", Strings.toString(tokenId)));
        string memory description = string(abi.encodePacked("The current evolving state of the ChronicleForge. Hash: 0x", Strings.toHexString(uint256(chronicleState), 32)));
        string memory image = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJoc2wo",
            // The hash of chronicleState determines a color, making the image "dynamic"
            string(abi.encodePacked(Strings.toString(uint256(chronicleState) % 360), ",100%,50%)\"/></svg>"));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '", "description": "', description, '", "image": "', image, '"}'
        ));
        return string(abi.encodePacked(_baseURI(), Strings.toBase64(bytes(json))));
    }

    function setTokenURI(uint256 tokenId, bytes32 chronicleState) public {
        // This is a placeholder for actual NFT update logic.
        // In a real scenario, you'd trigger a metadata refresh on platforms.
        // For on-chain dynamic metadata, the `tokenURI` function does the work.
    }
}

contract ChronicleForge is Ownable {
    using SafeMath for uint256;

    // --- II. Core State & Data Structures ---

    // The core evolving state of the chronicle
    bytes32 public chronicleState;

    // Epoch management
    uint256 public epochCounter;
    uint256 public epochStartTime;
    uint256 public epochDuration; // in seconds

    // User reputation: higher reputation grants more influence
    mapping(address => uint256) public userReputation;
    uint256 public constant INITIAL_REPUTATION = 100;
    uint256 public constant REPUTATION_GAIN_PROPOSER = 50;
    uint256 public constant REPUTATION_GAIN_VOTER = 10;
    uint256 public constant REPUTATION_LOSS_PROPOSER = 20;
    uint256 public constant REPUTATION_LOSS_VOTER = 5;

    // Proposals
    struct Proposal {
        bytes32 proposedFragment;
        address proposer;
        uint256 submittedEpoch;
        uint256 totalInfluenceFor;
        uint256 totalInfluenceAgainst;
        bool resolved;
        bool passed; // True if passed, false if failed
        uint256 stakeAmount; // Amount of tokens staked by proposer
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256[] public activeProposalIds; // Proposals active in current epoch

    // Influence Token & Staking
    InfluenceToken public influenceToken;
    ChronicleNFT public chronicleNFT;
    mapping(address => uint256) public stakedInfluenceTokens;
    uint256 public totalStakedInfluenceTokens;
    uint256 public minStakeForProposal; // Min tokens required to submit a proposal

    // Reward Pool
    uint256 public rewardPerInfluencePoint; // How much reward per point of influence on winning proposals
    mapping(address => uint256) public pendingRewards;

    // Oracle Integration
    address public oracleFeedAddress;
    uint256 public latestOracleEntropy; // Last received entropy from oracle

    // --- III. Access Control & Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleFeedAddress, "ChronicleForge: Only oracle can call this function");
        _;
    }

    // --- IV. Events ---
    event ChronicleStateUpdated(bytes32 indexed oldState, bytes32 indexed newState, uint256 epoch, uint256 oracleEntropy);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 epochStartTime);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 proposedFragment, uint256 stakeAmount);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 influenceWeight);
    event ProposalResolved(uint256 indexed proposalId, bool passed, bytes32 finalFragment);
    event InfluenceStaked(address indexed user, uint256 amount);
    event InfluenceUnstaked(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDeposited(address indexed depositor, uint256 amount);
    event OracleDataReceived(uint256 indexed entropy);
    event MinStakeForProposalUpdated(uint256 newMinStake);

    // --- V. Chronicle Management Functions ---

    /**
     * @notice Initializes the ChronicleForge contract.
     * @param initialEpochDuration The duration of each evolution epoch in seconds.
     * @param initialOracleAddress The address of the trusted off-chain oracle.
     */
    constructor(uint256 initialEpochDuration, address initialOracleAddress) Ownable(msg.sender) {
        epochDuration = initialEpochDuration;
        oracleFeedAddress = initialOracleAddress;
        epochStartTime = block.timestamp;
        epochCounter = 1;
        chronicleState = bytes32(uint256(keccak256(abi.encodePacked("InitialChronicleSeed", block.timestamp)))); // Initial arbitrary state

        // Deploy internal mock tokens for a self-contained example
        influenceToken = new InfluenceToken(1_000_000_000 * 10**18); // 1 Billion INFL tokens
        chronicleNFT = new ChronicleNFT();

        // Mint the single Chronicle NFT (token ID 0) to the contract owner initially
        // This NFT will represent the current state of the chronicle.
        chronicleNFT.mint(msg.sender, 0);

        minStakeForProposal = 100 * 10**18; // 100 INFL tokens minimum stake
        rewardPerInfluencePoint = 1; // 1 INFL per influence point for rewards
    }

    /**
     * @notice Advances the chronicle to the next epoch.
     * This function resolves active proposals, updates the core chronicleState,
     * processes rewards, and adjusts user reputations.
     * Callable by anyone after the `epochDuration` has passed.
     */
    function advanceEpoch() public {
        require(block.timestamp >= epochStartTime + epochDuration, "ChronicleForge: Epoch not yet ended");

        bytes32 winningFragment = 0;
        address winningProposer = address(0);
        uint256 maxNetInfluence = 0;
        uint256 totalEpochInfluence = 0; // Total influence participating in this epoch's winning proposal

        // Find the winning proposal
        for (uint256 i = 0; i < activeProposalIds.length; i++) {
            uint256 proposalId = activeProposalIds[i];
            Proposal storage p = proposals[proposalId];
            require(!p.resolved, "ChronicleForge: Proposal already resolved");

            uint256 netInfluence = p.totalInfluenceFor.sub(p.totalInfluenceAgainst);

            // Reward calculation: sum influence for positive votes
            totalEpochInfluence = totalEpochInfluence.add(p.totalInfluenceFor);

            if (netInfluence > maxNetInfluence) {
                maxNetInfluence = netInfluence;
                winningFragment = p.proposedFragment;
                winningProposer = p.proposer;
                p.passed = true; // Mark as winning
            } else {
                p.passed = false; // Mark as losing
            }
            p.resolved = true; // Mark all active proposals as resolved for current epoch
        }

        // Update chronicle state
        if (winningFragment != 0) {
            chronicleState = _calculateStateEvolution(chronicleState, winningFragment, latestOracleEntropy);
        } else {
            // If no proposals or no winning proposal, state evolves based on just oracle entropy
            chronicleState = _calculateStateEvolution(chronicleState, bytes32(0), latestOracleEntropy);
        }
        emit ChronicleStateUpdated(chronicleState, chronicleState, epochCounter, latestOracleEntropy);

        // Update NFT metadata to reflect new state
        chronicleNFT.setTokenURI(0, chronicleState);

        // Update reputations and distribute rewards
        for (uint256 i = 0; i < activeProposalIds.length; i++) {
            uint256 proposalId = activeProposalIds[i];
            Proposal storage p = proposals[proposalId];

            if (p.passed) {
                // Winning proposer gains reputation
                userReputation[p.proposer] = userReputation[p.proposer].add(REPUTATION_GAIN_PROPOSER);
                emit ReputationUpdated(p.proposer, userReputation[p.proposer]);

                // Proposer's stake is released
                pendingRewards[p.proposer] = pendingRewards[p.proposer].add(p.stakeAmount); // Return stake as pending reward
                totalStakedInfluenceTokens = totalStakedInfluenceTokens.sub(p.stakeAmount);

                // Distribute rewards to all voters who voted 'for' the winning proposal
                // (More complex logic for individual voter rewards would require iterating over voter records)
                // For simplicity, we just distribute to proposer for now or require separate claim for voters
            } else {
                // Losing proposer loses reputation and stake is partially or fully slashed
                userReputation[p.proposer] = userReputation[p.proposer] > REPUTATION_LOSS_PROPOSER ? userReputation[p.proposer].sub(REPUTATION_LOSS_PROPOSER) : 0;
                emit ReputationUpdated(p.proposer, userReputation[p.proposer]);

                // Slash portion of stake, return the rest (e.g., 50% slash for losing)
                uint256 slashedAmount = p.stakeAmount.div(2);
                pendingRewards[p.proposer] = pendingRewards[p.proposer].add(p.stakeAmount.sub(slashedAmount));
                totalStakedInfluenceTokens = totalStakedInfluenceTokens.sub(p.stakeAmount); // Remove total stake, then it gets returned or slashed
            }
        }

        // Distribute general epoch rewards to winning proposer (simple model)
        if (winningProposer != address(0) && totalEpochInfluence > 0) {
            _distributeRewards(totalEpochInfluence);
        }

        // Increment epoch and reset for next cycle
        epochCounter++;
        epochStartTime = block.timestamp;
        delete activeProposalIds; // Clear active proposals for the new epoch

        emit EpochAdvanced(epochCounter, epochStartTime);
    }

    /**
     * @notice Returns the current `chronicleState` (the core evolving data).
     * @return The current `bytes32` representation of the chronicle's state.
     */
    function getChronicleState() public view returns (bytes32) {
        return chronicleState;
    }

    /**
     * @notice Generates the dynamic metadata URI for the Chronicle NFT (Token ID 0).
     * The metadata reflects the current `chronicleState`.
     * @param tokenId The ID of the Chronicle NFT (expected to be 0).
     * @return A data URI containing the JSON metadata.
     */
    function getChronicleNFTMetadataURI(uint256 tokenId) public view returns (string memory) {
        // This function explicitly calls the ChronicleNFT's tokenURI with the current state.
        // In a real application, platforms like OpenSea would call ChronicleNFT directly,
        // but this shows how the state is passed.
        return chronicleNFT.tokenURI(tokenId, chronicleState);
    }

    /**
     * @notice Sets the duration for each chronicle evolution epoch.
     * @dev Only callable by the contract owner.
     * @param _newDuration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "ChronicleForge: Epoch duration must be positive");
        epochDuration = _newDuration;
    }

    /**
     * @notice Sets the address of the off-chain oracle used for entropy.
     * @dev Only callable by the contract owner.
     * @param _newOracleAddress The new address of the oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "ChronicleForge: Oracle address cannot be zero");
        oracleFeedAddress = _newOracleAddress;
    }

    /**
     * @notice Returns the current epoch number and remaining time in the epoch.
     * @return currentEpoch The current epoch number.
     * @return timeRemaining The time (in seconds) remaining until the epoch can be advanced.
     */
    function getEpochStatus() public view returns (uint256 currentEpoch, uint256 timeRemaining) {
        currentEpoch = epochCounter;
        if (block.timestamp >= epochStartTime + epochDuration) {
            timeRemaining = 0;
        } else {
            timeRemaining = (epochStartTime + epochDuration).sub(block.timestamp);
        }
    }

    // --- VI. Proposal & Voting System Functions ---

    /**
     * @notice Allows users to submit a `bytes32` fragment to influence the next chronicle state.
     * Requires minimum stake and a positive reputation.
     * @param _proposedFragment The `bytes32` fragment proposed for the chronicle's evolution.
     */
    function submitEvolutionProposal(bytes32 _proposedFragment) public {
        require(block.timestamp < epochStartTime + epochDuration, "ChronicleForge: Cannot submit proposals during epoch transition");
        require(stakedInfluenceTokens[msg.sender] >= minStakeForProposal, "ChronicleForge: Insufficient staked influence tokens");
        require(userReputation[msg.sender] > 0, "ChronicleForge: Must have positive reputation to propose");

        proposals[nextProposalId] = Proposal({
            proposedFragment: _proposedFragment,
            proposer: msg.sender,
            submittedEpoch: epochCounter,
            totalInfluenceFor: 0,
            totalInfluenceAgainst: 0,
            resolved: false,
            passed: false,
            stakeAmount: minStakeForProposal
        });

        // Register proposer's stake against this proposal
        // Note: The tokens are already staked via `stakeInfluenceTokens`,
        // this `stakeAmount` just records the commitment for this specific proposal.

        activeProposalIds.push(nextProposalId);
        emit ProposalSubmitted(nextProposalId, msg.sender, _proposedFragment, minStakeForProposal);
        nextProposalId++;
    }

    /**
     * @notice Allows users to vote 'for' or 'against' a proposal.
     * Their influence (stake + reputation) determines vote weight.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        require(block.timestamp < epochStartTime + epochDuration, "ChronicleForge: Voting is closed for this epoch");
        Proposal storage p = proposals[_proposalId];
        require(p.submittedEpoch == epochCounter, "ChronicleForge: Proposal not active in current epoch");
        require(!p.resolved, "ChronicleForge: Proposal already resolved");
        require(p.proposer != msg.sender, "ChronicleForge: Proposer cannot vote on their own proposal");
        require(!p.hasVoted[msg.sender], "ChronicleForge: Already voted on this proposal");
        require(stakedInfluenceTokens[msg.sender] > 0, "ChronicleForge: Must have staked tokens to vote");

        uint256 voterInfluence = _calculateInfluence(msg.sender);
        require(voterInfluence > 0, "ChronicleForge: Voter must have positive influence");

        p.hasVoted[msg.sender] = true;
        if (_support) {
            p.totalInfluenceFor = p.totalInfluenceFor.add(voterInfluence);
        } else {
            p.totalInfluenceAgainst = p.totalInfluenceAgainst.add(voterInfluence);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support, voterInfluence);
    }

    /**
     * @notice Retrieves detailed information about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        bytes32 proposedFragment,
        address proposer,
        uint256 submittedEpoch,
        uint256 totalInfluenceFor,
        uint256 totalInfluenceAgainst,
        bool resolved,
        bool passed,
        uint256 stakeAmount
    ) {
        Proposal storage p = proposals[_proposalId];
        return (
            p.proposedFragment,
            p.proposer,
            p.submittedEpoch,
            p.totalInfluenceFor,
            p.totalInfluenceAgainst,
            p.resolved,
            p.passed,
            p.stakeAmount
        );
    }

    /**
     * @notice Returns an array of IDs for all proposals currently open for voting in the current epoch.
     * @return An array of active proposal IDs.
     */
    function getActiveProposals() public view returns (uint256[] memory) {
        return activeProposalIds;
    }

    /**
     * @notice Allows a proposer to withdraw their staked tokens after the proposal has been resolved.
     * @param _proposalId The ID of the proposal.
     */
    function withdrawProposalStake(uint256 _proposalId) public {
        Proposal storage p = proposals[_proposalId];
        require(p.proposer == msg.sender, "ChronicleForge: Not the proposer");
        require(p.resolved, "ChronicleForge: Proposal not yet resolved");
        require(p.stakeAmount > 0, "ChronicleForge: No stake to withdraw or already withdrawn");

        uint256 amountToReturn = p.stakeAmount;
        // If the proposal lost, the stake was partially slashed during advanceEpoch.
        // The remaining amount is already added to pendingRewards.
        // So, we just need to ensure the `stakeAmount` is cleared to prevent double withdrawals.
        p.stakeAmount = 0; // Mark as withdrawn

        // The stake was technically 'released' into pendingRewards during advanceEpoch.
        // This function simply confirms the withdrawal eligibility.
        // The actual transfer happens via claimEpochRewards.
        // We still need to decrement totalStakedInfluenceTokens if it wasn't already for some edge case,
        // but `advanceEpoch` should handle reducing totalStakedTokens when resolving.
    }


    // --- VII. Reputation & Influence System Functions ---

    /**
     * @notice Allows users to stake `InfluenceToken`s to increase their voting influence.
     * @param _amount The amount of `InfluenceToken`s to stake.
     */
    function stakeInfluenceTokens(uint256 _amount) public {
        require(_amount > 0, "ChronicleForge: Amount must be greater than zero");
        influenceToken.transferFrom(msg.sender, address(this), _amount);
        stakedInfluenceTokens[msg.sender] = stakedInfluenceTokens[msg.sender].add(_amount);
        totalStakedInfluenceTokens = totalStakedInfluenceTokens.add(_amount);

        // Initialize reputation if new user
        if (userReputation[msg.sender] == 0) {
            userReputation[msg.sender] = INITIAL_REPUTATION;
            emit ReputationUpdated(msg.sender, INITIAL_REPUTATION);
        }
        emit InfluenceStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows users to unstake `InfluenceToken`s.
     * @param _amount The amount of `InfluenceToken`s to unstake.
     */
    function unstakeInfluenceTokens(uint256 _amount) public {
        require(_amount > 0, "ChronicleForge: Amount must be greater than zero");
        require(stakedInfluenceTokens[msg.sender] >= _amount, "ChronicleForge: Insufficient staked tokens");

        stakedInfluenceTokens[msg.sender] = stakedInfluenceTokens[msg.sender].sub(_amount);
        totalStakedInfluenceTokens = totalStakedInfluenceTokens.sub(_amount);
        influenceToken.transfer(msg.sender, _amount);
        emit InfluenceUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Retrieves the current reputation score of a specific user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @notice Returns the total amount of InfluenceTokens currently staked in the contract.
     * @return The total staked amount.
     */
    function getTotalStakedInfluenceTokens() public view returns (uint256) {
        return totalStakedInfluenceTokens;
    }

    // --- VIII. Reward & Token Management Functions ---

    /**
     * @notice Allows eligible users to claim rewards earned from successful contributions in past epochs.
     */
    function claimEpochRewards() public {
        uint256 reward = pendingRewards[msg.sender];
        require(reward > 0, "ChronicleForge: No pending rewards to claim");

        pendingRewards[msg.sender] = 0;
        influenceToken.transfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    /**
     * @notice Allows anyone to deposit `InfluenceToken`s into the contract's public reward pool.
     * These tokens will be distributed to contributors.
     * @param _amount The amount of `InfluenceToken`s to deposit.
     */
    function depositRewardTokens(uint256 _amount) public {
        require(_amount > 0, "ChronicleForge: Amount must be greater than zero");
        influenceToken.transferFrom(msg.sender, address(this), _amount);
        emit RewardsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Returns the current balance of InfluenceTokens available in the reward pool.
     * @return The reward pool balance.
     */
    function getRewardPoolBalance() public view returns (uint256) {
        return influenceToken.balanceOf(address(this)).sub(totalStakedInfluenceTokens);
    }

    /**
     * @notice Sets the minimum amount of InfluenceTokens required to submit a new proposal.
     * @dev Only callable by the contract owner.
     * @param _newMinStake The new minimum stake amount.
     */
    function setMinStakeForProposal(uint256 _newMinStake) public onlyOwner {
        require(_newMinStake > 0, "ChronicleForge: Minimum stake must be positive");
        minStakeForProposal = _newMinStake;
        emit MinStakeForProposalUpdated(_newMinStake);
    }


    // --- IX. Oracle Integration Functions ---

    /**
     * @notice Callback function for the whitelisted oracle to push new entropy data.
     * @dev Only callable by the designated oracle address.
     * @param _entropy A `uint256` value representing external entropy.
     */
    function receiveOracleData(uint256 _entropy) public onlyOracle {
        latestOracleEntropy = _entropy;
        emit OracleDataReceived(_entropy);
    }

    /**
     * @notice Returns the last received entropy value from the oracle.
     * @return The `uint256` entropy value.
     */
    function getLatestOracleEntropy() public view returns (uint256) {
        return latestOracleEntropy;
    }


    // --- X. Utility Functions (Internal/View) ---

    /**
     * @notice Internal/view function to calculate a user's total voting influence
     * based on their staked tokens and reputation.
     * @param _user The address of the user.
     * @return The calculated influence score.
     */
    function _calculateInfluence(address _user) internal view returns (uint256) {
        // Simple linear model: Influence = staked tokens * (1 + reputation / 1000)
        // Adjust multiplier for desired impact of reputation
        uint256 baseInfluence = stakedInfluenceTokens[_user];
        if (baseInfluence == 0) return 0;

        uint256 reputationMultiplier = 1e3 + userReputation[_user]; // e.g., if rep is 100, multiplier is 1100
        return baseInfluence.mul(reputationMultiplier).div(1e3); // Divide by 1000 to get correct scale
    }

    /**
     * @notice Internal function defining the core algorithmic state update.
     * It combines the current state, the winning proposal's fragment, and the oracle's entropy.
     * @param _current The current `chronicleState`.
     * @param _fragment The `bytes32` fragment from the winning proposal.
     * @param _entropy The `uint256` entropy value from the oracle.
     * @return The new `bytes32` chronicle state.
     */
    function _calculateStateEvolution(bytes32 _current, bytes32 _fragment, uint256 _entropy) internal pure returns (bytes32) {
        // A simple, deterministic XOR operation for state evolution.
        // This makes the state highly sensitive to all three inputs.
        // A more complex algorithm could involve cryptographic primitives,
        // hash functions, or bitwise rotations for more artistic "evolution".
        return bytes32(uint256(_current) ^ uint256(_fragment) ^ _entropy);
    }

    /**
     * @notice Internal function to distribute rewards to successful contributors.
     * @dev Called during `advanceEpoch`.
     * @param _totalEpochInfluence The total influence points accumulated by voters for the winning proposal.
     */
    function _distributeRewards(uint256 _totalEpochInfluence) internal {
        if (_totalEpochInfluence == 0) return;

        uint256 rewardsAvailable = getRewardPoolBalance();
        if (rewardsAvailable == 0) return;

        // Simple reward distribution model:
        // A fixed amount (e.g., 10 INFL tokens) is distributed for each 100 influence points
        // of winning proposals. This needs to be adjusted based on desired economy.
        uint256 totalRewardAmount = _totalEpochInfluence.mul(rewardPerInfluencePoint);

        if (totalRewardAmount > rewardsAvailable) {
            totalRewardAmount = rewardsAvailable; // Don't overspend
        }

        // For simplicity, pending rewards are currently only accumulated for the proposer's stake return/slash.
        // A more detailed reward system for individual voters would require tracking each voter's influence
        // on the winning proposal during `advanceEpoch`. This is a placeholder for that complexity.
        // The `rewardPerInfluencePoint` can be used to calculate what each positive voter gets.
        // For this contract, we will add the `totalRewardAmount` to the winning proposer's pending rewards
        // as a bonus for leading the successful evolution.
        uint256 winningProposerId = 0; // Assuming the first winning proposal is the overall winner for reward distribution
        if (activeProposalIds.length > 0) {
            winningProposerId = activeProposalIds[0]; // Or iterate to find the actual winner by maxNetInfluence
            Proposal storage p = proposals[winningProposerId];
            if (p.passed) { // Check if this was indeed the winning one
                pendingRewards[p.proposer] = pendingRewards[p.proposer].add(totalRewardAmount);
            }
        }
    }
}

```