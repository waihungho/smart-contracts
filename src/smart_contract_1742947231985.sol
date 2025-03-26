```solidity
/**
 * @title Dynamic Reputation NFT with Community Governance
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT that evolves based on user reputation within a community.
 *      It also incorporates basic community governance features like feature proposals and voting,
 *      driven by NFT holders and their reputation.
 *
 * **Contract Outline:**
 *
 * **Core Functionality (NFT & Reputation):**
 *   1. `mintNFT(address _to)`: Mints a Reputation NFT to a user. Initial reputation is set.
 *   2. `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 *   3. `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an NFT, reflecting reputation.
 *   4. `getReputation(address _user)`: Retrieves the reputation score of a user.
 *   5. `increaseReputation(address _user, uint256 _amount)`: Increases a user's reputation (Admin only).
 *   6. `decreaseReputation(address _user, uint256 _amount)`: Decreases a user's reputation (Admin only).
 *   7. `setReputationThresholds(uint256[] memory _thresholds, string[] memory _tiers)`: Sets reputation tiers and thresholds (Admin only).
 *   8. `getReputationTier(address _user)`: Returns the reputation tier of a user based on their score.
 *
 * **Community Governance (Proposals & Voting):**
 *   9. `proposeFeature(string memory _title, string memory _description)`: Allows NFT holders to propose new features.
 *   10. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on a feature proposal. Voting power is reputation-weighted.
 *   11. `executeProposal(uint256 _proposalId)`: Allows Admin to execute an approved proposal (based on vote outcome).
 *   12. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *   13. `listProposals()`: Returns a list of all proposal IDs.
 *   14. `getVotingPower(address _user)`: Calculates the voting power of a user based on their reputation.
 *
 * **Utility & Admin Functions:**
 *   15. `setBaseMetadataURI(string memory _baseURI)`: Sets the base URI for NFT metadata (Admin only).
 *   16. `pauseContract()`: Pauses certain contract functionalities (Admin only).
 *   17. `unpauseContract()`: Unpauses contract functionalities (Admin only).
 *   18. `isAdmin(address _account)`: Checks if an address is an admin.
 *   19. `addAdmin(address _admin)`: Adds a new admin (Admin only).
 *   20. `removeAdmin(address _admin)`: Removes an admin (Admin only, cannot remove self if only admin left).
 *   21. `withdrawContractBalance()`: Allows Admin to withdraw any ETH balance in the contract.
 *
 * **Events:**
 *   - `NFTMinted(address indexed to, uint256 tokenId)`: Emitted when an NFT is minted.
 *   - `ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation)`: Emitted when reputation is increased.
 *   - `ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation)`: Emitted when reputation is decreased.
 *   - `ReputationThresholdsUpdated(uint256[] thresholds, string[] tiers)`: Emitted when reputation thresholds are updated.
 *   - `FeatureProposed(uint256 proposalId, address proposer, string title)`: Emitted when a new feature proposal is created.
 *   - `VotedOnProposal(uint256 proposalId, address voter, bool vote)`: Emitted when a user votes on a proposal.
 *   - `ProposalExecuted(uint256 proposalId)`: Emitted when a proposal is executed.
 *   - `ContractPaused()`: Emitted when the contract is paused.
 *   - `ContractUnpaused()`: Emitted when the contract is unpaused.
 *   - `AdminAdded(address indexed admin)`: Emitted when a new admin is added.
 *   - `AdminRemoved(address indexed admin)`: Emitted when an admin is removed.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DynamicReputationNFT {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public name = "Dynamic Reputation NFT";
    string public symbol = "DRNFT";
    string public baseMetadataURI = "ipfs://your_base_metadata_uri/"; // Set your base IPFS URI

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => address) public tokenOwners;
    mapping(address => uint256) public userReputations;
    mapping(uint256 => uint256) public tokenReputation; // Store reputation at time of mint or update for metadata

    uint256[] public reputationThresholds = [100, 500, 1000]; // Example thresholds
    string[] public reputationTiers = ["Bronze", "Silver", "Gold", "Diamond"]; // Example tiers

    struct Proposal {
        address proposer;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    address public contractOwner;
    mapping(address => bool) public admins;
    bool public paused;

    event NFTMinted(address indexed to, uint256 tokenId);
    event ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationThresholdsUpdated(uint256[] thresholds, string[] tiers);
    event FeatureProposed(uint256 proposalId, address proposer, string title);
    event VotedOnProposal(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == contractOwner, "Only admins can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
        admins[msg.sender] = true; // Owner is also an admin initially
    }

    // -------------------- Core Functionality (NFT & Reputation) --------------------

    /// @dev Mints a Reputation NFT to a user. Initial reputation is set to 0.
    /// @param _to The address to mint the NFT to.
    function mintNFT(address _to) public onlyAdmin whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        tokenOwners[tokenId] = _to;
        userReputations[_to] = 0; // Initial reputation
        tokenReputation[tokenId] = 0; // Store initial reputation for metadata
        emit NFTMinted(_to, tokenId);
    }

    /// @dev Transfers an NFT to another address.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        address currentOwner = tokenOwners[_tokenId];
        require(currentOwner == msg.sender, "You are not the owner of this NFT.");
        require(_to != address(0), "Invalid recipient address.");
        tokenOwners[_tokenId] = _to;
    }

    /// @dev Returns the dynamic metadata URI for an NFT, reflecting reputation.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI string.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(tokenOwners[_tokenId] != address(0), "Token ID does not exist.");
        uint256 reputationScore = tokenReputation[_tokenId]; // Use stored reputation for consistency
        string memory tier = getReputationTier(tokenOwners[_tokenId]); // Get tier based on current reputation (can be adjusted)

        // Construct dynamic metadata (simple example - can be more complex JSON generation)
        string memory metadata = string(abi.encodePacked(
            '{"name": "', name, ' #', _tokenId.toString(), '",',
            '"description": "A Dynamic Reputation NFT representing community standing.",',
            '"image": "', baseMetadataURI, _tokenId.toString(), '.png",', // Example image URI based on tokenId
            '"attributes": [',
                '{"trait_type": "Reputation Score", "value": ', reputationScore.toString(), '},',
                '{"trait_type": "Reputation Tier", "value": "', tier, '"}',
            ']}'
        ));

        // For simplicity, we are returning the metadata string directly encoded as data URI.
        // In a real application, you would typically return an IPFS URI or a URL to a metadata server.
        return string(abi.encodePacked("data:application/json;base64,", vm.base64Encode(bytes(metadata))));
    }

    /// @dev Retrieves the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputation(address _user) public view returns (uint256) {
        return userReputations[_user];
    }

    /// @dev Increases a user's reputation (Admin only).
    /// @param _user The address of the user.
    /// @param _amount The amount to increase the reputation by.
    function increaseReputation(address _user, uint256 _amount) public onlyAdmin whenNotPaused {
        userReputations[_user] += _amount;
        // Update token reputation if user owns an NFT (assuming 1 NFT per user for simplicity)
        uint256 tokenId = _getTokenIdForUser(_user); // Helper function to get token ID for user
        if (tokenId != 0) {
            tokenReputation[tokenId] = userReputations[_user]; // Update stored reputation
        }
        emit ReputationIncreased(_user, _amount, userReputations[_user]);
    }

    /// @dev Decreases a user's reputation (Admin only).
    /// @param _user The address of the user.
    /// @param _amount The amount to decrease the reputation by.
    function decreaseReputation(address _user, uint256 _amount) public onlyAdmin whenNotPaused {
        require(userReputations[_user] >= _amount, "Reputation cannot be negative.");
        userReputations[_user] -= _amount;
        // Update token reputation if user owns an NFT
        uint256 tokenId = _getTokenIdForUser(_user);
        if (tokenId != 0) {
            tokenReputation[tokenId] = userReputations[_user]; // Update stored reputation
        }
        emit ReputationDecreased(_user, _amount, userReputations[_user]);
    }

    /// @dev Sets reputation tiers and thresholds (Admin only).
    /// @param _thresholds Array of reputation thresholds (must be sorted ascending).
    /// @param _tiers Array of tier names corresponding to the thresholds.
    function setReputationThresholds(uint256[] memory _thresholds, string[] memory _tiers) public onlyAdmin {
        require(_thresholds.length == _tiers.length, "Thresholds and tiers arrays must have the same length.");
        reputationThresholds = _thresholds;
        reputationTiers = _tiers;
        emit ReputationThresholdsUpdated(_thresholds, _tiers);
    }

    /// @dev Returns the reputation tier of a user based on their score.
    /// @param _user The address of the user.
    /// @return The reputation tier string.
    function getReputationTier(address _user) public view returns (string memory) {
        uint256 reputation = userReputations[_user];
        for (uint256 i = 0; i < reputationThresholds.length; i++) {
            if (reputation < reputationThresholds[i]) {
                if (i == 0) {
                    return reputationTiers[0]; // Lowest tier if below first threshold
                } else {
                    return reputationTiers[i]; // Tier corresponding to the threshold range
                }
            }
        }
        return reputationTiers[reputationTiers.length - 1]; // Highest tier if above all thresholds
    }

    // -------------------- Community Governance (Proposals & Voting) --------------------

    /// @dev Allows NFT holders to propose new features.
    /// @param _title The title of the proposal.
    /// @param _description The description of the proposal.
    function proposeFeature(string memory _title, string memory _description) public whenNotPaused {
        require(_getTokenIdForUser(msg.sender) != 0, "You must hold an NFT to propose features."); // Only NFT holders can propose
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            title: _title,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit FeatureProposed(proposalId, msg.sender, _title);
    }

    /// @dev Allows NFT holders to vote on a feature proposal. Voting power is reputation-weighted.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for "for", false for "against".
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(_getTokenIdForUser(msg.sender) != 0, "You must hold an NFT to vote."); // Only NFT holders can vote
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal.");
        require(!proposals[_proposalId].executed, "Proposal has already been executed.");

        uint256 votingPower = getVotingPower(msg.sender); // Get voting power based on reputation
        if (_vote) {
            proposals[_proposalId].votesFor += votingPower;
        } else {
            proposals[_proposalId].votesAgainst += votingPower;
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit VotedOnProposal(_proposalId, msg.sender, _vote);
    }

    /// @dev Allows Admin to execute an approved proposal (based on vote outcome).
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyAdmin whenNotPaused {
        require(!proposals[_proposalId].executed, "Proposal has already been executed.");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal not approved by community."); // Simple majority for now

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
        // Here you would implement the actual logic to execute the proposed feature.
        // This could involve calling other functions, updating contract state, etc.
        // For this example, we are just marking it as executed.
    }

    /// @dev Retrieves details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        require(_proposalId < _proposalIdCounter.current(), "Invalid proposal ID.");
        return proposals[_proposalId];
    }

    /// @dev Returns a list of all proposal IDs.
    /// @return Array of proposal IDs.
    function listProposals() public view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](_proposalIdCounter.current());
        for (uint256 i = 0; i < _proposalIdCounter.current(); i++) {
            proposalIds[i] = i;
        }
        return proposalIds;
    }

    /// @dev Calculates the voting power of a user based on their reputation.
    /// @param _user The address of the user.
    /// @return The voting power (higher reputation = higher power).
    function getVotingPower(address _user) public view returns (uint256) {
        // Simple voting power calculation: reputation score + 1 (at least 1 vote)
        return userReputations[_user] + 1;
        // Can implement more complex voting power logic if needed (e.g., tiered voting power)
    }

    // -------------------- Utility & Admin Functions --------------------

    /// @dev Sets the base URI for NFT metadata (Admin only).
    /// @param _baseURI The new base metadata URI.
    function setBaseMetadataURI(string memory _baseURI) public onlyAdmin {
        baseMetadataURI = _baseURI;
    }

    /// @dev Pauses certain contract functionalities (Admin only).
    function pauseContract() public onlyAdmin {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Unpauses contract functionalities (Admin only).
    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    /// @dev Checks if an address is an admin.
    /// @param _account The address to check.
    /// @return True if the address is an admin, false otherwise.
    function isAdmin(address _account) public view returns (bool) {
        return admins[_account];
    }

    /// @dev Adds a new admin (Admin only).
    /// @param _admin The address to add as an admin.
    function addAdmin(address _admin) public onlyAdmin {
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /// @dev Removes an admin (Admin only, cannot remove self if only admin left).
    /// @param _admin The address to remove as an admin.
    function removeAdmin(address _admin) public onlyAdmin {
        require(_admin != contractOwner, "Cannot remove contract owner as admin.");
        uint256 adminCount = 0;
        for (address adminAddress in admins) {
            if (admins[adminAddress]) {
                adminCount++;
            }
        }
        require(adminCount > 1 || _admin != msg.sender, "Cannot remove the only admin (you)."); // Prevent removing self if you are the last admin.
        delete admins[_admin];
        emit AdminRemoved(_admin);
    }

    /// @dev Allows Admin to withdraw any ETH balance in the contract.
    function withdrawContractBalance() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    // -------------------- Internal Helper Functions --------------------

    /// @dev Internal helper function to get the token ID associated with a user address (assuming 1 NFT per user).
    /// @param _user The address of the user.
    /// @return The token ID, or 0 if no NFT found for the user.
    function _getTokenIdForUser(address _user) internal view returns (uint256) {
        for (uint256 tokenId = 0; tokenId < _tokenIdCounter.current(); tokenId++) {
            if (tokenOwners[tokenId] == _user) {
                return tokenId;
            }
        }
        return 0; // User does not own an NFT
    }
}
```