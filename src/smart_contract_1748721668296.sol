Okay, here is a Solidity smart contract called `CryptoSculptor` that aims to implement a unique concept involving dynamic, evolving NFT art pieces managed through on-chain parameters, time-based mechanics, and a simplified governance system.

It's designed to be more than just a static NFT; the "sculptures" have internal state that changes based on user interaction ("sculpting"), passage of time ("aging"), and potentially global parameters set by governance. The visual representation would exist off-chain, interpreting the on-chain parameters.

This contract is for demonstration and educational purposes. It integrates multiple concepts but simplifies complex areas like true randomness or full decentralized governance for brevity and focus.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. Imports
// 2. State Variables (Sculpture data, Counters, Fees, Governance, Global Params)
// 3. Structs (Sculpture, Proposal)
// 4. Events (Minting, Sculpting, Aging, Governance, Ownership)
// 5. Modifiers (None specific beyond Ownable)
// 6. ERC-721 Core Functions (Standard overrides and extensions)
// 7. Sculpture State Management (Getting parameters, history)
// 8. Sculpting Actions (Applying changes to sculptures)
// 9. Time-Based Evolution (Incorporating time into state)
// 10. Complexity & Rarity (Calculating scores)
// 11. Governance Proposals (Proposing & voting on global parameters)
// 12. Utility & Owner Functions (Fees, base URI, etc.)
// 13. Internal Helpers

// Function Summary:
// Core ERC721 (Overridden/Included via Imports):
// - constructor: Initializes contract name, symbol, and owner.
// - balanceOf(address owner): Returns the number of tokens owned by `owner`.
// - ownerOf(uint256 tokenId): Returns the owner of the `tokenId`.
// - approve(address to, uint256 tokenId): Approves `to` to manage `tokenId`.
// - getApproved(uint256 tokenId): Returns the approved address for `tokenId`.
// - setApprovalForAll(address operator, bool approved): Sets approval for an operator for all owner's tokens.
// - isApprovedForAll(address owner, address operator): Checks if `operator` is approved for all tokens of `owner`.
// - transferFrom(address from, address to, uint256 tokenId): Transfers `tokenId` from `from` to `to`.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer of `tokenId`.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with data.
// - supportsInterface(bytes4 interfaceId): Standard ERC165 interface detection.
// - name(): Returns the contract name.
// - symbol(): Returns the contract symbol.
// - totalSupply(): Returns the total number of minted tokens. (From Enumerable)
// - tokenByIndex(uint256 index): Returns token ID at an index. (From Enumerable)
// - tokenOfOwnerByIndex(address owner, uint256 index): Returns token ID at an index for owner. (From Enumerable)
// - tokenURI(uint256 tokenId): Returns the metadata URI for `tokenId`. (Overridden for dynamic data)

// Sculpture State & Actions:
// - mintInitialSculpture(address recipient, uint256 initialComplexitySeed, uint256 initialColorSeed): Mints a new sculpture with base parameters, requires mint fee.
// - getSculptureParameters(uint256 tokenId): Retrieves the current on-chain parameters for a sculpture.
// - applySculptAction(uint256 tokenId, uint8 actionType, int256 actionValue): Applies a specific sculpting action, modifying parameters based on action type and value.
// - getSculptureHistorySummary(uint256 tokenId): Provides a summary of sculpting interactions.
// - getLastSculptTimestamp(uint256 tokenId): Returns the timestamp of the last `applySculptAction`.
// - getTotalSculptActions(uint256 tokenId): Returns the total number of times `applySculptAction` has been called on this token.

// Time-Based Evolution:
// - triggerTimeEvolution(uint256 tokenId): Updates sculpture parameters based on time elapsed since last update or minting.
// - getSculptureEvolutionStage(uint256 tokenId): Calculates a 'stage' based on age and interactions.
// - getSculptureCreationTime(uint256 tokenId): Returns the timestamp when the sculpture was minted.

// Complexity & Rarity:
// - calculateComplexityScore(uint256 tokenId): Calculates a complexity score based on the sculpture's current parameters and history.
// - getSculptureRandomnessSeed(uint256 tokenId): Generates a pseudo-random seed based on sculpture data and block info.
// - peekNextEvolutionState(uint256 tokenId, uint256 timeDelta): Simulates the effect of `timeDelta` on parameters without changing state.

// Governance Proposals:
// - proposeSculptParameterInfluence(uint8 paramIndex, int256 agingInfluence, int256 actionInfluence): Creates a proposal to change how aging/actions affect a specific parameter globally.
// - voteOnInfluenceProposal(uint256 proposalId, bool approve): Casts a vote on a governance proposal.
// - getInfluenceProposal(uint256 proposalId): Retrieves details about a specific proposal.
// - executeInfluenceProposal(uint256 proposalId): Owner executes a passed proposal to update global influences.

// Utility & Owner Functions:
// - getMinMintFee(): Returns the current minimum fee required to mint a sculpture.
// - setMinMintFee(uint256 fee): Owner sets the minimum mint fee.
// - setTokenBaseURI(string memory newBaseURI): Owner sets the base URI for metadata.
// - withdrawContractBalance(): Owner withdraws accumulated contract balance (mint fees).
// - getGlobalSculptInfluences(): Returns the current global influence parameters for all sculpture types.
// - isSculptureActive(uint256 tokenId): Checks if a sculpture has been sculpted or aged recently (example of status derived from state).


contract CryptoSculptor is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- State Variables ---

    struct Sculpture {
        // Core Parameters defining the visual/data state
        uint256[] parameters; // Dynamic array for future expansion, e.g., [shape, color, texture, material, light...]

        // History & Timestamps
        uint64 creationTime;
        uint64 lastSculptTime;
        uint32 totalSculptActions;
        uint32 totalTimeEvolutionTriggers; // How many times triggerTimeEvolution was called

        // Potentially add more history like array of action types, but keep small for gas
        // uint8[] historyActionTypes;
    }

    mapping(uint256 => Sculpture) private _sculptures;

    uint256 private _minMintFee;
    string private _baseTokenURI;

    // --- Governance State ---

    // Represents how global aging and sculpting actions influence each parameter type
    // Index corresponds to parameter index in Sculpture.parameters
    struct GlobalParameterInfluence {
        int256 agingInfluencePerSecond; // How much this parameter changes per second if no action
        int256 actionInfluenceMultiplier; // Multiplier for how actionValue affects this parameter
    }
    GlobalParameterInfluence[] public globalSculptInfluences;

    struct Proposal {
        uint256 proposalId;
        uint64 deadline;
        uint8 targetParameterIndex;
        int256 newAgingInfluence;
        int256 newActionInfluenceMultiplier;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // To prevent double voting
        bool executed;
        bool passed; // Determined after deadline
    }

    mapping(uint256 => Proposal) private _proposals;
    Counters.Counter private _proposalIds;
    uint256 public minVotesForProposal; // Minimum votes required for a proposal to be considered 'passed' (simplified)
    uint64 public proposalVotingPeriod; // Duration in seconds for voting

    // Define indices for parameters (for clarity)
    enum ParameterIndices {
        Shape,
        Color,
        Texture,
        Material,
        Complexity // Example parameters
    }

    // --- Events ---

    event SculptureMinted(uint256 indexed tokenId, address indexed owner, uint256[] initialParameters);
    event SculptureParametersChanged(uint256 indexed tokenId, uint8 indexed actionType, int256 actionValue, uint256[] newParameters);
    event SculptureAged(uint256 indexed tokenId, uint256 timeElapsed, uint256[] newParameters);
    event ComplexityScoreUpdated(uint256 indexed tokenId, uint256 newScore); // Maybe emitted on certain actions/aging
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 indexed targetParameterIndex, uint64 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event MinMintFeeUpdated(uint256 oldFee, uint256 newFee);
    event BaseURIUpdated(string newURI);

    // --- Constructor ---

    constructor(string memory name, string memory symbol, uint256 initialMinMintFee, uint256 initialMinVotes, uint64 initialVotingPeriod)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _minMintFee = initialMinMintFee;
        minVotesForProposal = initialMinVotes;
        proposalVotingPeriod = initialVotingPeriod;

        // Initialize global sculpt influences for initial parameters
        globalSculptInfluences.push(GlobalParameterInfluence({ // Shape
            agingInfluencePerSecond: 0,
            actionInfluenceMultiplier: 100 // Actions have direct influence
        }));
         globalSculptInfluences.push(GlobalParameterInfluence({ // Color
            agingInfluencePerSecond: 50, // Color might fade over time
            actionInfluenceMultiplier: 150
        }));
         globalSculptInfluences.push(GlobalParameterInfluence({ // Texture
            agingInfluencePerSecond: -10, // Texture might degrade over time
            actionInfluenceMultiplier: 120
        }));
         globalSculptInfluences.push(GlobalParameterInfluence({ // Material (more stable)
            agingInfluencePerSecond: 0,
            actionInfluenceMultiplier: 80
        }));
         globalSculptInfluences.push(GlobalParameterInfluence({ // Complexity (might increase or decrease)
            agingInfluencePerSecond: 5,
            actionInfluenceMultiplier: 200
        }));
         // Add more default influences if more parameters are added
    }

    // --- ERC-721 Core Functions (Overrides/Included) ---
    // These are mostly handled by OpenZeppelin, but tokenURI is overridden.

    // ERC721URIStorage override
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireOwned(tokenId);
        // The token URI should point to a service that interprets the on-chain parameters
        // and generates metadata and potentially an image URL.
        // Example: "https://cryptosculptor.xyz/metadata/123" where 123 is tokenId
        // The service would call getSculptureParameters(123) to build the metadata.
        if (bytes(_baseTokenURI).length == 0) {
             return super.tokenURI(tokenId); // Fallback or error if base URI not set
        }
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

     // ERC165 support
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    // --- Sculpture State & Actions ---

    /**
     * @notice Mints a new CryptoSculptor NFT.
     * @param recipient The address to receive the new sculpture.
     * @param initialComplexitySeed A seed used to help determine initial complexity.
     * @param initialColorSeed A seed used to help determine initial color.
     * @dev Requires sending at least `minMintFee` with the transaction.
     */
    function mintInitialSculpture(address recipient, uint256 initialComplexitySeed, uint256 initialColorSeed) external payable {
        require(msg.value >= _minMintFee, "CryptoSculptor: Insufficient mint fee");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // Deterministically generate initial parameters based on seeds and block data
        uint256 blockSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newItemId)));

        // Simple initial parameter generation (can be made more complex)
        uint256[] memory initialParams = new uint256[](globalSculptInfluences.length);
        initialParams[uint8(ParameterIndices.Shape)] = (blockSeed ^ initialComplexitySeed) % 1000; // Example range
        initialParams[uint8(ParameterIndices.Color)] = (blockSeed ^ initialColorSeed) % 16777216; // Example RGB range
        initialParams[uint8(ParameterIndices.Texture)] = (blockSeed * initialColorSeed) % 255; // Example range
        initialParams[uint8(ParameterIndices.Material)] = (blockSeed / (initialComplexitySeed + 1)) % 10; // Example range
        initialParams[uint8(ParameterIndices.Complexity)] = (initialComplexitySeed + initialColorSeed + (blockSeed % 100)) % 500; // Example range

        _sculptures[newItemId] = Sculpture({
            parameters: initialParams,
            creationTime: uint64(block.timestamp),
            lastSculptTime: uint64(block.timestamp),
            totalSculptActions: 0,
            totalTimeEvolutionTriggers: 0
        });

        _safeMint(recipient, newItemId);

        emit SculptureMinted(newItemId, recipient, initialParams);
    }

    /**
     * @notice Retrieves the current parameters of a sculpture.
     * @param tokenId The ID of the sculpture.
     * @return An array of uint256 representing the sculpture's parameters.
     */
    function getSculptureParameters(uint256 tokenId) public view returns (uint256[] memory) {
        _requireMinted(tokenId);
        return _sculptures[tokenId].parameters;
    }

    /**
     * @notice Applies a sculpting action to a sculpture, modifying its parameters.
     * @param tokenId The ID of the sculpture to sculpt.
     * @param actionType The index of the parameter to influence (e.g., 0 for Shape, 1 for Color).
     * @param actionValue The value representing the intensity or direction of the sculpting action.
     * @dev Only the owner or an approved address can sculpt. Requires `actionType` to be a valid parameter index.
     */
    function applySculptAction(uint256 tokenId, uint8 actionType, int256 actionValue) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "CryptoSculptor: Not approved or owner");
        require(actionType < globalSculptInfluences.length, "CryptoSculptor: Invalid action type (parameter index)");

        Sculpture storage sculpture = _sculptures[tokenId];

        // Apply time evolution first before sculpting to ensure state is up-to-date
        _triggerTimeEvolutionInternal(tokenId); // Internal call

        // Calculate the parameter change based on actionValue and global influence
        int256 parameterChange = (actionValue * globalSculptInfluences[actionType].actionInfluenceMultiplier) / 100; // Divide by 100 for percentage-like multiplier

        // Apply the change, ensuring parameters don't go negative (assuming uint256 represents non-negative aspects)
        // Note: If parameters could represent signed values, this logic would need adjustment.
        // Here, we treat uint256 as a value that shouldn't drop below 0.
        if (parameterChange < 0) {
            // Prevent underflow if parameterChange is negative
            if (uint256(-parameterChange) > sculpture.parameters[actionType]) {
                sculpture.parameters[actionType] = 0;
            } else {
                 sculpture.parameters[actionType] = sculpture.parameters[actionType] - uint256(-parameterChange);
            }
        } else {
            sculpture.parameters[actionType] = sculpture.parameters[actionType] + uint256(parameterChange);
        }

        sculpture.lastSculptTime = uint64(block.timestamp);
        sculpture.totalSculptActions++;

        emit SculptureParametersChanged(tokenId, actionType, actionValue, sculpture.parameters);
    }

     /**
     * @notice Gets a summary of sculpting history for a token.
     * @param tokenId The ID of the sculpture.
     * @return lastSculptTimestamp Timestamp of the most recent sculpt action.
     * @return totalSculptActionsCount Total number of sculpt actions applied.
     */
    function getSculptureHistorySummary(uint256 tokenId) public view returns (uint64 lastSculptTimestamp, uint32 totalSculptActionsCount) {
        _requireMinted(tokenId);
        Sculpture storage sculpture = _sculptures[tokenId];
        return (sculpture.lastSculptTime, sculpture.totalSculptActions);
    }

     /**
     * @notice Returns the timestamp of the last time applySculptAction was called.
     * @param tokenId The ID of the sculpture.
     * @return Timestamp of the last sculpt action.
     */
    function getLastSculptTimestamp(uint256 tokenId) public view returns (uint64) {
        _requireMinted(tokenId);
        return _sculptures[tokenId].lastSculptTime;
    }

     /**
     * @notice Returns the total count of applySculptAction calls on the token.
     * @param tokenId The ID of the sculpture.
     * @return Total sculpt actions count.
     */
    function getTotalSculptActions(uint256 tokenId) public view returns (uint32) {
        _requireMinted(tokenId);
        return _sculptures[tokenId].totalSculptActions;
    }


    // --- Time-Based Evolution ---

    /**
     * @notice Triggers the 'aging' process for a sculpture based on elapsed time.
     * @param tokenId The ID of the sculpture to age.
     * @dev Can be called by anyone to push the state forward, but changes based on time since last update.
     */
    function triggerTimeEvolution(uint256 tokenId) external {
        _requireMinted(tokenId);
        _triggerTimeEvolutionInternal(tokenId); // Use internal helper
    }

     /**
     * @notice Internal helper to apply time-based evolution logic.
     * @param tokenId The ID of the sculpture.
     * @dev Calculates time elapsed and applies aging influence to parameters.
     */
    function _triggerTimeEvolutionInternal(uint256 tokenId) internal {
        Sculpture storage sculpture = _sculptures[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - sculpture.lastSculptTime; // Time since last action/aging

        if (timeElapsed == 0) {
            return; // No time elapsed, no aging
        }

        // Apply aging influence to each parameter
        for (uint i = 0; i < sculpture.parameters.length; i++) {
            if (i < globalSculptInfluences.length) { // Ensure influence exists for this parameter
                 int256 agingChange = (int256(timeElapsed) * globalSculptInfluences[i].agingInfluencePerSecond) / 1 seconds; // Scale by seconds if needed, or just use timeElapsed directly

                 if (agingChange < 0) {
                     // Prevent underflow
                    if (uint256(-agingChange) > sculpture.parameters[i]) {
                        sculpture.parameters[i] = 0;
                    } else {
                        sculpture.parameters[i] = sculpture.parameters[i] - uint256(-agingChange);
                    }
                 } else {
                     sculpture.parameters[i] = sculpture.parameters[i] + uint256(agingChange);
                 }
            }
        }

        sculpture.lastSculptTime = currentTime; // Update last update time
        sculpture.totalTimeEvolutionTriggers++;

        emit SculptureAged(tokenId, timeElapsed, sculpture.parameters);
    }


    /**
     * @notice Calculates an evolution stage based on age and interactions.
     * @param tokenId The ID of the sculpture.
     * @return A uint8 representing the evolution stage (e.g., 0=New, 1=Developing, 2=Mature, 3=Ancient).
     * @dev This is a view function that derives stage; state is not stored.
     */
    function getSculptureEvolutionStage(uint256 tokenId) public view returns (uint8) {
         _requireMinted(tokenId);
        Sculpture storage sculpture = _sculptures[tokenId];
        uint64 age = uint64(block.timestamp) - sculpture.creationTime;

        // Simple stage logic based on age and total sculpt actions
        if (sculpture.totalSculptActions == 0 && age < 1 days) return 0; // New & Untouched
        if (age < 7 days && sculpture.totalSculptActions < 5) return 1; // Developing
        if (age >= 7 days && age < 30 days && sculpture.totalSculptActions >= 5) return 2; // Mature
        if (age >= 30 days || sculpture.totalSculptActions >= 20) return 3; // Ancient/Complex
        return 0; // Default/Other
    }

    /**
     * @notice Returns the timestamp when the sculpture was minted.
     * @param tokenId The ID of the sculpture.
     * @return Creation timestamp.
     */
     function getSculptureCreationTime(uint256 tokenId) public view returns (uint64) {
         _requireMinted(tokenId);
         return _sculptures[tokenId].creationTime;
     }

    // --- Complexity & Rarity ---

    /**
     * @notice Calculates a complexity score for a sculpture based on its current parameters and history.
     * @param tokenId The ID of the sculpture.
     * @return A uint256 representing the calculated complexity score.
     * @dev The complexity logic is arbitrary and can be customized.
     */
    function calculateComplexityScore(uint256 tokenId) public view returns (uint256) {
         _requireMinted(tokenId);
        Sculpture storage sculpture = _sculptures[tokenId];
        uint256 score = 0;

        // Simple example score calculation
        for (uint i = 0; i < sculpture.parameters.length; i++) {
            score += sculpture.parameters[i]; // Sum of parameters
        }

        score += sculpture.totalSculptActions * 100; // Actions add complexity
        score += sculpture.totalTimeEvolutionTriggers * 50; // Aging adds complexity

        // Add some variance based on creation time or other factors
        score += (sculpture.creationTime % 100);

        return score;
    }

     /**
     * @notice Generates a pseudo-random seed based on the sculpture's state and recent block data.
     * @param tokenId The ID of the sculpture.
     * @return A uint256 pseudo-random seed.
     * @dev WARNING: This is NOT cryptographically secure randomness suitable for high-value decisions.
     * Block data is predictable. Use only for non-critical features like visual variation.
     */
    function getSculptureRandomnessSeed(uint256 tokenId) public view returns (uint256) {
         _requireMinted(tokenId);
        Sculpture storage sculpture = _sculptures[tokenId];

        // Combine unique sculpture data with block data for a seed
        uint256 seed = uint256(keccak256(abi.encodePacked(
            sculpture.parameters,
            sculpture.creationTime,
            sculpture.lastSculptTime,
            sculpture.totalSculptActions,
            block.timestamp,
            block.number,
            tx.origin, // Or msg.sender depending on use case
            tokenId
        )));

        return seed;
    }

     /**
     * @notice Simulates the effect of time evolution on parameters without changing state.
     * @param tokenId The ID of the sculpture.
     * @param timeDelta The amount of time (in seconds) to simulate aging for.
     * @return An array of uint256 representing the predicted parameters after timeDelta.
     * @dev Useful for off-chain previews.
     */
    function peekNextEvolutionState(uint256 tokenId, uint256 timeDelta) public view returns (uint256[] memory) {
        _requireMinted(tokenId);
        Sculpture storage sculpture = _sculptures[tokenId];
        uint256[] memory predictedParams = new uint256[](sculpture.parameters.length);

        for (uint i = 0; i < sculpture.parameters.length; i++) {
             predictedParams[i] = sculpture.parameters[i]; // Start with current value
             if (i < globalSculptInfluences.length) {
                 int256 agingChange = (int256(timeDelta) * globalSculptInfluences[i].agingInfluencePerSecond) / 1 seconds;

                  if (agingChange < 0) {
                     if (uint256(-agingChange) > predictedParams[i]) {
                        predictedParams[i] = 0;
                    } else {
                        predictedParams[i] = predictedParams[i] - uint256(-agingChange);
                    }
                 } else {
                     predictedParams[i] = predictedParams[i] + uint256(agingChange);
                 }
             }
        }
        return predictedParams;
    }


    // --- Governance Proposals ---

    /**
     * @notice Proposes changing the global aging and action influence for a specific parameter type.
     * @param paramIndex The index of the parameter (e.g., 0 for Shape).
     * @param agingInfluence The new aging influence per second for this parameter.
     * @param actionInfluenceMultiplier The new action influence multiplier for this parameter.
     * @dev Anyone can create a proposal, but they must be voted on.
     */
    function proposeSculptParameterInfluence(uint8 paramIndex, int256 agingInfluence, int256 actionInfluenceMultiplier) external {
        require(paramIndex < globalSculptInfluences.length, "CryptoSculptor: Invalid parameter index for proposal");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        uint64 deadline = uint64(block.timestamp) + proposalVotingPeriod;

        _proposals[proposalId] = Proposal({
            proposalId: proposalId,
            deadline: deadline,
            targetParameterIndex: paramIndex,
            newAgingInfluence: agingInfluence,
            newActionInfluenceMultiplier: actionInfluenceMultiplier,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            passed: false
        });

        emit ProposalCreated(proposalId, msg.sender, paramIndex, deadline);
    }

    /**
     * @notice Casts a vote on a governance proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes', False for 'no'.
     * @dev Requires the voter to own at least one sculpture to vote (simple voting power).
     */
    function voteOnInfluenceProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.deadline > 0, "CryptoSculptor: Proposal does not exist");
        require(block.timestamp < proposal.deadline, "CryptoSculptor: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "CryptoSculptor: Already voted on this proposal");
        // Simple voting power: must own at least one token
        require(balanceOf(msg.sender) > 0, "CryptoSculptor: Must own a sculpture to vote");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Retrieves details about a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return Struct containing proposal details.
     */
    function getInfluenceProposal(uint256 proposalId) public view returns (Proposal memory) {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.deadline > 0, "CryptoSculptor: Proposal does not exist");
        // Return a memory copy, not storage pointer
        return Proposal({
             proposalId: proposal.proposalId,
             deadline: proposal.deadline,
             targetParameterIndex: proposal.targetParameterIndex,
             newAgingInfluence: proposal.newAgingInfluence,
             newActionInfluenceMultiplier: proposal.newActionInfluenceMultiplier,
             votesFor: proposal.votesFor,
             votesAgainst: proposal.votesAgainst,
             hasVoted: new mapping(address => bool), // Cannot return mappings directly
             executed: proposal.executed,
             passed: proposal.passed
        });
    }

    /**
     * @notice Owner executes a governance proposal after its voting period has ended.
     * @param proposalId The ID of the proposal to execute.
     * @dev Can only be called by the contract owner. Checks if proposal passed the vote threshold.
     */
    function executeInfluenceProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.deadline > 0, "CryptoSculptor: Proposal does not exist");
        require(block.timestamp >= proposal.deadline, "CryptoSculptor: Voting period is not over");
        require(!proposal.executed, "CryptoSculptor: Proposal already executed");
        require(proposal.targetParameterIndex < globalSculptInfluences.length, "CryptoSculptor: Invalid parameter index in proposal");


        // Determine if the proposal passed
        bool passed = (proposal.votesFor >= minVotesForProposal) && (proposal.votesFor > proposal.votesAgainst);
        proposal.passed = passed; // Record the outcome

        if (passed) {
            // Apply the proposed changes to global influences
            globalSculptInfluences[proposal.targetParameterIndex].agingInfluencePerSecond = proposal.newAgingInfluence;
            globalSculptInfluences[proposal.targetParameterIndex].actionInfluenceMultiplier = proposal.newActionInfluenceMultiplier;
        }

        proposal.executed = true; // Mark as executed regardless of outcome

        emit ProposalExecuted(proposalId, passed);
    }


    // --- Utility & Owner Functions ---

    /**
     * @notice Gets the current minimum fee required to mint a sculpture.
     */
    function getMinMintFee() public view returns (uint256) {
        return _minMintFee;
    }

    /**
     * @notice Allows the owner to set a new minimum mint fee.
     * @param fee The new minimum fee in wei.
     */
    function setMinMintFee(uint256 fee) external onlyOwner {
        uint256 oldFee = _minMintFee;
        _minMintFee = fee;
        emit MinMintFeeUpdated(oldFee, fee);
    }

    /**
     * @notice Allows the owner to set the base URI for token metadata.
     * @param newBaseURI The new base URI string.
     * @dev This URI should typically end with a slash '/' and the tokenURI function will append the tokenId.
     */
    function setTokenBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @notice Allows the owner to withdraw the contract's balance (accumulated mint fees).
     * @dev Transfers the entire contract balance to the owner.
     */
    function withdrawContractBalance() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "CryptoSculptor: Withdrawal failed");
    }

     /**
     * @notice Returns the current global influence parameters for all sculpture types.
     * @dev Useful for off-chain services to understand how sculptures are affected globally.
     */
    function getGlobalSculptInfluences() public view returns (GlobalParameterInfluence[] memory) {
        return globalSculptInfluences;
    }

     /**
     * @notice Checks if a sculpture has been recently sculpted or aged.
     * @param tokenId The ID of the sculpture.
     * @return True if active (e.g., active in last 7 days), False otherwise.
     * @dev Example of deriving a status from internal state. Threshold is arbitrary.
     */
    function isSculptureActive(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        Sculpture storage sculpture = _sculptures[tokenId];
        uint64 lastActivity = sculpture.lastSculptTime;
        uint64 currentTime = uint64(block.timestamp);
        return (currentTime - lastActivity < 7 days); // Active if sculpted/aged in last 7 days
    }


    // --- Internal Helpers ---

    /**
     * @dev Helper function to check if a token ID has been minted.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "CryptoSculptor: ERC721 token not minted");
    }

    // The rest of the internal functions (_beforeTokenTransfer, _afterTokenTransfer, etc.)
    // are handled by OpenZeppelin's ERC721 implementation and its extensions.
    // We don't need to explicitly list or implement them unless we need custom logic there.
}
```

---

**Explanation of Concepts and Features:**

1.  **Dynamic NFTs (On-Chain Parameters):** Instead of just storing a static URI, each `Sculpture` token has a `parameters` array stored directly in the contract state. These parameters represent different aspects (shape, color, texture, etc.) of the digital art piece. An off-chain service (website, renderer) reads these on-chain parameters via `getSculptureParameters` and `tokenURI` to generate the corresponding image/metadata. This makes the art piece truly dynamic and bound to the contract's state.

2.  **Sculpting Actions (`applySculptAction`):** Users (owners or approved addresses) can interact with their NFTs by calling `applySculptAction`. This function takes an `actionType` (mapping to a parameter index) and an `actionValue`, modifying the sculpture's internal parameters based on defined `globalSculptInfluences`. This introduces interactive gameplay/modification mechanics.

3.  **Time-Based Evolution (`triggerTimeEvolution`):** Sculptures "age". The `triggerTimeEvolution` function (callable by anyone to push the state forward) calculates the time elapsed since the last interaction (`lastSculptTime`) and applies time-based changes to the parameters based on the `globalSculptInfluences`. This means even inactive sculptures can change over time, potentially degrading or gaining unique characteristics.

4.  **Complexity Scoring (`calculateComplexityScore`):** A function calculates a score based on the current state of the parameters and the history (number of actions, aging triggers). This could be used off-chain for rarity ranking or display.

5.  **Pseudo-Randomness (`getSculptureRandomnessSeed`):** Provides a way to derive a seed from the sculpture's unique data and recent block information. *Crucially, this is noted as insecure for financial outcomes* but useful for introducing visual variance or non-critical in-game effects based on token state.

6.  **Simple Governance (`proposeSculptParameterInfluence`, `voteOnInfluenceProposal`, `executeInfluenceProposal`):** A basic system where users (who own tokens) can propose changes to the *global* influence parameters (how aging and actions affect *all* sculpture types). Token holders can vote, and the contract owner can execute a proposal if it meets a minimum vote threshold within a voting period. This adds a layer of community influence over the game/art's mechanics.

7.  **Peek into Future State (`peekNextEvolutionState`):** A view function allowing users to simulate the effect of aging over a specified time delta *without* modifying the on-chain state. Useful for previews.

8.  **ERC-721 Extensions:** Inherits from `ERC721Enumerable` (for discovering all tokens) and `ERC721URIStorage` (allowing modification of the token URI, useful for dynamic updates).

9.  **Owner-Controlled Utility:** Includes standard owner functions for setting mint fees, base URI, and withdrawing funds, common in initial phases of a project.

10. **Minimum 20 Functions:** The contract includes standard ERC-721 functions (many inherited/overridden) plus the custom functions totaling well over the required 20 unique functions interacting with the sculpture state, time, complexity, and governance.

This contract demonstrates how to build complex, dynamic NFTs with internal state, interactive mechanics, and evolving characteristics driven by on-chain logic and user/community actions, going beyond simple static digital collectibles.