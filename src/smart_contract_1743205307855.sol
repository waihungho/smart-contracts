```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Evolution Contract - "Evolving Glyphs"
 * @author Bard (Example Contract - Not for Production)
 *
 * @dev This contract implements a dynamic NFT system where NFTs can evolve through various stages based on different on-chain and potentially off-chain triggers.
 * It introduces concepts of NFT evolution, rarity tiers, skill trees, community influence, and dynamic metadata updates.
 *
 * **Contract Outline:**
 *
 * 1. **NFT Core Functionality (ERC721 Base):** Standard NFT functionalities like minting, transferring, ownership, approvals, and metadata handling.
 * 2. **Evolution System:**
 *    - Stages of Evolution: NFTs progress through defined stages (e.g., Stage 1, Stage 2, Stage 3...).
 *    - Evolution Triggers: Multiple mechanisms to trigger evolution:
 *      - Time-based evolution.
 *      - Staking/Interaction-based evolution.
 *      - Community Vote/Influence-based evolution.
 *      - Skill-based evolution (achieving certain on-chain actions).
 * 3. **Rarity Tiers:** NFTs can have different rarity tiers that influence their evolution paths and potential.
 * 4. **Skill Trees:**  NFTs can unlock skills or attributes as they evolve, creating a progression system.
 * 5. **Dynamic Metadata:** NFT metadata (name, description, image URI) changes dynamically based on evolution stage, rarity, and skills.
 * 6. **Community Influence:** Allow community to vote on certain evolution paths or features.
 * 7. **Oracle Integration (Conceptual):**  Outline how external data feeds could potentially influence evolution (e.g., in-game achievements, real-world events - not implemented for simplicity but concept included).
 * 8. **Burning Mechanism:** Allow burning of NFTs, potentially for resource generation or other in-game mechanics.
 * 9. **Customizable Evolution Rules:** Admin functions to define and adjust evolution parameters.
 * 10. **Event Emission:**  Emit detailed events for all significant actions (minting, evolution, skill unlock, etc.).
 * 11. **Pausing Mechanism:**  Admin function to pause contract functionalities for emergency or maintenance.
 * 12. **Withdrawal Mechanism:**  Admin function to withdraw contract balance (if any fees are collected).
 * 13. **Rarity Management:** Admin functions to manage rarity tiers and their properties.
 * 14. **Skill Management:** Admin functions to manage skill trees and skill effects.
 * 15. **Community Vote Functions:** Functions for community voting on evolution paths or features.
 * 16. **Metadata Update Function:** Function to manually refresh metadata URI (in case of off-chain storage updates).
 * 17. **Token Gating (Conceptual):**  Outline potential for token-gated access to features based on NFT evolution stage or skills.
 * 18. **Batch Minting:**  Function to mint multiple NFTs in a single transaction (admin or potentially whitelisted users).
 * 19. **Attribute Retrieval:**  Functions to easily retrieve NFT attributes (stage, rarity, skills) on-chain.
 * 20. **Royalties (ERC2981 Support - Conceptual):**  Outline potential for integrating royalty standards (not implemented for simplicity).
 *
 * **Function Summary:**
 *
 * **Core NFT Functions:**
 * - `mint(address to, uint256 rarityTier)`: Mints a new NFT with a specified rarity tier.
 * - `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an NFT.
 * - `approve(address approved, uint256 tokenId)`: Approves another address to transfer an NFT.
 * - `getApproved(uint256 tokenId)`: Gets the approved address for an NFT.
 * - `setApprovalForAll(address operator, bool approved)`: Sets approval for all NFTs for an operator.
 * - `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all NFTs of an owner.
 * - `ownerOf(uint256 tokenId)`: Gets the owner of an NFT.
 * - `balanceOf(address owner)`: Gets the balance of NFTs for an owner.
 * - `tokenURI(uint256 tokenId)`: Returns the metadata URI for an NFT.
 * - `supportsInterface(bytes4 interfaceId)`: Checks if the contract supports a given interface.
 * - `totalSupply()`: Returns the total number of NFTs minted.
 *
 * **Evolution & Rarity Functions:**
 * - `getEvolutionStage(uint256 tokenId)`: Returns the current evolution stage of an NFT.
 * - `getEvolutionTimeRemaining(uint256 tokenId)`: Returns the time remaining until the next automatic evolution (if applicable).
 * - `manualEvolve(uint256 tokenId)`: Allows manual evolution of an NFT (potentially with conditions).
 * - `getRarityTier(uint256 tokenId)`: Returns the rarity tier of an NFT.
 * - `setEvolutionStages(string[] memory _stages)`: Admin function to set the names of evolution stages.
 * - `setEvolutionTimers(uint256[] memory _timers)`: Admin function to set the time intervals for automatic evolution.
 * - `defineRarityTier(uint256 tierId, string memory tierName, uint256 evolutionBoost)`: Admin function to define a rarity tier.
 * - `getRarityTierDetails(uint256 tierId)`: Admin function to get details of a rarity tier.
 *
 * **Skill Tree Functions:**
 * - `unlockSkill(uint256 tokenId, uint256 skillId)`: Unlocks a skill for an NFT (triggered by evolution or other conditions).
 * - `getUnlockedSkills(uint256 tokenId)`: Returns the list of unlocked skills for an NFT.
 * - `defineSkill(uint256 skillId, string memory skillName, string memory skillDescription)`: Admin function to define a skill.
 * - `getSkillDetails(uint256 skillId)`: Admin function to get details of a skill.
 *
 * **Community & Admin Functions:**
 * - `startCommunityVote(string memory proposalDescription, string[] memory options)`: Admin function to start a community vote.
 * - `vote(uint256 voteId, uint256 optionIndex)`: Function for NFT holders to vote in a community poll.
 * - `endCommunityVote(uint256 voteId)`: Admin function to end a community vote and apply the result.
 * - `pauseContract()`: Admin function to pause the contract.
 * - `unpauseContract()`: Admin function to unpause the contract.
 * - `withdraw()`: Admin function to withdraw contract balance.
 * - `setBaseURI(string memory _baseURI)`: Admin function to set the base URI for metadata.
 * - `refreshMetadata(uint256 tokenId)`: Function to refresh metadata URI for a specific token.
 * - `burn(uint256 tokenId)`: Allows burning of an NFT by its owner.
 * - `batchMint(address[] memory recipients, uint256[] memory rarityTiers)`: Admin function for batch minting NFTs.
 * - `getAttribute(uint256 tokenId, string memory attributeName)`:  Function to retrieve a specific attribute for an NFT.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EvolvingGlyphs is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    // -------- State Variables --------

    string public baseURI; // Base URI for metadata
    string[] public evolutionStages; // Names of evolution stages (e.g., ["Egg", "Hatchling", "Juvenile", "Adult"])
    uint256[] public evolutionTimers; // Time intervals (in seconds) between automatic evolution stages
    mapping(uint256 => uint256) public tokenStage; // Token ID => Current Evolution Stage Index
    mapping(uint256 => uint256) public lastEvolutionTime; // Token ID => Last Evolution Timestamp
    mapping(uint256 => uint256) public rarityTier; // Token ID => Rarity Tier ID
    mapping(uint256 => string) public tokenAttributes; // Token ID => JSON string of attributes (expandable)
    mapping(uint256 => uint256[]) public unlockedSkills; // Token ID => Array of Skill IDs
    mapping(uint256 => RarityTier) public rarityTiers; // Rarity Tier ID => Rarity Tier Details
    mapping(uint256 => Skill) public skills; // Skill ID => Skill Details
    Counters.Counter private _rarityTierCounter;
    Counters.Counter private _skillCounter;
    bool public paused; // Contract Pausing Mechanism

    struct RarityTier {
        string name;
        uint256 evolutionBoost; // Example: Higher tiers evolve faster or have better attributes
    }

    struct Skill {
        string name;
        string description;
    }

    struct CommunityVote {
        string proposalDescription;
        string[] options;
        mapping(address => uint256) votes; // Voter address => Option Index
        uint256 voteEndTime;
        bool isActive;
        uint256 winningOption;
    }
    mapping(uint256 => CommunityVote) public communityVotes;
    Counters.Counter private _voteCounter;


    // -------- Events --------

    event GlyphMinted(uint256 tokenId, address recipient, uint256 rarityTier);
    event GlyphEvolved(uint256 tokenId, uint256 fromStage, uint256 toStage);
    event SkillUnlocked(uint256 tokenId, uint256 skillId);
    event MetadataRefreshed(uint256 tokenId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event CommunityVoteStarted(uint256 voteId, string proposalDescription);
    event CommunityVoteCasted(uint256 voteId, address voter, uint256 optionIndex);
    event CommunityVoteEnded(uint256 voteId, uint256 winningOption);

    // -------- Modifiers --------

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function");
        _;
    }

    // -------- Constructor --------

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        paused = false; // Contract starts unpaused
        // Initialize default evolution stages and timers (example)
        evolutionStages = ["Egg", "Hatchling", "Juvenile", "Adult", "Elder"];
        evolutionTimers = [86400, 172800, 259200, 345600]; // 1 day, 2 days, 3 days, 4 days in seconds (example)
    }

    // -------- Core NFT Functions --------

    /**
     * @dev Mints a new NFT with a specified rarity tier.
     * @param to The address to mint the NFT to.
     * @param _rarityTier The rarity tier of the new NFT.
     */
    function mint(address to, uint256 _rarityTier) public onlyAdmin whenNotPaused returns (uint256) {
        require(_rarityTier > 0 && _rarityTier <= _rarityTierCounter.current(), "Invalid rarity tier");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(to, newTokenId);
        rarityTier[newTokenId] = _rarityTier;
        tokenStage[newTokenId] = 0; // Initial stage (Egg)
        lastEvolutionTime[newTokenId] = block.timestamp;
        emit GlyphMinted(newTokenId, to, _rarityTier);
        return newTokenId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory stageName = evolutionStages[tokenStage[tokenId]];
        string memory rarityName = rarityTiers[rarityTier[tokenId]].name;

        // Example dynamic metadata generation - customize as needed
        string memory metadata = string(abi.encodePacked(
            '{',
            '"name": "', name(), " #", tokenId.toString(), ' - Stage ', stageName, ' - Rarity: ', rarityName, '",',
            '"description": "An Evolving Glyph. Currently at Stage ', stageName, ' and Rarity Tier ', rarityName, '. Evolve to unlock more potential.",',
            '"image": "', baseURI, "/", tokenId.toString(), '.png",', // Example image path - adjust as needed
            '"attributes": [',
                '{"trait_type": "Stage", "value": "', stageName, '"},',
                '{"trait_type": "Rarity", "value": "', rarityName, '"},',
                '{"trait_type": "Evolution Stage", "value": "', tokenStage[tokenId].toString(), '"},',
                '{"trait_type": "Rarity Tier", "value": "', rarityTier[tokenId].toString(), '"}' ,
            ']',
            '}'
        ));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(metadata))));
    }

    /**
     * @dev Refreshes the metadata URI for a specific token.
     * Useful if off-chain metadata storage is updated.
     * @param tokenId The ID of the token to refresh metadata for.
     */
    function refreshMetadata(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        _setTokenURI(tokenId, tokenURI(tokenId));
        emit MetadataRefreshed(tokenId);
    }


    // -------- Evolution & Rarity Functions --------

    /**
     * @dev Returns the current evolution stage index of an NFT.
     * @param tokenId The ID of the token.
     * @return The evolution stage index (0-based).
     */
    function getEvolutionStage(uint256 tokenId) public view whenNotPaused returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenStage[tokenId];
    }

    /**
     * @dev Returns the time remaining until the next automatic evolution (if applicable).
     * @param tokenId The ID of the token.
     * @return The time remaining in seconds, or 0 if no automatic evolution is pending.
     */
    function getEvolutionTimeRemaining(uint256 tokenId) public view whenNotPaused returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        uint256 currentStage = tokenStage[tokenId];
        if (currentStage >= evolutionStages.length - 1) {
            return 0; // Already at max stage
        }
        uint256 nextEvolutionTime = lastEvolutionTime[tokenId] + evolutionTimers[currentStage] * rarityTiers[rarityTier[tokenId]].evolutionBoost / 100 ; // Rarity boost example
        if (block.timestamp < nextEvolutionTime) {
            return nextEvolutionTime - block.timestamp;
        }
        return 0; // Time elapsed, ready to evolve
    }

    /**
     * @dev Allows manual evolution of an NFT if conditions are met (e.g., time elapsed).
     * @param tokenId The ID of the token to evolve.
     */
    function manualEvolve(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(msg.sender == ownerOf(tokenId), "Not token owner");

        uint256 currentStage = tokenStage[tokenId];
        require(currentStage < evolutionStages.length - 1, "Token is already at max stage");

        uint256 nextEvolutionTime = lastEvolutionTime[tokenId] + evolutionTimers[currentStage] * rarityTiers[rarityTier[tokenId]].evolutionBoost / 100;
        require(block.timestamp >= nextEvolutionTime, "Evolution time not yet reached");

        _evolveToken(tokenId);
    }

    /**
     * @dev Internal function to handle token evolution logic.
     * @param tokenId The ID of the token to evolve.
     */
    function _evolveToken(uint256 tokenId) internal {
        uint256 currentStage = tokenStage[tokenId];
        uint256 nextStage = currentStage + 1;

        emit GlyphEvolved(tokenId, currentStage, nextStage);
        tokenStage[tokenId] = nextStage;
        lastEvolutionTime[tokenId] = block.timestamp;

        // Example: Unlock a skill upon evolution
        if (nextStage == 2) { // Example: Unlock skill at Stage 2
            unlockSkill(tokenId, 1); // Skill ID 1
        }
        refreshMetadata(tokenId); // Update metadata after evolution
    }

    /**
     * @dev Admin function to set the names of evolution stages.
     * @param _stages An array of strings representing evolution stage names.
     */
    function setEvolutionStages(string[] memory _stages) public onlyAdmin {
        require(_stages.length > 0, "Stages array cannot be empty");
        evolutionStages = _stages;
    }

    /**
     * @dev Admin function to set the time intervals for automatic evolution stages.
     * @param _timers An array of uint256 representing time intervals in seconds.
     */
    function setEvolutionTimers(uint256[] memory _timers) public onlyAdmin {
        require(_timers.length == evolutionStages.length - 1, "Timers array length must be one less than stages array length");
        evolutionTimers = _timers;
    }

    /**
     * @dev Admin function to define a rarity tier.
     * @param tierId The ID of the rarity tier.
     * @param tierName The name of the rarity tier.
     * @param evolutionBoost A percentage boost to evolution speed (e.g., 100 = no boost, 50 = 50% faster evolution).
     */
    function defineRarityTier(uint256 tierId, string memory tierName, uint256 evolutionBoost) public onlyAdmin {
        rarityTiers[tierId] = RarityTier({name: tierName, evolutionBoost: evolutionBoost});
        if (tierId > _rarityTierCounter.current()) {
            _rarityTierCounter.increment();
        }
    }

    /**
     * @dev Admin function to get details of a rarity tier.
     * @param tierId The ID of the rarity tier.
     * @return RarityTier struct containing tier details.
     */
    function getRarityTierDetails(uint256 tierId) public view onlyAdmin returns (RarityTier memory) {
        return rarityTiers[tierId];
    }

    /**
     * @dev Returns the rarity tier ID of an NFT.
     * @param tokenId The ID of the token.
     * @return The rarity tier ID.
     */
    function getRarityTier(uint256 tokenId) public view whenNotPaused returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return rarityTier[tokenId];
    }


    // -------- Skill Tree Functions --------

    /**
     * @dev Unlocks a skill for an NFT.
     * @param tokenId The ID of the token.
     * @param skillId The ID of the skill to unlock.
     */
    function unlockSkill(uint256 tokenId, uint256 skillId) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(skills[skillId].name.length > 0, "Skill does not exist"); // Skill must be defined
        bool alreadyUnlocked = false;
        for (uint256 i = 0; i < unlockedSkills[tokenId].length; i++) {
            if (unlockedSkills[tokenId][i] == skillId) {
                alreadyUnlocked = true;
                break;
            }
        }
        require(!alreadyUnlocked, "Skill already unlocked");

        unlockedSkills[tokenId].push(skillId);
        emit SkillUnlocked(tokenId, skillId);
        refreshMetadata(tokenId); // Update metadata to reflect skill unlock
    }

    /**
     * @dev Returns the list of unlocked skill IDs for an NFT.
     * @param tokenId The ID of the token.
     * @return An array of skill IDs.
     */
    function getUnlockedSkills(uint256 tokenId) public view whenNotPaused returns (uint256[] memory) {
        require(_exists(tokenId), "Token does not exist");
        return unlockedSkills[tokenId];
    }

    /**
     * @dev Admin function to define a skill.
     * @param skillId The ID of the skill.
     * @param skillName The name of the skill.
     * @param skillDescription A description of the skill.
     */
    function defineSkill(uint256 skillId, string memory skillName, string memory skillDescription) public onlyAdmin {
        skills[skillId] = Skill({name: skillName, description: skillDescription});
        if (skillId > _skillCounter.current()) {
            _skillCounter.increment();
        }
    }

    /**
     * @dev Admin function to get details of a skill.
     * @param skillId The ID of the skill.
     * @return Skill struct containing skill details.
     */
    function getSkillDetails(uint256 skillId) public view onlyAdmin returns (Skill memory) {
        return skills[skillId];
    }


    // -------- Community & Admin Functions --------

    /**
     * @dev Admin function to start a community vote.
     * @param proposalDescription Description of the proposal being voted on.
     * @param options Array of voting options (strings).
     */
    function startCommunityVote(string memory proposalDescription, string[] memory options) public onlyAdmin whenNotPaused {
        _voteCounter.increment();
        uint256 voteId = _voteCounter.current();
        require(options.length > 1, "Must provide at least two options");
        communityVotes[voteId] = CommunityVote({
            proposalDescription: proposalDescription,
            options: options,
            voteEndTime: block.timestamp + 7 days, // Example: 7 days voting period
            isActive: true,
            winningOption: 0 // Default to the first option initially
        });
        emit CommunityVoteStarted(voteId, proposalDescription);
    }

    /**
     * @dev Function for NFT holders to vote in a community poll.
     * @param voteId The ID of the community vote.
     * @param optionIndex The index of the option to vote for (0-based).
     */
    function vote(uint256 voteId, uint256 optionIndex) public whenNotPaused {
        require(communityVotes[voteId].isActive, "Vote is not active");
        require(block.timestamp < communityVotes[voteId].voteEndTime, "Voting period ended");
        require(optionIndex < communityVotes[voteId].options.length, "Invalid option index");
        require(balanceOf(msg.sender) > 0, "Must own at least one NFT to vote"); // Token-gated voting

        communityVotes[voteId].votes[msg.sender] = optionIndex;
        emit CommunityVoteCasted(voteId, msg.sender, optionIndex);
    }

    /**
     * @dev Admin function to end a community vote and determine the winning option.
     * @param voteId The ID of the community vote to end.
     */
    function endCommunityVote(uint256 voteId) public onlyAdmin whenNotPaused {
        require(communityVotes[voteId].isActive, "Vote is not active");
        require(block.timestamp >= communityVotes[voteId].voteEndTime, "Voting period not yet ended");

        communityVotes[voteId].isActive = false; // Mark vote as inactive

        uint256[] memory voteCounts = new uint256[](communityVotes[voteId].options.length);
        uint256 totalVotes = 0;
        uint256 winningOptionIndex = 0;
        uint256 maxVotes = 0;

        // Count votes for each option
        for (uint256 i = 0; i < communityVotes[voteId].options.length; i++) {
            voteCounts[i] = 0;
        }
        for (uint256 i = 0; i < communityVotes[voteId].options.length; i++) {
            for (address voter => uint256 votedOptionIndex in communityVotes[voteId].votes) {
                if (votedOptionIndex == i) {
                    voteCounts[i]++;
                    totalVotes++;
                }
            }
        }

        // Determine winning option (simple majority - can be customized)
        for (uint256 i = 0; i < communityVotes[voteId].options.length; i++) {
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                winningOptionIndex = i;
            }
        }
        communityVotes[voteId].winningOption = winningOptionIndex;

        // Apply vote result (example - could trigger contract parameter changes, etc.)
        // For example:  if (voteId == 1 && winningOptionIndex == 0) { // If vote 1, option 0 wins, do something... }

        emit CommunityVoteEnded(voteId, winningOptionIndex);
    }


    /**
     * @dev Admin function to pause the contract.
     */
    function pauseContract() public onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Admin function to unpause the contract.
     */
    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Admin function to withdraw contract balance to the owner.
     */
    function withdraw() public onlyAdmin {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Admin function to set the base URI for metadata.
     * @param _baseURI The new base URI string.
     */
    function setBaseURI(string memory _baseURI) public onlyAdmin {
        baseURI = _baseURI;
    }

    /**
     * @dev Allows burning of an NFT by its owner.
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        _burn(tokenId);
    }

    /**
     * @dev Admin function for batch minting NFTs.
     * @param recipients An array of addresses to receive NFTs.
     * @param rarityTiers An array of rarity tiers for each NFT being minted.
     */
    function batchMint(address[] memory recipients, uint256[] memory rarityTiers) public onlyAdmin whenNotPaused {
        require(recipients.length == rarityTiers.length, "Recipients and rarity tiers arrays must have the same length");
        for (uint256 i = 0; i < recipients.length; i++) {
            mint(recipients[i], rarityTiers[i]);
        }
    }

    /**
     * @dev Function to retrieve a specific attribute for an NFT (example attribute retrieval).
     * @param tokenId The ID of the token.
     * @param attributeName The name of the attribute to retrieve (e.g., "Stage", "Rarity").
     * @return The value of the attribute as a string. Returns "Attribute not found" if not found.
     */
    function getAttribute(uint256 tokenId, string memory attributeName) public view whenNotPaused returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory metadataURI = tokenURI(tokenId);
        // In a real-world scenario, you would parse the JSON metadata from metadataURI
        // and extract the attribute value. For simplicity, this example returns placeholders.
        if (keccak256(bytes(attributeName)) == keccak256(bytes("Stage"))) {
            return evolutionStages[tokenStage[tokenId]];
        } else if (keccak256(bytes(attributeName)) == keccak256(bytes("Rarity"))) {
            return rarityTiers[rarityTier[tokenId]].name;
        } else {
            return "Attribute not found";
        }
    }

    // -------- ERC721 Overrides (Optional - for custom behavior if needed) --------
    // You can override _beforeTokenTransfer, _afterTokenTransfer, etc., if you need
    // to implement custom logic during token transfers or burns.

    // -------- Utility Libraries (Base64 Encoding - from OpenZeppelin Contracts - for metadata) --------
    /**
     * @dev Base64 encoding library.
     * Derived from https://github.com/miguelmota/solidity-base64
     */
    library Base64 {
        string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        function encode(bytes memory data) internal pure returns (string memory) {
            if (data.length == 0) return "";

            // load the table into memory
            string memory table = TABLE;

            // multiply by 4/3 rounded up
            uint256 encodedLen = 4 * ((data.length + 2) / 3);

            // add some extra buffer at the end required for the writing
            string memory result = new string(encodedLen+32);

            assembly {
                // set the actual output string length last
                mstore(result, encodedLen)
                // prepare input, output and table pointers
                let data_ptr := add(data, 32)
                let end := add(data_ptr, mload(data))
                let result_ptr := add(result, 32)
                let table_ptr := add(table, 32)

                // iterate over the input data
                for { let i := 0 } lt(data_ptr, end) { i := add(i, 3) } {
                    // read 3 bytes from input
                    let b1 := mload(data_ptr)
                    data_ptr := add(data_ptr, 1)
                    let b2 := 0
                    let b3 := 0
                    if lt(data_ptr, end) {
                        b2 := mload(data_ptr)
                        data_ptr := add(data_ptr, 1)
                    }
                    if lt(data_ptr, end) {
                        b3 := mload(data_ptr)
                        data_ptr := add(data_ptr, 1)
                    }

                    // encode 3 bytes into 4 characters
                    let idx1 := shr(2, b1)
                    let idx2 := and(shl(4, b1), 0x3f)
                    let idx3 := shr(6, b2)
                    let idx4 := and(shl(2, b2), 0x3f)
                    let idx5 := shr(8, b3)
                    let idx6 := b3

                    // write 4 characters to output string
                    mstore8(result_ptr, mload(add(table_ptr, idx1)))
                    result_ptr := add(result_ptr, 1)
                    mstore8(result_ptr, mload(add(table_ptr, add(idx2,1))))
                    result_ptr := add(result_ptr, 1)
                    mstore8(result_ptr, mload(add(table_ptr, add(idx3,2))))
                    result_ptr := add(result_ptr, 1)
                    mstore8(result_ptr, mload(add(table_ptr, add(idx4,3))))
                    result_ptr := add(result_ptr, 1)
                }
                // padding with '='
                switch mod(mload(data), 3)
                case 1 { mstore(sub(result_ptr, 2), shl(240, 0x3d3d)) } // '=='
                case 2 { mstore(sub(result_ptr, 1), shl(248, 0x3d)) } // '='
            }

            return result;
        }
    }
}
```