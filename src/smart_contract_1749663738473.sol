Okay, here is a smart contract combining several advanced and trendy concepts: a dynamic, reputation-based DAO with utility NFTs and a simulated "Meta-Morph" engine that influences protocol parameters. This design aims for complexity and inter-component interaction without directly duplicating existing large open-source libraries like OpenZeppelin's full Governance or ERC implementations (though it uses similar principles for basic token logic).

We'll call this `MetaMorphoDAO`.

**Core Concepts:**

1.  **Dynamic Parameters:** Key system parameters (like proposal thresholds, voting periods, reputation decay rates, NFT boosts) can change over time, influenced by both DAO votes and a simulated "MetaMorph Engine".
2.  **Reputation System:** Users earn on-chain reputation based on participation (voting, proposing). Reputation decays over inactivity.
3.  **Utility NFTs (MorphoArtifacts):** Non-fungible tokens that provide boosts or special privileges within the DAO, their effect potentially scaled by user reputation or the artifact's dynamic state.
4.  **Simulated MetaMorph Engine:** A function that simulates an external or complex process (like AI analysis or market conditions) and updates specific system parameters. This is *not* actual on-chain AI, but a mechanism to introduce external/complex influence via state changes.
5.  **Weighted Voting:** Voting power is derived from a combination of held tokens, user reputation, and owned utility NFTs.
6.  **Complex Proposal Types (Conceptual):** While execution is standard, the *definition* allows for diverse actions (parameter changes, engine activation, etc.).
7.  **Participation Rewards:** Users can claim rewards for positive engagement (successful votes, accepted proposals).

---

**Outline and Function Summary:**

**Contract Name:** `MetaMorphoDAO`

**Description:** A decentralized autonomous organization where governance power, participation, and utility are dynamically influenced by user reputation, unique utility NFTs (MorphoArtifacts), and a simulated MetaMorph Engine that adapts core protocol parameters over time.

**Key Modules:**

*   **Tokens:** Manages the native `META` token (governance/utility) and `MorphoArtifact` NFTs.
*   **Reputation:** Tracks and updates user reputation scores.
*   **Governance:** Handles proposal creation, voting, and execution.
*   **Parameters:** Stores and manages dynamic DAO and Engine parameters.
*   **Engine:** Simulates the "MetaMorph Engine" logic to influence parameters.
*   **Rewards:** Handles distribution of participation rewards.

**Function Summary (Minimum 20 Functions):**

1.  `constructor()`: Initializes contract, deploys/sets token addresses, sets initial parameters.
2.  `mintMETA(address recipient, uint256 amount)`: Mints new META tokens (controlled access).
3.  `burnMETA(address account, uint256 amount)`: Burns META tokens (controlled access).
4.  `balanceOfMETA(address account) view`: Gets META balance.
5.  `transferMETA(address recipient, uint256 amount)`: Sends META tokens (basic internal).
6.  `approveMETA(address spender, uint256 amount)`: Approves spender for META (basic internal).
7.  `transferFromMETA(address sender, address recipient, uint256 amount)`: Transfers META using approval (basic internal).
8.  `mintArtifact(address recipient, uint256 artifactType) returns (uint256 tokenId)`: Mints a new MorphoArtifact NFT of a specific type (controlled access, possibly based on reputation).
9.  `burnArtifact(uint256 tokenId)`: Burns a MorphoArtifact NFT (controlled access).
10. `ownerOfArtifact(uint256 tokenId) view`: Gets owner of an Artifact NFT.
11. `getArtifactDetails(uint256 tokenId) view`: Gets type and dynamic state of an Artifact.
12. `updateArtifactState(uint256 tokenId, uint256 newState) returns (bool)`: Updates the dynamic state of an artifact (controlled by owner, DAO, or Engine).
13. `getReputation(address account) view`: Gets current reputation score.
14. `decayReputation(address account)`: Triggers reputation decay for an account based on time elapsed.
15. `_addReputation(address account, uint256 amount)`: Internal function to add reputation (e.g., called after a successful vote/proposal).
16. `getUserVotingPower(address account) view`: Calculates current voting power based on META, reputation, and Artifacts.
17. `propose(address[] targets, uint256[] values, bytes[] calldatas, string description) returns (uint256 proposalId)`: Creates a new governance proposal (requires min voting power/reputation).
18. `vote(uint256 proposalId, bool support)`: Casts a vote on a proposal (weight based on `getUserVotingPower`).
19. `getProposalState(uint256 proposalId) view`: Gets the current state of a proposal.
20. `getProposalDetails(uint256 proposalId) view`: Gets targets, calldatas, votes, state, proposer, etc.
21. `executeProposal(uint256 proposalId)`: Executes a successful proposal.
22. `cancelProposal(uint256 proposalId)`: Cancels a proposal under specific conditions (e.g., proposer cancels before voting, or fails threshold early).
23. `runMetaMorphEngine()`: Callable function to simulate the MetaMorph Engine's logic, potentially updating Engine parameters based on internal state or simulated conditions.
24. `getEngineParameter(bytes32 paramName) view`: Gets the current value of a parameter controlled by the Engine.
25. `getDAOParameter(bytes32 paramName) view`: Gets the current value of a parameter controlled by DAO votes.
26. `setDAOParameter(bytes32 paramName, uint256 newValue)`: Internal/protected function to set a DAO parameter (called by proposal execution).
27. `claimParticipationReward()`: Allows users to claim accrued rewards for participation.
28. `setArtifactUtilityBoost(uint256 artifactType, uint256 reputationThreshold, uint256 boostPercentage) public onlyOwner`: Sets how much an artifact type boosts voting power *at* a certain reputation level. (Could be made DAO/Engine controlled later).
29. `getArtifactUtilityBoost(uint256 artifactType, uint256 userReputation) view`: Calculates the effective boost percentage based on artifact type and user reputation.
30. `setReputationDecayParameters(uint256 decayRatePerPeriod, uint256 decayPeriodDuration) public onlyOwner`: Sets parameters for reputation decay. (Could be made DAO/Engine controlled later).
31. `getReputationDecayParameters() view`: Gets current reputation decay parameters.
32. `getParticipationRewardsAvailable(address account) view`: Checks how many rewards are available for an account.
33. `pauseContract() public onlyOwner`: Emergency pause function.
34. `unpauseContract() public onlyOwner`: Unpause function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal Pausable implementation
contract Pausable {
    bool internal _paused;

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _pause() internal virtual {
        require(!_paused, "Pausable: paused");
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual {
        require(_paused, "Pausable: not paused");
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// Minimal Ownable implementation
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// Minimal ERC20-like token logic (not full ERC20 to avoid duplication)
contract SimpleMetaToken {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


// Minimal ERC721-like token logic (not full ERC721 to avoid duplication)
contract SimpleMorphoArtifact {
    mapping(uint256 => address) internal _tokenOwners;
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => address) internal _tokenApprovals;
    uint256 internal _currentTokenId; // Simple token ID counter

    enum ArtifactType { Basic, Guardian, Catalyst, Oracle } // Define artifact types
    struct ArtifactDetails {
        ArtifactType artifactType;
        uint256 dynamicState; // e.g., energy level, charge, status
        // Add other dynamic properties here
    }
    mapping(uint256 => ArtifactDetails) internal _artifactDetails;
    mapping(ArtifactType => mapping(uint256 => uint256)) internal artifactUtilityBoosts; // type => minReputation => boostPercentage (scaled by 100)


    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ArtifactStateUpdated(uint256 indexed tokenId, uint256 newState);
    event ArtifactUtilityBoostSet(uint256 indexed artifactType, uint256 reputationThreshold, uint256 boostPercentage);


    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner, "ERC721: approve caller is not token owner");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        delete _tokenApprovals[tokenId];

        unchecked {
             _balanceOf[from] -= 1;
        }
        _balanceOf[to] += 1;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, ArtifactType artifactType) internal returns (uint256 tokenId) {
        require(to != address(0), "ERC721: mint to the zero address");

        unchecked {
             tokenId = ++_currentTokenId;
        }
        require(!_exists(tokenId), "ERC721: token already minted"); // Should not happen with counter

        _tokenOwners[tokenId] = to;
        _balanceOf[to] += 1;
        _artifactDetails[tokenId] = ArtifactDetails({
            artifactType: artifactType,
            dynamicState: 100 // Initial state, e.g., 100% charge
        });

        emit Transfer(address(0), to, tokenId);
    }

     function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        delete _tokenApprovals[tokenId];
        delete _tokenOwners[tokenId];
        delete _artifactDetails[tokenId];

        unchecked {
             _balanceOf[owner] -= 1;
        }

        emit Transfer(owner, address(0), tokenId);
    }

    // --- Custom Artifact Functions ---

    function getArtifactDetails(uint256 tokenId) public view returns (ArtifactType artifactType, uint256 dynamicState) {
        require(_exists(tokenId), "Artifact: non-existent token");
        ArtifactDetails storage details = _artifactDetails[tokenId];
        return (details.artifactType, details.dynamicState);
    }

    function updateArtifactState(uint256 tokenId, uint256 newState) public returns (bool) {
         require(_exists(tokenId), "Artifact: non-existent token");
         // This logic could be restricted: only owner, DAO, or Engine?
         // For demo, let's allow owner to trigger but DAO/Engine can too via proposal execution.
         require(msg.sender == ownerOf(tokenId) || msg.sender == address(this), "Artifact: not authorized to update state"); // DAO address can update

         _artifactDetails[tokenId].dynamicState = newState;
         emit ArtifactStateUpdated(tokenId, newState);
         return true;
    }

    function setArtifactUtilityBoost(uint256 artifactType, uint256 reputationThreshold, uint256 boostPercentage) public {
         // This should ideally be callable only by the DAO itself via proposal execution
         // Or initially by the owner for setup
         // require(msg.sender == address(this) || msg.sender == owner(), "Artifact: only DAO or owner can set boost");
         artifactUtilityBoosts[ArtifactType(artifactType)][reputationThreshold] = boostPercentage; // boostPercentage is scaled, e.g., 120 for 1.2x
         emit ArtifactUtilityBoostSet(artifactType, reputationThreshold, boostPercentage);
    }

    function getArtifactUtilityBoost(uint256 artifactType, uint256 userReputation) public view returns (uint256) {
        uint256 bestBoost = 100; // Default 100% (no boost)
        // Find the highest reputation threshold the user meets for this artifact type
        uint256 highestThreshold = 0;
        for (uint256 threshold = 0; threshold <= userReputation; threshold++) {
            if (artifactUtilityBoosts[ArtifactType(artifactType)][threshold] > 0) {
                highestThreshold = threshold;
            }
        }
        if (highestThreshold > 0 || artifactUtilityBoosts[ArtifactType(artifactType)][0] > 0) { // Check threshold 0 as well
             // Find the actual boost value at the highest applicable threshold
             // Need a way to iterate map keys or store thresholds. Simplification: check specific tiers
             // For demonstration, let's just use the *exact* threshold match or a default if 0 is set
             if (artifactUtilityBoosts[ArtifactType(artifactType)][userReputation] > 0) {
                 return artifactUtilityBoosts[ArtifactType(artifactType)][userReputation];
             } else if (artifactUtilityBoosts[ArtifactType(artifactType)][0] > 0) {
                 return artifactUtilityBoosts[ArtifactType(artifactType)][0]; // Apply base boost if no threshold-specific boost
             }
             // A more advanced version would iterate through stored thresholds to find the best match <= userReputation
        }
         return bestBoost; // Return 100 if no specific boost found
    }
}


contract MetaMorphoDAO is Ownable, Pausable {

    // --- State Variables ---

    // Tokens (using simplified internal versions)
    SimpleMetaToken public metaToken;
    SimpleMorphoArtifact public morphoArtifact;

    // Reputation
    mapping(address => uint256) private userReputation;
    mapping(address => uint256) private lastReputationDecay; // Timestamp of last decay

    // Governance
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted; // Simple check to prevent double voting
    }

    mapping(uint256 => Proposal) private proposals;
    uint256 private nextProposalId = 1;

    // Parameters (Dynamic)
    mapping(bytes32 => uint256) private daoParameters;
    mapping(bytes32 => uint256) private engineParameters;

    // Engine State (for simulation)
    uint256 private engineCycleCount = 0;
    uint256 private lastEngineRunBlock = 0;

    // Rewards
    mapping(address => uint256) private participationRewardsAvailable;

    // --- Events ---

    event ReputationUpdated(address indexed account, uint256 newReputation);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ParameterChanged(bytes32 indexed paramName, uint256 oldValue, uint256 newValue, bool byEngine);
    event EngineRun(uint256 indexed cycleCount, uint256 blockNumber);
    event RewardsClaimed(address indexed account, uint256 amount);
    event ArtifactMinted(address indexed recipient, uint256 indexed tokenId, uint256 artifactType);
    event ArtifactBurned(uint256 indexed tokenId);


    // --- Constructor ---

    constructor(address metaTokenAddress, address morphoArtifactAddress) {
        // Assume tokens are deployed elsewhere and set here
        // Or deploy them here if they are simple internal contracts
        // For this example, let's use the simple internal implementations
        metaToken = new SimpleMetaToken();
        morphoArtifact = new SimpleMorphoArtifact();
        _owner = msg.sender; // Set owner via Ownable constructor

        // Set initial DAO parameters
        daoParameters[keccak256("MinMetaToPropose")] = 100 ether; // Example: 100 META needed to propose
        daoParameters[keccak256("MinReputationToPropose")] = 500; // Example: 500 reputation needed
        daoParameters[keccak256("VotingPeriodBlocks")] = 100; // Example: 100 blocks voting period
        daoParameters[keccak256("ProposalThresholdPercentage")] = 4; // Example: 4% of total voting power needed to pass
        daoParameters[keccak256("ReputationDecayRatePerPeriod")] = 10; // Example: lose 10 reputation per decay period
        daoParameters[keccak256("ReputationDecayPeriodDuration")] = 1 days; // Example: decay period is 1 day (in seconds)
        daoParameters[keccak256("ParticipationRewardAmount")] = 1 ether; // Example: 1 META per claimed reward

        // Set initial Engine parameters (these can be overridden by runMetaMorphEngine)
        engineParameters[keccak256("VotingPowerReputationWeight")] = 10; // Example: 10 reputation points = 1 META equivalent voting power
        engineParameters[keccak256("EngineCooldownBlocks")] = 50; // Example: Engine can only run every 50 blocks

        // Initial artifact boosts (can be set via DAO or Engine later)
        morphoArtifact.setArtifactUtilityBoost(uint256(SimpleMorphoArtifact.ArtifactType.Basic), 0, 100); // Basic: no boost
        morphoArtifact.setArtifactUtilityBoost(uint256(SimpleMorphoArtifact.ArtifactType.Guardian), 100, 110); // Guardian: 1.1x boost from 100 rep
        morphoArtifact.setArtifactUtilityBoost(uint256(SimpleMorphoArtifact.ArtifactType.Catalyst), 500, 125); // Catalyst: 1.25x boost from 500 rep
        morphoArtifact.setArtifactUtilityBoost(uint256(SimpleMorphoArtifact.ArtifactType.Oracle), 1000, 150); // Oracle: 1.5x boost from 1000 rep

        _pause(); // Start paused, owner unpauses after full setup
    }

    // --- Token Functions (simplified, wrapped from internal contracts) ---

    /// @notice Mints META tokens, restricted to owner or DAO execution.
    /// @param recipient The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mintMETA(address recipient, uint256 amount) public onlyOwner whenNotPaused { // Restricted access
        metaToken._mint(recipient, amount);
    }

    /// @notice Burns META tokens from an account, restricted to owner or DAO execution.
    /// @param account The account to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burnMETA(address account, uint256 amount) public onlyOwner whenNotPaused { // Restricted access
        metaToken._burn(account, amount);
    }

    /// @notice Gets the META balance of an account.
    /// @param account The address to query.
    /// @return The META balance.
    function balanceOfMETA(address account) public view whenNotPaused returns (uint256) {
        return metaToken.balanceOf(account);
    }

    /// @notice Transfers META tokens from the caller's account.
    /// @param recipient The address to send to.
    /// @param amount The amount to send.
    /// @return True if successful.
    function transferMETA(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        return metaToken.transfer(recipient, amount);
    }

    /// @notice Approves a spender to transfer META tokens on behalf of the caller.
    /// @param spender The address to approve.
    /// @param amount The amount to approve.
    /// @return True if successful.
    function approveMETA(address spender, uint256 amount) public whenNotPaused returns (bool) {
         return metaToken.approve(spender, amount);
    }

    /// @notice Transfers META tokens from one account to another using allowance.
    /// @param sender The account to transfer from.
    /// @param recipient The account to transfer to.
    /// @param amount The amount to transfer.
    /// @return True if successful.
    function transferFromMETA(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
         return metaToken.transferFrom(sender, recipient, amount);
    }

    /// @notice Gets the total supply of META tokens.
    /// @return The total supply.
    function getTotalSupplyMETA() public view whenNotPaused returns (uint256) {
        return metaToken.totalSupply();
    }


    // --- Artifact Functions (simplified, wrapped from internal contracts) ---

    /// @notice Mints a MorphoArtifact NFT of a specific type, restricted.
    /// @param recipient The address to mint the NFT to.
    /// @param artifactType The type of artifact to mint (enum index).
    /// @return The new token ID.
    function mintArtifact(address recipient, uint256 artifactType) public onlyOwner whenNotPaused returns (uint256 tokenId) { // Restricted access, maybe based on reputation/contribution in a real system
        require(artifactType < uint265(SimpleMorphoArtifact.ArtifactType.Oracle) + 1, "Invalid artifact type");
        tokenId = morphoArtifact._mint(recipient, SimpleMorphoArtifact.ArtifactType(artifactType));
        emit ArtifactMinted(recipient, tokenId, artifactType);
    }

    /// @notice Burns a MorphoArtifact NFT, restricted.
    /// @param tokenId The ID of the NFT to burn.
    function burnArtifact(uint256 tokenId) public onlyOwner whenNotPaused { // Restricted access
        morphoArtifact._burn(tokenId);
        emit ArtifactBurned(tokenId);
    }

    /// @notice Gets the owner of a MorphoArtifact NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The owner address.
    function ownerOfArtifact(uint256 tokenId) public view whenNotPaused returns (address) {
        return morphoArtifact.ownerOf(tokenId);
    }

     /// @notice Gets the number of MorphoArtifacts owned by an account.
     /// @param owner The address to query.
     /// @return The number of Artifacts owned.
     function balanceOfArtifacts(address owner) public view whenNotPaused returns (uint256) {
         return morphoArtifact.balanceOf(owner);
     }

    /// @notice Gets the details (type, dynamic state) of a MorphoArtifact NFT.
    /// @param tokenId The ID of the NFT.
    /// @return artifactType The type of the artifact.
    /// @return dynamicState The current dynamic state of the artifact.
    function getArtifactDetails(uint256 tokenId) public view whenNotPaused returns (uint256 artifactType, uint256 dynamicState) {
        (SimpleMorphoArtifact.ArtifactType typeEnum, uint256 state) = morphoArtifact.getArtifactDetails(tokenId);
        return (uint256(typeEnum), state);
    }

    /// @notice Updates the dynamic state of a MorphoArtifact NFT. Restricted to owner, DAO, or Engine.
    /// @param tokenId The ID of the NFT.
    /// @param newState The new dynamic state value.
    /// @return True if successful.
    function updateArtifactState(uint256 tokenId, uint256 newState) public whenNotPaused returns (bool) {
        // Callable by NFT owner OR the DAO contract address itself (via execution) OR the Engine (simulated)
        require(msg.sender == morphoArtifact.ownerOf(tokenId) || msg.sender == address(this) || msg.sender == owner(), "Artifact: not authorized to update state"); // Added owner as Engine simulator proxy
        return morphoArtifact.updateArtifactState(tokenId, newState);
    }

    /// @notice Gets the total supply of MorphoArtifact NFTs.
    /// @return The total supply.
    function getTotalSupplyArtifacts() public view whenNotPaused returns (uint256) {
        return morphoArtifact._currentTokenId; // Assuming _currentTokenId tracks total minted
    }

    /// @notice Gets the effective utility boost percentage for a specific artifact type and user reputation.
    /// @param artifactType The type of artifact (enum index).
    /// @param userReputation The user's reputation score.
    /// @return The boost percentage (e.g., 120 for 1.2x boost).
    function getArtifactUtilityBoost(uint256 artifactType, uint256 userReputation) public view whenNotPaused returns (uint256) {
        require(artifactType < uint265(SimpleMorphoArtifact.ArtifactType.Oracle) + 1, "Invalid artifact type");
        return morphoArtifact.getArtifactUtilityBoost(SimpleMorphoArtifact.ArtifactType(artifactType), userReputation);
    }

     /// @notice Sets the utility boost percentage for an artifact type at a given reputation threshold.
     /// Restricted to owner or DAO execution.
     /// @param artifactType The type of artifact (enum index).
     /// @param reputationThreshold The minimum reputation needed for this boost.
     /// @param boostPercentage The boost percentage (e.g., 120 for 1.2x).
    function setArtifactUtilityBoost(uint256 artifactType, uint256 reputationThreshold, uint256 boostPercentage) public onlyOwner whenNotPaused {
        require(artifactType < uint265(SimpleMorphoArtifact.ArtifactType.Oracle) + 1, "Invalid artifact type");
        morphoArtifact.setArtifactUtilityBoost(artifactType, reputationThreshold, boostPercentage);
    }


    // --- Reputation Functions ---

    /// @notice Gets the current reputation score for an account.
    /// @param account The address to query.
    /// @return The reputation score.
    function getReputation(address account) public view whenNotPaused returns (uint256) {
        // Automatically decay reputation if needed before returning
        _decayReputationInternal(account); // Decay simulation on read
        return userReputation[account];
    }

    /// @notice Triggers reputation decay for a specific account. Can be called by anyone.
    /// @param account The account to decay reputation for.
    function decayReputation(address account) public whenNotPaused {
        _decayReputationInternal(account);
    }

    /// @dev Internal function to handle reputation decay based on time.
    function _decayReputationInternal(address account) internal view {
        uint256 lastDecay = lastReputationDecay[account];
        uint256 decayPeriodDuration = daoParameters[keccak256("ReputationDecayPeriodDuration")];

        if (decayPeriodDuration == 0 || lastDecay == 0) {
            // No decay configured or never updated, do nothing
            return;
        }

        uint256 periodsElapsed = (block.timestamp - lastDecay) / decayPeriodDuration;
        uint256 decayRate = daoParameters[keccak256("ReputationDecayRatePerPeriod")];

        if (periodsElapsed > 0) {
            uint256 decayAmount = periodsElapsed * decayRate;
            if (userReputation[account] > decayAmount) {
                 userReputation[account] -= decayAmount;
            } else {
                 userReputation[account] = 0;
            }
            lastReputationDecay[account] = lastDecay + periodsElapsed * decayPeriodDuration; // Update last decay time accurately
            emit ReputationUpdated(account, userReputation[account]);
        }
    }

    /// @dev Internal function to add reputation, typically called by action handlers.
    /// @param account The account to add reputation to.
    /// @param amount The amount of reputation to add.
    function _addReputation(address account, uint256 amount) internal {
        userReputation[account] += amount;
        // Update last decay time to now when reputation is gained, preventing immediate decay after gain
        lastReputationDecay[account] = block.timestamp;
        emit ReputationUpdated(account, userReputation[account]);
    }

    /// @notice Sets parameters for reputation decay (rate and period duration).
    /// Restricted to owner or DAO execution.
    /// @param decayRatePerPeriod The amount of reputation lost per period.
    /// @param decayPeriodDuration The duration of a decay period in seconds.
    function setReputationDecayParameters(uint256 decayRatePerPeriod, uint256 decayPeriodDuration) public onlyOwner whenNotPaused { // Can be executed by DAO
        daoParameters[keccak256("ReputationDecayRatePerPeriod")] = decayRatePerPeriod;
        daoParameters[keccak256("ReputationDecayPeriodDuration")] = decayPeriodDuration;
        emit ParameterChanged(keccak256("ReputationDecayRatePerPeriod"), 0, decayRatePerPeriod, false); // Emit old value 0 for simplicity
        emit ParameterChanged(keccak256("ReputationDecayPeriodDuration"), 0, decayPeriodDuration, false);
    }

     /// @notice Gets the current reputation decay parameters.
     /// @return decayRatePerPeriod The amount of reputation lost per period.
     /// @return decayPeriodDuration The duration of a decay period in seconds.
    function getReputationDecayParameters() public view whenNotPaused returns (uint256 decayRatePerPeriod, uint256 decayPeriodDuration) {
        return (daoParameters[keccak256("ReputationDecayRatePerPeriod")], daoParameters[keccak256("ReputationDecayPeriodDuration")]);
    }

    // --- Voting Power Calculation ---

    /// @notice Calculates the current voting power of an account.
    /// Power is derived from META balance, reputation, and owned artifacts.
    /// @param account The address to query.
    /// @return The calculated voting power.
    function getUserVotingPower(address account) public view whenNotPaused returns (uint256) {
        // Decay reputation before calculating power
        _decayReputationInternal(account); // Simulate decay on read

        uint256 metaBalance = metaToken.balanceOf(account);
        uint256 reputation = userReputation[account];
        uint256 repWeight = engineParameters[keccak256("VotingPowerReputationWeight")]; // Reputation points per META equivalent

        uint256 baseVotingPower = metaBalance; // META directly contributes 1:1

        // Add reputation-based power
        if (repWeight > 0) {
             baseVotingPower += (reputation * 1 ether) / repWeight; // Scale reputation to META equivalent
        }

        uint256 totalArtifactBoost = 100; // Start with 100%
        uint256 artifactCount = morphoArtifact.balanceOf(account);
        // This part is simplified - in a real system, you'd need to iterate through owned token IDs
        // For demonstration, we'll apply a simple average or sum based on artifact types owned
        // A full implementation would require a mapping from owner to token IDs or iterating _tokenOwners
        // Let's simulate a simple average boost based on artifact types the user is *eligible* for
        SimpleMorphoArtifact.ArtifactType[] memory artifactTypes = new SimpleMorphoArtifact.ArtifactType[](4);
        artifactTypes[0] = SimpleMorphoArtifact.ArtifactType.Basic;
        artifactTypes[1] = SimpleMorphoArtifact.ArtifactType.Guardian;
        artifactTypes[2] = SimpleMorphoArtifact.ArtifactType.Catalyst;
        artifactTypes[3] = SimpleMorphoArtifact.ArtifactType.Oracle;

        uint256 cumulativeBoostPercentage = 0;
        uint256 applicableArtifactTypes = 0;

        for(uint i = 0; i < artifactTypes.length; i++) {
             // This check is a simplification. A real system would check which specific NFTs are owned.
             // Here we check if the user has at least one artifact of a type to get the boost.
             // This requires iterating through token IDs owned by the user, which is expensive.
             // Let's *assume* for this demo that owning *any* artifact of a type grants the potential boost,
             // but the boost is only applied if the user owns at least one NFT.
             // A more practical approach needs off-chain indexing or a different data structure.
             // For now, let's calculate a potential boost based on owned count > 0 and reputation.

             // Simplified: Check if the user owns *any* artifacts. If so, get the boost for the *highest* artifact type they could benefit from based on reputation.
             if (artifactCount > 0) {
                 // Find highest applicable type based on reputation
                 SimpleMorphoArtifact.ArtifactType highestApplicableType = SimpleMorphoArtifact.ArtifactType.Basic;
                 if (reputation >= 100) highestApplicableType = SimpleMorphoArtifact.ArtifactType.Guardian;
                 if (reputation >= 500) highestApplicableType = SimpleMorphoArtifact.ArtifactType.Catalyst;
                 if (reputation >= 1000) highestApplicableType = SimpleMorphoArtifact.ArtifactType.Oracle;

                 // Get the boost for that type at the user's reputation
                 uint256 boost = morphoArtifact.getArtifactUtilityBoost(uint256(highestApplicableType), reputation);
                 totalArtifactBoost = boost; // Apply the highest single applicable boost
                 break; // Apply only the highest single boost for simplicity
             }
        }


        // Apply artifact boost
        // totalArtifactBoost is scaled by 100 (e.g., 120 for 1.2x)
        uint256 finalVotingPower = (baseVotingPower * totalArtifactBoost) / 100;

        return finalVotingPower;
    }

    // --- Governance Functions ---

    /// @notice Creates a new governance proposal.
    /// Requires minimum META and reputation.
    /// @param targets Array of target addresses for calls.
    /// @param values Array of ETH values to send with calls.
    /// @param calldatas Array of calldata for calls.
    /// @param description A string description of the proposal.
    /// @return The ID of the created proposal.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public whenNotPaused returns (uint256 proposalId) {
        require(targets.length == values.length && targets.length == calldatas.length, "Proposal: array lengths mismatch");
        require(targets.length > 0, "Proposal: must include actions");

        // Check minimum requirements (voting power might be used, but explicit META+Reputation is simpler here)
        uint256 minMeta = daoParameters[keccak256("MinMetaToPropose")];
        uint256 minRep = daoParameters[keccak256("MinReputationToPropose")];
        require(metaToken.balanceOf(msg.sender) >= minMeta, "Proposal: insufficient META balance");
        require(userReputation[msg.sender] >= minRep, "Proposal: insufficient reputation");

        // Decay reputation before adding for proposing
        _decayReputationInternal(msg.sender);

        proposalId = nextProposalId++;
        uint256 startBlock = block.number;
        uint256 endBlock = startBlock + daoParameters[keccak256("VotingPeriodBlocks")];

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targets: targets,
            values: values,
            calldatas: calldatas,
            description: description,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            canceled: false,
            hasVoted: new mapping(address => bool)() // Initialize mapping
        });

        // Reward proposer with reputation
        _addReputation(msg.sender, 50); // Example: 50 reputation for proposing

        emit ProposalCreated(proposalId, msg.sender, description, endBlock);
        emit ProposalStateChanged(proposalId, ProposalState.Pending); // Starts Pending until voting period begins implicitly
    }

    /// @notice Casts a vote on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for a "for" vote, false for "against".
    function vote(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Vote: proposal not found");
        require(block.number > proposal.startBlock && block.number <= proposal.endBlock, "Vote: voting period is not active");
        require(!proposal.hasVoted[msg.sender], "Vote: already voted");

        // Decay reputation before calculating voting power
        _decayReputationInternal(msg.sender);

        uint256 votingPower = getUserVotingPower(msg.sender);
        require(votingPower > 0, "Vote: zero voting power");

        if (support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        // Reward voter with reputation
        _addReputation(msg.sender, 10); // Example: 10 reputation for voting

        // Make participation rewards available
        participationRewardsAvailable[msg.sender] += daoParameters[keccak256("ParticipationRewardAmount")];

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    /// @notice Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The state of the proposal.
    function getProposalState(uint256 proposalId) public view whenNotPaused returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) return ProposalState.Pending; // Or some error state, but Pending is simple
        if (proposal.canceled) return ProposalState.Canceled;
        if (block.number <= proposal.startBlock) return ProposalState.Pending;
        if (block.number <= proposal.endBlock) return ProposalState.Active;
        if (proposal.executed) return ProposalState.Executed;

        // Voting period ended, check outcome
        uint256 totalVotingPower = metaToken.totalSupply(); // Simplified: Assume total voting power is proportional to total META
        // A more accurate check would require summing up voting power of ALL eligible voters or using a checkpointing system.
        // Using total supply as a proxy for simplicity.
        // Check if total votes meet a quorum (optional, added complexity)
        // Check if 'for' votes meet threshold percentage of total voting power
        uint256 thresholdPercentage = daoParameters[keccak256("ProposalThresholdPercentage")];
        uint256 requiredVotes = (totalVotingPower * thresholdPercentage) / 100; // Simplified threshold calculation

        if (proposal.forVotes > proposal.againstVotes && proposal.forVotes >= requiredVotes) {
            // Proposal Succeeded. Check if executable now or requires queuing
             // For simplicity, assume immediate execution if state is Succeeded.
             // Real systems often require queuing.
             return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /// @notice Gets details about a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return targets Array of target addresses.
    /// @return values Array of ETH values.
    /// @return calldatas Array of calldata.
    /// @return description The proposal description.
    /// @return startBlock The start block of voting.
    /// @return endBlock The end block of voting.
    /// @return forVotes The number of 'for' votes.
    /// @return againstVotes The number of 'against' votes.
    /// @return executed Whether the proposal has been executed.
    /// @return canceled Whether the proposal has been canceled.
    function getProposalDetails(uint256 proposalId) public view whenNotPaused returns (
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        uint256 startBlock,
        uint256 endBlock,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed,
        bool canceled
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Details: proposal not found");
        return (
            proposal.targets,
            proposal.values,
            proposal.calldatas,
            proposal.description,
            proposal.startBlock,
            proposal.endBlock,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed,
            proposal.canceled
        );
    }


    /// @notice Executes a successful proposal.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Execute: proposal not found");
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Execute: proposal not in succeeded state");
        require(!proposal.executed, "Execute: proposal already executed");

        proposal.executed = true;

        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success,) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            // Consider adding failure handling or logging here
            // require(success, "Execute: action failed");
             if (!success) {
                 // Log failed execution part? Revert? Depends on desired DAO robustness.
                 // For simplicity here, we just proceed, but in real DAO, failure should be handled.
             }
        }

        // Reward proposer for successful execution
        _addReputation(proposal.proposer, 100); // Example: 100 reputation for executed proposal

        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    /// @notice Cancels a proposal. Limited conditions (e.g., proposer cancels before voting ends, or specific conditions).
    /// @param proposalId The ID of the proposal.
    function cancelProposal(uint256 proposalId) public whenNotPaused {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.id != 0, "Cancel: proposal not found");
         require(!proposal.canceled, "Cancel: proposal already canceled");
         require(getProposalState(proposalId) < ProposalState.Succeeded, "Cancel: proposal voting ended or already succeeded");

         // Allow proposer to cancel if voting hasn't ended
         require(msg.sender == proposal.proposer || msg.sender == owner(), "Cancel: not authorized"); // Owner can also cancel emergency

         proposal.canceled = true;
         emit ProposalStateChanged(proposalId, ProposalState.Canceled);
    }


    // --- Parameter Functions ---

    /// @notice Gets the current value of a parameter controlled by the Engine.
    /// @param paramName The keccak256 hash of the parameter name.
    /// @return The parameter value.
    function getEngineParameter(bytes32 paramName) public view whenNotPaused returns (uint256) {
        return engineParameters[paramName];
    }

    /// @notice Gets the current value of a parameter controlled by DAO votes.
    /// @param paramName The keccak256 hash of the parameter name.
    /// @return The parameter value.
    function getDAOParameter(bytes32 paramName) public view whenNotPaused returns (uint256) {
        return daoParameters[paramName];
    }

    /// @dev Internal function to set a DAO parameter, callable only by DAO execution.
    /// @param paramName The keccak256 hash of the parameter name.
    /// @param newValue The new parameter value.
    function setDAOParameter(bytes32 paramName, uint256 newValue) public whenNotPaused {
        // Only the DAO contract address itself can call this
        require(msg.sender == address(this), "SetDAOParam: only DAO execution allowed");

        uint256 oldValue = daoParameters[paramName];
        daoParameters[paramName] = newValue;
        emit ParameterChanged(paramName, oldValue, newValue, false);
    }


    // --- MetaMorph Engine Simulation ---

    /// @notice Simulates the MetaMorph Engine's logic.
    /// Can be called by anyone, but has a cooldown and state-dependent effects.
    function runMetaMorphEngine() public whenNotPaused {
        uint256 engineCooldown = engineParameters[keccak256("EngineCooldownBlocks")];
        require(block.number >= lastEngineRunBlock + engineCooldown, "Engine: cooldown not elapsed");

        engineCycleCount++;
        lastEngineRunBlock = block.number;

        // --- Simulated Engine Logic ---
        // This is where complex, simulated logic would reside.
        // It could be based on:
        // 1. Internal state (e.g., proposal success rate, total META supply)
        // 2. Time elapsed
        // 3. Randomness (within limits, e.g., using blockhash - careful with security)
        // 4. Oracle data (requires an actual oracle integration)

        // Example Simulation:
        // If recent proposals have high "for" votes, increase reputation weight slightly.
        // If too many artifacts of one type are minted, slightly decrease their boost.
        // Periodically adjust EngineCooldownBlocks based on network congestion (simulated by time/blockdiff).

        // Simple Simulation based on cycle count:
        bytes32 repWeightParam = keccak256("VotingPowerReputationWeight");
        uint256 currentRepWeight = engineParameters[repWeightParam];
        uint256 oldRepWeight = currentRepWeight;

        if (engineCycleCount % 10 == 0) { // Every 10 cycles, slightly adjust reputation weight
            if (engineCycleCount % 20 == 0) {
                 // Increase every 20 cycles
                 engineParameters[repWeightParam] = currentRepWeight + 1;
            } else {
                 // Decrease every other 10 cycles (every 10, 30, 50, ...)
                 if (currentRepWeight > 1) {
                     engineParameters[repWeightParam] = currentRepWeight - 1;
                 }
            }
             emit ParameterChanged(repWeightParam, oldRepWeight, engineParameters[repWeightParam], true);
        }

        bytes32 engineCooldownParam = keccak256("EngineCooldownBlocks");
        uint256 currentCooldown = engineParameters[engineCooldownParam];
        uint256 oldCooldown = currentCooldown;
        if (engineCycleCount % 5 == 0) { // Every 5 cycles, adjust cooldown
             engineParameters[engineCooldownParam] = (currentCooldown * 105) / 100; // Increase by 5%
             emit ParameterChanged(engineCooldownParam, oldCooldown, engineParameters[engineCooldownParam], true);
        }

        // More complex example: Check total META supply vs total reputation, adjust parameters
        uint256 totalMeta = metaToken.totalSupply();
        // uint256 totalReputation; // Requires iterating all users, impractical on-chain

        // Can call `morphoArtifact.setArtifactUtilityBoost` here based on simulated conditions
        // E.g., if artifact type X is abundant, reduce its boost slightly for low reputation users.

        emit EngineRun(engineCycleCount, block.number);
    }


    // --- Rewards Functions ---

    /// @notice Allows a user to claim their available participation rewards.
    function claimParticipationReward() public whenNotPaused {
        uint256 amount = participationRewardsAvailable[msg.sender];
        require(amount > 0, "Rewards: no rewards available");

        participationRewardsAvailable[msg.sender] = 0; // Reset available rewards

        // Transfer META tokens as reward
        metaToken._mint(msg.sender, amount); // Minting new tokens for rewards

        emit RewardsClaimed(msg.sender, amount);
    }

    /// @notice Checks the amount of participation rewards available for an account.
    /// @param account The address to query.
    /// @return The amount of rewards available.
    function getParticipationRewardsAvailable(address account) public view whenNotPaused returns (uint256) {
        return participationRewardsAvailable[account];
    }

    // --- Pausable Functions ---

    /// @notice Pauses the contract in case of emergency. Restricted to owner.
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Restricted to owner.
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }


    // --- Fallback/Receive (Handle potential ETH sent) ---
    // This DAO expects META and ERC721 interactions, not direct ETH transfers.
    // Add receive/fallback if ETH might be intentionally sent (e.g., for proposal values)
    // For this example, direct ETH transfers are not supported by design.

    // receive() external payable {
    //     // Optionally handle received ETH, e.g., log event or revert
    //     revert("MetaMorphoDAO: direct ETH transfers not accepted");
    // }

    // fallback() external payable {
    //     // Optionally handle received ETH via fallback
    //      revert("MetaMorphoDAO: direct ETH transfers not accepted");
    // }
}
```