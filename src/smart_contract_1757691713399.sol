This smart contract, **EtherealCanvas**, introduces a novel approach to collaborative, decentralized generative art creation and evolution. It combines dynamic NFTs, AI-assisted curation (via an oracle), a gamified reputation system, and a multi-token economy to create a living, evolving digital art ecosystem.

The core idea is that "Evolution Fragments" (NFTs) are not static images but rather mathematical seeds or parameter sets for generative art. These fragments can be evolved over time through community proposals and a unique voting mechanism, guided by an AI oracle's quality assessment.

---

## EtherealCanvas: A Generative Art Evolution Protocol

**Outline:**

1.  **Core Contracts & Standards:**
    *   `EtherealFragment` (ERC721): The dynamic generative art NFT.
    *   `CreativeSpark` (ERC20): The utility token for interaction, proposals, and rewards.
    *   `CuratorialInfluence` (ERC20): A non-transferable, soulbound-like token representing reputation and voting power.
2.  **Evolution Fragment Structure:** Details of the NFT's state, including its current parameters, generation, and evolution history.
3.  **Evolution Proposal Mechanism:**
    *   Users submit proposals with new generative art parameters and a `CreativeSpark` fee.
    *   An `AIOracle` (simulated for this contract) provides a quality score.
    *   Community members vote using `CuratorialInfluence`.
    *   Successful proposals evolve the NFT, burning and distributing `CreativeSpark`.
4.  **Reputation System (`CuratorialInfluence`):**
    *   Earned through successful contributions and impactful votes.
    *   Weights voting power, making the governance more meritocratic.
5.  **Catalyst Pool & Economy:**
    *   `CreativeSpark` tokens are bought with ETH, funding the `CatalystPool`.
    *   The pool covers AI oracle costs and rewards top contributors.
    *   Fees and burn mechanisms manage `CreativeSpark` supply.
6.  **Access Control & Security:** Roles for Owner, AI Oracle, and general users.

---

**Function Summary:**

**A. Initialization & Setup (Admin Functions):**
1.  `constructor`: Deploys child tokens, sets initial owner, AI oracle, and fees.
2.  `setAIOracleAddress`: Updates the trusted AI Oracle address.
3.  `setEvolutionFee`: Sets the `CreativeSpark` fee for submitting proposals.
4.  `setMinAIQualityScore`: Defines the minimum AI score a proposal needs to be considered.
5.  `setVotingPeriodDuration`: Sets the duration for proposal voting.
6.  `setCuratorialInfluenceAwardRate`: Defines how much influence is awarded per successful action.
7.  `pauseContract`: Pauses contract operations in emergencies.
8.  `unpauseContract`: Unpauses contract operations.

**B. EtherealFragment (NFT) Management:**
9.  `mintInitialFragment`: Mints the first generation of an `EtherealFragment`.
10. `getFragmentDetails`: Retrieves detailed information about an `EtherealFragment`.
11. `getTokenURI`: Standard ERC721 function; generates dynamic metadata URI.
12. `getFragmentEvolutionHistory`: Returns the chronological list of parameter hashes for a fragment.
13. `transferFragment`: Custom function for transferring fragments (standard ERC721 transfer functions like `safeTransferFrom` are inherited but not explicitly listed here).

**C. CreativeSpark (ERC20) Management:**
14. `buyCreativeSparkTokens`: Users can exchange ETH for `CreativeSpark` tokens.
15. `burnCreativeSparkTokens`: Allows users to burn their `CreativeSpark` tokens.
16. `distributeSparkRewards`: Admin/internal function to distribute `CreativeSpark` to contributors.
17. `claimSparkRewards`: Users claim pending `CreativeSpark` rewards.

**D. Evolution Proposals & Governance:**
18. `submitEvolutionProposal`: Initiates a proposal for an NFT's evolution, paying a `CreativeSpark` fee.
19. `requestAIQualityScore`: **(AI Oracle Only)** The AI Oracle provides a quality score for a pending proposal.
20. `castCuratorialVote`: Users vote on proposals using their `CuratorialInfluence`.
21. `executeSuccessfulProposal`: Applies the changes of a successfully voted and AI-approved proposal to the target `EtherealFragment`.
22. `getProposalDetails`: Retrieves comprehensive details of a specific proposal.
23. `getProposalsByFragment`: Lists all proposals related to a particular fragment.
24. `withdrawFailedProposalFunds`: Allows proposers to retrieve their `CreativeSpark` fee if their proposal fails or expires.

**E. CuratorialInfluence (Reputation) Management:**
25. `getCuratorialInfluence`: Returns the `CuratorialInfluence` balance for an address.
26. `awardCuratorialInfluence`: Internal/admin function to grant `CuratorialInfluence` for specific achievements.
27. `stakeSparkForInfluenceBoost`: Users can temporarily stake `CreativeSpark` to gain a boost in `CuratorialInfluence`.

**F. Catalyst Pool & Treasury:**
28. `fundCatalystPool`: Allows anyone to donate ETH to the `CatalystPool`.
29. `withdrawFromCatalystPool`: **(Owner Only)** Withdraws funds from the `CatalystPool`.
30. `distributeCatalystRewards`: **(Owner Only)** Distributes ETH rewards from the `CatalystPool` to deserving addresses.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Custom ERC20 for Creative Spark ---
contract CreativeSpark is ERC20, Ownable {
    constructor(address initialOwner) ERC20("CreativeSpark", "CRSPK") Ownable(initialOwner) {}

    // Mint tokens specifically for the protocol's use (e.g., initial supply, rewards)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Allow burning of tokens by holders
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

// --- Custom ERC20 for Curatorial Influence (Non-transferable) ---
contract CuratorialInfluence is ERC20, Ownable {
    constructor(address initialOwner) ERC20("CuratorialInfluence", "CINF") Ownable(initialOwner) {}

    // Override transfer functions to prevent transfers
    function transfer(address, uint256) public pure override returns (bool) {
        revert("CuratorialInfluence is non-transferable.");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("CuratorialInfluence is non-transferable.");
    }

    // Function to award influence by the owner (or authorized minter)
    function award(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Function to decay influence (can be called by owner or automated)
    function decay(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

// --- Main EtherealCanvas Contract ---
contract EtherealCanvas is ERC721, ERC721Burnable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Token contracts
    CreativeSpark public creativeSpark;
    CuratorialInfluence public curatorialInfluence;

    // Addresses for key roles
    address public aiOracleAddress;
    address public immutable catalystPoolAddress; // Where ETH from Spark purchases goes

    // Configuration parameters
    uint256 public evolutionFee; // CreativeSpark tokens required to submit a proposal
    uint256 public minAIQualityScore; // Minimum AI score for a proposal to be eligible for execution
    uint256 public votingPeriodDuration; // Duration in seconds for proposal voting
    uint256 public curatorialInfluenceAwardRate; // CINF awarded for successful actions
    uint256 public sparkToInfluenceStakeRate; // Ratio of Spark staked to Influence boost per period

    // --- Structs ---

    struct EvolutionFragment {
        uint256 tokenId;
        address owner;
        string currentParametersHash; // IPFS/Arweave hash pointing to generative art parameters
        uint256 generation; // How many times this fragment has evolved
        uint256 creationTimestamp;
    }

    enum ProposalStatus { PendingAIRating, PendingVoting, Approved, Rejected, Executed, Expired }

    struct EvolutionProposal {
        uint256 proposalId;
        uint256 targetFragmentId;
        address proposer;
        string newParametersHash; // IPFS/Arweave hash for proposed new parameters
        uint256 submittedTimestamp;
        int256 aiQualityScore; // Can be negative for very bad proposals
        uint256 totalUpvotes;
        uint256 totalDownvotes;
        ProposalStatus status;
        uint256 votingEndTime;
        uint256 sparkFeePaid; // Amount of CreativeSpark paid by proposer
    }

    // --- Mappings ---
    mapping(uint256 => EvolutionFragment) public fragments;
    mapping(uint256 => EvolutionProposal) public proposals; // proposalId => EvolutionProposal
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted
    mapping(uint256 => string[]) public fragmentEvolutionHistory; // tokenId => array of past parameter hashes
    mapping(address => uint256) public sparkStakedForInfluence; // User => amount staked
    mapping(address => uint256) public sparkStakeEndTime; // User => timestamp when stake ends
    mapping(address => uint256) public pendingSparkRewards; // User => amount of CreativeSpark pending claim

    Counters.Counter private _proposalIdCounter;

    // --- Events ---
    event FragmentMinted(uint256 indexed tokenId, address indexed owner, string initialParametersHash);
    event FragmentEvolved(uint256 indexed tokenId, uint256 indexed generation, string newParametersHash, uint256 proposalId);
    event EvolutionProposalSubmitted(uint256 indexed proposalId, uint256 indexed targetFragmentId, address indexed proposer, string newParametersHash);
    event AIQualityScoreReceived(uint256 indexed proposalId, int256 aiQualityScore);
    event CuratorialVoteCast(uint256 indexed proposalId, address indexed voter, bool isUpvote, uint256 influenceWeightedPower);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed targetFragmentId);
    event SparkTokensPurchased(address indexed buyer, uint256 amountSpark, uint256 amountEth);
    event InfluenceAwarded(address indexed recipient, uint256 amount);
    event SparkRewardsClaimed(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "EtherealCanvas: Only AI Oracle can call this function.");
        _;
    }

    // --- Constructor ---
    constructor(address _aiOracleAddress, address _catalystPoolAddress)
        ERC721("EtherealCanvas Fragment", "EFRA")
        Ownable(msg.sender)
        Pausable()
    {
        aiOracleAddress = _aiOracleAddress;
        catalystPoolAddress = _catalystPoolAddress;

        // Deploy child contracts
        creativeSpark = new CreativeSpark(address(this)); // Owner of Spark token is this contract
        curatorialInfluence = new CuratorialInfluence(address(this)); // Owner of Influence token is this contract

        // Initial configurations
        evolutionFee = 100 ether; // 100 CreativeSpark tokens
        minAIQualityScore = 50; // AI score out of 100 (example)
        votingPeriodDuration = 3 days; // 3 days for voting
        curatorialInfluenceAwardRate = 10 ether; // 10 CINF
        sparkToInfluenceStakeRate = 1 ether; // 1 CRSPK staked gives 1 CINF/day (example)

        // Grant this contract approval to manage its own tokens
        CreativeSpark(creativeSpark).transferOwnership(address(this));
        CuratorialInfluence(curatorialInfluence).transferOwnership(address(this));
    }

    // --- A. Initialization & Setup (Admin Functions) ---

    function setAIOracleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "EtherealCanvas: Invalid address");
        aiOracleAddress = _newAddress;
    }

    function setEvolutionFee(uint256 _newFee) public onlyOwner {
        evolutionFee = _newFee;
    }

    function setMinAIQualityScore(uint256 _newScore) public onlyOwner {
        require(_newScore <= 100, "Score must be <= 100");
        minAIQualityScore = _newScore;
    }

    function setVotingPeriodDuration(uint256 _newDuration) public onlyOwner {
        votingPeriodDuration = _newDuration;
    }

    function setCuratorialInfluenceAwardRate(uint256 _newRate) public onlyOwner {
        curatorialInfluenceAwardRate = _newRate;
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- B. EtherealFragment (NFT) Management ---

    function mintInitialFragment(string memory _initialParametersHash) public payable whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);

        fragments[newItemId] = EvolutionFragment({
            tokenId: newItemId,
            owner: msg.sender,
            currentParametersHash: _initialParametersHash,
            generation: 1,
            creationTimestamp: block.timestamp
        });

        fragmentEvolutionHistory[newItemId].push(_initialParametersHash);

        emit FragmentMinted(newItemId, msg.sender, _initialParametersHash);
        return newItemId;
    }

    function getFragmentDetails(uint256 _tokenId) public view returns (uint256, address, string memory, uint256, uint256) {
        EvolutionFragment storage fragment = fragments[_tokenId];
        require(fragment.tokenId != 0, "EtherealCanvas: Fragment does not exist.");
        return (fragment.tokenId, fragment.owner, fragment.currentParametersHash, fragment.generation, fragment.creationTimestamp);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        EvolutionFragment storage fragment = fragments[_tokenId];
        // Construct a dynamic URI based on current parameters and generation
        // This URI would point to a metadata JSON that also includes a link to a generative renderer
        // Example: ipfs://[METADATA_BASE_CID]/_tokenId_generation_paramsHash.json
        return string.concat(
            "ipfs://", // or https://api.etherealcanvas.xyz/metadata/
            Strings.toString(_tokenId),
            "/",
            Strings.toString(fragment.generation),
            "/",
            fragment.currentParametersHash,
            ".json"
        );
    }

    function getFragmentEvolutionHistory(uint256 _tokenId) public view returns (string[] memory) {
        require(fragments[_tokenId].tokenId != 0, "EtherealCanvas: Fragment does not exist.");
        return fragmentEvolutionHistory[_tokenId];
    }

    // ERC721 transfer functions are inherited.
    // We can add a custom transfer if additional logic is needed, but standard is fine.
    function transferFragment(address from, address to, uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EtherealCanvas: Caller is not owner nor approved");
        _transfer(from, to, tokenId);
        fragments[tokenId].owner = to; // Update owner in our custom struct
    }

    // --- C. CreativeSpark (ERC20) Management ---

    function buyCreativeSparkTokens() public payable whenNotPaused {
        require(msg.value > 0, "EtherealCanvas: ETH amount must be greater than zero.");

        // For simplicity, let's assume a fixed rate for now (e.g., 1 ETH = 1000 CreativeSpark)
        // In a real system, this would likely be a bonding curve or a complex price oracle.
        uint256 sparkAmount = msg.value * 1000; // Example: 1 ETH = 1000 CRSPK

        // Mint CreativeSpark directly to the buyer
        creativeSpark.mint(msg.sender, sparkAmount);

        // Send ETH to the Catalyst Pool
        (bool sent, ) = payable(catalystPoolAddress).call{value: msg.value}("");
        require(sent, "EtherealCanvas: Failed to send ETH to Catalyst Pool.");

        emit SparkTokensPurchased(msg.sender, sparkAmount, msg.value);
    }

    function burnCreativeSparkTokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "EtherealCanvas: Amount to burn must be greater than zero.");
        creativeSpark.burn(_amount);
    }

    function distributeSparkRewards(address _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0), "EtherealCanvas: Invalid recipient address.");
        require(_amount > 0, "EtherealCanvas: Amount must be greater than zero.");
        pendingSparkRewards[_recipient] += _amount;
    }

    function claimSparkRewards() public whenNotPaused {
        uint256 rewards = pendingSparkRewards[msg.sender];
        require(rewards > 0, "EtherealCanvas: No pending Spark rewards to claim.");
        
        pendingSparkRewards[msg.sender] = 0;
        creativeSpark.mint(msg.sender, rewards); // Mint to claimant from contract's balance
        emit SparkRewardsClaimed(msg.sender, rewards);
    }


    // --- D. Evolution Proposals & Governance ---

    function submitEvolutionProposal(uint256 _targetFragmentId, string memory _newParametersHash) public whenNotPaused {
        require(fragments[_targetFragmentId].tokenId != 0, "EtherealCanvas: Target fragment does not exist.");
        require(bytes(_newParametersHash).length > 0, "EtherealCanvas: New parameters hash cannot be empty.");
        require(creativeSpark.balanceOf(msg.sender) >= evolutionFee, "EtherealCanvas: Insufficient CreativeSpark for fee.");

        // Transfer fee to the contract (which owns the CreativeSpark token contract)
        creativeSpark.transferFrom(msg.sender, address(this), evolutionFee);

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = EvolutionProposal({
            proposalId: newProposalId,
            targetFragmentId: _targetFragmentId,
            proposer: msg.sender,
            newParametersHash: _newParametersHash,
            submittedTimestamp: block.timestamp,
            aiQualityScore: 0, // Awaits AI rating
            totalUpvotes: 0,
            totalDownvotes: 0,
            status: ProposalStatus.PendingAIRating,
            votingEndTime: 0, // Set after AI rating
            sparkFeePaid: evolutionFee
        });

        emit EvolutionProposalSubmitted(newProposalId, _targetFragmentId, msg.sender, _newParametersHash);
    }

    function requestAIQualityScore(uint256 _proposalId, int256 _qualityScore) public onlyAIOracle whenNotPaused {
        EvolutionProposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "EtherealCanvas: Proposal does not exist.");
        require(proposal.status == ProposalStatus.PendingAIRating, "EtherealCanvas: Proposal not in PendingAIRating status.");
        require(_qualityScore >= -100 && _qualityScore <= 100, "EtherealCanvas: AI score must be between -100 and 100.");

        proposal.aiQualityScore = _qualityScore;
        proposal.status = ProposalStatus.PendingVoting;
        proposal.votingEndTime = block.timestamp + votingPeriodDuration;

        emit AIQualityScoreReceived(_proposalId, _qualityScore);
    }

    function castCuratorialVote(uint256 _proposalId, bool _isUpvote) public whenNotPaused {
        EvolutionProposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "EtherealCanvas: Proposal does not exist.");
        require(proposal.status == ProposalStatus.PendingVoting, "EtherealCanvas: Proposal not in voting phase.");
        require(block.timestamp <= proposal.votingEndTime, "EtherealCanvas: Voting period has ended.");
        require(!hasVoted[_proposalId][msg.sender], "EtherealCanvas: Already voted on this proposal.");

        uint256 voterInfluence = curatorialInfluence.balanceOf(msg.sender);
        require(voterInfluence > 0, "EtherealCanvas: Must have Curatorial Influence to vote.");

        if (_isUpvote) {
            proposal.totalUpvotes += voterInfluence;
        } else {
            proposal.totalDownvotes += voterInfluence;
        }
        hasVoted[_proposalId][msg.sender] = true;

        emit CuratorialVoteCast(_proposalId, msg.sender, _isUpvote, voterInfluence);
    }

    function executeSuccessfulProposal(uint256 _proposalId) public whenNotPaused {
        EvolutionProposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "EtherealCanvas: Proposal does not exist.");
        require(proposal.status == ProposalStatus.PendingVoting, "EtherealCanvas: Proposal not in voting phase.");
        require(block.timestamp > proposal.votingEndTime, "EtherealCanvas: Voting period has not ended.");
        
        // Check if AI score is sufficient
        require(proposal.aiQualityScore >= int256(minAIQualityScore), "EtherealCanvas: AI quality score too low.");

        // Check if community approval (weighted by influence) is sufficient
        // Example: Net upvotes must be positive and exceed a threshold.
        // For simplicity, let's say (totalUpvotes > totalDownvotes * 1.5) and totalUpvotes > 0
        require(proposal.totalUpvotes > proposal.totalDownvotes, "EtherealCanvas: Proposal did not receive enough support.");

        // Mark as executed and update fragment
        proposal.status = ProposalStatus.Executed;
        _updateFragmentParameters(proposal.targetFragmentId, proposal.newParametersHash, _proposalId);

        // Distribute rewards from the Spark fee and potentially Catalyst pool
        _distributeProposalRewards(proposal.proposer, proposal.sparkFeePaid);

        emit ProposalExecuted(_proposalId, proposal.targetFragmentId);
    }

    function _updateFragmentParameters(uint256 _tokenId, string memory _newParametersHash, uint256 _proposalId) internal {
        EvolutionFragment storage fragment = fragments[_tokenId];
        fragmentEvolutionHistory[_tokenId].push(fragment.currentParametersHash); // Store old hash
        fragment.currentParametersHash = _newParametersHash;
        fragment.generation++;
        // Award influence to proposer and perhaps active voters
        curatorialInfluence.award(fragment.owner, curatorialInfluenceAwardRate / 2); // Owner might get some influence for successfully evolving their art
        curatorialInfluence.award(proposals[_proposalId].proposer, curatorialInfluenceAwardRate); // Proposer gets influence
    }

    function _distributeProposalRewards(address _proposer, uint256 _feePaid) internal {
        // Burn a portion of the fee and distribute the rest
        uint256 burnAmount = _feePaid / 4; // Burn 25%
        uint256 rewardAmount = _feePaid - burnAmount;

        creativeSpark.burn(burnAmount);
        
        // Distribute remaining Spark to the proposer (or other contributors/treasury)
        pendingSparkRewards[_proposer] += rewardAmount;
    }

    function getProposalDetails(uint256 _proposalId) public view returns (EvolutionProposal memory) {
        require(proposals[_proposalId].proposalId != 0, "EtherealCanvas: Proposal does not exist.");
        return proposals[_proposalId];
    }

    function getProposalsByFragment(uint256 _fragmentId) public view returns (EvolutionProposal[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
            if (proposals[i].targetFragmentId == _fragmentId) {
                count++;
            }
        }

        EvolutionProposal[] memory fragmentProposals = new EvolutionProposal[](count);
        uint256 current = 0;
        for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
            if (proposals[i].targetFragmentId == _fragmentId) {
                fragmentProposals[current] = proposals[i];
                current++;
            }
        }
        return fragmentProposals;
    }

    function withdrawFailedProposalFunds(uint256 _proposalId) public whenNotPaused {
        EvolutionProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "EtherealCanvas: Only proposer can withdraw funds.");
        require(proposal.sparkFeePaid > 0, "EtherealCanvas: No fee was paid for this proposal.");
        require(
            (proposal.status != ProposalStatus.Executed && block.timestamp > proposal.votingEndTime) ||
            (proposal.status == ProposalStatus.Rejected) ||
            (proposal.status == ProposalStatus.PendingAIRating && block.timestamp > proposal.submittedTimestamp + votingPeriodDuration * 2) // Allow withdrawal if AI doesn't act
            , "EtherealCanvas: Proposal is still active or already executed."
        );
        require(proposal.sparkFeePaid > 0, "EtherealCanvas: Fee already withdrawn or no fee paid.");

        uint256 amountToRefund = proposal.sparkFeePaid;
        proposal.sparkFeePaid = 0; // Prevent double withdrawal
        
        creativeSpark.mint(msg.sender, amountToRefund); // Refund the Spark token
    }

    // --- E. CuratorialInfluence (Reputation) Management ---

    function getCuratorialInfluence(address _user) public view returns (uint256) {
        return curatorialInfluence.balanceOf(_user);
    }

    function awardCuratorialInfluence(address _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0), "EtherealCanvas: Invalid recipient address.");
        require(_amount > 0, "EtherealCanvas: Amount must be greater than zero.");
        curatorialInfluence.award(_recipient, _amount);
        emit InfluenceAwarded(_recipient, _amount);
    }

    function stakeSparkForInfluenceBoost(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "EtherealCanvas: Amount to stake must be positive.");
        require(creativeSpark.balanceOf(msg.sender) >= _amount, "EtherealCanvas: Insufficient CreativeSpark balance.");
        
        creativeSpark.transferFrom(msg.sender, address(this), _amount); // Transfer Spark to contract
        sparkStakedForInfluence[msg.sender] += _amount;
        sparkStakeEndTime[msg.sender] = block.timestamp + 30 days; // Example: 30-day staking period

        // Award initial influence boost (could be dynamic based on stake duration)
        curatorialInfluence.award(msg.sender, _amount / 10 * sparkToInfluenceStakeRate); // Example: 10% of staked amount as immediate boost
    }

    // --- F. Catalyst Pool & Treasury ---

    function fundCatalystPool() public payable whenNotPaused {
        require(msg.value > 0, "EtherealCanvas: ETH amount must be greater than zero.");
        (bool sent, ) = payable(catalystPoolAddress).call{value: msg.value}("");
        require(sent, "EtherealCanvas: Failed to send ETH to Catalyst Pool.");
    }

    function withdrawFromCatalystPool(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "EtherealCanvas: Invalid recipient address.");
        require(_amount > 0, "EtherealCanvas: Amount must be greater than zero.");
        require(address(this).balance >= _amount, "EtherealCanvas: Insufficient funds in Catalyst Pool.");

        (bool sent, ) = payable(_to).call{value: _amount}("");
        require(sent, "EtherealCanvas: Failed to withdraw from Catalyst Pool.");
    }

    function distributeCatalystRewards(address _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0), "EtherealCanvas: Invalid recipient address.");
        require(_amount > 0, "EtherealCanvas: Amount must be greater than zero.");
        require(address(this).balance >= _amount, "EtherealCanvas: Insufficient funds in Catalyst Pool.");

        (bool sent, ) = payable(_recipient).call{value: _amount}("");
        require(sent, "EtherealCanvas: Failed to distribute Catalyst rewards.");
    }
}
```