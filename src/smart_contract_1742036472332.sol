```solidity
/**
 * @title EvolvingNFTCollective - Dynamic and Interactive NFT Ecosystem
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing a collection of Dynamic NFTs with evolving attributes,
 *      a reputation system, decentralized governance, and interactive features.
 *
 * **Outline:**
 *  This contract implements a Dynamic NFT collection where NFTs can evolve their attributes based on
 *  user interactions and on-chain events. It introduces a reputation system to reward active participants
 *  and a decentralized governance mechanism for community-driven attribute evolution and feature proposals.
 *
 * **Function Summary:**
 *  1.  `mintNFT(string memory _baseURI)`: Mints a new EvolvingNFT with initial attributes and base URI.
 *  2.  `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 *  3.  `tokenURI(uint256 _tokenId)`: Returns the URI for an NFT, dynamically generated based on attributes.
 *  4.  `getNFTAttributes(uint256 _tokenId)`: Retrieves the current attributes of an NFT.
 *  5.  `evolveAttribute(uint256 _tokenId, string memory _attributeName)`: Triggers the evolution of a specific NFT attribute based on predefined rules.
 *  6.  `interactWithNFT(uint256 _tokenId, string memory _interactionType)`: Records user interactions with NFTs, influencing attribute evolution and reputation.
 *  7.  `setBaseAttributeChangeRate(string memory _attributeName, uint256 _rate)`: Admin function to set the base rate of attribute change for specific attributes.
 *  8.  `getBaseAttributeChangeRate(string memory _attributeName)`: Retrieves the base attribute change rate for a given attribute.
 *  9.  `getReputation(address _user)`: Retrieves the reputation score of a user.
 *  10. `createProposal(string memory _title, string memory _description, bytes memory _calldata)`: Allows users with sufficient reputation to create governance proposals.
 *  11. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with reputation to vote on active proposals.
 *  12. `executeProposal(uint256 _proposalId)`: Executes a passed proposal if enough votes are reached and time limit is met (Admin/Governance).
 *  13. `getProposalState(uint256 _proposalId)`: Retrieves the current state of a proposal (Active, Passed, Failed, Executed).
 *  14. `setContractPaused(bool _paused)`: Admin function to pause/unpause core contract functionalities.
 *  15. `isAttributeEvolvable(string memory _attributeName)`: Checks if a specific attribute is configured for evolution.
 *  16. `addEvolvableAttribute(string memory _attributeName, uint256 _baseRate)`: Admin function to add a new attribute that can evolve.
 *  17. `removeEvolvableAttribute(string memory _attributeName)`: Admin function to remove an attribute from the evolution system.
 *  18. `getNFTCount()`: Returns the total number of NFTs minted.
 *  19. `supportsInterface(bytes4 interfaceId)`:  Standard ERC721 interface support.
 *  20. `withdrawContractBalance()`: Admin function to withdraw accumulated contract balance (if any, e.g., from fees).
 *  21. `setInteractionWeight(string memory _interactionType, uint256 _weight)`: Admin function to adjust the reputation weight of different interaction types.
 *  22. `getInteractionWeight(string memory _interactionType)`: Retrieves the reputation weight for a given interaction type.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract EvolvingNFTCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    // --- NFT Attributes ---
    struct NFTAttributes {
        uint256 level;
        uint256 power;
        uint256 agility;
        uint256 intelligence;
        uint256 vitality;
        // Add more dynamic attributes as needed
    }
    mapping(uint256 => NFTAttributes) public nftAttributes;

    // --- Attribute Evolution Configuration ---
    mapping(string => uint256) public baseAttributeChangeRates; // Attribute name => Base change rate (per interaction/time unit)
    mapping(string => bool) public isEvolvableAttribute; // Attribute name => Is evolvable flag

    // --- Reputation System ---
    mapping(address => uint256) public userReputations;
    mapping(string => uint256) public interactionWeights; // Interaction type => Reputation weight

    // --- Governance Proposals ---
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        bytes calldata;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalState state;
    }
    enum ProposalState { Active, Passed, Failed, Executed }
    Proposal[] public proposals;
    uint256 public proposalVoteDuration = 7 days; // Default proposal voting duration
    uint256 public proposalQuorum = 50; // Percentage of total reputation needed to pass a proposal

    // --- Contract State ---
    bool public contractPaused;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address minter);
    event AttributeEvolved(uint256 tokenId, string attributeName, uint256 newValue);
    event InteractionRecorded(uint256 tokenId, address user, string interactionType);
    event ReputationChanged(address user, uint256 newReputation, string reason);
    event ProposalCreated(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused(bool paused);
    event AttributeChangeRateSet(string attributeName, uint256 newRate);
    event EvolvableAttributeAdded(string attributeName, uint256 baseRate);
    event EvolvableAttributeRemoved(string attributeName);
    event InteractionWeightSet(string interactionType, uint256 newWeight);


    constructor() ERC721("EvolvingNFTCollective", "ENFTC") {
        // Initialize default evolvable attributes and base change rates
        addEvolvableAttribute("level", 1);
        addEvolvableAttribute("power", 2);
        addEvolvableAttribute("agility", 2);
        addEvolvableAttribute("intelligence", 1);
        addEvolvableAttribute("vitality", 3);

        // Initialize default interaction weights
        setInteractionWeight("mint", 5);
        setInteractionWeight("evolve", 10);
        setInteractionWeight("interact", 2);
        setInteractionWeight("vote", 3);
    }

    // --- 1. Mint NFT ---
    function mintNFT(string memory _baseURI) public whenNotPaused {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);

        // Initialize default NFT attributes
        nftAttributes[tokenId] = NFTAttributes({
            level: 1,
            power: 10,
            agility: 10,
            intelligence: 10,
            vitality: 100
        });

        _setTokenURI(tokenId, _generateTokenURI(tokenId, _baseURI));

        emit NFTMinted(tokenId, msg.sender);
        _updateReputation(msg.sender, interactionWeights["mint"], "NFT Minted");
    }

    // --- 2. Transfer NFT ---
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        safeTransferFrom(ownerOf(_tokenId), _to, _tokenId);
    }

    // --- 3. Token URI ---
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return _tokenURIs[_tokenId];
    }

    function _generateTokenURI(uint256 _tokenId, string memory _baseURI) private view returns (string memory) {
        NFTAttributes memory attributes = nftAttributes[_tokenId];

        string memory metadata = string(abi.encodePacked(
            '{"name": "EvolvingNFT #', _tokenId.toString(), '",',
            '"description": "A Dynamic NFT from the EvolvingNFTCollective.",',
            '"image": "', _baseURI, Strings.toString(_tokenId), '.png",', // Example image URI construction
            '"attributes": [',
                '{"trait_type": "Level", "value": "', attributes.level.toString(), '"},',
                '{"trait_type": "Power", "value": "', attributes.power.toString(), '"},',
                '{"trait_type": "Agility", "value": "', attributes.agility.toString(), '"},',
                '{"trait_type": "Intelligence", "value": "', attributes.intelligence.toString(), '"},',
                '{"trait_type": "Vitality", "value": "', attributes.vitality.toString(), '"}]',
            '}'
        ));

        string memory json = string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(bytes(metadata))
        ));
        return json;
    }

    // --- 4. Get NFT Attributes ---
    function getNFTAttributes(uint256 _tokenId) public view returns (NFTAttributes memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftAttributes[_tokenId];
    }

    // --- 5. Evolve Attribute ---
    function evolveAttribute(uint256 _tokenId, string memory _attributeName) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(isEvolvableAttribute[_attributeName], "Attribute is not evolvable");

        NFTAttributes storage attributes = nftAttributes[_tokenId];
        uint256 changeRate = getBaseAttributeChangeRate(_attributeName); // Get base rate

        // --- Example Evolution Logic (Can be customized based on attribute and game rules) ---
        if (keccak256(bytes(_attributeName)) == keccak256(bytes("level"))) {
            attributes.level += changeRate;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("power"))) {
            attributes.power += changeRate;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("agility"))) {
            attributes.agility += changeRate;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("intelligence"))) {
            attributes.intelligence += changeRate;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("vitality"))) {
            attributes.vitality += changeRate;
        } else {
            revert("Unknown attribute for evolution");
        }

        _setTokenURI(_tokenId, _generateTokenURI(_tokenId, _tokenURIs[_tokenId])); // Update token URI to reflect changes

        emit AttributeEvolved(_tokenId, _attributeName, _getAttributeValue(_tokenId, _attributeName));
        _updateReputation(msg.sender, interactionWeights["evolve"], "Attribute Evolved");
    }

    function _getAttributeValue(uint256 _tokenId, string memory _attributeName) private view returns (uint256) {
        NFTAttributes memory attributes = nftAttributes[_tokenId];
        if (keccak256(bytes(_attributeName)) == keccak256(bytes("level"))) {
            return attributes.level;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("power"))) {
            return attributes.power;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("agility"))) {
            return attributes.agility;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("intelligence"))) {
            return attributes.intelligence;
        } else if (keccak256(bytes(_attributeName)) == keccak256(bytes("vitality"))) {
            return attributes.vitality;
        }
        return 0; // Default, should not reach here if attribute is properly checked
    }


    // --- 6. Interact with NFT ---
    function interactWithNFT(uint256 _tokenId, string memory _interactionType) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        // Add more complex interaction logic here - e.g., based on interactionType, update NFT attributes or trigger events
        emit InteractionRecorded(_tokenId, msg.sender, _interactionType);
        _updateReputation(msg.sender, interactionWeights["interact"], string(abi.encodePacked("NFT Interaction: ", _interactionType)));
    }

    // --- 7. Set Base Attribute Change Rate (Admin) ---
    function setBaseAttributeChangeRate(string memory _attributeName, uint256 _rate) public onlyOwner {
        require(isEvolvableAttribute[_attributeName], "Attribute is not evolvable");
        baseAttributeChangeRates[_attributeName] = _rate;
        emit AttributeChangeRateSet(_attributeName, _rate);
    }

    // --- 8. Get Base Attribute Change Rate ---
    function getBaseAttributeChangeRate(string memory _attributeName) public view returns (uint256) {
        return baseAttributeChangeRates[_attributeName];
    }

    // --- 9. Get Reputation ---
    function getReputation(address _user) public view returns (uint256) {
        return userReputations[_user];
    }

    // --- Reputation Update Function ---
    function _updateReputation(address _user, uint256 _amount, string memory _reason) private {
        userReputations[_user] += _amount;
        emit ReputationChanged(_user, userReputations[_user], _reason);
    }

    // --- 10. Create Proposal ---
    function createProposal(string memory _title, string memory _description, bytes memory _calldata) public whenNotPaused {
        require(userReputations[msg.sender] > 100, "Insufficient reputation to create proposal"); // Example reputation threshold
        proposals.push(Proposal({
            id: proposals.length,
            title: _title,
            description: _description,
            proposer: msg.sender,
            calldata: _calldata,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            state: ProposalState.Active
        }));
        emit ProposalCreated(proposals.length - 1, msg.sender, _title);
    }

    // --- 11. Vote on Proposal ---
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(_proposalId < proposals.length, "Proposal ID does not exist");
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(userReputations[msg.sender] > 0, "No reputation to vote"); // Require some reputation to vote

        Proposal storage proposal = proposals[_proposalId];
        // Simple voting - can be made more sophisticated (e.g., weighted voting based on reputation)
        if (_support) {
            proposal.votesFor += userReputations[msg.sender]; // Simple: 1 reputation point = 1 vote
        } else {
            proposal.votesAgainst += userReputations[msg.sender];
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    // --- 12. Execute Proposal (Admin/Governance) ---
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        require(_proposalId < proposals.length, "Proposal ID does not exist");
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        uint256 totalReputation = _getTotalReputation(); // Calculate total reputation in the system
        uint256 quorumThreshold = (totalReputation * proposalQuorum) / 100;

        if (proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst && proposals[_proposalId].votesFor >= quorumThreshold) {
            proposals[_proposalId].state = ProposalState.Passed;
            (bool success, ) = address(this).call(proposals[_proposalId].calldata); // Execute proposal calldata
            if (success) {
                proposals[_proposalId].state = ProposalState.Executed;
                proposals[_proposalId].executed = true;
                emit ProposalExecuted(_proposalId);
            } else {
                proposals[_proposalId].state = ProposalState.Failed; // Execution failed
            }
        } else {
            proposals[_proposalId].state = ProposalState.Failed; // Not enough votes or votes against won
        }
    }

    function _getTotalReputation() private view returns (uint256) {
        uint256 totalReputation = 0;
        address[] memory users = _getUsersWithReputation(); // Get list of users with reputation (implementation needed)
        for (uint256 i = 0; i < users.length; i++) {
            totalReputation += userReputations[users[i]];
        }
        return totalReputation;
    }

    // --- 13. Get Proposal State ---
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        require(_proposalId < proposals.length, "Proposal ID does not exist");
        return proposals[_proposalId].state;
    }

    // --- 14. Set Contract Paused (Admin) ---
    function setContractPaused(bool _paused) public onlyOwner {
        contractPaused = _paused;
        emit ContractPaused(_paused);
    }

    // --- 15. Is Attribute Evolvable ---
    function isAttributeEvolvable(string memory _attributeName) public view returns (bool) {
        return isEvolvableAttribute[_attributeName];
    }

    // --- 16. Add Evolvable Attribute (Admin) ---
    function addEvolvableAttribute(string memory _attributeName, uint256 _baseRate) public onlyOwner {
        require(!isEvolvableAttribute[_attributeName], "Attribute already evolvable");
        isEvolvableAttribute[_attributeName] = true;
        baseAttributeChangeRates[_attributeName] = _baseRate;
        emit EvolvableAttributeAdded(_attributeName, _baseRate);
    }

    // --- 17. Remove Evolvable Attribute (Admin) ---
    function removeEvolvableAttribute(string memory _attributeName) public onlyOwner {
        require(isEvolvableAttribute[_attributeName], "Attribute is not evolvable");
        delete isEvolvableAttribute[_attributeName];
        delete baseAttributeChangeRates[_attributeName];
        emit EvolvableAttributeRemoved(_attributeName);
    }

    // --- 18. Get NFT Count ---
    function getNFTCount() public view returns (uint256) {
        return _tokenIds.current();
    }

    // --- 19. Supports Interface ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- 20. Withdraw Contract Balance (Admin) ---
    function withdrawContractBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // --- 21. Set Interaction Weight (Admin) ---
    function setInteractionWeight(string memory _interactionType, uint256 _weight) public onlyOwner {
        interactionWeights[_interactionType] = _weight;
        emit InteractionWeightSet(_interactionType, _weight);
    }

    // --- 22. Get Interaction Weight ---
    function getInteractionWeight(string memory _interactionType) public view returns (uint256) {
        return interactionWeights[_interactionType];
    }


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    // --- Placeholder function - Implementation needed for _getTotalReputation Quorum Calculation ---
    function _getUsersWithReputation() private view returns (address[] memory) {
        // In a real implementation, you would need a way to track users who have earned reputation.
        // This could be done by maintaining a separate mapping of users with reputation or iterating
        // through all events and building a list. For simplicity in this example, it's a placeholder.
        return new address[](0); // Placeholder -  Return empty array for now.
    }
}
```