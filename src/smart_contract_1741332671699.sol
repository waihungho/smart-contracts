```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Evolution & DAO Governance Contract
 * @author Bard (Example Smart Contract)
 *
 * @notice This contract implements a dynamic NFT system where NFT traits evolve based on community votes and external data (simulated oracle).
 * It incorporates DAO governance for managing NFT evolution parameters, treasury, and community proposals.
 *
 * **Outline:**
 * 1. **Dynamic NFT Functionality:**
 *    - Minting Dynamic NFTs with initial traits.
 *    - Trait evolution mechanism based on community votes and simulated oracle.
 *    - NFT trait retrieval and metadata URI generation.
 *    - NFT transfer and ownership management.
 * 2. **DAO Governance:**
 *    - Proposal submission and voting system for trait evolution, parameter changes, etc.
 *    - Treasury management for community funds.
 *    - Role-based access control for administrative functions.
 * 3. **Simulated Oracle Integration (for demonstration):**
 *    - Function to simulate external data feed that can influence NFT traits.
 *
 * **Function Summary:**
 * 1. `mintDynamicNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT to the specified address with an initial base URI.
 * 2. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT to another address.
 * 3. `getNFTOwner(uint256 _tokenId)`: Returns the owner of a specific NFT.
 * 4. `getNFTTrait(uint256 _tokenId, string memory _traitName)`: Retrieves a specific trait value for an NFT.
 * 5. `setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: (Admin only) Directly sets a trait value for an NFT (for initial setup/emergency).
 * 6. `getNFTMetadataURI(uint256 _tokenId)`: Generates and returns the metadata URI for a given NFT, dynamically reflecting its traits.
 * 7. `submitTraitEvolutionProposal(uint256 _tokenId, string memory _traitName, string memory _proposedValue, string memory _description)`: Allows NFT holders to submit proposals to evolve NFT traits.
 * 8. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows DAO members to vote on pending proposals.
 * 9. `executeProposal(uint256 _proposalId)`: Executes a passed proposal, updating NFT traits or contract parameters.
 * 10. `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 * 11. `getProposalVoteCount(uint256 _proposalId)`: Returns the current vote count for a proposal.
 * 12. `depositToTreasury() payable`: Allows anyone to deposit ETH into the DAO treasury.
 * 13. `withdrawFromTreasury(address _to, uint256 _amount)`: (Admin only) Allows withdrawing ETH from the treasury to a specified address.
 * 14. `getTreasuryBalance()`: Returns the current balance of the DAO treasury.
 * 15. `setVotingDuration(uint256 _durationInBlocks)`: (Admin only) Sets the voting duration for proposals.
 * 16. `setQuorumPercentage(uint256 _percentage)`: (Admin only) Sets the quorum percentage required for proposals to pass.
 * 17. `simulateExternalDataFeed(string memory _data)`: (Admin only - Simulation) Simulates an external data feed that can be used in future trait evolution logic.
 * 18. `triggerOracleTraitEvolution(uint256 _tokenId)`: (Admin only - Simulation) Triggers a trait evolution based on the simulated oracle data for a specific NFT.
 * 19. `pauseContract()`: (Admin only) Pauses critical contract functionalities.
 * 20. `unpauseContract()`: (Admin only) Resumes paused contract functionalities.
 * 21. `isAdmin(address _account)`: Checks if an address is an admin.
 * 22. `addAdmin(address _newAdmin)`: (Admin only) Adds a new admin.
 * 23. `removeAdmin(address _adminToRemove)`: (Admin only) Removes an admin.
 */

contract DynamicNFTDAO {
    // --- State Variables ---

    string public contractName = "DynamicNFT";
    string public contractSymbol = "D-NFT";

    address public admin; // Contract administrator
    mapping(address => bool) public admins; // List of admins

    uint256 public nftCounter; // Counter for NFT IDs
    mapping(uint256 => address) public nftOwners; // NFT ID to owner mapping
    mapping(uint256 => mapping(string => string)) public nftTraits; // NFT ID to traits mapping
    mapping(uint256 => string) public nftBaseURIs; // NFT ID to base URI

    uint256 public proposalCounter;
    struct Proposal {
        uint256 tokenId;
        string traitName;
        string proposedValue;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address proposer;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => votedYes

    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50; // Percentage of votes needed to pass a proposal

    address payable public treasury; // DAO Treasury
    string public simulatedOracleData; // For demonstration - simulated external data

    bool public paused = false; // Contract pause state

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event TraitUpdated(uint256 tokenId, string traitName, string oldValue, string newValue);
    event ProposalSubmitted(uint256 proposalId, uint256 tokenId, string traitName, string proposedValue, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier validNFT(uint256 _tokenId) {
        require(nftOwners[_tokenId] != address(0), "Invalid NFT ID");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].proposer != address(0), "Invalid Proposal ID");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.number >= proposals[_proposalId].startTime && block.number <= proposals[_proposalId].endTime, "Voting period is not active");
        _;
    }

    // --- Constructor ---

    constructor() payable {
        admin = msg.sender;
        admins[admin] = true;
        treasury = payable(address(this)); // Contract itself acts as treasury initially
    }

    // --- Admin Functions ---

    function isAdmin(address _account) public view returns (bool) {
        return admins[_account];
    }

    function addAdmin(address _newAdmin) public onlyAdmin {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _adminToRemove) public onlyAdmin {
        require(_adminToRemove != admin, "Cannot remove initial admin through this function"); // Prevent removing initial admin accidentally
        admins[_adminToRemove] = false;
    }

    function setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public onlyAdmin validNFT(_tokenId) {
        string memory oldValue = nftTraits[_tokenId][_traitName];
        nftTraits[_tokenId][_traitName] = _traitValue;
        emit TraitUpdated(_tokenId, _traitName, oldValue, _traitValue);
    }

    function withdrawFromTreasury(address _to, uint256 _amount) public onlyAdmin {
        require(address(treasury).balance >= _amount, "Insufficient treasury balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Treasury withdrawal failed");
        emit TreasuryWithdrawal(_to, _amount);
    }

    function setVotingDuration(uint256 _durationInBlocks) public onlyAdmin {
        votingDurationBlocks = _durationInBlocks;
    }

    function setQuorumPercentage(uint256 _percentage) public onlyAdmin {
        require(_percentage <= 100, "Quorum percentage cannot exceed 100");
        quorumPercentage = _percentage;
    }

    function simulateExternalDataFeed(string memory _data) public onlyAdmin {
        simulatedOracleData = _data;
    }

    function triggerOracleTraitEvolution(uint256 _tokenId) public onlyAdmin validNFT(_tokenId) {
        // Example logic: Evolve a trait based on simulatedOracleData
        // This is a simplified example for demonstration. Real oracle integration is more complex.
        if (bytes(simulatedOracleData).length > 0) {
            string memory currentTrait = nftTraits[_tokenId]["environment"];
            string memory newTrait;
            if (keccak256(bytes(simulatedOracleData)) == keccak256(bytes("Sunny"))) {
                newTrait = "Blooming";
            } else if (keccak256(bytes(simulatedOracleData)) == keccak256(bytes("Rainy"))) {
                newTrait = "Growing";
            } else {
                newTrait = "Neutral";
            }

            if (keccak256(bytes(currentTrait)) != keccak256(bytes(newTrait))) {
                nftTraits[_tokenId]["environment"] = newTrait;
                emit TraitUpdated(_tokenId, "environment", currentTrait, newTrait);
            }
        }
    }

    function pauseContract() public onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }


    // --- NFT Functions ---

    function mintDynamicNFT(address _to, string memory _baseURI) public whenNotPaused {
        uint256 tokenId = nftCounter++;
        nftOwners[tokenId] = _to;
        nftBaseURIs[tokenId] = _baseURI;

        // Initialize default traits (can be customized)
        nftTraits[tokenId]["generation"] = "Genesis";
        nftTraits[tokenId]["environment"] = "Neutral";
        nftTraits[tokenId]["rarity"] = "Common";

        emit NFTMinted(tokenId, _to);
    }

    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused validNFT(_tokenId) {
        require(msg.sender == nftOwners[_tokenId], "Not NFT owner");
        nftOwners[_tokenId] = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    function getNFTOwner(uint256 _tokenId) public view validNFT(_tokenId) returns (address) {
        return nftOwners[_tokenId];
    }

    function getNFTTrait(uint256 _tokenId, string memory _traitName) public view validNFT(_tokenId) returns (string memory) {
        return nftTraits[_tokenId][_traitName];
    }

    function getNFTMetadataURI(uint256 _tokenId) public view validNFT(_tokenId) returns (string memory) {
        // Dynamically generate metadata URI based on traits.
        // In a real application, you might use IPFS or a more robust system.
        string memory traitsString = "";
        string memory generation = nftTraits[_tokenId]["generation"];
        string memory environment = nftTraits[_tokenId]["environment"];
        string memory rarity = nftTraits[_tokenId]["rarity"];

        traitsString = string(abi.encodePacked(traitsString, "generation:", generation, ","));
        traitsString = string(abi.encodePacked(traitsString, "environment:", environment, ","));
        traitsString = string(abi.encodePacked(traitsString, "rarity:", rarity));


        return string(abi.encodePacked(nftBaseURIs[_tokenId], _toString(_tokenId), "?traits=", traitsString));
    }


    // --- DAO Governance Functions ---

    function submitTraitEvolutionProposal(
        uint256 _tokenId,
        string memory _traitName,
        string memory _proposedValue,
        string memory _description
    ) public whenNotPaused validNFT(_tokenId) {
        require(nftOwners[_tokenId] == msg.sender, "Only NFT owner can submit proposals for this NFT");

        uint256 proposalId = proposalCounter++;
        proposals[proposalId] = Proposal({
            tokenId: _tokenId,
            traitName: _traitName,
            proposedValue: _proposedValue,
            description: _description,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender
        });

        emit ProposalSubmitted(proposalId, _tokenId, _traitName, _proposedValue, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused validProposal(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        proposalVotes[_proposalId][msg.sender] = true;

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public whenNotPaused validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.number > proposals[_proposalId].endTime, "Voting period not ended yet");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;

        if (proposals[_proposalId].yesVotes >= quorum) {
            // Execute the proposal - in this case, update NFT trait
            string memory oldValue = nftTraits[proposals[_proposalId].tokenId][proposals[_proposalId].traitName];
            nftTraits[proposals[_proposalId].tokenId][proposals[_proposalId].traitName] = proposals[_proposalId].proposedValue;
            proposals[_proposalId].executed = true;
            emit ProposalExecuted(_proposalId);
            emit TraitUpdated(proposals[_proposalId].tokenId, proposals[_proposalId].traitName, oldValue, proposals[_proposalId].proposedValue);
        } else {
            // Proposal failed - no action taken (or handle failure logic if needed)
            proposals[_proposalId].executed = true; // Mark as executed even if failed to prevent re-execution
        }
    }

    function getProposalDetails(uint256 _proposalId) public view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getProposalVoteCount(uint256 _proposalId) public view validProposal(_proposalId) returns (uint256 yesVotes, uint256 noVotes) {
        return (proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes);
    }

    // --- Treasury Functions ---

    function depositToTreasury() public payable whenNotPaused {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(treasury).balance;
    }


    // --- Utility Functions ---
    function _toString(uint256 _tokenId) internal pure returns (string memory) {
        // Simple uint256 to string conversion - for metadata URI
        if (_tokenId == 0) {
            return "0";
        }
        uint256 j = _tokenId;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_tokenId != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + _tokenId % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _tokenId /= 10;
        }
        return string(bstr);
    }

    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value); // Allow direct ETH deposits to contract
    }
}
```