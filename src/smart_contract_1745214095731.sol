```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT system where NFTs can evolve over time,
 *      interact with staking mechanisms, participate in governance, and have unique on-chain traits.
 *
 * Function Summary:
 * -----------------
 * **NFT Core Functions:**
 * 1. mintNFT(address _to, string memory _baseURI) - Mints a new Dynamic NFT to the specified address.
 * 2. transferNFT(address _from, address _to, uint256 _tokenId) - Transfers an NFT to a new address.
 * 3. tokenURI(uint256 _tokenId) - Returns the URI for the metadata of the NFT. (Dynamic and stage-dependent)
 * 4. balanceOf(address _owner) - Returns the balance of NFTs owned by an address.
 * 5. ownerOf(uint256 _tokenId) - Returns the owner of a specific NFT.
 * 6. approve(address _approved, uint256 _tokenId) - Approves an address to spend a specific NFT.
 * 7. getApproved(uint256 _tokenId) - Gets the approved address for a specific NFT.
 * 8. setApprovalForAll(address _operator, bool _approved) - Sets approval for an operator to manage all NFTs of the sender.
 * 9. isApprovedForAll(address _owner, address _operator) - Checks if an operator is approved for all NFTs of an owner.
 *
 * **Evolution & Staking Functions:**
 * 10. stakeNFT(uint256 _tokenId) - Stakes an NFT to begin its evolution process.
 * 11. unstakeNFT(uint256 _tokenId) - Unstakes an NFT, pausing its evolution.
 * 12. evolveNFT(uint256 _tokenId) - Manually triggers the evolution process for a staked NFT (can be time-based or event-based).
 * 13. getNFTStage(uint256 _tokenId) - Returns the current evolution stage of an NFT.
 * 14. getStakingStatus(uint256 _tokenId) - Returns the staking status of an NFT.
 * 15. claimEvolutionRewards(uint256 _tokenId) - Allows owner to claim rewards upon reaching certain evolution stages.
 *
 * **Governance & Customization Functions:**
 * 16. proposeEvolutionParameterChange(string memory _parameterName, uint256 _newValue, string memory _description) - Allows NFT holders to propose changes to evolution parameters.
 * 17. voteOnProposal(uint256 _proposalId, bool _vote) - Allows NFT holders to vote on active proposals.
 * 18. executeProposal(uint256 _proposalId) - Executes a successful proposal after voting period.
 * 19. getProposalState(uint256 _proposalId) - Returns the current state of a proposal.
 * 20. setBaseURI(string memory _newBaseURI) - Admin function to set the base URI for NFT metadata.
 * 21. pauseContract() - Admin function to pause core functionalities of the contract.
 * 22. unpauseContract() - Admin function to unpause the contract.
 * 23. withdrawContractBalance() - Admin function to withdraw contract balance.
 */

contract DynamicNFTEvolution {
    // --- State Variables ---

    string public name = "Dynamic Evolution NFT";
    string public symbol = "DYN_NFT";
    string public baseURI;
    uint256 public totalSupply;
    uint256 public nextTokenId = 1;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOfAddress;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    // Evolution related mappings
    mapping(uint256 => uint256) public nftStage; // Stage of evolution for each NFT
    mapping(uint256 => uint256) public stakeStartTime; // Timestamp when NFT was staked
    mapping(uint256 => bool) public isStaked; // Staking status of each NFT
    mapping(uint256 => uint256) public lastEvolutionTime; // Last time NFT evolved

    // Evolution Parameters (governance can change these)
    uint256 public evolutionStageDuration = 7 days; // Time for each evolution stage
    uint256 public maxEvolutionStages = 5;
    uint256 public stakingRewardPerStage = 10; // Example reward unit

    // Governance related mappings
    struct Proposal {
        string parameterName;
        uint256 newValue;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    uint256 public votingDuration = 3 days;
    uint256 public quorumPercentage = 51; // Percentage of total supply needed to pass

    bool public paused = false;
    address public contractOwner;

    // --- Events ---
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransferred(address indexed from, address indexed to, uint256 tokenId);
    event NFTStaked(uint256 indexed tokenId, address indexed owner);
    event NFTUnstaked(uint256 indexed tokenId, address indexed owner);
    event NFTEvolved(uint256 indexed tokenId, uint256 stage);
    event EvolutionParameterProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event BaseURISet(string newBaseURI, address admin);

    // --- Modifiers ---
    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "Not the owner of this NFT");
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
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
    constructor(string memory _baseURI) {
        contractOwner = msg.sender;
        baseURI = _baseURI;
    }

    // --- NFT Core Functions ---

    /// @notice Mints a new Dynamic NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The base URI for the NFT metadata.
    function mintNFT(address _to, string memory _baseURI) public whenNotPaused {
        require(_to != address(0), "Mint to the zero address");
        uint256 tokenId = nextTokenId++;
        ownerOf[tokenId] = _to;
        balanceOfAddress[_to]++;
        nftStage[tokenId] = 1; // Initial stage
        lastEvolutionTime[tokenId] = block.timestamp; // Set initial evolution time
        baseURI = _baseURI; // Update base URI when minting (can be adjusted for more dynamic URI setting)

        emit NFTMinted(_to, tokenId);
        totalSupply++;
    }

    /// @notice Transfers an NFT to a new address.
    /// @param _from The current owner of the NFT.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_from == ownerOf[_tokenId], "Transfer from incorrect owner");
        require(_to != address(0), "Transfer to the zero address");
        require(msg.sender == _from || getApproved(_tokenId) == msg.sender || isApprovedForAll(_from, msg.sender), "Transfer caller is not owner nor approved");

        _clearApproval(_tokenId);

        balanceOfAddress[_from]--;
        balanceOfAddress[_to]++;
        ownerOf[_tokenId] = _to;

        isStaked[_tokenId] = false; // Unstake on transfer
        stakeStartTime[_tokenId] = 0; // Reset stake time

        emit NFTTransferred(_from, _to, _tokenId);
    }

    /// @notice Returns the URI for the metadata of the NFT. (Dynamic and stage-dependent)
    /// @param _tokenId The ID of the NFT.
    /// @return The URI string for the NFT metadata.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        // Example dynamic URI based on stage - customize as needed
        return string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), "/", Strings.toString(nftStage[_tokenId]), ".json"));
    }

    /// @notice Returns the balance of NFTs owned by an address.
    /// @param _owner The address to check the balance of.
    /// @return The number of NFTs owned by the address.
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for the zero address");
        return balanceOfAddress[_owner];
    }

    /// @notice Returns the owner of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the owner of the NFT.
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "Owner query for nonexistent token");
        return ownerOf[_tokenId];
    }

    /// @notice Approves an address to spend a specific NFT.
    /// @param _approved The address to be approved.
    /// @param _tokenId The ID of the NFT to be approved for.
    function approve(address _approved, uint256 _tokenId) public whenNotPaused onlyOwnerOfToken(_tokenId) {
        require(_approved != address(0), "Approve to the zero address");
        tokenApprovals[_tokenId] = _approved;
    }

    /// @notice Gets the approved address for a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address approved to spend the NFT.
    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "Approved query for nonexistent token");
        return tokenApprovals[_tokenId];
    }

    /// @notice Sets approval for an operator to manage all NFTs of the sender.
    /// @param _operator The address to be set as an operator.
    /// @param _approved True if the operator is approved, false to revoke approval.
    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        require(_operator != msg.sender, "Approve to caller");
        operatorApprovals[msg.sender][_operator] = _approved;
    }

    /// @notice Checks if an operator is approved for all NFTs of an owner.
    /// @param _owner The owner of the NFTs.
    /// @param _operator The operator to check for approval.
    /// @return True if the operator is approved, false otherwise.
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    // --- Evolution & Staking Functions ---

    /// @notice Stakes an NFT to begin its evolution process.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) public whenNotPaused onlyOwnerOfToken(_tokenId) {
        require(!isStaked[_tokenId], "NFT is already staked");
        isStaked[_tokenId] = true;
        stakeStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @notice Unstakes an NFT, pausing its evolution.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) public whenNotPaused onlyOwnerOfToken(_tokenId) {
        require(isStaked[_tokenId], "NFT is not staked");
        isStaked[_tokenId] = false;
        stakeStartTime[_tokenId] = 0;
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /// @notice Manually triggers the evolution process for a staked NFT.
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) public whenNotPaused onlyOwnerOfToken(_tokenId) {
        require(isStaked[_tokenId], "NFT must be staked to evolve");
        uint256 currentStage = nftStage[_tokenId];
        require(currentStage < maxEvolutionStages, "NFT is already at max stage");

        uint256 timeElapsed = block.timestamp - lastEvolutionTime[_tokenId];
        if (timeElapsed >= evolutionStageDuration) {
            nftStage[_tokenId]++;
            lastEvolutionTime[_tokenId] = block.timestamp;
            emit NFTEvolved(_tokenId, nftStage[_tokenId]);
        } else {
            revert("Evolution time not yet reached");
        }
    }

    /// @notice Returns the current evolution stage of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The current evolution stage (uint256).
    function getNFTStage(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Stage query for nonexistent token");
        return nftStage[_tokenId];
    }

    /// @notice Returns the staking status of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return True if staked, false otherwise.
    function getStakingStatus(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Staking status query for nonexistent token");
        return isStaked[_tokenId];
    }

    /// @notice Allows owner to claim rewards upon reaching certain evolution stages.
    /// @param _tokenId The ID of the NFT to claim rewards for.
    function claimEvolutionRewards(uint256 _tokenId) public whenNotPaused onlyOwnerOfToken(_tokenId) {
        require(_exists(_tokenId), "Reward claim for nonexistent token");
        require(isStaked[_tokenId], "NFT must be staked to claim rewards");
        uint256 currentStage = nftStage[_tokenId];
        // Example reward logic - can be expanded to transfer tokens, etc.
        uint256 rewardAmount = currentStage * stakingRewardPerStage;
        // In a real scenario, you might transfer ERC20 tokens or perform other actions here.
        // For this example, we'll just emit an event.
        emit NFTClaimedReward(_tokenId, msg.sender, rewardAmount);
    }

    event NFTClaimedReward(uint256 indexed tokenId, address indexed owner, uint256 rewardAmount);


    // --- Governance & Customization Functions ---

    /// @notice Allows NFT holders to propose changes to evolution parameters.
    /// @param _parameterName The name of the parameter to change (e.g., "evolutionStageDuration").
    /// @param _newValue The new value for the parameter.
    /// @param _description Description of the proposal.
    function proposeEvolutionParameterChange(string memory _parameterName, uint256 _newValue, string memory _description) public whenNotPaused {
        require(balanceOf(msg.sender) > 0, "Only NFT holders can propose changes");
        require(bytes(_parameterName).length > 0 && bytes(_description).length > 0, "Parameter name and description required");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            parameterName: _parameterName,
            newValue: _newValue,
            description: _description,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: true
        });

        emit EvolutionParameterProposed(proposalId, _parameterName, _newValue, msg.sender);
    }

    /// @notice Allows NFT holders to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True to vote for, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(balanceOf(msg.sender) > 0, "Only NFT holders can vote");
        require(proposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        if (_vote) {
            proposals[_proposalId].votesFor += balanceOf(msg.sender);
        } else {
            proposals[_proposalId].votesAgainst += balanceOf(msg.sender);
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a successful proposal after voting period.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused onlyContractOwner { // Only contract owner can execute after voting passes
        require(proposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 requiredVotes = (totalSupply * quorumPercentage) / 100;

        if (proposals[_proposalId].votesFor >= requiredVotes && proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst) {
            if (keccak256(abi.encodePacked(proposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("evolutionStageDuration"))) {
                evolutionStageDuration = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("maxEvolutionStages"))) {
                maxEvolutionStages = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("stakingRewardPerStage"))) {
                stakingRewardPerStage = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
                votingDuration = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
                quorumPercentage = proposals[_proposalId].newValue;
            }
            // Add more parameters to be governed here as needed

            proposals[_proposalId].executed = true;
            proposals[_proposalId].active = false;
            emit ProposalExecuted(_proposalId);
        } else {
            proposals[_proposalId].active = false; // Proposal failed
            revert("Proposal failed to reach quorum or majority");
        }
    }

    /// @notice Returns the current state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalState(uint256 _proposalId) public view returns (Proposal memory) {
        require(_existsProposal(_proposalId), "Proposal does not exist");
        return proposals[_proposalId];
    }

    /// @notice Admin function to set the base URI for NFT metadata.
    /// @param _newBaseURI The new base URI string.
    function setBaseURI(string memory _newBaseURI) public onlyContractOwner {
        baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI, msg.sender);
    }

    /// @notice Admin function to pause core functionalities of the contract.
    function pauseContract() public onlyContractOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() public onlyContractOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Admin function to withdraw contract balance.
    function withdrawContractBalance() public onlyContractOwner {
        payable(contractOwner).transfer(address(this).balance);
    }


    // --- Internal helper functions ---
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return ownerOf[_tokenId] != address(0);
    }

    function _existsProposal(uint256 _proposalId) internal view returns (bool) {
        return proposals[_proposalId].startTime != 0; // Basic check if proposal exists
    }

    function _clearApproval(uint256 _tokenId) private {
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }
    }
}

// --- Library for string conversions ---
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c794ac4837067380aa478538aa56d3/oraclizeAPI_0.5.sol

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
```