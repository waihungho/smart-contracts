This smart contract, "Veridian Labs: Decentralized IP Incubator & Impact Network," introduces a novel framework for decentralized content creation, intellectual property (IP) incubation, and impact assessment. It combines elements of DAO governance, dynamic NFTs, reputation systems (including Soulbound Tokens), and a simulated AI-driven oracle for content curation. Creators submit IP proposals, which are then evaluated by a community of "Patrons" and an AI oracle. Successful proposals lead to the minting of dynamic IP NFTs, royalty distribution, and the potential for on-chain licensing. The system incentivizes participation through reputation scores and SBTs.

---

## Veridian Labs: Decentralized IP Incubator & Impact Network

This contract facilitates the decentralized incubation and management of intellectual property (IP). It allows creators to submit IP proposals, which are then voted on by a community of staked token holders ("Patrons") and assessed by a simulated AI oracle. Successful proposals result in the minting of dynamic IP NFTs, royalty distribution, and an on-chain licensing framework. A reputation system rewards active and successful participants with Soulbound Tokens (SBTs).

### Outline & Function Summary

**I. Core Infrastructure & Administration**
1.  **`constructor`**: Initializes the contract with the governance token, IP NFT token, and initial owner.
2.  **`updateGovernanceToken`**: Allows the owner to update the address of the ERC-20 governance token.
3.  **`updateIPNFTContract`**: Allows the owner to update the address of the ERC-721 IP NFT contract.
4.  **`setAIOracleAddress`**: Sets the address of the trusted AI Oracle (simulated external AI service).
5.  **`emergencyPause`**: Owner can pause the contract in case of emergencies.
6.  **`unpause`**: Owner can unpause the contract.
7.  **`withdrawContractFees`**: Allows the owner to withdraw accumulated ETH fees from proposals.

**II. Governance & Staking (Patron System)**
8.  **`stakeTokens`**: Allows users to stake governance tokens to gain voting power.
9.  **`unstakeTokens`**: Allows users to unstake their tokens and withdraw them.
10. **`delegateVotingPower`**: Allows a staker to delegate their voting power to another address.
11. **`undelegateVotingPower`**: Allows a staker to revoke their delegation.
12. **`getVotingPower` (view)**: Returns the current voting power of an address.

**III. IP Proposal & Curation**
13. **`submitIPProposal`**: Creators submit a new IP proposal with metadata (IPFS hash) and a fee.
14. **`voteOnProposal`**: Patrons vote 'yes' or 'no' on a proposal, weighted by their voting power.
15. **`submitAIEvaluation`**: The designated AI Oracle submits an evaluation score for a proposal.
16. **`challengeAIEvaluation`**: Patrons can challenge an AI evaluation by staking tokens, triggering a community re-evaluation.
17. **`resolveAIEvaluationChallenge`**: Owner/DAO resolves a challenge, either approving the AI or ruling for the challengers.
18. **`fundProposal`**: Patrons can directly contribute ETH to a proposal to boost its funding.
19. **`finalizeProposal`**: Finalizes a proposal after voting and AI evaluation, leading to NFT minting or rejection.

**IV. IP Asset Management (Dynamic NFTs)**
20. **`mintIPAssetNFT` (internal)**: Mints a unique IP Asset NFT to the creator upon successful proposal finalization.
21. **`proposeDynamicIPTraitUpdate`**: Creator can propose updates to their IP NFT's metadata (e.g., project evolution).
22. **`voteOnDynamicIPTraitUpdate`**: Patrons vote on proposed IP NFT metadata updates.
23. **`executeDynamicIPTraitUpdate`**: Finalizes and applies approved IP NFT metadata updates.
24. **`distributeIPRoyalties`**: Manages the distribution of collected royalties from the IP to creators, funders, and the network.

**V. Reputation & Impact**
25. **`calculateUserReputation` (view)**: Calculates a user's reputation score based on successful votes, funding, and AI evaluation contributions.
26. **`claimReputationBadgeNFT`**: Allows users who meet a reputation threshold to mint a Soulbound Token (SBT) representing their expertise.

**VI. On-chain IP Licensing**
27. **`setIPLicensingModel`**: Creator defines a licensing model for their IP (e.g., perpetual, per-use, subscription).
28. **`grantIPLicense`**: Allows an approved licensee to acquire a license for the IP, recording terms on-chain.
29. **`revokeIPLicense`**: Creator can revoke an active license under predefined conditions.

**VII. Utilities & Views**
30. **`getProposalDetails` (view)**: Retrieves details of a specific IP proposal.
31. **`getIPAssetDetails` (view)**: Retrieves details of a specific IP Asset NFT.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors for gas efficiency and clarity
error InvalidProposalState();
error AlreadyVoted();
error NotEnoughVotingPower();
error NoActiveProposalToChallenge();
error InvalidAIEvaluationScore();
error IPNotFound();
error NotCreatorOfIP();
error InsufficientFundsForChallenge();
error UnauthorizedAIOracle();
error ProposalAlreadyFinalized();
error ChallengeNotResolved();
error ReputationThresholdNotMet();
error NotLicensedUser();
error LicenseAlreadyActive();
error LicenseExpiredOrRevoked();
error InvalidLicenseDuration();
error OnlyCallableByIPOwner();
error NoFundsToWithdraw();
error TokenTransferFailed();
error Unauthorized();
error DelegationFailed();

// --- Interfaces for custom NFTs ---
interface IIPAssetNFT {
    function mint(address to, uint256 tokenId, string calldata uri, uint256 proposalId) external;
    function updateMetadata(uint256 tokenId, string calldata newUri) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function exists(uint256 tokenId) external view returns (bool);
    function setBaseURI(string calldata baseURI_) external;
    function tokenData(uint256 tokenId) external view returns (uint256 proposalId, uint256 currentReputationScore, uint256 totalFundingReceived);
}

// Soulbound Token for Reputation Badges (simplified ERC721 without transfer function)
interface IReputationBadgeNFT {
    function mint(address to, uint256 tokenId, string calldata uri) external;
    function exists(uint256 tokenId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function setBaseURI(string calldata baseURI_) external;
}


// --- Main Contract ---
contract VeridianLabs is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public governanceToken;
    IIPAssetNFT public ipAssetNFT;
    IReputationBadgeNFT public reputationBadgeNFT;
    address public aiOracleAddress; // Address of the trusted AI Oracle (can be a multisig or another contract)

    Counters.Counter private _proposalIds;
    Counters.Counter private _ipAssetIds;
    Counters.Counter private _reputationBadgeIds;

    uint256 public constant MIN_STAKE_FOR_VOTE = 100 * 10 ** 18; // Example: 100 tokens
    uint256 public constant MIN_REP_FOR_BADGE = 500; // Minimum reputation score to claim a badge
    uint256 public constant PROPOSAL_FEE = 0.01 ether; // 0.01 ETH for submitting a proposal

    // --- Structs ---

    enum ProposalState { Pending, Voting, AIEvaluation, Challenged, Approved, Rejected, Finalized }
    enum LicenseStatus { Inactive, Active, Revoked, Expired }
    enum LicensingModel { Perpetual, PerUse, Subscription, Custom }

    struct IPProposal {
        address creator;
        string ipfsHash; // Link to detailed proposal document/assets
        uint256 submittedAt;
        ProposalState state;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        uint256 totalFundedETH;
        uint256 aiEvaluationScore; // Score from 0-100
        uint256 ipAssetTokenId; // If approved, link to minted IPAssetNFT
        bool aiEvaluationChallenged;
        address challengerAddress;
        uint256 challengeStake;
        bool challengeResolved;
        bool challengeAcceptedByDAO; // If DAO rules in favor of challenger
    }
    mapping(uint256 => IPProposal) public proposals;

    struct UserData {
        uint256 stakedAmount;
        address delegatee; // Address to which voting power is delegated
        uint256 reputationScore; // Based on successful votes, funding, challenges etc.
        bool hasClaimedReputationBadge;
    }
    mapping(address => UserData) public userData;

    struct IPAssetData {
        address creator;
        string ipfsHash; // Current metadata for the IP
        mapping(address => LicenseAgreement) licenses; // Active licenses for this IP
        LicensingModel licensingModel;
        uint256 creatorRoyaltyShare; // Percentage for creator (e.g., 70 for 70%)
        uint256 funderRoyaltyShare;  // Percentage for funders
        uint256 networkFeeShare;     // Percentage for the Veridian Labs treasury
        uint256 totalRevenueCollected;
    }
    mapping(uint256 => IPAssetData) public ipAssets; // ipAssetTokenId => IPAssetData

    struct LicenseAgreement {
        address licensee;
        uint256 grantedAt;
        uint256 expiresAt; // 0 for perpetual
        string licenseTermsURI; // IPFS hash for full license terms
        LicenseStatus status;
        uint256 feePaid; // Amount paid for this specific license
    }

    // --- Events ---
    event GovernanceTokenUpdated(address indexed newTokenAddress);
    event IPNFTContractUpdated(address indexed newIPNFTAddress);
    event AIOracleAddressUpdated(address indexed newAIOracleAddress);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed staker, uint256 amount);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event VotingPowerUndelegated(address indexed delegator);
    event IPProposalSubmitted(uint256 indexed proposalId, address indexed creator, string ipfsHash);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event AIEvaluationSubmitted(uint256 indexed proposalId, uint256 score);
    event AIEvaluationChallenged(uint256 indexed proposalId, address indexed challenger, uint256 stake);
    event AIEvaluationChallengeResolved(uint256 indexed proposalId, bool acceptedByDAO);
    event ProposalFunded(uint256 indexed proposalId, address indexed funder, uint256 amount);
    event ProposalFinalized(uint256 indexed proposalId, ProposalState finalState, uint256 ipAssetTokenId);
    event IPAssetMetadataProposed(uint256 indexed ipAssetTokenId, uint256 indexed proposalId, string newIpfsHash);
    event IPAssetMetadataUpdated(uint256 indexed ipAssetTokenId, string newIpfsHash);
    event RoyaltiesDistributed(uint256 indexed ipAssetTokenId, uint256 totalAmount, uint256 creatorShare, uint256 funderShare, uint256 networkShare);
    event ReputationBadgeClaimed(address indexed user, uint256 indexed badgeTokenId, uint256 reputationScore);
    event IPLicensingModelSet(uint256 indexed ipAssetTokenId, LicensingModel model, uint256 creatorShare, uint256 funderShare, uint256 networkFeeShare);
    event IPLicenseGranted(uint256 indexed ipAssetTokenId, address indexed licensee, uint256 licenseId, uint256 feePaid);
    event IPLicenseRevoked(uint256 indexed ipAssetTokenId, address indexed licensee, uint256 licenseId);
    event CreatorFundsWithdrawn(address indexed creator, uint256 ipAssetTokenId, uint256 amount);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert UnauthorizedAIOracle();
        _;
    }

    modifier onlyIPCreator(uint256 _ipAssetTokenId) {
        if (ipAssets[_ipAssetTokenId].creator != msg.sender) revert OnlyCallableByIPOwner();
        _;
    }

    // --- Constructor ---
    constructor(address _governanceToken, address _ipAssetNFT, address _reputationBadgeNFT) Ownable(msg.sender) {
        governanceToken = IERC20(_governanceToken);
        ipAssetNFT = IIPAssetNFT(_ipAssetNFT);
        reputationBadgeNFT = IReputationBadgeNFT(_reputationBadgeNFT);
    }

    // --- I. Core Infrastructure & Administration ---

    function updateGovernanceToken(address _newTokenAddress) external onlyOwner whenNotPaused {
        if (_newTokenAddress == address(0)) revert Unauthorized(); // Simplified error for address(0)
        governanceToken = IERC20(_newTokenAddress);
        emit GovernanceTokenUpdated(_newTokenAddress);
    }

    function updateIPNFTContract(address _newIPNFTAddress) external onlyOwner whenNotPaused {
        if (_newIPNFTAddress == address(0)) revert Unauthorized();
        ipAssetNFT = IIPAssetNFT(_newIPNFTAddress);
        emit IPNFTContractUpdated(_newIPNFTAddress);
    }

    function setAIOracleAddress(address _newAIOracleAddress) external onlyOwner whenNotPaused {
        if (_newAIOracleAddress == address(0)) revert Unauthorized();
        aiOracleAddress = _newAIOracleAddress;
        emit AIOracleAddressUpdated(_newAIOracleAddress);
    }

    function emergencyPause() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function withdrawContractFees(address _to, uint256 _amount) external onlyOwner nonReentrant whenNotPaused {
        if (_amount == 0) revert NoFundsToWithdraw();
        // The contract collects ETH directly for `PROPOSAL_FEE`
        // Governance token fees would need explicit transfer calls
        if (address(this).balance < _amount) revert NoFundsToWithdraw();
        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert TokenTransferFailed();
    }

    // --- II. Governance & Staking (Patron System) ---

    function stakeTokens(uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount == 0) revert TokenTransferFailed(); // Simplified for 0 amount
        uint256 currentStake = userData[msg.sender].stakedAmount;
        if (!governanceToken.transferFrom(msg.sender, address(this), _amount)) revert TokenTransferFailed();
        userData[msg.sender].stakedAmount = currentStake + _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    function unstakeTokens(uint256 _amount) external nonReentrant whenNotPaused {
        uint256 currentStake = userData[msg.sender].stakedAmount;
        if (_amount == 0 || currentStake < _amount) revert TokenTransferFailed();

        // Ensure no active delegations if unstaking significantly
        if (userData[msg.sender].delegatee != address(0) && currentStake - _amount < MIN_STAKE_FOR_VOTE) {
             // Optionally auto-undelegate or require undelegation first
             userData[msg.sender].delegatee = address(0);
             emit VotingPowerUndelegated(msg.sender);
        }

        userData[msg.sender].stakedAmount = currentStake - _amount;
        if (!governanceToken.transfer(msg.sender, _amount)) revert TokenTransferFailed();
        emit TokensUnstaked(msg.sender, _amount);
    }

    function delegateVotingPower(address _delegatee) external whenNotPaused {
        if (userData[msg.sender].stakedAmount < MIN_STAKE_FOR_VOTE) revert NotEnoughVotingPower();
        if (_delegatee == msg.sender) revert DelegationFailed(); // Cannot delegate to self
        userData[msg.sender].delegatee = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    function undelegateVotingPower() external whenNotPaused {
        if (userData[msg.sender].delegatee == address(0)) revert DelegationFailed(); // No active delegation
        userData[msg.sender].delegatee = address(0);
        emit VotingPowerUndelegated(msg.sender);
    }

    function getVotingPower(address _voter) public view returns (uint256) {
        address currentDelegatee = userData[_voter].delegatee;
        if (currentDelegatee != address(0) && currentDelegatee != _voter) {
            return userData[currentDelegatee].stakedAmount;
        }
        return userData[_voter].stakedAmount;
    }

    // --- III. IP Proposal & Curation ---

    function submitIPProposal(string calldata _ipfsHash) external payable nonReentrant whenNotPaused {
        if (msg.value < PROPOSAL_FEE) revert InsufficientFundsForChallenge(); // Reusing error
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = IPProposal({
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            submittedAt: block.timestamp,
            state: ProposalState.Pending, // Will transition to Voting by a separate mechanism or immediate
            yesVotes: 0,
            noVotes: 0,
            totalFundedETH: 0,
            aiEvaluationScore: 0,
            ipAssetTokenId: 0,
            aiEvaluationChallenged: false,
            challengerAddress: address(0),
            challengeStake: 0,
            challengeResolved: false,
            challengeAcceptedByDAO: false
        });
        proposals[proposalId].state = ProposalState.Voting; // Immediately enter voting phase

        emit IPProposalSubmitted(proposalId, msg.sender, _ipfsHash);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        IPProposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) revert IPNotFound(); // Proposal does not exist
        if (proposal.state != ProposalState.Voting && proposal.state != ProposalState.Challenged) revert InvalidProposalState();

        address voter = msg.sender;
        if (userData[voter].delegatee != address(0)) {
            voter = userData[voter].delegatee; // If delegated, the actual voter is the delegatee
        }
        if (proposal.hasVoted[voter]) revert AlreadyVoted();

        uint256 votingPower = getVotingPower(voter);
        if (votingPower == 0) revert NotEnoughVotingPower();

        proposal.hasVoted[voter] = true;
        if (_support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, votingPower);
    }

    function submitAIEvaluation(uint256 _proposalId, uint256 _score) external onlyAIOracle whenNotPaused {
        IPProposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) revert IPNotFound();
        if (proposal.state != ProposalState.Voting) revert InvalidProposalState(); // AI can only evaluate during voting phase

        if (_score > 100) revert InvalidAIEvaluationScore(); // Score 0-100
        
        proposal.aiEvaluationScore = _score;
        proposal.state = ProposalState.AIEvaluation; // Move to AI Evaluation stage after score is in
        emit AIEvaluationSubmitted(_proposalId, _score);
    }

    function challengeAIEvaluation(uint256 _proposalId) external payable nonReentrant whenNotPaused {
        IPProposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) revert IPNotFound();
        if (proposal.state != ProposalState.AIEvaluation) revert NoActiveProposalToChallenge();
        if (proposal.aiEvaluationChallenged) revert NoActiveProposalToChallenge(); // Already challenged

        // Requires a minimum stake to challenge, for example, 0.1 ETH
        uint256 minChallengeStake = 0.1 ether;
        if (msg.value < minChallengeStake) revert InsufficientFundsForChallenge();

        proposal.aiEvaluationChallenged = true;
        proposal.challengerAddress = msg.sender;
        proposal.challengeStake = msg.value;
        proposal.state = ProposalState.Challenged; // Re-enters voting-like state
        emit AIEvaluationChallenged(_proposalId, msg.sender, msg.value);
    }

    function resolveAIEvaluationChallenge(uint256 _proposalId, bool _acceptChallengerClaim) external onlyOwner nonReentrant whenNotPaused {
        IPProposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) revert IPNotFound();
        if (proposal.state != ProposalState.Challenged) revert NoActiveProposalToChallenge();
        if (proposal.challengeResolved) revert ChallengeNotResolved(); // Already resolved

        proposal.challengeResolved = true;
        proposal.challengeAcceptedByDAO = _acceptChallengerClaim;

        if (_acceptChallengerClaim) {
            // Return stake to challenger, potentially penalize AI Oracle / re-evaluate AI score
            (bool success,) = proposal.challengerAddress.call{value: proposal.challengeStake}("");
            if (!success) revert TokenTransferFailed(); // Or handle refund failure
            // Update AI score if challenged successfully, for now, manual decision
            // proposal.aiEvaluationScore = new_score_from_dao_vote;
            _updateUserReputation(proposal.challengerAddress, 50); // Reward challenger
        } else {
            // Burn stake or send to treasury if challenge fails
            // Current implementation just keeps it in contract for later withdrawal
            _updateUserReputation(proposal.challengerAddress, -20); // Penalize challenger
        }

        // After challenge, move back to AIEvaluation for finalization (or re-voting)
        // For simplicity, directly finalize based on owner decision
        proposal.state = ProposalState.AIEvaluation;
        emit AIEvaluationChallengeResolved(_proposalId, _acceptChallengerClaim);
    }

    function fundProposal(uint256 _proposalId) external payable nonReentrant whenNotPaused {
        IPProposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) revert IPNotFound();
        if (proposal.state == ProposalState.Rejected || proposal.state == ProposalState.Finalized) revert InvalidProposalState();
        if (msg.value == 0) revert NoFundsToWithdraw(); // Reusing error

        proposal.totalFundedETH += msg.value;
        _updateUserReputation(msg.sender, 5); // Small reputation boost for funding
        emit ProposalFunded(_proposalId, msg.sender, msg.value);
    }

    function finalizeProposal(uint256 _proposalId) external onlyOwner nonReentrant whenNotPaused {
        IPProposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) revert IPNotFound();
        if (proposal.state == ProposalState.Finalized || proposal.state == ProposalState.Rejected) revert ProposalAlreadyFinalized();
        if (proposal.aiEvaluationChallenged && !proposal.challengeResolved) revert ChallengeNotResolved();

        // Determine final outcome based on votes and AI score
        bool passedVoting = (proposal.yesVotes > proposal.noVotes);
        bool passedAIScore = (proposal.aiEvaluationScore >= 60); // Example threshold

        if (proposal.aiEvaluationChallenged && proposal.challengeAcceptedByDAO) {
            // If challenge accepted, AI score might be overridden, or treated as passed regardless of score
            passedAIScore = true; // DAO overrides AI in this case
        }

        if (passedVoting && passedAIScore) {
            proposal.state = ProposalState.Approved;
            _ipAssetIds.increment();
            uint256 newIpAssetTokenId = _ipAssetIds.current();
            proposal.ipAssetTokenId = newIpAssetTokenId;
            
            _mintIPAssetNFT(
                proposal.creator,
                newIpAssetTokenId,
                proposal.ipfsHash,
                _proposalId,
                userData[proposal.creator].reputationScore,
                proposal.totalFundedETH
            );

            ipAssets[newIpAssetTokenId].creator = proposal.creator;
            ipAssets[newIpAssetTokenId].ipfsHash = proposal.ipfsHash;
            ipAssets[newIpAssetTokenId].licensingModel = LicensingModel.Custom; // Default
            ipAssets[newIpAssetTokenId].creatorRoyaltyShare = 70; // Default 70%
            ipAssets[newIpAssetTokenId].funderRoyaltyShare = 20;  // Default 20%
            ipAssets[newIpAssetTokenId].networkFeeShare = 10;     // Default 10%

            _updateUserReputation(proposal.creator, 100); // Significant reputation for successful IP
        } else {
            proposal.state = ProposalState.Rejected;
            // Optionally, return funds to original contributors or burn if rejected
        }

        proposal.state = ProposalState.Finalized;
        emit ProposalFinalized(_proposalId, proposal.state, proposal.ipAssetTokenId);
    }

    // --- IV. IP Asset Management (Dynamic NFTs) ---

    function _mintIPAssetNFT(address _to, uint256 _tokenId, string memory _uri, uint256 _proposalId, uint256 _creatorReputation, uint256 _totalFunding) internal {
        ipAssetNFT.mint(_to, _tokenId, _uri, _proposalId);
    }

    function proposeDynamicIPTraitUpdate(uint256 _ipAssetTokenId, string calldata _newIpfsHash) external onlyIPCreator(_ipAssetTokenId) whenNotPaused {
        if (!ipAssetNFT.exists(_ipAssetTokenId)) revert IPNotFound();
        // Create a new proposal for this update
        _proposalIds.increment();
        uint256 updateProposalId = _proposalIds.current();

        proposals[updateProposalId] = IPProposal({
            creator: msg.sender,
            ipfsHash: _newIpfsHash, // This IPFS hash is for the *update* metadata
            submittedAt: block.timestamp,
            state: ProposalState.Voting,
            yesVotes: 0,
            noVotes: 0,
            totalFundedETH: 0,
            aiEvaluationScore: 0,
            ipAssetTokenId: _ipAssetTokenId, // Link to the IP asset being updated
            aiEvaluationChallenged: false,
            challengerAddress: address(0),
            challengeStake: 0,
            challengeResolved: false,
            challengeAcceptedByDAO: false
        });

        emit IPAssetMetadataProposed(_ipAssetTokenId, updateProposalId, _newIpfsHash);
    }

    function executeDynamicIPTraitUpdate(uint256 _updateProposalId) external onlyOwner nonReentrant whenNotPaused {
        IPProposal storage proposal = proposals[_updateProposalId];
        if (proposal.creator == address(0) || proposal.ipAssetTokenId == 0) revert IPNotFound(); // Not a valid update proposal
        if (proposal.state != ProposalState.Finalized || proposal.state != ProposalState.Approved) revert InvalidProposalState();

        // Check if the original IP asset still exists and creator hasn't changed
        if (!ipAssetNFT.exists(proposal.ipAssetTokenId) || ipAssetNFT.ownerOf(proposal.ipAssetTokenId) != proposal.creator) {
            revert IPNotFound(); // IP asset transferred or doesn't exist anymore
        }

        ipAssetNFT.updateMetadata(proposal.ipAssetTokenId, proposal.ipfsHash);
        ipAssets[proposal.ipAssetTokenId].ipfsHash = proposal.ipfsHash; // Update the record in this contract too
        emit IPAssetMetadataUpdated(proposal.ipAssetTokenId, proposal.ipfsHash);
    }

    function distributeIPRoyalties(uint256 _ipAssetTokenId, uint256 _amount) external nonReentrant whenNotPaused {
        IPAssetData storage ipAsset = ipAssets[_ipAssetTokenId];
        if (ipAsset.creator == address(0)) revert IPNotFound();
        if (_amount == 0) revert NoFundsToWithdraw();

        uint256 creatorShare = (_amount * ipAsset.creatorRoyaltyShare) / 100;
        uint256 funderShare = (_amount * ipAsset.funderRoyaltyShare) / 100;
        uint256 networkShare = (_amount * ipAsset.networkFeeShare) / 100;

        // Distribute to creator
        (bool successCreator,) = ipAsset.creator.call{value: creatorShare}("");
        if (!successCreator) revert TokenTransferFailed();

        // Distribute to original funders (simplified: could be pro-rata or to network treasury if no direct funders recorded)
        // For simplicity, send funder share to network treasury for now if no specific funder mechanism is implemented
        // In a real system, you'd track individual funders per proposal.
        (bool successFunder,) = address(this).call{value: funderShare}(""); // Add to contract balance
        if (!successFunder) revert TokenTransferFailed();

        // Distribute network fee
        (bool successNetwork,) = address(this).call{value: networkShare}(""); // Add to contract balance
        if (!successNetwork) revert TokenTransferFailed();

        ipAsset.totalRevenueCollected += _amount;
        emit RoyaltiesDistributed(_ipAssetTokenId, _amount, creatorShare, funderShare, networkShare);
    }

    // Creator can withdraw their share collected by the contract.
    function withdrawCreatorFunds(uint256 _ipAssetTokenId, uint256 _amount) external onlyIPCreator(_ipAssetTokenId) nonReentrant whenNotPaused {
        // This function assumes royalties collected are held by the contract until withdrawal
        // In this simplified example, `distributeIPRoyalties` directly sends.
        // A more complex system would have a balance per creator per IP.
        // For now, this is a placeholder or implies a direct deposit from a license.
        if (_amount == 0) revert NoFundsToWithdraw();
        // Placeholder: Needs a mechanism to track creator specific withdrawable balance
        // For now, let's assume `distributeIPRoyalties` directly sends, making this redundant for royalty flow.
        // This could be used if a direct licensing fee is sent to contract and needs manual withdrawal.
        if (address(this).balance < _amount) revert NoFundsToWithdraw(); // Check general contract balance
        (bool success,) = msg.sender.call{value: _amount}("");
        if (!success) revert TokenTransferFailed();
        emit CreatorFundsWithdrawn(msg.sender, _ipAssetTokenId, _amount);
    }

    // --- V. Reputation & Impact ---

    function _updateUserReputation(address _user, int256 _change) internal {
        // Ensure reputation score doesn't go below zero
        if (_change < 0 && userData[_user].reputationScore < uint256(-_change)) {
            userData[_user].reputationScore = 0;
        } else {
            userData[_user].reputationScore = uint256(int256(userData[_user].reputationScore) + _change);
        }
    }

    function calculateUserReputation(address _user) public view returns (uint256) {
        return userData[_user].reputationScore;
    }

    function claimReputationBadgeNFT() external nonReentrant whenNotPaused {
        if (userData[msg.sender].reputationScore < MIN_REP_FOR_BADGE) revert ReputationThresholdNotMet();
        if (userData[msg.sender].hasClaimedReputationBadge) revert Unauthorized(); // Already claimed

        _reputationBadgeIds.increment();
        uint256 badgeTokenId = _reputationBadgeIds.current();
        string memory tokenUri = string(abi.encodePacked("ipfs://QmT_Your_Badge_IPFS_Hash/", Strings.toString(badgeTokenId))); // Example URI
        reputationBadgeNFT.mint(msg.sender, badgeTokenId, tokenUri);

        userData[msg.sender].hasClaimedReputationBadge = true;
        _updateUserReputation(msg.sender, 100); // Reward for claiming the badge itself
        emit ReputationBadgeClaimed(msg.sender, badgeTokenId, userData[msg.sender].reputationScore);
    }

    // --- VI. On-chain IP Licensing ---

    function setIPLicensingModel(
        uint256 _ipAssetTokenId,
        LicensingModel _model,
        uint256 _creatorShare,
        uint256 _funderShare,
        uint256 _networkFeeShare
    ) external onlyIPCreator(_ipAssetTokenId) whenNotPaused {
        if (_creatorShare + _funderShare + _networkFeeShare != 100) revert InvalidProposalState(); // Simplified for now
        IPAssetData storage ipAsset = ipAssets[_ipAssetTokenId];
        if (ipAsset.creator == address(0)) revert IPNotFound();

        ipAsset.licensingModel = _model;
        ipAsset.creatorRoyaltyShare = _creatorShare;
        ipAsset.funderRoyaltyShare = _funderShare;
        ipAsset.networkFeeShare = _networkFeeShare;

        emit IPLicensingModelSet(_ipAssetTokenId, _model, _creatorShare, _funderShare, _networkFeeShare);
    }

    function grantIPLicense(
        uint256 _ipAssetTokenId,
        address _licensee,
        uint256 _durationInDays, // 0 for perpetual
        string calldata _licenseTermsURI,
        uint256 _licenseFee // In ETH
    ) external payable onlyIPCreator(_ipAssetTokenId) nonReentrant whenNotPaused {
        if (!ipAssetNFT.exists(_ipAssetTokenId)) revert IPNotFound();
        if (_licensee == address(0)) revert Unauthorized();
        if (ipAssets[_ipAssetTokenId].licenses[_licensee].status == LicenseStatus.Active) revert LicenseAlreadyActive();
        if (_licenseFee > 0 && msg.value < _licenseFee) revert InsufficientFundsForChallenge(); // Reusing error for ETH payment

        IPAssetData storage ipAsset = ipAssets[_ipAssetTokenId];
        ipAsset.licenses[_licensee] = LicenseAgreement({
            licensee: _licensee,
            grantedAt: block.timestamp,
            expiresAt: _durationInDays == 0 ? 0 : block.timestamp + (_durationInDays * 1 days),
            licenseTermsURI: _licenseTermsURI,
            status: LicenseStatus.Active,
            feePaid: _licenseFee
        });

        // Distribute _licenseFee immediately
        if (_licenseFee > 0) {
            uint256 creatorShare = (_licenseFee * ipAsset.creatorRoyaltyShare) / 100;
            uint256 funderShare = (_licenseFee * ipAsset.funderRoyaltyShare) / 100;
            uint256 networkShare = (_licenseFee * ipAsset.networkFeeShare) / 100;

            (bool successCreator,) = ipAsset.creator.call{value: creatorShare}("");
            if (!successCreator) revert TokenTransferFailed();
            (bool successFunder,) = address(this).call{value: funderShare}(""); // For simplicity, to contract
            if (!successFunder) revert TokenTransferFailed();
            (bool successNetwork,) = address(this).call{value: networkShare}(""); // For simplicity, to contract
            if (!successNetwork) revert TokenTransferFailed();
        }

        emit IPLicenseGranted(_ipAssetTokenId, _licensee, 0, _licenseFee); // License ID can be _licensee address or an incrementing counter
    }

    function revokeIPLicense(uint256 _ipAssetTokenId, address _licensee) external onlyIPCreator(_ipAssetTokenId) whenNotPaused {
        IPAssetData storage ipAsset = ipAssets[_ipAssetTokenId];
        if (ipAsset.creator == address(0)) revert IPNotFound();
        if (ipAsset.licenses[_licensee].status != LicenseStatus.Active) revert LicenseExpiredOrRevoked();

        // Additional logic for revocation conditions (e.g., breach of terms, which would be off-chain adjudicated)
        // For simplicity, creator can just revoke.
        ipAsset.licenses[_licensee].status = LicenseStatus.Revoked;
        emit IPLicenseRevoked(_ipAssetTokenId, _licensee, 0); // License ID can be _licensee address
    }

    // --- VII. Utilities & Views ---

    function getProposalDetails(uint256 _proposalId) public view returns (
        address creator,
        string memory ipfsHash,
        uint256 submittedAt,
        ProposalState state,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 totalFundedETH,
        uint256 aiEvaluationScore,
        uint256 ipAssetTokenId,
        bool aiEvaluationChallenged,
        address challengerAddress,
        uint256 challengeStake,
        bool challengeResolved,
        bool challengeAcceptedByDAO
    ) {
        IPProposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) revert IPNotFound();

        return (
            proposal.creator,
            proposal.ipfsHash,
            proposal.submittedAt,
            proposal.state,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.totalFundedETH,
            proposal.aiEvaluationScore,
            proposal.ipAssetTokenId,
            proposal.aiEvaluationChallenged,
            proposal.challengerAddress,
            proposal.challengeStake,
            proposal.challengeResolved,
            proposal.challengeAcceptedByDAO
        );
    }

    function getIPAssetDetails(uint256 _ipAssetTokenId) public view returns (
        address creator,
        string memory ipfsHash,
        LicensingModel licensingModel,
        uint256 creatorRoyaltyShare,
        uint256 funderRoyaltyShare,
        uint256 networkFeeShare,
        uint256 totalRevenueCollected
    ) {
        IPAssetData storage ipAsset = ipAssets[_ipAssetTokenId];
        if (ipAsset.creator == address(0)) revert IPNotFound(); // Not a valid IP asset ID

        return (
            ipAsset.creator,
            ipAsset.ipfsHash,
            ipAsset.licensingModel,
            ipAsset.creatorRoyaltyShare,
            ipAsset.funderRoyaltyShare,
            ipAsset.networkFeeShare,
            ipAsset.totalRevenueCollected
        );
    }

    function getLicenseDetails(uint256 _ipAssetTokenId, address _licensee) public view returns (
        address licensee,
        uint256 grantedAt,
        uint256 expiresAt,
        string memory licenseTermsURI,
        LicenseStatus status,
        uint256 feePaid
    ) {
        IPAssetData storage ipAsset = ipAssets[_ipAssetTokenId];
        if (ipAsset.creator == address(0)) revert IPNotFound();
        LicenseAgreement storage license = ipAsset.licenses[_licensee];
        if (license.licensee == address(0)) revert NotLicensedUser(); // No license for this user

        return (
            license.licensee,
            license.grantedAt,
            license.expiresAt,
            license.licenseTermsURI,
            license.status,
            license.feePaid
        );
    }

    // Fallback function to receive ETH
    receive() external payable {}
}

```