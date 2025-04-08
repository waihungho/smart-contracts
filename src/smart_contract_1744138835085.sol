```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Evolution & Community Governance Contract
 * @author Bard (Example - Not for Production)
 * @dev A smart contract demonstrating advanced concepts like dynamic NFTs, community governance,
 *      on-chain randomness (with caveats), and interactive elements.  This contract allows
 *      NFTs to evolve based on community votes and external factors (simulated within the contract).
 *
 * **Outline & Function Summary:**
 *
 * **Core NFT Functionality:**
 * 1. `mintNFT(string memory _initialMetadataURI)`: Mints a new Dynamic NFT, assigning initial metadata.
 * 2. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 * 3. `getNFTOwner(uint256 _tokenId)`: Returns the owner of a specific NFT.
 * 4. `getNFTMetadataURI(uint256 _tokenId)`: Retrieves the current metadata URI of an NFT.
 * 5. `getTotalNFTsMinted()`: Returns the total number of NFTs minted.
 *
 * **Dynamic Evolution System:**
 * 6. `submitEvolutionProposal(uint256 _tokenId, string memory _newMetadataURI)`: Allows NFT owners to propose evolution updates for their NFTs.
 * 7. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows token holders to vote on evolution proposals.
 * 8. `executeEvolution(uint256 _proposalId)`: Executes a successful evolution proposal, updating NFT metadata.
 * 9. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific evolution proposal.
 * 10. `getActiveProposals()`: Returns a list of IDs of active evolution proposals.
 *
 * **Community Governance & Staking (Simplified):**
 * 11. `stakeTokensForVoting(uint256 _amount)`: Allows users to stake tokens to gain voting power. (Simplified - assumes a basic token exists)
 * 12. `unstakeTokens(uint256 _amount)`: Allows users to unstake tokens, reducing voting power.
 * 13. `getVotingPower(address _voter)`: Returns the voting power of a given address based on staked tokens.
 * 14. `setGovernanceThreshold(uint256 _newThreshold)`: Admin function to change the voting threshold for proposals.
 * 15. `getCurrentGovernanceThreshold()`: Returns the current governance threshold.
 *
 * **Randomness & Trait Mutation (Simulated & Controlled):**
 * 16. `triggerRandomMutation(uint256 _tokenId)`: Simulates a random mutation event for an NFT, potentially altering its traits. (Controlled randomness for example)
 * 17. `getNFTTraits(uint256 _tokenId)`: Retrieves the current traits of an NFT.
 *
 * **Utility & Admin Functions:**
 * 18. `pauseContract()`: Admin function to pause core contract functionalities.
 * 19. `unpauseContract()`: Admin function to unpause contract functionalities.
 * 20. `withdrawContractBalance()`: Admin function to withdraw contract's ETH balance.
 * 21. `getVersion()`: Returns the contract version.
 * 22. `supportsInterface(bytes4 interfaceId)` (ERC165 compatibility for NFT standards).
 */
contract DynamicNFTEvolution {

    // --- State Variables ---

    string public contractName = "DynamicNFT";
    string public contractVersion = "1.0";

    address public admin;
    address public curator; // Role for managing content/metadata updates
    bool public paused = false;

    uint256 public nftCounter;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftMetadataURI;
    mapping(uint256 => string[]) public nftTraits; // Example: Store traits as string array

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Vote[]) public proposalVotes;
    uint256 public governanceThreshold = 50; // Percentage of votes needed for proposal to pass (e.g., 50%)

    mapping(address => uint256) public stakedTokens; // Simplified staking for voting power - in real-world use an actual token contract
    uint256 public totalStakedTokens;

    // --- Structs & Enums ---

    struct NFT {
        uint256 tokenId;
        string metadataURI;
        string[] traits;
    }

    struct Proposal {
        uint256 proposalId;
        uint256 tokenId;
        string newMetadataURI;
        address proposer;
        uint256 startTime;
        uint256 endTime; // Example: Proposal duration
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    struct Vote {
        address voter;
        bool vote; // true for yes, false for no
    }

    enum ProposalStatus {
        Pending,
        Active,
        Passed,
        Rejected,
        Executed
    }

    // --- Events ---

    event NFTMinted(uint256 tokenId, address owner, string metadataURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event MetadataUpdated(uint256 tokenId, string newMetadataURI);
    event EvolutionProposalSubmitted(uint256 proposalId, uint256 tokenId, string newMetadataURI, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event EvolutionExecuted(uint256 proposalId, uint256 tokenId, string newMetadataURI);
    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address unstaker, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminWithdrawal(address admin, uint256 amount);
    event TraitMutationTriggered(uint256 tokenId);
    event TraitsUpdated(uint256 tokenId, string[] newTraits);
    event GovernanceThresholdUpdated(uint256 newThreshold);


    // --- Modifiers ---

    modifier onlyOwnerOfNFT(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "Not owner of NFT");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyCurator() {
        require(msg.sender == curator, "Only curator can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        // Curator can be set later by admin if needed
    }

    // --- Core NFT Functions ---

    /// @notice Mints a new Dynamic NFT with initial metadata.
    /// @param _initialMetadataURI The initial metadata URI for the NFT.
    function mintNFT(string memory _initialMetadataURI) public whenNotPaused {
        nftCounter++;
        uint256 tokenId = nftCounter;
        nftOwner[tokenId] = msg.sender;
        nftMetadataURI[tokenId] = _initialMetadataURI;

        // Initialize default traits (example) - can be more complex logic or external data
        nftTraits[tokenId] = ["Generation 1", "Rarity: Common", "Element: Fire"];

        emit NFTMinted(tokenId, msg.sender, _initialMetadataURI);
    }

    /// @notice Transfers ownership of an NFT to a new address.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        require(nftOwner[_tokenId] == msg.sender, "Not owner of NFT");
        require(_to != address(0), "Invalid recipient address");
        address from = nftOwner[_tokenId];
        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, from, _to);
    }

    /// @notice Retrieves the owner of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        return nftOwner[_tokenId];
    }

    /// @notice Retrieves the current metadata URI of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI of the NFT.
    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return nftMetadataURI[_tokenId];
    }

    /// @notice Returns the total number of NFTs minted so far.
    /// @return The total count of NFTs.
    function getTotalNFTsMinted() public view returns (uint256) {
        return nftCounter;
    }

    // --- Dynamic Evolution System ---

    /// @notice Allows NFT owners to submit a proposal to evolve their NFT's metadata.
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _newMetadataURI The proposed new metadata URI.
    function submitEvolutionProposal(uint256 _tokenId, string memory _newMetadataURI) public whenNotPaused onlyOwnerOfNFT(_tokenId) {
        proposalCounter++;
        uint256 proposalId = proposalCounter;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            tokenId: _tokenId,
            newMetadataURI: _newMetadataURI,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // Example: 7-day voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit EvolutionProposalSubmitted(proposalId, _tokenId, _newMetadataURI, msg.sender);
    }

    /// @notice Allows token holders to vote on an active evolution proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote `true` to vote yes, `false` to vote no.
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(proposals[_proposalId].startTime != 0, "Proposal does not exist");
        require(proposals[_proposalId].endTime > block.timestamp, "Voting period ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        // Simplified voting power - using staked tokens. In real-world, use actual governance token and voting delegation
        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "No voting power");

        // Check if voter already voted - for simplicity, just allow one vote per address per proposal in this example
        for (uint i = 0; i < proposalVotes[_proposalId].length; i++) {
            require(proposalVotes[_proposalId][i].voter != msg.sender, "Already voted on this proposal");
        }

        proposalVotes[_proposalId].push(Vote({voter: msg.sender, vote: _vote}));

        if (_vote) {
            proposals[_proposalId].yesVotes += voterPower;
        } else {
            proposals[_proposalId].noVotes += voterPower;
        }

        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes an evolution proposal if it has passed the governance threshold.
    /// @param _proposalId The ID of the proposal to execute.
    function executeEvolution(uint256 _proposalId) public whenNotPaused {
        require(proposals[_proposalId].startTime != 0, "Proposal does not exist");
        require(proposals[_proposalId].endTime < block.timestamp, "Voting period not ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes cast"); // Prevent division by zero
        uint256 yesPercentage = (proposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= governanceThreshold) {
            uint256 tokenId = proposals[_proposalId].tokenId;
            string memory newMetadataURI = proposals[_proposalId].newMetadataURI;
            nftMetadataURI[tokenId] = newMetadataURI;
            proposals[_proposalId].executed = true;
            emit EvolutionExecuted(_proposalId, tokenId, newMetadataURI);
            emit MetadataUpdated(tokenId, newMetadataURI);
        } else {
            proposals[_proposalId].executed = true; // Mark as executed even if rejected to prevent re-execution
            proposals[_proposalId].noVotes = totalVotes - proposals[_proposalId].yesVotes; // Ensure noVotes is correctly updated
            emit ProposalVoted(_proposalId, address(0), false); // Emit a "rejected" event, voter address is irrelevant in rejection
        }
    }

    /// @notice Retrieves details of a specific evolution proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns a list of IDs of active evolution proposals.
    /// @return Array of proposal IDs that are currently active.
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCounter); // Max possible active is all proposals, can optimize
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].startTime != 0 && proposals[i].endTime > block.timestamp && !proposals[i].executed) {
                activeProposalIds[activeCount] = i;
                activeCount++;
            }
        }
        // Resize array to actual active count
        assembly {
            mstore(activeProposalIds, activeCount) // Update length in memory
        }
        return activeProposalIds;
    }


    // --- Community Governance & Staking (Simplified) ---

    /// @notice Allows users to stake tokens to gain voting power. (Simplified - assumes basic token logic)
    /// @param _amount The amount of tokens to stake.
    function stakeTokensForVoting(uint256 _amount) public whenNotPaused {
        // In a real-world scenario, you'd interact with an actual token contract here to transfer tokens
        // For simplicity, we just assume users have "tokens" and track staked amounts directly in this contract.
        require(_amount > 0, "Amount must be greater than zero");
        stakedTokens[msg.sender] += _amount;
        totalStakedTokens += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows users to unstake tokens, reducing their voting power.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakedTokens[msg.sender] >= _amount, "Insufficient staked tokens");
        stakedTokens[msg.sender] -= _amount;
        totalStakedTokens -= _amount;
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Returns the voting power of a given address based on staked tokens.
    /// @param _voter The address to check voting power for.
    /// @return The voting power of the address.
    function getVotingPower(address _voter) public view returns (uint256) {
        return stakedTokens[_voter]; // Simplified - voting power is directly proportional to staked tokens
    }

    /// @notice Admin function to set the governance threshold for proposal approval.
    /// @param _newThreshold The new governance threshold percentage (e.g., 50 for 50%).
    function setGovernanceThreshold(uint256 _newThreshold) public onlyAdmin {
        require(_newThreshold <= 100, "Threshold must be between 0 and 100");
        governanceThreshold = _newThreshold;
        emit GovernanceThresholdUpdated(_newThreshold);
    }

    /// @notice Returns the current governance threshold percentage.
    /// @return The current governance threshold.
    function getCurrentGovernanceThreshold() public view returns (uint256) {
        return governanceThreshold;
    }


    // --- Randomness & Trait Mutation (Simulated & Controlled) ---

    /// @notice Triggers a simulated random mutation event for an NFT, potentially altering its traits.
    /// @param _tokenId The ID of the NFT to mutate.
    function triggerRandomMutation(uint256 _tokenId) public whenNotPaused onlyOwnerOfNFT(_tokenId) {
        // **Important Security Note:**  On-chain randomness is generally predictable and manipulable.
        // For true randomness in production, use a verifiable randomness oracle like Chainlink VRF.
        // This example uses a very basic, insecure method for demonstration purposes only.

        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, msg.sender)));
        uint256 mutationChance = randomValue % 100; // Example: 1 in 100 chance of mutation

        if (mutationChance < 15) { // Example: 15% chance of mutation
            string[] memory currentTraits = nftTraits[_tokenId];
            string[] memory newTraits = new string[](currentTraits.length);

            for (uint i = 0; i < currentTraits.length; i++) {
                if (i == 2) { // Example: Mutate the "Element" trait
                    uint256 elementRandom = randomValue % 3; // 3 possible elements
                    if (elementRandom == 0) {
                        newTraits[i] = "Element: Water";
                    } else if (elementRandom == 1) {
                        newTraits[i] = "Element: Earth";
                    } else {
                        newTraits[i] = "Element: Air";
                    }
                } else {
                    newTraits[i] = currentTraits[i]; // Keep other traits unchanged
                }
            }
            nftTraits[_tokenId] = newTraits;
            emit TraitsUpdated(_tokenId, newTraits);
        }
        emit TraitMutationTriggered(_tokenId);
    }

    /// @notice Retrieves the current traits of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return Array of strings representing the NFT's traits.
    function getNFTTraits(uint256 _tokenId) public view returns (string[] memory) {
        return nftTraits[_tokenId];
    }


    // --- Utility & Admin Functions ---

    /// @notice Pauses core contract functionalities, preventing minting, transfers, proposals, voting, etc.
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses contract functionalities, restoring normal operation.
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the admin to withdraw the contract's ETH balance.
    function withdrawContractBalance() public onlyAdmin {
        (bool success, ) = admin.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
        emit AdminWithdrawal(admin, address(this).balance);
    }

    /// @notice Returns the contract version string.
    function getVersion() public view returns (string memory) {
        return contractVersion;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // Basic ERC165 support - can be extended for specific NFT interfaces if needed
        return interfaceId == type(IERC165).interfaceId;
    }

    // --- Interface for ERC165 (Minimalistic example for demonstration) ---
    interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }
}
```