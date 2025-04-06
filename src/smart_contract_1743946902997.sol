```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Evolving NFT with On-Chain Governance and Rarity-Based Abilities
 * @author Bard (Example Smart Contract - Educational Purposes)
 *
 * @dev This contract implements a unique NFT that can dynamically evolve through user interactions,
 *      governance proposals, and inherent rarity traits. It features on-chain governance for
 *      parameter adjustments, a dynamic metadata system reflecting NFT evolution, and
 *      rarity-based abilities that unlock as NFTs evolve.
 *
 * **Outline:**
 * 1. **Core NFT Functionality:** Basic ERC721-like structure with minting, ownership, and transfers.
 * 2. **Dynamic Evolution System:**
 *    - Evolution Stages: NFTs progress through predefined stages.
 *    - Evolution Triggers: Time-based, interaction-based, governance-based.
 *    - Evolution Logic: Defines how NFTs evolve based on triggers and stages.
 * 3. **On-Chain Governance:**
 *    - Proposal System: Users can propose changes to evolution parameters.
 *    - Voting Mechanism: NFT holders vote on proposals.
 *    - Execution of Proposals: Successful proposals update contract parameters.
 * 4. **Rarity and Abilities:**
 *    - Rarity Tiers: NFTs assigned rarity levels at minting.
 *    - Ability Unlocking: Abilities unlock at specific evolution stages based on rarity.
 *    - Ability Usage: Functions to utilize unlocked NFT abilities.
 * 5. **Dynamic Metadata:**
 *    - Metadata Updates: `tokenURI` dynamically reflects NFT's current evolution stage and abilities.
 *    - On-Chain Metadata Storage:  Efficiently stores metadata and evolution data.
 * 6. **Advanced Features:**
 *    - NFT Staking for Governance Power: Stake NFTs to increase voting weight.
 *    - Burning Mechanism: Allow NFT burning for specific actions (optional).
 *    - Randomized Evolution Paths (Optional): Introduce randomness into evolution.
 *
 * **Function Summary:**
 * 1. `mintNFT(address _to, uint256 _rarityTier)`: Mints a new NFT to the specified address with a given rarity tier.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 * 3. `getNFTOwner(uint256 _tokenId)`: Returns the owner of a specific NFT.
 * 4. `getNFTRarity(uint256 _tokenId)`: Returns the rarity tier of a specific NFT.
 * 5. `getNFTEvolutionStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 6. `triggerTimeBasedEvolution(uint256 _tokenId)`: Triggers time-based evolution for an NFT if conditions are met.
 * 7. `interactWithNFT(uint256 _tokenId, uint256 _interactionType)`: Simulates user interaction with an NFT, potentially triggering evolution.
 * 8. `proposeEvolutionParameterChange(string memory _parameterName, uint256 _newValue, string memory _description)`: Allows NFT holders to propose changes to evolution parameters.
 * 9. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on active governance proposals.
 * 10. `executeProposal(uint256 _proposalId)`: Executes a successful governance proposal, updating contract parameters.
 * 11. `getStakedNFTs(address _user)`: Returns a list of token IDs staked by a user for governance.
 * 12. `stakeNFTForGovernance(uint256 _tokenId)`: Allows NFT owners to stake their NFTs for governance voting power.
 * 13. `unstakeNFTForGovernance(uint256 _tokenId)`: Allows NFT owners to unstake their NFTs from governance.
 * 14. `useNFTAbility(uint256 _tokenId, uint256 _abilityId)`: Allows NFT owners to use unlocked abilities based on their NFT's evolution and rarity.
 * 15. `getNFTAbilities(uint256 _tokenId)`: Returns a list of unlocked abilities for an NFT.
 * 16. `getProposalDetails(uint256 _proposalId)`: Returns details of a specific governance proposal.
 * 17. `getCurrentProposals()`: Returns a list of IDs of currently active governance proposals.
 * 18. `getPastProposals()`: Returns a list of IDs of past (executed or failed) governance proposals.
 * 19. `setBaseMetadataURI(string memory _baseURI)`: (Admin function) Sets the base URI for NFT metadata.
 * 20. `withdrawContractBalance()`: (Admin function) Allows the contract owner to withdraw contract balance.
 * 21. `pauseContract()`: (Admin function) Pauses certain functionalities of the contract.
 * 22. `unpauseContract()`: (Admin function) Resumes paused functionalities of the contract.
 */

contract DynamicEvolvingNFT {
    // ** 1. Core NFT Functionality **
    string public name = "Dynamic Evolving NFT";
    string public symbol = "DENFT";
    string public baseMetadataURI;

    mapping(uint256 => address) public nftOwner;
    mapping(address => uint256) public balance;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Mint(address indexed to, uint256 tokenId, uint256 rarityTier);

    // ** 2. Dynamic Evolution System **
    enum EvolutionStage { Stage0, Stage1, Stage2, Stage3, Stage4 } // Example stages
    mapping(uint256 => EvolutionStage) public nftEvolutionStage;
    mapping(uint256 => uint256) public lastEvolutionTime;
    uint256 public evolutionTimeIntervalStage1 = 7 days; // Example intervals, governable
    uint256 public evolutionTimeIntervalStage2 = 14 days;
    uint256 public evolutionInteractionThresholdStage2 = 10; // Example interaction threshold, governable
    mapping(uint256 => uint256) public interactionCount;

    event EvolutionTriggered(uint256 tokenId, EvolutionStage fromStage, EvolutionStage toStage, string reason);
    event StageUpgraded(uint256 tokenId, EvolutionStage newStage);

    // ** 3. On-Chain Governance **
    struct Proposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        address proposer;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public proposalVoteDuration = 3 days; // Governable duration
    uint256 public proposalQuorumPercentage = 50; // Governable quorum percentage
    mapping(uint256 => mapping(address => bool)) public votes; // proposalId => voter => voted

    event ProposalCreated(uint256 proposalId, string parameterName, uint256 newValue, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);

    // ** 4. Rarity and Abilities **
    enum RarityTier { Common, Rare, Epic, Legendary } // Example rarity tiers
    mapping(uint256 => RarityTier) public nftRarityTier;

    struct Ability {
        uint256 abilityId;
        string abilityName;
        string description;
        EvolutionStage requiredStage;
        RarityTier[] requiredRarities; // Array of rarities that can use this ability
    }

    Ability[] public abilities;
    mapping(uint256 => mapping(uint256 => bool)) public nftAbilitiesUnlocked; // tokenId => abilityId => unlocked

    event AbilityUnlocked(uint256 tokenId, uint256 abilityId, string abilityName);
    event AbilityUsed(uint256 tokenId, uint256 abilityId, string abilityName);


    // ** 5. Dynamic Metadata **
    // Metadata is dynamically generated in tokenURI function based on NFT state

    // ** 6. Advanced Features **
    mapping(address => uint256[]) public stakedNFTsByUser; // user => array of tokenIds staked
    mapping(uint256 => bool) public isNFTStaked; // tokenId => staked status

    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);


    // ** Admin Functions **
    address public owner;
    bool public paused;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }


    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseMetadataURI = _baseURI;
        // Define some example abilities
        abilities.push(Ability(1, "Boost Speed", "Temporarily increases speed in supported games.", EvolutionStage.Stage2, [RarityTier.Rare, RarityTier.Epic, RarityTier.Legendary]));
        abilities.push(Ability(2, "Enhanced Defense", "Provides a defensive buff in certain scenarios.", EvolutionStage.Stage3, [RarityTier.Epic, RarityTier.Legendary]));
        abilities.push(Ability(3, "Unique Visual Aura", "Displays a special visual effect.", EvolutionStage.Stage1, [RarityTier.Common, RarityTier.Rare, RarityTier.Epic, RarityTier.Legendary]));

    }

    // ** 1. Core NFT Functionality Functions **

    function mintNFT(address _to, uint256 _rarityTier) public onlyOwner whenNotPaused returns (uint256) {
        require(_to != address(0), "Cannot mint to the zero address.");
        totalSupply++;
        uint256 tokenId = totalSupply;
        nftOwner[tokenId] = _to;
        balance[_to]++;
        nftRarityTier[tokenId] = RarityTier(_rarityTier); // Assuming rarityTier is 0, 1, 2, 3
        nftEvolutionStage[tokenId] = EvolutionStage.Stage0;
        lastEvolutionTime[tokenId] = block.timestamp;

        emit Mint(_to, tokenId, _rarityTier);
        emit Transfer(address(0), _to, tokenId);
        return tokenId;
    }

    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(msg.sender == nftOwner[_tokenId] || msg.sender == owner, "Not NFT owner or admin."); // Only owner can transfer
        require(_to != address(0), "Cannot transfer to the zero address.");
        require(nftOwner[_tokenId] == _from, "Incorrect from address.");

        balance[_from]--;
        balance[_to]++;
        nftOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        return nftOwner[_tokenId];
    }

    function getNFTRarity(uint256 _tokenId) public view returns (RarityTier) {
        return nftRarityTier[_tokenId];
    }

    function getNFTEvolutionStage(uint256 _tokenId) public view returns (EvolutionStage) {
        return nftEvolutionStage[_tokenId];
    }


    // ** 2. Dynamic Evolution System Functions **

    function triggerTimeBasedEvolution(uint256 _tokenId) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(msg.sender == nftOwner[_tokenId], "Not NFT owner.");

        EvolutionStage currentStage = nftEvolutionStage[_tokenId];
        if (currentStage == EvolutionStage.Stage0) {
            if (block.timestamp >= lastEvolutionTime[_tokenId] + evolutionTimeIntervalStage1) {
                _evolveNFT(_tokenId, EvolutionStage.Stage1, "Time-based evolution Stage 1");
            }
        } else if (currentStage == EvolutionStage.Stage1) {
            if (block.timestamp >= lastEvolutionTime[_tokenId] + evolutionTimeIntervalStage2) {
                _evolveNFT(_tokenId, EvolutionStage.Stage2, "Time-based evolution Stage 2");
            }
        }
        // Add more stages and conditions as needed
    }

    function interactWithNFT(uint256 _tokenId, uint256 _interactionType) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(msg.sender == nftOwner[_tokenId], "Not NFT owner.");

        interactionCount[_tokenId]++;
        if (nftEvolutionStage[_tokenId] == EvolutionStage.Stage1 && interactionCount[_tokenId] >= evolutionInteractionThresholdStage2) {
            _evolveNFT(_tokenId, EvolutionStage.Stage2, "Interaction-based evolution Stage 2");
        }
        // Interaction types can be used for more complex evolution logic
        emit EvolutionTriggered(_tokenId, nftEvolutionStage[_tokenId], nftEvolutionStage[_tokenId], "User Interaction");
    }

    function _evolveNFT(uint256 _tokenId, EvolutionStage _newStage, string memory _reason) private {
        EvolutionStage currentStage = nftEvolutionStage[_tokenId];
        if (_newStage > currentStage) {
            nftEvolutionStage[_tokenId] = _newStage;
            lastEvolutionTime[_tokenId] = block.timestamp; // Reset time for next stage
            _unlockAbilitiesOnEvolution(_tokenId, _newStage);
            emit EvolutionTriggered(_tokenId, currentStage, _newStage, _reason);
            emit StageUpgraded(_tokenId, _newStage);
        }
    }

    function _unlockAbilitiesOnEvolution(uint256 _tokenId, EvolutionStage _stage) private {
        RarityTier rarity = nftRarityTier[_tokenId];
        for (uint256 i = 0; i < abilities.length; i++) {
            Ability storage ability = abilities[i];
            if (ability.requiredStage == _stage) {
                for (uint256 j = 0; j < ability.requiredRarities.length; j++) {
                    if (ability.requiredRarities[j] == rarity) {
                        if (!nftAbilitiesUnlocked[_tokenId][ability.abilityId]) {
                            nftAbilitiesUnlocked[_tokenId][ability.abilityId] = true;
                            emit AbilityUnlocked(_tokenId, ability.abilityId, ability.abilityName);
                        }
                        break; // No need to check other rarities for this ability
                    }
                }
            }
        }
    }


    // ** 3. On-Chain Governance Functions **

    function proposeEvolutionParameterChange(string memory _parameterName, uint256 _newValue, string memory _description) public whenNotPaused {
        require(nftOwner[1] != address(0), "Need at least one NFT to propose."); // Example: require at least one NFT to propose
        require(balance[msg.sender] > 0, "You need to own at least one NFT to propose.");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.parameterName = _parameterName;
        newProposal.newValue = _newValue;
        newProposal.description = _description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + proposalVoteDuration;
        newProposal.proposer = msg.sender;

        emit ProposalCreated(proposalCount, _parameterName, _newValue, _description, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(nftOwner[1] != address(0), "Need at least one NFT to vote."); // Example: require at least one NFT to vote
        require(balance[msg.sender] > 0, "You need to own at least one NFT to vote.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period ended.");
        require(!votes[_proposalId][msg.sender], "Already voted on this proposal.");

        votes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].votesFor += getVotingPower(msg.sender); // Voting power based on staked NFTs
        } else {
            proposals[_proposalId].votesAgainst += getVotingPower(msg.sender);
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused onlyOwner { // Only owner can execute after voting
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period not ended.");

        uint256 totalVotingPower = getTotalVotingPower();
        uint256 quorum = (totalVotingPower * proposalQuorumPercentage) / 100;

        if (proposals[_proposalId].votesFor >= quorum && proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst) {
            // Example parameter updates - expand as needed, consider using a mapping for parameters
            if (keccak256(bytes(proposals[_proposalId].parameterName)) == keccak256(bytes("evolutionTimeIntervalStage1"))) {
                evolutionTimeIntervalStage1 = proposals[_proposalId].newValue;
            } else if (keccak256(bytes(proposals[_proposalId].parameterName)) == keccak256(bytes("evolutionTimeIntervalStage2"))) {
                evolutionTimeIntervalStage2 = proposals[_proposalId].newValue;
            } // ... add more parameter updates here
            else {
                revert("Unknown parameter to update."); // Or handle unknown parameters differently
            }

            proposals[_proposalId].executed = true;
            emit ProposalExecuted(_proposalId, proposals[_proposalId].parameterName, proposals[_proposalId].newValue);
        } else {
            revert("Proposal failed: Not enough votes or quorum not reached.");
        }
    }

    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getCurrentProposals() public view returns (uint256[] memory) {
        uint256[] memory currentProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (!proposals[i].executed && block.timestamp < proposals[i].endTime) {
                currentProposalIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(currentProposalIds, count) // Adjust array length to actual count
        }
        return currentProposalIds;
    }

    function getPastProposals() public view returns (uint256[] memory) {
        uint256[] memory pastProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].executed || block.timestamp >= proposals[i].endTime) {
                pastProposalIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(pastProposalIds, count) // Adjust array length to actual count
        }
        return pastProposalIds;
    }


    // ** 4. Rarity and Abilities Functions **

    function useNFTAbility(uint256 _tokenId, uint256 _abilityId) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(msg.sender == nftOwner[_tokenId], "Not NFT owner.");
        require(nftAbilitiesUnlocked[_tokenId][_abilityId], "Ability not unlocked for this NFT.");

        Ability storage ability = abilities[_abilityId - 1]; // Ability IDs are 1-based
        // Implement ability logic here - this is just a placeholder
        // e.g., trigger in-game effects, update NFT metadata, etc.
        emit AbilityUsed(_tokenId, _abilityId, ability.abilityName);
        // For example, maybe abilities have cooldowns or limited uses (add logic if needed)
    }

    function getNFTAbilities(uint256 _tokenId) public view returns (Ability[] memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        Ability[] memory unlockedAbilities = new Ability[](abilities.length); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < abilities.length; i++) {
            if (nftAbilitiesUnlocked[_tokenId][abilities[i].abilityId]) {
                unlockedAbilities[count] = abilities[i];
                count++;
            }
        }
        assembly {
            mstore(unlockedAbilities, count) // Adjust array length to actual count
        }
        return unlockedAbilities;
    }


    // ** 6. Advanced Features Functions (Staking for Governance) **

    function stakeNFTForGovernance(uint256 _tokenId) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(msg.sender == nftOwner[_tokenId], "Not NFT owner.");
        require(!isNFTStaked[_tokenId], "NFT already staked.");

        isNFTStaked[_tokenId] = true;
        stakedNFTsByUser[msg.sender].push(_tokenId);
        emit NFTStaked(msg.sender, _tokenId);
    }

    function unstakeNFTForGovernance(uint256 _tokenId) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(msg.sender == nftOwner[_tokenId], "Not NFT owner.");
        require(isNFTStaked[_tokenId], "NFT not staked.");

        isNFTStaked[_tokenId] = false;
        uint256[] storage stakedTokens = stakedNFTsByUser[msg.sender];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == _tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1]; // Replace with last element
                stakedTokens.pop();
                break;
            }
        }
        emit NFTUnstaked(msg.sender, _tokenId);
    }

    function getStakedNFTs(address _user) public view returns (uint256[] memory) {
        return stakedNFTsByUser[_user];
    }

    function getVotingPower(address _voter) public view returns (uint256) {
        return stakedNFTsByUser[_voter].length; // Voting power is simply number of staked NFTs
    }

    function getTotalVotingPower() public view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (isNFTStaked[i]) {
                totalPower++;
            }
        }
        return totalPower;
    }


    // ** 5. Dynamic Metadata Function **

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        string memory stageName;
        if (nftEvolutionStage[_tokenId] == EvolutionStage.Stage0) {
            stageName = "Stage 0 - Dormant";
        } else if (nftEvolutionStage[_tokenId] == EvolutionStage.Stage1) {
            stageName = "Stage 1 - Awakening";
        } else if (nftEvolutionStage[_tokenId] == EvolutionStage.Stage2) {
            stageName = "Stage 2 - Evolving";
        } else if (nftEvolutionStage[_tokenId] == EvolutionStage.Stage3) {
            stageName = "Stage 3 - Ascended";
        } else {
            stageName = "Stage 4 - Transcendent";
        }

        string memory rarityName;
        if (nftRarityTier[_tokenId] == RarityTier.Common) {
            rarityName = "Common";
        } else if (nftRarityTier[_tokenId] == RarityTier.Rare) {
            rarityName = "Rare";
        } else if (nftRarityTier[_tokenId] == RarityTier.Epic) {
            rarityName = "Epic";
        } else {
            rarityName = "Legendary";
        }

        string memory abilitiesList = "[";
        Ability[] memory unlockedAbilities = getNFTAbilities(_tokenId);
        for (uint256 i = 0; i < unlockedAbilities.length; i++) {
            abilitiesList = string(abi.encodePacked(abilitiesList, '{"name":"', unlockedAbilities[i].abilityName, '", "description":"', unlockedAbilities[i].description, '"}'));
            if (i < unlockedAbilities.length - 1) {
                abilitiesList = string(abi.encodePacked(abilitiesList, ","));
            }
        }
        abilitiesList = string(abi.encodePacked(abilitiesList, "]"));


        string memory metadata = string(abi.encodePacked(
            '{',
            '"name": "', name, ' #', Strings.toString(_tokenId), ' - ', stageName, '",',
            '"description": "A Dynamic Evolving NFT of ', rarityName, ' rarity. Evolves through stages and unlocks abilities.",',
            '"image": "', baseMetadataURI, _tokenId, '.png",', // Example image URI - customize
            '"attributes": [',
                '{"trait_type": "Rarity", "value": "', rarityName, '"},',
                '{"trait_type": "Evolution Stage", "value": "', stageName, '"},',
                '{"trait_type": "Abilities", "value": ', abilitiesList, '}', // Abilities as JSON array
            ']',
            '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }


    // ** Admin Functions **

    function setBaseMetadataURI(string memory _baseURI) public onlyOwner {
        baseMetadataURI = _baseURI;
    }

    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
    }
}

// --- Helper Libraries (Import or include as needed) ---

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(addr, false);
    }

    function toHexString(address addr, bool withPrefix) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 + _ADDRESS_LENGTH * 2);
        if (withPrefix) {
            buffer[0] = "0";
            buffer[1] = "x";
        }
        bytes memory addrBytes = addressToBytes(addr);
        for (uint256 i = 0; i < _ADDRESS_LENGTH; ) {
            uint8 high = uint8(uint256(addrBytes[i]) >> 4);
            uint8 low = uint8(uint256(addrBytes[i]) & 0x0f);
            buffer[2 + i * 2] = _HEX_SYMBOLS[high];
            buffer[3 + i * 2] = _HEX_SYMBOLS[low];
            unchecked {
                i++;
            }
        }
        return string(buffer);
    }

    function addressToBytes(address addr) private pure returns (bytes memory) {
        assembly {
            mstore(0, addr)
            return(32, _ADDRESS_LENGTH)
        }
    }

    uint256 internal constant uint256_MAX = type(uint256).max;

    function toHexString(uint256 value) internal pure returns (string memory) {
        return toHexString(value, false);
    }

    function toHexString(uint256 value, bool withPrefix) internal pure returns (string memory) {
        if (value == 0) {
            return "0x0";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        length *= 2;
        bytes memory buffer = new bytes(length + 2);
        uint256 index = length;
        while (value != 0) {
            index--;
            buffer[index] = _HEX_SYMBOLS[uint8(value & 0xf)];
            index--;
            buffer[index] = _HEX_SYMBOLS[uint8((value >> 4) & 0xf)];
            value >>= 8;
        }
        if (withPrefix) {
            buffer[0] = "0";
            buffer[1] = "x";
        }
        return string(buffer);
    }
}

library Base64 {
    string private constant _BASE64_ENCODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Calculate the output length
        uint256 len = data.length;
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Allocate memory for the encoded string
        bytes memory encoded = new bytes(encodedLen);

        uint256 inputIndex = 0;
        uint256 outputIndex = 0;

        while (inputIndex < len) {
            uint24 chunk = 0;
            chunk |= uint24(data[inputIndex++]) << 16;
            if (inputIndex < len) {
                chunk |= uint24(data[inputIndex++]) << 8;
            }
            if (inputIndex < len) {
                chunk |= uint24(data[inputIndex++]);
            }

            encoded[outputIndex++] = _BASE64_ENCODE_CHARS[uint8((chunk >> 18) & 0x3F)];
            encoded[outputIndex++] = _BASE64_ENCODE_CHARS[uint8((chunk >> 12) & 0x3F)];
            encoded[outputIndex++] = _BASE64_ENCODE_CHARS[uint8((chunk >> 6) & 0x3F)];
            encoded[outputIndex++] = _BASE64_ENCODE_CHARS[uint8(chunk & 0x3F)];
        }

        // Padding
        if (len % 3 == 1) {
            encoded[encodedLen - 2] = "=";
            encoded[encodedLen - 1] = "=";
        } else if (len % 3 == 2) {
            encoded[encodedLen - 1] = "=";
        }

        return string(encoded);
    }
}
```