The concept behind this smart contract, **ImpactNexus**, is a hybrid reputation and influence protocol. It introduces two core intertwined concepts:

1.  **Impact Points (Soulbound Reputation):** Non-transferable, personal reputation scores earned through verifiable positive actions, attested by other users or the protocol itself. These are "soulbound" in spirit, meaning they cannot be directly traded, bought, or sold.
2.  **Impact Certificates (Liquid Influence NFTs):** ERC721 NFTs that are minted by *staking* a user's own Impact Points. These certificates represent a portion of the holder's reputation dedicated to sponsoring a specific project, proposal, or entity. Unlike Impact Points, these NFTs *are* transferable, allowing the "influence" derived from reputation to become a liquid asset that can be traded, delegated, or used as collateral. The certificate's metadata can be dynamic, evolving with the sponsored entity's performance or the underlying reputation.

This creates a unique mechanism where non-transferable reputation can be leveraged to generate transferable influence, while still retaining the integrity of the underlying reputation system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
Outline and Function Summary for ImpactNexus

Contract Name: ImpactNexus

Description:
ImpactNexus is a Decentralized Impact & Reputation Protocol that bridges non-transferable "Impact Points" (IPs)
with liquid "Impact Certificate" NFTs. Users earn IPs by performing verifiable positive actions, attested by
other users. These IPs, while soulbound, can be staked to mint transferable Impact Certificate NFTs, which
represent dedicated influence or sponsorship for specific projects, proposals, or entities. The protocol
features dynamic certificate metadata, reputation-based gating, a challenge system for attestations,
and an innovative mechanism for delegating certificate power without transferring ownership.

Core Concepts:
1.  Impact Points (IPs): Non-transferable, personal reputation points.
2.  Impact Certificates (ICs): ERC721 NFTs minted by staking IPs, representing liquid influence.
3.  Attestations: On-chain verifiable claims of positive impact.
4.  Challenges: System to dispute fraudulent or incorrect attestations.
5.  Delegated Power: Ability to delegate an IC's influence without transferring the NFT.
6.  Dynamic NFTs: IC metadata can evolve based on various factors.

Outline:
I.   Configuration & Administration
II.  Impact Points Management
III. Attestation & Challenge System
IV.  Impact Certificate (ERC721) Management
V.   Certificate Delegation
VI.  Utility & Query Functions

Function Summary (27 Functions):

I.   Configuration & Administration (Owner-only)
1.  constructor(string memory _name, string memory _symbol): Initializes the contract, sets the ERC721 name and symbol, and the deployer as owner.
2.  setAttestationFee(uint256 _fee): Sets the fee required to issue an attestation.
3.  setMinAttestorImpactForAttestation(uint256 _minImpact): Sets the minimum Impact Points an address must have to be eligible to attest.
4.  setMinImpactForCertificateCreation(uint256 _minImpact): Sets the minimum Impact Points a user needs to mint an Impact Certificate.
5.  setImpactCertificateBondAmount(uint256 _bond): Sets the bond required to mint an Impact Certificate, refundable upon redemption.
6.  setChallengeParameters(uint256 _bond, uint64 _period): Sets the bond amount and duration for challenging an attestation.
7.  pause(): Pauses all core functionalities (attestation, certificate minting/redemption) in an emergency.
8.  unpause(): Unpauses the system, restoring functionality.
9.  withdrawFees(): Allows the contract owner to withdraw accumulated fees.
10. grantImpactByAdmin(address _recipient, uint256 _amount): Allows the admin to directly grant Impact Points, e.g., for off-chain achievements.

II.  Impact Points Management
11. decayImpactPoints(address _user): Public function that allows anyone to trigger the decay of Impact Points for a specified user, potentially receiving a small reward for gas.
12. getImpactPoints(address _user): Returns the current Impact Points of a given address.

III. Attestation & Challenge System
13. attestImpact(address _recipient, string memory _attestationUri): Allows an eligible user to attest to another user's positive impact, paying a fee.
14. challengeAttestation(uint256 _attestationId): Allows any user to challenge an attestation by depositing a bond.
15. resolveChallenge(uint256 _challengeId, bool _challengerWins): Owner/admin resolves a challenge, distributing bonds accordingly and potentially reversing the attestation's impact.
16. getAttestationDetails(uint256 _attestationId): Returns the full details of a specific attestation.
17. getChallengeDetails(uint256 _challengeId): Returns the full details of a specific challenge.

IV.  Impact Certificate (ERC721) Management
18. mintImpactCertificate(uint256 _stakedImpactAmount, address _targetEntity, string memory _metadataUri): Mints an Impact Certificate NFT by staking a portion of the caller's Impact Points, designating a target entity for influence.
19. redeemImpactCertificate(uint256 _tokenId): Burns an Impact Certificate NFT, returning the staked Impact Points to the owner (subject to any decay or penalties).
20. reassignCertificateTarget(uint256 _tokenId, address _newTargetEntity): Allows the certificate owner to change the target entity their certificate is sponsoring.
21. updateCertificateMetadata(uint256 _tokenId, string memory _newMetadataUri): Allows the certificate owner to update the URI for the certificate's dynamic metadata.
22. getCertificateStakedImpact(uint256 _tokenId): Returns the amount of Impact Points currently staked by a given Impact Certificate.
23. tokenURI(uint256 _tokenId): Overrides ERC721's tokenURI to provide dynamic metadata based on the certificate's state and underlying impact.

V.   Certificate Delegation
24. delegateCertificatePower(uint256 _tokenId, address _delegatee): Allows the owner of an Impact Certificate to delegate its voting/influence power to another address without transferring the NFT itself.
25. revokeCertificateDelegation(uint256 _tokenId): Revokes any previously set delegation for an Impact Certificate.
26. getCertificateDelegate(uint256 _tokenId): Returns the address currently delegated the power of a specific Impact Certificate.

VI.  Utility & Query Functions
27. getLatestAttestationId(): Returns the ID of the most recently created attestation.

*/

contract ImpactNexus is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Impact Points: Non-transferable reputation score for each user
    mapping(address => uint256) public impactPoints;

    // Attestations: Records of impact claims
    struct Attestation {
        uint256 id;
        address attestor;
        address recipient;
        uint256 impactAmount; // The amount of impact granted by this attestation
        uint64 timestamp;
        string attestationUri; // URI pointing to details/proof of attestation
        bool isValid; // True if not challenged or challenge failed
    }
    mapping(uint256 => Attestation) public attestations;
    Counters.Counter private _nextAttestationId;

    // Challenges: Records of disputes against attestations
    struct Challenge {
        uint256 id;
        uint256 attestationId;
        address challenger;
        uint256 bondAmount;
        uint64 challengeStartTimestamp;
        uint64 challengeEndTimestamp;
        bool resolved;
        bool challengerWon; // Only relevant if resolved
    }
    mapping(uint256 => Challenge) public challenges;
    Counters.Counter private _nextChallengeId;

    // Impact Certificates: ERC721 NFT data
    struct ImpactCertificateData {
        uint256 stakedImpactAmount; // The amount of IP staked to mint this certificate
        address owner; // ERC721 handles primary ownership, this stores initial owner/for quick lookup
        address targetEntity; // The project/proposal/entity this certificate sponsors
        string metadataUri; // URI for dynamic metadata
        uint64 mintTimestamp;
    }
    mapping(uint256 => ImpactCertificateData) public impactCertificateData;
    Counters.Counter private _nextCertificateId;

    // Certificate Delegation: Allows delegation of influence without transferring the NFT
    mapping(uint256 => address) public certificateDelegates; // tokenId -> delegatee address

    // --- Configuration Parameters ---
    uint256 public attestationFee;
    uint256 public minAttestorImpactForAttestation;
    uint256 public minImpactForCertificateCreation;
    uint256 public impactCertificateBondAmount; // Bond required to mint an IC, refundable on redemption
    uint256 public challengeBondAmount; // Bond required to challenge an attestation
    uint64 public challengePeriod; // Duration (in seconds) for which a challenge is active

    // Accumulated fees from attestations
    uint256 public totalProtocolFees;

    // Impact Decay Rate: Amount of impact decayed per block (or per some time unit, here simplified per second check)
    // For a real-world scenario, this would likely be more sophisticated (e.g., per day, or based on activity)
    // For simplicity, we'll use a decaying impact points based on last interaction/timestamp or triggerable decay.
    // Let's make it a simple decay per unit time based on a function call.
    uint256 public impactDecayRatePerThousandBlocks; // e.g., 1 IP decays every 1000 blocks
    mapping(address => uint65) public lastImpactUpdateBlock; // Use block.timestamp for more stable time reference

    // --- Events ---
    event ImpactAttested(uint256 indexed attestationId, address indexed attestor, address indexed recipient, uint256 impactAmount, string attestationUri);
    event ImpactPointsGranted(address indexed recipient, uint256 amount, string reason);
    event ImpactPointsDecayed(address indexed user, uint256 decayedAmount, uint256 newImpact);
    event AttestationChallengeInitiated(uint256 indexed challengeId, uint256 indexed attestationId, address indexed challenger);
    event AttestationChallengeResolved(uint256 indexed challengeId, uint256 indexed attestationId, bool challengerWon);
    event ImpactCertificateMinted(uint256 indexed tokenId, address indexed owner, uint256 stakedImpact, address indexed targetEntity, string metadataUri);
    event ImpactCertificateRedeemed(uint256 indexed tokenId, address indexed owner, uint256 returnedImpact);
    event ImpactCertificateTargetReassigned(uint256 indexed tokenId, address indexed oldTarget, address indexed newTarget);
    event ImpactCertificateMetadataUpdated(uint256 indexed tokenId, string newMetadataUri);
    event CertificatePowerDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event CertificatePowerRevoked(uint256 indexed tokenId, address indexed delegator);
    event FeesWithdrawn(address indexed recipient, uint224 amount);
    event ParametersUpdated(string paramName, uint256 newValue);

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        attestationFee = 0.001 ether; // Example: 0.001 ETH
        minAttestorImpactForAttestation = 100; // Example: 100 Impact Points
        minImpactForCertificateCreation = 500; // Example: 500 Impact Points
        impactCertificateBondAmount = 0.01 ether; // Example: 0.01 ETH bond
        challengeBondAmount = 0.005 ether; // Example: 0.005 ETH bond
        challengePeriod = 3 days; // Example: 3 days for challenges
        impactDecayRatePerThousandBlocks = 1; // 1 IP decays per 1000 blocks (arbitrary example)
        _nextAttestationId.increment(); // Start IDs from 1
        _nextChallengeId.increment();
        _nextCertificateId.increment();
    }

    // --- I. Configuration & Administration (Owner-only) ---

    /// @notice Sets the fee required to issue an attestation.
    /// @param _fee The new attestation fee in wei.
    function setAttestationFee(uint256 _fee) external onlyOwner {
        attestationFee = _fee;
        emit ParametersUpdated("attestationFee", _fee);
    }

    /// @notice Sets the minimum Impact Points an address must have to be eligible to attest.
    /// @param _minImpact The new minimum impact for attestors.
    function setMinAttestorImpactForAttestation(uint256 _minImpact) external onlyOwner {
        minAttestorImpactForAttestation = _minImpact;
        emit ParametersUpdated("minAttestorImpactForAttestation", _minImpact);
    }

    /// @notice Sets the minimum Impact Points a user needs to mint an Impact Certificate.
    /// @param _minImpact The new minimum impact for certificate creation.
    function setMinImpactForCertificateCreation(uint256 _minImpact) external onlyOwner {
        minImpactForCertificateCreation = _minImpact;
        emit ParametersUpdated("minImpactForCertificateCreation", _minImpact);
    }

    /// @notice Sets the bond required to mint an Impact Certificate, refundable upon redemption.
    /// @param _bond The new bond amount in wei.
    function setImpactCertificateBondAmount(uint256 _bond) external onlyOwner {
        impactCertificateBondAmount = _bond;
        emit ParametersUpdated("impactCertificateBondAmount", _bond);
    }

    /// @notice Sets the bond amount and duration for challenging an attestation.
    /// @param _bond The new challenge bond amount in wei.
    /// @param _period The new challenge period in seconds.
    function setChallengeParameters(uint256 _bond, uint64 _period) external onlyOwner {
        challengeBondAmount = _bond;
        challengePeriod = _period;
        emit ParametersUpdated("challengeBondAmount", _bond);
        emit ParametersUpdated("challengePeriod", _period);
    }

    /// @notice Pauses all core functionalities (attestation, certificate minting/redemption) in an emergency.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the system, restoring functionality.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the contract owner to withdraw accumulated fees.
    function withdrawFees() external onlyOwner {
        uint256 amount = totalProtocolFees;
        require(amount > 0, "No fees to withdraw");
        totalProtocolFees = 0;
        payable(owner()).transfer(amount);
        emit FeesWithdrawn(owner(), uint224(amount));
    }

    /// @notice Allows the admin to directly grant Impact Points, e.g., for off-chain achievements.
    /// @param _recipient The address to grant Impact Points to.
    /// @param _amount The amount of Impact Points to grant.
    function grantImpactByAdmin(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        _updateImpactPoints(_recipient, _amount);
        emit ImpactPointsGranted(_recipient, _amount, "Admin grant");
    }

    // --- II. Impact Points Management ---

    /// @notice Triggers the decay of Impact Points for a specified user. Can be called by anyone.
    /// This is a simplified decay mechanism. More advanced systems might use a continuous decay
    /// or decay based on user inactivity/last interaction.
    /// @param _user The address whose Impact Points should be decayed.
    function decayImpactPoints(address _user) public whenNotPaused {
        uint64 lastUpdateBlock = lastImpactUpdateBlock[_user];
        if (lastUpdateBlock == 0) { // No previous update, set current block
            lastImpactUpdateBlock[_user] = uint64(block.number);
            return;
        }

        uint64 blocksSinceLastUpdate = uint64(block.number) - lastUpdateBlock;
        if (blocksSinceLastUpdate == 0) return; // No blocks passed

        uint256 currentImpact = impactPoints[_user];
        if (currentImpact == 0) return;

        uint256 decayAmount = (currentImpact * impactDecayRatePerThousandBlocks * blocksSinceLastUpdate) / 1000;
        if (decayAmount == 0 && blocksSinceLastUpdate < 1000) return; // Only decay if significant blocks passed or decay is > 0
        if (decayAmount >= currentImpact) {
            decayAmount = currentImpact; // Cap decay at current impact
        }

        if (decayAmount > 0) {
            impactPoints[_user] -= decayAmount;
            lastImpactUpdateBlock[_user] = uint64(block.number); // Update last update block
            emit ImpactPointsDecayed(_user, decayAmount, impactPoints[_user]);
        }
    }

    /// @notice Returns the current Impact Points of a given address.
    /// @param _user The address to query.
    /// @return The current Impact Points of the user.
    function getImpactPoints(address _user) public view returns (uint256) {
        return impactPoints[_user];
    }

    // --- III. Attestation & Challenge System ---

    /// @notice Allows an eligible user to attest to another user's positive impact, paying a fee.
    /// @param _recipient The address whose impact is being attested.
    /// @param _attestationUri URI pointing to details/proof of the attestation.
    function attestImpact(address _recipient, string memory _attestationUri)
        external
        payable
        whenNotPaused
    {
        require(msg.value == attestationFee, "Incorrect attestation fee");
        require(impactPoints[msg.sender] >= minAttestorImpactForAttestation, "Attestor lacks sufficient impact");
        require(_recipient != address(0) && _recipient != msg.sender, "Invalid recipient or self-attestation");
        
        totalProtocolFees += msg.value;

        uint256 id = _nextAttestationId.current();
        attestations[id] = Attestation({
            id: id,
            attestor: msg.sender,
            recipient: _recipient,
            impactAmount: 10, // Example: each attestation grants 10 IP, can be dynamic
            timestamp: uint64(block.timestamp),
            attestationUri: _attestationUri,
            isValid: true // Initially valid, until challenged successfully
        });
        _nextAttestationId.increment();

        _updateImpactPoints(_recipient, attestations[id].impactAmount); // Grant impact immediately
        emit ImpactAttested(id, msg.sender, _recipient, attestations[id].impactAmount, _attestationUri);
    }

    /// @notice Allows any user to challenge an attestation by depositing a bond.
    /// @param _attestationId The ID of the attestation to challenge.
    function challengeAttestation(uint256 _attestationId) external payable whenNotPaused {
        Attestation storage attestation = attestations[_attestationId];
        require(attestation.id != 0, "Attestation does not exist");
        require(attestation.isValid, "Attestation is already invalid or challenged");
        require(msg.value == challengeBondAmount, "Incorrect challenge bond amount");

        // Check for existing challenge for this attestation
        for (uint256 i = 1; i < _nextChallengeId.current(); i++) {
            if (challenges[i].attestationId == _attestationId && !challenges[i].resolved) {
                revert("Attestation already under an active challenge");
            }
        }

        uint256 id = _nextChallengeId.current();
        challenges[id] = Challenge({
            id: id,
            attestationId: _attestationId,
            challenger: msg.sender,
            bondAmount: msg.value,
            challengeStartTimestamp: uint66(block.timestamp),
            challengeEndTimestamp: uint66(block.timestamp) + challengePeriod,
            resolved: false,
            challengerWon: false
        });
        _nextChallengeId.increment();

        attestation.isValid = false; // Mark attestation as under dispute
        emit AttestationChallengeInitiated(id, _attestationId, msg.sender);
    }

    /// @notice Owner/admin resolves a challenge, distributing bonds accordingly and potentially reversing the attestation's impact.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _challengerWins True if the challenger's claim is upheld, false otherwise.
    function resolveChallenge(uint256 _challengeId, bool _challengerWins) external onlyOwner {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "Challenge does not exist");
        require(!challenge.resolved, "Challenge already resolved");
        require(block.timestamp >= challenge.challengeEndTimestamp, "Challenge period not over yet");

        Attestation storage attestation = attestations[challenge.attestationId];

        challenge.resolved = true;
        challenge.challengerWon = _challengerWins;

        if (_challengerWins) {
            // Challenger wins: return bond to challenger, slash attestor's bond/impact (if any, or just fees)
            // For simplicity, we just refund challenger and remove attestation's impact.
            payable(challenge.challenger).transfer(challenge.bondAmount);
            // Revert the impact points granted by this attestation
            if (impactPoints[attestation.recipient] >= attestation.impactAmount) {
                 impactPoints[attestation.recipient] -= attestation.impactAmount;
                 emit ImpactPointsDecayed(attestation.recipient, attestation.impactAmount, impactPoints[attestation.recipient]);
            }
        } else {
            // Challenger loses: slash challenger's bond, attestation becomes valid again
            totalProtocolFees += challenge.bondAmount; // Challenger's bond goes to protocol fees
            attestation.isValid = true;
        }

        emit AttestationChallengeResolved(_challengeId, challenge.attestationId, _challengerWins);
    }

    /// @notice Returns the full details of a specific attestation.
    /// @param _attestationId The ID of the attestation.
    /// @return The attestation details.
    function getAttestationDetails(uint256 _attestationId) public view returns (Attestation memory) {
        return attestations[_attestationId];
    }

    /// @notice Returns the full details of a specific challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return The challenge details.
    function getChallengeDetails(uint256 _challengeId) public view returns (Challenge memory) {
        return challenges[_challengeId];
    }

    // --- IV. Impact Certificate (ERC721) Management ---

    /// @notice Mints an Impact Certificate NFT by staking a portion of the caller's Impact Points,
    /// designating a target entity for influence.
    /// @param _stakedImpactAmount The amount of Impact Points to stake.
    /// @param _targetEntity The address of the entity this certificate aims to influence/sponsor.
    /// @param _metadataUri Initial URI for the certificate's dynamic metadata.
    function mintImpactCertificate(uint256 _stakedImpactAmount, address _targetEntity, string memory _metadataUri)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        require(msg.value == impactCertificateBondAmount, "Incorrect certificate bond amount");
        require(_stakedImpactAmount > 0, "Must stake a positive amount of impact");
        require(impactPoints[msg.sender] >= _stakedImpactAmount, "Insufficient Impact Points to stake");
        require(impactPoints[msg.sender] >= minImpactForCertificateCreation, "Caller lacks minimum impact to create certificate");
        require(_targetEntity != address(0), "Invalid target entity address");

        // Deduct staked IP from sender's balance
        impactPoints[msg.sender] -= _stakedImpactAmount;
        _updateLastImpactUpdateBlock(msg.sender); // Update last interaction block

        uint256 tokenId = _nextCertificateId.current();
        _safeMint(msg.sender, tokenId);

        impactCertificateData[tokenId] = ImpactCertificateData({
            stakedImpactAmount: _stakedImpactAmount,
            owner: msg.sender, // Keep track of initial minter
            targetEntity: _targetEntity,
            metadataUri: _metadataUri,
            mintTimestamp: uint64(block.timestamp)
        });
        _nextCertificateId.increment();

        // The bond is held by the contract. It will be refunded on redemption.
        emit ImpactCertificateMinted(tokenId, msg.sender, _stakedImpactAmount, _targetEntity, _metadataUri);
        return tokenId;
    }

    /// @notice Burns an Impact Certificate NFT, returning the staked Impact Points to the owner
    /// (subject to any decay or penalties). Refunds the bond.
    /// @param _tokenId The ID of the Impact Certificate to redeem.
    function redeemImpactCertificate(uint256 _tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        ImpactCertificateData storage cert = impactCertificateData[_tokenId];
        require(cert.owner != address(0), "Certificate does not exist"); // Check if initialized

        uint256 returnedImpact = cert.stakedImpactAmount; // Can apply decay here based on time/performance

        _burn(_tokenId); // Burn the NFT

        // Return staked IP to owner's non-transferable balance
        _updateImpactPoints(msg.sender, returnedImpact);
        // Refund the bond
        payable(msg.sender).transfer(impactCertificateBondAmount);

        // Clear certificate data and delegation
        delete impactCertificateData[_tokenId];
        delete certificateDelegates[_tokenId];

        emit ImpactCertificateRedeemed(_tokenId, msg.sender, returnedImpact);
    }

    /// @notice Allows the certificate owner to change the target entity their certificate is sponsoring.
    /// @param _tokenId The ID of the Impact Certificate.
    /// @param _newTargetEntity The new address of the entity to sponsor.
    function reassignCertificateTarget(uint256 _tokenId, address _newTargetEntity) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(_newTargetEntity != address(0), "Invalid new target entity address");
        ImpactCertificateData storage cert = impactCertificateData[_tokenId];
        require(cert.owner != address(0), "Certificate does not exist");

        address oldTarget = cert.targetEntity;
        cert.targetEntity = _newTargetEntity;

        emit ImpactCertificateTargetReassigned(_tokenId, oldTarget, _newTargetEntity);
    }

    /// @notice Allows the certificate owner to update the URI for the certificate's dynamic metadata.
    /// @param _tokenId The ID of the Impact Certificate.
    /// @param _newMetadataUri The new metadata URI.
    function updateCertificateMetadata(uint256 _tokenId, string memory _newMetadataUri) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        ImpactCertificateData storage cert = impactCertificateData[_tokenId];
        require(cert.owner != address(0), "Certificate does not exist");

        cert.metadataUri = _newMetadataUri;
        emit ImpactCertificateMetadataUpdated(_tokenId, _newMetadataUri);
    }

    /// @notice Returns the amount of Impact Points currently staked by a given Impact Certificate.
    /// @param _tokenId The ID of the Impact Certificate.
    /// @return The staked Impact Points.
    function getCertificateStakedImpact(uint256 _tokenId) public view returns (uint256) {
        return impactCertificateData[_tokenId].stakedImpactAmount;
    }

    /// @notice Overrides ERC721's tokenURI to provide dynamic metadata based on the certificate's state and underlying impact.
    /// For a full dynamic NFT, this would likely query an off-chain API or on-chain data to construct a JSON blob.
    /// @param _tokenId The ID of the Impact Certificate.
    /// @return A URI pointing to the certificate's metadata.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        ImpactCertificateData storage cert = impactCertificateData[_tokenId];

        // Example of simple dynamic metadata: could embed the staked amount or target.
        // In a real application, this URI would likely point to an off-chain API
        // that generates dynamic JSON metadata based on the contract's state.
        string memory baseURI = cert.metadataUri;
        if (bytes(baseURI).length == 0) {
            baseURI = "ipfs://QmbnQ4QxM2Yg6F3J9g8H9n6V3S6k3W2Q3L3Z5x7C9K1V5J3B7H8N0P9Q0R0S0T1U2V3W4X5Y6Z7A8B9C0D1E2F3G4H5I6J7K8L9M0N1O2P3Q4R5S6T7U7"; // Placeholder default
        }
        
        string memory stakedImpactStr = cert.stakedImpactAmount.toString();
        string memory targetEntityStr = Strings.toHexString(uint160(cert.targetEntity), 20);

        // This is a simplified example. Real dynamic NFTs often return a base URI
        // to an external API endpoint like `api.example.com/nft/{tokenId}` which
        // then generates the JSON metadata dynamically, pulling data from the blockchain.
        // For on-chain metadata, you'd construct the full JSON here.
        return string(abi.encodePacked(
            baseURI,
            "?staked=", stakedImpactStr,
            "&target=", targetEntityStr,
            "&owner=", Strings.toHexString(uint160(ownerOf(_tokenId)), 20)
        ));
    }


    // --- V. Certificate Delegation ---

    /// @notice Allows the owner of an Impact Certificate to delegate its voting/influence power to another address
    /// without transferring the NFT itself (similar to Compound's delegation).
    /// @param _tokenId The ID of the Impact Certificate.
    /// @param _delegatee The address to delegate the power to.
    function delegateCertificatePower(uint256 _tokenId, address _delegatee) external whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the certificate owner");
        certificateDelegates[_tokenId] = _delegatee;
        emit CertificatePowerDelegated(_tokenId, msg.sender, _delegatee);
    }

    /// @notice Revokes any previously set delegation for an Impact Certificate.
    /// @param _tokenId The ID of the Impact Certificate.
    function revokeCertificateDelegation(uint256 _tokenId) external whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the certificate owner");
        delete certificateDelegates[_tokenId];
        emit CertificatePowerRevoked(_tokenId, msg.sender);
    }

    /// @notice Returns the address currently delegated the power of a specific Impact Certificate.
    /// @param _tokenId The ID of the Impact Certificate.
    /// @return The delegatee address, or address(0) if no delegation.
    function getCertificateDelegate(uint256 _tokenId) public view returns (address) {
        return certificateDelegates[_tokenId];
    }

    // --- VI. Utility & Query Functions ---

    /// @notice Returns the ID of the most recently created attestation.
    /// @return The latest attestation ID.
    function getLatestAttestationId() public view returns (uint256) {
        return _nextAttestationId.current() - 1;
    }

    // --- Internal Helpers ---

    /// @dev Internal function to safely update impact points and record last update block.
    /// @param _user The user's address.
    /// @param _amount The amount of impact to add.
    function _updateImpactPoints(address _user, uint256 _amount) internal {
        decayImpactPoints(_user); // Apply decay before adding new points
        impactPoints[_user] += _amount;
        _updateLastImpactUpdateBlock(_user);
    }

    /// @dev Internal function to update the lastImpactUpdateBlock for a user.
    /// @param _user The user's address.
    function _updateLastImpactUpdateBlock(address _user) internal {
        lastImpactUpdateBlock[_user] = uint64(block.number);
    }
}
```