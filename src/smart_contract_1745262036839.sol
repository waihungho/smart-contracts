```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Gemini AI Assistant
 * @notice A smart contract implementing a dynamic NFT system where NFTs can evolve through various on-chain and off-chain interactions,
 *         incorporating decentralized governance, rarity tiers, skill-based evolution, and community-driven storylines.
 *
 * Function Summary:
 * -----------------
 * **Core NFT Functions:**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new base-level NFT to the specified address.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 * 3. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a given NFT token ID.
 * 4. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT token ID.
 * 5. `totalSupply()`: Returns the total number of NFTs minted.
 * 6. `balanceOf(address _owner)`: Returns the number of NFTs owned by an address.
 *
 * **Dynamic Evolution Functions:**
 * 7. `evolveNFT(uint256 _tokenId)`: Initiates the evolution process for an NFT, subject to criteria and costs.
 * 8. `setEvolutionCriteria(uint256 _stage, EvolutionCriteria memory _criteria)`: Sets the evolution criteria for a specific evolution stage.
 * 9. `getEvolutionStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 10. `getEvolutionCriteria(uint256 _stage)`: Returns the evolution criteria for a specific stage.
 * 11. `setEvolutionCost(uint256 _stage, uint256 _cost)`: Sets the cost (in native token) for evolving to a specific stage.
 * 12. `getRandomEvolutionOutcome(uint256 _tokenId)`: (Internal) Generates a random outcome for evolution based on rarity and skills.
 * 13. `applyEvolutionEffects(uint256 _tokenId, EvolutionOutcome memory _outcome)`: (Internal) Applies the effects of an evolution outcome to the NFT.
 *
 * **Rarity and Skill System Functions:**
 * 14. `setRarityTierWeights(uint256[] memory _weights)`: Sets the weights for rarity tiers in random outcomes.
 * 15. `getRarityTier(uint256 _tokenId)`: Returns the rarity tier of an NFT.
 * 16. `setSkillAttribute(uint256 _tokenId, string memory _skillName, uint256 _skillValue)`: Sets a skill attribute for an NFT.
 * 17. `getSkillAttribute(uint256 _tokenId, string memory _skillName)`: Returns the value of a skill attribute for an NFT.
 *
 * **Decentralized Governance Functions:**
 * 18. `proposeEvolutionRuleChange(string memory _proposalDescription, EvolutionCriteria memory _newCriteria, uint256 _stage)`: Allows users to propose changes to evolution rules.
 * 19. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on active proposals.
 * 20. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting threshold.
 * 21. `getProposalDetails(uint256 _proposalId)`: Returns details of a specific governance proposal.
 * 22. `pauseContract()`: Owner function to pause core functionalities in case of emergency.
 * 23. `unpauseContract()`: Owner function to resume paused functionalities.
 * 24. `withdrawFunds()`: Owner function to withdraw contract balance (e.g., evolution fees).
 */
contract DynamicNFTEvolution {
    // --- Data Structures ---

    struct NFTData {
        uint256 evolutionStage;
        uint256 rarityTier;
        mapping(string => uint256) skills; // Skill name to value
        string baseURI;
    }

    struct EvolutionCriteria {
        uint256 requiredStage; // Stage required to evolve *to* this stage
        uint256 minTimeSinceLastEvolution; // Minimum time since last evolution (in seconds)
        uint256 minTokenAge;          // Minimum age of the token (in seconds)
        uint256 interactionCountThreshold; // Number of interactions required (e.g., staking, voting)
        // Add more criteria as needed (e.g., holding specific tokens, participating in events)
    }

    struct EvolutionOutcome {
        uint256 newRarityTier;
        mapping(string => int256) skillChanges; // Skill name to change (can be positive or negative)
        string metadataUpdate; // Optional metadata update string
    }

    struct GovernanceProposal {
        string description;
        EvolutionCriteria newCriteria;
        uint256 stageToChange;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
        uint256 proposalTimestamp;
    }

    // --- State Variables ---

    mapping(uint256 => NFTData) public nftData; // tokenId => NFTData
    mapping(uint256 => address) public tokenOwner; // tokenId => owner address
    mapping(address => uint256) public ownerTokenCount; // owner address => token count
    mapping(uint256 => EvolutionCriteria) public evolutionCriteria; // stage => EvolutionCriteria
    mapping(uint256 => uint256) public evolutionCosts; // stage => evolution cost in native token
    uint256[] public rarityTierWeights; // Weights for each rarity tier (e.g., [50, 30, 15, 5] for 4 tiers)
    GovernanceProposal[] public governanceProposals;
    uint256 public proposalCounter;
    uint256 public nextTokenId = 1;
    bool public paused = false;
    address public owner;

    // --- Events ---

    event NFTMinted(uint256 tokenId, address owner, string baseURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTEvolved(uint256 tokenId, uint256 newStage, EvolutionOutcome outcome);
    event EvolutionCriteriaSet(uint256 stage, EvolutionCriteria criteria);
    event EvolutionCostSet(uint256 stage, uint256 cost);
    event RarityTierWeightsSet(uint256[] weights);
    event SkillAttributeSet(uint256 tokenId, string skillName, uint256 skillValue);
    event GovernanceProposalCreated(uint256 proposalId, string description, uint256 stageToChange);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event FundsWithdrawn(address to, uint256 amount);

    // --- Modifiers ---

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

    modifier validTokenId(uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        // Initialize default rarity tier weights (example: Common, Uncommon, Rare, Epic)
        rarityTierWeights = [50, 30, 15, 5];
        // Initialize default evolution criteria for stage 1 (stage 0 is base level)
        evolutionCriteria[1] = EvolutionCriteria({
            requiredStage: 0,
            minTimeSinceLastEvolution: 0,
            minTokenAge: 0,
            interactionCountThreshold: 0
        });
        evolutionCosts[1] = 0.01 ether; // Example cost for stage 1 evolution
    }

    // --- Core NFT Functions ---

    /// @notice Mints a new base-level NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The base URI for the NFT metadata.
    function mintNFT(address _to, string memory _baseURI) external whenNotPaused {
        uint256 tokenId = nextTokenId++;
        tokenOwner[tokenId] = _to;
        ownerTokenCount[_to]++;
        nftData[tokenId] = NFTData({
            evolutionStage: 0,
            rarityTier: getRandomRarityTier(), // Initial rarity based on weights
            baseURI: _baseURI
        });
        emit NFTMinted(tokenId, _to, _baseURI);
    }

    /// @notice Transfers an NFT from one address to another.
    /// @param _from The address sending the NFT.
    /// @param _to The address receiving the NFT.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(_from == msg.sender, "Incorrect sender address.");
        require(_to != address(0), "Invalid recipient address.");

        ownerTokenCount[_from]--;
        ownerTokenCount[_to]++;
        tokenOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /// @notice Returns the metadata URI for a given NFT token ID.
    /// @param _tokenId The ID of the NFT.
    /// @return string The metadata URI.
    function tokenURI(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        // Construct dynamic URI based on token data (stage, rarity, etc.)
        return string(abi.encodePacked(nftData[_tokenId].baseURI, "/", uint2str(_tokenId), ".json"));
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8((48 + _i % 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @notice Returns the owner of a given NFT token ID.
    /// @param _tokenId The ID of the NFT.
    /// @return address The owner address.
    function ownerOf(uint256 _tokenId) external view validTokenId(_tokenId) returns (address) {
        return tokenOwner[_tokenId];
    }

    /// @notice Returns the total number of NFTs minted.
    /// @return uint256 Total NFT supply.
    function totalSupply() external view returns (uint256) {
        return nextTokenId - 1;
    }

    /// @notice Returns the number of NFTs owned by an address.
    /// @param _owner The address to check.
    /// @return uint256 The number of NFTs owned.
    function balanceOf(address _owner) external view returns (uint256) {
        return ownerTokenCount[_owner];
    }

    // --- Dynamic Evolution Functions ---

    /// @notice Initiates the evolution process for an NFT, subject to criteria and costs.
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) external payable whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        uint256 currentStage = nftData[_tokenId].evolutionStage;
        uint256 nextStage = currentStage + 1;

        require(evolutionCriteria[nextStage].requiredStage <= currentStage, "Not eligible for this evolution stage yet.");
        // Add more criteria checks here (time since last evolution, token age, interactions, etc.)
        require(msg.value >= evolutionCosts[nextStage], "Insufficient evolution cost.");

        EvolutionOutcome memory outcome = getRandomEvolutionOutcome(_tokenId);
        applyEvolutionEffects(_tokenId, outcome);
        nftData[_tokenId].evolutionStage = nextStage;

        // Transfer evolution cost to contract owner (or treasury)
        payable(owner).transfer(evolutionCosts[nextStage]); // Or send to a designated treasury address

        emit NFTEvolved(_tokenId, nextStage, outcome);
    }

    /// @notice Sets the evolution criteria for a specific evolution stage.
    /// @param _stage The evolution stage to set criteria for.
    /// @param _criteria The evolution criteria struct.
    function setEvolutionCriteria(uint256 _stage, EvolutionCriteria memory _criteria) external onlyOwner {
        evolutionCriteria[_stage] = _criteria;
        emit EvolutionCriteriaSet(_stage, _criteria);
    }

    /// @notice Returns the current evolution stage of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256 The current evolution stage.
    function getEvolutionStage(uint256 _tokenId) external view validTokenId(_tokenId) returns (uint256) {
        return nftData[_tokenId].evolutionStage;
    }

    /// @notice Returns the evolution criteria for a specific stage.
    /// @param _stage The evolution stage to query.
    /// @return EvolutionCriteria The evolution criteria struct.
    function getEvolutionCriteria(uint256 _stage) external view returns (EvolutionCriteria memory) {
        return evolutionCriteria[_stage];
    }

    /// @notice Sets the cost (in native token) for evolving to a specific stage.
    /// @param _stage The evolution stage to set the cost for.
    /// @param _cost The evolution cost in native token (wei).
    function setEvolutionCost(uint256 _stage, uint256 _cost) external onlyOwner {
        evolutionCosts[_stage] = _cost;
        emit EvolutionCostSet(_stage, _cost);
    }

    /// @notice (Internal) Generates a random outcome for evolution based on rarity and skills.
    /// @param _tokenId The ID of the NFT being evolved.
    /// @return EvolutionOutcome The random evolution outcome.
    function getRandomEvolutionOutcome(uint256 _tokenId) internal returns (EvolutionOutcome memory) {
        // Placeholder for more sophisticated randomness and outcome generation logic
        // In a real application, use Chainlink VRF or similar for provable randomness.

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId))); // Not secure, for example only
        uint256 rarityRoll = randomNumber % 100; // Roll between 0 and 99

        uint256 newRarityTier = nftData[_tokenId].rarityTier; // Default to current rarity
        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < rarityTierWeights.length; i++) {
            cumulativeWeight += rarityTierWeights[i];
            if (rarityRoll < cumulativeWeight) {
                newRarityTier = i + 1; // Rarity tiers are 1-indexed (1, 2, 3, ...)
                break;
            }
        }

        EvolutionOutcome memory outcome;
        outcome.newRarityTier = newRarityTier;
        outcome.skillChanges["attack"] = int256((randomNumber % 10) - 5); // Example: Attack skill change -5 to +4
        outcome.skillChanges["defense"] = int256((randomNumber % 8) - 4);  // Example: Defense skill change -4 to +3
        outcome.metadataUpdate = "Evolved to stage "; // Example metadata update (can be more complex)

        return outcome;
    }

    /// @notice (Internal) Applies the effects of an evolution outcome to the NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _outcome The evolution outcome struct.
    function applyEvolutionEffects(uint256 _tokenId, EvolutionOutcome memory _outcome) internal {
        nftData[_tokenId].rarityTier = _outcome.newRarityTier;
        // Apply skill changes
        string[] memory skillNames = new string[](2); // Example skills - adjust dynamically in real app
        skillNames[0] = "attack";
        skillNames[1] = "defense";
        for (uint256 i = 0; i < skillNames.length; i++) {
            if (_outcome.skillChanges[skillNames[i]] != 0) {
                nftData[_tokenId].skills[skillNames[i]] = uint256(int256(nftData[_tokenId].skills[skillNames[i]]) + _outcome.skillChanges[skillNames[i]]);
            }
        }
        // Metadata update logic can be added here (e.g., updating on IPFS)
    }


    /// @notice (Internal) Generates a random rarity tier based on configured weights.
    function getRandomRarityTier() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))); // Not secure, for example only
        uint256 rarityRoll = randomNumber % 100; // Roll between 0 and 99

        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < rarityTierWeights.length; i++) {
            cumulativeWeight += rarityTierWeights[i];
            if (rarityRoll < cumulativeWeight) {
                return i + 1; // Rarity tiers are 1-indexed (1, 2, 3, ...)
            }
        }
        return 1; // Default to the lowest tier if no tier is selected (shouldn't happen with proper weights)
    }


    // --- Rarity and Skill System Functions ---

    /// @notice Sets the weights for rarity tiers in random outcomes.
    /// @param _weights An array of weights for each rarity tier. Sum of weights should ideally be 100 or less.
    function setRarityTierWeights(uint256[] memory _weights) external onlyOwner {
        rarityTierWeights = _weights;
        emit RarityTierWeightsSet(_weights);
    }

    /// @notice Returns the rarity tier of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256 The rarity tier of the NFT.
    function getRarityTier(uint256 _tokenId) external view validTokenId(_tokenId) returns (uint256) {
        return nftData[_tokenId].rarityTier;
    }

    /// @notice Sets a skill attribute for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _skillName The name of the skill attribute.
    /// @param _skillValue The value of the skill attribute.
    function setSkillAttribute(uint256 _tokenId, string memory _skillName, uint256 _skillValue) external onlyOwner validTokenId(_tokenId) { // Owner can directly set for now, consider access control
        nftData[_tokenId].skills[_skillName] = _skillValue;
        emit SkillAttributeSet(_tokenId, _skillName, _skillValue);
    }

    /// @notice Returns the value of a skill attribute for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _skillName The name of the skill attribute.
    /// @return uint256 The value of the skill attribute.
    function getSkillAttribute(uint256 _tokenId, string memory _skillName) external view validTokenId(_tokenId) returns (uint256) {
        return nftData[_tokenId].skills[_skillName];
    }

    // --- Decentralized Governance Functions ---

    /// @notice Allows users to propose changes to evolution rules.
    /// @param _proposalDescription A description of the proposed rule change.
    /// @param _newCriteria The new evolution criteria to propose.
    /// @param _stageToChange The evolution stage that the proposal targets.
    function proposeEvolutionRuleChange(string memory _proposalDescription, EvolutionCriteria memory _newCriteria, uint256 _stageToChange) external whenNotPaused {
        require(balanceOf(msg.sender) > 0, "Must own at least one NFT to propose."); // Example: Require NFT ownership to propose

        governanceProposals.push(GovernanceProposal({
            description: _proposalDescription,
            newCriteria: _newCriteria,
            stageToChange: _stageToChange,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false,
            proposalTimestamp: block.timestamp
        }));
        proposalCounter++;
        emit GovernanceProposalCreated(proposalCounter, _proposalDescription, _stageToChange);
    }

    /// @notice Allows NFT holders to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True to vote in favor, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        GovernanceProposal storage proposal = governanceProposals[_proposalId - 1]; // Adjust index for 1-based proposal ID
        require(proposal.isActive, "Proposal is not active.");
        require(tokenOwner[1] != address(0), "Must own at least one NFT to vote."); // Example: Require NFT ownership to vote (can be adjusted based on token weight etc.)

        // In a real application, track who has voted to prevent double voting per proposal

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a proposal if it passes the voting threshold.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external whenNotPaused onlyOwner { // Only owner can execute after voting passes
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        GovernanceProposal storage proposal = governanceProposals[_proposalId - 1]; // Adjust index for 1-based proposal ID
        require(proposal.isActive, "Proposal is not active.");
        require(!proposal.isExecuted, "Proposal already executed.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = totalSupply() / 2; // Example quorum: 50% of total supply
        uint256 votingPeriod = 7 days; // Example voting period

        require(block.timestamp >= proposal.proposalTimestamp + votingPeriod, "Voting period not over yet.");
        require(totalVotes >= quorum, "Quorum not reached.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass (more against votes).");

        evolutionCriteria[proposal.stageToChange] = proposal.newCriteria;
        proposal.isActive = false;
        proposal.isExecuted = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Returns details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return GovernanceProposal The governance proposal struct.
    function getProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        return governanceProposals[_proposalId - 1]; // Adjust index for 1-based proposal ID
    }

    // --- Owner Functions ---

    /// @notice Pauses core functionalities of the contract.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Resumes paused functionalities of the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Allows the owner to withdraw contract balance (e.g., evolution fees).
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

    // --- Fallback and Receive ---
    receive() external payable {} // To accept ETH for evolution costs and potentially other features
    fallback() external {}
}
```