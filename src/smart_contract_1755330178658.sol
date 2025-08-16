Here is a Solidity smart contract named "AetherialForge," designed to showcase several advanced, creative, and trendy concepts. It focuses on decentralized AI-assisted content/data curation and reputation management using dynamic NFTs and adaptive economics.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is generally not needed in 0.8+ due to default checks, but kept for clarity.
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string for URI generation

// --- Mock AETH Token for Demonstration Purposes ---
// In a real-world scenario, this would be a separate, deployed ERC20 token.
contract MockAETH is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string public name = "Aetherial Token";
    string public symbol = "AETH";
    uint8 public decimals = 18;

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

/**
 * @title AetherialForge - Decentralized AI-Assisted Content Curation & Reputation Protocol
 * @dev AetherialForge is a decentralized protocol designed to facilitate verifiable data submissions,
 *      expert evaluations, and dynamic reputation management. It enables users to submit "Proposals"
 *      (e.g., AI model outputs, research claims, market predictions), which are then evaluated by
 *      a curated network of "Oracles." The protocol features a dynamic reputation system represented
 *      by evolving NFTs (dNFTs) for both contributors and oracles, alongside an adaptive economic model
 *      that adjusts fees and rewards based on system accuracy and participation. It aims to foster a
 *      reliable decentralized knowledge and data validation ecosystem.
 *
 * Key Advanced Concepts Employed:
 * - Dynamic NFTs (dNFTs): Reputation and influence are embodied in NFTs whose traits and metadata URIs
 *   evolve based on on-chain actions (successful proposals, accurate evaluations). The metadata URI
 *   can be updated to reflect changes in reputation score, prompting off-chain services to update NFT art.
 * - Adaptive Economics: Protocol fees for submissions and rewards for Oracles are dynamically adjusted
 *   (conceptually, using placeholder logic for this demo) based on network activity, proposal success
 *   rates, and overall system accuracy, encouraging healthy participation and penalizing poor performance.
 * - Internal Oracle Network with Reputation-Weighted Selection: A decentralized set of Oracles are
 *   selected for evaluations based on their staked tokens and their accumulated reputation score.
 *   (Simplified selection for demo, real implementation needs VRF).
 * - Verifiable Claims & Truth Discovery: While the underlying data/AI model is off-chain, the system
 *   provides a framework for submitting claims, having them evaluated by a decentralized network,
 *   and reaching consensus on their validity. The "truth" can be provided via a trusted source
 *   or an external oracle (e.g., Chainlink feeds for real-world outcomes).
 * - Gamified Dispute Resolution: A mechanism for challenging outcomes, involving a community-driven
 *   voting process (simplified for this contract demo) with economic incentives for accurate judgment.
 */
contract AetherialForge is Ownable, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---
    IERC20 public immutable AETH_TOKEN; // The ERC20 token used for staking and rewards

    uint256 public epochDuration; // Duration of each operational epoch in seconds
    uint256 public currentEpoch; // Current epoch number
    uint256 public lastEpochUpdateTime; // Timestamp of the last epoch update

    address public protocolFeeRecipient; // Address to receive collected protocol fees
    uint256 public baseProposalFee; // Base fee for submitting a proposal (in AETH)
    uint256 public baseOracleFee; // Base fee for an oracle to register (in AETH)
    uint256 public minOracleStake; // Minimum AETH required to be staked by an oracle

    // Adaptive fee parameters: Higher weights mean more impact from success/accuracy
    struct AdaptiveFeeParams {
        uint256 successWeight;  // Weight for proposal success rate in fee calculation
        uint256 accuracyWeight; // Weight for oracle accuracy in reward calculation
        uint256 baseFactor;     // Base multiplier for dynamic adjustments (e.g., 10000 for 1.0)
    }
    AdaptiveFeeParams public adaptiveFeeParams;

    // --- Reputable Entities (Oracles & Contributors) ---
    struct OracleInfo {
        uint256 stake;
        uint256 reputationScore; // Higher score = more influence, better selection chances
        uint256 lastActivityEpoch;
        uint256 nftTokenId; // Token ID of their associated Oracle NFT
        uint256 rewardsDue; // Accumulated AETH rewards
        bool exists; // To check if an address is a registered oracle
    }
    mapping(address => OracleInfo) public oracles;
    address[] public activeOracles; // Dynamic list of currently eligible oracles

    struct ContributorInfo {
        uint256 reputationScore; // Higher score = more influence, better proposal acceptance
        uint256 nftTokenId; // Token ID of their associated Contributor NFT
        uint256 rewardsDue; // Accumulated AETH rewards
        bool exists;
    }
    mapping(address => ContributorInfo) public contributors;

    // --- Proposals ---
    enum ProposalStatus { PENDING_EVALUATION, EVALUATED, FINALIZED, DISPUTED }

    struct Proposal {
        address submitter;
        bytes32 proposalHash; // Hash of the content/claim (e.g., IPFS hash, verifiable AI output)
        string metadataURI;   // URI for initial metadata of the proposal
        uint256 submissionTime;
        ProposalStatus status;
        uint256 totalAETHStaked; // Total AETH collected for this proposal (fee + potential challenge bonds)
        uint256 rewardsPool; // Portion of AETH allocated for rewards for accurate oracles/submitter
        address[] selectedOracles; // Oracles selected to evaluate this proposal
        mapping(address => bytes32) judgments; // Oracle address => their judgment hash
        uint256 judgmentsCount;
        bytes32 finalOutcomeHash; // The agreed-upon "truth" hash for the proposal
        bool outcomeTruthSet;

        // Dispute specific fields
        address challenger;
        uint256 challengeBond; // ETH value for the bond
        bool isChallenged;
        bool challengeResolved;
        mapping(address => bool) disputeVotesCast; // Oracle/voter => true if voted
        uint256 votesForChallenger;
        uint256 votesAgainstChallenger;
    }
    mapping(bytes32 => Proposal) public proposals;

    // --- Counters for NFTs ---
    Counters.Counter private _oracleTokenIds;
    Counters.Counter private _contributorTokenIds;

    // --- Accumulated Protocol Funds ---
    uint256 public accruedProtocolFees;
    uint256 public totalAccruedOracleRewards; // Sum of all rewards waiting to be claimed by oracles

    // --- Events ---
    event EpochAdvanced(uint256 newEpoch);
    event OracleRegistered(address indexed oracleAddress, uint256 indexed tokenId);
    event OracleStakeUpdated(address indexed oracleAddress, uint256 newStake);
    event OracleDeregistered(address indexed oracleAddress);
    event ProposalSubmitted(bytes32 indexed proposalHash, address indexed submitter, uint256 feePaid);
    event OracleJudgmentSubmitted(bytes32 indexed proposalHash, address indexed oracleAddress, bytes32 judgmentHash);
    event ProposalFinalized(bytes32 indexed proposalHash, bytes32 finalOutcomeHash, uint256 rewardsDistributed);
    event NFTReputationUpdated(uint256 indexed tokenId, uint256 newReputationScore, string newMetadataURI);
    event RewardsClaimed(address indexed claimant, uint256 amount);
    event ProposalChallenged(bytes32 indexed proposalHash, address indexed challenger, uint256 bondAmount);
    event DisputeVote(bytes32 indexed proposalHash, address indexed voter, bool voteForChallenger);
    event DisputeResolved(bytes32 indexed proposalHash, bool challengerWon);

    /**
     * @dev Constructor for AetherialForge.
     * @param _aethTokenAddress Address of the AETH ERC20 token.
     * @param _epochDuration Duration of each epoch in seconds.
     * @param _protocolFeeRecipient Initial recipient for protocol fees.
     * @param _minOracleStake Minimum AETH stake required for an oracle.
     * @param _baseProposalFee Initial base fee for proposal submission.
     * @param _baseOracleFee Initial base fee for oracle registration.
     */
    constructor(
        address _aethTokenAddress,
        uint256 _epochDuration,
        address _protocolFeeRecipient,
        uint256 _minOracleStake,
        uint256 _baseProposalFee,
        uint256 _baseOracleFee
    ) ERC721("AetherialForge dNFT", "AFDNFT") Ownable(msg.sender) {
        require(_aethTokenAddress != address(0), "Invalid AETH token address");
        require(_epochDuration > 0, "Epoch duration must be positive");
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient");
        require(_minOracleStake > 0, "Min oracle stake must be positive");

        AETH_TOKEN = IERC20(_aethTokenAddress);
        epochDuration = _epochDuration;
        protocolFeeRecipient = _protocolFeeRecipient;
        minOracleStake = _minOracleStake;
        baseProposalFee = _baseProposalFee;
        baseOracleFee = _baseOracleFee;

        lastEpochUpdateTime = block.timestamp;
        currentEpoch = 1;

        // Initialize adaptive fee parameters (e.g., 100 for 1%, 10000 for 100%)
        adaptiveFeeParams = AdaptiveFeeParams({
            successWeight: 100,  // Example: 1% impact per 1% change in success rate
            accuracyWeight: 100, // Example: 1% impact per 1% change in accuracy
            baseFactor: 10000    // Multiplier to handle decimals (e.g., 10000 for 1.0)
        });
    }

    // --- I. Core Protocol Management (Owner/Admin Controlled) ---

    /**
     * @dev Updates the duration of each operational epoch.
     * @param _newDuration New duration in seconds.
     */
    function updateEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "Epoch duration must be positive");
        epochDuration = _newDuration;
    }

    /**
     * @dev Pauses the contract in case of emergencies, preventing most operations.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming normal operations.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Designates the address to receive collected protocol fees.
     * @param _recipient The new address for protocol fees.
     */
    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        protocolFeeRecipient = _recipient;
    }

    /**
     * @dev Allows the fee recipient to withdraw collected protocol fees.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(uint256 _amount) external {
        require(msg.sender == protocolFeeRecipient || msg.sender == owner(), "Only fee recipient or owner can withdraw");
        require(_amount > 0, "Amount must be positive");
        require(accruedProtocolFees >= _amount, "Insufficient accrued fees");

        accruedProtocolFees = accruedProtocolFees.sub(_amount);
        require(AETH_TOKEN.transfer(protocolFeeRecipient, _amount), "AETH transfer failed for fee withdrawal");
    }

    /**
     * @dev Adjusts the base fees for proposal submission and oracle registration.
     * @param _newBaseProposalFee New base fee for proposals.
     * @param _newBaseOracleFee New base fee for oracles.
     */
    function setBaseProtocolFees(uint256 _newBaseProposalFee, uint256 _newBaseOracleFee) external onlyOwner {
        baseProposalFee = _newBaseProposalFee;
        baseOracleFee = _newBaseOracleFee;
    }

    /**
     * @dev Configures parameters for the dynamic fee and reward adjustment mechanism.
     * @param _successWeight Weight for proposal success rate.
     * @param _accuracyWeight Weight for oracle accuracy.
     * @param _baseFactor Base multiplier for calculations (e.g., 10000 for 1.0 to handle 4 decimals).
     */
    function setAdaptiveFeeParams(uint256 _successWeight, uint256 _accuracyWeight, uint256 _baseFactor) external onlyOwner {
        adaptiveFeeParams = AdaptiveFeeParams({
            successWeight: _successWeight,
            accuracyWeight: _accuracyWeight,
            baseFactor: _baseFactor
        });
    }

    // --- II. Oracle Network Management ---

    /**
     * @dev Registers an address as an Oracle by staking a minimum amount of tokens
     *      and providing an initial metadata URI for their Oracle NFT.
     *      AETH tokens must be approved to this contract beforehand.
     * @param _metadataURI The initial URI for the Oracle's dNFT metadata.
     */
    function registerOracle(string calldata _metadataURI) external whenNotPaused {
        require(!oracles[msg.sender].exists, "Caller is already a registered oracle");
        require(AETH_TOKEN.transferFrom(msg.sender, address(this), minOracleStake), "AETH transfer failed for stake");

        _oracleTokenIds.increment();
        uint256 tokenId = _oracleTokenIds.current();

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _metadataURI);

        oracles[msg.sender] = OracleInfo({
            stake: minOracleStake,
            reputationScore: 1000, // Starting reputation score
            lastActivityEpoch: currentEpoch,
            nftTokenId: tokenId,
            rewardsDue: 0,
            exists: true
        });
        activeOracles.push(msg.sender); // Add to active oracle list

        emit OracleRegistered(msg.sender, tokenId);
    }

    /**
     * @dev Allows a registered Oracle to increase or decrease their staked amount.
     *      If decreasing, funds are transferred back to the oracle.
     *      If increasing, AETH tokens must be approved to this contract beforehand.
     * @param _newStakeAmount The new total stake amount for the oracle.
     */
    function updateOracleStake(uint256 _newStakeAmount) external whenNotPaused {
        require(oracles[msg.sender].exists, "Caller is not a registered oracle");
        require(_newStakeAmount >= minOracleStake, "New stake must meet minimum requirement");

        uint256 currentStake = oracles[msg.sender].stake;

        if (_newStakeAmount > currentStake) {
            uint256 additionalStake = _newStakeAmount.sub(currentStake);
            require(AETH_TOKEN.transferFrom(msg.sender, address(this), additionalStake), "AETH transfer failed for additional stake");
        } else if (_newStakeAmount < currentStake) {
            uint256 reducedStake = currentStake.sub(_newStakeAmount);
            require(AETH_TOKEN.transfer(msg.sender, reducedStake), "AETH transfer failed for stake reduction");
        } else {
            // No change in stake, do nothing
            return;
        }

        oracles[msg.sender].stake = _newStakeAmount;
        emit OracleStakeUpdated(msg.sender, _newStakeAmount);
    }

    /**
     * @dev Allows an Oracle to withdraw their stake and deregister.
     *      A cooldown period or penalty could be added here for production.
     */
    function deregisterOracle() external whenNotPaused {
        require(oracles[msg.sender].exists, "Caller is not a registered oracle");
        require(oracles[msg.sender].rewardsDue == 0, "Cannot deregister with pending rewards");

        uint256 oracleStake = oracles[msg.sender].stake;
        uint256 oracleNFTId = oracles[msg.sender].nftTokenId;
        
        delete oracles[msg.sender]; // Remove oracle from mapping

        // Remove from activeOracles array (inefficient for very large arrays, consider linked list or remapping)
        for (uint224 i = 0; i < activeOracles.length; i++) {
            if (activeOracles[i] == msg.sender) {
                activeOracles[i] = activeOracles[activeOracles.length - 1];
                activeOracles.pop();
                break;
            }
        }
        
        _burn(oracleNFTId); // Burn the Oracle NFT

        require(AETH_TOKEN.transfer(msg.sender, oracleStake), "AETH transfer failed for stake withdrawal");
        emit OracleDeregistered(msg.sender);
    }

    /**
     * @dev Retrieves detailed information about a registered Oracle.
     * @param _oracleAddress The address of the oracle.
     * @return OracleInfo struct.
     */
    function getOracleInfo(address _oracleAddress) external view returns (OracleInfo memory) {
        require(oracles[_oracleAddress].exists, "Oracle not found");
        return oracles[_oracleAddress];
    }

    /**
     * @dev Selects a dynamic subset of oracles for a given proposal based on stake and reputation.
     *      This is a simplified selection for demonstration. A more advanced, decentralized system
     *      would likely involve a verifiable random function (VRF) to prevent manipulation,
     *      weighted by oracle stake and reputation score.
     * @param _proposalHash The hash of the proposal to select oracles for (used as a seed for more complex VRF).
     * @return An array of selected oracle addresses.
     */
    function selectActiveOracles(bytes32 _proposalHash) public view returns (address[] memory) {
        uint256 numToSelect = 3; // Example: select 3 oracles
        address[] memory selected = new address[](numToSelect);
        uint256 currentCount = 0;

        // Simplistic selection: just take the first `numToSelect` active oracles.
        // In a real system, you'd sort by reputation/stake or use a commit-reveal scheme with VRF
        // to ensure fair and unpredictable selection.
        for (uint256 i = 0; i < activeOracles.length && currentCount < numToSelect; i++) {
            address oracleAddr = activeOracles[i];
            // Basic check if oracle is still active and meets minimum stake
            if (oracles[oracleAddr].exists && oracles[oracleAddr].stake >= minOracleStake) {
                selected[currentCount] = oracleAddr;
                currentCount++;
            }
        }
        
        // If not enough oracles are available, return the ones we have.
        if (currentCount < numToSelect) {
            address[] memory actualSelected = new address[](currentCount);
            for(uint224 i=0; i<currentCount; i++) {
                actualSelected[i] = selected[i];
            }
            return actualSelected;
        }

        return selected;
    }


    // --- III. Proposal & Evaluation Lifecycle ---

    /**
     * @dev Submits a new proposal with an associated hash and initial metadata URI.
     *      Requires a dynamic fee in AETH, which must be approved beforehand.
     * @param _proposalHash Hash of the content/claim (e.g., IPFS hash, verifiable AI output).
     * @param _metadataURI The initial URI for the proposal's metadata.
     */
    function submitProposal(bytes32 _proposalHash, string calldata _metadataURI) external whenNotPaused {
        require(proposals[_proposalHash].submitter == address(0), "Proposal with this hash already exists");
        
        uint256 fee = getDynamicProposalFee();
        require(AETH_TOKEN.transferFrom(msg.sender, address(this), fee), "AETH transfer failed for proposal fee");
        
        accruedProtocolFees = accruedProtocolFees.add(fee);

        proposals[_proposalHash] = Proposal({
            submitter: msg.sender,
            proposalHash: _proposalHash,
            metadataURI: _metadataURI,
            submissionTime: block.timestamp,
            status: ProposalStatus.PENDING_EVALUATION,
            totalAETHStaked: fee,
            rewardsPool: fee.mul(70).div(100), // Example: 70% of fee goes to rewards for oracles/submitter
            selectedOracles: selectActiveOracles(_proposalHash), // Select oracles immediately
            judgmentsCount: 0,
            finalOutcomeHash: 0,
            outcomeTruthSet: false,
            challenger: address(0),
            challengeBond: 0,
            isChallenged: false,
            challengeResolved: false,
            disputeVotesCast: new mapping(address => bool)(), // Initialize mapping
            votesForChallenger: 0,
            votesAgainstChallenger: 0
        });

        // Ensure contributor exists or initialize, and mint NFT if new
        if (!contributors[msg.sender].exists) {
            _contributorTokenIds.increment();
            uint256 tokenId = _contributorTokenIds.current();
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, _metadataURI); // Initial Contributor NFT URI
            contributors[msg.sender] = ContributorInfo({
                reputationScore: 1000, // Starting reputation for new contributors
                nftTokenId: tokenId,
                rewardsDue: 0,
                exists: true
            });
        }
        // Contributor NFT reputation update happens upon successful proposal finalization

        emit ProposalSubmitted(_proposalHash, msg.sender, fee);
    }

    /**
     * @dev An assigned Oracle submits their judgment for a specific proposal.
     * @param _proposalHash The hash of the proposal.
     * @param _judgmentHash The hash of the oracle's evaluation/judgment.
     */
    function submitOracleJudgment(bytes32 _proposalHash, bytes32 _judgmentHash) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.submitter != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.PENDING_EVALUATION, "Proposal is not in evaluation phase");
        require(oracles[msg.sender].exists, "Caller is not a registered oracle");

        bool isSelectedOracle = false;
        for (uint224 i = 0; i < proposal.selectedOracles.length; i++) {
            if (proposal.selectedOracles[i] == msg.sender) {
                isSelectedOracle = true;
                break;
            }
        }
        require(isSelectedOracle, "Caller is not an assigned oracle for this proposal");
        require(proposal.judgments[msg.sender] == bytes32(0), "Oracle already submitted judgment for this proposal");

        proposal.judgments[msg.sender] = _judgmentHash;
        proposal.judgmentsCount = proposal.judgmentsCount.add(1);

        emit OracleJudgmentSubmitted(_proposalHash, msg.sender, _judgmentHash);
    }

    /**
     * @dev Finalizes a proposal's outcome by providing the "truth" hash and determining consensus
     *      among Oracle judgments. This triggers reward distribution and reputation updates.
     *      This function would ideally be called by an automated keeper (e.g., Chainlink Keeper)
     *      or a trusted third-party after a set evaluation period. The `_truthHash` is the verifiable
     *      outcome against which oracle judgments are compared.
     * @param _proposalHash The hash of the proposal to finalize.
     * @param _truthHash The objective "truth" hash against which judgments are compared.
     *        This could come from an external Chainlink oracle, a reveal phase, or admin input.
     * @param _oracleConsensusThreshold The minimum number of accurate oracle judgments required for success.
     */
    function finalizeProposalOutcome(bytes32 _proposalHash, bytes32 _truthHash, uint256 _oracleConsensusThreshold) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.submitter != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.PENDING_EVALUATION, "Proposal is not in evaluation phase");
        require(!proposal.outcomeTruthSet, "Outcome already finalized or truth set");
        require(msg.sender == owner(), "Only owner (or designated keeper) can finalize"); // Simplification for demo

        proposal.finalOutcomeHash = _truthHash;
        proposal.outcomeTruthSet = true;
        proposal.status = ProposalStatus.FINALIZED;

        uint256 accurateOracleCount = 0;
        uint256 totalOracleReputationGained = 0; // For tracking overall accuracy for dynamic fees/rewards

        for (uint224 i = 0; i < proposal.selectedOracles.length; i++) {
            address oracleAddr = proposal.selectedOracles[i];
            bytes32 oracleJudgment = proposal.judgments[oracleAddr];

            if (oracleJudgment == _truthHash) {
                accurateOracleCount = accurateOracleCount.add(1);
                // Reward accurate oracles based on their stake/reputation
                // The reward factor could be based on getDynamicOracleRewardFactor()
                uint256 oracleShare = proposal.rewardsPool.div(proposal.selectedOracles.length); // Example: Even split
                oracles[oracleAddr].rewardsDue = oracles[oracleAddr].rewardsDue.add(oracleShare);
                totalAccruedOracleRewards = totalAccruedOracleRewards.add(oracleShare);
                
                // Increase oracle reputation
                oracles[oracleAddr].reputationScore = oracles[oracleAddr].reputationScore.add(10); // Example score increase
                totalOracleReputationGained = totalOracleReputationGained.add(10); 
                
                // Update oracle NFT metadata to reflect new reputation
                _updateNFTReputationAndMetadata(
                    oracles[oracleAddr].nftTokenId, 
                    oracles[oracleAddr].reputationScore, 
                    string(abi.encodePacked("ipfs://oracle_meta/", oracles[oracleAddr].reputationScore.toString())) // Dynamic URI
                );
            } else if (oracleJudgment != bytes32(0)) { // If judgment was submitted but incorrect
                 // Penalize inaccurate oracles (e.g., reduce reputation slightly)
                oracles[oracleAddr].reputationScore = oracles[oracleAddr].reputationScore.sub(5); // Example score decrease
                _updateNFTReputationAndMetadata(
                    oracles[oracleAddr].nftTokenId, 
                    oracles[oracleAddr].reputationScore, 
                    string(abi.encodePacked("ipfs://oracle_meta/", oracles[oracleAddr].reputationScore.toString()))
                );
            }
        }

        // Reward proposal submitter if successful (based on oracle consensus)
        if (accurateOracleCount >= _oracleConsensusThreshold) {
            uint256 submitterReward = proposal.rewardsPool.mul(30).div(100); // Example: 30% of rewards pool to submitter
            contributors[proposal.submitter].rewardsDue = contributors[proposal.submitter].rewardsDue.add(submitterReward);
            
            // Increase contributor reputation
            contributors[proposal.submitter].reputationScore = contributors[proposal.submitter].reputationScore.add(20); // Example
            _updateNFTReputationAndMetadata(
                contributors[proposal.submitter].nftTokenId,
                contributors[proposal.submitter].reputationScore,
                string(abi.encodePacked("ipfs://contributor_meta/", contributors[proposal.submitter].reputationScore.toString()))
            );
            // RewardsClaimed event for submitter will be fired when they claim via `claimProposalRewards`
        } else {
            // Proposal failed due to insufficient consensus. The remaining rewards pool is kept by protocol.
            accruedProtocolFees = accruedProtocolFees.add(proposal.rewardsPool);
        }

        emit ProposalFinalized(_proposalHash, _truthHash, proposal.rewardsPool);
    }

    /**
     * @dev Retrieves all current details about a specific proposal.
     * @param _proposalHash The hash of the proposal.
     * @return Proposal struct.
     */
    function getProposalDetails(bytes32 _proposalHash) external view returns (Proposal memory) {
        require(proposals[_proposalHash].submitter != address(0), "Proposal does not exist");
        return proposals[_proposalHash];
    }

    // --- IV. Dynamic Reputation & NFT System (ERC721 Extension) ---

    // Note: mintContributorNFT and mintOracleNFT are primarily handled internally upon registration/first proposal.
    // They are left here as public for potential future direct minting scenarios by owner.

    /**
     * @dev Mints a unique Contributor NFT for a new successful participant, reflecting their initial reputation.
     *      Normally called internally upon first successful proposal submission.
     * @param _contributor The address of the contributor.
     * @param _initialScore The initial reputation score.
     * @param _metadataURI The initial URI for the NFT metadata.
     */
    function mintContributorNFT(address _contributor, uint256 _initialScore, string calldata _metadataURI) external onlyOwner {
        require(!contributors[_contributor].exists, "Contributor already has an NFT");
        _contributorTokenIds.increment();
        uint256 tokenId = _contributorTokenIds.current();
        _mint(_contributor, tokenId);
        _setTokenURI(tokenId, _metadataURI);
        contributors[_contributor] = ContributorInfo({
            reputationScore: _initialScore,
            nftTokenId: tokenId,
            rewardsDue: 0,
            exists: true
        });
    }

    /**
     * @dev Mints a unique Oracle NFT upon registration, reflecting their initial standing.
     *      Normally called internally during `registerOracle`.
     * @param _oracle The address of the oracle.
     * @param _initialScore The initial reputation score.
     * @param _metadataURI The initial URI for the NFT metadata.
     */
    function mintOracleNFT(address _oracle, uint256 _initialScore, string calldata _metadataURI) external onlyOwner {
        require(!oracles[_oracle].exists, "Oracle already has an NFT");
        _oracleTokenIds.increment();
        uint256 tokenId = _oracleTokenIds.current();
        _mint(_oracle, tokenId);
        _setTokenURI(tokenId, _metadataURI);
        oracles[_oracle] = OracleInfo({
            stake: minOracleStake, // Assume min stake for initial mint, updated later
            reputationScore: _initialScore,
            lastActivityEpoch: currentEpoch,
            nftTokenId: tokenId,
            rewardsDue: 0,
            exists: true
        });
        activeOracles.push(_oracle); // Add to active oracle list
    }

    /**
     * @dev Internal function to update the off-chain metadata URI for a specific Contributor or Oracle NFT.
     *      The `_newReputationScore` is passed for informational purposes, as the actual score update
     *      occurs directly on the respective `oracles` or `contributors` struct.
     * @param _tokenId The token ID of the NFT.
     * @param _newReputationScore The new numerical reputation score.
     * @param _newMetadataURI The new URI for the NFT metadata (e.g., reflecting trait changes).
     */
    function _updateNFTReputationAndMetadata(uint256 _tokenId, uint256 _newReputationScore, string memory _newMetadataURI) internal {
        // This function leverages ERC721URIStorage's _setTokenURI to update the URI.
        // Off-chain services would monitor this event or query tokenURI to reflect changes.
        _setTokenURI(_tokenId, _newMetadataURI);
        emit NFTReputationUpdated(_tokenId, _newReputationScore, _newMetadataURI);
    }

    /**
     * @dev Retrieves the current numerical reputation score for a given NFT.
     *      Note: This function iterates through `activeOracles` and looks up contributor by `ownerOf`
     *      which can be inefficient for very large numbers of users. For production, a more
     *      efficient `tokenId -> entity` mapping would be ideal.
     * @param _tokenId The token ID of the NFT.
     * @return The reputation score associated with the NFT. Returns 0 if not found.
     */
    function getTokenReputationScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");

        // Attempt to find if it's an Oracle NFT
        for (uint224 i = 0; i < activeOracles.length; i++) {
            if (oracles[activeOracles[i]].exists && oracles[activeOracles[i]].nftTokenId == _tokenId) {
                return oracles[activeOracles[i]].reputationScore;
            }
        }
        
        // If not an Oracle NFT, check if it's a Contributor NFT
        // More robust: maintain a tokenId -> address mapping or a single `reputation` mapping.
        // For simplicity, we get the owner and check if they are a contributor.
        address ownerOfToken = ownerOf(_tokenId);
        if(contributors[ownerOfToken].exists && contributors[ownerOfToken].nftTokenId == _tokenId) {
            return contributors[ownerOfToken].reputationScore;
        }
        
        return 0; // Token found, but no associated reputation (e.g. if it's a burned token or uninitialized)
    }

    /**
     * @dev Overrides ERC721 `tokenURI` to return the current metadata URI for a specific NFT.
     *      The URI is updated dynamically by `_updateNFTReputationAndMetadata`.
     * @param _tokenId The token ID.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[_tokenId]; // Returns the URI stored by ERC721URIStorage
    }

    // --- V. Rewards & Claiming ---

    /**
     * @dev Allows the original submitter of a successfully finalized proposal to claim their rewards.
     * @param _proposalHash The hash of the proposal.
     */
    function claimProposalRewards(bytes32 _proposalHash) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.submitter == msg.sender, "Only the submitter can claim rewards");
        require(proposal.status == ProposalStatus.FINALIZED, "Proposal is not finalized");
        require(contributors[msg.sender].rewardsDue > 0, "No rewards due for this contributor");

        uint256 amount = contributors[msg.sender].rewardsDue;
        contributors[msg.sender].rewardsDue = 0; // Reset
        
        require(AETH_TOKEN.transfer(msg.sender, amount), "AETH transfer failed for proposal rewards");
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev Allows eligible Oracles to claim accumulated rewards from accurate judgments.
     */
    function claimOracleRewards() external whenNotPaused {
        require(oracles[msg.sender].exists, "Caller is not a registered oracle");
        require(oracles[msg.sender].rewardsDue > 0, "No rewards due for this oracle");

        uint256 amount = oracles[msg.sender].rewardsDue;
        oracles[msg.sender].rewardsDue = 0; // Reset
        
        totalAccruedOracleRewards = totalAccruedOracleRewards.sub(amount); // Decrement total
        require(AETH_TOKEN.transfer(msg.sender, amount), "AETH transfer failed for oracle rewards");
        emit RewardsClaimed(msg.sender, amount);
    }

    // --- VI. Dispute Resolution & Slashing (Advanced - Simplified) ---

    /**
     * @dev Allows a user to dispute the finalized outcome of a proposal by staking a challenge bond.
     *      This initiates a new voting phase on the dispute. Uses native ETH for the bond for simplicity.
     * @param _proposalHash The hash of the proposal to challenge.
     */
    function challengeProposalOutcome(bytes32 _proposalHash) external payable whenNotPaused {
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.submitter != address(0), "Proposal does not exist");
        require(proposal.status == ProposalStatus.FINALIZED, "Proposal is not in a finalized state to be challenged");
        require(!proposal.isChallenged, "Proposal is already under dispute");
        require(msg.value > 0, "Challenge bond must be greater than zero"); // Using ETH for challenge bond

        proposal.challenger = msg.sender;
        proposal.challengeBond = msg.value;
        proposal.isChallenged = true;
        proposal.status = ProposalStatus.DISPUTED; // Change status to indicate dispute

        emit ProposalChallenged(_proposalHash, msg.sender, msg.value);
    }

    /**
     * @dev Registered Oracles (or a broader community if a governance module is integrated)
     *      vote on the validity of a challenged outcome.
     *      Simplified: only registered Oracles can vote.
     * @param _proposalHash The hash of the proposal under dispute.
     * @param _isChallengerCorrect True if the voter believes the challenger is correct.
     */
    function voteOnDispute(bytes32 _proposalHash, bool _isChallengerCorrect) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.isChallenged, "Proposal is not under dispute");
        require(proposal.status == ProposalStatus.DISPUTED, "Proposal is not in dispute status");
        require(oracles[msg.sender].exists, "Only registered oracles can vote on disputes");
        require(!proposal.disputeVotesCast[msg.sender], "Oracle already voted on this dispute");

        if (_isChallengerCorrect) {
            proposal.votesForChallenger = proposal.votesForChallenger.add(1);
        } else {
            proposal.votesAgainstChallenger = proposal.votesAgainstChallenger.add(1);
        }
        proposal.disputeVotesCast[msg.sender] = true;

        emit DisputeVote(_proposalHash, msg.sender, _isChallengerCorrect);
    }

    /**
     * @dev Finalizes a dispute, distributing challenge bonds, potentially reversing an outcome,
     *      and applying slashing for incorrect judgments/challenges.
     *      This function would ideally be called by an automated keeper after a dispute voting period.
     * @param _proposalHash The hash of the proposal.
     */
    function resolveDispute(bytes32 _proposalHash) external onlyOwner { // Or by a specific dispute resolver role / automated keeper
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.isChallenged, "Proposal is not under dispute");
        require(!proposal.challengeResolved, "Dispute already resolved");
        
        // Determine outcome based on votes (simple majority)
        bool challengerWon = proposal.votesForChallenger > proposal.votesAgainstChallenger;

        if (challengerWon) {
            // Challenger was correct:
            // Reward challenger: gets their bond back + a portion of the original proposal fee (or slashes from original oracles).
            // This logic is highly simplified. A real system would need to reverse or adjust previous rewards/slashes.
            uint256 challengerReward = proposal.challengeBond.add(proposal.totalAETHStaked.mul(10).div(100)); // Example reward from original fee
            payable(proposal.challenger).transfer(challengerReward); // Transfer ETH
            
            // Further logic for slashing initially incorrect oracles or restoring reputation could go here.
            
            emit DisputeResolved(_proposalHash, true);
        } else {
            // Challenger was incorrect: challenger loses their bond.
            // The bond is kept by the contract (added to protocol fees) or distributed to correct voters.
            accruedProtocolFees = accruedProtocolFees.add(proposal.challengeBond); // Protocol keeps bond
            emit DisputeResolved(_proposalHash, false);
        }

        proposal.challengeResolved = true;
        // Optionally revert proposal status to an adjusted 'FINALIZED' state or a new 'DISPUTE_SETTLED' status.
        proposal.status = ProposalStatus.FINALIZED;
    }

    // --- VII. Helper & View Functions ---

    /**
     * @dev Calculates the dynamic proposal fee based on conceptual system health (e.g., success rate).
     *      For this demo, it's a placeholder. A real implementation would track historical success rates
     *      and adjust fees based on `adaptiveFeeParams`.
     * @return The calculated dynamic proposal fee in AETH.
     */
    function getDynamicProposalFee() public view returns (uint256) {
        // Placeholder for dynamic calculation.
        // Factors could include: overall proposal success rate (higher success -> lower fees to encourage submissions),
        // Oracle availability/load, network congestion.
        // Example formula: baseFee * (1 + (1 - avgSuccessRate) * successWeight / baseFactor)
        return baseProposalFee;
    }

    /**
     * @dev Calculates the dynamic oracle reward factor based on overall oracle accuracy.
     *      For this demo, it's a placeholder. A real implementation would track average accuracy
     *      of oracle judgments and adjust rewards based on `adaptiveFeeParams`.
     * @return The calculated dynamic oracle reward factor (as a multiplier, e.g., 10000 for 1x).
     */
    function getDynamicOracleRewardFactor() public view returns (uint256) {
        // Placeholder for dynamic calculation.
        // Factors could include: overall oracle accuracy (higher accuracy -> higher rewards to incentivize quality),
        // Oracle competition, amount of open proposals.
        // Example formula: baseFactor * (1 + avgAccuracy * accuracyWeight / baseFactor)
        return adaptiveFeeParams.baseFactor; // Returns 100% of the base factor (e.g., 10000)
    }

    /**
     * @dev Advances the current epoch if enough time has passed.
     *      This function can be called by anyone but will only advance if `epochDuration` has passed
     *      since the last epoch update. Useful for time-gated operations or reputation decay.
     */
    function advanceEpoch() public {
        if (block.timestamp >= lastEpochUpdateTime.add(epochDuration)) {
            currentEpoch = currentEpoch.add(1);
            lastEpochUpdateTime = block.timestamp;
            emit EpochAdvanced(currentEpoch);
        }
    }

    /**
     * @dev Get total number of currently active registered oracles.
     * @return The count of active oracles.
     */
    function getTotalOracles() external view returns (uint256) {
        return activeOracles.length;
    }
}
```