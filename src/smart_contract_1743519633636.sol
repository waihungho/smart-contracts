```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Skill-Based NFT System
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic reputation and skill-based NFT system.
 *
 * **Outline and Function Summary:**
 *
 * **Core Concepts:**
 * - **Skill-Based NFTs:** NFTs that represent skills or achievements.
 * - **Dynamic Metadata:** NFT metadata (like name, description, image) can change based on on-chain reputation/skill level.
 * - **Reputation Points:**  Users earn reputation points for various actions and contributions within the system.
 * - **Skill Levels:**  Skills associated with NFTs can have levels that are influenced by reputation and potentially external verification.
 * - **Community Governance (Basic):**  Simple proposal and voting mechanism for certain system parameters.
 * - **Oracle Integration (Conceptual):** Placeholder for potential integration with external data oracles.
 *
 * **Functions (20+):**
 *
 * **NFT Management (Minting & Transfer):**
 * 1. `mintSkillNFT(string memory _skillName)`: Mints a new Skill NFT for the caller, associated with a skill name.
 * 2. `transferSkillNFT(address _to, uint256 _tokenId)`: Transfers a Skill NFT to another address. (Standard ERC721 function)
 * 3. `getSkillNFTMetadata(uint256 _tokenId)`: Returns the current dynamic metadata URI for a Skill NFT.
 * 4. `getSkillName(uint256 _tokenId)`: Returns the skill name associated with a Skill NFT.
 * 5. `getSkillLevel(uint256 _tokenId)`: Returns the current skill level of a Skill NFT.
 *
 * **Reputation Management:**
 * 6. `earnReputation(address _user, uint256 _amount)`: Allows the contract owner (or designated roles) to award reputation points to a user.
 * 7. `burnReputation(address _user, uint256 _amount)`: Allows the contract owner (or designated roles) to deduct reputation points from a user.
 * 8. `getUserReputation(address _user)`: Returns the current reputation points of a user.
 * 9. `contributeToSkillPool(string memory _skillName)`: Allows users to contribute ETH to a skill-specific reward pool, increasing potential reputation gains related to that skill.
 * 10. `withdrawSkillPoolFunds(string memory _skillName)`:  Allows the contract owner to withdraw funds from a skill's reward pool (potentially for development or community rewards).
 *
 * **Skill Level & Dynamic NFT Updates:**
 * 11. `updateSkillLevel(uint256 _tokenId, uint8 _newLevel)`: Allows the contract owner (or designated roles) to manually update the skill level of an NFT.
 * 12. `autoLevelUp(uint256 _tokenId)`:  Automatically increases the skill level of an NFT based on the owner's reputation (with level limits).
 * 13. `setBaseMetadataURI(string memory _baseURI)`:  Sets the base URI for NFT metadata.
 * 14. `setSkillLevelThresholds(uint8 _level, uint256 _reputationThreshold)`: Sets the reputation threshold required to reach a specific skill level for auto-leveling.
 * 15. `getSkillLevelThreshold(uint8 _level)`: Returns the reputation threshold for a given skill level.
 *
 * **Community Governance (Basic Proposal & Voting):**
 * 16. `proposeNewSkill(string memory _skillName)`: Allows users to propose a new skill to be added to the system.
 * 17. `voteForSkillProposal(uint256 _proposalId, bool _vote)`: Allows users to vote for or against a skill proposal.
 * 18. `enactSkillProposal(uint256 _proposalId)`: Allows the contract owner to enact an approved skill proposal, adding it to the system.
 * 19. `getSkillProposalStatus(uint256 _proposalId)`: Returns the status of a skill proposal (pending, approved, rejected).
 *
 * **Admin & Utility Functions:**
 * 20. `setReputationAuthority(address _authority)`: Sets the address authorized to grant/burn reputation points.
 * 21. `pauseContract()`:  Pauses certain contract functionalities (e.g., minting, reputation updates).
 * 22. `unpauseContract()`: Resumes paused functionalities.
 * 23. `withdrawContractBalance()`: Allows the contract owner to withdraw any ETH held by the contract.
 * 24. `setOracleAddress(address _oracle)`: Sets the address of an external oracle contract (placeholder for future integration).
 */

contract DynamicReputationNFT {
    // --- State Variables ---

    string public contractName = "Dynamic Reputation Skill NFT";
    string public contractSymbol = "DRSNFT";
    address public owner;
    address public reputationAuthority; // Address authorized to grant/burn reputation
    address public oracleAddress; // Placeholder for oracle integration

    uint256 public nextTokenId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public skillNames;
    mapping(uint256 => uint8) public skillLevels;
    mapping(address => uint256) public userReputation;
    mapping(string => bool) public validSkills; // Track valid skill names
    mapping(uint8 => uint256) public skillLevelThresholds; // Reputation needed for each skill level
    string public baseMetadataURI;

    // Skill Proposal System
    uint256 public nextProposalId = 1;
    struct SkillProposal {
        string skillName;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool enacted;
        bool exists;
    }
    mapping(uint256 => SkillProposal) public skillProposals;
    uint256 public proposalVoteDuration = 7 days; // Example vote duration
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Track votes per proposal and user

    mapping(string => uint256) public skillPoolBalances; // ETH pool for each skill

    bool public paused = false;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, string skillName);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event ReputationEarned(address user, uint256 amount);
    event ReputationBurned(address user, uint256 amount);
    event SkillLevelUpdated(uint256 tokenId, uint8 oldLevel, uint8 newLevel);
    event BaseMetadataURISet(string newBaseURI);
    event SkillLevelThresholdSet(uint8 level, uint256 threshold);
    event NewSkillProposed(uint256 proposalId, string skillName, address proposer);
    event SkillProposalVoted(uint256 proposalId, address voter, bool vote);
    event SkillProposalEnacted(uint256 proposalId, string skillName);
    event ContractPaused();
    event ContractUnpaused();
    event FundsWithdrawn(address recipient, uint256 amount);
    event SkillPoolContribution(string skillName, address contributor, uint256 amount);
    event SkillPoolWithdrawal(string skillName, address recipient, uint256 amount);
    event OracleAddressSet(address newOracleAddress);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyReputationAuthority() {
        require(msg.sender == reputationAuthority, "Only reputation authority can call this function.");
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


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        reputationAuthority = msg.sender; // Initially, owner is also reputation authority
        baseMetadataURI = "ipfs://defaultBaseURI/"; // Set a default base URI
        // Initialize some default skill level thresholds (example)
        skillLevelThresholds[1] = 100;
        skillLevelThresholds[2] = 500;
        skillLevelThresholds[3] = 1500;
        skillLevelThresholds[4] = 3000;
        skillLevelThresholds[5] = 5000;

        // Initialize some valid skills (example)
        validSkills["Coding"] = true;
        validSkills["Art"] = true;
        validSkills["Writing"] = true;
    }

    // --- NFT Management Functions ---

    /**
     * @dev Mints a new Skill NFT associated with a given skill name.
     * @param _skillName The name of the skill associated with the NFT.
     */
    function mintSkillNFT(string memory _skillName) external whenNotPaused {
        require(validSkills[_skillName], "Invalid skill name."); // Ensure skill is valid
        uint256 tokenId = nextTokenId++;
        nftOwner[tokenId] = msg.sender;
        skillNames[tokenId] = _skillName;
        skillLevels[tokenId] = 1; // Initial skill level is 1
        emit NFTMinted(tokenId, msg.sender, _skillName);
    }

    /**
     * @dev Transfers ownership of an NFT. (Standard ERC721-like transfer)
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferSkillNFT(address _to, uint256 _tokenId) external whenNotPaused {
        require(nftOwner[_tokenId] == msg.sender, "Not NFT owner.");
        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    /**
     * @dev Returns the dynamic metadata URI for a given Skill NFT.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function getSkillNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return string(abi.encodePacked(baseMetadataURI, "/", _tokenId, ".json")); // Simple dynamic metadata URI
        // In a real application, metadata generation would be more complex and might involve off-chain services.
        // Could include skill name, skill level, visual representation based on level, etc.
    }

    /**
     * @dev Returns the skill name associated with an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The skill name string.
     */
    function getSkillName(uint256 _tokenId) external view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return skillNames[_tokenId];
    }

    /**
     * @dev Returns the current skill level of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The skill level (uint8).
     */
    function getSkillLevel(uint256 _tokenId) external view returns (uint8) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return skillLevels[_tokenId];
    }


    // --- Reputation Management Functions ---

    /**
     * @dev Awards reputation points to a user. Only callable by the reputation authority.
     * @param _user The address of the user to award reputation to.
     * @param _amount The amount of reputation points to award.
     */
    function earnReputation(address _user, uint256 _amount) external onlyReputationAuthority whenNotPaused {
        userReputation[_user] += _amount;
        emit ReputationEarned(_user, _amount);
    }

    /**
     * @dev Burns (deducts) reputation points from a user. Only callable by the reputation authority.
     * @param _user The address of the user to burn reputation from.
     * @param _amount The amount of reputation points to burn.
     */
    function burnReputation(address _user, uint256 _amount) external onlyReputationAuthority whenNotPaused {
        require(userReputation[_user] >= _amount, "Not enough reputation to burn.");
        userReputation[_user] -= _amount;
        emit ReputationBurned(_user, _amount);
    }

    /**
     * @dev Returns the current reputation points of a user.
     * @param _user The address of the user.
     * @return The user's reputation points.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Allows users to contribute ETH to a skill-specific reward pool.
     * @param _skillName The name of the skill to contribute to.
     */
    function contributeToSkillPool(string memory _skillName) external payable whenNotPaused {
        require(validSkills[_skillName], "Invalid skill name.");
        skillPoolBalances[_skillName] += msg.value;
        emit SkillPoolContribution(_skillName, msg.sender, msg.value);
    }

    /**
     * @dev Allows the contract owner to withdraw funds from a skill's reward pool.
     * @param _skillName The name of the skill to withdraw funds from.
     */
    function withdrawSkillPoolFunds(string memory _skillName) external onlyOwner whenNotPaused {
        require(validSkills[_skillName], "Invalid skill name.");
        uint256 balance = skillPoolBalances[_skillName];
        skillPoolBalances[_skillName] = 0; // Reset balance after withdrawal
        payable(owner).transfer(balance);
        emit SkillPoolWithdrawal(_skillName, owner, balance);
    }


    // --- Skill Level & Dynamic NFT Updates ---

    /**
     * @dev Allows the contract owner (or designated roles) to manually update the skill level of an NFT.
     * @param _tokenId The ID of the NFT to update.
     * @param _newLevel The new skill level to set.
     */
    function updateSkillLevel(uint256 _tokenId, uint8 _newLevel) external onlyOwner whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        uint8 oldLevel = skillLevels[_tokenId];
        skillLevels[_tokenId] = _newLevel;
        emit SkillLevelUpdated(_tokenId, oldLevel, _newLevel);
    }

    /**
     * @dev Automatically increases the skill level of an NFT based on the owner's reputation.
     * @param _tokenId The ID of the NFT to level up.
     */
    function autoLevelUp(uint256 _tokenId) external whenNotPaused {
        require(nftOwner[_tokenId] == msg.sender, "Not NFT owner.");
        uint8 currentLevel = skillLevels[_tokenId];
        require(currentLevel < 5, "Max skill level reached."); // Example max level 5

        uint256 reputationNeeded = skillLevelThresholds[currentLevel + 1];
        if (userReputation[msg.sender] >= reputationNeeded) {
            uint8 newLevel = currentLevel + 1;
            skillLevels[_tokenId] = newLevel;
            emit SkillLevelUpdated(_tokenId, currentLevel, newLevel);
        } else {
            revert("Not enough reputation to level up.");
        }
    }

    /**
     * @dev Sets the base URI for NFT metadata. Only callable by the contract owner.
     * @param _baseURI The new base metadata URI.
     */
    function setBaseMetadataURI(string memory _baseURI) external onlyOwner {
        baseMetadataURI = _baseURI;
        emit BaseMetadataURISet(_baseURI);
    }

    /**
     * @dev Sets the reputation threshold required to reach a specific skill level for auto-leveling.
     * @param _level The skill level.
     * @param _reputationThreshold The reputation points required.
     */
    function setSkillLevelThresholds(uint8 _level, uint256 _reputationThreshold) external onlyOwner {
        skillLevelThresholds[_level] = _reputationThreshold;
        emit SkillLevelThresholdSet(_level, _reputationThreshold);
    }

    /**
     * @dev Returns the reputation threshold for a given skill level.
     * @param _level The skill level.
     * @return The reputation threshold.
     */
    function getSkillLevelThreshold(uint8 _level) external view returns (uint256) {
        return skillLevelThresholds[_level];
    }


    // --- Community Governance (Basic Proposal & Voting) ---

    /**
     * @dev Allows users to propose a new skill to be added to the system.
     * @param _skillName The name of the skill to propose.
     */
    function proposeNewSkill(string memory _skillName) external whenNotPaused {
        require(!validSkills[_skillName], "Skill already exists.");
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");

        SkillProposal storage proposal = skillProposals[nextProposalId];
        proposal.skillName = _skillName;
        proposal.proposer = msg.sender;
        proposal.exists = true; // Mark proposal as existing

        emit NewSkillProposed(nextProposalId, _skillName, msg.sender);
        nextProposalId++;
    }

    /**
     * @dev Allows users to vote for or against a skill proposal.
     * @param _proposalId The ID of the skill proposal.
     * @param _vote True to vote for, false to vote against.
     */
    function voteForSkillProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(skillProposals[_proposalId].exists, "Proposal does not exist.");
        require(!skillProposals[_proposalId].enacted, "Proposal already enacted.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true; // Record vote

        if (_vote) {
            skillProposals[_proposalId].votesFor++;
        } else {
            skillProposals[_proposalId].votesAgainst++;
        }
        emit SkillProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Allows the contract owner to enact an approved skill proposal, adding it to the system.
     * @param _proposalId The ID of the skill proposal.
     */
    function enactSkillProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(skillProposals[_proposalId].exists, "Proposal does not exist.");
        require(!skillProposals[_proposalId].enacted, "Proposal already enacted.");

        SkillProposal storage proposal = skillProposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast."); // Ensure votes were cast
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected by votes."); // Simple majority for approval

        validSkills[proposal.skillName] = true; // Add the new skill to valid skills
        proposal.enacted = true;
        emit SkillProposalEnacted(_proposalId, proposal.skillName);
    }

    /**
     * @dev Returns the status of a skill proposal.
     * @param _proposalId The ID of the skill proposal.
     * @return The status string ("pending", "approved", "rejected", "enacted", "not found").
     */
    function getSkillProposalStatus(uint256 _proposalId) external view returns (string memory) {
        if (!skillProposals[_proposalId].exists) {
            return "not found";
        } else if (skillProposals[_proposalId].enacted) {
            return "enacted";
        } else if (skillProposals[_proposalId].votesFor > skillProposals[_proposalId].votesAgainst && (skillProposals[_proposalId].votesFor + skillProposals[_proposalId].votesAgainst) > 0) {
            return "approved"; // Assuming simple majority for approval
        } else if ((skillProposals[_proposalId].votesFor + skillProposals[_proposalId].votesAgainst) > 0) {
            return "rejected";
        } else {
            return "pending";
        }
    }


    // --- Admin & Utility Functions ---

    /**
     * @dev Sets the address authorized to grant/burn reputation points. Only callable by the contract owner.
     * @param _authority The address of the new reputation authority.
     */
    function setReputationAuthority(address _authority) external onlyOwner {
        reputationAuthority = _authority;
        // No event emitted for simplicity, but should be in production.
    }

    /**
     * @dev Pauses certain contract functionalities. Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Resumes paused contract functionalities. Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Allows the contract owner to withdraw any ETH held by the contract.
     */
    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

    /**
     * @dev Sets the address of an external oracle contract (placeholder for future integration).
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    // --- Fallback and Receive (Optional, for receiving ETH) ---
    receive() external payable {}
    fallback() external payable {}
}
```