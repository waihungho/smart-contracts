```solidity
/**
 * @title Dynamic Reputation NFT with DAO Governance and Evolving Attributes
 * @author Bard (AI Assistant)
 * @dev A smart contract for creating Dynamic Reputation NFTs that evolve based on user interaction and are governed by a Decentralized Autonomous Organization (DAO).
 *
 * **Outline:**
 *
 * **NFT Core Functionality:**
 *   - Minting: Create new Reputation NFTs with initial attributes.
 *   - Transfer: Standard ERC721 transfer functionality.
 *   - Burning: Destroy NFTs (potentially for reputation penalties or specific use cases).
 *   - Token URI: Dynamic metadata generation based on NFT attributes and reputation.
 *   - Attribute Viewing: Functions to retrieve NFT attributes.
 *
 * **Reputation System:**
 *   - Reputation Accumulation: Functions for users to earn reputation through actions (e.g., staking, voting, contributions).
 *   - Reputation Decay: Implement a mechanism for reputation to decrease over time if inactive.
 *   - Reputation Levels: Define reputation tiers and associated benefits.
 *   - Reputation Boosts:  Temporary or permanent reputation multipliers.
 *   - Reputation-Gated Features: Access to certain contract functions or NFT attributes based on reputation levels.
 *
 * **Dynamic NFT Attributes:**
 *   - Attribute Evolution: Automatically update NFT attributes based on reputation, time, or external events.
 *   - Attribute Randomization (Initial): Introduce randomness in initial attribute generation.
 *   - Attribute Upgrades:  Allow users to spend tokens or reputation to upgrade specific attributes.
 *   - Attribute Customization (Limited):  Potentially allow limited user customization of certain attributes.
 *
 * **DAO Governance:**
 *   - Proposal Creation: Users can propose changes to contract parameters, attribute evolution rules, etc.
 *   - Voting Mechanism:  Implement a voting system for token holders or reputation holders to decide on proposals.
 *   - Parameter Setting (DAO Governed):  Certain contract parameters can only be modified through DAO votes.
 *   - Treasury Management (Optional):  If the contract collects fees, a DAO can manage the treasury.
 *   - Role-Based Access Control (DAO Governed):  DAO can manage admin roles and permissions.
 *
 * **Utility and Interaction:**
 *   - Staking NFTs: Allow users to stake their NFTs for rewards or reputation boosts.
 *   - Event Logging: Comprehensive event logging for all important actions.
 *   - Emergency Pause/Unpause:  Owner function to pause contract in case of critical issues (governed by DAO in future versions).
 *   - Fee Collection (Optional):  Implement fees for certain actions (e.g., minting, upgrades) to fund the DAO treasury or development.
 *
 * **Function Summary:**
 *
 * **NFT Core:**
 *   1. `mintNFT(address _to, string memory _baseURI)`: Mints a new Dynamic Reputation NFT to the specified address.
 *   2. `transferFrom(address _from, address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 *   3. `burnNFT(uint256 _tokenId)`: Burns (destroys) a specific NFT.
 *   4. `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an NFT.
 *   5. `getNFTAttributes(uint256 _tokenId)`: Retrieves the attributes of a specific NFT.
 *
 * **Reputation:**
 *   6. `earnReputation(address _user, uint256 _amount)`: Increases the reputation of a user.
 *   7. `decayReputation(address _user)`: Decreases the reputation of a user based on inactivity (automatic or triggered).
 *   8. `getUserReputation(address _user)`: Retrieves the reputation of a user.
 *   9. `getReputationLevel(address _user)`: Returns the reputation level of a user based on their reputation score.
 *   10. `applyReputationBoost(address _user, uint256 _boostPercentage, uint256 _duration)`: Applies a temporary reputation boost to a user.
 *
 * **Dynamic Attributes:**
 *   11. `evolveNFTAttributes(uint256 _tokenId)`: Evolves the attributes of an NFT based on reputation and other factors.
 *   12. `upgradeNFTAttribute(uint256 _tokenId, uint8 _attributeIndex)`: Allows users to upgrade a specific NFT attribute (costing tokens or reputation).
 *   13. `getRandomAttributeValue(uint256 _seed)`: Generates a random attribute value based on a seed.
 *   14. `setAttributeEvolutionRule(uint8 _attributeIndex, uint8 _evolutionType, uint256 _evolutionRate)`: Sets the evolution rule for a specific attribute (DAO governed).
 *
 * **DAO Governance:**
 *   15. `createProposal(string memory _title, string memory _description, bytes memory _calldata)`: Allows users to create a DAO proposal.
 *   16. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to vote on a DAO proposal.
 *   17. `executeProposal(uint256 _proposalId)`: Executes a passed DAO proposal.
 *   18. `getProposalState(uint256 _proposalId)`: Retrieves the current state of a DAO proposal.
 *   19. `setVotingQuorum(uint256 _newQuorum)`: Sets the voting quorum for DAO proposals (DAO governed).
 *
 * **Utility & Admin:**
 *   20. `stakeNFT(uint256 _tokenId)`: Allows users to stake their NFTs.
 *   21. `unstakeNFT(uint256 _tokenId)`: Allows users to unstake their NFTs.
 *   22. `pauseContract()`: Pauses the contract (owner only, eventually DAO governed).
 *   23. `unpauseContract()`: Unpauses the contract (owner only, eventually DAO governed).
 *   24. `withdrawFees()`: Allows the DAO or treasury to withdraw collected fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicReputationNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Structs & Enums ---

    struct NFTAttributes {
        uint8 level;
        uint8 power;
        uint8 agility;
        uint8 intelligence;
        // Add more attributes as needed
    }

    struct ReputationBoost {
        uint256 boostPercentage;
        uint256 endTime;
    }

    struct Proposal {
        string title;
        string description;
        bytes calldata;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voters; // Track voters to prevent double voting
    }

    enum AttributeEvolutionType {
        REPUTATION_BASED,
        TIME_BASED,
        EVENT_BASED // Example: Specific contract interactions
    }

    struct AttributeEvolutionRule {
        AttributeEvolutionType evolutionType;
        uint256 evolutionRate; // Rate of evolution per unit of time/reputation/event
    }

    // --- State Variables ---

    mapping(uint256 => NFTAttributes) public nftAttributes;
    mapping(address => uint256) public userReputation;
    mapping(address => ReputationBoost) public reputationBoosts;
    mapping(uint256 => uint256) public nftStakeTime; // Track NFT stake time
    mapping(uint256 => bool) public isNFTStaked;
    mapping(uint8 => AttributeEvolutionRule) public attributeEvolutionRules; // Attribute index => Evolution Rule
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public votingQuorum = 50; // Percentage quorum for DAO proposals

    string public baseTokenURI;
    bool public paused;

    // --- Events ---

    event NFTMinted(uint256 tokenId, address to);
    event NFTBurned(uint256 tokenId);
    event ReputationEarned(address user, uint256 amount, uint256 newReputation);
    event ReputationDecayed(address user, uint256 oldReputation, uint256 newReputation);
    event NFTAttributeEvolved(uint256 tokenId, uint8 attributeIndex, uint8 newValue);
    event NFTAttributeUpgraded(uint256 tokenId, uint8 attributeIndex, uint8 newValue, address upgradedBy);
    event ProposalCreated(uint256 proposalId, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyDAO() { // Placeholder - Replace with actual DAO logic
        require(msg.sender == owner(), "Only DAO can call this function (replace with actual DAO check)"); // Example: Owner acts as DAO for simplicity in this example
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseTokenURI = _baseURI;
        paused = false;

        // Set default attribute evolution rules (example - can be modified by DAO)
        attributeEvolutionRules[0] = AttributeEvolutionRule(AttributeEvolutionType.REPUTATION_BASED, 1); // Level evolves based on reputation
        attributeEvolutionRules[1] = AttributeEvolutionRule(AttributeEvolutionType.TIME_BASED, 1);     // Power evolves over time
        attributeEvolutionRules[2] = AttributeEvolutionRule(AttributeEvolutionType.EVENT_BASED, 1);    // Agility evolves on specific events (example needed)
        attributeEvolutionRules[3] = AttributeEvolutionRule(AttributeEvolutionType.REPUTATION_BASED, 1); // Intelligence evolves based on reputation
    }

    // -------------------- NFT Core Functionality --------------------

    /// @notice Mints a new Dynamic Reputation NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The base URI for the NFT metadata.
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);

        // Initialize NFT attributes - can be randomized or based on some logic
        nftAttributes[tokenId] = NFTAttributes({
            level: 1,
            power: getRandomAttributeValue(block.timestamp + tokenId) % 100 + 1, // Random power 1-100
            agility: getRandomAttributeValue(block.timestamp + tokenId + 1) % 100 + 1, // Random agility 1-100
            intelligence: getRandomAttributeValue(block.timestamp + tokenId + 2) % 100 + 1 // Random intelligence 1-100
        });

        baseTokenURI = _baseURI; // Update base URI if needed on minting

        emit NFTMinted(tokenId, _to);
        return tokenId;
    }

    /// @inheritdoc ERC721
    function transferFrom(address _from, address _to, uint256 _tokenId) public override whenNotPaused {
        super.transferFrom(_from, _to, _tokenId);
    }

    /// @notice Burns (destroys) a specific NFT.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        // Add any burning restrictions or logic here (e.g., reputation penalties)
        _burn(_tokenId);
        emit NFTBurned(_tokenId);
    }

    /// @inheritdoc ERC721Metadata
    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        // Dynamically generate metadata URI based on NFT attributes and reputation
        string memory metadata = generateNFTMetadata(_tokenId);
        string memory json = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(metadata))));
        return json;
    }

    /// @notice Retrieves the attributes of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The NFTAttributes struct containing the attributes.
    function getNFTAttributes(uint256 _tokenId) public view returns (NFTAttributes memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftAttributes[_tokenId];
    }


    // -------------------- Reputation System --------------------

    /// @notice Increases the reputation of a user.
    /// @param _user The address of the user.
    /// @param _amount The amount of reputation to add.
    function earnReputation(address _user, uint256 _amount) public whenNotPaused {
        userReputation[_user] = userReputation[_user].add(_amount);
        emit ReputationEarned(_user, _amount, userReputation[_user]);
    }

    /// @notice Decreases the reputation of a user based on inactivity. (Example - manual trigger, can be automated)
    /// @param _user The address of the user.
    function decayReputation(address _user) public whenNotPaused {
        uint256 currentReputation = userReputation[_user];
        uint256 decayAmount = currentReputation.div(10); // Example: Decay by 10% - adjust logic as needed
        if (decayAmount > 0) {
            userReputation[_user] = currentReputation.sub(decayAmount);
            emit ReputationDecayed(_user, currentReputation, userReputation[_user]);
        }
    }

    /// @notice Retrieves the reputation of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Returns the reputation level of a user based on their reputation score.
    /// @param _user The address of the user.
    /// @return The reputation level (example: 1, 2, 3, etc.).
    function getReputationLevel(address _user) public view returns (uint8) {
        uint256 reputation = userReputation[_user];
        if (reputation >= 10000) return 5; // Level 5: Legendary
        if (reputation >= 5000) return 4;  // Level 4: Epic
        if (reputation >= 1000) return 3;  // Level 3: Rare
        if (reputation >= 100) return 2;   // Level 2: Uncommon
        return 1;                         // Level 1: Common
    }

    /// @notice Applies a temporary reputation boost to a user.
    /// @param _user The address of the user.
    /// @param _boostPercentage The percentage boost (e.g., 10 for 10%).
    /// @param _duration The duration of the boost in seconds.
    function applyReputationBoost(address _user, uint256 _boostPercentage, uint256 _duration) public onlyOwner whenNotPaused {
        reputationBoosts[_user] = ReputationBoost({
            boostPercentage: _boostPercentage,
            endTime: block.timestamp + _duration
        });
    }

    // -------------------- Dynamic NFT Attributes --------------------

    /// @notice Evolves the attributes of an NFT based on reputation and other factors. (Example - manual trigger, can be automated)
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFTAttributes(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        NFTAttributes storage attributes = nftAttributes[_tokenId];

        // Example evolution logic - customize based on your game/system
        for (uint8 i = 0; i < 4; i++) { // Iterate through attributes (0 to 3 in this example)
            AttributeEvolutionRule memory rule = attributeEvolutionRules[i];
            if (rule.evolutionType == AttributeEvolutionType.REPUTATION_BASED) {
                uint256 reputationLevel = getReputationLevel(ownerOf(_tokenId)); // Evolve based on owner reputation
                if (reputationLevel > attributes.level) {
                    attributes.level = uint8(reputationLevel); // Level up NFT level to match reputation level
                    emit NFTAttributeEvolved(_tokenId, i, attributes.level);
                }
            } else if (rule.evolutionType == AttributeEvolutionType.TIME_BASED) {
                // Example: Power increases over time staked (need to track stake time and implement logic)
                if(isNFTStaked[_tokenId]) {
                    uint256 timeStaked = block.timestamp - nftStakeTime[_tokenId];
                    uint256 evolutionSteps = timeStaked / rule.evolutionRate; // Example rate: evolve every 'evolutionRate' seconds
                    if (evolutionSteps > 0) {
                        attributes.power = uint8(uint256(attributes.power).add(evolutionSteps) % 255); // Cap at 255, adjust logic
                        nftStakeTime[_tokenId] = block.timestamp; // Reset stake time to avoid excessive evolution in one call
                        emit NFTAttributeEvolved(_tokenId, i, attributes.power);
                    }
                }
            } // Add more evolution types as needed (EVENT_BASED etc.)
        }
    }

    /// @notice Allows users to upgrade a specific NFT attribute (costing tokens or reputation).
    /// @param _tokenId The ID of the NFT to upgrade.
    /// @param _attributeIndex The index of the attribute to upgrade (0: level, 1: power, 2: agility, 3: intelligence).
    function upgradeNFTAttribute(uint256 _tokenId, uint8 _attributeIndex) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(_attributeIndex < 4, "Invalid attribute index"); // Assuming 4 attributes

        // Example upgrade cost - can be tokens, reputation, etc.
        uint256 upgradeCost = 100; // Example: 100 reputation points

        require(userReputation[msg.sender] >= upgradeCost, "Not enough reputation to upgrade");
        userReputation[msg.sender] = userReputation[msg.sender].sub(upgradeCost);

        NFTAttributes storage attributes = nftAttributes[_tokenId];
        if (_attributeIndex == 0) attributes.level++;
        else if (_attributeIndex == 1) attributes.power = uint8(uint256(attributes.power).add(10) % 255); // Example: Increase power by 10, cap at 255
        else if (_attributeIndex == 2) attributes.agility = uint8(uint256(attributes.agility).add(10) % 255); // Example: Increase agility by 10, cap at 255
        else if (_attributeIndex == 3) attributes.intelligence = uint8(uint256(attributes.intelligence).add(10) % 255); // Example: Increase intelligence by 10, cap at 255

        emit NFTAttributeUpgraded(_tokenId, _attributeIndex, getAttributeValueByIndex(attributes, _attributeIndex), msg.sender);
    }

    /// @notice Generates a random attribute value based on a seed. (Basic randomness - consider Chainlink VRF for better randomness in production)
    /// @param _seed The seed value for randomness.
    /// @return A random uint8 value.
    function getRandomAttributeValue(uint256 _seed) internal view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed))) % 256);
    }

    /// @notice Sets the evolution rule for a specific attribute (DAO governed).
    /// @param _attributeIndex The index of the attribute.
    /// @param _evolutionType The new evolution type.
    /// @param _evolutionRate The new evolution rate.
    function setAttributeEvolutionRule(uint8 _attributeIndex, uint8 _evolutionType, uint256 _evolutionRate) public onlyDAO whenNotPaused {
        attributeEvolutionRules[_attributeIndex] = AttributeEvolutionRule({
            evolutionType: AttributeEvolutionType(_evolutionType),
            evolutionRate: _evolutionRate
        });
    }

    // -------------------- DAO Governance --------------------

    /// @notice Allows users to create a DAO proposal.
    /// @param _title The title of the proposal.
    /// @param _description The description of the proposal.
    /// @param _calldata The calldata to execute if the proposal passes.
    function createProposal(string memory _title, string memory _description, bytes memory _calldata) public whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            title: _title,
            description: _description,
            calldata: _calldata,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // Example: 7-day voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            voters: mapping(address => bool)()
        });

        emit ProposalCreated(proposalId, msg.sender);
    }

    /// @notice Allows users to vote on a DAO proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote for, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(proposals[_proposalId].endTime > block.timestamp, "Voting period has ended");
        require(!proposals[_proposalId].voters[msg.sender], "Already voted on this proposal");

        uint256 votingPower = getUserReputation(msg.sender); // Example: Voting power based on reputation - could be NFT ownership, tokens, etc.
        require(votingPower > 0, "No voting power"); // Ensure voters have voting power

        proposals[_proposalId].voters[msg.sender] = true; // Mark voter as voted

        if (_support) {
            proposals[_proposalId].votesFor = proposals[_proposalId].votesFor.add(votingPower);
        } else {
            proposals[_proposalId].votesAgainst = proposals[_proposalId].votesAgainst.add(votingPower);
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed DAO proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        require(proposals[_proposalId].endTime <= block.timestamp, "Voting period has not ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        uint256 totalVotes = proposals[_proposalId].votesFor.add(proposals[_proposalId].votesAgainst);
        uint256 percentageFor = (proposals[_proposalId].votesFor * 100) / totalVotes; // Calculate percentage of 'for' votes

        require(percentageFor >= votingQuorum, "Proposal does not meet quorum"); // Check quorum

        (bool success, ) = address(this).call(proposals[_proposalId].calldata); // Execute proposal calldata
        require(success, "Proposal execution failed");

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Retrieves the current state of a DAO proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalState(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Sets the voting quorum for DAO proposals (DAO governed).
    /// @param _newQuorum The new voting quorum percentage (e.g., 51 for 51%).
    function setVotingQuorum(uint256 _newQuorum) public onlyDAO whenNotPaused {
        require(_newQuorum <= 100, "Quorum must be a percentage value (<= 100)");
        votingQuorum = _newQuorum;
    }


    // -------------------- Utility & Admin --------------------

    /// @notice Allows users to stake their NFTs.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(!isNFTStaked[_tokenId], "NFT already staked");

        isNFTStaked[_tokenId] = true;
        nftStakeTime[_tokenId] = block.timestamp;
        // Transfer NFT to contract (or manage stake internally without transfer - depends on design)
        safeTransferFrom(msg.sender, address(this), _tokenId);

        // Example: Earn initial reputation for staking
        earnReputation(msg.sender, 50); // Example reputation reward for staking
    }

    /// @notice Allows users to unstake their NFTs.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(isNFTStaked[_tokenId], "NFT not staked");
        require(ownerOf(_tokenId) == address(this), "Contract is not NFT owner (internal error)"); // Sanity check

        isNFTStaked[_tokenId] = false;
        delete nftStakeTime[_tokenId]; // Clean up stake time
        // Transfer NFT back to owner
        safeTransferFrom(address(this), msg.sender, _tokenId);

        // Example: Earn reputation based on stake duration
        uint256 stakeDuration = block.timestamp - nftStakeTime[_tokenId];
        uint256 reputationReward = stakeDuration / (1 hours); // Example: 1 reputation per hour staked
        earnReputation(msg.sender, reputationReward);
    }

    /// @notice Pauses the contract, preventing most functions from being called (owner only, eventually DAO governed).
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing functions to be called again (owner only, eventually DAO governed).
    function unpauseContract() public onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Allows the DAO or treasury to withdraw collected fees (if any fee mechanisms are implemented).
    function withdrawFees() public onlyDAO whenNotPaused {
        // Implement fee withdrawal logic if fees are collected in the contract
        payable(owner()).transfer(address(this).balance); // Example: Withdraw all contract balance to owner (as DAO representative)
    }

    // -------------------- Internal Helper Functions --------------------

    /// @dev Internal helper function to generate dynamic NFT metadata JSON.
    /// @param _tokenId The ID of the NFT.
    /// @return JSON string representing the NFT metadata.
    function generateNFTMetadata(uint256 _tokenId) internal view returns (string memory) {
        NFTAttributes memory attributes = nftAttributes[_tokenId];
        uint8 reputationLevel = getReputationLevel(ownerOf(_tokenId));

        string memory attributesJson = string(abi.encodePacked(
            '{"level": "', attributes.level.toString(), '", ',
            '"power": "', attributes.power.toString(), '", ',
            '"agility": "', attributes.agility.toString(), '", ',
            '"intelligence": "', attributes.intelligence.toString(), '", ',
            '"reputationLevel": "', reputationLevel.toString(), '"}'
        ));

        string memory metadata = string(abi.encodePacked(
            '{',
            '"name": "Dynamic Reputation NFT #', _tokenId.toString(), '", ',
            '"description": "A Dynamic Reputation NFT that evolves and is governed by a DAO.", ',
            '"image": "', baseTokenURI, _tokenId.toString(), '.png", ', // Example image URI - adjust as needed
            '"attributes": ', attributesJson,
            '}'
        ));
        return metadata;
    }

    /// @dev Internal helper function to get attribute value by index from NFTAttributes struct.
    /// @param _attributes NFTAttributes struct.
    /// @param _index Attribute index (0: level, 1: power, 2: agility, 3: intelligence).
    /// @return Attribute value as uint8.
    function getAttributeValueByIndex(NFTAttributes memory _attributes, uint8 _index) internal pure returns (uint8) {
        if (_index == 0) return _attributes.level;
        if (_index == 1) return _attributes.power;
        if (_index == 2) return _attributes.agility;
        if (_index == 3) return _attributes.intelligence;
        return 0; // Default return if index is out of range (should not happen with proper checks)
    }
}

// --- Base64 Encoding Library (for dynamic metadata) ---
// From: https://ethereum.stackexchange.com/questions/87875/how-to-get-base64-string-of-json-in-solidity
library Base64 {
    string internal constant alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = alphabet;

        // multiply by 3/4 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set pointer to start of input data
            let dataPtr := add(data, 32)
            // set pointer to start of output result
            let resultPtr := add(result, 32)

            // iterate over the input data
            for {
                let i := 0
            } lt(i, data.length) {

            } i := add(i, 3) {
                // copy 3 bytes from data into scratch area
                let b1 := and(mload(add(dataPtr, i)), 0xff)
                let b2 := and(mload(add(dataPtr, add(i, 1))), 0xff)
                let b3 := and(mload(add(dataPtr, add(i, 2))), 0xff)

                // encode 3 bytes into 4 characters
                mstore(resultPtr, shl(248, mload(add(table, mul(and(shr(2, b1), 0x3f), 1)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(table, mul(and(or(shl(4, b1), shr(4, b2)), 0x3f), 1)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(table, mul(and(or(shl(2, b2), shr(6, b3)), 0x3f), 1)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(table, mul(and(b3, 0x3f), 1)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(data.length, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
```