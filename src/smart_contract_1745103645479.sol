```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Skill-Based NFT Contract
 * @author Bard (Example Contract - Not for Production Use)
 * @dev A smart contract implementing a dynamic NFT system where NFTs represent user reputation and skills.
 *      NFTs can evolve based on on-chain and off-chain verifiable actions, skill endorsements, and community governance.
 *      This contract incorporates advanced concepts like dynamic metadata, skill-based traits, reputation tracking,
 *      decentralized skill endorsements, and a basic governance mechanism for NFT evolution.
 *
 * Function Summary:
 * -----------------
 * **Core NFT Functions:**
 * 1. mintNFT(address _recipient, string _initialSkillSet) - Mints a new Reputation NFT to the recipient with an initial skill set.
 * 2. transferNFT(address _to, uint256 _tokenId) - Transfers ownership of an NFT.
 * 3. tokenURI(uint256 _tokenId) - Returns the dynamic metadata URI for an NFT, reflecting its current traits and reputation.
 * 4. getOwnerOfNFT(uint256 _tokenId) - Returns the owner of a specific NFT.
 * 5. getTotalNFTsMinted() - Returns the total number of NFTs minted.
 *
 * **Skill and Trait Management:**
 * 6. addSkill(uint256 _tokenId, string _skill) - Adds a new skill to an NFT's skill set (requires endorsement or governance).
 * 7. endorseSkill(uint256 _tokenId, string _skill, address _endorser) - Allows an address to endorse a specific skill for an NFT, increasing its reputation in that skill.
 * 8. getNFTSkills(uint256 _tokenId) - Returns the list of skills associated with an NFT.
 * 9. getSkillEndorsements(uint256 _tokenId, string _skill) - Returns the number of endorsements for a specific skill of an NFT.
 * 10. evolveNFTTraits(uint256 _tokenId) - Triggers an evolution process for an NFT based on its accumulated skills and endorsements.
 * 11. setBaseURI(string _baseURI) - Sets the base URI for the dynamic metadata.
 *
 * **Reputation and Leveling System:**
 * 12. getNFTReputationScore(uint256 _tokenId) - Calculates and returns the reputation score of an NFT based on skills and endorsements.
 * 13. getNFTLevel(uint256 _tokenId) - Determines the level of an NFT based on its reputation score.
 * 14. reputationThresholdForLevel(uint256 _level) - Returns the reputation score threshold required to reach a specific level.
 *
 * **Governance and Community Features:**
 * 15. proposeSkillAddition(uint256 _tokenId, string _skill) - Allows users to propose adding a new skill to an NFT through a governance process.
 * 16. voteOnSkillProposal(uint256 _proposalId, bool _vote) - Allows community members to vote on skill addition proposals.
 * 17. executeSkillProposal(uint256 _proposalId) - Executes a successful skill addition proposal, adding the skill to the NFT.
 * 18. getProposalDetails(uint256 _proposalId) - Returns details of a specific skill addition proposal.
 * 19. setGovernanceThreshold(uint256 _threshold) - Sets the threshold of votes required for a proposal to pass.
 *
 * **Admin Functions:**
 * 20. pauseContract() - Pauses certain functionalities of the contract.
 * 21. unpauseContract() - Resumes paused functionalities.
 * 22. withdrawContractBalance() - Allows the contract owner to withdraw contract balance (if any).
 * 23. setContractOwner(address _newOwner) - Changes the contract owner.
 */

contract DynamicReputationNFT {
    // State Variables
    string public contractName = "DynamicReputationNFT";
    string public contractSymbol = "DRNFT";
    string public baseURI; // Base URI for dynamic metadata
    uint256 public totalSupply; // Total number of NFTs minted
    uint256 public nextProposalId; // Counter for proposal IDs
    uint256 public governanceThreshold = 50; // Percentage threshold for proposal approval (e.g., 50% for simple majority)
    bool public paused = false;
    address public contractOwner;

    mapping(uint256 => address) public nftOwner; // Token ID to owner address
    mapping(address => uint256[]) public ownerNFTs; // Owner address to list of token IDs
    mapping(uint256 => string[]) public nftSkills; // Token ID to list of skills
    mapping(uint256 => mapping(string => uint256)) public skillEndorsements; // Token ID, Skill to Endorsement Count
    mapping(uint256 => Proposal) public skillProposals; // Proposal ID to Proposal details
    mapping(uint256 => uint256) public nftReputationScore; // Token ID to Reputation Score
    mapping(uint256 => uint256) public levelThresholds; // Level to Reputation Threshold

    // Structs
    struct Proposal {
        uint256 tokenId;
        string skill;
        address proposer;
        uint256 upVotes;
        uint256 downVotes;
        bool executed;
    }

    // Enums
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // Events
    event NFTMinted(uint256 tokenId, address recipient);
    event NFTSkillAdded(uint256 tokenId, string skill, address addedBy);
    event NFTSkillEndorsed(uint256 tokenId, string skill, address endorser);
    event NFTTraitsEvolved(uint256 tokenId);
    event SkillProposalCreated(uint256 proposalId, uint256 tokenId, string skill, address proposer);
    event SkillProposalVoted(uint256 proposalId, address voter, bool vote);
    event SkillProposalExecuted(uint256 proposalId);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event ContractOwnerChanged(address oldOwner, address newOwner);
    event BalanceWithdrawn(address owner, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
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

    // Constructor
    constructor(string memory _baseURI) {
        contractOwner = msg.sender;
        baseURI = _baseURI;
        // Define initial level thresholds (can be modified later through governance if needed)
        levelThresholds[1] = 100;
        levelThresholds[2] = 300;
        levelThresholds[3] = 700;
        levelThresholds[4] = 1500;
        levelThresholds[5] = 3000;
    }

    // ------------------------ Core NFT Functions ------------------------

    /**
     * @dev Mints a new Reputation NFT to the recipient with an initial skill set.
     * @param _recipient The address to receive the NFT.
     * @param _initialSkillSet A comma-separated string of initial skills.
     */
    function mintNFT(address _recipient, string memory _initialSkillSet) public whenNotPaused {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        totalSupply++;
        uint256 newTokenId = totalSupply;

        nftOwner[newTokenId] = _recipient;
        ownerNFTs[_recipient].push(newTokenId);

        // Add initial skills
        string[] memory skills = split(_initialSkillSet, ',');
        for (uint256 i = 0; i < skills.length; i++) {
            string memory skill = trim(skills[i]);
            if (bytes(skill).length > 0) { // Ensure not empty after trim
                nftSkills[newTokenId].push(skill);
            }
        }

        emit NFTMinted(newTokenId, _recipient);
    }

    /**
     * @dev Transfers ownership of an NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        require(_to != address(0), "Transfer to address cannot be zero.");
        require(nftOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");

        address previousOwner = nftOwner[_tokenId];
        nftOwner[_tokenId] = _to;

        // Update ownerNFTs mapping - remove from previous owner, add to new owner
        removeNFTFromOwnerList(previousOwner, _tokenId);
        ownerNFTs[_to].push(_tokenId);

        // No transfer event needed as standard ERC721 transfer events are handled by libraries in real implementations.
    }

    /**
     * @dev Returns the dynamic metadata URI for an NFT, reflecting its current traits and reputation.
     * @param _tokenId The ID of the NFT.
     * @return string The URI for the NFT metadata.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");

        // Construct dynamic JSON metadata based on NFT's skills, endorsements, reputation, level, etc.
        string memory metadata = generateNFTMetadata(_tokenId);
        string memory jsonMetadata = string(abi.encodePacked('data:application/json;base64,', base64Encode(bytes(metadata))));
        return string(abi.encodePacked(baseURI, jsonMetadata));
    }

    /**
     * @dev Returns the owner of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return address The owner address.
     */
    function getOwnerOfNFT(uint256 _tokenId) public view returns (address) {
        return nftOwner[_tokenId];
    }

    /**
     * @dev Returns the total number of NFTs minted.
     * @return uint256 Total NFT count.
     */
    function getTotalNFTsMinted() public view returns (uint256) {
        return totalSupply;
    }

    // ------------------------ Skill and Trait Management ------------------------

    /**
     * @dev Adds a new skill to an NFT's skill set (requires endorsement or governance).
     * @param _tokenId The ID of the NFT to add the skill to.
     * @param _skill The skill to add.
     */
    function addSkill(uint256 _tokenId, string memory _skill) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(!hasSkill(_tokenId, _skill), "NFT already has this skill.");

        // For demonstration - simpler skill addition. In a real system, you would likely require
        // endorsement count to reach a threshold or governance approval to directly add a skill.
        nftSkills[_tokenId].push(_skill);
        emit NFTSkillAdded(_tokenId, _skill, msg.sender);
        evolveNFTTraits(_tokenId); // Trigger evolution after skill addition
    }

    /**
     * @dev Allows an address to endorse a specific skill for an NFT, increasing its reputation in that skill.
     * @param _tokenId The ID of the NFT being endorsed.
     * @param _skill The skill being endorsed.
     * @param _endorser The address doing the endorsement (can be msg.sender or another account).
     */
    function endorseSkill(uint256 _tokenId, string memory _skill, address _endorser) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(hasSkill(_tokenId, _skill), "NFT does not have this skill to endorse.");
        require(_endorser != address(0), "Endorser address cannot be zero.");
        require(_endorser != nftOwner[_tokenId], "Owner cannot endorse their own NFT."); // Optional: prevent self-endorsement

        skillEndorsements[_tokenId][_skill]++;
        emit NFTSkillEndorsed(_tokenId, _skill, _endorser);
        evolveNFTTraits(_tokenId); // Trigger evolution after endorsement
    }

    /**
     * @dev Returns the list of skills associated with an NFT.
     * @param _tokenId The ID of the NFT.
     * @return string[] An array of skills.
     */
    function getNFTSkills(uint256 _tokenId) public view returns (string[] memory) {
        return nftSkills[_tokenId];
    }

    /**
     * @dev Returns the number of endorsements for a specific skill of an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _skill The skill to query endorsements for.
     * @return uint256 The number of endorsements.
     */
    function getSkillEndorsements(uint256 _tokenId, string memory _skill) public view returns (uint256) {
        return skillEndorsements[_tokenId][_skill];
    }

    /**
     * @dev Triggers an evolution process for an NFT based on its accumulated skills and endorsements.
     *      This is a simplified example. More complex evolution logic can be implemented based on various factors.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFTTraits(uint256 _tokenId) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");

        // Example evolution logic: Increase reputation based on skill endorsements
        uint256 currentReputation = getNFTReputationScore(_tokenId);
        uint256 newReputation = currentReputation;

        for (uint256 i = 0; i < nftSkills[_tokenId].length; i++) {
            string memory skill = nftSkills[_tokenId][i];
            newReputation += skillEndorsements[_tokenId][skill] * 10; // Example: 10 reputation per endorsement
        }

        nftReputationScore[_tokenId] = newReputation;
        emit NFTTraitsEvolved(_tokenId);
    }

    /**
     * @dev Sets the base URI for the dynamic metadata. Only owner can call.
     * @param _baseURI The new base URI.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner whenNotPaused {
        baseURI = _baseURI;
    }


    // ------------------------ Reputation and Leveling System ------------------------

    /**
     * @dev Calculates and returns the reputation score of an NFT based on skills and endorsements.
     *      This is a simplified calculation. Can be customized with weighted skills, etc.
     * @param _tokenId The ID of the NFT.
     * @return uint256 The reputation score.
     */
    function getNFTReputationScore(uint256 _tokenId) public view returns (uint256) {
        uint256 reputation = 0;
        for (uint256 i = 0; i < nftSkills[_tokenId].length; i++) {
            string memory skill = nftSkills[_tokenId][i];
            reputation += 50; // Base reputation per skill
            reputation += skillEndorsements[_tokenId][skill] * 5; // Reputation per endorsement
        }
        return reputation;
    }

    /**
     * @dev Determines the level of an NFT based on its reputation score.
     * @param _tokenId The ID of the NFT.
     * @return uint256 The NFT level.
     */
    function getNFTLevel(uint256 _tokenId) public view returns (uint256) {
        uint256 reputation = getNFTReputationScore(_tokenId);
        if (reputation >= levelThresholds[5]) return 5;
        if (reputation >= levelThresholds[4]) return 4;
        if (reputation >= levelThresholds[3]) return 3;
        if (reputation >= levelThresholds[2]) return 2;
        if (reputation >= levelThresholds[1]) return 1;
        return 0; // Level 0 if below level 1 threshold
    }

    /**
     * @dev Returns the reputation score threshold required to reach a specific level.
     * @param _level The level to check.
     * @return uint256 The reputation threshold.
     */
    function reputationThresholdForLevel(uint256 _level) public view returns (uint256) {
        return levelThresholds[_level];
    }

    // ------------------------ Governance and Community Features ------------------------

    /**
     * @dev Allows users to propose adding a new skill to an NFT through a governance process.
     * @param _tokenId The ID of the NFT to add the skill to.
     * @param _skill The skill to propose adding.
     */
    function proposeSkillAddition(uint256 _tokenId, string memory _skill) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(!hasSkill(_tokenId, _skill), "NFT already has this skill.");

        uint256 proposalId = nextProposalId++;
        skillProposals[proposalId] = Proposal({
            tokenId: _tokenId,
            skill: _skill,
            proposer: msg.sender,
            upVotes: 0,
            downVotes: 0,
            executed: false
        });

        emit SkillProposalCreated(proposalId, _tokenId, _skill, msg.sender);
    }

    /**
     * @dev Allows community members to vote on skill addition proposals.
     *      For simplicity, anyone can vote. In a real DAO, voting might be restricted to token holders, etc.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnSkillProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(skillProposals[_proposalId].tokenId != 0, "Proposal does not exist.");
        require(!skillProposals[_proposalId].executed, "Proposal already executed.");

        if (_vote) {
            skillProposals[_proposalId].upVotes++;
        } else {
            skillProposals[_proposalId].downVotes++;
        }
        emit SkillProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a successful skill addition proposal, adding the skill to the NFT if it passes governance threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeSkillProposal(uint256 _proposalId) public whenNotPaused {
        require(skillProposals[_proposalId].tokenId != 0, "Proposal does not exist.");
        require(!skillProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = skillProposals[_proposalId].upVotes + skillProposals[_proposalId].downVotes;
        require(totalVotes > 0, "No votes cast on this proposal.");

        uint256 upVotePercentage = (skillProposals[_proposalId].upVotes * 100) / totalVotes;

        if (upVotePercentage >= governanceThreshold) {
            addSkill(skillProposals[_proposalId].tokenId, skillProposals[_proposalId].skill);
            skillProposals[_proposalId].executed = true;
            emit SkillProposalExecuted(_proposalId);
        } else {
            skillProposals[_proposalId].executed = true; // Mark as executed even if rejected to prevent re-execution
            // Optionally emit a ProposalRejected event if needed
        }
    }

    /**
     * @dev Returns details of a specific skill addition proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal Proposal details struct.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return skillProposals[_proposalId];
    }

    /**
     * @dev Sets the governance threshold for proposal approval. Only owner can call.
     * @param _threshold The new governance threshold percentage (e.g., 50 for 50%).
     */
    function setGovernanceThreshold(uint256 _threshold) public onlyOwner whenNotPaused {
        require(_threshold <= 100, "Governance threshold cannot exceed 100%.");
        governanceThreshold = _threshold;
    }


    // ------------------------ Admin Functions ------------------------

    /**
     * @dev Pauses certain functionalities of the contract. Only owner can call.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Resumes paused functionalities. Only owner can call.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw contract balance (if any).
     *      Useful in case of accidental ETH sent to the contract.
     */
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        payable(contractOwner).transfer(balance);
        emit BalanceWithdrawn(contractOwner, balance);
    }

    /**
     * @dev Changes the contract owner. Only current owner can call.
     * @param _newOwner The address of the new owner.
     */
    function setContractOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner address cannot be zero.");
        emit ContractOwnerChanged(contractOwner, _newOwner);
        contractOwner = _newOwner;
    }


    // ------------------------ Internal Helper Functions ------------------------

    /**
     * @dev Checks if an NFT has a specific skill.
     * @param _tokenId The ID of the NFT.
     * @param _skill The skill to check for.
     * @return bool True if NFT has the skill, false otherwise.
     */
    function hasSkill(uint256 _tokenId, string memory _skill) internal view returns (bool) {
        for (uint256 i = 0; i < nftSkills[_tokenId].length; i++) {
            if (keccak256(bytes(nftSkills[_tokenId][i])) == keccak256(bytes(_skill))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Removes an NFT token ID from an owner's NFT list.
     * @param _owner The owner address.
     * @param _tokenId The NFT token ID to remove.
     */
    function removeNFTFromOwnerList(address _owner, uint256 _tokenId) internal {
        uint256[] storage tokens = ownerNFTs[_owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenId) {
                tokens[i] = tokens[tokens.length - 1]; // Move last element to current position
                tokens.pop(); // Remove last element (duplicate)
                break;
            }
        }
    }

    /**
     * @dev Generates dynamic JSON metadata for an NFT based on its current state.
     * @param _tokenId The ID of the NFT.
     * @return string JSON metadata string.
     */
    function generateNFTMetadata(uint256 _tokenId) internal view returns (string memory) {
        string memory name = string(abi.encodePacked(contractName, " #", Strings.toString(_tokenId)));
        string memory description = "A Dynamic Reputation and Skill-Based NFT.";

        string memory skillsList = "[";
        for (uint256 i = 0; i < nftSkills[_tokenId].length; i++) {
            skillsList = string(abi.encodePacked(skillsList, '"', nftSkills[_tokenId][i], '"'));
            if (i < nftSkills[_tokenId].length - 1) {
                skillsList = string(abi.encodePacked(skillsList, ","));
            }
        }
        skillsList = string(abi.encodePacked(skillsList, "]"));

        string memory endorsementsData = "{";
        bool firstEndorsement = true;
        for (uint256 i = 0; i < nftSkills[_tokenId].length; i++) {
            string memory skill = nftSkills[_tokenId][i];
            if (skillEndorsements[_tokenId][skill] > 0) {
                if (!firstEndorsement) {
                    endorsementsData = string(abi.encodePacked(endorsementsData, ","));
                }
                endorsementsData = string(abi.encodePacked(endorsementsData, '"', skill, '": ', Strings.toString(skillEndorsements[_tokenId][skill])));
                firstEndorsement = false;
            }
        }
        endorsementsData = string(abi.encodePacked(endorsementsData, "}"));

        string memory level = Strings.toString(getNFTLevel(_tokenId));
        string memory reputation = Strings.toString(getNFTReputationScore(_tokenId));

        string memory metadata = string(abi.encodePacked(
            '{',
                '"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "ipfs://your_ipfs_image_cid_here.png",', // Replace with your image CID or dynamic image generation logic
                '"attributes": [',
                    '{ "trait_type": "Level", "value": ', level, ' },',
                    '{ "trait_type": "Reputation Score", "value": ', reputation, ' },',
                    '{ "trait_type": "Skills", "value": ', skillsList, ' },',
                    '{ "trait_type": "Skill Endorsements", "value": ', endorsementsData, ' }',
                ']',
            '}'
        ));
        return metadata;
    }

    /**
     * @dev Splits a string by a delimiter.
     * @param _str The string to split.
     * @param _delimiter The delimiter character.
     * @return string[] Array of split strings.
     */
    function split(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory delimiterBytes = bytes(_delimiter);
        uint count = 0;
        for (uint i = 0; i < strBytes.length; i++) {
            if (i + delimiterBytes.length <= strBytes.length) {
                bytes memory slice = strBytes[i:i + delimiterBytes.length];
                if (keccak256(slice) == keccak256(delimiterBytes)) {
                    count++;
                }
            }
        }
        string[] memory parts = new string[](count + 1);
        uint j = 0;
        uint k = uint(-1);
        for (uint i = 0; i < strBytes.length; i++) {
            if (i + delimiterBytes.length <= strBytes.length) {
                bytes memory slice = strBytes[i:i + delimiterBytes.length];
                if (keccak256(slice) == keccak256(delimiterBytes)) {
                    parts[j++] = string(strBytes[k + 1:i]);
                    k = i + delimiterBytes.length - 1;
                }
            }
        }
        parts[j] = string(strBytes[k + 1:strBytes.length]);
        return parts;
    }

    /**
     * @dev Removes leading and trailing whitespace from a string.
     * @param _str The string to trim.
     * @return string Trimmed string.
     */
    function trim(string memory _str) internal pure returns (string memory) {
        bytes memory bstr = bytes(_str);
        bytes memory whitespace = " \r\n\t";
        uint start = 0;
        for (; start < bstr.length; start++) {
            bool isWhitespace = false;
            for (uint j = 0; j < whitespace.length; j++) {
                if (bstr[start] == whitespace[j]) {
                    isWhitespace = true;
                    break;
                }
            }
            if (!isWhitespace) break;
        }
        uint end = bstr.length;
        for (; end > start; end--) {
            bool isWhitespace = false;
            for (uint j = 0; j < whitespace.length; j++) {
                if (bstr[end - 1] == whitespace[j]) {
                    isWhitespace = true;
                    break;
                }
            }
            if (!isWhitespace) break;
        }
        return string(bstr[start:end]);
    }

    /**
     * @dev Encodes bytes to base64 string.
     * @param _data Bytes data to encode.
     * @return string Base64 encoded string.
     */
    function base64Encode(bytes memory _data) internal pure returns (string memory) {
        string memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        bytes memory encoded = new bytes(((_data.length + 2) / 3) * 4); // Calculate output length
        uint24 i = 0;
        uint24 j = 0;
        while (i < _data.length) {
            uint24 input = uint24(_data[i++]) << 16;
            if (i < _data.length) input += uint24(_data[i++]) << 8;
            if (i < _data.length) input += uint24(_data[i++]);
            encoded[j++] = bytes1(uint8(alphabet[input >> 18]));
            encoded[j++] = bytes1(uint8(alphabet[(input >> 12) & 0x3F]));
            encoded[j++] = bytes1(uint8(alphabet[(input >> 6) & 0x3F]));
            encoded[j++] = bytes1(uint8(alphabet[input & 0x3F]));
        }
        uint24 paddingLength = (3 - (_data.length % 3)) % 3;
        for (i = 0; i < paddingLength; i++) {
            encoded[bytes(encoded).length - 1 - i] = bytes1(uint8(0x3d)); // '=' character
        }
        return string(encoded);
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // If you have strings of length 32 or less use concatenate instead
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits == 0 ? 1 : digits);
        uint256 index = buffer.length;
        while (value != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        if (digits == 0) {
            buffer[0] = "0";
        }
        return string(buffer);
    }
}
```