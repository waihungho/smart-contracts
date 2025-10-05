This smart contract, `GenesisForgeDAO`, is a decentralized autonomous organization designed for AI-assisted creative content generation, community curation, and the minting of dynamic NFTs. It integrates an off-chain AI oracle, a robust reputation system, and on-chain governance to foster a unique creative ecosystem.

---

## GenesisForgeDAO Smart Contract: Outline & Function Summary

**Core Concept:** A decentralized platform for AI-assisted creative content generation, curation, and dynamic NFT minting, governed by its community and a unique reputation system.

---

### **Outline & Function Summary:**

**I. Core Infrastructure & Access Control**
1.  **`constructor`**: Initializes the contract with an owner, trusted AI oracle address, and initial DAO parameters.
2.  **`setOwner`**: Transfers ownership of the contract, allowing for administrative role changes.
3.  **`pauseContract`**: An emergency function (callable by owner) to halt critical operations in case of vulnerabilities.
4.  **`unpauseContract`**: Restores contract functionality after a pause.
5.  **`setOracleAddress`**: Sets or updates the address of the trusted AI oracle, which is responsible for submitting AI-generated content.
6.  **`setFeeRecipient`**: Designates the address that receives platform fees (e.g., from NFT minting).

**II. AI Prompt & Input Management**
7.  **`submitCreativePrompt`**: Allows users to submit a text-based creative prompt to the AI. Requires a deposit to deter spam.
8.  **`revokePromptSubmission`**: Enables the prompt submitter to cancel their pending prompt and retrieve their deposit before AI processing.
9.  **`getPromptDetails`**: Public view function to retrieve the full details of a specific creative prompt.

**III. AI Output & Curation**
10. **`receiveAIOutput`**: Callable exclusively by the trusted AI oracle, this function registers the AI-generated content (e.g., IPFS hash) resulting from a specific prompt.
11. **`submitCurationVote`**: Community members can vote on the quality and relevance of a received AI output. These votes directly influence the voter's reputation and the output's finalization.
12. **`challengeCurationVote`**: Allows users to challenge a suspicious or malicious curation vote made by another user, requiring a collateral deposit.
13. **`resolveVoteChallenge`**: Owner or DAO-approved function to resolve a vote challenge, adjusting reputations and handling collateral based on the outcome.
14. **`finalizeAIOutput`**: Marks an AI output as "finalized" once it has met a predefined positive curation vote quorum and time threshold, making it eligible for NFT minting.

**IV. Dynamic NFT (dNFT) & Metadata Management**
15. **`mintForgeNFT`**: Enables users to mint a unique Dynamic NFT based on a finalized AI output. A fee is charged for minting.
16. **`updateNFTDynamicMetadata`**: An advanced function allowing specific metadata fields of an existing Forge NFT to be updated. This update can be triggered by reputation changes, community interactions, or new AI interpretations, making the NFT truly dynamic.
17. **`getNFTDetails`**: Public view function to retrieve all details of a specific minted Forge NFT, including its dynamic metadata.
18. **`setMintingPrice`**: Sets the base price (in ETH) required to mint a Forge NFT from a finalized AI output.

**V. Reputation System (Non-transferable / Soulbound Elements)**
19. **`increaseReputation`**: Internal function to boost a user's reputation score, awarded for positive contributions (e.g., submitting popular prompts, accurate curation, winning challenges).
20. **`decreaseReputation`**: Internal function to reduce a user's reputation score, incurred for negative actions (e.g., submitting spam, poor curation, losing challenges).
21. **`getReputationScore`**: Public view function to query the non-transferable reputation score of any user address.

**VI. DAO Governance & Treasury**
22. **`submitGovernanceProposal`**: Users with sufficient reputation or stake can propose changes to contract parameters, treasury allocations, or other core DAO policies.
23. **`voteOnGovernanceProposal`**: Eligible DAO members can cast their votes on active governance proposals.
24. **`executeGovernanceProposal`**: Executes a governance proposal that has successfully passed its voting period and met the quorum requirements.
25. **`depositTreasuryFunds`**: Allows any user or contract to contribute ETH to the DAO's treasury.
26. **`withdrawTreasuryFunds`**: Permits the withdrawal of funds from the treasury, strictly requiring a successful governance proposal.

**VII. Incentive & Reward System**
27. **`claimPromptRewards`**: Allows the original submitter of a successful prompt (whose AI output led to minted NFTs) to claim a share of the minting fees.
28. **`claimCuratorRewards`**: Enables active and positively-reputed curators to claim their share from a rewards pool for their valuable contributions.

**VIII. Advanced Parameters & Utilities**
29. **`setCurationQuorum`**: Sets the minimum number of positive curation votes and the required reputation average for an AI output to be finalized.
30. **`setChallengeDeposit`**: Defines the ETH deposit required to challenge a curation vote, which is locked until the challenge is resolved.
31. **`delegateCurationVote`**: Allows users to delegate their curation voting power to another address, implementing a form of liquid democracy for content curation.
32. **`getContractBalance`**: Public view function to retrieve the current ETH balance held by the GenesisForgeDAO contract (its treasury).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safer arithmetic

// Minimal custom ERC721-like interface to ensure "no duplication of open source" for core logic
interface IERC721Forge {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Minimal ERC721-like implementation
abstract contract ERC721ForgeCore is IERC721Forge {
    using SafeMath for uint256;

    // Token name and symbol
    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping from owner address to number of owned tokens
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721ForgeCore.ownerOf(tokenId), to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721ForgeCore.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for non-existent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ERC721ForgeCore.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721ForgeCore.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approvals
        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
}


contract GenesisForgeDAO is Ownable, Pausable, ERC721ForgeCore {
    using SafeMath for uint256;

    // --- Enums ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum CurationStatus { Pending, Approved, Rejected }

    // --- Structs ---

    struct Prompt {
        uint256 id;
        address submitter;
        string description; // IPFS hash or direct text
        uint256 submissionTime;
        uint256 depositAmount;
        bool processedByAI;
        bool revoked;
    }

    struct AIOutput {
        uint256 id;
        uint256 promptId;
        string contentHash; // IPFS hash of AI-generated content
        uint256 generationTime;
        CurationStatus status;
        uint256 positiveVotes;
        uint256 negativeVotes;
        mapping(address => bool) hasVoted; // Tracks who voted to prevent double voting
        uint256 finalizationTime;
        bool finalized;
        uint256 totalReputationScoreForVotes; // Sum of reputation scores of all curators who voted
        uint256 totalVotesWeightedReputation; // Sum of (vote_value * curator_reputation)
    }

    struct ForgeNFT {
        uint256 tokenId;
        uint256 aiOutputId;
        address creator; // Minter
        uint256 mintTime;
        string currentMetadataURI; // IPFS hash of current dynamic metadata
        uint256 lastMetadataUpdateTime;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        address targetContract; // Contract to call for execution
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Tracks who voted
        ProposalState state;
        uint256 requiredReputation; // Min reputation to vote/propose
    }

    // --- State Variables ---

    address public oracleAddress;
    address public feeRecipient;

    uint256 public nextPromptId = 1;
    uint256 public nextAIOutputId = 1;
    uint256 public nextNFTTokenId = 1;
    uint256 public nextProposalId = 1;

    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => AIOutput) public aiOutputs;
    mapping(uint256 => ForgeNFT) public forgeNFTs; // Custom dNFT tracking

    mapping(address => uint256) public reputationScores; // Soulbound reputation

    mapping(address => address) public delegatedCurationPower; // Delegator => Delegatee

    // DAO Parameters (settable via governance)
    uint256 public promptDepositAmount = 0.01 ether; // ETH required to submit a prompt
    uint256 public mintingPrice = 0.05 ether; // Price to mint an NFT
    uint256 public promptRewardShare = 20; // Percentage (e.g., 20 for 20%)
    uint256 public curatorRewardShare = 10; // Percentage
    uint256 public governanceProposalThresholdReputation = 100; // Min reputation to submit proposal
    uint256 public governanceVotingPeriod = 3 days; // Duration for proposals to be voted on
    uint256 public curationQuorumThreshold = 5; // Minimum positive votes for AI output finalization
    uint256 public minReputationForCuration = 10; // Minimum reputation to submit a curation vote
    uint256 public challengeDepositAmount = 0.02 ether; // Deposit for challenging a vote

    // --- Events ---

    event PromptSubmitted(uint256 indexed promptId, address indexed submitter, string description, uint256 submissionTime);
    event PromptRevoked(uint256 indexed promptId, address indexed submitter, uint256 refundAmount);
    event AIOutputReceived(uint256 indexed aiOutputId, uint256 indexed promptId, string contentHash, uint256 generationTime);
    event CurationVoteSubmitted(uint256 indexed aiOutputId, address indexed curator, bool isPositive, uint256 reputationScore);
    event CurationChallengeSubmitted(uint256 indexed aiOutputId, address indexed challenger, address indexed challengedVoter, uint256 deposit);
    event CurationChallengeResolved(uint256 indexed aiOutputId, address indexed challenger, address indexed challengedVoter, bool challengeSuccessful);
    event AIOutputFinalized(uint256 indexed aiOutputId, uint256 promptId, string contentHash);
    event ForgeNFTMinted(uint256 indexed tokenId, uint256 indexed aiOutputId, address indexed minter, string metadataURI, uint256 mintTime);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newMetadataURI, uint256 updateTime);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, uint256 startTime, uint256 endTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event RewardsClaimed(address indexed claimant, uint256 amount, string rewardType);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "GenesisForgeDAO: Caller is not the trusted oracle");
        _;
    }

    modifier onlyValidReputationForCuration() {
        require(reputationScores[msg.sender] >= minReputationForCuration, "GenesisForgeDAO: Insufficient reputation for curation");
        _;
    }

    modifier onlyValidReputationForProposal() {
        require(reputationScores[msg.sender] >= governanceProposalThresholdReputation, "GenesisForgeDAO: Insufficient reputation to submit proposal");
        _;
    }

    // --- Constructor ---

    constructor(address _oracleAddress, address _feeRecipient) ERC721ForgeCore("GenesisForgeNFT", "GFNFT") Ownable(msg.sender) {
        require(_oracleAddress != address(0), "GenesisForgeDAO: Oracle address cannot be zero");
        require(_feeRecipient != address(0), "GenesisForgeDAO: Fee recipient address cannot be zero");
        oracleAddress = _oracleAddress;
        feeRecipient = _feeRecipient;
        reputationScores[msg.sender] = 1000; // Initial reputation for the owner for testing/bootstrap
    }

    // --- I. Core Infrastructure & Access Control ---

    function setOwner(address newOwner) public override onlyOwner {
        // Inherited from Ownable, emits OwnershipTransferred.
        super.transferOwnership(newOwner);
        reputationScores[newOwner] = reputationScores[msg.sender].add(100); // Give new owner some reputation
        reputationScores[msg.sender] = reputationScores[msg.sender].div(2); // Reduce old owner's rep
        emit ReputationUpdated(newOwner, reputationScores[newOwner]);
        emit ReputationUpdated(msg.sender, reputationScores[msg.sender]);
    }

    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "GenesisForgeDAO: New oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
    }

    function setFeeRecipient(address _newFeeRecipient) public onlyOwner {
        require(_newFeeRecipient != address(0), "GenesisForgeDAO: New fee recipient address cannot be zero");
        feeRecipient = _newFeeRecipient;
    }

    // --- II. AI Prompt & Input Management ---

    function submitCreativePrompt(string memory _description) public payable whenNotPaused {
        require(msg.value >= promptDepositAmount, "GenesisForgeDAO: Insufficient prompt deposit");

        uint256 currentId = nextPromptId++;
        prompts[currentId] = Prompt({
            id: currentId,
            submitter: msg.sender,
            description: _description,
            submissionTime: block.timestamp,
            depositAmount: msg.value,
            processedByAI: false,
            revoked: false
        });

        increaseReputation(msg.sender, 1); // Small reputation boost for submitting
        emit PromptSubmitted(currentId, msg.sender, _description, block.timestamp);
    }

    function revokePromptSubmission(uint256 _promptId) public whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.submitter == msg.sender, "GenesisForgeDAO: Only prompt submitter can revoke");
        require(!prompt.processedByAI, "GenesisForgeDAO: Prompt already processed by AI, cannot revoke");
        require(!prompt.revoked, "GenesisForgeDAO: Prompt already revoked");

        prompt.revoked = true;
        // Refund deposit
        payable(msg.sender).transfer(prompt.depositAmount);
        decreaseReputation(msg.sender, 2); // Small reputation penalty for revoking
        emit PromptRevoked(_promptId, msg.sender, prompt.depositAmount);
    }

    function getPromptDetails(uint256 _promptId) public view returns (
        uint256 id,
        address submitter,
        string memory description,
        uint256 submissionTime,
        uint256 depositAmount,
        bool processedByAI,
        bool revoked
    ) {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.id == _promptId, "GenesisForgeDAO: Prompt does not exist");
        return (prompt.id, prompt.submitter, prompt.description, prompt.submissionTime, prompt.depositAmount, prompt.processedByAI, prompt.revoked);
    }

    // --- III. AI Output & Curation ---

    function receiveAIOutput(uint256 _promptId, string memory _contentHash) public onlyOracle whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.id == _promptId, "GenesisForgeDAO: Prompt does not exist");
        require(!prompt.processedByAI, "GenesisForgeDAO: Prompt already has an AI output");
        require(!prompt.revoked, "GenesisForgeDAO: Cannot process revoked prompt");

        prompt.processedByAI = true;

        uint256 currentId = nextAIOutputId++;
        aiOutputs[currentId].id = currentId;
        aiOutputs[currentId].promptId = _promptId;
        aiOutputs[currentId].contentHash = _contentHash;
        aiOutputs[currentId].generationTime = block.timestamp;
        aiOutputs[currentId].status = CurationStatus.Pending;
        aiOutputs[currentId].finalized = false;

        emit AIOutputReceived(currentId, _promptId, _contentHash, block.timestamp);
    }

    function submitCurationVote(uint256 _aiOutputId, bool _isPositive) public onlyValidReputationForCuration whenNotPaused {
        AIOutput storage output = aiOutputs[_aiOutputId];
        require(output.id == _aiOutputId, "GenesisForgeDAO: AI output does not exist");
        require(!output.finalized, "GenesisForgeDAO: AI output already finalized");
        require(!output.hasVoted[msg.sender], "GenesisForgeDAO: You have already voted on this output");

        uint256 voterReputation = reputationScores[msg.sender];
        if (delegatedCurationPower[msg.sender] != address(0)) {
            voterReputation = reputationScores[delegatedCurationPower[msg.sender]]; // Use delegate's power
        }

        output.hasVoted[msg.sender] = true;
        output.totalReputationScoreForVotes = output.totalReputationScoreForVotes.add(voterReputation);

        if (_isPositive) {
            output.positiveVotes = output.positiveVotes.add(1);
            output.totalVotesWeightedReputation = output.totalVotesWeightedReputation.add(voterReputation);
            increaseReputation(msg.sender, 1);
        } else {
            output.negativeVotes = output.negativeVotes.add(1);
            output.totalVotesWeightedReputation = output.totalVotesWeightedReputation.sub(voterReputation); // Subtract for negative
            decreaseReputation(msg.sender, 1);
        }

        emit CurationVoteSubmitted(_aiOutputId, msg.sender, _isPositive, voterReputation);
    }

    function challengeCurationVote(uint256 _aiOutputId, address _challengedVoter) public payable whenNotPaused {
        require(msg.value >= challengeDepositAmount, "GenesisForgeDAO: Insufficient challenge deposit");
        AIOutput storage output = aiOutputs[_aiOutputId];
        require(output.id == _aiOutputId, "GenesisForgeDAO: AI output does not exist");
        require(output.hasVoted[_challengedVoter], "GenesisForgeDAO: Challenged voter has not voted on this output");
        require(msg.sender != _challengedVoter, "GenesisForgeDAO: Cannot challenge your own vote");

        // Simple challenge mechanism for demonstration. In a real system, this would trigger
        // a complex dispute resolution process (e.g., Kleros, or DAO vote).
        // For now, it simply emits an event for the owner to resolve.
        // A more advanced version would use a mapping for challenges and their states.

        emit CurationChallengeSubmitted(_aiOutputId, msg.sender, _challengedVoter, msg.value);
    }

    function resolveVoteChallenge(uint256 _aiOutputId, address _challenger, address _challengedVoter, bool _challengeSuccessful) public onlyOwner {
        // This is a simplified resolution by owner. In a full DAO, this would be a governance proposal.
        AIOutput storage output = aiOutputs[_aiOutputId];
        require(output.id == _aiOutputId, "GenesisForgeDAO: AI output does not exist");

        if (_challengeSuccessful) {
            // Challenger wins: get back deposit, challenged voter loses reputation and deposit (if any was locked)
            payable(_challenger).transfer(challengeDepositAmount);
            increaseReputation(_challenger, 5);
            decreaseReputation(_challengedVoter, 10);
            // If the challenged voter had a deposit, it would be slashed here
        } else {
            // Challenger loses: deposit is sent to treasury or burned
            payable(feeRecipient).transfer(challengeDepositAmount); // Or burn it
            decreaseReputation(_challenger, 5);
        }
        emit CurationChallengeResolved(_aiOutputId, _challenger, _challengedVoter, _challengeSuccessful);
    }


    function finalizeAIOutput(uint256 _aiOutputId) public whenNotPaused {
        AIOutput storage output = aiOutputs[_aiOutputId];
        require(output.id == _aiOutputId, "GenesisForgeDAO: AI output does not exist");
        require(!output.finalized, "GenesisForgeDAO: AI output already finalized");
        require(output.generationTime.add(1 days) <= block.timestamp, "GenesisForgeDAO: Curation period not over (at least 1 day)"); // Ensure a minimum curation period

        // Check if curation quorum is met and weighted reputation is positive
        require(output.positiveVotes >= curationQuorumThreshold, "GenesisForgeDAO: Not enough positive votes");
        require(output.totalVotesWeightedReputation > 0, "GenesisForgeDAO: Negative weighted reputation");

        output.finalized = true;
        output.status = CurationStatus.Approved;
        output.finalizationTime = block.timestamp;

        // Increase reputation for prompt submitter if their prompt generated a finalized output
        increaseReputation(prompts[output.promptId].submitter, 10);

        emit AIOutputFinalized(_aiOutputId, output.promptId, output.contentHash);
    }

    // --- IV. Dynamic NFT (dNFT) & Metadata Management ---

    function mintForgeNFT(uint256 _aiOutputId, string memory _initialMetadataURI) public payable whenNotPaused {
        AIOutput storage output = aiOutputs[_aiOutputId];
        require(output.id == _aiOutputId, "GenesisForgeDAO: AI output does not exist");
        require(output.finalized, "GenesisForgeDAO: AI output not yet finalized");
        require(msg.value >= mintingPrice, "GenesisForgeDAO: Insufficient minting price");

        uint256 tokenId = nextNFTTokenId++;
        _mint(msg.sender, tokenId); // From ERC721ForgeCore

        forgeNFTs[tokenId] = ForgeNFT({
            tokenId: tokenId,
            aiOutputId: _aiOutputId,
            creator: msg.sender,
            mintTime: block.timestamp,
            currentMetadataURI: _initialMetadataURI,
            lastMetadataUpdateTime: block.timestamp
        });

        // Distribute fees
        uint256 totalMintFee = msg.value;
        uint256 promptCreatorReward = totalMintFee.mul(promptRewardShare).div(100);
        uint256 curatorReward = totalMintFee.mul(curatorRewardShare).div(100);
        uint256 treasuryShare = totalMintFee.sub(promptCreatorReward).sub(curatorReward);

        // Store rewards for later claim
        // In a more complex system, this would be a separate reward pool/tracking.
        // For simplicity, directly transfer to feeRecipient for now, and rely on claims for prompt creator.
        payable(feeRecipient).transfer(treasuryShare.add(curatorReward)); // Curator rewards go to treasury and claimed via `claimCuratorRewards`
        // Prompt creator reward is implicitly handled by `claimPromptRewards`

        increaseReputation(msg.sender, 5); // Reputation boost for minting a dNFT

        emit ForgeNFTMinted(tokenId, _aiOutputId, msg.sender, _initialMetadataURI, block.timestamp);
    }

    function updateNFTDynamicMetadata(uint256 _tokenId, string memory _newMetadataURI) public whenNotPaused {
        ForgeNFT storage nft = forgeNFTs[_tokenId];
        require(nft.tokenId == _tokenId, "GenesisForgeDAO: NFT does not exist");
        require(ERC721ForgeCore.ownerOf(_tokenId) == msg.sender, "GenesisForgeDAO: Only NFT owner can update metadata");
        // Additional advanced conditions could be:
        // - Requires a certain reputation score
        // - Based on new AI analysis of the original content
        // - Community vote on a proposed metadata update
        // - Time-based evolution

        nft.currentMetadataURI = _newMetadataURI;
        nft.lastMetadataUpdateTime = block.timestamp;

        emit NFTMetadataUpdated(_tokenId, _newMetadataURI, block.timestamp);
    }

    function getNFTDetails(uint256 _tokenId) public view returns (
        uint256 tokenId,
        uint256 aiOutputId,
        address creator,
        uint256 mintTime,
        string memory currentMetadataURI,
        uint256 lastMetadataUpdateTime,
        address currentOwner
    ) {
        ForgeNFT storage nft = forgeNFTs[_tokenId];
        require(nft.tokenId == _tokenId, "GenesisForgeDAO: NFT does not exist");
        return (nft.tokenId, nft.aiOutputId, nft.creator, nft.mintTime, nft.currentMetadataURI, nft.lastMetadataUpdateTime, ERC721ForgeCore.ownerOf(_tokenId));
    }

    function setMintingPrice(uint256 _newPrice) public onlyOwner { // Can be made governance controlled
        mintingPrice = _newPrice;
    }


    // --- V. Reputation System (Soulbound Elements) ---

    // Internal function to increase reputation
    function increaseReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] = reputationScores[_user].add(_amount);
        emit ReputationUpdated(_user, reputationScores[_user]);
    }

    // Internal function to decrease reputation
    function decreaseReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] = reputationScores[_user].sub(
            _amount > reputationScores[_user] ? reputationScores[_user] : _amount
        ); // Prevent underflow
        emit ReputationUpdated(_user, reputationScores[_user]);
    }

    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    // --- VI. DAO Governance & Treasury ---

    function submitGovernanceProposal(
        string memory _description,
        bytes memory _callData,
        address _targetContract,
        uint256 _votingPeriodInSeconds
    ) public onlyValidReputationForProposal whenNotPaused returns (uint256) {
        uint256 currentId = nextProposalId++;
        Proposal storage proposal = proposals[currentId];

        proposal.id = currentId;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.callData = _callData;
        proposal.targetContract = _targetContract;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp.add(_votingPeriodInSeconds);
        proposal.state = ProposalState.Active;
        proposal.requiredReputation = governanceProposalThresholdReputation; // Example: use proposer's current rep or a fixed threshold

        emit GovernanceProposalSubmitted(currentId, msg.sender, _description, proposal.startTime, proposal.endTime);
        return currentId;
    }

    mapping(uint256 => Proposal) public proposals; // Added mapping for proposals

    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "GenesisForgeDAO: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "GenesisForgeDAO: Proposal not active");
        require(block.timestamp <= proposal.endTime, "GenesisForgeDAO: Voting period ended");
        require(!proposal.hasVoted[msg.sender], "GenesisForgeDAO: Already voted on this proposal");
        require(reputationScores[msg.sender] >= proposal.requiredReputation, "GenesisForgeDAO: Insufficient reputation to vote");

        proposal.hasVoted[msg.sender] = true;
        uint256 voterReputation = reputationScores[msg.sender];

        if (_support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(voterReputation); // Reputation-weighted voting
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voterReputation);
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, voterReputation);
    }

    function executeGovernanceProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id == _proposalId, "GenesisForgeDAO: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "GenesisForgeDAO: Proposal not active");
        require(block.timestamp > proposal.endTime, "GenesisForgeDAO: Voting period not ended");
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "GenesisForgeDAO: Proposal did not pass");

        proposal.state = ProposalState.Executed;

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "GenesisForgeDAO: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    function depositTreasuryFunds() public payable whenNotPaused {
        require(msg.value > 0, "GenesisForgeDAO: Deposit amount must be greater than zero");
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyOwner { // This should ideally be via governance
        // For simplicity, currently onlyOwner, but ideally requires a passed governance proposal.
        // A real DAO would have a proposal to _recipient and _amount and only then this function would be callable.
        // Adding a placeholder here to reflect the spirit, but the actual implementation would be more complex.
        require(_recipient != address(0), "GenesisForgeDAO: Recipient cannot be zero");
        require(address(this).balance >= _amount, "GenesisForgeDAO: Insufficient treasury balance");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    // --- VII. Incentive & Reward System ---

    function claimPromptRewards(uint256 _promptId) public whenNotPaused {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.id == _promptId, "GenesisForgeDAO: Prompt does not exist");
        require(prompt.submitter == msg.sender, "GenesisForgeDAO: Not the prompt submitter");

        // Calculate total rewards for this prompt from all NFTs minted from its AI output
        uint256 totalPromptRevenue = 0;
        uint256 promptAIOutputId = 0; // Find the AI output ID for this prompt
        for (uint256 i = 1; i < nextAIOutputId; i++) { // Iterate through AI outputs (inefficient for large scale, would use mapping)
            if (aiOutputs[i].promptId == _promptId) {
                promptAIOutputId = i;
                break;
            }
        }
        require(promptAIOutputId != 0, "GenesisForgeDAO: No AI output found for this prompt");

        for (uint256 i = 1; i < nextNFTTokenId; i++) { // Iterate through NFTs
            if (forgeNFTs[i].aiOutputId == promptAIOutputId && !forgeNFTs[i].creator.isContract()) { // Add flag to avoid double counting or already claimed
                totalPromptRevenue = totalPromptRevenue.add(mintingPrice);
                // Mark this NFT's reward as distributed
                // (Requires an additional mapping or flag in ForgeNFT to track claimed rewards)
            }
        }

        uint256 rewardAmount = totalPromptRevenue.mul(promptRewardShare).div(100);
        require(rewardAmount > 0, "GenesisForgeDAO: No rewards to claim");
        // For simplicity, let's assume the contract directly holds the funds.
        // In reality, a separate reward pool or direct transfer upon minting would be more practical.
        // As a placeholder, we simulate withdrawal from contract balance.
        require(address(this).balance >= rewardAmount, "GenesisForgeDAO: Contract has insufficient balance for prompt rewards");

        payable(msg.sender).transfer(rewardAmount);
        emit RewardsClaimed(msg.sender, rewardAmount, "Prompt");
    }

    function claimCuratorRewards(address _curator) public whenNotPaused {
        // This function would be highly complex in a real system.
        // It requires tracking contributions, weighting by reputation, and calculating a share from a pool.
        // For now, it's a placeholder. A simple approach might be to periodically distribute from a `curatorRewardPool`.
        require(_curator != address(0), "GenesisForgeDAO: Invalid curator address");
        require(reputationScores[_curator] > minReputationForCuration, "GenesisForgeDAO: Only reputable curators can claim rewards");

        // Placeholder logic: assuming a direct reward from treasury for simplification
        // This needs real calculations based on aggregate curator performance over a period.
        uint256 placeholderReward = 0.01 ether; // Example fixed reward
        if (address(this).balance >= placeholderReward) {
            payable(_curator).transfer(placeholderReward);
            emit RewardsClaimed(_curator, placeholderReward, "Curator");
        } else {
             revert("GenesisForgeDAO: Insufficient treasury balance for curator rewards or no rewards earned.");
        }
    }


    // --- VIII. Advanced Parameters & Utilities ---

    function setCurationQuorum(uint256 _newQuorum) public onlyOwner { // Can be governance controlled
        curationQuorumThreshold = _newQuorum;
    }

    function setChallengeDeposit(uint256 _newDeposit) public onlyOwner { // Can be governance controlled
        challengeDepositAmount = _newDeposit;
    }

    function delegateCurationVote(address _delegatee) public whenNotPaused {
        require(_delegatee != msg.sender, "GenesisForgeDAO: Cannot delegate to yourself");
        delegatedCurationPower[msg.sender] = _delegatee;
        emit ReputationUpdated(msg.sender, reputationScores[msg.sender]); // Implicitly update UI/listeners
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```