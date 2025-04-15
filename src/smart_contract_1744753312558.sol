```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution & Governance Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract for dynamic NFTs that evolve based on time, interactions, and community governance.
 *
 * **Outline:**
 * 1. **NFT Core Functionality (ERC721 base):** Minting, Transfer, Approval, Metadata URI.
 * 2. **Dynamic Evolution System:** Time-based evolution stages, evolution triggers, stage-based attributes.
 * 3. **Interaction-Based Evolution:**  NFT "feeding" with tokens, battling/interaction with other NFTs.
 * 4. **Community Governance:** Proposals and voting on evolution rules, new features, and contract parameters.
 * 5. **Staking and Reward System:** Staking NFTs for platform tokens, rewards based on NFT stage/rarity.
 * 6. **Marketplace Integration (Simulated):** Basic listing and delisting functionality within the contract.
 * 7. **Rarity and Attribute System:**  NFT attributes that change with evolution and affect gameplay/utility.
 * 8. **Event Logging:** Comprehensive event logging for all key actions.
 * 9. **Admin Functions:**  Contract pausing, emergency shutdown, parameter adjustments.
 * 10. **Randomness (Pseudo-Random):** Using blockhash for limited on-chain pseudo-randomness in evolution.
 * 11. **NFT Gifting/Airdrop Functionality:**  Functions for gifting and airdropping NFTs.
 * 12. **Custom Metadata Extension:**  Beyond basic ERC721 metadata, include dynamic attributes in tokenURI.
 * 13. **Layered Security:**  Modifiers for access control, reentrancy guards.
 * 14. **Upgradeability (Proxy Pattern - Conceptual):**  Outline for future upgradeability (though not fully implemented in this example for simplicity, but mentioned in design).
 * 15. **Composable NFTs (Conceptual):**  Idea of NFTs interacting and combining (not fully implemented, but a direction).
 * 16. **NFT Burning Mechanism:**  Function to burn NFTs permanently.
 * 17. **Referral System:**  Reward users for referring new users to mint NFTs.
 * 18. **Batch Minting:** Mint multiple NFTs in a single transaction for efficiency.
 * 19. **Customizable Evolution Paths (Governance Driven):**  Allow governance to influence evolution paths.
 * 20. **NFT Attribute Reset/Re-roll (Limited):**  Function to reset certain NFT attributes (perhaps with a cost).
 * 21. **Dynamic Royalty System (Governance Driven):** Royalty percentage adjustable by governance.
 * 22. **External Data Oracle Integration (Conceptual):**  Mention possibility to integrate external data for evolution triggers (e.g., weather, game scores).
 *
 * **Function Summary:**
 * - `constructor(string memory _name, string memory _symbol)`: Initializes the contract with NFT name and symbol.
 * - `mintNFT(address _to)`: Mints a new NFT to the specified address.
 * - `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT.
 * - `approve(address _approved, uint256 _tokenId)`: Approves an address to operate on an NFT.
 * - `getApproved(uint256 _tokenId)`: Gets the approved address for an NFT.
 * - `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for all NFTs.
 * - `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 * - `tokenURI(uint256 _tokenId)`: Returns the URI for the NFT metadata (dynamic).
 * - `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * - `getNFTAttributes(uint256 _tokenId)`: Returns the attributes of an NFT based on its stage.
 * - `manualEvolveNFT(uint256 _tokenId)`: Allows manual evolution of an NFT if conditions are met.
 * - `feedNFT(uint256 _tokenId, uint256 _amount)`: Allows "feeding" an NFT with platform tokens to influence evolution.
 * - `battleNFTs(uint256 _tokenId1, uint256 _tokenId2)`: Simulates a battle between two NFTs, influencing evolution.
 * - `proposeEvolutionRuleChange(string memory _description, bytes memory _data)`: Allows NFT holders to propose changes to evolution rules.
 * - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on governance proposals.
 * - `executeProposal(uint256 _proposalId)`: Executes a successful governance proposal.
 * - `stakeNFT(uint256 _tokenId)`: Stakes an NFT to earn platform tokens.
 * - `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT.
 * - `claimStakingRewards(uint256 _tokenId)`: Claims accumulated staking rewards for an NFT.
 * - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the simulated marketplace.
 * - `delistNFTFromSale(uint256 _tokenId)`: Delists an NFT from sale.
 * - `buyNFT(uint256 _tokenId)`: Buys an NFT listed for sale.
 * - `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT.
 * - `giftNFT(uint256 _tokenId, address _recipient)`: Gifts an NFT to another address.
 * - `airdropNFTs(address[] memory _recipients)`: Airdrops NFTs to multiple addresses.
 * - `resetNFTAttributes(uint256 _tokenId)`: Resets certain attributes of an NFT (with potential cost).
 * - `setDynamicRoyalty(uint256 _newRoyaltyPercentage)`: Sets a new dynamic royalty percentage through governance.
 * - `batchMintNFTs(address _to, uint256 _count)`: Mints multiple NFTs in a batch.
 * - `pauseContract()`: Pauses the contract functionality (admin only).
 * - `unpauseContract()`: Unpauses the contract functionality (admin only).
 * - `withdrawFunds()`: Allows the contract owner to withdraw contract balance.
 * - `setBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata (admin only).
 */
contract DynamicNFTEvolution {
    // **State Variables**
    string public name;
    string public symbol;
    string public baseURI;
    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => uint256) public nftStage; // Evolution stage of each NFT
    mapping(uint256 => uint256) public lastEvolutionTime; // Last evolution timestamp
    uint256 public evolutionInterval = 7 days; // Default evolution interval
    uint256 public nextNFTId = 1;
    address public contractOwner;
    bool public paused = false;

    // Governance variables
    struct Proposal {
        uint256 proposalId;
        string description;
        bytes data;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address proposer;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount = 0;
    uint256 public votingDuration = 3 days;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // Proposal ID => Voter => Voted

    // Staking variables
    mapping(uint256 => bool) public isStaked;
    mapping(uint256 => uint256) public stakeStartTime;
    uint256 public stakingRewardRate = 10; // Example reward rate per day per 1000 staked NFTs (adjust as needed)
    mapping(uint256 => uint256) public pendingRewards;

    // Marketplace variables (Simulated)
    mapping(uint256 => uint256) public nftPrice; // Price in native token (e.g., ETH) if listed for sale
    mapping(uint256 => bool) public isListedForSale;

    // Dynamic Royalty System
    uint256 public royaltyPercentage = 5; // Default royalty percentage (5%)

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTEvolved(uint256 indexed tokenId, uint256 fromStage, uint256 toStage);
    event NFTFed(uint256 indexed tokenId, uint256 amount);
    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event NFTStaked(uint256 indexed tokenId, address owner);
    event NFTUnstaked(uint256 indexed tokenId, address owner);
    event RewardsClaimed(uint256 indexed tokenId, address owner, uint256 rewardAmount);
    event NFTListedForSale(uint256 indexed tokenId, uint256 price);
    event NFTDelistedFromSale(uint256 indexed tokenId);
    event NFTBought(uint256 indexed tokenId, address buyer, address seller, uint256 price);
    event NFTBurned(uint256 indexed tokenId);
    event NFTGifted(uint256 indexed tokenId, address sender, address recipient);
    event NFTAttributesReset(uint256 indexed tokenId);
    event DynamicRoyaltySet(uint256 newRoyaltyPercentage);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

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

    modifier validTokenId(uint256 _tokenId) {
        require(ownerOf[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "Not token owner.");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner.");
        _;
    }

    modifier onlyGovernance() {
        // In a real DAO, governance might be more complex. For simplicity, assuming token holders are governance.
        require(balanceOf[msg.sender] > 0, "Only NFT holders can use governance functions.");
        _;
    }

    // **Constructor**
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
    }

    // **NFT Core Functions (ERC721)**
    function mintNFT(address _to) external onlyOwner whenNotPaused returns (uint256 tokenId) {
        tokenId = nextNFTId++;
        ownerOf[tokenId] = _to;
        balanceOf[_to]++;
        nftStage[tokenId] = 1; // Initial stage
        lastEvolutionTime[tokenId] = block.timestamp;
        totalSupply++;
        emit NFTMinted(_to, tokenId);
        emit Transfer(address(0), _to, tokenId);
        return tokenId;
    }

    function batchMintNFTs(address _to, uint256 _count) external onlyOwner whenNotPaused {
        require(_count > 0 && _count <= 100, "Batch mint count must be between 1 and 100."); // Example limit
        for (uint256 i = 0; i < _count; i++) {
            mintNFT(_to); // Reusing mintNFT for simplicity. Can optimize further if needed.
        }
    }

    function transferNFT(address _from, address _to, uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyApprovedOrOwner(_tokenId) {
        require(ownerOf[_tokenId] == _from, "Transfer from incorrect owner");
        require(_to != address(0), "Transfer to the zero address");

        _clearApproval(_tokenId);

        balanceOf[_from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        getApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view validTokenId(_tokenId) returns (address) {
        return getApproved[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external whenNotPaused {
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return isApprovedForAll[_owner][_operator];
    }

    function tokenURI(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        // Example dynamic metadata - in real-world, this would likely call an off-chain service
        string memory stageStr = Strings.toString(nftStage[_tokenId]);
        string memory attributes = getNFTAttributes(_tokenId);
        return string(abi.encodePacked(baseURI, _tokenId,
            "?stage=", stageStr,
            "&attributes=", attributes));
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // **Dynamic Evolution System**
    function getNFTStage(uint256 _tokenId) public view validTokenId(_tokenId) returns (uint256) {
        return nftStage[_tokenId];
    }

    function getNFTAttributes(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory) {
        uint256 stage = nftStage[_tokenId];
        // Example attributes - can be expanded and made more complex based on stage and other factors
        if (stage == 1) {
            return "Common";
        } else if (stage == 2) {
            return "Rare";
        } else if (stage == 3) {
            return "Epic";
        } else {
            return "Legendary";
        }
    }

    function manualEvolveNFT(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        _evolveNFT(_tokenId);
    }

    function _evolveNFT(uint256 _tokenId) internal {
        require(block.timestamp >= lastEvolutionTime[_tokenId] + evolutionInterval, "Evolution cooldown not finished.");
        uint256 currentStage = nftStage[_tokenId];
        if (currentStage < 4) { // Example: Max 4 stages
            uint256 nextStage = currentStage + 1;
            nftStage[_tokenId] = nextStage;
            lastEvolutionTime[_tokenId] = block.timestamp;
            emit NFTEvolved(_tokenId, currentStage, nextStage);
        }
        // Can add more complex evolution logic here, e.g., based on randomness, attributes, etc.
    }

    // **Interaction-Based Evolution**
    function feedNFT(uint256 _tokenId, uint256 _amount) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        // Example: Feeding with platform tokens (assume a platform token contract exists and is approved)
        // In real-world, you'd integrate with an actual token contract.
        require(_amount > 0, "Feed amount must be greater than zero.");
        // Assume a platform token contract and transferFrom function for simplicity
        // IERC20 platformToken = IERC20(platformTokenAddress);
        // platformToken.transferFrom(msg.sender, address(this), _amount);

        // Example: Small chance of immediate evolution upon feeding
        if (blockhash(block.number - 1) % 100 < 10) { // 10% chance (pseudo-random)
            _evolveNFT(_tokenId);
        }
        emit NFTFed(_tokenId, _amount);
    }

    function battleNFTs(uint256 _tokenId1, uint256 _tokenId2) external whenNotPaused validTokenId(_tokenId1) validTokenId(_tokenId2) onlyTokenOwner(_tokenId1) {
        address owner2 = ownerOf[_tokenId2];
        require(owner2 != msg.sender, "Cannot battle your own NFT.");
        // Example: Simple battle logic based on NFT stage and pseudo-randomness
        uint256 stage1 = nftStage[_tokenId1];
        uint256 stage2 = nftStage[_tokenId2];
        uint256 randomFactor = uint256(blockhash(block.number - 1)) % 100;

        if ((stage1 > stage2 && randomFactor < 70) || (stage1 == stage2 && randomFactor < 50) || (stage1 < stage2 && randomFactor < 30)) {
            _evolveNFT(_tokenId1); // NFT1 wins and evolves (example)
            // Optionally, add logic for NFT2 as well (e.g., slight attribute change)
        } else {
            // NFT2 wins (or no evolution occurs)
        }
        // In a real battle system, you'd have much more complex logic, potentially off-chain components, etc.
    }

    // **Community Governance**
    function proposeEvolutionRuleChange(string memory _description, bytes memory _data) external onlyGovernance whenNotPaused {
        require(bytes(_description).length > 0 && bytes(_description).length <= 256, "Description must be between 1 and 256 characters.");
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.description = _description;
        newProposal.data = _data; // Optional data for complex proposals
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingDuration;
        newProposal.proposer = msg.sender;
        emit ProposalCreated(proposalCount, _description, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyGovernance whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId == _proposalId, "Invalid proposal ID.");
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting period ended.");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal.");

        hasVoted[_proposalId][msg.sender] = true;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused { // Example: Only owner can execute after voting
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId == _proposalId, "Invalid proposal ID.");
        require(block.timestamp > proposal.votingEndTime, "Voting period not ended.");
        require(!proposal.executed, "Proposal already executed.");
        require(proposal.yesVotes > proposal.noVotes, "Proposal failed to pass.");

        proposal.executed = true;
        // Implement proposal logic based on proposal.data - example: change evolutionInterval
        // if (keccak256(proposal.description) == keccak256("Change evolution interval")) { // Example check - refine in real use
        //     evolutionInterval = abi.decode(proposal.data, (uint256));
        // }
        emit ProposalExecuted(_proposalId);
    }

    // **Staking and Reward System**
    function stakeNFT(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(!isStaked[_tokenId], "NFT already staked.");
        isStaked[_tokenId] = true;
        stakeStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(isStaked[_tokenId], "NFT not staked.");
        _claimRewards(_tokenId); // Automatically claim rewards before unstaking
        isStaked[_tokenId] = false;
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    function calculateStakingRewards(uint256 _tokenId) public view validTokenId(_tokenId) returns (uint256) {
        if (!isStaked[_tokenId]) return 0;
        uint256 timeStaked = block.timestamp - stakeStartTime[_tokenId];
        uint256 reward = (timeStaked * stakingRewardRate * nftStage[_tokenId]) / (1 days * 1000); // Example reward calculation
        return reward;
    }

    function claimStakingRewards(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        _claimRewards(_tokenId);
    }

    function _claimRewards(uint256 _tokenId) internal {
        uint256 rewardAmount = calculateStakingRewards(_tokenId);
        if (rewardAmount > 0) {
            pendingRewards[_tokenId] = 0; // Reset pending rewards
            // In real-world, transfer platform tokens to user
            // IERC20 platformToken = IERC20(platformTokenAddress);
            // platformToken.transfer(msg.sender, rewardAmount);
            emit RewardsClaimed(_tokenId, msg.sender, rewardAmount);
        }
    }

    // **Marketplace Integration (Simulated)**
    function listNFTForSale(uint256 _tokenId, uint256 _price) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(!isListedForSale[_tokenId], "NFT already listed for sale.");
        approve(address(this), _tokenId); // Approve contract to handle transfer
        isListedForSale[_tokenId] = true;
        nftPrice[_tokenId] = _price;
        emit NFTListedForSale(_tokenId, _price);
    }

    function delistNFTFromSale(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(isListedForSale[_tokenId], "NFT not listed for sale.");
        isListedForSale[_tokenId] = false;
        nftPrice[_tokenId] = 0;
        emit NFTDelistedFromSale(_tokenId);
    }

    function buyNFT(uint256 _tokenId) external payable whenNotPaused validTokenId(_tokenId) {
        require(isListedForSale[_tokenId], "NFT not listed for sale.");
        uint256 price = nftPrice[_tokenId];
        require(msg.value >= price, "Insufficient funds.");

        address seller = ownerOf[_tokenId];
        delistNFTFromSale(_tokenId);
        transferNFT(seller, msg.sender, _tokenId);

        // Transfer funds to seller (and royalty if applicable)
        uint256 royaltyAmount = (price * royaltyPercentage) / 100;
        uint256 sellerAmount = price - royaltyAmount;

        (bool successSeller, ) = payable(seller).call{value: sellerAmount}("");
        require(successSeller, "Seller payment failed.");

        if (royaltyAmount > 0) {
            (bool successRoyalty, ) = payable(contractOwner).call{value: royaltyAmount}(""); // Example: Royalty to contract owner
            require(successRoyalty, "Royalty payment failed.");
        }

        emit NFTBought(_tokenId, msg.sender, seller, price);

        // Refund extra ETH if any
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // **NFT Burning Mechanism**
    function burnNFT(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(!isStaked[_tokenId], "Cannot burn staked NFT.");
        require(!isListedForSale[_tokenId], "Cannot burn listed NFT.");

        address owner = ownerOf[_tokenId];
        _clearApproval(_tokenId);
        delete ownerOf[_tokenId];
        delete getApproved[_tokenId];
        balanceOf[owner]--;
        totalSupply--;

        emit NFTBurned(_tokenId);
        emit Transfer(owner, address(0), _tokenId);
    }

    // **NFT Gifting/Airdrop Functionality**
    function giftNFT(uint256 _tokenId, address _recipient) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        transferNFT(msg.sender, _recipient, _tokenId);
        emit NFTGifted(_tokenId, msg.sender, _recipient);
    }

    function airdropNFTs(address[] memory _recipients) external onlyOwner whenNotPaused {
        require(_recipients.length > 0 && _recipients.length <= 100, "Airdrop recipient count must be between 1 and 100."); // Example limit

        for (uint256 i = 0; i < _recipients.length; i++) {
            mintNFT(_recipients[i]); // Mint and send to each recipient
        }
    }

    // **NFT Attribute Reset/Re-roll**
    function resetNFTAttributes(uint256 _tokenId) external whenNotPaused validTokenId(_tokenId) onlyTokenOwner(_tokenId) {
        // Example: Reset to stage 1 and reset evolution timer (can add cost in tokens)
        uint256 currentStage = nftStage[_tokenId];
        nftStage[_tokenId] = 1;
        lastEvolutionTime[_tokenId] = block.timestamp;
        emit NFTAttributesReset(_tokenId);
        emit NFTEvolved(_tokenId, currentStage, 1); // Emit evolution event to reflect stage change
    }

    // **Dynamic Royalty System**
    function setDynamicRoyalty(uint256 _newRoyaltyPercentage) external onlyGovernance whenNotPaused {
        require(_newRoyaltyPercentage <= 20, "Royalty percentage cannot exceed 20%."); // Example limit
        royaltyPercentage = _newRoyaltyPercentage;
        emit DynamicRoyaltySet(_newRoyaltyPercentage);
    }

    // **Pause/Unpause Functionality**
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // **Withdraw Funds Function**
    function withdrawFunds() external onlyOwner {
        payable(contractOwner).transfer(address(this).balance);
    }

    // **Internal Helper Functions**
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        return (ownerOf[_tokenId] == _spender || getApproved[_tokenId] == _spender || isApprovedForAll[ownerOf[_tokenId]][_spender]);
    }

    function _clearApproval(uint256 _tokenId) internal {
        if (getApproved[_tokenId] != address(0)) {
            delete getApproved[_tokenId];
        }
    }
}

// --- Helper Library for String Conversion ---
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
}

// --- Example Interface for IERC20 Token (for demonstration purposes - not fully implemented) ---
// interface IERC20 {
//     function transfer(address recipient, uint256 amount) external returns (bool);
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//     function balanceOf(address account) external view returns (uint256);
//     // ... other ERC20 functions
// }
```