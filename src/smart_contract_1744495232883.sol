```solidity
/**
 * @title Dynamic NFT Social Game DAO Contract
 * @author Gemini AI
 * @dev A smart contract showcasing advanced concepts for a dynamic NFT social game governed by a DAO.
 *
 * **Outline & Function Summary:**
 *
 * **1. NFT Management & Dynamic Traits:**
 *   - `mintNFT(string memory _name, string memory _imageUrl, uint8 _initialRarity)`: Mints a new Dynamic NFT with customizable name, image URL, and initial rarity.
 *   - `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 *   - `getNFTMetadata(uint256 _tokenId)`: Retrieves metadata (name, image URL, rarity, dynamic stats) of an NFT.
 *   - `evolveNFT(uint256 _tokenId)`: Allows NFT holders to evolve their NFT, increasing rarity and potentially changing traits based on game mechanics.
 *   - `setAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue)`: Allows setting custom attributes for NFTs (governed by DAO proposal).
 *
 * **2. Social Game Mechanics & Guilds:**
 *   - `createGuild(string memory _guildName, string memory _guildSymbol)`: Allows users to create guilds with unique names and symbols.
 *   - `joinGuild(uint256 _guildId)`: Allows users to join an existing guild.
 *   - `leaveGuild()`: Allows users to leave their current guild.
 *   - `guildContribute(uint256 _guildId, uint256 _amount)`: Allows users to contribute tokens to their guild's treasury.
 *   - `guildAction(uint256 _guildId, string memory _actionType, bytes memory _actionData)`: A generic function to trigger guild-specific actions (e.g., guild quests, events, governed by DAO).
 *
 * **3. DAO Governance & Proposals:**
 *   - `proposeNewParameter(string memory _parameterName, uint256 _newValue)`: Allows DAO members to propose changes to contract parameters (e.g., minting fees, evolution costs).
 *   - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to vote on active proposals.
 *   - `executeProposal(uint256 _proposalId)`: Executes a proposal if it reaches quorum and passes.
 *   - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific DAO proposal.
 *   - `getDAOParameter(string memory _parameterName)`: Retrieves the current value of a DAO-governed parameter.
 *
 * **4. Tokenomics & In-Game Currency (Simplified):**
 *   - `depositTokens(uint256 _amount)`: Allows users to deposit in-game currency (assuming an external token, simplified in this example).
 *   - `withdrawTokens(uint256 _amount)`: Allows users to withdraw in-game currency.
 *   - `getBalance()`: Retrieves the user's in-game currency balance.
 *
 * **5. Utility & Admin Functions:**
 *   - `pauseContract()`: Pauses the contract, restricting certain functionalities (admin-only).
 *   - `unpauseContract()`: Resumes contract functionality (admin-only).
 *   - `setBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata (admin-only).
 *   - `withdrawContractBalance()`: Allows the contract owner to withdraw ETH from the contract balance (admin-only).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol"; // For more advanced DAO, consider Timelock

contract DynamicNFTGameDAO is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- NFT Metadata ---
    string private _baseURI;
    struct NFTMetadata {
        string name;
        string imageUrl;
        uint8 rarity; // Example dynamic trait
        mapping(string => string) attributes; // Dynamic attributes
    }
    mapping(uint256 => NFTMetadata) public nftMetadata;

    // --- Game Parameters (DAO Governed) ---
    mapping(string => uint256) public daoParameters; // Key-value store for parameters
    uint256 public mintFee;
    uint256 public evolutionCost;

    // --- Guilds ---
    struct Guild {
        string name;
        string symbol;
        address leader;
        uint256 treasuryBalance;
        mapping(address => bool) members;
    }
    mapping(uint256 => Guild) public guilds;
    Counters.Counter private _guildIdCounter;
    mapping(address => uint256) public userGuilds; // User address to Guild ID

    // --- DAO Proposals ---
    struct Proposal {
        string parameterName;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public proposalVoteDuration = 7 days; // DAO Governed Parameter
    uint256 public proposalQuorum = 50; // Percentage, DAO Governed Parameter

    // --- In-Game Currency (Simplified - using ETH for example, in real case, would be external ERC20) ---
    mapping(address => uint256) public userBalances;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address minter, string name);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTEvolved(uint256 tokenId, uint8 newRarity);
    event NFTAttributeSet(uint256 tokenId, string attributeName, string attributeValue);
    event GuildCreated(uint256 guildId, string guildName, address leader);
    event GuildJoined(uint256 guildId, address member);
    event GuildLeft(uint256 guildId, address member);
    event GuildContribution(uint256 guildId, address contributor, uint256 amount);
    event DAOProposalCreated(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event DAOProposalVoted(uint256 proposalId, address voter, bool support);
    event DAOProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event BaseURISet(string baseURI, address admin);
    event TokensDeposited(address user, uint256 amount);
    event TokensWithdrawn(address user, uint256 amount);

    constructor(string memory _name, string memory _symbol, string memory _baseUri) ERC721(_name, _symbol) {
        _baseURI = _baseUri;
        mintFee = 0.01 ether; // Initial Minting Fee
        evolutionCost = 0.05 ether; // Initial Evolution Cost
        daoParameters["proposalVoteDuration"] = proposalVoteDuration;
        daoParameters["proposalQuorum"] = proposalQuorum;
    }

    // --- 1. NFT Management & Dynamic Traits ---

    function mintNFT(string memory _name, string memory _imageUrl, uint8 _initialRarity) public payable whenNotPaused {
        require(msg.value >= mintFee, "Insufficient mint fee");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        nftMetadata[tokenId] = NFTMetadata({
            name: _name,
            imageUrl: _imageUrl,
            rarity: _initialRarity
        });

        emit NFTMinted(tokenId, msg.sender, _name);
    }

    function transferNFT(address _to, uint256 _tokenId) public payable whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner");
        safeTransferFrom(msg.sender, _to, _tokenId);
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    function getNFTMetadata(uint256 _tokenId) public view returns (NFTMetadata memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftMetadata[_tokenId];
    }

    function evolveNFT(uint256 _tokenId) public payable whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner");
        require(msg.value >= evolutionCost, "Insufficient evolution cost");
        require(_exists(_tokenId), "NFT does not exist");

        nftMetadata[_tokenId].rarity = nftMetadata[_tokenId].rarity + 1; // Example evolution - increase rarity
        emit NFTEvolved(_tokenId, nftMetadata[_tokenId].rarity);
    }

    function setAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue) public whenNotPaused {
        // Example: DAO could vote to allow setting custom lore or background for NFTs
        // This function would ideally be callable by a DAO-approved role or after a successful proposal.
        // For simplicity, we'll allow owner to set it for now.
        require(owner() == msg.sender, "Only owner can set attributes in this example (DAO controlled in real case)");
        require(_exists(_tokenId), "NFT does not exist");
        nftMetadata[_tokenId].attributes[_attributeName] = _attributeValue;
        emit NFTAttributeSet(_tokenId, _tokenId, _attributeName, _attributeValue);
    }

    // --- 2. Social Game Mechanics & Guilds ---

    function createGuild(string memory _guildName, string memory _guildSymbol) public whenNotPaused {
        require(userGuilds[msg.sender] == 0, "Already in a guild");
        uint256 guildId = _guildIdCounter.current();
        _guildIdCounter.increment();
        guilds[guildId] = Guild({
            name: _guildName,
            symbol: _guildSymbol,
            leader: msg.sender,
            treasuryBalance: 0,
            members: mapping(address => bool)() // Initialize empty members mapping
        });
        guilds[guildId].members[msg.sender] = true; // Leader is automatically a member
        userGuilds[msg.sender] = guildId;
        emit GuildCreated(guildId, _guildName, msg.sender);
    }

    function joinGuild(uint256 _guildId) public whenNotPaused {
        require(userGuilds[msg.sender] == 0, "Already in a guild");
        require(guilds[_guildId].leader != address(0), "Guild does not exist"); // Check if guild exists
        guilds[_guildId].members[msg.sender] = true;
        userGuilds[msg.sender] = _guildId;
        emit GuildJoined(_guildId, msg.sender);
    }

    function leaveGuild() public whenNotPaused {
        uint256 guildId = userGuilds[msg.sender];
        require(guildId != 0, "Not in a guild");
        delete guilds[guildId].members[msg.sender];
        delete userGuilds[msg.sender];
        emit GuildLeft(guildId, msg.sender);
    }

    function guildContribute(uint256 _guildId, uint256 _amount) public payable whenNotPaused {
        require(userGuilds[msg.sender] == _guildId, "Not a member of this guild");
        // In a real case, this would likely involve transferring an external ERC20 token
        // For simplicity, we'll use ETH transfer to the contract as guild treasury.
        require(msg.value >= _amount, "Insufficient contribution amount");
        guilds[_guildId].treasuryBalance += msg.value;
        emit GuildContribution(_guildId, msg.sender, _amount);
    }

    function guildAction(uint256 _guildId, string memory _actionType, bytes memory _actionData) public whenNotPaused {
        require(userGuilds[msg.sender] == _guildId, "Not a member of this guild");
        require(guilds[_guildId].leader == msg.sender, "Only guild leader can initiate actions in this example (DAO controlled in real case)");
        // This is a placeholder for more complex guild actions.
        // _actionType could be "startQuest", "initiateWar", etc.
        // _actionData could contain parameters for the action.
        // In a real game, this would trigger more complex logic based on the action type.
        // Example: if (_actionType == "startQuest") { ... }
        // For now, we just emit an event to show the action was triggered.
        // emit GuildActionTriggered(_guildId, _actionType, _actionData); // Define this event if needed.
        // In a more advanced version, actions could be governed by DAO proposals as well.
        (void)_actionType; // To avoid unused variable warning
        (void)_actionData; // To avoid unused variable warning
        // Add actual logic for guild actions based on _actionType and _actionData in a real application.
    }

    // --- 3. DAO Governance & Proposals ---

    function proposeNewParameter(string memory _parameterName, uint256 _newValue) public whenNotPaused {
        // In a real DAO, you'd have token-weighted voting and more sophisticated membership.
        // For simplicity, anyone can propose in this example.
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();
        proposals[proposalId] = Proposal({
            parameterName: _parameterName,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + daoParameters["proposalVoteDuration"],
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit DAOProposalCreated(proposalId, _parameterName, _newValue, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period is over");

        // In a real DAO, voting power would be based on token holdings or other criteria.
        // For simplicity, each address gets 1 vote in this example.
        // We'd need to track who voted to prevent double voting in a real implementation.

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit DAOProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused onlyOwner { // For simplicity, onlyOwner can execute, in real DAO, it's automatic or timelocked
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "Voting period is not over yet");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorumNeeded = (totalVotes * daoParameters["proposalQuorum"]) / 100; // Calculate quorum based on percentage

        if (proposal.yesVotes >= quorumNeeded) { // Simplified quorum and passing condition
            daoParameters[proposal.parameterName] = proposal.newValue;
            proposal.executed = true;
            emit DAOProposalExecuted(_proposalId, proposal.parameterName, proposal.newValue);
        } else {
            revert("Proposal failed to reach quorum or did not pass");
        }
    }

    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        require(proposals[_proposalId].parameterName != "", "Proposal does not exist"); // Basic check for proposal existence
        return proposals[_proposalId];
    }

    function getDAOParameter(string memory _parameterName) public view returns (uint256) {
        return daoParameters[_parameterName];
    }

    // --- 4. Tokenomics & In-Game Currency (Simplified) ---

    function depositTokens(uint256 _amount) public payable whenNotPaused {
        require(msg.value >= _amount, "Insufficient deposit amount");
        userBalances[msg.sender] += msg.value; // Using ETH as in-game currency for simplicity
        emit TokensDeposited(msg.sender, msg.value);
    }

    function withdrawTokens(uint256 _amount) public whenNotPaused {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        userBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount); // Transfer ETH back
        emit TokensWithdrawn(msg.sender, _amount);
    }

    function getBalance() public view returns (uint256) {
        return userBalances[msg.sender];
    }

    // --- 5. Utility & Admin Functions ---

    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _baseURI = _baseURI;
        emit BaseURISet(_baseURI, msg.sender);
    }

    function withdrawContractBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // --- ERC721 Overrides ---
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURI;
    }

    // --- Pausable Override ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // --- Supports Interface (for ERC721 metadata) ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```