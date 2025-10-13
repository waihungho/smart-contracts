```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline
// This contract, "QuantumNexus", aims to be a decentralized hub for AI prompt generation, attestation,
// and community-driven validation. It integrates several advanced concepts:
// - Decentralized AI Prompt Management: Users submit prompts, request AI processing via oracles.
// - Community Attestation Layer: A system for users to validate AI outputs and general claims.
// - Reputation System: Dynamic reputation scores based on honest contributions and attestations.
// - Dynamic Soulbound NFTs (Catalysts): Non-transferable NFTs representing roles and tiers based on reputation.
// - Micro-Bounty System: Rewards for specific tasks within the network.
// - Gamified Discovery: A mechanism for users to identify and get rewarded for unique sequences of AI prompts.

// I. Core Infrastructure & Access Control
//    Handles contract ownership, pausing functionality, and administrative withdrawals.
// II. AI Prompt & Generation Management
//    Enables submission of AI prompts, requesting off-chain AI processing via a trusted oracle,
//    receiving AI outputs, and community attestation of output quality.
// III. Decentralized Attestation Layer
//    Allows users to create claims, submit attestations to these claims (with reputation requirements),
//    dispute false attestations, and have disputes resolved by governance.
// IV. Reputation & Governance Metrics
//    Manages a mutable reputation score for each user, adjusted based on their activities
//    in prompt quality attestation and claim attestation/dispute resolution.
// V. Dynamic Soulbound Catalyst NFTs
//    Implements a basic non-transferable NFT (Soulbound Token) system. These "Catalyst NFTs"
//    represent user roles or achievements, with tiers that can be dynamically updated
//    (e.g., based on reputation) and can be locked/unlocked.
// VI. Micro-Bounties & Gamified Discovery
//    A system for creating and fulfilling small bounties for specific tasks, and a novel
//    mechanism for users to propose and get rewarded for "discovering" unique or insightful
//    sequences of AI prompts.

// Function Summary
// I. Core Infrastructure & Access Control
// 1. constructor(): Initializes contract owner and sets initial state.
// 2. setOracleAddress(address _oracleAddress): Sets the address of the trusted AI Oracle. (Owner only)
// 3. transferOwnership(address newOwner): Transfers contract ownership to a new address. (Owner only)
// 4. pause(): Pauses critical contract operations to prevent unwanted state changes. (Owner only)
// 5. unpause(): Unpauses critical contract operations. (Owner only)
// 6. withdrawFunds(address _tokenAddress, uint256 _amount): Allows owner to withdraw any accidentally sent ETH or approved ERC20 tokens. (Owner only)

// II. AI Prompt & Generation Management
// 7. submitAIPrompt(string memory _promptText, string memory _category): Allows users to submit a new AI prompt to the network.
// 8. requestAIOutput(uint256 _promptId, string memory _inputParameters): Requests the off-chain AI Oracle to process a specific prompt with given parameters.
// 9. fulfillAIOutput(bytes32 _requestId, uint256 _promptId, string memory _aiOutput, string memory _metadata): Called by the AI Oracle to submit the generated output corresponding to a request.
// 10. attestAIOutputQuality(uint256 _aiOutputId, uint8 _rating, string memory _comment): Users rate the quality of a generated AI output, influencing reputations.
// 11. getPromptDetails(uint256 _promptId): Retrieves details for a given AI prompt. (View)
// 12. getAIOutputDetails(uint256 _aiOutputId): Retrieves details for a given AI output. (View)
// 13. getAverageAIOutputRating(uint256 _aiOutputId): Calculates the average rating for a specific AI output. (View)

// III. Decentralized Attestation Layer
// 14. createAttestationClaim(string memory _claimHash, string memory _contextURI, uint256 _requiredReputation): Proposes a new claim for community attestation, requiring minimum reputation from attesters.
// 15. submitAttestation(uint256 _claimId, bool _agreesWithClaim, string memory _evidenceURI): Users attest to a claim's veracity, providing evidence.
// 16. disputeAttestation(uint256 _attestationId, string memory _reasonURI): Initiates a dispute against an existing attestation.
// 17. resolveAttestationDispute(uint256 _disputeId, bool _disputeValid): Owner/governance resolves an attestation dispute, affecting involved parties' reputations. (Owner only)
// 18. getClaimDetails(uint256 _claimId): Retrieves details for a given attestation claim. (View)
// 19. getAttestationDetails(uint256 _attestationId): Retrieves details for a specific attestation. (View)

// IV. Reputation & Governance Metrics
// 20. getUserReputation(address _user): Retrieves a user's current reputation score. (View)
// 21. burnReputation(address _user, uint256 _amount): Admin function to decrease a user's reputation score (e.g., for penalties). (Owner only)
// 22. mintReputation(address _user, uint256 _amount): Admin function to increase a user's reputation score (e.g., for rewards). (Owner only)
// 23. getTotalReputation(): Retrieves the total accumulated reputation in the network. (View)

// V. Dynamic Soulbound Catalyst NFTs
// 24. mintCatalystNFT(address _to, uint256 _tier): Mints a new non-transferable Catalyst NFT to a user, representing their role/tier. (Owner only, or triggered by internal logic)
// 25. updateCatalystNFTTier(uint256 _tokenId, uint256 _newTier): Updates the tier of an existing Catalyst NFT, affecting its associated permissions/benefits. (Owner only, or triggered by reputation)
// 26. lockCatalystNFT(uint256 _tokenId): Temporarily locks a Catalyst NFT, revoking its active status or associated benefits. (Owner only)
// 27. unlockCatalystNFT(uint256 _tokenId): Unlocks a previously locked Catalyst NFT. (Owner only)
// 28. getCatalystNFTDetails(uint256 _tokenId): Retrieves details for a given Catalyst NFT. (View)
// 29. getCatalystNFTOwner(uint256 _tokenId): Retrieves the owner of a given Catalyst NFT. (View)

// VI. Micro-Bounties & Gamified Discovery
// 30. createBounty(string memory _description, uint256 _rewardAmount, address _tokenAddress, uint256 _deadline): Creates a new micro-bounty for specific tasks, requiring token transfer for the reward.
// 31. fulfillBounty(uint256 _bountyId, string memory _solutionURI): Submits a solution to an open bounty.
// 32. approveBountyFulfillment(uint256 _bountyFulfillmentId): Owner/governance approves a bounty solution and distributes rewards. (Owner only)
// 33. discoverUniquePromptPath(uint256[] memory _promptIds, string memory _discoveryMetadata): Allows users to propose a sequence of AI prompts as a novel "discovery path."
// 34. validateDiscoveryPath(uint256 _discoveryId, bool _isValid): Owner/governance validates a proposed discovery path, rewarding or penalizing the discoverer. (Owner only)

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract QuantumNexus {
    address public owner;
    address public aiOracleAddress; // Address of the trusted off-chain AI oracle
    bool public paused;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event AIPromptSubmitted(uint256 indexed promptId, address indexed submitter, string category, string promptText);
    event AIOutputRequested(bytes32 indexed requestId, uint256 indexed promptId, address indexed requester, string inputParameters);
    event AIOutputFulfilled(bytes32 indexed requestId, uint256 indexed promptId, uint256 indexed aiOutputId, string aiOutput);
    event AIOutputQualityAttested(uint256 indexed aiOutputId, address indexed attester, uint8 rating);

    event AttestationClaimCreated(uint256 indexed claimId, address indexed creator, string claimHash);
    event AttestationSubmitted(uint256 indexed attestationId, uint256 indexed claimId, address indexed attester, bool agreesWithClaim);
    event AttestationDisputed(uint256 indexed disputeId, uint256 indexed attestationId, address indexed disputer);
    event AttestationDisputeResolved(uint256 indexed disputeId, uint256 indexed attestationId, bool disputeValid);

    event ReputationUpdated(address indexed user, uint256 newReputation, string reason);

    event CatalystNFTMinted(uint256 indexed tokenId, address indexed to, uint256 tier);
    event CatalystNFTTierUpdated(uint256 indexed tokenId, uint256 oldTier, uint256 newTier);
    event CatalystNFTLocked(uint256 indexed tokenId);
    event CatalystNFTUnlocked(uint256 indexed tokenId);

    event BountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, address tokenAddress, uint256 deadline);
    event BountyFulfilled(uint256 indexed bountyFulfillmentId, uint256 indexed bountyId, address indexed fulfiller);
    event BountyFulfillmentApproved(uint256 indexed bountyFulfillmentId, uint256 indexed bountyId, address indexed approver);

    event UniquePromptPathDiscovered(uint256 indexed discoveryId, address indexed discoverer);
    event DiscoveryPathValidated(uint256 indexed discoveryId, address indexed validator, bool isValid);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    // --- State Variables & Structs ---

    // II. AI Prompt & Generation Management
    struct AIPrompt {
        address submitter;
        string promptText;
        string category;
        uint256 submissionTime;
        uint256[] aiOutputIds; // IDs of generated outputs for this prompt
    }
    mapping(uint256 => AIPrompt) public prompts;
    uint256 public nextPromptId;

    struct AIOutput {
        uint256 promptId;
        bytes32 requestId; // Corresponds to the oracle request
        string aiOutput;
        string metadata;
        uint256 fulfillmentTime;
        uint256 totalRatings;
        uint256 sumRatings; // To calculate average rating
        mapping(address => bool) hasAttestedQuality; // To prevent multiple attestations by same user
    }
    mapping(uint256 => AIOutput) public aiOutputs;
    uint256 public nextAIOutputId;

    mapping(bytes32 => uint256) public requestIdToAIOutputId; // Maps oracle request ID to AI output ID

    // III. Decentralized Attestation Layer
    struct AttestationClaim {
        address creator;
        string claimHash; // A unique hash representing the claim content (e.g., IPFS hash of a document)
        string contextURI; // URI to detailed context/evidence for the claim
        uint256 creationTime;
        uint256 requiredReputation; // Minimum reputation required to submit an attestation for this claim
        uint256 positiveAttestations;
        uint256 negativeAttestations;
        bool isActive; // Can be deactivated by owner or governance
        mapping(address => bool) hasAttestedClaim; // To prevent multiple attestations by same user
    }
    mapping(uint256 => AttestationClaim) public attestationClaims;
    uint256 public nextClaimId;

    struct Attestation {
        uint256 claimId;
        address attester;
        bool agreesWithClaim; // True if attester agrees with the claim, false otherwise
        string evidenceURI; // URI to supporting evidence for the attestation
        uint256 attestationTime;
        bool disputed; // True if this attestation is currently under dispute
        bool valid; // True if valid, false if disputed and proven false
    }
    mapping(uint256 => Attestation) public attestations;
    uint256 public nextAttestationId;

    struct AttestationDispute {
        uint256 attestationId; // The ID of the attestation being disputed
        address disputer;
        string reasonURI; // URI to the reason/evidence for the dispute
        uint256 disputeTime;
        bool resolved; // True if the dispute has been resolved
        bool disputeValid; // True if the dispute was upheld (original attestation was invalid)
    }
    mapping(uint256 => AttestationDispute) public attestationDisputes;
    uint256 public nextDisputeId;

    // IV. Reputation & Governance Metrics
    mapping(address => uint256) public userReputation;
    uint256 public totalReputation;

    // V. Dynamic Soulbound Catalyst NFTs (Simplified ERC721-like for non-transferable)
    struct CatalystNFT {
        address owner;
        uint256 tier; // e.g., 1=Basic, 2=Contributor, 3=Architect, influencing permissions/benefits
        uint256 mintTime;
        bool locked; // If locked, it cannot grant benefits
        string tokenURI; // Optional: for metadata like `ipfs://<hash>`
    }
    mapping(uint256 => CatalystNFT) public catalystNFTs;
    mapping(address => uint256[]) public ownerCatalystNFTs; // Keep track of NFTs by owner
    uint256 public nextCatalystTokenId;
    string public constant CATALYST_NFT_NAME = "QuantumNexusCatalyst";
    string public constant CATALYST_NFT_SYMBOL = "QNC";

    // VI. Micro-Bounties & Gamified Discovery
    struct Bounty {
        address creator;
        string description; // Description of the task
        uint256 rewardAmount;
        address tokenAddress; // Address of the ERC20 token for reward
        uint256 creationTime;
        uint256 deadline;
        bool active; // Can be deactivated after fulfillment or expiration
        uint256[] fulfillmentIds; // IDs of submitted solutions
    }
    mapping(uint256 => Bounty) public bounties;
    uint256 public nextBountyId;

    struct BountyFulfillment {
        uint256 bountyId; // The ID of the bounty this fulfills
        address fulfiller;
        string solutionURI; // URI to the solution/evidence
        uint256 fulfillmentTime;
        bool approved; // True if the fulfillment has been approved
        bool rewarded; // True if the fulfiller has received the reward
    }
    mapping(uint256 => BountyFulfillment) public bountyFulfillments;
    uint256 public nextBountyFulfillmentId;

    struct DiscoveryPath {
        address discoverer;
        uint256[] promptIds; // The sequence of AI prompt IDs forming the path
        string discoveryMetadata; // URI to explanation or context of the discovery
        uint256 submissionTime;
        bool validated; // True if the path has been reviewed
        bool isValid; // True if validated as unique/insightful
    }
    mapping(uint256 => DiscoveryPath) public discoveryPaths;
    uint256 public nextDiscoveryId;

    constructor() {
        owner = msg.sender;
        paused = false;
        nextPromptId = 1;
        nextAIOutputId = 1;
        nextClaimId = 1;
        nextAttestationId = 1;
        nextDisputeId = 1;
        nextCatalystTokenId = 1;
        nextBountyId = 1;
        nextBountyFulfillmentId = 1;
        nextDiscoveryId = 1;
        emit OwnershipTransferred(address(0), owner);
    }

    // --- I. Core Infrastructure & Access Control ---

    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid address");
        aiOracleAddress = _oracleAddress;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function withdrawFunds(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0)) { // ETH withdrawal
            require(address(this).balance >= _amount, "Insufficient ETH balance");
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "ETH transfer failed");
        } else { // ERC20 token withdrawal
            IERC20 token = IERC20(_tokenAddress);
            require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance");
            require(token.transfer(msg.sender, _amount), "Token transfer failed");
        }
    }

    // --- II. AI Prompt & Generation Management ---

    function submitAIPrompt(string memory _promptText, string memory _category) external whenNotPaused {
        uint256 currentId = nextPromptId++;
        prompts[currentId] = AIPrompt({
            submitter: msg.sender,
            promptText: _promptText,
            category: _category,
            submissionTime: block.timestamp,
            aiOutputIds: new uint256[](0)
        });
        emit AIPromptSubmitted(currentId, msg.sender, _category, _promptText);
    }

    function requestAIOutput(uint256 _promptId, string memory _inputParameters) external whenNotPaused {
        require(prompts[_promptId].submitter != address(0), "Prompt does not exist");
        require(aiOracleAddress != address(0), "AI Oracle address not set");

        // Generate a unique request ID for the oracle
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _promptId, _inputParameters));
        require(requestIdToAIOutputId[requestId] == 0, "Request already exists or is being processed");

        // In a real system, there would be a fee or stake required for requesting AI output
        // and a more robust mechanism for the oracle to pick up this event and process off-chain.
        
        emit AIOutputRequested(requestId, _promptId, msg.sender, _inputParameters);
    }

    function fulfillAIOutput(bytes32 _requestId, uint256 _promptId, string memory _aiOutput, string memory _metadata) external whenNotPaused {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can fulfill requests");
        require(prompts[_promptId].submitter != address(0), "Prompt does not exist");
        require(requestIdToAIOutputId[_requestId] == 0, "Output for this request already fulfilled or request never made");

        uint256 currentId = nextAIOutputId++;
        aiOutputs[currentId] = AIOutput({
            promptId: _promptId,
            requestId: _requestId,
            aiOutput: _aiOutput,
            metadata: _metadata,
            fulfillmentTime: block.timestamp,
            totalRatings: 0,
            sumRatings: 0
        });
        prompts[_promptId].aiOutputIds.push(currentId);
        requestIdToAIOutputId[_requestId] = currentId;

        emit AIOutputFulfilled(_requestId, _promptId, currentId, _aiOutput);
    }

    function attestAIOutputQuality(uint256 _aiOutputId, uint8 _rating, string memory _comment) external whenNotPaused {
        require(aiOutputs[_aiOutputId].promptId != 0, "AI Output does not exist");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(!aiOutputs[_aiOutputId].hasAttestedQuality[msg.sender], "Already attested quality for this output");

        aiOutputs[_aiOutputId].totalRatings++;
        aiOutputs[_aiOutputId].sumRatings += _rating;
        aiOutputs[_aiOutputId].hasAttestedQuality[msg.sender] = true;

        // Simple reputation logic: Higher rating, more reputation; lower rating, less or even burn
        if (_rating >= 4) {
            _mintReputation(msg.sender, 10, "Attested high quality AI output");
        } else if (_rating <= 2) {
             _burnReputation(msg.sender, 5, "Attested low quality AI output");
        }
        // The _comment could be stored off-chain (e.g., as an IPFS hash) to save gas,
        // but its presence is noted here for functionality.
        _comment; 
        emit AIOutputQualityAttested(_aiOutputId, msg.sender, _rating);
    }

    function getPromptDetails(uint256 _promptId) external view returns (address submitter, string memory promptText, string memory category, uint256 submissionTime, uint256[] memory aiOutputIds) {
        AIPrompt storage p = prompts[_promptId];
        require(p.submitter != address(0), "Prompt does not exist"); // Check if promptId is valid
        return (p.submitter, p.promptText, p.category, p.submissionTime, p.aiOutputIds);
    }

    function getAIOutputDetails(uint256 _aiOutputId) external view returns (uint256 promptId, bytes32 requestId, string memory aiOutput, string memory metadata, uint256 fulfillmentTime, uint256 totalRatings, uint256 sumRatings) {
        AIOutput storage o = aiOutputs[_aiOutputId];
        require(o.promptId != 0, "AI Output does not exist"); // Check if aiOutputId is valid
        return (o.promptId, o.requestId, o.aiOutput, o.metadata, o.fulfillmentTime, o.totalRatings, o.sumRatings);
    }

    function getAverageAIOutputRating(uint256 _aiOutputId) external view returns (uint256) {
        AIOutput storage o = aiOutputs[_aiOutputId];
        require(o.promptId != 0, "AI Output does not exist"); // Check if aiOutputId is valid
        if (o.totalRatings == 0) {
            return 0;
        }
        return o.sumRatings / o.totalRatings;
    }

    // --- III. Decentralized Attestation Layer ---

    function createAttestationClaim(string memory _claimHash, string memory _contextURI, uint256 _requiredReputation) external whenNotPaused {
        uint256 currentId = nextClaimId++;
        attestationClaims[currentId] = AttestationClaim({
            creator: msg.sender,
            claimHash: _claimHash,
            contextURI: _contextURI,
            creationTime: block.timestamp,
            requiredReputation: _requiredReputation,
            positiveAttestations: 0,
            negativeAttestations: 0,
            isActive: true
        });
        emit AttestationClaimCreated(currentId, msg.sender, _claimHash);
    }

    function submitAttestation(uint256 _claimId, bool _agreesWithClaim, string memory _evidenceURI) external whenNotPaused {
        AttestationClaim storage claim = attestationClaims[_claimId];
        require(claim.creator != address(0), "Claim does not exist");
        require(claim.isActive, "Claim is not active");
        require(userReputation[msg.sender] >= claim.requiredReputation, "Insufficient reputation to attest");
        require(!claim.hasAttestedClaim[msg.sender], "Already attested this claim");

        uint256 currentId = nextAttestationId++;
        attestations[currentId] = Attestation({
            claimId: _claimId,
            attester: msg.sender,
            agreesWithClaim: _agreesWithClaim,
            evidenceURI: _evidenceURI,
            attestationTime: block.timestamp,
            disputed: false,
            valid: true
        });
        claim.hasAttestedClaim[msg.sender] = true;

        if (_agreesWithClaim) {
            claim.positiveAttestations++;
            _mintReputation(msg.sender, 20, "Attested positively to a claim");
        } else {
            claim.negativeAttestations++;
            _mintReputation(msg.sender, 20, "Attested negatively to a claim"); // Reward for honest opposing view
        }
        emit AttestationSubmitted(currentId, _claimId, msg.sender, _agreesWithClaim);
    }

    function disputeAttestation(uint256 _attestationId, string memory _reasonURI) external whenNotPaused {
        Attestation storage att = attestations[_attestationId];
        require(att.claimId != 0, "Attestation does not exist");
        require(!att.disputed, "Attestation is already under dispute");
        require(att.attester != msg.sender, "Cannot dispute your own attestation");

        uint256 currentId = nextDisputeId++;
        attestationDisputes[currentId] = AttestationDispute({
            attestationId: _attestationId,
            disputer: msg.sender,
            reasonURI: _reasonURI,
            disputeTime: block.timestamp,
            resolved: false,
            disputeValid: false
        });
        att.disputed = true; // Mark the original attestation as disputed

        // Small reputation reward for initiating a dispute, encourages vigilance
        _mintReputation(msg.sender, 5, "Initiated an attestation dispute");

        emit AttestationDisputed(currentId, _attestationId, msg.sender);
    }

    function resolveAttestationDispute(uint256 _disputeId, bool _disputeValid) external onlyOwner whenNotPaused {
        AttestationDispute storage dispute = attestationDisputes[_disputeId];
        require(dispute.attestationId != 0, "Dispute does not exist");
        require(!dispute.resolved, "Dispute already resolved");

        Attestation storage originalAtt = attestations[dispute.attestationId];
        require(originalAtt.claimId != 0, "Original attestation not found for dispute");

        dispute.resolved = true;
        dispute.disputeValid = _disputeValid;

        if (_disputeValid) { // Disputer was correct, original attestation was invalid
            originalAtt.valid = false;
            // Penalize the original attester heavily
            _burnReputation(originalAtt.attester, 50, "Attestation proven invalid via dispute");
            // Reward the disputer for correctly identifying an invalid attestation
            _mintReputation(dispute.disputer, 50, "Successfully disputed an invalid attestation");
        } else { // Disputer was incorrect, original attestation was valid
            // Penalize the disputer for a false dispute
            _burnReputation(dispute.disputer, 25, "Unsuccessfully disputed a valid attestation");
            // Reward the original attester for having their attestation upheld
            _mintReputation(originalAtt.attester, 10, "Attestation upheld after dispute");
        }

        emit AttestationDisputeResolved(_disputeId, dispute.attestationId, _disputeValid);
    }

    function getClaimDetails(uint256 _claimId) external view returns (address creator, string memory claimHash, string memory contextURI, uint256 creationTime, uint256 requiredReputation, uint256 positiveAttestations, uint256 negativeAttestations, bool isActive) {
        AttestationClaim storage claim = attestationClaims[_claimId];
        require(claim.creator != address(0), "Claim does not exist");
        return (claim.creator, claim.claimHash, claim.contextURI, claim.creationTime, claim.requiredReputation, claim.positiveAttestations, claim.negativeAttestations, claim.isActive);
    }

    function getAttestationDetails(uint256 _attestationId) external view returns (uint256 claimId, address attester, bool agreesWithClaim, string memory evidenceURI, uint256 attestationTime, bool disputed, bool valid) {
        Attestation storage att = attestations[_attestationId];
        require(att.claimId != 0, "Attestation does not exist");
        return (att.claimId, att.attester, att.agreesWithClaim, att.evidenceURI, att.attestationTime, att.disputed, att.valid);
    }

    // --- IV. Reputation & Governance Metrics ---

    function _mintReputation(address _user, uint256 _amount, string memory _reason) internal {
        userReputation[_user] += _amount;
        totalReputation += _amount;
        emit ReputationUpdated(_user, userReputation[_user], _reason);
    }

    function _burnReputation(address _user, uint256 _amount, string memory _reason) internal {
        if (userReputation[_user] < _amount) {
            _amount = userReputation[_user]; // Cannot burn more than available
        }
        userReputation[_user] -= _amount;
        totalReputation -= _amount;
        emit ReputationUpdated(_user, userReputation[_user], _reason);
    }

    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    function burnReputation(address _user, uint256 _amount) external onlyOwner {
        _burnReputation(_user, _amount, "Owner-initiated burn");
    }

    function mintReputation(address _user, uint256 _amount) external onlyOwner {
        _mintReputation(_user, _amount, "Owner-initiated mint");
    }

    function getTotalReputation() external view returns (uint256) {
        return totalReputation;
    }

    // --- V. Dynamic Soulbound Catalyst NFTs ---

    function mintCatalystNFT(address _to, uint256 _tier) external onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        uint256 tokenId = nextCatalystTokenId++;
        catalystNFTs[tokenId] = CatalystNFT({
            owner: _to,
            tier: _tier,
            mintTime: block.timestamp,
            locked: false,
            tokenURI: "" // Can be set later or dynamically generated (e.g., pointing to metadata based on tier)
        });
        ownerCatalystNFTs[_to].push(tokenId);
        // Note: For a true soulbound token, a user might only hold one of a certain type/tier.
        // This simplified implementation allows multiple, but they are non-transferable due to no transfer function.
        emit CatalystNFTMinted(tokenId, _to, _tier);
    }

    function updateCatalystNFTTier(uint256 _tokenId, uint256 _newTier) external onlyOwner {
        CatalystNFT storage nft = catalystNFTs[_tokenId];
        require(nft.owner != address(0), "Catalyst NFT does not exist");
        require(nft.tier != _newTier, "New tier must be different from current");

        uint256 oldTier = nft.tier;
        nft.tier = _newTier;
        emit CatalystNFTTierUpdated(_tokenId, oldTier, _newTier);
    }

    function lockCatalystNFT(uint256 _tokenId) external onlyOwner {
        CatalystNFT storage nft = catalystNFTs[_tokenId];
        require(nft.owner != address(0), "Catalyst NFT does not exist");
        require(!nft.locked, "Catalyst NFT is already locked");
        nft.locked = true;
        emit CatalystNFTLocked(_tokenId);
    }

    function unlockCatalystNFT(uint256 _tokenId) external onlyOwner {
        CatalystNFT storage nft = catalystNFTs[_tokenId];
        require(nft.owner != address(0), "Catalyst NFT does not exist");
        require(nft.locked, "Catalyst NFT is not locked");
        nft.locked = false;
        emit CatalystNFTUnlocked(_tokenId);
    }

    function getCatalystNFTDetails(uint256 _tokenId) external view returns (address owner, uint256 tier, uint256 mintTime, bool locked, string memory tokenURI) {
        CatalystNFT storage nft = catalystNFTs[_tokenId];
        require(nft.owner != address(0), "Catalyst NFT does not exist");
        return (nft.owner, nft.tier, nft.mintTime, nft.locked, nft.tokenURI);
    }

    function getCatalystNFTOwner(uint256 _tokenId) external view returns (address) {
        return catalystNFTs[_tokenId].owner;
    }

    // --- VI. Micro-Bounties & Gamified Discovery ---

    function createBounty(string memory _description, uint256 _rewardAmount, address _tokenAddress, uint256 _deadline) external whenNotPaused {
        require(_rewardAmount > 0, "Reward amount must be positive");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_tokenAddress != address(0), "Token address cannot be zero");

        IERC20 token = IERC20(_tokenAddress);
        // Transfer the reward tokens from the bounty creator to the contract
        require(token.transferFrom(msg.sender, address(this), _rewardAmount), "Token transfer for bounty failed");

        uint256 currentId = nextBountyId++;
        bounties[currentId] = Bounty({
            creator: msg.sender,
            description: _description,
            rewardAmount: _rewardAmount,
            tokenAddress: _tokenAddress,
            creationTime: block.timestamp,
            deadline: _deadline,
            active: true,
            fulfillmentIds: new uint256[](0)
        });
        emit BountyCreated(currentId, msg.sender, _rewardAmount, _tokenAddress, _deadline);
    }

    function fulfillBounty(uint256 _bountyId, string memory _solutionURI) external whenNotPaused {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.creator != address(0), "Bounty does not exist");
        require(bounty.active, "Bounty is not active");
        require(block.timestamp <= bounty.deadline, "Bounty deadline has passed");
        require(msg.sender != bounty.creator, "Creator cannot fulfill their own bounty");

        uint256 currentId = nextBountyFulfillmentId++;
        bountyFulfillments[currentId] = BountyFulfillment({
            bountyId: _bountyId,
            fulfiller: msg.sender,
            solutionURI: _solutionURI,
            fulfillmentTime: block.timestamp,
            approved: false,
            rewarded: false
        });
        bounty.fulfillmentIds.push(currentId);
        _mintReputation(msg.sender, 15, "Submitted bounty fulfillment");
        emit BountyFulfilled(currentId, _bountyId, msg.sender);
    }

    function approveBountyFulfillment(uint256 _bountyFulfillmentId) external onlyOwner whenNotPaused {
        BountyFulfillment storage fulfillment = bountyFulfillments[_bountyFulfillmentId];
        require(fulfillment.bountyId != 0, "Bounty fulfillment does not exist");
        require(!fulfillment.approved, "Bounty fulfillment already approved");
        require(!fulfillment.rewarded, "Bounty already rewarded");

        Bounty storage bounty = bounties[fulfillment.bountyId];
        require(bounty.active, "Bounty is not active");
        require(bounty.tokenAddress != address(0), "Bounty token address is invalid");
        require(IERC20(bounty.tokenAddress).balanceOf(address(this)) >= bounty.rewardAmount, "Contract has insufficient bounty funds");

        fulfillment.approved = true;
        fulfillment.rewarded = true;

        IERC20 token = IERC20(bounty.tokenAddress);
        require(token.transfer(fulfillment.fulfiller, bounty.rewardAmount), "Bounty reward transfer failed");
        _mintReputation(fulfillment.fulfiller, 50, "Successfully fulfilled and rewarded a bounty");

        bounty.active = false; // Close the bounty after one approval (can be modified for multiple winners)

        emit BountyFulfillmentApproved(_bountyFulfillmentId, fulfillment.bountyId, msg.sender);
    }

    function discoverUniquePromptPath(uint256[] memory _promptIds, string memory _discoveryMetadata) external whenNotPaused {
        require(_promptIds.length >= 2, "Prompt path must contain at least two prompts");
        for (uint256 i = 0; i < _promptIds.length; i++) {
            require(prompts[_promptIds[i]].submitter != address(0), "One or more prompts in path do not exist");
        }
        // In a more advanced version, this could involve a complex on-chain or off-chain check
        // for "uniqueness" or "insightfulness" by comparing against existing paths or AI analysis.
        // For this contract, we simply record the submission.

        uint256 currentId = nextDiscoveryId++;
        discoveryPaths[currentId] = DiscoveryPath({
            discoverer: msg.sender,
            promptIds: _promptIds,
            discoveryMetadata: _discoveryMetadata,
            submissionTime: block.timestamp,
            validated: false,
            isValid: false
        });
        _mintReputation(msg.sender, 25, "Submitted a unique prompt path for discovery");
        emit UniquePromptPathDiscovered(currentId, msg.sender);
    }

    function validateDiscoveryPath(uint256 _discoveryId, bool _isValid) external onlyOwner whenNotPaused {
        DiscoveryPath storage path = discoveryPaths[_discoveryId];
        require(path.discoverer != address(0), "Discovery path does not exist");
        require(!path.validated, "Discovery path already validated");

        path.validated = true;
        path.isValid = _isValid;

        if (_isValid) {
            _mintReputation(path.discoverer, 100, "Unique prompt path validated");
            // Could mint a special Catalyst NFT for this, or other significant rewards
        } else {
            _burnReputation(path.discoverer, 20, "Unique prompt path invalidated");
        }
        emit DiscoveryPathValidated(_discoveryId, msg.sender, _isValid);
    }
}
```