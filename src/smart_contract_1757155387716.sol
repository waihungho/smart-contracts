Here's a Solidity smart contract named "Synthex Labs: Decentralized Algorithmic Research & Innovation Fund". This contract aims to be an advanced, creative, and trendy platform for decentralized science (DeSci) and innovation funding. It integrates simulated AI evaluation, on-chain reputation (SynPoints), tokenized intellectual property (Discovery NFTs) with revenue sharing, and a multi-stage proposal lifecycle.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary:

/*
*   Synthex Labs: Decentralized Algorithmic Research & Innovation Fund
*   ------------------------------------------------------------------
*   This contract facilitates decentralized research and innovation funding. It leverages a simulated
*   AI oracle for proposal evaluation, integrates an on-chain reputation system (SynPoints - ERC-1155)
*   for participants, and tokenizes successful intellectual property (Discovery NFTs - ERC-721)
*   with built-in revenue-sharing mechanisms. Governance is managed by a Synthex Council.
*
*   I.   Core Fund Management & Proposal Lifecycle
*        1. submitResearchProposal(string _ipfsHash, uint256 _fundingRequested, uint256 _durationWeeks):
*           Allows researchers to submit new proposals with an initial bond.
*        2. endorseProposal(uint256 _proposalId, uint256 _amount):
*           Community members stake tokens to endorse proposals, influencing funding.
*        3. revokeEndorsement(uint256 _proposalId):
*           Allows endorsers to withdraw their stake from a proposal within the endorsement window.
*        4. triggerSynthexEvaluation(uint256 _proposalId):
*           Initiates the simulated AI oracle evaluation for a proposal after the endorsement window closes.
*        5. finalizeProposalFunding(uint256 _proposalId):
*           Releases approved funding to successful proposals based on Synthex Score and endorsement.
*        6. reportResearchCompletion(uint256 _proposalId, string _resultIpfsHash):
*           Researcher marks their proposal as complete, providing research results.
*        7. verifyResearchOutcome(uint256 _proposalId, bool _isSuccessful):
*           Synthex Council verifies the outcome of completed research.
*        8. claimFundingMilestone(uint256 _proposalId, uint256 _milestoneIndex):
*           (Placeholder) Allows researchers to claim partial funding based on milestones.
*        9. reclaimProposalBond(uint256 _proposalId):
*           Researcher reclaims their initial bond after successful project completion and verification.
*
*   II.  Intellectual Property (IP) & Discovery NFTs
*        10. mintDiscoveryNFT(uint256 _proposalId, string _ipRightsIpfsHash):
*            Mints a unique ERC-721 token representing IP rights for successfully completed research.
*        11. assignIPRevenueShare(uint256 _discoveryNFTId, address _beneficiary, uint256 _percentage):
*            Allows Discovery NFT owners to define revenue distribution percentages for their IP.
*        12. distributeIPRevenue(uint256 _discoveryNFTId, uint256 _amount):
*            Anyone can send revenue to the contract for a specific IP NFT, which is then recorded for beneficiaries.
*        13. claimIPRevenue(uint256 _discoveryNFTId):
*            Allows beneficiaries to claim their accumulated revenue shares from a Discovery NFT.
*
*   III. Synthex Reputation & Incentives (ERC-1155 SynPoints)
*        14. awardSynPointsExternal(address _recipient, uint256 _typeId, uint256 _amount):
*            Synthex Council can manually award non-transferable SynPoints for various contributions.
*        15. burnSynPointsExternal(address _holder, uint256 _typeId, uint256 _amount):
*            Synthex Council can manually burn SynPoints, e.g., for penalties or misuse.
*        16. claimEndorsementRewards(uint256 _proposalId):
*            Allows successful endorsers to claim their rewards for backing winning proposals.
*
*   IV.  Governance & Protocol Parameters
*        17. updateNumericalProtocolParameter(bytes32 _paramName, uint256 _newValue):
*            Synthex Council can update key numerical parameters of the protocol.
*        18. setExternalContractAddress(bytes32 _contractName, address _newAddress):
*            Synthex Council can update the addresses of integrated external contracts (e.g., Oracle).
*        19. proposeCouncilMember(address _newMember):
*            (Placeholder) Allows any user to propose a new address to become a Synthex Council member.
*        20. voteOnCouncilMember(address _candidate, bool _approve):
*            (Simplified) Synthex Council members can vote on or directly add new council members
*            if they meet SynPoints requirements.
*        21. withdrawFromTreasury(address _recipient, uint256 _amount):
*            Synthex Council can withdraw funds from the contract treasury for operations.
*/

// --- INTERFACES ---

interface ISynthexOracle {
    function getSynthexScore(uint256 _proposalId, string calldata _ipfsHash) external view returns (uint256);
}

/**
 * @title SynPoints
 * @dev ERC-1155 contract for non-transferable reputation points within Synthex Labs.
 *      Managed exclusively by the SynthexLabs contract.
 */
contract SynPoints is ERC1155, Ownable {
    address public synthexLabsContract;

    constructor(address _synthexLabsContract) ERC1155("https://synthexlabs.io/synpoints/{id}.json") Ownable(msg.sender) {
        synthexLabsContract = _synthexLabsContract;
    }

    // Only SynthexLabs contract can call _mint or _burn
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external {
        require(msg.sender == synthexLabsContract, "SynPoints: Only SynthexLabs can mint");
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        require(msg.sender == synthexLabsContract, "SynPoints: Only SynthexLabs can burn");
        _burn(from, id, amount);
    }

    /**
     * @dev Prevents external transfers of SynPoints, making them non-transferable/soulbound.
     *      Allows minting (from address(0)) and burning (to address(0)).
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // Prevent transfers unless it's a mint or burn operation
        if (from != address(0) && to != address(0)) {
            revert("SynPoints: Tokens are non-transferable");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Grants SynthexLabs contract approval for all SynPoints operations on behalf of users.
     *      This is to facilitate burning/awarding by the main contract logic without explicit user approval.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (operator == synthexLabsContract) {
            return true;
        }
        return super.isApprovedForAll(account, operator);
    }
}

/**
 * @title DiscoveryNFTs
 * @dev ERC-721 contract for tokenized Intellectual Property within Synthex Labs.
 *      Minting managed exclusively by the SynthexLabs contract.
 */
contract DiscoveryNFTs is ERC721, Ownable {
    address public synthexLabsContract;

    constructor(address _synthexLabsContract) ERC721("Discovery NFT", "DSNFT") Ownable(msg.sender) {
        synthexLabsContract = _synthexLabsContract;
    }

    function mintNFT(address to, uint256 tokenId, string memory tokenURI) external returns (uint256) {
        require(msg.sender == synthexLabsContract, "DiscoveryNFTs: Only SynthexLabs can mint");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    /**
     * @dev Allows Discovery NFT owners to explicitly approve SynthexLabs for managing their specific NFT.
     *      This could be used for revenue distribution, escrow, or other future IP-related operations.
     */
    function setApprovalForSynthexLabs(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "DiscoveryNFTs: Not NFT owner");
        _approve(synthexLabsContract, tokenId);
    }
}


// --- MAIN CONTRACT ---

contract SynthexLabs is Ownable {
    using Counters for Counters.Counter;

    // --- STATE VARIABLES ---

    IERC20 public fundingToken; // The ERC-20 token used for funding and staking
    ISynthexOracle public synthexOracle; // Interface for the external Synthex AI Oracle
    SynPoints public synPoints; // ERC-1155 contract for SynPoints (reputation)
    DiscoveryNFTs public discoveryNFTs; // ERC-721 contract for Discovery NFTs (IP)

    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _discoveryNFTIdCounter;

    // --- CONFIGURABLE PARAMETERS (DAO-governed) ---
    uint256 public proposalBondAmount; // Required bond from researcher to submit a proposal
    uint256 public minSynthexScoreForFunding; // Minimum score from oracle for a proposal to be considered
    uint256 public minEndorsementStakePercentage; // Percentage of funding requested that needs to be endorsed
    uint256 public endorsementRewardPercentage; // Percentage of proposal bond given to successful endorsers
    uint256 public failedProposalPenaltyPercentage; // Percentage of staked endorsement lost for failed proposals
    uint256 public researcherRewardSynPoints; // SynPoints awarded to researcher for successful project
    uint256 public endorserRewardSynPoints; // SynPoints awarded to endorsers for successful project
    uint256 public councilMemberSynPointsRequirement; // Min SynPoints to be eligible for council
    uint256 public proposalEvaluationWindow; // Time (in seconds) for community endorsement
    uint256 public researchCompletionWindow; // Time (in seconds) for researcher to complete after funding
    uint256 public verificationWindow; // Time (in seconds) for council to verify research

    // --- STRUCTS ---

    enum ProposalState {
        Submitted,
        Evaluating,
        Approved,
        Rejected,
        Funded,
        CompletedPendingVerification,
        CompletedVerified,
        Failed
    }

    struct Proposal {
        uint256 id;
        address researcher;
        string ipfsHash; // Hash of the proposal details
        uint256 fundingRequested;
        uint256 fundingReleased; // Amount of funding already released
        uint256 durationWeeks;
        uint256 submissionTime;
        ProposalState state;
        uint256 synthexScore; // Score from the Synthex Oracle
        uint256 totalEndorsementStake;
        address[] endorsers; // List of unique endorsers
        mapping(address => uint256) endorsementStakes; // Amount staked by each endorser
        string resultIpfsHash; // Hash of the research results
        uint256 completionTime; // Time when research was reported completed
        uint256 discoveryNFTId; // ID of the minted Discovery NFT, if any
        bool bondReclaimed;
    }

    struct DiscoveryIP {
        uint256 id;
        uint256 proposalId;
        string ipRightsIpfsHash; // Hash of the IP rights documentation
        mapping(address => uint256) revenueSharePercentages; // Percentage for each beneficiary (sum must be 10000 = 100%)
        uint256 totalRevenueCollected;
        mapping(address => uint256) claimedRevenue; // Revenue already claimed by beneficiary
    }

    // --- MAPPINGS ---
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => DiscoveryIP) public discoveryIPs;
    mapping(address => bool) public isSynthexCouncilMember;
    address[] public synthexCouncilMembers; // For easy iteration, limited size expected for council

    // --- EVENTS ---
    event ProposalSubmitted(uint256 indexed proposalId, address indexed researcher, uint256 fundingRequested, string ipfsHash);
    event ProposalEndorsed(uint256 indexed proposalId, address indexed endorser, uint256 amount);
    event EndorsementRevoked(uint256 indexed proposalId, address indexed endorser, uint256 amount);
    event SynthexEvaluationTriggered(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event FundingReleased(uint256 indexed proposalId, uint256 amount);
    event ResearchReported(uint256 indexed proposalId, string resultIpfsHash);
    event ResearchVerified(uint256 indexed proposalId, bool isSuccessful);
    event DiscoveryNFTMinted(uint256 indexed discoveryNFTId, uint256 indexed proposalId, address indexed owner);
    event IPRevenueShared(uint256 indexed discoveryNFTId, address indexed beneficiary, uint256 percentage);
    event IPRevenueDistributed(uint256 indexed discoveryNFTId, uint256 amount);
    event IPRevenueClaimed(uint256 indexed discoveryNFTId, address indexed beneficiary, uint256 amount);
    event SynPointsAwarded(address indexed recipient, uint256 typeId, uint256 amount);
    event SynPointsBurned(address indexed holder, uint256 typeId, uint256 amount);
    event EndorsementRewardsClaimed(uint256 indexed proposalId, address indexed endorser, uint256 amount);
    event NumericalProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event ExternalContractAddressUpdated(bytes32 indexed contractName, address newAddress);
    event CouncilMemberProposed(address indexed candidate);
    event CouncilMemberVoted(address indexed voter, address indexed candidate, bool approved);
    event CouncilMemberAdded(address indexed member);
    event FundsWithdrawn(address indexed recipient, uint256 amount);


    // --- CONSTRUCTOR ---
    constructor(
        address _fundingToken,
        address _synthexOracle,
        address _synPointsContract,
        address _discoveryNFTsContract
    ) Ownable(msg.sender) {
        fundingToken = IERC20(_fundingToken);
        synthexOracle = ISynthexOracle(_synthexOracle);
        synPoints = SynPoints(_synPointsContract);
        discoveryNFTs = DiscoveryNFTs(_discoveryNFTsContract);

        // Make deployer the initial council member for bootstrap
        isSynthexCouncilMember[msg.sender] = true;
        synthexCouncilMembers.push(msg.sender);

        // Initial default parameters (should be updated via governance if needed)
        proposalBondAmount = 100 ether; // Example: 100 tokens
        minSynthexScoreForFunding = 70; // Example: 70 out of 100
        minEndorsementStakePercentage = 50; // Example: 50%
        endorsementRewardPercentage = 10; // Example: 10% of bond
        failedProposalPenaltyPercentage = 20; // Example: 20% loss
        researcherRewardSynPoints = 50;
        endorserRewardSynPoints = 5;
        councilMemberSynPointsRequirement = 100;
        proposalEvaluationWindow = 7 days; // 1 week
        researchCompletionWindow = 365 days; // 1 year
        verificationWindow = 14 days; // 2 weeks
    }

    // --- MODIFIERS ---
    modifier onlySynthexCouncil() {
        require(isSynthexCouncilMember[msg.sender], "SynthexLabs: Only Synthex Council member");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalIdCounter.current() >= _proposalId && _proposalId > 0, "SynthexLabs: Proposal does not exist");
        _;
    }

    // --- I. CORE FUND MANAGEMENT & PROPOSAL LIFECYCLE ---

    /**
     * @dev Submit a new research proposal. Requires an initial bond in `fundingToken`.
     * @param _ipfsHash IPFS hash pointing to detailed proposal information.
     * @param _fundingRequested Amount of funding requested by the researcher.
     * @param _durationWeeks Estimated duration of the research project in weeks.
     */
    function submitResearchProposal(string memory _ipfsHash, uint256 _fundingRequested, uint256 _durationWeeks)
        external
    {
        require(_fundingRequested > 0, "SynthexLabs: Funding requested must be positive");
        require(_durationWeeks > 0, "SynthexLabs: Duration must be positive");
        require(fundingToken.transferFrom(msg.sender, address(this), proposalBondAmount), "SynthexLabs: Failed to transfer proposal bond");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            researcher: msg.sender,
            ipfsHash: _ipfsHash,
            fundingRequested: _fundingRequested,
            fundingReleased: 0,
            durationWeeks: _durationWeeks,
            submissionTime: block.timestamp,
            state: ProposalState.Submitted,
            synthexScore: 0,
            totalEndorsementStake: 0,
            endorsers: new address[](0),
            completionTime: 0,
            resultIpfsHash: "",
            discoveryNFTId: 0,
            bondReclaimed: false
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _fundingRequested, _ipfsHash);
    }

    /**
     * @dev Community members stake `fundingToken` to endorse a proposal, showing their support.
     * @param _proposalId The ID of the proposal to endorse.
     * @param _amount The amount of `fundingToken` to stake.
     */
    function endorseProposal(uint256 _proposalId, uint256 _amount) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Submitted, "SynthexLabs: Proposal not in endorsement phase");
        require(block.timestamp <= proposal.submissionTime + proposalEvaluationWindow, "SynthexLabs: Endorsement window closed");
        require(_amount > 0, "SynthexLabs: Endorsement amount must be positive");
        require(fundingToken.transferFrom(msg.sender, address(this), _amount), "SynthexLabs: Failed to transfer endorsement stake");

        if (proposal.endorsementStakes[msg.sender] == 0) {
            proposal.endorsers.push(msg.sender); // Add to unique endorsers list
        }
        proposal.endorsementStakes[msg.sender] += _amount;
        proposal.totalEndorsementStake += _amount;

        emit ProposalEndorsed(_proposalId, msg.sender, _amount);
    }

    /**
     * @dev Allows an endorser to revoke their stake if the endorsement window is still open.
     * @param _proposalId The ID of the proposal.
     */
    function revokeEndorsement(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Submitted, "SynthexLabs: Proposal not in endorsement phase");
        require(block.timestamp <= proposal.submissionTime + proposalEvaluationWindow, "SynthexLabs: Endorsement window closed");
        uint256 stakedAmount = proposal.endorsementStakes[msg.sender];
        require(stakedAmount > 0, "SynthexLabs: No active endorsement from sender");

        proposal.totalEndorsementStake -= stakedAmount;
        delete proposal.endorsementStakes[msg.sender]; // Remove the specific stake

        require(fundingToken.transfer(msg.sender, stakedAmount), "SynthexLabs: Failed to return revoked endorsement");

        emit EndorsementRevoked(_proposalId, msg.sender, stakedAmount);
    }

    /**
     * @dev Triggers the Synthex Oracle to evaluate a proposal. Only callable after endorsement window.
     *      In a real scenario, this would be an external call to a Chainlink or other oracle service
     *      that performs complex off-chain computation and returns the score on-chain.
     * @param _proposalId The ID of the proposal to evaluate.
     */
    function triggerSynthexEvaluation(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Submitted, "SynthexLabs: Proposal not in submitted state");
        require(block.timestamp > proposal.submissionTime + proposalEvaluationWindow, "SynthexLabs: Endorsement window still open");

        proposal.synthexScore = synthexOracle.getSynthexScore(_proposalId, proposal.ipfsHash);
        proposal.state = ProposalState.Evaluating;

        emit SynthexEvaluationTriggered(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Evaluating);
    }

    /**
     * @dev Finalizes proposal funding if it meets Synthex Score and endorsement criteria.
     * @param _proposalId The ID of the proposal.
     */
    function finalizeProposalFunding(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Evaluating, "SynthexLabs: Proposal not in evaluating state");

        bool fundingApproved = true;

        if (proposal.synthexScore < minSynthexScoreForFunding) {
            fundingApproved = false;
        }

        uint256 requiredEndorsement = proposal.fundingRequested * minEndorsementStakePercentage / 100;
        if (proposal.totalEndorsementStake < requiredEndorsement) {
            fundingApproved = false;
        }

        if (!fundingApproved) {
            proposal.state = ProposalState.Rejected;
            _handleRejectedProposal(_proposalId);
            emit ProposalStateChanged(_proposalId, ProposalState.Rejected);
            return;
        }

        // Fund the proposal - assuming full funding for simplicity, could be milestone-based
        require(fundingToken.transfer(proposal.researcher, proposal.fundingRequested), "SynthexLabs: Failed to transfer requested funding");
        proposal.fundingReleased = proposal.fundingRequested;
        proposal.state = ProposalState.Funded;

        emit FundingReleased(_proposalId, proposal.fundingRequested);
        emit ProposalStateChanged(_proposalId, ProposalState.Funded);
    }

    /**
     * @dev Internal function to handle a rejected proposal: refund researcher bond and penalize endorsers.
     * @param _proposalId The ID of the rejected proposal.
     */
    function _handleRejectedProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];

        // Refund researcher's bond
        if (!proposal.bondReclaimed) {
            require(fundingToken.transfer(proposal.researcher, proposalBondAmount), "SynthexLabs: Failed to refund researcher bond on rejection");
            proposal.bondReclaimed = true;
        }

        // Return endorsement stakes minus penalty
        for (uint i = 0; i < proposal.endorsers.length; i++) {
            address endorser = proposal.endorsers[i];
            uint256 stakedAmount = proposal.endorsementStakes[endorser];
            if (stakedAmount > 0) { // Check if the endorser still has a stake (not revoked)
                uint256 refundAmount = stakedAmount - (stakedAmount * failedProposalPenaltyPercentage / 100);
                if (refundAmount > 0) {
                    require(fundingToken.transfer(endorser, refundAmount), "SynthexLabs: Failed to refund endorser stake");
                }
            }
        }
        // The penalty amount remains in the SynthexLabs treasury.
    }

    /**
     * @dev Researcher reports the completion of their project.
     * @param _proposalId The ID of the completed proposal.
     * @param _resultIpfsHash IPFS hash pointing to research results and documentation.
     */
    function reportResearchCompletion(uint256 _proposalId, string memory _resultIpfsHash) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "SynthexLabs: Only researcher can report completion");
        require(proposal.state == ProposalState.Funded, "SynthexLabs: Proposal not in funded state");
        require(block.timestamp <= proposal.submissionTime + proposal.durationWeeks * 7 days + researchCompletionWindow, "SynthexLabs: Research completion window expired");

        proposal.resultIpfsHash = _resultIpfsHash;
        proposal.completionTime = block.timestamp;
        proposal.state = ProposalState.CompletedPendingVerification;

        emit ResearchReported(_proposalId, _resultIpfsHash);
        emit ProposalStateChanged(_proposalId, ProposalState.CompletedPendingVerification);
    }

    /**
     * @dev Synthex Council verifies the outcome of a completed research project.
     * @param _proposalId The ID of the proposal.
     * @param _isSuccessful True if research is verified as successful, false otherwise.
     */
    function verifyResearchOutcome(uint256 _proposalId, bool _isSuccessful) external onlySynthexCouncil proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.CompletedPendingVerification, "SynthexLabs: Proposal not pending verification");
        require(block.timestamp <= proposal.completionTime + verificationWindow, "SynthexLabs: Verification window expired");

        if (_isSuccessful) {
            proposal.state = ProposalState.CompletedVerified;
            _awardSuccessRewards(_proposalId);
        } else {
            proposal.state = ProposalState.Failed;
            _penalizeFailedProject(_proposalId);
        }

        emit ResearchVerified(_proposalId, _isSuccessful);
        emit ProposalStateChanged(_proposalId, proposal.state);
    }

    /**
     * @dev Internal function to award SynPoints to researcher and endorsers for a successful project.
     * @param _proposalId The ID of the successful proposal.
     */
    function _awardSuccessRewards(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];

        // Award SynPoints to researcher (Type 1 for Researcher SynPoints)
        synPoints.mint(proposal.researcher, 1, researcherRewardSynPoints, "");
        emit SynPointsAwarded(proposal.researcher, 1, researcherRewardSynPoints);

        // Award SynPoints to endorsers (Type 2 for Endorser SynPoints)
        for (uint i = 0; i < proposal.endorsers.length; i++) {
            address endorser = proposal.endorsers[i];
            if (proposal.endorsementStakes[endorser] > 0) { // Check if they still have an active stake
                synPoints.mint(endorser, 2, endorserRewardSynPoints, "");
                emit SynPointsAwarded(endorser, 2, endorserRewardSynPoints);
            }
        }
    }

    /**
     * @dev Internal function to penalize for a failed project *after* funding (e.g., failed verification).
     *      Researcher bond is forfeit, and endorsers get their stake back without rewards.
     * @param _proposalId The ID of the failed proposal.
     */
    function _penalizeFailedProject(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        // Researcher's bond is forfeit if not already reclaimed. (It remains in the contract).

        // Endorser stakes are returned, but no rewards given.
        for (uint i = 0; i < proposal.endorsers.length; i++) {
            address endorser = proposal.endorsers[i];
            uint256 stakedAmount = proposal.endorsementStakes[endorser];
            if (stakedAmount > 0) {
                 require(fundingToken.transfer(endorser, stakedAmount), "SynthexLabs: Failed to refund endorser stake on post-funding failure");
            }
        }
    }

    /**
     * @dev Placeholder for claiming partial funding based on milestones.
     *      Requires a more complex milestone definition and verification system.
     * @param _proposalId The ID of the proposal.
     * @param _milestoneIndex The index of the milestone to claim.
     */
    function claimFundingMilestone(uint256 _proposalId, uint256 _milestoneIndex) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "SynthexLabs: Only researcher can claim milestones");
        require(proposal.state == ProposalState.Funded, "SynthexLabs: Proposal not in funded state");
        // Further logic for milestone verification and partial funding release would go here.
        revert("SynthexLabs: Milestone funding not fully implemented in this version. Full funding released on approval.");
    }

    /**
     * @dev Researcher reclaims their initial proposal bond upon successful project completion and verification.
     * @param _proposalId The ID of the proposal.
     */
    function reclaimProposalBond(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.researcher == msg.sender, "SynthexLabs: Only researcher can reclaim bond");
        require(proposal.state == ProposalState.CompletedVerified, "SynthexLabs: Proposal not successfully verified");
        require(!proposal.bondReclaimed, "SynthexLabs: Bond already reclaimed");

        require(fundingToken.transfer(msg.sender, proposalBondAmount), "SynthexLabs: Failed to transfer bond back");
        proposal.bondReclaimed = true;
    }

    // --- II. INTELLECTUAL PROPERTY (IP) & DISCOVERY NFTs ---

    /**
     * @dev Mints a Discovery NFT (ERC-721) for a successfully completed and verified research project.
     *      The NFT represents the IP rights of the research.
     * @param _proposalId The ID of the proposal.
     * @param _ipRightsIpfsHash IPFS hash pointing to official IP rights documentation.
     */
    function mintDiscoveryNFT(uint256 _proposalId, string memory _ipRightsIpfsHash) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.CompletedVerified, "SynthexLabs: Proposal not successfully verified");
        require(proposal.discoveryNFTId == 0, "SynthexLabs: Discovery NFT already minted for this proposal");

        _discoveryNFTIdCounter.increment();
        uint256 newDiscoveryNFTId = _discoveryNFTIdCounter.current();

        discoveryNFTs.mintNFT(proposal.researcher, newDiscoveryNFTId, _ipRightsIpfsHash);
        proposal.discoveryNFTId = newDiscoveryNFTId;

        discoveryIPs[newDiscoveryNFTId] = DiscoveryIP({
            id: newDiscoveryNFTId,
            proposalId: _proposalId,
            ipRightsIpfsHash: _ipRightsIpfsHash,
            totalRevenueCollected: 0
        });

        // Default: Researcher gets 100% of future revenue, can be changed via assignIPRevenueShare
        discoveryIPs[newDiscoveryNFTId].revenueSharePercentages[proposal.researcher] = 10000; // 100% (represented as 10000 basis points)

        emit DiscoveryNFTMinted(newDiscoveryNFTId, _proposalId, proposal.researcher);
    }

    /**
     * @dev Assigns or updates revenue sharing percentages for a Discovery NFT.
     *      Only the current NFT owner can call this. The sum of all shares must eventually be 10000.
     * @param _discoveryNFTId The ID of the Discovery NFT.
     * @param _beneficiary The address of the beneficiary.
     * @param _percentage The percentage (e.g., 1000 for 10%, max 10000 for 100%).
     */
    function assignIPRevenueShare(uint256 _discoveryNFTId, address _beneficiary, uint256 _percentage) external {
        require(discoveryNFTs.ownerOf(_discoveryNFTId) == msg.sender, "SynthexLabs: Only NFT owner can assign revenue share");
        require(_percentage <= 10000, "SynthexLabs: Percentage exceeds 100%");

        DiscoveryIP storage ip = discoveryIPs[_discoveryNFTId];
        require(ip.id != 0, "SynthexLabs: Discovery IP does not exist");

        ip.revenueSharePercentages[_beneficiary] = _percentage;
        // Note: Owner is responsible for ensuring all assigned percentages sum up to 10000 (100%).
        // A more advanced system would track all beneficiaries and enforce the sum explicitly.

        emit IPRevenueShared(_discoveryNFTId, _beneficiary, _percentage);
    }

    /**
     * @dev Allows anyone to send `fundingToken` revenue to the contract for a specific Discovery NFT.
     *      The amount is recorded and made available for beneficiaries to claim.
     * @param _discoveryNFTId The ID of the Discovery NFT for which revenue is being sent.
     * @param _amount The amount of `fundingToken` revenue to distribute.
     */
    function distributeIPRevenue(uint256 _discoveryNFTId, uint256 _amount) external {
        DiscoveryIP storage ip = discoveryIPs[_discoveryNFTId];
        require(ip.id != 0, "SynthexLabs: Discovery IP does not exist");
        require(_amount > 0, "SynthexLabs: Amount must be positive");
        require(fundingToken.transferFrom(msg.sender, address(this), _amount), "SynthexLabs: Failed to transfer revenue to contract");

        ip.totalRevenueCollected += _amount;

        // Iterate through all known beneficiaries and update their claimable amounts.
        // For simplicity, this iterates over council members + NFT owner. A real system needs a robust way to track ALL beneficiaries.
        address currentNFTOwner = discoveryNFTs.ownerOf(_discoveryNFTId);
        address[] memory potentialBeneficiaries = new address[](synthexCouncilMembers.length + 1);
        for(uint i=0; i < synthexCouncilMembers.length; i++) {
            potentialBeneficiaries[i] = synthexCouncilMembers[i];
        }
        potentialBeneficiaries[synthexCouncilMembers.length] = currentNFTOwner;


        for (uint i = 0; i < potentialBeneficiaries.length; i++) {
            address beneficiary = potentialBeneficiaries[i];
            uint256 share = ip.revenueSharePercentages[beneficiary];
            if (share > 0) {
                uint256 amountToDistribute = _amount * share / 10000;
                if (amountToDistribute > 0) {
                    ip.claimedRevenue[beneficiary] += amountToDistribute; // Accumulate for later claiming
                }
            }
        }
        emit IPRevenueDistributed(_discoveryNFTId, _amount);
    }

    /**
     * @dev Allows a beneficiary to claim their accumulated `fundingToken` revenue share for a Discovery NFT.
     * @param _discoveryNFTId The ID of the Discovery NFT.
     */
    function claimIPRevenue(uint256 _discoveryNFTId) external {
        DiscoveryIP storage ip = discoveryIPs[_discoveryNFTId];
        require(ip.id != 0, "SynthexLabs: Discovery IP does not exist");

        uint256 claimable = ip.claimedRevenue[msg.sender];
        require(claimable > 0, "SynthexLabs: No claimable revenue for sender");

        ip.claimedRevenue[msg.sender] = 0; // Reset before transfer
        require(fundingToken.transfer(msg.sender, claimable), "SynthexLabs: Failed to transfer IP revenue");
        emit IPRevenueClaimed(_discoveryNFTId, msg.sender, claimable);
    }


    // --- III. SYNTHEX REPUTATION & INCENTIVES (ERC-1155 SynPoints) ---

    /**
     * @dev Allows Synthex Council to manually award SynPoints (ERC-1155) to a recipient.
     *      Useful for rewarding off-chain contributions or as a governance tool.
     * @param _recipient The address to award SynPoints to.
     * @param _typeId The type of SynPoint (e.g., 1 for researcher, 2 for endorser, etc.).
     * @param _amount The amount of SynPoints to award.
     */
    function awardSynPointsExternal(address _recipient, uint256 _typeId, uint256 _amount) external onlySynthexCouncil {
        require(_amount > 0, "SynthexLabs: Amount must be positive");
        synPoints.mint(_recipient, _typeId, _amount, "");
        emit SynPointsAwarded(_recipient, _typeId, _amount);
    }

    /**
     * @dev Allows Synthex Council to manually burn SynPoints from a holder.
     *      Useful for penalizing malicious behavior or as a governance tool.
     * @param _holder The address to burn SynPoints from.
     * @param _typeId The type of SynPoint.
     * @param _amount The amount of SynPoints to burn.
     */
    function burnSynPointsExternal(address _holder, uint256 _typeId, uint256 _amount) external onlySynthexCouncil {
        require(_amount > 0, "SynthexLabs: Amount must be positive");
        synPoints.burn(_holder, _typeId, _amount);
        emit SynPointsBurned(_holder, _typeId, _amount);
    }

    /**
     * @dev Allows successful endorsers to claim their endorsement rewards.
     *      Rewards are a percentage of the proposal bond, distributed among endorsers.
     * @param _proposalId The ID of the proposal.
     */
    function claimEndorsementRewards(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.CompletedVerified, "SynthexLabs: Proposal not successfully verified");

        uint256 stakedAmount = proposal.endorsementStakes[msg.sender];
        require(stakedAmount > 0, "SynthexLabs: No active endorsement from sender for this proposal");

        // Calculate reward: a percentage of the researcher's initial bond, distributed among unique endorsers.
        uint256 rewardPerEndorser = proposalBondAmount * endorsementRewardPercentage / 100 / proposal.endorsers.length; // Simplified flat reward

        uint256 totalClaim = stakedAmount + rewardPerEndorser;

        // Clear the stake after claiming rewards to prevent double claims
        proposal.totalEndorsementStake -= stakedAmount;
        delete proposal.endorsementStakes[msg.sender];

        require(fundingToken.transfer(msg.sender, totalClaim), "SynthexLabs: Failed to transfer endorsement reward");

        emit EndorsementRewardsClaimed(_proposalId, msg.sender, totalClaim);
    }


    // --- IV. GOVERNANCE & PROTOCOL PARAMETERS ---

    /**
     * @dev Allows Synthex Council to update various numerical protocol parameters.
     *      This simulates a DAO-like governance where proposals are voted on off-chain
     *      and the council executes the approved changes.
     * @param _paramName The name of the parameter to update (e.g., "proposalBondAmount").
     * @param _newValue The new value for the parameter.
     */
    function updateNumericalProtocolParameter(bytes32 _paramName, uint256 _newValue) external onlySynthexCouncil {
        if (_paramName == "proposalBondAmount") {
            proposalBondAmount = _newValue;
        } else if (_paramName == "minSynthexScoreForFunding") {
            minSynthexScoreForFunding = _newValue;
        } else if (_paramName == "minEndorsementStakePercentage") {
            minEndorsementStakePercentage = _newValue;
        } else if (_paramName == "endorsementRewardPercentage") {
            endorsementRewardPercentage = _newValue;
        } else if (_paramName == "failedProposalPenaltyPercentage") {
            failedProposalPenaltyPercentage = _newValue;
        } else if (_paramName == "researcherRewardSynPoints") {
            researcherRewardSynPoints = _newValue;
        } else if (_paramName == "endorserRewardSynPoints") {
            endorserRewardSynPoints = _newValue;
        } else if (_paramName == "councilMemberSynPointsRequirement") {
            councilMemberSynPointsRequirement = _newValue;
        } else if (_paramName == "proposalEvaluationWindow") {
            proposalEvaluationWindow = _newValue;
        } else if (_paramName == "researchCompletionWindow") {
            researchCompletionWindow = _newValue;
        } else if (_paramName == "verificationWindow") {
            verificationWindow = _newValue;
        } else {
            revert("SynthexLabs: Unknown parameter name");
        }
        emit NumericalProtocolParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Allows Synthex Council to update the addresses of external integrated contracts.
     * @param _contractName The name of the contract to update (e.g., "synthexOracle", "fundingToken").
     * @param _newAddress The new address for the contract.
     */
    function setExternalContractAddress(bytes32 _contractName, address _newAddress) external onlySynthexCouncil {
        require(_newAddress != address(0), "SynthexLabs: Invalid address");
        if (_contractName == "synthexOracle") {
            synthexOracle = ISynthexOracle(_newAddress);
        } else if (_contractName == "fundingToken") {
            fundingToken = IERC20(_newAddress);
        } else if (_contractName == "synPoints") {
            synPoints = SynPoints(_newAddress);
        } else if (_contractName == "discoveryNFTs") {
            discoveryNFTs = DiscoveryNFTs(_newAddress);
        } else {
            revert("SynthexLabs: Unknown contract name");
        }
        emit ExternalContractAddressUpdated(_contractName, _newAddress);
    }

    /**
     * @dev Placeholder: Allows any user to propose a new address to become a Synthex Council member.
     *      In a full DAO, this would initiate an on-chain proposal and voting process.
     * @param _newMember The address of the candidate.
     */
    function proposeCouncilMember(address _newMember) external {
        require(_newMember != address(0), "SynthexLabs: Invalid address");
        // This would typically involve a staking mechanism or other barriers to proposal.
        // For this version, it just emits an event. Actual addition requires council vote.
        emit CouncilMemberProposed(_newMember);
    }

    /**
     * @dev Simplified function for Synthex Council members to vote on a proposed council member.
     *      If approved and the candidate meets SynPoints requirement, they are added.
     *      This acts as a direct 'add member' function for the council.
     * @param _candidate The address of the candidate.
     * @param _approve True to approve the candidate, false to reject.
     */
    function voteOnCouncilMember(address _candidate, bool _approve) external onlySynthexCouncil {
        require(_candidate != address(0), "SynthexLabs: Invalid address");

        if (_approve) {
            require(!isSynthexCouncilMember[_candidate], "SynthexLabs: Candidate is already a council member");
            // Example: check SynPoints balance for council eligibility (Type 0 for general SynPoints)
            require(synPoints.balanceOf(_candidate, 0) >= councilMemberSynPointsRequirement, "SynthexLabs: Candidate does not meet SynPoints requirement");
            isSynthexCouncilMember[_candidate] = true;
            synthexCouncilMembers.push(_candidate);
            emit CouncilMemberAdded(_candidate);
        }
        emit CouncilMemberVoted(msg.sender, _candidate, _approve);
    }

    /**
     * @dev Allows Synthex Council to withdraw funds from the contract treasury for protocol operations.
     *      This should be used for expenses approved through off-chain DAO governance.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of `fundingToken` to withdraw.
     */
    function withdrawFromTreasury(address _recipient, uint256 _amount) external onlySynthexCouncil {
        require(_amount > 0, "SynthexLabs: Amount must be positive");
        require(fundingToken.balanceOf(address(this)) >= _amount, "SynthexLabs: Insufficient balance in treasury");
        require(fundingToken.transfer(_recipient, _amount), "SynthexLabs: Failed to withdraw from treasury");

        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- VIEW FUNCTIONS ---

    function getProposalEndorsementStake(uint256 _proposalId, address _endorser) external view proposalExists(_proposalId) returns (uint256) {
        return proposals[_proposalId].endorsementStakes[_endorser];
    }

    function getDiscoveryIPRevenueShare(uint256 _discoveryNFTId, address _beneficiary) external view returns (uint256) {
        require(discoveryIPs[_discoveryNFTId].id != 0, "SynthexLabs: Discovery IP does not exist");
        return discoveryIPs[_discoveryNFTId].revenueSharePercentages[_beneficiary];
    }

    function getDiscoveryIPClaimableRevenue(uint256 _discoveryNFTId, address _beneficiary) external view returns (uint256) {
        require(discoveryIPs[_discoveryNFTId].id != 0, "SynthexLabs: Discovery IP does not exist");
        return discoveryIPs[_discoveryNFTId].claimedRevenue[_beneficiary];
    }

    function getSynthexCouncilMembers() external view returns (address[] memory) {
        return synthexCouncilMembers;
    }
}

// --- MOCK ORACLE (for demonstration purposes) ---
// In a real scenario, this would be a Chainlink Functions consumer or a decentralized oracle network.
// This mock contract simulates the `ISynthexOracle` interface.
contract MockSynthexOracle is ISynthexOracle {
    mapping(uint256 => uint256) public proposalScores; // For manually setting scores for testing

    /**
     * @dev Simulates an AI's evaluation by returning a pseudo-random score based on proposal data.
     *      In a production environment, this would involve complex off-chain computations.
     * @param _proposalId The ID of the proposal.
     * @param _ipfsHash The IPFS hash of the proposal details.
     * @return A simulated Synthex Score (0-99).
     */
    function getSynthexScore(uint256 _proposalId, string calldata _ipfsHash) external view returns (uint256) {
        // Allow pre-set scores for specific proposals, otherwise generate pseudo-random
        if (proposalScores[_proposalId] > 0) {
            return proposalScores[_proposalId];
        }
        // Pseudo-random score for demonstration
        bytes32 hash = keccak256(abi.encodePacked(_proposalId, _ipfsHash, block.timestamp));
        return uint256(hash) % 100; // Score between 0-99
    }

    /**
     * @dev For testing: Allows setting a specific Synthex Score for a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _score The score to set (0-99).
     */
    function setProposalScore(uint256 _proposalId, uint256 _score) external {
        require(_score < 100, "Score must be less than 100");
        proposalScores[_proposalId] = _score;
    }
}
```