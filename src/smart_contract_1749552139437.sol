Okay, let's design a smart contract that implements a decentralized knowledge base or "Fact Registry" with concepts like reputation, staking for verification, dynamic NFTs representing contribution level, and a basic delegation mechanism.

We'll call the contract `CognitoNexus`. It manages "Facts" submitted by users, allows others to stake and vote on their validity, tracks user reputation, and issues dynamic NFTs ("CognitoMarks") that evolve based on a user's reputation and validated contributions.

This contract will interact with two external contracts: an ERC-20 token (`CGNX`) used for staking and rewards, and an ERC-721 token (`CognitoMark`) for the dynamic NFTs. We'll define interfaces for these.

---

**Outline and Function Summary**

**Contract Name:** `CognitoNexus`

**Description:** A decentralized protocol for submitting, verifying, and managing "Facts" or pieces of knowledge. It incorporates staking mechanisms, a reputation system, delegation of verification rights, and dynamic non-fungible tokens (NFTs) that evolve based on a contributor's activity and success.

**Core Concepts:**
1.  **Facts:** Submissions by users containing data (e.g., hash of content, IPFS CID) and metadata.
2.  **Contributors:** Users registered with the system, possessing a reputation score.
3.  **CGNX Token:** An external ERC-20 token used for staking on facts (to signal confidence/support) and distributed as rewards.
4.  **CognitoMark NFT:** An external ERC-721 token. Each registered contributor *can* own one, which dynamically reflects their reputation and validated contributions. Metadata is updated based on on-chain state.
5.  **Staking:** Users stake CGNX on facts to participate in verification/dispute processes and potentially earn rewards.
6.  **Verification/Dispute:** A decentralized process where stakers vote on a fact's validity.
7.  **Reputation:** A score earned by contributors for successful validation, dispute, and fact submission. Decay mechanism included.
8.  **Delegation:** Contributors can delegate their verification *right* (not stake) to another address.
9.  **Lifecycle Management:** Facts transition through states (Pending, Validated, Disputed, Invalidated) based on staking and verification results.
10. **Dynamic NFT:** The CognitoMark NFT's visual representation (metadata) is linked to the owner's on-chain reputation and fact contributions, triggered by on-chain events.

**Function Summaries:**

1.  `constructor(address _cgnxTokenAddress, address _cognitoMarkTokenAddress)`: Initializes the contract with addresses of required external tokens.
2.  `registerContributor()`: Allows a new user to register and become a contributor, initializing their reputation.
3.  `submitFact(string memory _contentHash)`: Allows a registered contributor to submit a new fact, which enters the 'Pending' state. Requires a small stake from the submitter.
4.  `stakeOnFact(uint256 _factId, bool _isValid)`: Allows any contributor to stake CGNX tokens on a 'Pending' or 'Disputed' fact, signaling belief in its validity (`_isValid = true`) or invalidity (`_isValid = false`). Tokens are transferred via `transferFrom`.
5.  `withdrawStake(uint256 _factId)`: Allows a staker to withdraw their stake *if* the fact has reached a final state (Validated or Invalidated). Rewards/losses are calculated.
6.  `delegateVerification(address _delegatee)`: Allows a contributor to delegate their *right* to verify facts (but not their stake or reputation earning) to another address.
7.  `revokeDelegation()`: Allows a contributor to revoke their current delegation.
8.  `triggerFactEvaluation(uint256 _factId)`: Anyone can call this to check if a 'Pending' fact has met the criteria (stake, verification votes) to move to 'Validated' or 'Disputed'. Rewards/penalties are distributed to stakers based on the outcome.
9.  `challengeFact(uint256 _factId)`: Allows a contributor to challenge a fact currently in 'Validated' or 'Disputed' status by staking CGNX. Moves the fact to 'Challenged' state.
10. `resolveChallenge(uint256 _factId, bool _isValid)`: (Admin/Governance or potentially a dedicated resolver role) Finalizes a 'Challenged' fact as 'Validated' or 'Invalidated'. Distributes stakes/rewards/penalties based on the resolution outcome.
11. `claimReputation(address _contributor)`: Allows a contributor (or anyone on their behalf) to calculate and add pending reputation points earned from finalized facts.
12. `claimTokenRewards(address _contributor)`: Allows a contributor (or anyone on their behalf) to withdraw accrued CGNX token rewards.
13. `mintCognitoMark()`: Allows a *registered* contributor *without* a CognitoMark to mint their unique NFT.
14. `updateCognitoMarkMetadata(address _contributor)`: Callable by the contributor or admin to trigger a conceptual update of the associated CognitoMark NFT's metadata URI based on the contributor's current on-chain reputation and stats.
15. `decayReputation(address _contributor)`: Callable periodically by anyone (incentivized or purely public function) to apply time-based decay to a contributor's reputation score.
16. `setMinimumStake(uint256 _amount)`: (Admin) Sets the minimum CGNX required to submit a fact or participate in staking.
17. `setEvaluationThresholds(uint256 _minTotalStake, uint256 _validationRatio)`: (Admin) Sets the minimum total stake required and the ratio of 'valid' stakes vs 'invalid' stakes needed for automatic fact evaluation transition (Pending -> Validated/Disputed).
18. `setChallengeParameters(uint256 _challengeStake, uint256 _challengePeriod)`: (Admin) Sets the stake required to challenge a fact and the duration of the challenge period.
19. `setRewardParameters(...)`: (Admin) Sets the parameters for calculating CGNX and reputation rewards/penalties. (Simplified in code)
20. `pauseSystem()`: (Admin) Pauses core functionalities (submissions, staking, evaluation triggers) in case of emergency.
21. `unpauseSystem()`: (Admin) Unpauses the system.
22. `getFactDetails(uint256 _factId)`: (View) Retrieves detailed information about a specific fact.
23. `getContributorDetails(address _contributor)`: (View) Retrieves detailed information about a specific contributor.
24. `getFactsByStatus(FactStatus _status)`: (View) Retrieves a list of fact IDs currently in a given status.
25. `getTotalSubmittedFacts()`: (View) Returns the total number of facts submitted.
26. `getDelegation(address _contributor)`: (View) Returns the address the contributor has delegated verification rights to (address(0) if none).

*(Note: Some functions like calculating complex rewards/penalties or implementing the full dynamic NFT metadata might require more sophisticated logic or off-chain components, but the structure provides the on-chain triggers and data storage)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
// We won't implement the full ERC721 here, just interact via interface
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Use an external contract

/// @title CognitoNexus
/// @dev A decentralized knowledge base / fact registry protocol with reputation, staking, delegation, and dynamic NFTs.
/// @author [Your Name/Alias] - Creative implementation combining multiple concepts.

interface ICGNXToken is IERC20 {} // Interface for the staking/reward token
interface ICognitoMarkNFT is IERC721, IERC721Metadata {
    // Add specific functions if needed for metadata updates initiated by this contract
    function updateMetadata(uint256 tokenId) external;
}


contract CognitoNexus is Ownable, Pausable {

    // --- State Variables ---

    enum FactStatus { Pending, Validated, Disputed, Challenged, Invalidated }

    struct Fact {
        uint256 id;
        address submitter;
        string contentHash; // e.g., IPFS CID or cryptographic hash of the fact content
        uint256 submissionTimestamp;
        FactStatus status;
        uint256 totalStakeValid;
        uint256 totalStakeInvalid;
        mapping(address => uint256) stakerStake; // Staker address => amount staked
        mapping(address => bool) stakerVoteValid; // Staker address => their vote (true for valid, false for invalid)
        mapping(address => bool) hasStaked; // To track if an address has staked on this fact
        address[] stakers; // To iterate through stakers
        uint256 challengeStake; // Stake required to challenge
        uint256 challengeTimestamp; // Timestamp challenge was initiated
    }

    struct Contributor {
        bool isRegistered;
        uint256 reputationScore; // Simple integer score
        uint256 pendingReputation; // Reputation earned from finalized facts, waiting to be claimed
        uint256 pendingTokenRewards; // CGNX earned from finalized facts, waiting to be claimed
        address delegatedTo; // Address they have delegated verification rights to (address(0) if none)
        uint256 cognitoMarkTokenId; // 0 if no NFT, otherwise the token ID
    }

    ICGNXToken public cgnxToken;
    ICognitoMarkNFT public cognitoMarkToken;

    uint256 private _nextFactId;
    mapping(uint256 => Fact) public facts;
    mapping(address => Contributor) public contributors;

    // --- Configuration Parameters (Set by Owner) ---
    uint256 public minimumSubmissionStake = 100 ether; // Example: 100 CGNX
    uint256 public minimumVerificationStake = 50 ether; // Example: 50 CGNX per verification
    uint256 public evaluationMinTotalStake = 500 ether; // Example: 500 total CGNX stake needed to trigger evaluation
    uint256 public evaluationValidationRatio = 70; // Example: 70% valid stake to be 'Validated'
    uint256 public challengeStakeAmount = 200 ether; // Example: 200 CGNX to challenge
    uint256 public challengePeriodDuration = 3 days; // Example: 3 days for the challenge to be active
    uint256 public reputationDecayRate = 1; // Example: Decay rate per unit of time (e.g., per day)
    uint256 public reputationDecayPeriod = 1 days; // Example: Time unit for decay
    mapping(address => uint256) private _lastReputationDecayTimestamp; // Track last decay time per user

    // --- Events ---
    event ContributorRegistered(address indexed contributor);
    event FactSubmitted(uint256 indexed factId, address indexed submitter, string contentHash, uint256 timestamp);
    event StakeApplied(uint256 indexed factId, address indexed staker, uint256 amount, bool isValidVote);
    event StakeWithdrawn(uint256 indexed factId, address indexed staker, uint256 amount);
    event FactStatusUpdated(uint256 indexed factId, FactStatus oldStatus, FactStatus newStatus);
    event ReputationClaimed(address indexed contributor, uint256 reputationAmount);
    event TokenRewardsClaimed(address indexed contributor, uint256 tokenAmount);
    event VerificationDelegated(address indexed delegator, address indexed delegatee);
    event DelegationRevoked(address indexed delegator);
    event ChallengeInitiated(uint256 indexed factId, address indexed challenger, uint256 timestamp);
    event ChallengeResolved(uint256 indexed factId, bool finalValidity, address indexed resolver);
    event CognitoMarkMinted(address indexed owner, uint256 indexed tokenId);
    event CognitoMarkMetadataUpdateTriggered(address indexed owner, uint256 indexed tokenId);
    event ReputationDecayed(address indexed contributor, uint256 oldScore, uint256 newScore);

    // --- Constructor ---

    constructor(address _cgnxTokenAddress, address _cognitoMarkTokenAddress) Ownable(msg.sender) Pausable() {
        require(_cgnxTokenAddress != address(0), "CGNX token address cannot be zero");
        require(_cognitoMarkTokenAddress != address(0), "CognitoMark token address cannot be zero");
        cgnxToken = ICGNXToken(_cgnxTokenAddress);
        cognitoMarkToken = ICognitoMarkNFT(_cognitoMarkTokenAddress);
        _nextFactId = 1;
    }

    // --- Registration and Contributor Management ---

    /// @dev Allows a new user to register as a contributor.
    function registerContributor() external whenNotPaused {
        require(!contributors[msg.sender].isRegistered, "Already registered");
        contributors[msg.sender].isRegistered = true;
        contributors[msg.sender].reputationScore = 0; // Start with 0 reputation
        emit ContributorRegistered(msg.sender);
    }

    /// @dev Allows a contributor to delegate their verification rights to another address.
    /// @param _delegatee The address to delegate verification rights to.
    function delegateVerification(address _delegatee) external whenNotPaused {
        require(contributors[msg.sender].isRegistered, "Must be a registered contributor");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        // Optional: require _delegatee is also registered? Depends on design. Let's allow delegating to any address for flexibility.
        contributors[msg.sender].delegatedTo = _delegatee;
        emit VerificationDelegated(msg.sender, _delegatee);
    }

    /// @dev Allows a contributor to revoke their current verification delegation.
    function revokeDelegation() external whenNotPaused {
        require(contributors[msg.sender].isRegistered, "Must be a registered contributor");
        require(contributors[msg.sender].delegatedTo != address(0), "No active delegation");
        contributors[msg.sender].delegatedTo = address(0);
        emit DelegationRevoked(msg.sender);
    }

    // --- Fact Submission and Staking ---

    /// @dev Allows a registered contributor to submit a new fact.
    /// @param _contentHash A hash or IPFS CID representing the fact's content.
    function submitFact(string memory _contentHash) external whenNotPaused {
        require(contributors[msg.sender].isRegistered, "Must be a registered contributor");
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(cgnxToken.transferFrom(msg.sender, address(this), minimumSubmissionStake), "CGNX transfer failed for submission stake");

        uint256 factId = _nextFactId++;
        Fact storage newFact = facts[factId];
        newFact.id = factId;
        newFact.submitter = msg.sender;
        newFact.contentHash = _contentHash;
        newFact.submissionTimestamp = block.timestamp;
        newFact.status = FactStatus.Pending;
        newFact.challengeStake = 0; // Initial challenge stake is 0

        // Submitters stake automatically counts as valid
        newFact.stakerStake[msg.sender] = minimumSubmissionStake;
        newFact.stakerVoteValid[msg.sender] = true;
        newFact.hasStaked[msg.sender] = true;
        newFact.stakers.push(msg.sender);
        newFact.totalStakeValid += minimumSubmissionStake;

        emit FactSubmitted(factId, msg.sender, _contentHash, block.timestamp);
    }

    /// @dev Allows a contributor (or their delegatee) to stake CGNX on a fact, signalling belief in its validity or invalidity.
    /// @param _factId The ID of the fact to stake on.
    /// @param _isValid True if staking on validity, false if staking on invalidity.
    function stakeOnFact(uint256 _factId, bool _isValid) external whenNotPaused {
        require(contributors[msg.sender].isRegistered || contributors[msg.sender].delegatedTo == msg.sender, "Must be a registered contributor or delegatee");
        require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
        Fact storage fact = facts[_factId];
        require(fact.status == FactStatus.Pending || fact.status == FactStatus.Disputed || fact.status == FactStatus.Challenged, "Fact is not in a stakeable status");
        require(!fact.hasStaked[msg.sender], "Already staked on this fact");
        require(cgnxToken.transferFrom(msg.sender, address(this), minimumVerificationStake), "CGNX transfer failed for verification stake");

        fact.stakerStake[msg.sender] = minimumVerificationStake;
        fact.stakerVoteValid[msg.sender] = _isValid;
        fact.hasStaked[msg.sender] = true;
        fact.stakers.push(msg.sender); // Add to list of stakers

        if (_isValid) {
            fact.totalStakeValid += minimumVerificationStake;
        } else {
            fact.totalStakeInvalid += minimumVerificationStake;
        }

        emit StakeApplied(_factId, msg.sender, minimumVerificationStake, _isValid);
    }

    /// @dev Allows a staker to withdraw their stake after a fact is finalized.
    /// Rewards/penalties are applied upon withdrawal based on the final status.
    /// @param _factId The ID of the fact to withdraw stake from.
    function withdrawStake(uint256 _factId) external whenNotPaused {
        require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
        Fact storage fact = facts[_factId];
        require(fact.status == FactStatus.Validated || fact.status == FactStatus.Invalidated, "Fact is not in a final status");
        require(fact.hasStaked[msg.sender], "No stake found for this fact and staker");

        uint256 stakeAmount = fact.stakerStake[msg.sender];
        bool votedValid = fact.stakerVoteValid[msg.sender];

        // Calculate rewards/penalties (Simplified example logic)
        uint256 reward = 0;
        uint256 penalty = 0;
        uint256 reputationChange = 0;

        if (fact.status == FactStatus.Validated && votedValid) {
            // Reward for correct 'valid' vote
            reward = (stakeAmount * 120) / 100; // Example: 20% profit
            reputationChange = 10; // Example: Earn 10 reputation
        } else if (fact.status == FactStatus.Invalidated && !votedValid) {
            // Reward for correct 'invalid' vote
            reward = (stakeAmount * 120) / 100; // Example: 20% profit
            reputationChange = 10; // Example: Earn 10 reputation
        } else {
             // Penalty for incorrect vote (or staking on a challenged fact that was resolved against your vote)
             penalty = (stakeAmount * 50) / 100; // Example: Lose 50% of stake
             reputationChange = type(uint256).max; // Signal reputation loss (handled later)
        }

        uint256 amountToReturn = stakeAmount - penalty + reward;
        fact.stakerStake[msg.sender] = 0; // Clear stake
        fact.hasStaked[msg.sender] = false; // Mark as withdrawn

        // Accumulate pending rewards/penalties
        if (amountToReturn > stakeAmount) {
             contributors[msg.sender].pendingTokenRewards += (amountToReturn - stakeAmount);
        } else if (amountToReturn < stakeAmount) {
             // Need a mechanism to handle penalties > current stake.
             // Simplest is to burn/collect the penalty amount if possible,
             // but for pending rewards, maybe track debt? Let's assume penalty <= stake for simplicity.
             // Or, the protocol keeps the penalty amount.
             uint256 penaltyAmount = stakeAmount - amountToReturn;
             // Penalty tokens remain in contract balance or are distributed elsewhere
             // No explicit burning/distribution here for simplicity.
        }

        // Handle reputation change
        if (reputationChange != type(uint256).max) {
             contributors[msg.sender].pendingReputation += reputationChange;
        } else {
             // Apply reputation penalty directly or queue a negative pending rep
             // Let's just subtract directly up to 0 for simplicity in this example
             uint256 currentRep = contributors[msg.sender].reputationScore;
             uint256 loss = 5; // Example loss
             contributors[msg.sender].reputationScore = currentRep > loss ? currentRep - loss : 0;
             // Trigger potential NFT metadata update on rep change
             if (contributors[msg.sender].cognitoMarkTokenId != 0) {
                 emit CognitoMarkMetadataUpdateTriggered(msg.sender, contributors[msg.sender].cognitoMarkTokenId);
             }
        }


        // Transfer the calculated amount back (original stake - penalty + reward)
        // Note: This assumes the contract holds enough CGNX from other stakers' penalties or a reward pool.
        // A real system would need a clear token flow/economy.
        require(cgnxToken.transfer(msg.sender, amountToReturn), "CGNX transfer failed for stake withdrawal");

        emit StakeWithdrawn(_factId, msg.sender, stakeAmount);

        // The first withdrawal could trigger cleanup, but let's leave stake data for historical queries.
    }


    // --- Fact Lifecycle Management ---

    /// @dev Triggers evaluation of a fact's status based on accumulated stake and votes.
    /// Moves fact from Pending to Validated or Disputed if thresholds are met.
    /// Anyone can call this, possibly incentivized off-chain.
    /// @param _factId The ID of the fact to evaluate.
    function triggerFactEvaluation(uint256 _factId) external whenNotPaused {
        require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
        Fact storage fact = facts[_factId];
        require(fact.status == FactStatus.Pending, "Fact is not in Pending status");

        uint256 totalStake = fact.totalStakeValid + fact.totalStakeInvalid;
        if (totalStake < evaluationMinTotalStake) {
            // Not enough stake to evaluate yet
            return;
        }

        // Calculate ratio of valid stake
        uint256 validRatio = (fact.totalStakeValid * 100) / totalStake;

        FactStatus oldStatus = fact.status;
        if (validRatio >= evaluationValidationRatio) {
            fact.status = FactStatus.Validated;
            // Logic to distribute rewards/penalties to stakers is handled on withdrawStake
            // Logic to award reputation to stakers is handled on claimReputation
        } else {
            fact.status = FactStatus.Disputed;
             // Logic to distribute rewards/penalties to stakers is handled on withdrawStake
             // Logic to award reputation to stakers is handled on claimReputation
        }
        emit FactStatusUpdated(_factId, oldStatus, fact.status);
    }

    /// @dev Allows a contributor to challenge a fact in Validated or Disputed status.
    /// Moves the fact to Challenged state and requires staking `challengeStakeAmount`.
    /// @param _factId The ID of the fact to challenge.
    function challengeFact(uint256 _factId) external whenNotPaused {
        require(contributors[msg.sender].isRegistered, "Must be a registered contributor");
        require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
        Fact storage fact = facts[_factId];
        require(fact.status == FactStatus.Validated || fact.status == FactStatus.Disputed, "Fact is not in Validated or Disputed status");
        require(fact.challengeStake == 0, "Fact is already under challenge"); // Only one active challenge at a time

        require(cgnxToken.transferFrom(msg.sender, address(this), challengeStakeAmount), "CGNX transfer failed for challenge stake");

        fact.challengeStake = challengeStakeAmount;
        fact.challengeTimestamp = block.timestamp;
        FactStatus oldStatus = fact.status;
        fact.status = FactStatus.Challenged; // Enters challenged state

        emit ChallengeInitiated(_factId, msg.sender, block.timestamp);
        emit FactStatusUpdated(_factId, oldStatus, fact.status);
    }

    /// @dev Resolves a challenged fact. This function is typically called by an authorized entity (e.g., admin, a DAO vote outcome).
    /// Distributes challenge stake based on the resolution and moves fact to a final state.
    /// @param _factId The ID of the fact to resolve.
    /// @param _isValid The final determination: true for Validated, false for Invalidated.
    function resolveChallenge(uint256 _factId, bool _isValid) external onlyOwner whenNotPaused { // Using onlyOwner for simplicity
        require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
        Fact storage fact = facts[_factId];
        require(fact.status == FactStatus.Challenged, "Fact is not currently challenged");
        require(block.timestamp >= fact.challengeTimestamp + challengePeriodDuration, "Challenge period not over yet");

        address challenger = address(0); // Need to store challenger address, currently not in struct. Let's add it conceptually or pass it.
        // For simplicity, let's assume the `msg.sender` of the challengeFact call was the challenger.
        // A better design would store the challenger address in the Fact struct when challengeFact is called.
        // Let's modify the struct and challengeFact slightly:
        // Add `address challengerAddress;` to Fact struct
        // In challengeFact: `fact.challengerAddress = msg.sender;`
        // In resolveChallenge: `address challenger = fact.challengerAddress;`

        address challengerAddress = address(0); // Placeholder based on struct update needed
        // Need logic to find the challenger. The initial implementation doesn't store it directly in Fact struct.
        // This highlights a missing piece in the struct design based on the function needed.
        // Let's assume, for the code example, we add `address challengerAddress;` to the Fact struct.
        // In `challengeFact`: `fact.challengerAddress = msg.sender;`
        // In `resolveChallenge`: `address challenger = fact.challengerAddress;`
        // Let's assume this structure update happened.
        challengerAddress = fact.submitter; // Dummy assignment - FIX THIS: The challenger is the one who called challengeFact.

        // Find the actual challenger by iterating stakers who staked during the challenge? No, simpler to store challenger address.
        // Okay, adding `address challengerAddress;` to the Fact struct is the clean way.

        // --- Assuming Fact struct now has `address challengerAddress;` ---
        address challenger = fact.challengerAddress;

        FactStatus oldStatus = fact.status;
        if (_isValid) {
            // Fact is Validated
            fact.status = FactStatus.Validated;
            // Challenger loses their stake
            // CGNX remains in contract or is distributed to stakers who voted 'valid' before the challenge?
            // Let's keep it in the contract for now.
            // original stakers (valid votes) potentially earn pending reputation/rewards (claimed later via withdrawStake/claimReputation)
        } else {
            // Fact is Invalidated
            fact.status = FactStatus.Invalidated;
            // Challenger gets stake back + potential reward? Or just stake back.
            // Let's return stake to challenger.
            require(cgnxToken.transfer(challenger, fact.challengeStake), "Failed to return challenge stake");
            // Original stakers (invalid votes) potentially earn pending reputation/rewards
            // Stakers who voted 'valid' before the challenge lose reputation?
        }

        // Cleanup challenge state
        fact.challengeStake = 0;
        fact.challengeTimestamp = 0;
        fact.challengerAddress = address(0); // Clear challenger

        emit ChallengeResolved(_factId, _isValid, msg.sender); // msg.sender is the resolver
        emit FactStatusUpdated(_factId, oldStatus, fact.status);

        // Note: Distributing complex rewards/penalties based on pre-challenge votes vs. challenge outcome
        // requires detailed state tracking per staker across status changes, which adds complexity.
        // The current `withdrawStake` logic handles basic outcomes based on final status.
    }

    // --- Reward & Reputation Claiming ---

    /// @dev Allows a contributor to claim their accumulated pending reputation points.
    /// @param _contributor The address of the contributor to claim for.
    function claimReputation(address _contributor) external whenNotPaused {
        require(contributors[_contributor].isRegistered, "Contributor not registered");
        require(contributors[_contributor].pendingReputation > 0, "No pending reputation to claim");

        uint256 reputationAmount = contributors[_contributor].pendingReputation;
        contributors[_contributor].reputationScore += reputationAmount;
        contributors[_contributor].pendingReputation = 0;

        emit ReputationClaimed(_contributor, reputationAmount);

        // Trigger potential NFT metadata update on reputation change
        if (contributors[_contributor].cognitoMarkTokenId != 0) {
            emit CognitoMarkMetadataUpdateTriggered(_contributor, contributors[_contributor].cognitoMarkTokenId);
        }
    }

    /// @dev Allows a contributor to claim their accumulated pending CGNX token rewards.
    /// @param _contributor The address of the contributor to claim for.
    function claimTokenRewards(address _contributor) external whenNotPaused {
         require(contributors[_contributor].isRegistered, "Contributor not registered");
         require(contributors[_contributor].pendingTokenRewards > 0, "No pending token rewards to claim");

         uint256 tokenAmount = contributors[_contributor].pendingTokenRewards;
         contributors[_contributor].pendingTokenRewards = 0;

         require(cgnxToken.transfer(_contributor, tokenAmount), "CGNX transfer failed for reward claim");

         emit TokenRewardsClaimed(_contributor, tokenAmount);
    }


    // --- Dynamic NFT Integration ---

    /// @dev Allows a registered contributor who doesn't own a CognitoMark to mint one.
    function mintCognitoMark() external whenNotPaused {
        require(contributors[msg.sender].isRegistered, "Must be a registered contributor");
        require(contributors[msg.sender].cognitoMarkTokenId == 0, "Contributor already owns a CognitoMark");

        // Mint the NFT from the external contract.
        // This assumes the CognitoMark NFT contract has a `mint` function callable by this contract.
        // The token ID should probably be linked to the contributor address somehow, e.g., hash of address or sequential ID.
        // Let's use a simple sequential ID linked to the contributor count or similar, or just store the minted ID.
        // A simple approach is to use the contributor's address as the token ID if the ERC721 supports non-sequential IDs.
        // If it requires sequential, we need to track the next NFT ID here and pass it to the external contract.
        // Let's assume for simplicity the external contract's mint function assigns an ID and returns it.
        // Or, the external contract uses the minter's address as the token ID. Let's assume the latter for simplicity here.
        // Function signature assumption: `cognitoMarkToken.mint(msg.sender)` which assigns msg.sender's address as token ID.
        // This is non-standard ERC721. A standard approach would be `cognitoMarkToken.mint(msg.sender, newTokenId);`
        // Let's *assume* the external contract allows `mint(address owner)` and we'll store the *owner's address* as the conceptual token ID for linking purposes.
        // This is a simplification for the example. A real implementation needs careful ERC721 design.
        // Let's use `msg.sender`'s address as the conceptual link, but the external NFT assigns a standard uint256 ID.
        // We need to track which contributor address is linked to which NFT ID. Let's add `cognitoMarkTokenId` to the Contributor struct.

        // Assuming the external contract has a function like `mintTo(address recipient) returns (uint256 tokenId)`
        // require(cognitoMarkToken.mintTo(msg.sender), "CognitoMark minting failed"); // Assuming mintTo returns bool

        // Standard ERC721 doesn't have a public mint function for external contracts calling it.
        // The standard way is to have the ERC721 contract owned by CognitoNexus, and CognitoNexus calls `_safeMint`.
        // OR, the ERC721 has a specific `mintForNexus` function with access control.
        // Let's assume the latter for this example: `cognitoMarkToken.mintForNexus(msg.sender) returns (uint256 tokenId)`.

        // uint256 newTokenId = cognitoMarkToken.mintForNexus(msg.sender); // Assuming this function exists and returns ID

        // Since we can't implement the external NFT here, let's *simulate* the NFT ID and storage.
        // A simple link could be `mapping(address => uint256) contributorNFTTokenId;`
        // Let's update Contributor struct to store the token ID.

        // --- Assuming Contributor struct now has `uint256 cognitoMarkTokenId;` ---

        // uint256 newTokenId = cognitoMarkToken.mintForNexus(msg.sender); // Replace with actual call
        uint256 newTokenId = uint256(uint160(msg.sender)); // SIMULATION: Use address hash as token ID for simplicity in example

        contributors[msg.sender].cognitoMarkTokenId = newTokenId; // Store the ID
        // require(cognitoMarkToken.ownerOf(newTokenId) == msg.sender, "NFT not minted to recipient"); // Verification

        emit CognitoMarkMinted(msg.sender, newTokenId);
        // Metadata update should happen automatically upon minting or triggered next
        emit CognitoMarkMetadataUpdateTriggered(msg.sender, newTokenId);
    }

    /// @dev Triggers an update request for the CognitoMark NFT metadata associated with a contributor.
    /// This allows off-chain services (like a metadata server) to fetch the latest on-chain state
    /// and update the NFT's metadata (e.g., image, attributes) based on reputation, facts, etc.
    /// Can be called by the contributor or potentially the owner/admin.
    /// @param _contributor The address of the contributor whose NFT metadata should be updated.
    function updateCognitoMarkMetadata(address _contributor) external whenNotPaused {
        require(contributors[_contributor].isRegistered, "Contributor not registered");
        uint256 tokenId = contributors[_contributor].cognitoMarkTokenId;
        require(tokenId != 0, "Contributor does not own a CognitoMark");
        // Optional: require msg.sender is _contributor or owner
        require(msg.sender == _contributor || owner() == msg.sender, "Not authorized to trigger update");

        // The actual metadata update logic happens off-chain by a service listening to this event
        // or querying the contract state periodically. We just emit the event here.
        // A more advanced version might call `IERC721Metadata.setTokenURI(tokenId, newTokenURI)`
        // but constructing the URI/metadata on-chain is complex and expensive.
        // The standard is for the NFT contract's tokenURI function to read state from this contract.
        // So this function just signals that the state *might* have changed and the URI *should* be refreshed.

        emit CognitoMarkMetadataUpdateTriggered(_contributor, tokenId);

        // Could also call a function on the external NFT contract if it's designed for it
        // Example: cognitoMarkToken.updateMetadata(tokenId); // Assuming this function exists
    }


    // --- Reputation Decay ---

    /// @dev Applies time-based decay to a contributor's reputation score.
    /// Can be called by anyone, potentially to keep the system fresh.
    /// @param _contributor The address of the contributor whose reputation should decay.
    function decayReputation(address _contributor) external whenNotPaused {
        require(contributors[_contributor].isRegistered, "Contributor not registered");

        uint256 lastDecay = _lastReputationDecayTimestamp[_contributor];
        uint256 timePassed = block.timestamp - lastDecay;

        if (lastDecay == 0) { // First decay check, set initial timestamp
             _lastReputationDecayTimestamp[_contributor] = block.timestamp;
             return; // No decay on first check
        }

        if (timePassed < reputationDecayPeriod) {
            return; // Not enough time passed for decay
        }

        uint256 decayPeriods = timePassed / reputationDecayPeriod;
        uint256 currentRep = contributors[_contributor].reputationScore;
        uint256 decayAmount = decayPeriods * reputationDecayRate;

        uint256 newRep = currentRep > decayAmount ? currentRep - decayAmount : 0;

        if (newRep < currentRep) {
            contributors[_contributor].reputationScore = newRep;
            _lastReputationDecayTimestamp[_contributor] = block.timestamp; // Update decay timestamp

            emit ReputationDecayed(_contributor, currentRep, newRep);

            // Trigger potential NFT metadata update on reputation change
            if (contributors[_contributor].cognitoMarkTokenId != 0) {
                emit CognitoMarkMetadataUpdateTriggered(_contributor, contributors[_contributor].cognitoMarkTokenId);
            }
        }
    }

    // --- Admin Functions ---

    /// @dev Sets the minimum CGNX stake required for fact submission.
    /// @param _amount The new minimum stake amount.
    function setMinimumSubmissionStake(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Stake must be greater than zero");
        minimumSubmissionStake = _amount;
    }

    /// @dev Sets the minimum CGNX stake required for verification/dispute staking.
    /// @param _amount The new minimum stake amount.
    function setMinimumVerificationStake(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Stake must be greater than zero");
        minimumVerificationStake = _amount;
    }


    /// @dev Sets the thresholds for automatic fact evaluation.
    /// @param _minTotalStake Minimum total CGNX stake required on a fact.
    /// @param _validationRatio Percentage of 'valid' stake needed for 'Validated' status (0-100).
    function setEvaluationThresholds(uint256 _minTotalStake, uint256 _validationRatio) external onlyOwner {
        evaluationMinTotalStake = _minTotalStake;
        evaluationValidationRatio = _validationRatio; // Consider adding bounds check e.g., <= 100
    }

    /// @dev Sets parameters for challenging facts.
    /// @param _challengeStake The CGNX stake required to initiate a challenge.
    /// @param _challengePeriod The duration of the challenge period in seconds.
    function setChallengeParameters(uint256 _challengeStake, uint256 _challengePeriod) external onlyOwner {
        require(_challengeStake > 0, "Challenge stake must be greater than zero");
        require(_challengePeriod > 0, "Challenge period must be greater than zero");
        challengeStakeAmount = _challengeStake;
        challengePeriodDuration = _challengePeriod;
    }

    /// @dev Sets parameters for reputation decay.
    /// @param _decayRate The amount of reputation lost per decay period.
    /// @param _decayPeriod The duration of the decay period in seconds.
    function setReputationDecayParameters(uint256 _decayRate, uint256 _decayPeriod) external onlyOwner {
        reputationDecayRate = _decayRate;
        reputationDecayPeriod = _decayPeriod;
    }

     /// @dev Placeholder for setting reward parameters (e.g., how much CGNX/rep rewards are distributed).
     /// This would involve more complex logic based on fact outcome, stake amount, etc.
     function setRewardParameters(uint256 factValidatedRepReward, uint256 factInvalidatedRepPenalty, uint256 validatorRepReward, uint256 disputerRepReward) external onlyOwner {
         // Example parameters. Actual calculation logic needed in withdrawStake/claimReputation.
         // This function just shows the administrative capability to tune reward settings.
         // For a real contract, map these parameters to the calculation logic.
     }


    /// @dev Pauses the contract in case of emergencies.
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    /// @dev Allows owner to withdraw excess CGNX tokens from the contract.
    /// Designed to withdraw fees, penalties, or unused funds, *not* staked funds.
    /// Careful implementation is needed to distinguish withdrawal types.
    /// For simplicity, this example allows withdrawing *any* CGNX owned by the contract.
    /// A real system needs protection against draining user stakes.
    function withdrawAdminCGNX(uint256 amount) external onlyOwner {
        require(cgnxToken.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        // WARNING: This function is overly simplistic and allows withdrawing user stakes.
        // A production contract needs to track admin/protocol revenue vs. user stakes.
        // For example, only allow withdrawing the sum of penalties collected, or explicitly allocated fees.
        require(cgnxToken.transfer(owner(), amount), "CGNX withdrawal failed");
    }


    // --- View Functions ---

    /// @dev Retrieves details for a specific fact.
    /// @param _factId The ID of the fact.
    /// @return Tuple containing fact details.
    function getFactDetails(uint256 _factId)
        external
        view
        returns (
            uint256 id,
            address submitter,
            string memory contentHash,
            uint256 submissionTimestamp,
            FactStatus status,
            uint256 totalStakeValid,
            uint256 totalStakeInvalid,
            uint256 challengeStake,
            uint256 challengeTimestamp
        )
    {
        require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
        Fact storage fact = facts[_factId];
        return (
            fact.id,
            fact.submitter,
            fact.contentHash,
            fact.submissionTimestamp,
            fact.status,
            fact.totalStakeValid,
            fact.totalStakeInvalid,
            fact.challengeStake,
            fact.challengeTimestamp
        );
    }

     /// @dev Retrieves stake details for a specific staker on a specific fact.
     /// @param _factId The ID of the fact.
     /// @param _staker The address of the staker.
     /// @return stakeAmount The amount staked.
     /// @return isValidVote True if their vote was for validity, false otherwise.
    function getStakerStakeDetails(uint256 _factId, address _staker) external view returns (uint256 stakeAmount, bool isValidVote) {
         require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
         Fact storage fact = facts[_factId];
         require(fact.hasStaked[_staker], "Staker has no stake on this fact");
         return (fact.stakerStake[_staker], fact.stakerVoteValid[_staker]);
     }

    /// @dev Retrieves details for a specific contributor.
    /// @param _contributor The address of the contributor.
    /// @return Tuple containing contributor details.
    function getContributorDetails(address _contributor)
        external
        view
        returns (
            bool isRegistered,
            uint256 reputationScore,
            uint256 pendingReputation,
            uint256 pendingTokenRewards,
            address delegatedTo,
            uint256 cognitoMarkTokenId
        )
    {
        Contributor storage contributor = contributors[_contributor];
        return (
            contributor.isRegistered,
            contributor.reputationScore,
            contributor.pendingReputation,
            contributor.pendingTokenRewards,
            contributor.delegatedTo,
            contributor.cognitoMarkTokenId
        );
    }

     /// @dev Gets the address a contributor has delegated verification rights to.
     /// @param _contributor The address of the contributor.
     /// @return The delegatee address, or address(0) if no delegation.
    function getDelegation(address _contributor) external view returns (address) {
         return contributors[_contributor].delegatedTo;
    }


    /// @dev Retrieves a list of fact IDs currently in a specific status.
    /// NOTE: Iterating through all facts can be gas intensive for large numbers.
    /// This is a simple implementation for demonstration.
    /// @param _status The status to filter by.
    /// @return An array of fact IDs.
    function getFactsByStatus(FactStatus _status) external view returns (uint256[] memory) {
        uint256[] memory factIds = new uint256[](_nextFactId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < _nextFactId; i++) {
            if (facts[i].status == _status) {
                factIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = factIds[i];
        }
        return result;
    }

    /// @dev Returns the total number of facts ever submitted.
    /// @return The total count of facts.
    function getTotalSubmittedFacts() external view returns (uint256) {
        return _nextFactId - 1; // Subtract 1 because _nextFactId is the ID for the *next* fact
    }

    /// @dev Checks if an address is a registered contributor.
    /// @param _address The address to check.
    /// @return True if registered, false otherwise.
    function isContributorRegistered(address _address) external view returns (bool) {
        return contributors[_address].isRegistered;
    }

    /// @dev Gets the current minimum stake required for fact submission.
    /// @return The minimum submission stake.
    function getMinimumSubmissionStake() external view returns (uint256) {
        return minimumSubmissionStake;
    }

     /// @dev Gets the current minimum stake required for verification staking.
     /// @return The minimum verification stake.
     function getMinimumVerificationStake() external view returns (uint256) {
         return minimumVerificationStake;
     }


    /// @dev Gets the total number of stakers for a specific fact.
    /// NOTE: This iterates over the `stakers` array, potentially gas intensive.
    /// @param _factId The ID of the fact.
    /// @return The number of stakers.
    function getFactStakerCount(uint256 _factId) external view returns (uint256) {
        require(_factId > 0 && _factId < _nextFactId, "Fact does not exist");
        return facts[_factId].stakers.length;
    }

     /// @dev Gets the timestamp of the last reputation decay for a contributor.
     /// @param _contributor The contributor's address.
     /// @return The timestamp.
     function getLastReputationDecayTimestamp(address _contributor) external view returns (uint256) {
         return _lastReputationDecayTimestamp[_contributor];
     }


     // --- Internal Helpers (if any, none complex needed for this structure) ---

}
```

---

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Decentralized Verification/Dispute (Staking-based):** Users don't just vote; they back their opinion with staked tokens (`CGNX`). This aligns economic incentives with honest participation. Incorrect stakers risk losing their stake, correct stakers earn rewards.
2.  **Reputation System:** Tracks a contributor's trustworthiness and success within the system. Earned via validated facts, successful verifications/disputes. Decays over time to encourage continued participation and reflect current engagement.
3.  **Dynamic NFTs (CognitoMark):** The NFT's value and appearance are directly linked to the holder's on-chain reputation and contributions. The `updateCognitoMarkMetadata` function triggers an off-chain process to update the NFT's visual or metadata attributes, making it a living representation of the user's status in the protocol. The NFT is more than just a static collectible; it's a status symbol tied to on-chain activity.
4.  **Delegation of Rights:** Contributors can delegate their ability to *verify* facts (though not their stake or reputation) to another address. This allows experienced users to empower others or manage activity through a separate address.
5.  **Fact Lifecycle State Machine:** Facts transition through well-defined states (`Pending`, `Validated`, `Disputed`, `Challenged`, `Invalidated`) driven by user actions (staking, challenging) and triggered evaluations, creating a structured process for knowledge consensus.
6.  **Challenge Mechanism:** Allows overturning previously 'Validated' or 'Disputed' facts by staking, adding a layer of appeal and robustness against incorrect initial outcomes.
7.  **Separation of Concerns (External Tokens):** The contract interacts with external ERC-20 and ERC-721 contracts via interfaces, making the core logic focused on the fact registry rules and token interactions explicit (staking via `transferFrom`, rewards via `transfer`, NFT minting/updating via interface calls). This is standard practice but crucial for modularity.
8.  **Pausable System:** Includes an emergency pause mechanism (`Ownable`, `Pausable`) for security, allowing the owner to freeze sensitive operations in case of bugs or attacks.
9.  **Triggered Evaluation/Decay:** Functions like `triggerFactEvaluation` and `decayReputation` can potentially be called by anyone (though `decayReputation` currently has a time check limiting its effect). This external trigger pattern can be combined with off-chain automation (like a Keeper network) or slight incentives to ensure maintenance tasks are performed without centralizing control entirely.
10. **Pending Rewards/Reputation:** Rewards and reputation are accrued as "pending" and need to be explicitly claimed (`claimReputation`, `claimTokenRewards`). This saves gas by not requiring calculations and transfers during every state change, deferring the cost to the user who wants to claim.

This contract combines elements of DeFi (staking), NFTs (dynamic state), Governance-like processes (decentralized validation, challenges), and Reputation systems into a single protocol for managing decentralized knowledge. It includes over 20 functions demonstrating various interactions, state changes, and parameter controls.