Okay, let's design a smart contract that facilitates decentralized AI research funding, validation, and outcome representation.

This concept combines elements of:
1.  **Decentralized Science (DeSci):** Funding and validating research in a distributed manner.
2.  **AI/ML:** Focusing the research domain on AI/ML outcomes.
3.  **Attestation/Verification:** Allowing a network of validators to verify claims about AI model performance or research results off-chain, bringing a *proof* of validation on-chain.
4.  **NFTs:** Representing validated research outcomes or access rights.
5.  **Staking & Reputation:** Incentivizing validators and tracking participant reliability.
6.  **Escrow:** Holding funds until validation is complete.

We'll call it **Decentralized AI Research Hub (DAIRH)**.

---

**Smart Contract: Decentralized AI Research Hub (DAIRH)**

**Outline:**

1.  **License and Pragma**
2.  **Interfaces:** For ERC20 (Funding Token) and ERC721 (Result NFT).
3.  **Enums:** Project states, Attestation states.
4.  **Structs:** Project, Attestation, Validator, Challenge.
5.  **State Variables:**
    *   Governance/Owner address.
    *   Accepted Funding Token address.
    *   Result NFT Contract address.
    *   Mappings for Projects, Attestations, Validators, Challenges, User Reputation.
    *   Counters for Project IDs, Attestation IDs, Challenge IDs.
    *   System Parameters (min funding, validation periods, stakes, fees).
    *   Platform Fee accumulator.
6.  **Events:** For state changes, submissions, rewards, etc.
7.  **Modifiers:** `onlyGovernance`, `onlyResearcher`, `onlyValidator`, etc.
8.  **Constructor:** Initialize core addresses and parameters.
9.  **Admin/Governance Functions (approx. 10):**
    *   Set core contract addresses (Governance, Tokens, NFTs).
    *   Adjust system parameters (min funding, stakes, periods, fees).
    *   Withdraw platform fees.
    *   Resolve disputes (governance intervention).
    *   Pause/Unpause contract.
10. **Researcher Functions (approx. 3):**
    *   Propose a new research project.
    *   Submit project outcome (link/hash + performance claims).
    *   Claim rewards (after successful validation).
11. **Funder Functions (approx. 2):**
    *   Fund a project.
    *   Claim refund (if project fails validation).
12. **Validator Functions (approx. 3):**
    *   Register as a validator (stake).
    *   Submit attestation for a project outcome.
    *   Unregister/Unstake (after cooldown).
13. **Dispute Functions (approx. 2):**
    *   Challenge an attestation or outcome claim.
    *   Submit evidence (internal/via challenge details).
14. **Query/View Functions (approx. 8):**
    *   Get project details.
    *   Get attestation details.
    *   Get validator details/stake.
    *   Get user reputation.
    *   Get challenge details.
    *   Get platform fee balance.
    *   Check project state.
    *   Get outcome NFT associated with a project.
15. **Internal/Helper Functions (approx. 2):**
    *   Handle reward distribution and fund transfers.
    *   Mint outcome NFT.
    *   Update reputation scores.

**Function Summary (Total > 20):**

1.  `constructor()`: Initializes governance, token, NFT contract addresses, and default parameters.
2.  `setGovernanceAddress(address _governance)`: Updates the address allowed to call governance functions. (Governance)
3.  `setFundingToken(address _token)`: Sets the address of the accepted ERC20 token for funding. (Governance)
4.  `setResultNFTContract(address _nftContract)`: Sets the address of the ERC721 contract for minting outcome NFTs. (Governance)
5.  `setMinProjectFunding(uint256 _amount)`: Sets the minimum total funding required for a project to become active. (Governance)
6.  `setValidatorStakeAmount(uint256 _amount)`: Sets the ERC20 stake required to register as a validator. (Governance)
7.  `setAttestationStakeAmount(uint256 _amount)`: Sets the additional ERC20 stake required to submit an attestation. (Governance)
8.  `setChallengeStakeAmount(uint256 _amount)`: Sets the ERC20 stake required to challenge an attestation/outcome. (Governance)
9.  `setValidationPeriod(uint256 _duration)`: Sets the time duration for the validation phase. (Governance)
10. `setDisputePeriod(uint256 _duration)`: Sets the time duration for the dispute phase. (Governance)
11. `setPlatformFee(uint256 _percentage)`: Sets the platform fee percentage on successful project funding (e.g., 500 = 5%). (Governance)
12. `withdrawPlatformFees(address payable _recipient)`: Allows governance to withdraw accumulated platform fees. (Governance)
13. `pause()`: Pauses contract activity (except unpausing). (Governance)
14. `unpause()`: Unpauses the contract. (Governance)
15. `proposeProject(string memory _title, string memory _descriptionHash, uint256 _fundingGoal)`: Researcher proposes a new project with details and funding goal.
16. `fundProject(uint256 _projectId, uint256 _amount)`: Funder contributes ERC20 tokens to a project's escrow. Requires prior approval.
17. `submitProjectOutcome(uint256 _projectId, string memory _outcomeHash, string memory _performanceClaimsHash)`: Researcher submits verifiable (off-chain) outcome details and claims.
18. `registerValidator()`: User stakes ERC20 tokens to become a registered validator. Requires `validatorStakeAmount`.
19. `submitAttestation(uint256 _projectId, bool _isPositive, string memory _attestationDetailsHash)`: Validator stakes `attestationStakeAmount` and attests positively or negatively to a project outcome.
20. `challengeAttestation(uint256 _attestationId, string memory _challengeDetailsHash)`: User challenges a specific attestation by staking `challengeStakeAmount`.
21. `resolveChallenge(uint256 _challengeId, bool _challengerWins)`: Governance resolves a challenge, distributing stakes and updating reputation based on outcome. (Governance)
22. `distributeRewards(uint256 _projectId)`: Triggers the distribution of funds, staking rewards, and NFT minting if validation/dispute periods are over.
23. `claimRefund(uint256 _projectId)`: Funder claims their locked funds back if a project fails validation or is cancelled.
24. `getUserReputation(address _user)`: View user's reputation score.
25. `getProjectDetails(uint256 _projectId)`: View details of a specific project.
26. `getProjectFunders(uint256 _projectId)`: View list of addresses that funded the project.
27. `getProjectAttestations(uint256 _projectId)`: View list of attestations for a project outcome.
28. `getValidatorDetails(address _validator)`: View validator's registration status and stake.
29. `getChallengeDetails(uint256 _challengeId)`: View details of a specific challenge.
30. `getPlatformFeeBalance()`: View the total accumulated platform fees.
31. `getProjectState(uint256 _projectId)`: View the current state of a project.
32. `getProjectOutcomeNFT(uint256 _projectId)`: View the ID of the outcome NFT minted for a project (if successful).
33. `unstakeValidator()`: Validator can withdraw their registration stake after a cooldown period, provided they are not involved in active validation/challenges.

---

**Solidity Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interfaces for external contracts
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    // Need other standard functions like allowance, decimals if needed for UI, but not for core logic here.
}

interface IERC721Metadata {
    function safeMint(address to, uint256 tokenId, string calldata uri) external;
    // Assumes the NFT contract handles token ID generation or uses a simple counter
    // and metadata via URI.
    function tokenURI(uint256 tokenId) external view returns (string memory);
    // Add other necessary IERC721 functions if interacting beyond minting
    // function ownerOf(uint256 tokenId) external view returns (address owner);
}

// Custom Errors for clarity and gas efficiency
error DAIRH__NotGovernance();
error DAIRH__NotResearcher(uint256 projectId);
error DAIRH__NotValidator();
error DAIRH__NotFunder(uint256 projectId);
error DAIRH__ProjectNotFound(uint256 projectId);
error DAIRH__ProjectNotInState(uint256 projectId, uint8 expectedState); // Using uint8 for enum ProjectState
error DAIRH__ProjectAlreadyFunded(uint256 projectId);
error DAIRH__FundingGoalNotMet(uint256 projectId);
error DAIRH__InsufficientFundingAmount();
error DAIRH__AttestationNotFound(uint256 attestationId);
error DAIRH__ChallengeNotFound(uint256 challengeId);
error DAIRH__ValidatorNotRegistered(address validator);
error DAIRH__ValidatorAlreadyRegistered(address validator);
error DAIRH__InsufficientStake(uint256 required);
error DAIRH__AlreadySubmittedOutcome(uint256 projectId);
error DAIRH__ValidationPeriodNotEnded(uint256 projectId);
error DAIRH__ValidationPeriodEnded(uint256 projectId);
error DAIRH__DisputePeriodNotEnded(uint256 projectId);
error DAIRH__DisputePeriodActive(uint256 projectId);
error DAIRH__ProjectNotCompleted(uint256 projectId);
error DAIRH__ProjectOutcomeNotSuccessful(uint256 projectId);
error DAIRH__ProjectOutcomeSuccessful(uint256 projectId);
error DAIRH__NothingToClaim(uint256 projectId);
error DAIRH__ValidatorStakeLocked(address validator);
error DAIRH__CannotUnregisterWhileValidating(address validator);
error DAIRH__CannotUnregisterWhileChallenging(address validator);
error DAIRH__ZeroAddress();
error DAIRH__FeeTooHigh(); // Fee percentage must be <= 10000 (100%)
error DAIRH__ContractPaused();

// Enums for project and attestation states
enum ProjectState {
    Proposed,           // Project is open for funding
    FundingActive,      // Project funding goal partially met
    FundingSuccessful,  // Project funding goal met
    OutcomeSubmitted,   // Researcher submitted outcome, awaiting validation
    AwaitingValidation, // Project is in the validation phase
    ValidationPeriodEnded, // Validation period is over, results can be processed
    DisputePeriodActive, // Attestations have been challenged
    CompletedSuccess,   // Project successfully validated, rewards distributed
    CompletedFailure,   // Project validation failed, funds returned
    Cancelled           // Project cancelled by governance or researcher (if allowed)
}

enum AttestationState {
    Submitted,         // Attestation submitted
    Challenged,        // Attestation has been challenged
    ChallengeResolved  // Challenge against this attestation has been resolved
}

// Structs for data storage
struct Project {
    uint256 projectId;
    address payable researcher; // Using payable as researcher receives funds
    string title;
    string descriptionHash; // IPFS hash or similar link to detailed description
    uint256 fundingGoal;
    uint256 currentFunding;
    ProjectState state;
    uint64 proposedTimestamp;
    uint64 fundingSuccessTimestamp;
    string outcomeHash; // IPFS hash or similar link to outcome details
    string performanceClaimsHash; // IPFS hash for verifiable claims (e.g., accuracy, dataset used)
    uint64 outcomeSubmissionTimestamp;
    uint64 validationPeriodEnd;
    uint64 disputePeriodEnd;
    uint256 outcomeNFTId; // ID of the NFT minted for this outcome
    mapping(address => uint256) funders; // Who funded and how much
    uint256[] attestationIds; // List of attestation IDs for this project outcome
    uint256 positiveAttestationCount;
    uint256 negativeAttestationCount;
    uint256 requiredValidatorCount; // Minimum unique validators needed for validity consideration
}

struct Attestation {
    uint256 attestationId;
    uint256 projectId;
    address validator;
    bool isPositive; // True for positive attestation, False for negative
    string attestationDetailsHash; // IPFS hash for validator's reasoning/evidence
    uint64 submittedTimestamp;
    AttestationState state;
    uint256 challengeId; // 0 if not challenged
    uint256 stakedAmount; // Stake required to submit this attestation
}

struct Validator {
    address validatorAddress;
    uint256 stakedAmount; // Registration stake
    bool isRegistered;
    uint64 registrationTimestamp;
    uint64 stakeReleaseTimestamp; // Timestamp when stake can be released
    bool isLocked; // True if involved in active validation/challenge
}

struct Challenge {
    uint256 challengeId;
    uint256 attestationId;
    address challenger;
    string challengeDetailsHash; // IPFS hash for challenger's evidence/reasoning
    uint64 submittedTimestamp;
    bool resolved;
    bool challengerWon; // Result of the resolution
    uint256 stakedAmount; // Stake required for the challenge
}

contract DecentralizedAIResearchHub {
    address public governance;
    IERC20 public fundingToken;
    IERC721Metadata public resultNFTContract;

    uint256 public minProjectFunding = 1 ether; // Example: 1 unit of funding token
    uint256 public validatorRegistrationStake = 10 ether; // Example stake
    uint256 public attestationStake = 0.1 ether; // Example stake per attestation
    uint256 public challengeStake = 0.2 ether; // Example stake for challenge
    uint256 public validationPeriod = 7 days;
    uint256 public disputePeriod = 3 days;
    uint256 public validatorStakeCooldown = 30 days; // Time before registration stake can be released

    // Fee is in basis points (100 = 1%)
    uint256 public platformFeePercentage = 500; // 5%

    uint256 public accumulatedPlatformFees;

    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId = 1;

    mapping(uint256 => Attestation) public attestations;
    uint256 public nextAttestationId = 1;

    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId = 1;

    mapping(address => Validator) public validators;
    mapping(address => int256) public userReputation; // Simple integer score

    bool public paused = false;

    // Modifiers
    modifier onlyGovernance() {
        if (msg.sender != governance) revert DAIRH__NotGovernance();
        _;
    }

    modifier onlyResearcher(uint256 _projectId) {
        if (projects[_projectId].researcher != msg.sender) revert DAIRH__NotResearcher(_projectId);
        _;
    }

    modifier onlyValidator() {
        if (!validators[msg.sender].isRegistered) revert DAIRH__NotValidator();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert DAIRH__ContractPaused();
        _;
    }

    // Events
    event ProjectProposed(uint256 projectId, address indexed researcher, string title, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount, uint256 totalFunded);
    event ProjectFundingSuccessful(uint256 indexed projectId, uint256 totalFunded);
    event ProjectOutcomeSubmitted(uint256 indexed projectId, string outcomeHash, string performanceClaimsHash);
    event ValidatorRegistered(address indexed validator, uint256 stake);
    event AttestationSubmitted(uint256 indexed attestationId, uint256 indexed projectId, address indexed validator, bool isPositive);
    event AttestationChallenged(uint256 indexed challengeId, uint256 indexed attestationId, address indexed challenger);
    event ChallengeResolved(uint256 indexed challengeId, bool challengerWon);
    event RewardsDistributed(uint256 indexed projectId, uint256 researcherReward, uint256 validatorRewards);
    event RefundClaimed(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ValidatorUnregistered(address indexed validator, uint256 stakeReturned);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState);
    event OutcomeNFTMinted(uint256 indexed projectId, uint256 indexed nftTokenId, address recipient);
    event ReputationUpdated(address indexed user, int256 newReputation);

    // Constructor
    constructor(address _fundingToken, address _resultNFTContract) {
        if (_fundingToken == address(0) || _resultNFTContract == address(0)) revert DAIRH__ZeroAddress();
        governance = msg.sender;
        fundingToken = IERC20(_fundingToken);
        resultNFTContract = IERC721Metadata(_resultNFTContract);
        emit ReputationUpdated(governance, 0); // Initialize governance reputation (optional)
    }

    // --- Admin/Governance Functions ---

    function setGovernanceAddress(address _governance) external onlyGovernance {
        if (_governance == address(0)) revert DAIRH__ZeroAddress();
        governance = _governance;
    }

    function setFundingToken(address _token) external onlyGovernance {
         if (_token == address(0)) revert DAIRH__ZeroAddress();
        fundingToken = IERC20(_token);
    }

    function setResultNFTContract(address _nftContract) external onlyGovernance {
        if (_nftContract == address(0)) revert DAIRH__ZeroAddress();
        resultNFTContract = IERC721Metadata(_nftContract);
    }

    function setMinProjectFunding(uint256 _amount) external onlyGovernance {
        minProjectFunding = _amount;
    }

    function setValidatorStakeAmount(uint256 _amount) external onlyGovernance {
        validatorRegistrationStake = _amount;
    }

    function setAttestationStakeAmount(uint256 _amount) external onlyGovernance {
        attestationStake = _amount;
    }

    function setChallengeStakeAmount(uint256 _amount) external onlyGovernance {
        challengeStake = _amount;
    }

    function setValidationPeriod(uint256 _duration) external onlyGovernance {
        validationPeriod = _duration;
    }

    function setDisputePeriod(uint256 _duration) external onlyGovernance {
        disputePeriod = _duration;
    }

    function setPlatformFee(uint256 _percentage) external onlyGovernance {
        if (_percentage > 10000) revert DAIRH__FeeTooHigh(); // Max 100% (10000 basis points)
        platformFeePercentage = _percentage;
    }

    function withdrawPlatformFees(address payable _recipient) external onlyGovernance {
         if (_recipient == address(0)) revert DAIRH__ZeroAddress();
        uint256 amount = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        if (amount > 0) {
            // Using transfer as recommended for ETH (if using ETH), or token.transfer for ERC20
            // Since we are using ERC20, use token.transfer
            bool success = fundingToken.transfer(_recipient, amount);
            require(success, "Token transfer failed");
            emit PlatformFeesWithdrawn(_recipient, amount);
        }
    }

    function pause() external onlyGovernance {
        paused = true;
    }

    function unpause() external onlyGovernance {
        paused = false;
    }

    // Governance can resolve challenges manually
    function resolveChallenge(uint256 _challengeId, bool _challengerWins) external onlyGovernance whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challengeId == 0 || challenge.resolved) revert DAIRH__ChallengeNotFound(_challengeId); // Using challengeId == 0 to check existence

        Attestation storage attestation = attestations[challenge.attestationId];
        // Lock validators involved until challenge is resolved
        validators[challenge.challenger].isLocked = false;
        validators[attestation.validator].isLocked = false;

        challenge.resolved = true;
        challenge.challengerWon = _challengerWins;
        attestation.state = AttestationState.ChallengeResolved;

        // Basic reputation update logic based on challenge outcome
        if (_challengerWon) {
            // Challenger wins: Attestation was likely incorrect/malicious
            // Challenger gets their stake back + attester's stake (minus fee?)
            // Attester loses stake, reputation decreases
            fundingToken.transfer(challenge.challenger, challenge.stakedAmount + attestation.stakedAmount); // Challenger gets both stakes
            userReputation[challenge.challenger] += 10; // Reward reputation for correct challenge
            userReputation[attestation.validator] -= 20; // Punish attester reputation
        } else {
            // Challenger loses: Attestation was likely correct
            // Attester gets their stake back + challenger's stake (minus fee?)
            // Challenger loses stake, reputation decreases
             fundingToken.transfer(attestation.validator, attestation.stakedAmount + challenge.stakedAmount); // Attester gets both stakes
            userReputation[attestation.validator] += 10; // Reward attester reputation
            userReputation[challenge.challenger] -= 20; // Punish challenger reputation
        }

        emit ChallengeResolved(_challengeId, _challengerWon);
        emit ReputationUpdated(challenge.challenger, userReputation[challenge.challenger]);
        emit ReputationUpdated(attestation.validator, userReputation[attestation.validator]);
    }


    // --- Researcher Functions ---

    function proposeProject(string memory _title, string memory _descriptionHash, uint256 _fundingGoal) external whenNotPaused {
        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            projectId: projectId,
            researcher: payable(msg.sender),
            title: _title,
            descriptionHash: _descriptionHash,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            state: ProjectState.Proposed,
            proposedTimestamp: uint64(block.timestamp),
            fundingSuccessTimestamp: 0,
            outcomeHash: "",
            performanceClaimsHash: "",
            outcomeSubmissionTimestamp: 0,
            validationPeriodEnd: 0,
            disputePeriodEnd: 0,
            outcomeNFTId: 0,
            attestationIds: new uint256[](0),
            positiveAttestationCount: 0,
            negativeAttestationCount: 0,
            requiredValidatorCount: 0 // This could be set by governance or dynamically
        });
        emit ProjectProposed(projectId, msg.sender, _title, _fundingGoal);
        emit ProjectStateChanged(projectId, ProjectState.Proposed);
    }

    function submitProjectOutcome(uint256 _projectId, string memory _outcomeHash, string memory _performanceClaimsHash)
        external
        onlyResearcher(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert DAIRH__ProjectNotFound(_projectId);
        if (project.state != ProjectState.FundingSuccessful) revert DAIRH__ProjectNotInState(_projectId, uint8(ProjectState.FundingSuccessful));
        if(bytes(project.outcomeHash).length > 0) revert DAIRH__AlreadySubmittedOutcome(_projectId); // Prevent multiple submissions

        project.outcomeHash = _outcomeHash;
        project.performanceClaimsHash = _performanceClaimsHash;
        project.outcomeSubmissionTimestamp = uint64(block.timestamp);
        project.validationPeriodEnd = uint64(block.timestamp + validationPeriod);
        // Required validator count could be based on funding amount, project complexity, etc.
        // Simple example: minimum 3 validators needed to consider results
        project.requiredValidatorCount = 3; // Example setting

        project.state = ProjectState.AwaitingValidation;

        emit ProjectOutcomeSubmitted(_projectId, _outcomeHash, _performanceClaimsHash);
        emit ProjectStateChanged(_projectId, ProjectState.AwaitingValidation);
    }

    function claimRewards(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert DAIRH__ProjectNotFound(_projectId);
        if (project.state != ProjectState.CompletedSuccess) revert DAIRH__ProjectOutcomeNotSuccessful(_projectId);
        if (project.researcher != msg.sender) revert DAIRH__NotResearcher(_projectId);

        // Rewards are transferred during distributeRewards. This function is just a state check
        // or could potentially handle late claims if reward distribution was pull-based.
        // In this push-based model (transfer in distributeRewards), this function is redundant
        // unless we add a separate claim mechanism. Let's make distributeRewards send directly
        // and remove the need for this explicit claim for researcher.

        // However, keeping it as a pattern placeholder or if validator rewards are pull-based.
        // Let's assume researcher reward is push, but validator rewards might be pull.
        // For simplicity, let's make *all* rewards push in distributeRewards for now.
        // If implementing pull, this would trigger validator claim.
        // Let's add a placeholder event if someone tries to claim when nothing is claimable.
        // In this implementation, researcher rewards are sent in distributeRewards.

        // A better use for a 'claim' function might be for validators to claim their *reward share*
        // after a successful project validation, separate from their staked amount.
        // But distributeRewards already handles validator stake return + reward.
        // Let's simplify: `distributeRewards` sends everything directly.
        // This function will remain as a pattern, maybe returning bool indicating if anything was sent (even if 0).
        // No actual transfer happens *in* this function based on the push design.
        // Consider this function primarily for querying if a project *can* be claimed (i.e., is CompletedSuccess).

        // For clarity, let's make it a view function indicating if rewards are available.
        // Or, modify distributeRewards to track claimed status.
        // Let's modify distributeRewards to transfer directly, and this function becomes less necessary.
        // We'll keep it for now, but note its limited utility in the current push design.
         revert("Rewards are distributed automatically."); // Or implement a pull mechanism here
    }


    // --- Funder Functions ---

    function fundProject(uint256 _projectId, uint256 _amount) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert DAIRH__ProjectNotFound(_projectId);
        if (project.state != ProjectState.Proposed && project.state != ProjectState.FundingActive)
            revert DAIRH__ProjectNotInState(_projectId, uint8(ProjectState.Proposed)); // Can only fund in Proposed/FundingActive

        if (_amount == 0) revert DAIRH__InsufficientFundingAmount();

        // Transfer funds from the funder to the contract (escrow)
        bool success = fundingToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Funding token transfer failed");

        project.currentFunding += _amount;
        project.funders[msg.sender] += _amount;

        if (project.state == ProjectState.Proposed) {
             project.state = ProjectState.FundingActive;
             emit ProjectStateChanged(_projectId, ProjectState.FundingActive);
        }


        if (project.currentFunding >= project.fundingGoal) {
            project.state = ProjectState.FundingSuccessful;
            project.fundingSuccessTimestamp = uint64(block.timestamp);
             emit ProjectFundingSuccessful(_projectId, project.currentFunding);
             emit ProjectStateChanged(_projectId, ProjectState.FundingSuccessful);
        }

        emit ProjectFunded(_projectId, msg.sender, _amount, project.currentFunding);
    }

    function claimRefund(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert DAIRH__ProjectNotFound(_projectId);
        if (project.state != ProjectState.CompletedFailure && project.state != ProjectState.Cancelled)
             revert DAIRH__ProjectNotInState(_projectId, uint8(ProjectState.CompletedFailure)); // Can only claim if failed or cancelled

        uint256 amountToRefund = project.funders[msg.sender];
        if (amountToRefund == 0) revert DAIRH__NothingToClaim(_projectId);

        project.funders[msg.sender] = 0; // Reset funding for this funder

        // Transfer funds back to the funder
        bool success = fundingToken.transfer(msg.sender, amountToRefund);
        require(success, "Refund token transfer failed");

        emit RefundClaimed(_projectId, msg.sender, amountToRefund);
    }


    // --- Validator Functions ---

    function registerValidator() external whenNotPaused {
        if (validators[msg.sender].isRegistered) revert DAIRH__ValidatorAlreadyRegistered(msg.sender);
        if (fundingToken.balanceOf(msg.sender) < validatorRegistrationStake) revert DAIRH__InsufficientStake(validatorRegistrationStake);

        // Transfer stake to the contract
        bool success = fundingToken.transferFrom(msg.sender, address(this), validatorRegistrationStake);
        require(success, "Validator stake transfer failed");

        validators[msg.sender] = Validator({
            validatorAddress: msg.sender,
            stakedAmount: validatorRegistrationStake,
            isRegistered: true,
            registrationTimestamp: uint64(block.timestamp),
            stakeReleaseTimestamp: uint64(block.timestamp + validatorStakeCooldown),
            isLocked: false
        });

        emit ValidatorRegistered(msg.sender, validatorRegistrationStake);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]); // Initialize reputation (defaults to 0)
    }

    function submitAttestation(uint256 _projectId, bool _isPositive, string memory _attestationDetailsHash) external onlyValidator whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert DAIRH__ProjectNotFound(_projectId);
        if (project.state != ProjectState.AwaitingValidation) revert DAIRH__ProjectNotInState(_projectId, uint8(ProjectState.AwaitingValidation));
        if (block.timestamp > project.validationPeriodEnd) revert DAIRH__ValidationPeriodEnded(_projectId);

        // Ensure validator hasn't already attested for this project outcome
        for(uint i = 0; i < project.attestationIds.length; i++) {
            if (attestations[project.attestationIds[i]].validator == msg.sender) {
                 revert("Validator already attested for this project");
            }
        }

        // Require attestation specific stake
        if (fundingToken.balanceOf(msg.sender) < attestationStake) revert DAIRH__InsufficientStake(attestationStake);
        bool success = fundingToken.transferFrom(msg.sender, address(this), attestationStake);
        require(success, "Attestation stake transfer failed");

        uint256 attestationId = nextAttestationId++;
        attestations[attestationId] = Attestation({
            attestationId: attestationId,
            projectId: _projectId,
            validator: msg.sender,
            isPositive: _isPositive,
            attestationDetailsHash: _attestationDetailsHash,
            submittedTimestamp: uint64(block.timestamp),
            state: AttestationState.Submitted,
            challengeId: 0,
            stakedAmount: attestationStake
        });

        project.attestationIds.push(attestationId);
        if (_isPositive) {
            project.positiveAttestationCount++;
        } else {
            project.negativeAttestationCount++;
        }

        // Lock the validator's registration stake temporarily? Or just the attestation stake?
        // Locking registration stake adds more commitment. Let's lock the registration stake.
        validators[msg.sender].isLocked = true;


        emit AttestationSubmitted(attestationId, _projectId, msg.sender, _isPositive);
    }

    function unstakeValidator() external onlyValidator whenNotPaused {
        Validator storage validator = validators[msg.sender];
        if (validator.isLocked) revert DAIRH__ValidatorStakeLocked(msg.sender);
        if (block.timestamp < validator.stakeReleaseTimestamp) revert DAIRH__CannotUnregisterWhileValidating(msg.sender); // Or a better error name

        uint256 stakeToReturn = validator.stakedAmount;
        // Reset validator state
        validator.isRegistered = false;
        validator.stakedAmount = 0; // Clear stake amount in the struct

        // Transfer stake back
        bool success = fundingToken.transfer(msg.sender, stakeToReturn);
        require(success, "Unstake token transfer failed");

        emit ValidatorUnregistered(msg.sender, stakeToReturn);
    }


    // --- Dispute Functions ---

    function challengeAttestation(uint256 _attestationId, string memory _challengeDetailsHash) external whenNotPaused {
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.attestationId == 0) revert DAIRH__AttestationNotFound(_attestationId); // Check existence
        if (attestation.state != AttestationState.Submitted) revert("Attestation cannot be challenged in its current state");

        Project storage project = projects[attestation.projectId];
        // Challenges must occur within the dispute period (which starts after validation ends)
         if (block.timestamp <= project.validationPeriodEnd || block.timestamp > project.disputePeriodEnd) {
             revert DAIRH__DisputePeriodNotEnded(attestation.projectId);
         }
        // Ensure project state allows disputes
         if (project.state != ProjectState.ValidationPeriodEnded) revert DAIRH__ProjectNotInState(attestation.projectId, uint8(ProjectState.ValidationPeriodEnded));

        // Check if challenger is a registered validator? Or allow anyone?
        // Allowing anyone adds more decentralized oversight. Let's allow anyone for now.
        // If only registered validators, uncomment: `if (!validators[msg.sender].isRegistered) revert DAIRH__NotValidator();`

        // Require challenge stake
        if (fundingToken.balanceOf(msg.sender) < challengeStake) revert DAIRH__InsufficientStake(challengeStake);
        bool success = fundingToken.transferFrom(msg.sender, address(this), challengeStake);
        require(success, "Challenge stake transfer failed");

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            challengeId: challengeId,
            attestationId: _attestationId,
            challenger: msg.sender,
            challengeDetailsHash: _challengeDetailsHash,
            submittedTimestamp: uint64(block.timestamp),
            resolved: false,
            challengerWon: false, // Default state
            stakedAmount: challengeStake
        });

        attestation.state = AttestationState.Challenged;
        attestation.challengeId = challengeId;

        // Lock challenger's validator stake if they are one, and the original attester's stake
        if (validators[msg.sender].isRegistered) validators[msg.sender].isLocked = true;
        if (validators[attestation.validator].isRegistered) validators[attestation.validator].isLocked = true;

        // Change project state to indicate active disputes
        project.state = ProjectState.DisputePeriodActive;
        project.disputePeriodEnd = uint64(block.timestamp + disputePeriod); // Extend period for resolution if needed? Or just fix the end time? Let's fix the end time relative to validation end.

        emit AttestationChallenged(challengeId, _attestationId, msg.sender);
        emit ProjectStateChanged(project.projectId, ProjectState.DisputePeriodActive);
    }


    // --- Core Logic: Reward Distribution ---

    // This function should be callable by anyone after the validation/dispute periods end
    function distributeRewards(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        if (project.projectId == 0) revert DAIRH__ProjectNotFound(_projectId);

        // Check if ready for distribution
        bool readyForDistribution = false;
        if (project.state == ProjectState.AwaitingValidation && block.timestamp > project.validationPeriodEnd) {
            project.state = ProjectState.ValidationPeriodEnded;
            emit ProjectStateChanged(_projectId, ProjectState.ValidationPeriodEnded);
            readyForDistribution = true;
        } else if (project.state == ProjectState.ValidationPeriodEnded && block.timestamp > project.validationPeriodEnd + disputePeriod) {
             // Validation period ended, dispute period also ended
             readyForDistribution = true;
        } else if (project.state == ProjectState.DisputePeriodActive && block.timestamp > project.disputePeriodEnd) {
            // Dispute period active, and dispute period ended (means governance didn't resolve, or resolved already)
            // We assume governance *must* resolve before disputePeriodEnd if challenges exist.
            // If period ends with unresolved challenges, they are implicitly resolved negatively for challenger?
            // Or prevent distribution until all challenges are resolved? Let's require resolution.
             bool allChallengesResolved = true;
             for(uint i=0; i < project.attestationIds.length; i++) {
                 Attestation storage att = attestations[project.attestationIds[i]];
                 if(att.state == AttestationState.Challenged) {
                     allChallengesResolved = false;
                     break;
                 }
             }
             if (!allChallengesResolved) revert("Cannot distribute rewards: Unresolved challenges exist.");
             readyForDistribution = true;

        } else {
             revert DAIRH__ValidationPeriodNotEnded(_projectId); // Or DisputePeriodNotEnded etc.
        }

        if (!readyForDistribution) return; // Should not happen with the reverts above, but good practice

        if (project.state == ProjectState.CompletedSuccess || project.state == ProjectState.CompletedFailure) {
            revert("Rewards already distributed for this project.");
        }

        uint256 totalStakedAttestation = 0;
        uint256 totalPositiveVotes = 0;
        uint256 totalNegativeVotes = 0;
        uint256 correctlyAttestingPositiveStakes = 0;
        uint256 correctlyAttestingNegativeStakes = 0;

        // Process attestations and stakes
        for (uint i = 0; i < project.attestationIds.length; i++) {
            Attestation storage att = attestations[project.attestationIds[i]];
            // Only consider attestations that were NOT successfully challenged, or were resolved in favour of the attester
             if (att.state == AttestationState.Submitted || (att.state == AttestationState.ChallengeResolved && !challenges[att.challengeId].challengerWon)) {
                totalStakedAttestation += att.stakedAmount;
                if (att.isPositive) {
                    totalPositiveVotes++;
                } else {
                    totalNegativeVotes++;
                }
                // Unlock validator's registration stake
                if (validators[att.validator].isRegistered) validators[att.validator].isLocked = false;
             } else if (att.state == AttestationState.ChallengeResolved && challenges[att.challengeId].challengerWon) {
                 // Attestation was successfully challenged, validator was wrong. Attester stake was given to challenger in resolveChallenge.
                 // Attester reputation was decreased in resolveChallenge.
                 // Unlock validator's registration stake
                if (validators[att.validator].isRegistered) validators[att.validator].isLocked = false;
             } // else: Attestation was challenged but not yet resolved -> Should be prevented by the check above.
        }

        // Unlock registration stakes for validators who did not attest or whose attestation was successfully challenged
        // We need to iterate over all registered validators to find those involved
        // (This might be gas intensive if there are many validators, consider alternative tracking)
        // Simpler approach: only explicitly lock/unlock validators *involved* in attestations/challenges.
        // Validators who didn't attest don't get their stake locked by this contract. Their general registration stake cooldown still applies.

        // Determine project outcome based on attestation majority (minimum required validators must have participated)
        bool projectSuccessful = false;
        uint256 totalValidAttestations = totalPositiveVotes + totalNegativeVotes;

        if (totalValidAttestations >= project.requiredValidatorCount) {
            if (totalPositiveVotes > totalNegativeVotes) {
                projectSuccessful = true;
            }
        } // If not enough validators, or tied votes, project is unsuccessful by default

        uint256 totalFunded = project.currentFunding;
        uint256 platformFee = 0;

        if (projectSuccessful) {
            // Success scenario: Researcher gets funds, positive validators get stake back + reward, negative validators lose stake, funders lose funds (used for research)
            platformFee = (totalFunded * platformFeePercentage) / 10000;
            uint256 researcherReward = totalFunded - platformFee;

            // Transfer researcher reward
            (bool successResearcher,) = project.researcher.call{value: 0}(abi.encodeWithSignature("transfer(uint256)", researcherReward)); // Assuming ERC20 transfer via call for robustness
             require(successResearcher, "Researcher reward transfer failed");

            // Accumulate platform fees
            accumulatedPlatformFees += platformFee;

            // Distribute stake/rewards to validators
            uint256 totalValidatorRewardPool = totalStakedAttestation; // Return all attestation stakes

            // How to reward validators? Split based on stake? Reputation?
            // Simple: return attestation stake + small bonus for correct (positive) attestations
            uint256 positiveValidatorCount = 0;
            for (uint i = 0; i < project.attestationIds.length; i++) {
                Attestation storage att = attestations[project.attestationIds[i]];
                 if (att.state == AttestationState.Submitted || (att.state == AttestationState.ChallengeResolved && !challenges[att.challengeId].challengerWon)) {
                    if (att.isPositive) {
                        positiveValidatorCount++;
                    }
                 }
            }

            uint256 rewardPerPositiveValidator = (totalValidatorRewardPool > 0 && positiveValidatorCount > 0) ? totalValidatorRewardPool / positiveValidatorCount : 0;

            uint256 totalValidatorRewardsSent = 0;
            for (uint i = 0; i < project.attestationIds.length; i++) {
                Attestation storage att = attestations[project.attestationIds[i]];
                 if (att.state == AttestationState.Submitted || (att.state == AttestationState.ChallengeResolved && !challenges[att.challengeId].challengerWon)) {
                    uint256 rewardAmount = att.stakedAmount; // Return stake
                    if (att.isPositive) {
                         rewardAmount += rewardPerPositiveValidator; // Add bonus for positive attestation
                         userReputation[att.validator] += 5; // Increase reputation for correct attestation
                    } else {
                         // Validator attested negatively, but project was successful -> incorrect attestation
                         // Stake is returned, but reputation might be slightly decreased? Or just no reward?
                         // Let's decrease reputation slightly
                         userReputation[att.validator] -= 5; // Decrease reputation for incorrect attestation
                    }
                    bool successValidator = fundingToken.transfer(att.validator, rewardAmount);
                    require(successValidator, "Validator reward transfer failed"); // Should not fail if funds are in contract
                    totalValidatorRewardsSent += rewardAmount;
                    emit ReputationUpdated(att.validator, userReputation[att.validator]);
                 }
                 // Validators whose attestations were successfully challenged already handled in resolveChallenge
            }


            // Mint the outcome NFT
            uint256 newNFTId = 0; // Assuming NFT contract manages IDs, or use project.projectId
            string memory tokenURI = string(abi.encodePacked("ipfs://", project.outcomeHash)); // Example URI
            // This requires the NFT contract to have a safeMint function callable by this contract
            // and to manage tokenIds and URIs. A dedicated NFT contract is needed.
            // For this example, we'll use projectId as the NFT ID for simplicity,
            // but a real implementation needs a proper ERC721 contract interaction.
            newNFTId = project.projectId; // Simple ID assignment
            resultNFTContract.safeMint(project.researcher, newNFTId, tokenURI);
            project.outcomeNFTId = newNFTId;
            emit OutcomeNFTMinted(project.projectId, newNFTId, project.researcher);


            project.state = ProjectState.CompletedSuccess;
            emit ProjectStateChanged(_projectId, ProjectState.CompletedSuccess);
            emit RewardsDistributed(_projectId, researcherReward, totalValidatorRewardsSent);
            userReputation[project.researcher] += 20; // Increase researcher reputation for success
            emit ReputationUpdated(project.researcher, userReputation[project.researcher]);


        } else {
            // Failure scenario: Funders get funds back, validators get stake back (unless successfully challenged), researcher gets nothing, no NFT
            // Funds are returned via `claimRefund` by funders calling it.
            // Return attestation stakes to validators who attested (unless challenged).
             for (uint i = 0; i < project.attestationIds.length; i++) {
                Attestation storage att = attestations[project.attestationIds[i]];
                 if (att.state == AttestationState.Submitted || (att.state == AttestationState.ChallengeResolved && !challenges[att.challengeId].challengerWon)) {
                     uint256 stakeToReturn = att.stakedAmount;
                     bool successValidator = fundingToken.transfer(att.validator, stakeToReturn);
                     require(successValidator, "Validator stake return failed");
                    // Validator attested negatively and project failed -> correct attestation
                    // Validator attested positively and project failed -> incorrect attestation
                    if (att.isPositive) {
                        userReputation[att.validator] -= 5; // Decrease reputation for incorrect attestation
                    } else {
                        userReputation[att.validator] += 5; // Increase reputation for correct attestation
                    }
                     emit ReputationUpdated(att.validator, userReputation[att.validator]);
                 }
                // Validators whose attestations were successfully challenged already handled in resolveChallenge
                 // Unlock validator's registration stake if it was locked
                 if (validators[att.validator].isRegistered) validators[att.validator].isLocked = false;
            }

            project.state = ProjectState.CompletedFailure;
            emit ProjectStateChanged(_projectId, ProjectState.CompletedFailure);
            emit RewardsDistributed(_projectId, 0, 0); // No rewards distributed on failure
             userReputation[project.researcher] -= 10; // Decrease researcher reputation for failure
            emit ReputationUpdated(project.researcher, userReputation[project.researcher]);

        }
    }


    // --- Query/View Functions ---

    function getUserReputation(address _user) external view returns (int256) {
        return userReputation[_user];
    }

    function getProjectDetails(uint256 _projectId) external view returns (
        uint256 projectId,
        address researcher,
        string memory title,
        string memory descriptionHash,
        uint256 fundingGoal,
        uint256 currentFunding,
        ProjectState state,
        uint64 proposedTimestamp,
        uint64 fundingSuccessTimestamp,
        string memory outcomeHash,
        string memory performanceClaimsHash,
        uint64 outcomeSubmissionTimestamp,
        uint64 validationPeriodEnd,
        uint64 disputePeriodEnd,
        uint256 outcomeNFTId,
        uint256 positiveAttestationCount,
        uint256 negativeAttestationCount,
        uint256 requiredValidatorCount
    ) {
        Project storage p = projects[_projectId];
        return (
            p.projectId,
            p.researcher,
            p.title,
            p.descriptionHash,
            p.fundingGoal,
            p.currentFunding,
            p.state,
            p.proposedTimestamp,
            p.fundingSuccessTimestamp,
            p.outcomeHash,
            p.performanceClaimsHash,
            p.outcomeSubmissionTimestamp,
            p.validationPeriodEnd,
            p.disputePeriodEnd,
            p.outcomeNFTId,
            p.positiveAttestationCount,
            p.negativeAttestationCount,
            p.requiredValidatorCount
        );
    }

    function getProjectFunders(uint256 _projectId) external view returns (address[] memory fundersList, uint256[] memory amounts) {
        Project storage p = projects[_projectId];
        // This requires iterating over the mapping keys, which is not directly possible.
        // A better design would track funders in a separate array or linked list per project.
        // For simplicity in this example, we'll just return an empty array or require off-chain indexing of the ProjectFunded events.
        // If we need this on-chain, the Project struct needs a `address[] fundersArray` and `uint256[] amountsArray`.
        // Let's add temporary placeholder data.
        return (new address[](0), new uint256[](0));
        // In a real contract, iterate over a list of funders tracked separately.
    }

     // To get actual funders on-chain:
     /*
     struct Project {
         // ... other fields
         address[] funderAddresses; // Add this
         mapping(address => uint256) funders; // Keep mapping for amounts
     }
     function fundProject(...) {
         // ... existing logic
         if (project.funders[msg.sender] == 0) { // Check if this is their first contribution
             project.funderAddresses.push(msg.sender);
         }
         project.funders[msg.sender] += _amount;
         // ... rest of logic
     }
     function getProjectFunders(uint256 _projectId) external view returns (address[] memory) {
         return projects[_projectId].funderAddresses;
     }
     // Need another view function to get amounts per funder: getProjectFunderAmount(projectId, funderAddress)
     */

    function getProjectAttestations(uint256 _projectId) external view returns (uint256[] memory) {
        return projects[_projectId].attestationIds;
    }

    function getAttestationDetails(uint256 _attestationId) external view returns (
        uint256 attestationId,
        uint256 projectId,
        address validator,
        bool isPositive,
        string memory attestationDetailsHash,
        uint64 submittedTimestamp,
        AttestationState state,
        uint256 challengeId,
        uint256 stakedAmount
    ) {
        Attestation storage a = attestations[_attestationId];
         if (a.attestationId == 0) revert DAIRH__AttestationNotFound(_attestationId); // Check existence
        return (
            a.attestationId,
            a.projectId,
            a.validator,
            a.isPositive,
            a.attestationDetailsHash,
            a.submittedTimestamp,
            a.state,
            a.challengeId,
            a.stakedAmount
        );
    }


    function getValidatorDetails(address _validator) external view returns (
        address validatorAddress,
        uint256 stakedAmount,
        bool isRegistered,
        uint64 registrationTimestamp,
        uint64 stakeReleaseTimestamp,
        bool isLocked
    ) {
        Validator storage v = validators[_validator];
        // Don't revert if not registered, just return default values (0, false, 0, 0, false)
        return (
            v.validatorAddress, // Will be address(0) if not registered
            v.stakedAmount,
            v.isRegistered,
            v.registrationTimestamp,
            v.stakeReleaseTimestamp,
            v.isLocked
        );
    }


    function getChallengeDetails(uint256 _challengeId) external view returns (
        uint256 challengeId,
        uint256 attestationId,
        address challenger,
        string memory challengeDetailsHash,
        uint64 submittedTimestamp,
        bool resolved,
        bool challengerWon,
        uint256 stakedAmount
    ) {
         Challenge storage c = challenges[_challengeId];
         if (c.challengeId == 0) revert DAIRH__ChallengeNotFound(_challengeId); // Check existence
        return (
            c.challengeId,
            c.attestationId,
            c.challenger,
            c.challengeDetailsHash,
            c.submittedTimestamp,
            c.resolved,
            c.challengerWon,
            c.stakedAmount
        );
    }

    function getPlatformFeeBalance() external view returns (uint256) {
        return accumulatedPlatformFees;
    }

    function getProjectState(uint256 _projectId) external view returns (ProjectState) {
         if (projects[_projectId].projectId == 0) revert DAIRH__ProjectNotFound(_projectId); // Check existence
        return projects[_projectId].state;
    }

    function getProjectOutcomeNFT(uint256 _projectId) external view returns (uint256 nftTokenId) {
        if (projects[_projectId].projectId == 0) revert DAIRH__ProjectNotFound(_projectId); // Check existence
        if (projects[_projectId].state != ProjectState.CompletedSuccess) revert DAIRH__ProjectOutcomeNotSuccessful(_projectId);
        return projects[_projectId].outcomeNFTId;
    }

    // Function to check if a validator's registration stake is currently locked
     function isValidatorStakeLocked(address _validator) external view returns (bool) {
         return validators[_validator].isLocked;
     }

    // Function to check if a validator can currently unstake
     function canValidatorUnstake(address _validator) external view returns (bool) {
         Validator storage v = validators[_validator];
         return v.isRegistered && !v.isLocked && block.timestamp >= v.stakeReleaseTimestamp;
     }
}
```