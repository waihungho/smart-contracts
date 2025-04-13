```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation-Based NFT with On-Chain Content Generation and DAO Integration
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This contract implements a dynamic NFT that evolves based on user reputation and incorporates
 *      on-chain content generation, DAO voting for feature upgrades, and advanced tokenomics.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core NFT Functionality (ERC721Enumerable Base):**
 *    - `mint(address to, string memory baseTokenURI)`: Mints a new NFT to the specified address with an initial base token URI.
 *    - `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an NFT.
 *    - `approve(address approved, uint256 tokenId)`: Approves an address to transfer an NFT on behalf of the owner.
 *    - `getApproved(uint256 tokenId)`: Gets the approved address for a specific NFT.
 *    - `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator to manage all NFTs of an owner.
 *    - `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all NFTs of an owner.
 *    - `tokenURI(uint256 tokenId)`: Returns the token URI for a given NFT, dynamically generated based on NFT properties.
 *    - `ownerOf(uint256 tokenId)`: Returns the owner of a given NFT.
 *    - `balanceOf(address owner)`: Returns the balance of NFTs owned by an address.
 *    - `totalSupply()`: Returns the total number of NFTs minted.
 *
 * **2. Reputation System:**
 *    - `increaseReputation(uint256 tokenId, uint256 amount)`: Increases the reputation score of a specific NFT (owner-controlled).
 *    - `decreaseReputation(uint256 tokenId, uint256 amount)`: Decreases the reputation score of a specific NFT (owner-controlled, with limits).
 *    - `getReputation(uint256 tokenId)`: Retrieves the current reputation score of an NFT.
 *    - `getLevelByReputation(uint256 reputationScore)`: Determines the reputation level based on the score.
 *
 * **3. Dynamic Content Generation:**
 *    - `generateOnChainContent(uint256 tokenId)`: Generates dynamic on-chain content for an NFT based on its reputation and other factors.
 *    - `updateNFTContent(uint256 tokenId)`: Updates the NFT's content and token URI based on current properties.
 *
 * **4. DAO Integration & Feature Voting:**
 *    - `proposeFeatureUpgrade(string memory description, bytes memory data)`: Allows NFT holders to propose new feature upgrades to the contract.
 *    - `voteOnProposal(uint256 proposalId, bool support)`: Allows NFT holders to vote on feature upgrade proposals (weighted by reputation).
 *    - `executeProposal(uint256 proposalId)`: Executes a passed proposal, potentially upgrading contract functionality (governance controlled).
 *    - `getProposalDetails(uint256 proposalId)`: Retrieves details of a specific proposal.
 *
 * **5. Advanced Tokenomics & Utility:**
 *    - `stakeNFT(uint256 tokenId)`: Allows NFT holders to stake their NFTs to earn rewards (simulated here).
 *    - `unstakeNFT(uint256 tokenId)`: Allows NFT holders to unstake their NFTs.
 *    - `claimStakingRewards(uint256 tokenId)`: Allows NFT holders to claim accumulated staking rewards (simulated).
 *    - `setBaseURI(string memory newBaseURI)`: Allows the contract owner to update the base URI for metadata.
 *    - `pauseContract()`: Pauses core contract functionalities (owner-only).
 *    - `unpauseContract()`: Unpauses contract functionalities (owner-only).
 *    - `withdrawFunds()`: Allows the contract owner to withdraw any ETH accidentally sent to the contract.
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DynamicReputationNFT is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public baseURI;
    string public contractMetadataURI; // URI for contract-level metadata (e.g., collection info)

    struct NFTProperties {
        uint256 reputationScore;
        string onChainContent; // Dynamically generated content
        uint256 lastContentUpdate;
        bool isStaked;
        uint256 stakingStartTime;
    }

    mapping(uint256 => NFTProperties) public nftProperties;
    Counters.Counter private _tokenIdCounter;

    // Reputation Levels Configuration
    uint256[] public reputationLevels = [100, 500, 1000, 2500, 5000]; // Example levels
    string[] public levelTitles = ["Beginner", "Apprentice", "Initiate", "Master", "Grandmaster"]; // Titles for levels

    // DAO Proposal Struct
    struct Proposal {
        string description;
        bytes data; // Data for execution if proposal passes (e.g., function signature and parameters)
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voters; // Track who voted to prevent double voting
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;

    bool public contractPaused; // Custom pause flag for finer control

    event ReputationIncreased(uint256 tokenId, uint256 amount, uint256 newReputation);
    event ReputationDecreased(uint256 tokenId, uint256 amount, uint256 newReputation);
    event ContentUpdated(uint256 tokenId, string newContent);
    event FeatureProposalCreated(uint256 proposalId, string description);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner);
    event StakingRewardsClaimed(uint256 tokenId, address owner, uint256 rewards);
    event ContractPaused();
    event ContractUnpaused();

    constructor(string memory _name, string memory _symbol, string memory _baseURI, string memory _contractMetadataURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        contractMetadataURI = _contractMetadataURI;
    }

    modifier whenNotPausedContract() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier onlyNFTOwner(uint256 tokenId) {
        require(_isOwner(tokenId, _msgSender()), "You are not the NFT owner");
        _;
    }

    modifier validTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Invalid token ID");
        _;
    }

    /**
     * @dev Mints a new NFT to the specified address.
     * @param to The address to mint the NFT to.
     * @param baseTokenURI The initial base token URI for the NFT.
     */
    function mint(address to, string memory baseTokenURI) public onlyOwner whenNotPausedContract {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        nftProperties[tokenId] = NFTProperties({
            reputationScore: 0,
            onChainContent: generateInitialContent(tokenId), // Generate initial content
            lastContentUpdate: block.timestamp,
            isStaked: false,
            stakingStartTime: 0
        });

        _setTokenURI(tokenId, string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")));
    }

    /**
     * @dev Generates initial on-chain content for a newly minted NFT.
     * @param tokenId The ID of the NFT.
     * @return string The initial content.
     */
    function generateInitialContent(uint256 tokenId) internal pure returns (string memory) {
        // Example: Simple initial content, can be made more complex based on randomness or other factors
        return string(abi.encodePacked("Initial Content for NFT #", tokenId.toString()));
    }

    /**
     * @dev Returns the token URI for a given token ID. Dynamically generates based on NFT properties.
     * @param tokenId The ID of the NFT.
     * @return string The token URI.
     */
    function tokenURI(uint256 tokenId) public view override virtual validTokenId(tokenId) returns (string memory) {
        // Example: Constructing a dynamic JSON data URI directly in the contract (for demonstration).
        // In a real-world scenario, you'd likely use an off-chain service to generate dynamic metadata based on on-chain data.

        string memory name = string(abi.encodePacked(name(), " #", tokenId.toString()));
        string memory description = "A Dynamic Reputation-Based NFT.";
        string memory currentContent = nftProperties[tokenId].onChainContent;
        uint256 reputation = nftProperties[tokenId].reputationScore;
        string memory level = getLevelByReputation(reputation);

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', string(abi.encodePacked(baseURI, tokenId.toString(), ".png")), '",', // Example image URI
            '"attributes": [',
                '{"trait_type": "Reputation", "value": "', reputation.toString(), '"},',
                '{"trait_type": "Reputation Level", "value": "', level, '"},',
                '{"trait_type": "Content", "value": "', currentContent, '"}'
            ']',
            '}'
        ));

        string memory base64 = vm.base64(bytes(json)); // Using Foundry's vm.base64 for base64 encoding in example
        return string(abi.encodePacked('data:application/json;base64,', base64));

        // Note: For production, consider using IPFS or Arweave for metadata storage and off-chain dynamic generation for complex scenarios.
    }

    /**
     * @dev Increases the reputation score of a specific NFT. Owner-controlled action.
     * @param tokenId The ID of the NFT.
     * @param amount The amount to increase the reputation by.
     */
    function increaseReputation(uint256 tokenId, uint256 amount) public onlyNFTOwner(tokenId) whenNotPausedContract validTokenId(tokenId) {
        nftProperties[tokenId].reputationScore += amount;
        emit ReputationIncreased(tokenId, amount, nftProperties[tokenId].reputationScore);
        updateNFTContent(tokenId); // Update content based on reputation change
    }

    /**
     * @dev Decreases the reputation score of a specific NFT. Owner-controlled with limits.
     * @param tokenId The ID of the NFT.
     * @param amount The amount to decrease the reputation by.
     */
    function decreaseReputation(uint256 tokenId, uint256 amount) public onlyNFTOwner(tokenId) whenNotPausedContract validTokenId(tokenId) {
        require(nftProperties[tokenId].reputationScore >= amount, "Reputation cannot be negative");
        nftProperties[tokenId].reputationScore -= amount;
        emit ReputationDecreased(tokenId, amount, nftProperties[tokenId].reputationScore);
        updateNFTContent(tokenId); // Update content based on reputation change
    }

    /**
     * @dev Retrieves the current reputation score of an NFT.
     * @param tokenId The ID of the NFT.
     * @return uint256 The reputation score.
     */
    function getReputation(uint256 tokenId) public view validTokenId(tokenId) returns (uint256) {
        return nftProperties[tokenId].reputationScore;
    }

    /**
     * @dev Determines the reputation level based on the score.
     * @param reputationScore The reputation score.
     * @return string The reputation level title.
     */
    function getLevelByReputation(uint256 reputationScore) public view returns (string memory) {
        for (uint256 i = 0; i < reputationLevels.length; i++) {
            if (reputationScore < reputationLevels[i]) {
                return levelTitles[i > 0 ? i - 1 : 0]; // Return previous level if below current threshold, or Beginner for level 0
            }
        }
        return levelTitles[levelTitles.length - 1]; // Return highest level if above all thresholds
    }

    /**
     * @dev Generates dynamic on-chain content for an NFT based on its reputation and other factors.
     * @param tokenId The ID of the NFT.
     * @return string The generated content.
     */
    function generateOnChainContent(uint256 tokenId) public view validTokenId(tokenId) returns (string memory) {
        uint256 reputation = nftProperties[tokenId].reputationScore;
        string memory level = getLevelByReputation(reputation);

        // Example: Content changes based on reputation level
        if (keccak256(bytes(level)) == keccak256(bytes("Beginner"))) {
            return "This NFT is just starting its journey.";
        } else if (keccak256(bytes(level)) == keccak256(bytes("Apprentice"))) {
            return "This NFT is learning and growing.";
        } else if (keccak256(bytes(level)) == keccak256(bytes("Initiate"))) {
            return "This NFT is becoming more experienced.";
        } else if (keccak256(bytes(level)) == keccak256(bytes("Master"))) {
            return "This NFT is a seasoned veteran.";
        } else { // Grandmaster or above
            return "This NFT is a legend!";
        }
    }

    /**
     * @dev Updates the NFT's content and triggers a token URI refresh.
     * @param tokenId The ID of the NFT.
     */
    function updateNFTContent(uint256 tokenId) public validTokenId(tokenId) {
        nftProperties[tokenId].onChainContent = generateOnChainContent(tokenId);
        nftProperties[tokenId].lastContentUpdate = block.timestamp;
        _setTokenURI(tokenId, tokenURI(tokenId)); // Force token URI refresh
        emit ContentUpdated(tokenId, nftProperties[tokenId].onChainContent);
    }

    // ---- DAO Integration & Feature Voting ----

    /**
     * @dev Allows NFT holders to propose new feature upgrades to the contract.
     * @param description A description of the proposed feature.
     * @param data Encoded data for the feature upgrade (e.g., function call data).
     */
    function proposeFeatureUpgrade(string memory description, bytes memory data) public whenNotPausedContract {
        require(balanceOf(_msgSender()) > 0, "You must own at least one NFT to propose a feature.");

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();
        proposals[proposalId] = Proposal({
            description: description,
            data: data,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            voters: mapping(address => bool)()
        });

        emit FeatureProposalCreated(proposalId, description);
    }

    /**
     * @dev Allows NFT holders to vote on feature upgrade proposals. Voting power is weighted by NFT reputation.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPausedContract {
        require(balanceOf(_msgSender()) > 0, "You must own at least one NFT to vote.");
        require(!proposals[proposalId].executed, "Proposal has already been executed");
        require(!proposals[proposalId].voters[_msgSender()], "You have already voted on this proposal.");

        uint256 votingPower = 0;
        uint256 balance = balanceOf(_msgSender());
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            votingPower += nftProperties[tokenId].reputationScore; // Voting power based on reputation sum of all NFTs owned
        }

        if (support) {
            proposals[proposalId].votesFor += votingPower;
        } else {
            proposals[proposalId].votesAgainst += votingPower;
        }
        proposals[proposalId].voters[_msgSender()] = true; // Mark voter as voted

        emit VoteCast(proposalId, _msgSender(), support);
    }

    /**
     * @dev Executes a passed proposal if it has enough votes. Owner-controlled for now (can be more decentralized).
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public onlyOwner whenNotPausedContract {
        require(!proposals[proposalId].executed, "Proposal has already been executed");
        require(proposals[proposalId].votesFor > proposals[proposalId].votesAgainst, "Proposal does not have enough votes to pass"); // Simple majority

        proposals[proposalId].executed = true;
        // Example: Execute the proposal data - This is a placeholder and needs careful security considerations in a real implementation.
        // (e.g., restrict executable data, use delegatecall with caution, consider timelocks, etc.)
        (bool success,) = address(this).delegatecall(proposals[proposalId].data);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Retrieves details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct containing proposal details.
     */
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        return proposals[proposalId];
    }

    // ---- Advanced Tokenomics & Utility ----

    uint256 public stakingRewardRate = 1; // Example: 1 reward unit per block per NFT staked (adjust as needed)

    /**
     * @dev Allows NFT holders to stake their NFTs.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) public onlyNFTOwner(tokenId) whenNotPausedContract validTokenId(tokenId) {
        require(!nftProperties[tokenId].isStaked, "NFT is already staked");
        nftProperties[tokenId].isStaked = true;
        nftProperties[tokenId].stakingStartTime = block.timestamp;
        emit NFTStaked(tokenId, _msgSender());
    }

    /**
     * @dev Allows NFT holders to unstake their NFTs.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) public onlyNFTOwner(tokenId) whenNotPausedContract validTokenId(tokenId) {
        require(nftProperties[tokenId].isStaked, "NFT is not staked");
        nftProperties[tokenId].isStaked = false;
        emit NFTUnstaked(tokenId, _msgSender());
    }

    /**
     * @dev Allows NFT holders to claim accumulated staking rewards (simulated for demonstration).
     * @param tokenId The ID of the NFT to claim rewards for.
     * @return uint256 The amount of rewards claimed (simulated).
     */
    function claimStakingRewards(uint256 tokenId) public onlyNFTOwner(tokenId) whenNotPausedContract validTokenId(tokenId) returns (uint256) {
        require(nftProperties[tokenId].isStaked, "NFT is not staked");

        uint256 elapsedTime = block.timestamp - nftProperties[tokenId].stakingStartTime;
        uint256 rewards = elapsedTime * stakingRewardRate; // Simple reward calculation for example

        // In a real system, you would likely transfer actual tokens (e.g., ERC20) as rewards.
        // For this example, we're just returning a simulated reward amount.

        emit StakingRewardsClaimed(tokenId, _msgSender(), rewards);
        return rewards; // Return simulated rewards amount
    }


    // ---- Admin Functions ----

    /**
     * @dev Sets the base URI for token metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner whenNotPausedContract {
        baseURI = newBaseURI;
    }

    /**
     * @dev Sets the contract metadata URI.
     * @param newContractMetadataURI The new contract metadata URI.
     */
    function setContractMetadataURI(string memory newContractMetadataURI) public onlyOwner whenNotPausedContract {
        contractMetadataURI = newContractMetadataURI;
    }


    /**
     * @dev Pauses the contract, preventing minting and other core functionalities.
     */
    function pauseContract() public onlyOwner whenNotPausedContract {
        contractPaused = true;
        _pause(); // OpenZeppelin Pausable functionality
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring normal functionalities.
     */
    function unpauseContract() public onlyOwner whenPaused whenNotPausedContract {
        contractPaused = false;
        _unpause(); // OpenZeppelin Pausable functionality
        emit ContractUnpaused();
    }

    /**
     * @dev Withdraws any ETH accidentally sent to the contract.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Override _beforeTokenTransfer to enforce contract paused state during transfers if needed.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPausedContract virtual {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev @inheritdoc ERC721Enumerable
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function to set the token URI for a specific token.
     * Overriding this to potentially add custom logic before setting URI if needed in future.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        super._setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Internal function to check if the sender is the owner of a token.
     */
    function _isOwner(uint256 tokenId, address account) internal view returns (bool) {
        return ownerOf(tokenId) == account;
    }
}
```

**Explanation of Concepts and Advanced Features:**

1.  **Dynamic Reputation-Based NFTs:**
    *   NFTs are not static. Their properties and content evolve based on user interaction or on-chain events.
    *   **Reputation System:**  NFTs have a reputation score that can be increased or decreased. This score influences the NFT's content and potentially its utility within the ecosystem.
    *   **Dynamic Content Generation:** The `generateOnChainContent` function creates content for the NFT that changes based on its reputation level. This content is embedded in the `tokenURI`, making the NFT's metadata dynamic.

2.  **On-Chain Content Generation:**
    *   Instead of just linking to off-chain metadata, this contract demonstrates a basic form of *on-chain* content generation. The `generateOnChainContent` function creates text content directly within the smart contract logic.
    *   This is a more advanced concept as it makes the NFT's content more immutable and verifiable on-chain.  In this example, it's simple text, but it could be expanded to generate more complex data or even SVG graphics (though gas costs would need careful consideration).

3.  **DAO Integration & Feature Voting:**
    *   **Governance:** The contract includes a rudimentary Decentralized Autonomous Organization (DAO) structure. NFT holders can propose and vote on feature upgrades for the contract itself.
    *   **Proposal Mechanism:**  `proposeFeatureUpgrade` allows users to submit proposals with a description and encoded data representing the upgrade (e.g., a function call).
    *   **Weighted Voting:** `voteOnProposal` allows NFT holders to vote, with their voting power weighted by the reputation of the NFTs they hold. This rewards users who have actively engaged with the system and built up their NFT's reputation.
    *   **Execution:** `executeProposal` (owner-controlled in this example for simplicity, but could be made more decentralized) executes proposals that pass a vote.  **Important Security Note:** Executing arbitrary data from proposals is highly risky and requires extremely careful design and security audits in a real-world DAO.  This example is a simplified illustration.

4.  **Advanced Tokenomics (Simulated Staking):**
    *   **Utility beyond Art/Collectibles:**  The contract demonstrates adding utility to NFTs beyond just being digital art or collectibles.
    *   **Staking (Simulated):** The `stakeNFT`, `unstakeNFT`, and `claimStakingRewards` functions illustrate a basic staking mechanism.  NFT holders can "stake" their NFTs and earn rewards over time.  In this example, the rewards are *simulated* (no actual tokens are being distributed), but it shows the concept. In a real implementation, you would likely reward users with an ERC20 token or some other form of on-chain value.

5.  **Contract Pausing & Admin Functions:**
    *   **Security and Control:** The `pauseContract` and `unpauseContract` functions provide an emergency brake mechanism for the contract owner to halt core functionalities in case of issues or vulnerabilities.
    *   **Withdraw Funds:** `withdrawFunds` is a utility function to recover ETH accidentally sent to the contract address.

**Important Notes:**

*   **Security:** This is an *example* contract showcasing concepts. It is **not audited** and should **not be used in production** without thorough security review and testing. DAO governance and executing arbitrary data from proposals are particularly complex security areas.
*   **Gas Optimization:**  This contract is not heavily optimized for gas.  For a production contract, gas optimization would be a crucial consideration, especially for functions like `tokenURI` and content generation.
*   **Dynamic Metadata (TokenURI):** The `tokenURI` implementation in this example directly embeds JSON data using `data:application/json;base64,`.  While functional for simple examples, for more complex and frequently updated metadata, it's generally better to use an off-chain service (like IPFS, Arweave, or a dedicated metadata server) to generate and host the metadata, and then have the `tokenURI` in the contract point to the URI of that off-chain metadata. This allows for more flexibility and potentially lower gas costs for updates.
*   **Foundry `vm.base64`:** The example uses `vm.base64` which is a cheatcode specific to Foundry testing framework for base64 encoding within Solidity.  For a standard deployment, you would need to use a different method for base64 encoding if needed on-chain (though it's often better to handle base64 encoding off-chain when generating metadata).

This contract provides a starting point for exploring advanced and creative smart contract functionalities. You can expand upon these concepts to build more sophisticated and engaging decentralized applications.