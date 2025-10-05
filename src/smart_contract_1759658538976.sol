This smart contract, "Epochal Resonance," introduces an advanced concept for decentralized reputation and skill validation using dynamic, soulbound NFTs. It goes beyond simple badges by enabling NFTs to evolve based on on-chain activities, community attestations, and a built-in decay mechanism that ensures relevance and freshness of reputation.

**Core Concepts:**

1.  **Soulbound NFTs (sNFTs):** Users mint a non-transferable "Resonance Core" NFT that serves as their on-chain identity and reputation anchor.
2.  **Resonance Tracks:** Reputation is segmented into distinct "tracks" (e.g., Builder, Governor, Curator), each representing a different domain of expertise or contribution.
3.  **Dynamic Evolution:** The sNFT's "level" and metadata (e.g., visual attributes) evolve based on accumulated "Resonance Points" (RP) across these tracks.
4.  **RP Acquisition:** RP can be earned through:
    *   **Challenges:** On-chain tasks or events, potentially requiring external verification.
    *   **Attestations:** Designated "Attestors" (e.g., community leads, project managers) can grant RP to users for their contributions.
5.  **Reputation Decay:** RP within each track gradually decays over time, incentivizing continuous engagement and ensuring that reputation remains current and active.
6.  **Influence Score:** An aggregated, weighted score reflecting a user's total on-chain influence based on their decayed RP across all tracks.

---

## Epochal Resonance Smart Contract: Outline & Function Summary

**Contract Name:** `EpochalResonance`

**Inherits:** `ERC721`, `Ownable`, `Pausable`, `Counters`

---

**I. Core Setup & Governance (Admin/Owner Functions)**

1.  **`constructor()`**
    *   **Summary:** Initializes the contract, setting the name, symbol, base URI, and the initial owner.
2.  **`pauseContract()`**
    *   **Summary:** Emergency function allowing the owner to pause all core contract interactions (minting, RP adjustments, challenge submissions).
3.  **`unpauseContract()`**
    *   **Summary:** Unpauses the contract, restoring normal functionality.
4.  **`setBaseURI(string memory newURI)`**
    *   **Summary:** Allows the owner to update the base URI for NFT metadata, useful for updating IPFS gateways or hosting services.
5.  **`setVerifierAddress(address _verifier, bool _isActive)`**
    *   **Summary:** Registers or unregisters an external smart contract or address responsible for verifying challenge completions. This enables off-chain or complex on-chain verification logic without bloating the main contract.
6.  **`setRPDecayPeriod(uint256 _decayPeriod)`**
    *   **Summary:** Sets the global time interval (in seconds) used for calculating RP decay. A shorter period means faster decay.

**II. Resonance Track Management (Admin/Owner Functions)**

7.  **`addResonanceTrack(string memory _name, string memory _description, uint16 _decayRateBasisPoints, uint256 _influenceWeight)`**
    *   **Summary:** Creates a new "Resonance Track" (e.g., "Builder," "Governor") where users can accumulate RP. Defines its name, description, decay rate (in basis points), and its weight in the overall influence calculation.
8.  **`updateResonanceTrack(uint256 _trackId, string memory _name, string memory _description, uint16 _decayRateBasisPoints, uint256 _influenceWeight, bool _isActive)`**
    *   **Summary:** Modifies details of an existing resonance track, including its name, description, decay rate, influence weight, or activation status.
9.  **`deactivateResonanceTrack(uint256 _trackId)`**
    *   **Summary:** Deactivates a resonance track, preventing further RP accumulation or attestations for it. Existing RP will still decay.

**III. Challenge Management (Admin/Owner & Verifier Functions)**

10. **`createChallenge(string memory _name, string memory _description, uint256 _trackId, uint256 _rewardRP, uint256 _deadline, bool _requiresExternalVerification)`**
    *   **Summary:** Defines a new challenge that users can complete to earn RP. Specifies the challenge name, description, target track, RP reward, submission deadline, and whether it requires external verification.
11. **`updateChallenge(uint256 _challengeId, string memory _name, string memory _description, uint256 _trackId, uint256 _rewardRP, uint256 _deadline, bool _requiresExternalVerification, bool _isActive)`**
    *   **Summary:** Modifies an existing challenge's details or its active status.
12. **`deactivateChallenge(uint256 _challengeId)`**
    *   **Summary:** Disables a challenge, preventing new submissions or verifications.
13. **`verifyChallengeCompletion(uint256 _challengeId, uint256 _tokenId, address _solver)`**
    *   **Summary:** *Callable only by registered `verifierAddress`.* This function marks a specific challenge as successfully completed for a given sNFT and grants the associated RP.

**IV. Attestor Management (Admin/Owner & Attestor Functions)**

14. **`addAttestor(address _attestor, uint256 _trackId, uint256 _maxAttestableRPPerPeriod)`**
    *   **Summary:** Designates an address as an "Attestor" for a specific resonance track, allowing them to grant RP to sNFTs. Includes a cap on the maximum RP they can attest within a decay period to prevent abuse.
15. **`removeAttestor(address _attestor, uint256 _trackId)`**
    *   **Summary:** Revokes the Attestor role for a specific address and track.
16. **`attestResonancePoints(uint256 _tokenId, uint256 _trackId, uint256 _amount)`**
    *   **Summary:** *Callable only by a registered Attestor.* Allows an Attestor to grant a specified amount of RP to a user's sNFT within a particular track, adhering to their per-period attestation cap.

**V. User Interaction (Public Functions)**

17. **`mintResonanceCore()`**
    *   **Summary:** Allows a user to mint their unique, non-transferable "Resonance Core" NFT. Each user can only mint one such NFT.
18. **`submitChallengeSolution(uint256 _challengeId, bytes memory _solutionProof)`**
    *   **Summary:** Users submit their proof of completion for a specific challenge. If the challenge requires external verification, this proof is then evaluated by the registered verifier.
19. **`getResonancePoints(uint256 _tokenId, uint256 _trackId)`**
    *   **Summary:** Returns the current, *decay-adjusted* Resonance Points for a given sNFT within a specific track.
20. **`getTokenLevel(uint256 _tokenId)`**
    *   **Summary:** Calculates and returns the aggregated "level" of an sNFT, based on the sum of its decay-adjusted RP across all tracks. This can be used for dynamic metadata.
21. **`tokenURI(uint256 _tokenId)`**
    *   **Summary:** Returns the dynamic metadata URI for the sNFT. This URI is generated on-the-fly, encoding attributes like the token's level and RP in various tracks into a base64-encoded JSON string.
22. **`calculateOverallInfluence(uint256 _tokenId)`**
    *   **Summary:** Computes a weighted "influence score" for an sNFT, summing up its decay-adjusted RP from all tracks, each weighted by its track's `influenceWeight`.
23. **`getCurrentResonanceTracks()`**
    *   **Summary:** Returns an array of details for all currently active resonance tracks, allowing dApps to display available tracks.
24. **`getChallengeDetails(uint256 _challengeId)`**
    *   **Summary:** Provides detailed information about a specific challenge, including its name, description, reward, deadline, and verification status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title EpochalResonance
 * @dev A dynamic, soulbound NFT contract for on-chain reputation and skill validation.
 *      NFTs evolve based on accumulated Resonance Points (RP) from challenges and attestations,
 *      featuring a decay mechanism to ensure reputation freshness.
 */
contract EpochalResonance is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _trackIdCounter;
    Counters.Counter private _challengeIdCounter;

    string private _baseTokenURI;
    address public verifierAddress;
    uint256 public rpDecayPeriod; // Global period (in seconds) for RP decay calculation

    // Structs definitions
    struct ResonanceTrack {
        string name;
        string description;
        uint16 decayRateBasisPoints; // e.g., 100 for 1% per decay period
        uint256 influenceWeight; // Weight for overall influence calculation
        bool isActive;
    }

    struct Challenge {
        string name;
        string description;
        uint256 trackId;
        uint256 rewardRP;
        uint256 deadline;
        bool requiresExternalVerification; // If true, only verifierAddress can complete
        bool isActive;
    }

    struct UserTrackRecord {
        uint256 rp; // Current Resonance Points
        uint256 lastRPUpdateTimestamp; // Timestamp of last RP change (grant/decay calc)
    }

    struct AttestorRole {
        uint256 trackId;
        uint256 maxAttestableRPPerPeriod;
        uint256 attestedRPThisPeriod; // RP attested by this attestor in current decay period
        uint256 lastPeriodResetTimestamp;
    }

    // Mappings
    mapping(uint256 => ResonanceTrack) public resonanceTracks;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => mapping(uint256 => UserTrackRecord)) private _userTrackData; // tokenId => trackId => UserTrackRecord
    mapping(uint256 => mapping(uint256 => bool)) public challengeCompleted; // tokenId => challengeId => isCompleted
    mapping(address => mapping(uint256 => AttestorRole)) public attestors; // attestorAddress => trackId => AttestorRole
    mapping(address => uint256) public userToTokenId; // Maps user address to their soulbound tokenId (1:1)

    // Events
    event ResonanceCoreMinted(uint256 indexed tokenId, address indexed owner);
    event ResonanceTrackAdded(uint256 indexed trackId, string name, uint16 decayRate);
    event ResonanceTrackUpdated(uint256 indexed trackId, string name, uint16 decayRate, bool isActive);
    event ChallengeCreated(uint256 indexed challengeId, string name, uint256 trackId, uint256 rewardRP);
    event ChallengeUpdated(uint256 indexed challengeId, string name, uint256 trackId, bool isActive);
    event ChallengeSubmitted(uint256 indexed challengeId, uint256 indexed tokenId, address indexed submitter);
    event ChallengeVerified(uint256 indexed challengeId, uint256 indexed tokenId, address indexed verifier);
    event ResonancePointsAttested(uint256 indexed tokenId, uint256 indexed trackId, address indexed attestor, uint256 amount);
    event AttestorAdded(address indexed attestor, uint256 indexed trackId, uint256 maxAttestableRP);
    event AttestorRemoved(address indexed attestor, uint256 indexed trackId);
    event VerifierAddressSet(address indexed oldVerifier, address indexed newVerifier, bool isActive);
    event RPDecayPeriodSet(uint256 oldPeriod, uint256 newPeriod);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, string memory baseURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI_;
        rpDecayPeriod = 7 days; // Default to 7 days
    }

    // --- Modifiers ---

    modifier onlyVerifier() {
        require(msg.sender == verifierAddress, "EpochalResonance: Not the designated verifier");
        _;
    }

    modifier onlyAttestor(uint256 _trackId) {
        require(attestors[msg.sender][_trackId].trackId == _trackId, "EpochalResonance: Not an attestor for this track");
        _;
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Calculates the decay for Resonance Points based on time elapsed and decay rate.
     *      Updates the stored RP and lastRPUpdateTimestamp to reflect the decay.
     * @param _rp The current Resonance Points.
     * @param _lastUpdateTimestamp The timestamp of the last RP update.
     * @param _decayRateBasisPoints The decay rate in basis points (e.g., 100 for 1%).
     * @return The decay-adjusted Resonance Points.
     */
    function _applyDecay(uint256 _rp, uint256 _lastUpdateTimestamp, uint16 _decayRateBasisPoints) internal view returns (uint256) {
        if (_decayRateBasisPoints == 0 || rpDecayPeriod == 0 || _rp == 0) {
            return _rp;
        }

        uint256 timeElapsed = block.timestamp - _lastUpdateTimestamp;
        if (timeElapsed == 0) { // No time has passed, no decay needed
            return _rp;
        }

        uint256 numPeriods = timeElapsed / rpDecayPeriod;
        if (numPeriods == 0) { // Not enough time for a full decay period
            return _rp;
        }

        uint256 currentRP = _rp;
        // Optimization: Use `exp` approximation or a fixed-point library for better precision if needed.
        // For simplicity, we'll apply it iteratively for a few periods, or use a single calculation.
        // Single calculation: currentRP * (1 - decayRate)^numPeriods
        // Using basis points: factor = (10000 - decayRateBasisPoints) / 10000
        // currentRP = currentRP * (factor ^ numPeriods)

        // For simplicity and gas, let's cap numPeriods for this example, or just calculate directly.
        // A direct calculation with integer math for (1-rate)^N is tricky.
        // Let's use a simplified approach that loses precision for very large N.
        // Each period, RP = RP * (1 - decayRateBasisPoints / 10000)

        for (uint256 i = 0; i < numPeriods; i++) {
            currentRP = currentRP * (10000 - _decayRateBasisPoints) / 10000;
            if (currentRP == 0) break; // Avoid unnecessary calculations
        }
        return currentRP;
    }

    /**
     * @dev Internal function to update RP for a specific track, applying decay and persisting.
     * @param _tokenId The ID of the sNFT.
     * @param _trackId The ID of the resonance track.
     * @param _amountDelta The change in RP (can be positive for gain).
     */
    function _updateResonancePoints(uint256 _tokenId, uint256 _trackId, uint256 _amountDelta) internal {
        ResonanceTrack storage track = resonanceTracks[_trackId];
        require(track.isActive, "EpochalResonance: Track is not active");

        UserTrackRecord storage record = _userTrackData[_tokenId][_trackId];

        // Apply decay to the current stored RP before adding new RP
        record.rp = _applyDecay(record.rp, record.lastRPUpdateTimestamp, track.decayRateBasisPoints);

        // Add the new RP
        record.rp += _amountDelta;
        record.lastRPUpdateTimestamp = block.timestamp;
    }

    /**
     * @dev Overrides ERC721's _transfer to make tokens soulbound (non-transferable).
     * @param from The current owner of the token.
     * @param to The new owner.
     * @param tokenId The token to transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("EpochalResonance: Soulbound tokens are non-transferable");
    }

    // --- I. Core Setup & Governance (Owner Functions) ---

    /**
     * @dev Pauses all core contract interactions (minting, RP adjustments, challenge submissions).
     * @dev Emits a Paused event.
     * @dev Only callable by the owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, restoring normal functionality.
     * @dev Emits an Unpaused event.
     * @dev Only callable by the owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to update the base URI for NFT metadata.
     * @param newURI The new base URI.
     * @dev Only callable by the owner.
     */
    function setBaseURI(string memory newURI) public onlyOwner {
        _baseTokenURI = newURI;
    }

    /**
     * @dev Registers or unregisters an external smart contract or address responsible for verifying challenge completions.
     * @param _verifier The address of the verifier.
     * @param _isActive True to set, false to unset.
     * @dev Only callable by the owner.
     */
    function setVerifierAddress(address _verifier, bool _isActive) public onlyOwner {
        address oldVerifier = verifierAddress;
        if (_isActive) {
            verifierAddress = _verifier;
        } else {
            verifierAddress = address(0);
        }
        emit VerifierAddressSet(oldVerifier, verifierAddress, _isActive);
    }

    /**
     * @dev Sets the global time interval (in seconds) used for calculating RP decay.
     * @param _decayPeriod The new decay period in seconds. Must be greater than 0.
     * @dev Only callable by the owner.
     */
    function setRPDecayPeriod(uint256 _decayPeriod) public onlyOwner {
        require(_decayPeriod > 0, "EpochalResonance: Decay period must be greater than 0");
        emit RPDecayPeriodSet(rpDecayPeriod, _decayPeriod);
        rpDecayPeriod = _decayPeriod;
    }

    // --- II. Resonance Track Management (Owner Functions) ---

    /**
     * @dev Creates a new "Resonance Track" where users can accumulate RP.
     * @param _name The name of the track (e.g., "Builder," "Governor").
     * @param _description A brief description of the track.
     * @param _decayRateBasisPoints The decay rate in basis points (0-10000, e.g., 100 for 1% per period).
     * @param _influenceWeight The weight this track contributes to the overall influence score.
     * @dev Only callable by the owner.
     * @return The ID of the newly created track.
     */
    function addResonanceTrack(
        string memory _name,
        string memory _description,
        uint16 _decayRateBasisPoints,
        uint256 _influenceWeight
    ) public onlyOwner returns (uint256) {
        _trackIdCounter.increment();
        uint256 newTrackId = _trackIdCounter.current();
        resonanceTracks[newTrackId] = ResonanceTrack({
            name: _name,
            description: _description,
            decayRateBasisPoints: _decayRateBasisPoints,
            influenceWeight: _influenceWeight,
            isActive: true
        });
        emit ResonanceTrackAdded(newTrackId, _name, _decayRateBasisPoints);
        return newTrackId;
    }

    /**
     * @dev Modifies details of an existing resonance track.
     * @param _trackId The ID of the track to update.
     * @param _name The new name for the track.
     * @param _description The new description for the track.
     * @param _decayRateBasisPoints The new decay rate in basis points.
     * @param _influenceWeight The new influence weight.
     * @param _isActive The new active status for the track.
     * @dev Only callable by the owner.
     */
    function updateResonanceTrack(
        uint256 _trackId,
        string memory _name,
        string memory _description,
        uint16 _decayRateBasisPoints,
        uint256 _influenceWeight,
        bool _isActive
    ) public onlyOwner {
        require(_trackId > 0 && _trackId <= _trackIdCounter.current(), "EpochalResonance: Invalid track ID");
        resonanceTracks[_trackId].name = _name;
        resonanceTracks[_trackId].description = _description;
        resonanceTracks[_trackId].decayRateBasisPoints = _decayRateBasisPoints;
        resonanceTracks[_trackId].influenceWeight = _influenceWeight;
        resonanceTracks[_trackId].isActive = _isActive;
        emit ResonanceTrackUpdated(_trackId, _name, _decayRateBasisPoints, _isActive);
    }

    /**
     * @dev Deactivates a resonance track, preventing further RP accumulation or attestations for it.
     * @param _trackId The ID of the track to deactivate.
     * @dev Only callable by the owner.
     */
    function deactivateResonanceTrack(uint256 _trackId) public onlyOwner {
        require(_trackId > 0 && _trackId <= _trackIdCounter.current(), "EpochalResonance: Invalid track ID");
        require(resonanceTracks[_trackId].isActive, "EpochalResonance: Track is already inactive");
        resonanceTracks[_trackId].isActive = false;
        emit ResonanceTrackUpdated(_trackId, resonanceTracks[_trackId].name, resonanceTracks[_trackId].decayRateBasisPoints, false);
    }

    // --- III. Challenge Management (Owner & Verifier Functions) ---

    /**
     * @dev Defines a new challenge that users can complete to earn RP.
     * @param _name The name of the challenge.
     * @param _description A description of the challenge.
     * @param _trackId The ID of the resonance track this challenge contributes to.
     * @param _rewardRP The amount of RP awarded upon completion.
     * @param _deadline The timestamp by which the challenge must be completed.
     * @param _requiresExternalVerification If true, `verifyChallengeCompletion` must be called by the `verifierAddress`.
     * @dev Only callable by the owner.
     * @return The ID of the newly created challenge.
     */
    function createChallenge(
        string memory _name,
        string memory _description,
        uint256 _trackId,
        uint256 _rewardRP,
        uint256 _deadline,
        bool _requiresExternalVerification
    ) public onlyOwner returns (uint256) {
        require(_trackId > 0 && _trackId <= _trackIdCounter.current(), "EpochalResonance: Invalid track ID");
        require(resonanceTracks[_trackId].isActive, "EpochalResonance: Target track is inactive");
        require(_deadline > block.timestamp, "EpochalResonance: Challenge deadline must be in the future");
        if (_requiresExternalVerification) {
            require(verifierAddress != address(0), "EpochalResonance: Verifier address not set for external verification");
        }

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();
        challenges[newChallengeId] = Challenge({
            name: _name,
            description: _description,
            trackId: _trackId,
            rewardRP: _rewardRP,
            deadline: _deadline,
            requiresExternalVerification: _requiresExternalVerification,
            isActive: true
        });
        emit ChallengeCreated(newChallengeId, _name, _trackId, _rewardRP);
        return newChallengeId;
    }

    /**
     * @dev Modifies an existing challenge's details or its active status.
     * @param _challengeId The ID of the challenge to update.
     * @param _name The new name for the challenge.
     * @param _description The new description.
     * @param _trackId The new target track ID.
     * @param _rewardRP The new RP reward.
     * @param _deadline The new deadline timestamp.
     * @param _requiresExternalVerification The new external verification status.
     * @param _isActive The new active status.
     * @dev Only callable by the owner.
     */
    function updateChallenge(
        uint256 _challengeId,
        string memory _name,
        string memory _description,
        uint256 _trackId,
        uint256 _rewardRP,
        uint256 _deadline,
        bool _requiresExternalVerification,
        bool _isActive
    ) public onlyOwner {
        require(_challengeId > 0 && _challengeId <= _challengeIdCounter.current(), "EpochalResonance: Invalid challenge ID");
        require(_trackId > 0 && _trackId <= _trackIdCounter.current(), "EpochalResonance: Invalid track ID");
        require(resonanceTracks[_trackId].isActive, "EpochalResonance: Target track is inactive");
        require(_deadline > block.timestamp, "EpochalResonance: Challenge deadline must be in the future");
        if (_requiresExternalVerification) {
            require(verifierAddress != address(0), "EpochalResonance: Verifier address not set for external verification");
        }

        Challenge storage challenge = challenges[_challengeId];
        challenge.name = _name;
        challenge.description = _description;
        challenge.trackId = _trackId;
        challenge.rewardRP = _rewardRP;
        challenge.deadline = _deadline;
        challenge.requiresExternalVerification = _requiresExternalVerification;
        challenge.isActive = _isActive;
        emit ChallengeUpdated(_challengeId, _name, _trackId, _isActive);
    }

    /**
     * @dev Disables a challenge, preventing new submissions or verifications.
     * @param _challengeId The ID of the challenge to deactivate.
     * @dev Only callable by the owner.
     */
    function deactivateChallenge(uint256 _challengeId) public onlyOwner {
        require(_challengeId > 0 && _challengeId <= _challengeIdCounter.current(), "EpochalResonance: Invalid challenge ID");
        require(challenges[_challengeId].isActive, "EpochalResonance: Challenge is already inactive");
        challenges[_challengeId].isActive = false;
        emit ChallengeUpdated(_challengeId, challenges[_challengeId].name, challenges[_challengeId].trackId, false);
    }

    /**
     * @dev Marks a specific challenge as successfully completed for a given sNFT and grants the associated RP.
     * @param _challengeId The ID of the challenge.
     * @param _tokenId The ID of the sNFT that completed the challenge.
     * @param _solver The address of the user who submitted the solution.
     * @dev Callable only by the registered `verifierAddress`.
     */
    function verifyChallengeCompletion(uint256 _challengeId, uint256 _tokenId, address _solver)
        public
        onlyVerifier
        whenNotPaused
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.isActive, "EpochalResonance: Challenge is not active");
        require(block.timestamp <= challenge.deadline, "EpochalResonance: Challenge deadline passed");
        require(challenge.requiresExternalVerification, "EpochalResonance: Challenge does not require external verification");
        require(ownerOf(_tokenId) == _solver, "EpochalResonance: Token owner mismatch");
        require(!challengeCompleted[_tokenId][_challengeId], "EpochalResonance: Challenge already completed by this token");

        // Grant RP
        _updateResonancePoints(_tokenId, challenge.trackId, challenge.rewardRP);
        challengeCompleted[_tokenId][_challengeId] = true;

        emit ChallengeVerified(_challengeId, _tokenId, msg.sender);
    }

    // --- IV. Attestor Management (Owner & Attestor Functions) ---

    /**
     * @dev Designates an address as an "Attestor" for a specific resonance track, allowing them to grant RP to sNFTs.
     * @param _attestor The address to grant attestor role.
     * @param _trackId The track ID for which this address will be an attestor.
     * @param _maxAttestableRPPerPeriod The maximum RP this attestor can grant per decay period.
     * @dev Only callable by the owner.
     */
    function addAttestor(address _attestor, uint256 _trackId, uint256 _maxAttestableRPPerPeriod) public onlyOwner {
        require(_attestor != address(0), "EpochalResonance: Attestor address cannot be zero");
        require(_trackId > 0 && _trackId <= _trackIdCounter.current(), "EpochalResonance: Invalid track ID");
        require(resonanceTracks[_trackId].isActive, "EpochalResonance: Target track is inactive");
        require(attestors[_attestor][_trackId].trackId == 0, "EpochalResonance: Attestor already added for this track");

        attestors[_attestor][_trackId] = AttestorRole({
            trackId: _trackId,
            maxAttestableRPPerPeriod: _maxAttestableRPPerPeriod,
            attestedRPThisPeriod: 0,
            lastPeriodResetTimestamp: block.timestamp
        });
        emit AttestorAdded(_attestor, _trackId, _maxAttestableRPPerPeriod);
    }

    /**
     * @dev Revokes the Attestor role for a specific address and track.
     * @param _attestor The address to remove attestor role from.
     * @param _trackId The track ID from which the role should be removed.
     * @dev Only callable by the owner.
     */
    function removeAttestor(address _attestor, uint256 _trackId) public onlyOwner {
        require(attestors[_attestor][_trackId].trackId == _trackId, "EpochalResonance: Not an active attestor for this track");
        delete attestors[_attestor][_trackId];
        emit AttestorRemoved(_attestor, _trackId);
    }

    /**
     * @dev Allows an Attestor to grant a specified amount of RP to a user's sNFT within a particular track,
     *      adhering to their per-period attestation cap.
     * @param _tokenId The ID of the sNFT to grant RP to.
     * @param _trackId The ID of the resonance track.
     * @param _amount The amount of RP to grant.
     * @dev Callable only by a registered Attestor for the specified track.
     */
    function attestResonancePoints(uint256 _tokenId, uint256 _trackId, uint256 _amount)
        public
        onlyAttestor(_trackId)
        whenNotPaused
    {
        require(_amount > 0, "EpochalResonance: RP amount must be positive");
        require(_tokenId > 0 && _tokenId <= _tokenIdCounter.current(), "EpochalResonance: Invalid token ID");
        require(_exists(_tokenId), "EpochalResonance: Token does not exist");
        require(resonanceTracks[_trackId].isActive, "EpochalResonance: Target track is inactive");

        AttestorRole storage attestorRole = attestors[msg.sender][_trackId];

        // Reset attestedRPThisPeriod if a new decay period has started for this attestor
        if (block.timestamp >= attestorRole.lastPeriodResetTimestamp + rpDecayPeriod) {
            attestorRole.attestedRPThisPeriod = 0;
            attestorRole.lastPeriodResetTimestamp = block.timestamp; // Reset to current time
        }

        require(attestorRole.attestedRPThisPeriod + _amount <= attestorRole.maxAttestableRPPerPeriod,
            "EpochalResonance: Attestor has exceeded RP attestation cap for this period");

        _updateResonancePoints(_tokenId, _trackId, _amount);
        attestorRole.attestedRPThisPeriod += _amount;

        emit ResonancePointsAttested(_tokenId, _trackId, msg.sender, _amount);
    }

    // --- V. User Interaction (Public Functions) ---

    /**
     * @dev Allows a user to mint their unique, non-transferable "Resonance Core" NFT.
     *      Each address can only mint one such NFT.
     * @dev Emits a ResonanceCoreMinted event.
     * @return The ID of the newly minted sNFT.
     */
    function mintResonanceCore() public whenNotPaused returns (uint256) {
        require(userToTokenId[msg.sender] == 0, "EpochalResonance: Already minted a Resonance Core");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId);
        userToTokenId[msg.sender] = newTokenId;

        emit ResonanceCoreMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    /**
     * @dev Users submit their proof of completion for a specific challenge.
     *      If the challenge requires external verification, this proof is then evaluated by the registered verifier.
     * @param _challengeId The ID of the challenge.
     * @param _solutionProof A byte array representing the proof of completion (e.g., hash, transaction ID).
     * @dev Note: If `requiresExternalVerification` is true, RP is only granted after `verifyChallengeCompletion` is called.
     */
    function submitChallengeSolution(uint256 _challengeId, bytes memory _solutionProof) public whenNotPaused {
        uint256 tokenId = userToTokenId[msg.sender];
        require(tokenId != 0, "EpochalResonance: User has no Resonance Core NFT");
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.isActive, "EpochalResonance: Challenge is not active");
        require(block.timestamp <= challenge.deadline, "EpochalResonance: Challenge deadline passed");
        require(!challengeCompleted[tokenId][_challengeId], "EpochalResonance: Challenge already completed by this token");

        if (!challenge.requiresExternalVerification) {
            // For challenges not requiring external verification, grant RP immediately
            _updateResonancePoints(tokenId, challenge.trackId, challenge.rewardRP);
            challengeCompleted[tokenId][_challengeId] = true;
            emit ChallengeVerified(_challengeId, tokenId, msg.sender); // Treated as self-verified
        }
        // If external verification is required, the verifier will call verifyChallengeCompletion
        // The _solutionProof can be logged in the event or passed off-chain for external verification.

        emit ChallengeSubmitted(_challengeId, tokenId, msg.sender);
    }

    /**
     * @dev Returns the current, *decay-adjusted* Resonance Points for a given sNFT within a specific track.
     * @param _tokenId The ID of the sNFT.
     * @param _trackId The ID of the resonance track.
     * @return The decay-adjusted Resonance Points.
     */
    function getResonancePoints(uint256 _tokenId, uint256 _trackId) public view returns (uint256) {
        require(_exists(_tokenId), "EpochalResonance: Token does not exist");
        require(_trackId > 0 && _trackId <= _trackIdCounter.current(), "EpochalResonance: Invalid track ID");

        UserTrackRecord storage record = _userTrackData[_tokenId][_trackId];
        ResonanceTrack storage track = resonanceTracks[_trackId];

        return _applyDecay(record.rp, record.lastRPUpdateTimestamp, track.decayRateBasisPoints);
    }

    /**
     * @dev Calculates and returns the aggregated "level" of an sNFT, based on the sum of its decay-adjusted RP across all tracks.
     * @param _tokenId The ID of the sNFT.
     * @return The calculated overall level.
     */
    function getTokenLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "EpochalResonance: Token does not exist");

        uint256 totalEffectiveRP = 0;
        for (uint256 i = 1; i <= _trackIdCounter.current(); i++) {
            if (resonanceTracks[i].isActive) {
                totalEffectiveRP += getResonancePoints(_tokenId, i);
            }
        }
        // Simple logarithmic level calculation: level = log(totalRP)/log(base) * factor
        // For simplicity, let's use a linear scale for now, maybe with diminishing returns.
        // level = sqrt(totalEffectiveRP / 100) or totalEffectiveRP / 1000
        return totalEffectiveRP / 1000; // 1000 RP per level
    }

    /**
     * @dev Returns the dynamic metadata URI for the sNFT.
     *      This URI is generated on-the-fly, encoding attributes like the token's level and RP in various tracks
     *      into a base64-encoded JSON string.
     * @param _tokenId The ID of the sNFT.
     * @return The base64-encoded JSON metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 tokenLevel = getTokenLevel(_tokenId);
        uint256 totalInfluence = calculateOverallInfluence(_tokenId);

        // Start JSON string construction
        string memory json = string(abi.encodePacked(
            '{"name": "Resonance Core #', _tokenId.toString(),
            '", "description": "An evolving soulbound NFT reflecting on-chain reputation and skills in the Epochal Resonance network.",',
            '"image": "', _baseTokenURI, _tokenId.toString(), '.png",', // Example image path, could be dynamic based on level
            '"attributes": [',
            '{"trait_type": "Overall Level", "value": ', tokenLevel.toString(), '},',
            '{"trait_type": "Total Influence", "value": ', totalInfluence.toString(), '}'
        ));

        // Add attributes for each active resonance track
        for (uint256 i = 1; i <= _trackIdCounter.current(); i++) {
            ResonanceTrack storage track = resonanceTracks[i];
            if (track.isActive) {
                uint256 rp = getResonancePoints(_tokenId, i);
                json = string(abi.encodePacked(
                    json, ',',
                    '{"trait_type": "', track.name, ' Resonance", "value": ', rp.toString(), '}'
                ));
            }
        }

        json = string(abi.encodePacked(json, ']}'));

        // Encode JSON to base64
        string memory base64Json = Base64.encode(bytes(json));

        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    /**
     * @dev Computes a weighted "influence score" for an sNFT, summing up its decay-adjusted RP from all tracks,
     *      each weighted by its track's `influenceWeight`.
     * @param _tokenId The ID of the sNFT.
     * @return The calculated overall influence score.
     */
    function calculateOverallInfluence(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "EpochalResonance: Token does not exist");

        uint256 totalInfluence = 0;
        for (uint256 i = 1; i <= _trackIdCounter.current(); i++) {
            ResonanceTrack storage track = resonanceTracks[i];
            if (track.isActive) {
                uint256 effectiveRP = getResonancePoints(_tokenId, i);
                totalInfluence += (effectiveRP * track.influenceWeight);
            }
        }
        return totalInfluence;
    }

    /**
     * @dev Returns an array of details for all currently active resonance tracks.
     * @return An array of ResonanceTrack structs.
     */
    function getCurrentResonanceTracks() public view returns (ResonanceTrack[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= _trackIdCounter.current(); i++) {
            if (resonanceTracks[i].isActive) {
                activeCount++;
            }
        }

        ResonanceTrack[] memory activeTracks = new ResonanceTrack[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= _trackIdCounter.current(); i++) {
            if (resonanceTracks[i].isActive) {
                activeTracks[currentIndex] = resonanceTracks[i];
                currentIndex++;
            }
        }
        return activeTracks;
    }

    /**
     * @dev Provides detailed information about a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return The Challenge struct containing its details.
     */
    function getChallengeDetails(uint256 _challengeId) public view returns (Challenge memory) {
        require(_challengeId > 0 && _challengeId <= _challengeIdCounter.current(), "EpochalResonance: Invalid challenge ID");
        return challenges[_challengeId];
    }
}
```