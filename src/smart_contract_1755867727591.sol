This smart contract, `EmergentCognitionNetwork`, establishes a decentralized ecosystem for "Digital Sentient Entities" (DSEs), which are represented as dynamic Non-Fungible Tokens (dNFTs). DSEs are the core participants, tasked with curating a shared "Knowledge Base" and governing the network. Their influence and rewards are directly tied to their "Cognitive Score," a dynamic on-chain attribute reflecting their reputation and successful contributions.

The contract integrates several advanced concepts:

1.  **Dynamic NFTs (dNFTs):** DSEs are ERC721 tokens whose core attributes, particularly `cognitiveScore` and `level`, are dynamically updated on-chain based on their participation and performance within the network. External services can then render NFT metadata and artwork reflecting these evolving states.
2.  **Adaptive Consensus & Reputation System:** Instead of simple one-token-one-vote, DSEs vote on "Knowledge Fragments" and "Governance Proposals" with a weight proportional to their `cognitiveScore`. This score is continuously adjusted (boosted or slashed) based on the outcome of their contributions, creating a self-regulating reputation-weighted governance model.
3.  **Decentralized Knowledge Base:** DSEs can submit "Knowledge Fragments" (e.g., verified data, assertions) for validation by other DSEs. Accepted fragments are added to an immutable, on-chain knowledge base, fostering collective intelligence.
4.  **Gamified Economics:** DSEs require an `EnergyToken` (an ERC20) to perform actions like submitting fragments or voting. Successful contributions are rewarded with more `EnergyToken` and boosts to their `cognitiveScore` and `level`, incentivizing active and constructive participation.
5.  **Self-Evolving Governance:** The network can evolve its own parameters (e.g., minting costs, voting periods) through a robust proposal system. DSEs with sufficient `cognitiveScore` can propose changes, and collective cognitive-weighted voting dictates execution, allowing the system to adapt over time.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// ERC20 token for Energy. This would be deployed separately.
// For demonstration, a placeholder interface is used which includes a `mint` function
// for distributing rewards (as rewards are "generated" by the network).
interface IEnergyToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/**
 * @title EmergentCognitionNetwork
 * @dev A decentralized network of "Digital Sentient Entities" (DSEs) represented by dynamic NFTs.
 * DSEs collaborate to curate a "Knowledge Base" of validated information and collectively govern
 * the network through an adaptive consensus mechanism where influence is directly tied to a DSE's "Cognitive Score."
 */
contract EmergentCognitionNetwork is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    /*
     * OUTLINE
     *
     * I. Core Infrastructure:
     *    - ERC721Enumerable: Manages DSE NFTs, allowing enumeration and ownership tracking.
     *    - ERC20 (EnergyToken): A fungible token crucial for DSE operations, staking, and rewards.
     *    - Ownable: Initial administrative control over core parameters, transitioning to DAO governance over time.
     *
     * II. DSE (Digital Sentient Entity) Management:
     *    - DSE NFT: Each DSE is a unique, dynamic ERC721 token with evolving on-chain attributes.
     *    - Cognitive Score: A core dynamic attribute representing a DSE's reputation and influence. It increases with positive contributions and decreases with negative ones.
     *    - Energy Reserve: Staked `EnergyToken` within a DSE, required to perform actions.
     *    - Level: A gamified progression metric derived from the Cognitive Score.
     *
     * III. Knowledge Fragment System:
     *    - Submission: DSEs propose "Knowledge Fragments" (data assertions/verified information) to the network.
     *    - Validation: DSEs vote on fragments, with their vote weight determined by their Cognitive Score.
     *    - Resolution: Fragments are accepted or rejected based on the collective cognitive weight, and successful contributors are rewarded.
     *    - Knowledge Base: Accepted fragments are immutably added to the network's on-chain "Knowledge Base."
     *
     * IV. Adaptive Consensus & Governance:
     *    - Proposals: DSEs with sufficient Cognitive Score can submit governance proposals to modify network parameters or execute arbitrary calls.
     *    - Weighted Voting: DSEs vote on proposals, again with their influence scaled by their Cognitive Score.
     *    - Execution: Accepted proposals are automatically executed by the contract.
     *
     * V. Economic & Incentive Layer:
     *    - Energy Consumption: Performing actions (submitting fragments, voting, proposing) consumes `EnergyToken` from a DSE's reserve.
     *    - Rewards: DSEs are rewarded with `EnergyToken` for valuable fragment submissions and successful governance participation.
     *    - Slashing/Boosting: Cognitive Scores are dynamically adjusted based on the outcome of fragment validations and proposal votes, ensuring alignment with network goals.
     */

    /*
     * FUNCTION SUMMARY
     *
     * DSE Creation & Attributes:
     * 1.  `mintDSE(string memory _initialMetadataURI)`: Mints a new DSE NFT with an initial URI, requiring `EnergyToken` payment.
     * 2.  `getDSE(uint256 _dseId)`: Retrieves a DSE's core on-chain data.
     * 3.  `getDSEOwner(uint256 _dseId)`: Returns the owner address of a DSE. (ERC721 `ownerOf`)
     * 4.  `updateDSEMetadataURI(uint256 _dseId, string memory _newURI)`: Allows DSE owner to update the DSE's base metadata URI.
     * 5.  `getDSENFTAttributes(uint256 _dseId)`: Provides a comprehensive view of a DSE's dynamic attributes (score, level, energy).
     * 6.  `transferDSE(address _from, address _to, uint256 _dseId)`: Transfers DSE ownership. (ERC721 `transferFrom`)
     * 7.  `getDSELevel(uint256 _dseId)`: Calculates and returns a DSE's level based on its Cognitive Score.
     *
     * Energy Token Management:
     * 8.  `setEnergyTokenAddress(address _newAddress)`: Sets the address of the ERC20 `EnergyToken` contract (admin/governance).
     * 9.  `depositEnergyToDSE(uint256 _dseId, uint256 _amount)`: Stakes `EnergyToken` into a DSE's energy reserve.
     * 10. `withdrawEnergyFromDSE(uint256 _dseId, uint256 _amount)`: Allows withdrawal of `EnergyToken` from a DSE's reserve.
     * 11. `getDSEEnergyReserve(uint256 _dseId)`: Returns the current `EnergyToken` balance of a DSE.
     *
     * Knowledge Fragment Operations:
     * 12. `submitKnowledgeFragment(uint256 _dseId, bytes32 _dataHash)`: Submits a new "Knowledge Fragment" for community validation, requiring DSE energy and minimum cognitive score.
     * 13. `voteOnKnowledgeFragment(uint256 _fragmentId, uint256 _dseId, bool _support)`: Casts a vote (for/against) on a knowledge fragment, consuming DSE energy.
     * 14. `resolveKnowledgeFragment(uint256 _fragmentId)`: Initiates the resolution process for a fragment, distributing rewards and adjusting Cognitive Scores.
     * 15. `getKnowledgeFragment(uint256 _fragmentId)`: Retrieves detailed information about a knowledge fragment.
     * 16. `getKnowledgeBaseEntry(uint256 _fragmentId)`: Returns the hash of an accepted fragment from the Knowledge Base.
     * 17. `claimFragmentSubmissionReward(uint256 _dseId, uint256 _fragmentId)`: Allows a DSE (submitter) to claim earned rewards for an accepted fragment.
     *
     * Governance & Parameter Tuning:
     * 18. `createGovernanceProposal(uint256 _dseId, bytes32 _descriptionHash, address _targetContract, bytes memory _calldata)`: DSE submits a proposal for network changes, requiring high cognitive score and energy.
     * 19. `voteOnProposal(uint256 _proposalId, uint256 _dseId, bool _support)`: DSE votes on a governance proposal.
     * 20. `executeProposal(uint256 _proposalId)`: Executes an accepted governance proposal.
     * 21. `getProposal(uint256 _proposalId)`: Retrieves details of a governance proposal.
     * 22. `setBaseMintCost(uint256 _newCost)`: Admin/governance function to update the DSE minting cost.
     * 23. `setValidationThreshold(uint256 _newThreshold)`: Admin/governance function to set minimum Cognitive Score for fragment submission.
     * 24. `setFragmentValidationPeriod(uint256 _newPeriod)`: Admin/governance function to set the duration for fragment voting.
     * 25. `setProposalVotingPeriod(uint256 _newPeriod)`: Admin/governance function to set the duration for proposal voting.
     * 26. `setCognitiveScoreAdjustments(uint256 _boost, uint256 _slash)`: Admin/governance function to configure score adjustment values.
     */

    // --- State Variables ---

    uint256 private _dseCounter; // Tracks total DSEs minted
    uint256 private _fragmentCounter; // Tracks total knowledge fragments submitted
    uint256 private _proposalCounter; // Tracks total governance proposals submitted

    // Structs for DSEs, Knowledge Fragments, and Proposals
    struct DSE {
        uint256 cognitiveScore;      // Reputation and influence
        uint256 energyReserve;       // Staked EnergyToken for operations
        string metadataURI;          // Base URI, dynamic attributes fetched off-chain
        uint256 level;               // Gamified progression
        uint256 lastActionTimestamp; // To implement cooldowns if needed
        bool exists;                 // To check if DSE ID is valid
    }

    enum FragmentStatus { Pending, Accepted, Rejected }
    struct KnowledgeFragment {
        uint256 submitterDSEId;
        bytes32 dataHash;         // IPFS hash or similar immutable data reference
        uint256 submissionTime;
        uint256 totalCognitiveWeightFor;
        uint256 totalCognitiveWeightAgainst;
        FragmentStatus status;
        bool isResolved;
    }

    enum ProposalStatus { Pending, Accepted, Rejected, Executed }
    struct Proposal {
        uint256 proposerDSEId;
        bytes32 descriptionHash; // IPFS hash for proposal details
        address targetContract;  // Contract address to call if proposal passes
        bytes calldataPayload;   // Calldata for the targetContract call
        uint256 submissionTime;
        uint256 totalCognitiveWeightFor;
        uint256 totalCognitiveWeightAgainst;
        ProposalStatus status;
        bool isExecuted;
    }

    // Mappings for state management
    mapping(uint256 => DSE) public dseData; // DSE ID -> DSE struct
    mapping(uint256 => KnowledgeFragment) public knowledgeFragments; // Fragment ID -> KnowledgeFragment struct
    mapping(uint256 => mapping(uint256 => bool)) public fragmentVotedDSEs; // Fragment ID -> DSE ID -> Voted
    mapping(uint256 => mapping(uint256 => bool)) public proposalVotedDSEs; // Proposal ID -> DSE ID -> Voted
    mapping(uint256 => mapping(uint256 => uint256)) public fragmentSubmissionRewards; // Fragment ID -> DSE ID (submitter) -> Claimable Rewards

    // The on-chain "Knowledge Base" of accepted facts
    mapping(uint256 => bytes32) public knowledgeBase; // Accepted Fragment ID -> dataHash

    // Contract addresses
    IEnergyToken public ENERGY_TOKEN;

    // Configurable parameters (initially by owner, then by governance)
    uint256 public baseMintCost = 1000 * (10 ** 18);          // Default DSE mint cost in EnergyToken
    uint256 public minCognitiveScoreToSubmitFragment = 100; // Min score for DSE to submit fragments
    uint256 public minCognitiveScoreToPropose = 1000;       // Min score for DSE to create proposals
    uint256 public fragmentValidationPeriod = 3 days;       // Time for fragment voting
    uint256 public proposalVotingPeriod = 7 days;           // Time for proposal voting
    uint256 public cognitiveScoreBoost = 10;                // Base boost for positive action
    uint256 public cognitiveScoreSlash = 5;                 // Base slash for negative action
    uint256 public fragmentSubmitterRewardAmount = 200 * (10 ** 18); // Reward for accepted fragment submission
    uint256 public proposalProposerRewardAmount = 500 * (10 ** 18);  // Reward for accepted proposal submission
    uint256 public DSE_ACTION_ENERGY_COST = 10 * (10 ** 18);  // Energy cost for submitting/voting

    // --- Events ---
    event DSEMinted(uint256 indexed dseId, address indexed owner, string initialMetadataURI);
    event EnergyDeposited(uint256 indexed dseId, address indexed depositor, uint256 amount);
    event EnergyWithdrawn(uint256 indexed dseId, address indexed receiver, uint256 amount);
    event CognitiveScoreAdjusted(uint256 indexed dseId, int256 adjustment, uint256 newScore);
    event KnowledgeFragmentSubmitted(uint256 indexed fragmentId, uint256 indexed submitterDSEId, bytes32 dataHash);
    event KnowledgeFragmentVoted(uint256 indexed fragmentId, uint256 indexed dseId, bool support, uint256 cognitiveWeight);
    event KnowledgeFragmentResolved(uint256 indexed fragmentId, FragmentStatus status);
    event KnowledgeBaseEntryAdded(uint256 indexed fragmentId, bytes32 dataHash);
    event GovernanceProposalCreated(uint256 indexed proposalId, uint256 indexed proposerDSEId, bytes32 descriptionHash, address targetContract, bytes calldataPayload);
    event GovernanceProposalVoted(uint256 indexed proposalId, uint256 indexed dseId, bool support, uint256 cognitiveWeight);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool success);
    event RewardsClaimed(uint256 indexed dseId, uint256 indexed itemId, uint256 amount);

    // --- Constructor ---
    constructor(address _energyTokenAddress) ERC721Enumerable("Digital Sentient Entity", "DSE") Ownable(msg.sender) {
        require(_energyTokenAddress != address(0), "EnergyToken address cannot be zero");
        ENERGY_TOKEN = IEnergyToken(_energyTokenAddress);
    }

    // --- Modifiers ---
    modifier onlyDSEOwner(uint256 _dseId) {
        require(_exists(_dseId), "DSE does not exist");
        require(ownerOf(_dseId) == _msgSender(), "Only DSE owner can call this function");
        _;
    }

    modifier onlyValidDSE(uint256 _dseId) {
        require(_exists(_dseId), "DSE does not exist");
        require(dseData[_dseId].exists, "DSE data not initialized"); // Redundant check but good for safety
        _;
    }

    modifier hasSufficientEnergy(uint256 _dseId, uint256 _amount) {
        require(dseData[_dseId].energyReserve >= _amount, "DSE has insufficient energy");
        _;
    }

    // --- I. DSE Creation & Attributes ---

    /**
     * @dev Mints a new DSE NFT with an initial metadata URI.
     *      Requires the caller to approve `baseMintCost` in EnergyToken to this contract.
     *      The initial Cognitive Score is set to 1.
     * @param _initialMetadataURI The URI pointing to the DSE's initial metadata.
     * @return The ID of the newly minted DSE.
     */
    function mintDSE(string memory _initialMetadataURI) public returns (uint256) {
        require(ENERGY_TOKEN.transferFrom(_msgSender(), address(this), baseMintCost), "EnergyToken transfer failed for minting");

        _dseCounter = _dseCounter.add(1);
        uint256 newDSEId = _dseCounter;

        _safeMint(_msgSender(), newDSEId);
        dseData[newDSEId] = DSE({
            cognitiveScore: 1, // Start with a base score
            energyReserve: 0,
            metadataURI: _initialMetadataURI,
            level: 1,
            lastActionTimestamp: block.timestamp,
            exists: true
        });

        emit DSEMinted(newDSEId, _msgSender(), _initialMetadataURI);
        return newDSEId;
    }

    /**
     * @dev Retrieves a DSE's core on-chain data.
     * @param _dseId The ID of the DSE.
     * @return The DSE struct.
     */
    function getDSE(uint256 _dseId) public view onlyValidDSE(_dseId) returns (DSE memory) {
        return dseData[_dseId];
    }

    /**
     * @dev Returns the owner address of a DSE. Overrides ERC721Enumerable's ownerOf for explicit mention.
     * @param _dseId The ID of the DSE.
     * @return The owner's address.
     */
    function getDSEOwner(uint256 _dseId) public view override returns (address) {
        return ownerOf(_dseId);
    }

    /**
     * @dev Allows a DSE owner to update their DSE's base metadata URI.
     *      Note: Dynamic attributes like cognitiveScore and level are updated internally,
     *      and an off-chain keeper service would typically re-generate the metadata
     *      JSON and point to the new content hash via this function.
     * @param _dseId The ID of the DSE.
     * @param _newURI The new URI for the DSE's metadata.
     */
    function updateDSEMetadataURI(uint256 _dseId, string memory _newURI) public onlyDSEOwner(_dseId) {
        dseData[_dseId].metadataURI = _newURI;
    }

    /**
     * @dev Provides a comprehensive view of a DSE's dynamic attributes.
     * @param _dseId The ID of the DSE.
     * @return cognitiveScore, energyReserve, metadataURI, level, lastActionTimestamp.
     */
    function getDSENFTAttributes(uint256 _dseId)
        public
        view
        onlyValidDSE(_dseId)
        returns (uint256 cognitiveScore, uint256 energyReserve, string memory metadataURI, uint256 level, uint256 lastActionTimestamp)
    {
        DSE storage dse = dseData[_dseId];
        return (dse.cognitiveScore, dse.energyReserve, dse.metadataURI, dse.level, dse.lastActionTimestamp);
    }

    /**
     * @dev Transfers DSE ownership. This directly uses ERC721's transferFrom.
     * @param _from The current owner.
     * @param _to The new owner.
     * @param _dseId The ID of the DSE to transfer.
     */
    function transferDSE(address _from, address _to, uint256 _dseId) public {
        _transfer(_from, _to, _dseId);
    }

    /**
     * @dev Calculates a DSE's level based on its Cognitive Score.
     *      Uses a logarithmic scale for progression: `floor(log2(cognitiveScore + 1)) + 1`.
     * @param _dseId The ID of the DSE.
     * @return The calculated level.
     */
    function getDSELevel(uint256 _dseId) public view onlyValidDSE(_dseId) returns (uint256) {
        uint256 score = dseData[_dseId].cognitiveScore;
        if (score == 0) return 0; // Avoid log(0) and ensure score 1 is level 1
        
        uint256 level = 0;
        uint256 tempScore = score;
        while (tempScore > 1) { // Calculate floor(log2(score))
            tempScore /= 2;
            level = level.add(1);
        }
        return level.add(1); // Min level 1
    }

    // --- II. Energy Token Management ---

    /**
     * @dev Sets the address of the ERC20 EnergyToken contract.
     *      Only callable by the contract owner (initially admin, later governance).
     * @param _newAddress The address of the new EnergyToken contract.
     */
    function setEnergyTokenAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "New EnergyToken address cannot be zero");
        ENERGY_TOKEN = IEnergyToken(_newAddress);
    }

    /**
     * @dev Stakes EnergyToken into a DSE's energy reserve.
     *      Requires the caller to approve `_amount` in EnergyToken to this contract.
     * @param _dseId The ID of the DSE to deposit energy into.
     * @param _amount The amount of EnergyToken to deposit.
     */
    function depositEnergyToDSE(uint256 _dseId, uint256 _amount) public onlyDSEOwner(_dseId) {
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(ENERGY_TOKEN.transferFrom(_msgSender(), address(this), _amount), "EnergyToken transfer failed for deposit");
        dseData[_dseId].energyReserve = dseData[_dseId].energyReserve.add(_amount);
        emit EnergyDeposited(_dseId, _msgSender(), _amount);
    }

    /**
     * @dev Allows withdrawal of EnergyToken from a DSE's reserve by its owner.
     * @param _dseId The ID of the DSE to withdraw energy from.
     * @param _amount The amount of EnergyToken to withdraw.
     */
    function withdrawEnergyFromDSE(uint256 _dseId, uint256 _amount) public onlyDSEOwner(_dseId) hasSufficientEnergy(_dseId, _amount) {
        require(_amount > 0, "Withdraw amount must be greater than zero");
        dseData[_dseId].energyReserve = dseData[_dseId].energyReserve.sub(_amount);
        require(ENERGY_TOKEN.transfer(ownerOf(_dseId), _amount), "EnergyToken transfer failed for withdrawal");
        emit EnergyWithdrawn(_dseId, ownerOf(_dseId), _amount);
    }

    /**
     * @dev Returns the current EnergyToken balance of a DSE.
     * @param _dseId The ID of the DSE.
     * @return The energy reserve amount.
     */
    function getDSEEnergyReserve(uint256 _dseId) public view onlyValidDSE(_dseId) returns (uint256) {
        return dseData[_dseId].energyReserve;
    }

    // --- III. Knowledge Fragment Operations ---

    /**
     * @dev Submits a new "Knowledge Fragment" for community validation.
     *      Requires the submitting DSE to have sufficient energy and a minimum cognitive score.
     * @param _dseId The ID of the DSE submitting the fragment.
     * @param _dataHash An immutable hash (e.g., IPFS CID) pointing to the fragment's data.
     * @return The ID of the new knowledge fragment.
     */
    function submitKnowledgeFragment(uint256 _dseId, bytes32 _dataHash) public onlyDSEOwner(_dseId) hasSufficientEnergy(_dseId, DSE_ACTION_ENERGY_COST) returns (uint256) {
        require(dseData[_dseId].cognitiveScore >= minCognitiveScoreToSubmitFragment, "DSE cognitive score too low to submit fragment");

        _fragmentCounter = _fragmentCounter.add(1); // Use dedicated fragment counter
        uint256 newFragmentId = _fragmentCounter;

        dseData[_dseId].energyReserve = dseData[_dseId].energyReserve.sub(DSE_ACTION_ENERGY_COST);
        dseData[_dseId].lastActionTimestamp = block.timestamp;

        knowledgeFragments[newFragmentId] = KnowledgeFragment({
            submitterDSEId: _dseId,
            dataHash: _dataHash,
            submissionTime: block.timestamp,
            totalCognitiveWeightFor: 0,
            totalCognitiveWeightAgainst: 0,
            status: FragmentStatus.Pending,
            isResolved: false
        });

        emit KnowledgeFragmentSubmitted(newFragmentId, _dseId, _dataHash);
        return newFragmentId;
    }

    /**
     * @dev Casts a vote (for/against) on a knowledge fragment.
     *      Requires the voting DSE to have sufficient energy and not have voted before.
     *      The weight of the vote is determined by the DSE's Cognitive Score.
     * @param _fragmentId The ID of the fragment to vote on.
     * @param _dseId The ID of the DSE casting the vote.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnKnowledgeFragment(uint256 _fragmentId, uint256 _dseId, bool _support) public onlyDSEOwner(_dseId) hasSufficientEnergy(_dseId, DSE_ACTION_ENERGY_COST) {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        require(fragment.status == FragmentStatus.Pending, "Fragment is not in pending state");
        require(block.timestamp <= fragment.submissionTime.add(fragmentValidationPeriod), "Fragment voting period has ended");
        require(!fragmentVotedDSEs[_fragmentId][_dseId], "DSE has already voted on this fragment");

        dseData[_dseId].energyReserve = dseData[_dseId].energyReserve.sub(DSE_ACTION_ENERGY_COST);
        dseData[_dseId].lastActionTimestamp = block.timestamp;

        uint256 cognitiveWeight = dseData[_dseId].cognitiveScore;
        if (_support) {
            fragment.totalCognitiveWeightFor = fragment.totalCognitiveWeightFor.add(cognitiveWeight);
        } else {
            fragment.totalCognitiveWeightAgainst = fragment.totalCognitiveWeightAgainst.add(cognitiveWeight);
        }
        fragmentVotedDSEs[_fragmentId][_dseId] = true;

        emit KnowledgeFragmentVoted(_fragmentId, _dseId, _support, cognitiveWeight);
    }

    /**
     * @dev Initiates the resolution process for a fragment.
     *      Can be called by any DSE after the validation period.
     *      If accepted, adds to Knowledge Base, rewards submitter, and boosts their Cognitive Score.
     *      If rejected, slashes submitter's Cognitive Score.
     * @param _fragmentId The ID of the fragment to resolve.
     */
    function resolveKnowledgeFragment(uint256 _fragmentId) public {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        require(fragment.status == FragmentStatus.Pending, "Fragment is not in pending state");
        require(block.timestamp > fragment.submissionTime.add(fragmentValidationPeriod), "Fragment voting period is not over");
        require(!fragment.isResolved, "Fragment already resolved");

        fragment.isResolved = true;
        
        if (fragment.totalCognitiveWeightFor > fragment.totalCognitiveWeightAgainst) {
            fragment.status = FragmentStatus.Accepted;
            knowledgeBase[_fragmentId] = fragment.dataHash;
            emit KnowledgeBaseEntryAdded(_fragmentId, fragment.dataHash);

            // Mark submitter for reward
            fragmentSubmissionRewards[_fragmentId][fragment.submitterDSEId] = fragmentSubmitterRewardAmount;
            _adjustCognitiveScore(fragment.submitterDSEId, int256(cognitiveScoreBoost)); // Boost submitter's score
        } else {
            fragment.status = FragmentStatus.Rejected;
            _adjustCognitiveScore(fragment.submitterDSEId, -int256(cognitiveScoreSlash)); // Slash submitter's score
        }

        emit KnowledgeFragmentResolved(_fragmentId, fragment.status);
    }

    /**
     * @dev Retrieves detailed information about a knowledge fragment.
     * @param _fragmentId The ID of the knowledge fragment.
     * @return The KnowledgeFragment struct.
     */
    function getKnowledgeFragment(uint256 _fragmentId) public view returns (KnowledgeFragment memory) {
        require(_fragmentId <= _fragmentCounter, "Fragment does not exist");
        return knowledgeFragments[_fragmentId];
    }

    /**
     * @dev Returns the dataHash of an accepted fragment from the Knowledge Base.
     * @param _fragmentId The ID of the accepted fragment.
     * @return The dataHash if accepted, or empty bytes32 if not found/rejected.
     */
    function getKnowledgeBaseEntry(uint256 _fragmentId) public view returns (bytes32) {
        return knowledgeBase[_fragmentId];
    }
    
    /**
     * @dev Allows a DSE (submitter) to claim earned rewards for an accepted fragment.
     * @param _dseId The ID of the DSE (submitter) claiming the reward.
     * @param _fragmentId The ID of the fragment for which to claim rewards.
     */
    function claimFragmentSubmissionReward(uint256 _dseId, uint256 _fragmentId) public onlyDSEOwner(_dseId) {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        require(fragment.isResolved, "Fragment not yet resolved.");
        require(fragment.status == FragmentStatus.Accepted, "Fragment was not accepted, no rewards.");
        require(fragment.submitterDSEId == _dseId, "Only the submitter DSE can claim this reward.");

        uint256 claimableAmount = fragmentSubmissionRewards[_fragmentId][_dseId];
        require(claimableAmount > 0, "No claimable rewards for this DSE on this fragment.");

        fragmentSubmissionRewards[_fragmentId][_dseId] = 0; // Reset claimable amount
        ENERGY_TOKEN.mint(ownerOf(_dseId), claimableAmount); // Mint and transfer rewards to DSE owner
        emit RewardsClaimed(_dseId, _fragmentId, claimableAmount);
    }


    // --- IV. Adaptive Consensus / Governance ---

    /**
     * @dev DSE submits a proposal for network changes or arbitrary execution.
     *      Requires DSE to have high cognitive score and sufficient energy.
     * @param _dseId The ID of the DSE proposing.
     * @param _descriptionHash IPFS hash for full proposal details.
     * @param _targetContract The address of the contract to call for execution.
     * @param _calldataPayload The calldata to be sent to the targetContract.
     * @return The ID of the new proposal.
     */
    function createGovernanceProposal(
        uint256 _dseId,
        bytes32 _descriptionHash,
        address _targetContract,
        bytes memory _calldataPayload
    ) public onlyDSEOwner(_dseId) hasSufficientEnergy(_dseId, DSE_ACTION_ENERGY_COST) returns (uint256) {
        require(dseData[_dseId].cognitiveScore >= minCognitiveScoreToPropose, "DSE cognitive score too low to create proposal");

        dseData[_dseId].energyReserve = dseData[_dseId].energyReserve.sub(DSE_ACTION_ENERGY_COST);
        dseData[_dseId].lastActionTimestamp = block.timestamp;

        _proposalCounter = _proposalCounter.add(1);
        uint256 newProposalId = _proposalCounter;

        proposals[newProposalId] = Proposal({
            proposerDSEId: _dseId,
            descriptionHash: _descriptionHash,
            targetContract: _targetContract,
            calldataPayload: _calldataPayload,
            submissionTime: block.timestamp,
            totalCognitiveWeightFor: 0,
            totalCognitiveWeightAgainst: 0,
            status: ProposalStatus.Pending,
            isExecuted: false
        });

        emit GovernanceProposalCreated(newProposalId, _dseId, _descriptionHash, _targetContract, _calldataPayload);
        return newProposalId;
    }

    /**
     * @dev DSE votes on a governance proposal.
     *      Consumes energy, and cognitive score determines vote weight.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _dseId The ID of the DSE casting the vote.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, uint256 _dseId, bool _support) public onlyDSEOwner(_dseId) hasSufficientEnergy(_dseId, DSE_ACTION_ENERGY_COST) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in pending state");
        require(block.timestamp <= proposal.submissionTime.add(proposalVotingPeriod), "Proposal voting period has ended");
        require(!proposalVotedDSEs[_proposalId][_dseId], "DSE has already voted on this proposal");

        dseData[_dseId].energyReserve = dseData[_dseId].energyReserve.sub(DSE_ACTION_ENERGY_COST);
        dseData[_dseId].lastActionTimestamp = block.timestamp;

        uint256 cognitiveWeight = dseData[_dseId].cognitiveScore;
        if (_support) {
            proposal.totalCognitiveWeightFor = proposal.totalCognitiveWeightFor.add(cognitiveWeight);
        } else {
            proposal.totalCognitiveWeightAgainst = proposal.totalCognitiveWeightAgainst.add(cognitiveWeight);
        }
        proposalVotedDSEs[_proposalId][_dseId] = true;

        emit GovernanceProposalVoted(_proposalId, _dseId, _support, cognitiveWeight);
    }

    /**
     * @dev Executes an accepted governance proposal.
     *      Can be called by any DSE after the voting period, if the proposal passed.
     *      If accepted, executes the `calldataPayload` on the `targetContract`,
     *      rewards the proposer, and boosts their Cognitive Score.
     *      If rejected, slashes the proposer's Cognitive Score.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal is not in pending state");
        require(block.timestamp > proposal.submissionTime.add(proposalVotingPeriod), "Proposal voting period is not over");
        require(!proposal.isExecuted, "Proposal already executed");

        proposal.isExecuted = true;
        bool executionSuccess = false;

        if (proposal.totalCognitiveWeightFor > proposal.totalCognitiveWeightAgainst) {
            proposal.status = ProposalStatus.Accepted;
            // Execute the proposal's calldata on the target contract
            (executionSuccess, ) = proposal.targetContract.call(proposal.calldataPayload);
            if (executionSuccess) {
                proposal.status = ProposalStatus.Executed;
                // Reward proposer and boost score
                ENERGY_TOKEN.mint(ownerOf(proposal.proposerDSEId), proposalProposerRewardAmount);
                _adjustCognitiveScore(proposal.proposerDSEId, int256(cognitiveScoreBoost));
            } else {
                // If execution fails, proposal is still 'Accepted' but not 'Executed'.
                // Could implement a retry or specific failure handling here.
                // For simplicity, we just won't change status to Executed and won't reward.
                // Or we could have a 'Failed' status. Sticking to 'Accepted' for now if execution didn't go through.
            }
        } else {
            proposal.status = ProposalStatus.Rejected;
            _adjustCognitiveScore(proposal.proposerDSEId, -int256(cognitiveScoreSlash));
        }
        emit GovernanceProposalExecuted(_proposalId, executionSuccess);
    }

    /**
     * @dev Retrieves details of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The Proposal struct.
     */
    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        require(_proposalId <= _proposalCounter, "Proposal does not exist");
        return proposals[_proposalId];
    }

    // --- V. Cognitive Score & Rewards Mechanics ---

    /**
     * @dev Internal function to adjust a DSE's Cognitive Score.
     *      Used for boosting or slashing based on actions.
     * @param _dseId The ID of the DSE to adjust.
     * @param _adjustment The amount to add or subtract (can be negative).
     */
    function _adjustCognitiveScore(uint256 _dseId, int256 _adjustment) internal onlyValidDSE(_dseId) {
        DSE storage dse = dseData[_dseId];
        
        if (_adjustment > 0) {
            dse.cognitiveScore = dse.cognitiveScore.add(uint256(_adjustment));
        } else if (_adjustment < 0) {
            uint256 absAdjustment = uint256(-_adjustment);
            if (dse.cognitiveScore > absAdjustment) {
                dse.cognitiveScore = dse.cognitiveScore.sub(absAdjustment);
            } else {
                dse.cognitiveScore = 0; // Score cannot go below zero
            }
        }
        emit CognitiveScoreAdjusted(_dseId, _adjustment, dse.cognitiveScore);
        // Update DSE's level after score adjustment
        dse.level = getDSELevel(_dseId);
    }
    
    // --- VI. Administrative/Maintenance (DAO controlled) ---
    // These functions are initially `onlyOwner` but would be proposed and executed
    // via the governance system once the contract matures, demonstrating self-governance.

    /**
     * @dev Admin/governance function to update the DSE minting cost.
     * @param _newCost The new cost in EnergyToken.
     */
    function setBaseMintCost(uint256 _newCost) public onlyOwner {
        baseMintCost = _newCost;
    }

    /**
     * @dev Admin/governance function to set minimum Cognitive Score for fragment submission.
     * @param _newThreshold The new minimum cognitive score.
     */
    function setValidationThreshold(uint256 _newThreshold) public onlyOwner {
        minCognitiveScoreToSubmitFragment = _newThreshold;
    }

    /**
     * @dev Admin/governance function to set the duration for fragment voting.
     * @param _newPeriod The new period in seconds.
     */
    function setFragmentValidationPeriod(uint256 _newPeriod) public onlyOwner {
        fragmentValidationPeriod = _newPeriod;
    }

    /**
     * @dev Admin/governance function to set the duration for proposal voting.
     * @param _newPeriod The new period in seconds.
     */
    function setProposalVotingPeriod(uint256 _newPeriod) public onlyOwner {
        proposalVotingPeriod = _newPeriod;
    }

    /**
     * @dev Admin/governance function to configure score adjustment values for boosts and slashes.
     * @param _boost The amount to boost cognitive score for positive actions.
     * @param _slash The amount to slash cognitive score for negative actions.
     */
    function setCognitiveScoreAdjustments(uint256 _boost, uint256 _slash) public onlyOwner {
        cognitiveScoreBoost = _boost;
        cognitiveScoreSlash = _slash;
    }

    /**
     * @dev Returns the token URI for a given DSE, pointing to its metadata.
     * @param _dseId The ID of the DSE.
     * @return The metadata URI.
     */
    function tokenURI(uint256 _dseId) public view override returns (string memory) {
        require(_exists(_dseId), "ERC721Metadata: URI query for nonexistent token");
        return dseData[_dseId].metadataURI;
    }
}
```