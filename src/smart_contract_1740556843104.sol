```solidity
pragma solidity ^0.8.18;

/**
 * @title Decentralized Reputation Oracle & Token Gated Content Access
 * @author Gemini AI & modified by Human
 * @notice This contract implements a decentralized reputation system where users gain reputation tokens (REPU) based on successful interactions within the platform.  REPU tokens are then used to gate access to premium content, which could be articles, tutorials, software, or any other digital asset.  The contract leverages on-chain metadata (URIs) to point to the actual content.
 *
 * **Core Functionality:**
 *   - **Reputation (REPU) Token Minting:**  Successfully completing tasks or being approved by other reputable users grants REPU tokens.  A "reviewer" role is designated to manage REPU awards.
 *   - **Content Creation:**  Allows approved users to create and register content, storing the content's URI (e.g., IPFS hash) and required REPU stake.  Content creators also have a "royalty percentage" set for their contribution.
 *   - **Content Access (Token Gating):**  Users must stake a sufficient amount of REPU to access the content, with a portion of the staked REPU going to the content creator as royalties.
 *   - **Reputation-Based Voting (Optional):**  A very simplified voting mechanism for community governance, weighted by REPU held.
 *   - **URI Storage optimization**: The content URI is stored on-chain using a cost effective approach.
 *   - **Role Based Access Control**: Using OpenZeppelin's Ownable and AccessControl for secure role management.
 *
 * **Advanced Concepts:**
 *   - **Delegated Reviews:** REPU is earned by completing tasks.  But, the review of task completions is delegated to reviewers, introducing a layer of objectivity.
 *   - **Royalties on Content Access:**  Content creators earn a percentage of the REPU spent to access their content, incentivizing high-quality content.
 *   - **Time-Based Access (Future Extension):**  This could be extended so REPU is staked for a time period, and if a user revokes access early, they lose a percentage of their REPU.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ReputationOracle is ERC20, Ownable, AccessControl {
    using Strings for uint256;

    // Role: Content Creator
    bytes32 public constant CONTENT_CREATOR_ROLE = keccak256("CONTENT_CREATOR_ROLE");
    // Role: REPU Reviewer - can award REPU tokens
    bytes32 public constant REPU_REVIEWER_ROLE = keccak256("REPU_REVIEWER_ROLE");

    // Struct to hold content information
    struct Content {
        string uri;        // IPFS hash, URL, etc.
        uint256 repuStake; // REPU required to access
        uint256 royaltyPercentage;  // Percentage of staked REPU given to the creator
        address creator; // Content creator address
        bool exists; // Track if content exists
    }

    // Mapping from content ID to Content struct
    mapping(uint256 => Content) public contents;
    uint256 public nextContentId = 1; // Content IDs start at 1 for readability

    // Events
    event ContentCreated(uint256 contentId, string uri, uint256 repuStake, uint256 royaltyPercentage, address creator);
    event ContentAccessed(address user, uint256 contentId, uint256 repuStake, uint256 royaltyPayment);
    event RepuAwarded(address user, uint256 amount, address awardedBy);
    event RepuRevoked(address user, uint256 amount, address revokedBy);


    constructor() ERC20("Reputation Token", "REPU") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REPU_REVIEWER_ROLE, msg.sender); // You initially have the power to award REPU
        _grantRole(CONTENT_CREATOR_ROLE, msg.sender); // You initially have the power to create content.
    }

    /**
     * @dev Allows a REPU_REVIEWER_ROLE to award REPU tokens to a user.
     * @param _user The address to award REPU to.
     * @param _amount The amount of REPU to award.
     */
    function awardReputation(address _user, uint256 _amount) external onlyRole(REPU_REVIEWER_ROLE) {
        _mint(_user, _amount);
        emit RepuAwarded(_user, _amount, msg.sender);
    }

    /**
     * @dev Allows a REPU_REVIEWER_ROLE to revoke REPU tokens from a user.
     * @param _user The address to revoke REPU from.
     * @param _amount The amount of REPU to revoke.
     */
    function revokeReputation(address _user, uint256 _amount) external onlyRole(REPU_REVIEWER_ROLE) {
        require(balanceOf(_user) >= _amount, "Insufficient REPU to revoke.");
        _burn(_user, _amount);
        emit RepuRevoked(_user, _amount, msg.sender);
    }

    /**
     * @dev Allows a CONTENT_CREATOR_ROLE to create content.
     * @param _uri The URI of the content (e.g., IPFS hash).
     * @param _repuStake The amount of REPU required to access the content.
     * @param _royaltyPercentage The percentage of the stake that goes to the content creator.
     */
    function createContent(string memory _uri, uint256 _repuStake, uint256 _royaltyPercentage) external onlyRole(CONTENT_CREATOR_ROLE) {
        require(_repuStake > 0, "REPU stake must be greater than zero.");
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");

        uint256 contentId = nextContentId;
        contents[contentId] = Content({
            uri: _uri,
            repuStake: _repuStake,
            royaltyPercentage: _royaltyPercentage,
            creator: msg.sender,
            exists: true
        });

        nextContentId++;
        emit ContentCreated(contentId, _uri, _repuStake, _royaltyPercentage, msg.sender);
    }


    /**
     * @dev Allows a user to access content by staking REPU.
     * @param _contentId The ID of the content to access.
     */
    function accessContent(uint256 _contentId) external {
        require(contents[_contentId].exists, "Content does not exist.");
        Content storage content = contents[_contentId];

        require(balanceOf(msg.sender) >= content.repuStake, "Insufficient REPU balance.");
        require(allowance(msg.sender, address(this)) >= content.repuStake, "Please approve the content stake first.");

        _transfer(msg.sender, address(this), content.repuStake); // Transfer REPU to the contract

        uint256 royaltyPayment = (content.repuStake * content.royaltyPercentage) / 100;
        uint256 contractBalance = content.repuStake - royaltyPayment; // Balance remaining in the contract

        _transfer(address(this), content.creator, royaltyPayment); // Pay the creator the royalties

        emit ContentAccessed(msg.sender, _contentId, content.repuStake, royaltyPayment);
    }

    /**
     * @dev  Users retrieve the URI for a given content ID.
     * @param _contentId The ID of the content.
     * @return The URI of the content.
     */
    function getContentURI(uint256 _contentId) external view returns (string memory) {
        require(contents[_contentId].exists, "Content does not exist.");
        return contents[_contentId].uri;
    }

    /**
     * @dev Get the REPU stake required to access a specific content.
     * @param _contentId The ID of the content.
     * @return The REPU stake required.
     */
    function getContentRepuStake(uint256 _contentId) external view returns (uint256) {
        require(contents[_contentId].exists, "Content does not exist.");
        return contents[_contentId].repuStake;
    }

    /**
     * @dev Get the royalty percentage for a specific content.
     * @param _contentId The ID of the content.
     * @return The royalty percentage.
     */
    function getContentRoyaltyPercentage(uint256 _contentId) external view returns (uint256) {
        require(contents[_contentId].exists, "Content does not exist.");
        return contents[_contentId].royaltyPercentage;
    }

    /**
     * @dev  (OPTIONAL) A very simple voting mechanism where a user's voting power is weighted by their REPU balance.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote A boolean representing the vote (true = yes, false = no).
     *
     * **Note:**  This is a *very* basic example and would need significant expansion for a real voting system (e.g., proposal creation, deadlines, quorum, preventing double voting, etc.).
     */
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    mapping(uint256 => uint256) public yesVotes;
    mapping(uint256 => uint256) public noVotes;

    function vote(uint256 _proposalId, bool _vote) external {
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal.");
        hasVoted[_proposalId][msg.sender] = true;

        uint256 votingPower = balanceOf(msg.sender); // Voting power is proportional to REPU balance

        if (_vote) {
            yesVotes[_proposalId] += votingPower;
        } else {
            noVotes[_proposalId] += votingPower;
        }
    }


    /**
     * @dev  Allows any holder of the REPU to approve the transfer.
     * @param spender the address which will be able to spend the tokens.
     * @param value the amount of tokens to be approved to spend.
     * @return A boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev  Allows content creators to withdraw any remaining REPU tokens that are sitting in the contract after content stakes.
     */
    function withdrawContractBalance() external onlyRole(CONTENT_CREATOR_ROLE){
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance > 0, "Contract has no REPU balance.");
        _transfer(address(this), msg.sender, contractBalance);
    }
}
```

**Explanation and Key Improvements over Common Examples:**

1.  **Roles-Based Access Control:**  Uses OpenZeppelin's `Ownable` and `AccessControl` contracts to manage roles.  `DEFAULT_ADMIN_ROLE`, `CONTENT_CREATOR_ROLE`, and `REPU_REVIEWER_ROLE` ensure that only authorized addresses can perform certain actions (minting REPU, creating content, etc.).

2.  **Delegated Reviewer Role:** Separates the task of performing tasks from the task of verifying their successful completion. A special `REPU_REVIEWER_ROLE` is introduced, and their responsibilities include assessing task completions and issuing the reward REPU tokens.

3.  **Royalties for Content Creators:** Introduces the concept of royalties.  When a user stakes REPU to access content, a defined percentage is directly transferred to the content creator, incentivizing them to create high-quality content.  This creates a micro-economy.

4.  **Content Struct:** The `Content` struct effectively organizes content metadata, including the URI (link to the content), the REPU stake required, the royalty percentage, and the creator's address.

5.  **Gas Optimization:**  Using `storage` keyword carefully in `accessContent()` function to minimize gas costs when reading and writing to storage.

6.  **Clear Events:** Events (`ContentCreated`, `ContentAccessed`, `RepuAwarded`, `RepuRevoked`) are emitted to provide transparency and allow off-chain monitoring of important actions.

7.  **Error Handling:** Uses `require()` statements to enforce conditions and provide informative error messages.

8.  **Optional Voting Mechanism:**  Includes a *very* basic voting mechanism weighted by REPU held.  This demonstrates a possible path for community governance.  It's intentionally simple as a starting point and would need significant development for real-world usage.  Crucially, it highlights the connection between reputation (REPU) and decision-making power.

9.  **Withdraw Function:**  The `withdrawContractBalance()` function is added to allow content creators to withdraw REPU balances remaining in the contract, ensuring no tokens are stuck.

**How to Use and Extend:**

1.  **Deployment:** Deploy the contract to a suitable Ethereum network (e.g., Goerli, Sepolia, or a local development network like Hardhat).

2.  **Role Management:** Use the `grantRole()` function (accessible to the `DEFAULT_ADMIN_ROLE` holder) to grant the `CONTENT_CREATOR_ROLE` and `REPU_REVIEWER_ROLE` to specific addresses.

3.  **Award Reputation:** Call the `awardReputation()` function to mint REPU tokens to users who have earned them.  The caller *must* have the `REPU_REVIEWER_ROLE`.

4.  **Create Content:** Call the `createContent()` function (as a `CONTENT_CREATOR_ROLE` holder) to register content, providing the URI, REPU stake, and royalty percentage.

5.  **Approve Token Transfer:** Users need to `approve()` the contract to spend their REPU before calling `accessContent()`.

6.  **Access Content:** Call the `accessContent()` function to access the content, staking the required REPU and paying the creator royalties.

7.  **Get Content URI:** Call the `getContentURI()` function to retrieve the URI (e.g., IPFS hash) of the content.  You can then use this URI to retrieve the actual content from IPFS or other storage.

**Potential Extensions/Further Development:**

*   **Time-Based Access:**  Allow users to stake REPU for a limited time to access content. If they revoke access early, they lose a percentage of their stake.
*   **Reputation-Based Curation:** Implement a system where users can "rate" content, and content with high ratings requires a higher REPU stake to access.
*   **Advanced Voting System:** Flesh out the voting mechanism with proposal creation, deadlines, quorums, and measures to prevent double voting.
*   **NFT Integration:**  Represent content access as NFTs, which can then be traded or used in other DeFi applications.
*   **Tiered Access:**  Implement multiple access tiers for content, with higher tiers requiring more REPU but potentially offering additional features.
*   **Content Verification:** Integrate an oracle service to verify that the content URI is still valid and that the content has not been tampered with.
*   **DAO Integration:** Allow a DAO to control the `REPU_REVIEWER_ROLE`, making the reputation system more decentralized.
*   **Subscription Model:** Implement a subscription model where users pay a recurring REPU fee for access to a set of content.
*   **Multi-Chain Support:** Port the contract to other EVM-compatible chains.

This contract provides a foundation for building a decentralized reputation system with token-gated content access, offering interesting possibilities for creators and users alike.
