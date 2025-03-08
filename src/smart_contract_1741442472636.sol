```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Evolution & DAO Governance Contract
 * @author Bard (AI Assistant)

 * @dev This contract implements a dynamic NFT that can evolve through user interaction and is governed by a Decentralized Autonomous Organization (DAO).
 * It features on-chain evolution based on staking and voting, DAO-controlled parameter adjustments, and dynamic metadata updates.
 *
 * Function Summary:
 *
 * **Core NFT Functions:**
 * 1. mintNFT(address _to, string memory _baseURI): Mints a new NFT to the specified address (Admin only).
 * 2. transferNFT(address _from, address _to, uint256 _tokenId): Transfers an NFT from one address to another (Owner or approved).
 * 3. tokenURI(uint256 _tokenId): Returns the metadata URI for a given token ID.
 * 4. getNFTLevel(uint256 _tokenId): Returns the current evolution level of an NFT.
 * 5. getNFTStakingStartTime(uint256 _tokenId): Returns the staking start time of an NFT, or 0 if not staked.
 *
 * **Dynamic Evolution Functions:**
 * 6. stakeNFT(uint256 _tokenId): Stakes an NFT to initiate its evolution process.
 * 7. unstakeNFT(uint256 _tokenId): Unstakes an NFT, stopping its evolution.
 * 8. evolveNFT(uint256 _tokenId): Manually triggers the evolution check for an NFT (can be time or event-based).
 * 9. setEvolutionStages(uint256[] memory _stages): Sets the evolution stages (time durations) (DAO Governance).
 * 10. getEvolutionStageDuration(uint256 _stage): Returns the duration for a specific evolution stage.
 * 11. getCurrentEvolutionStage(uint256 _tokenId): Returns the current evolution stage index of an NFT.
 *
 * **DAO Governance Functions:**
 * 12. proposeNewParameter(string memory _paramName, uint256 _newValue): Creates a proposal to change a contract parameter (DAO members only).
 * 13. voteOnProposal(uint256 _proposalId, bool _vote): Votes on a proposal (DAO members only).
 * 14. executeProposal(uint256 _proposalId): Executes a proposal if it passes (DAO Governance - Timelock and quorum required).
 * 15. getProposalStatus(uint256 _proposalId): Returns the status of a proposal.
 * 16. addDAOMember(address _member): Adds a new address to the DAO member list (DAO Governance).
 * 17. removeDAOMember(address _member): Removes an address from the DAO member list (DAO Governance).
 * 18. isDAOMember(address _address): Checks if an address is a DAO member.
 * 19. setDAORoles(address _member, bool _canPropose, bool _canExecute): Sets DAO member roles (DAO Governance).
 * 20. getDAORoles(address _member): Gets the roles of a DAO member.
 *
 * **Admin & Utility Functions:**
 * 21. setBaseURI(string memory _baseURI): Sets the base URI for NFT metadata (Admin only).
 * 22. withdrawContractBalance(): Allows the contract owner to withdraw contract balance (Admin only).
 * 23. pauseContract(): Pauses certain contract functionalities (Admin only).
 * 24. unpauseContract(): Resumes paused contract functionalities (Admin only).
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Timers.sol";

contract DynamicNFTEvolutionDAO is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Timers for Timers.Timer;

    // Base URI for NFT metadata
    string public baseURI;

    // Mapping from token ID to evolution level
    mapping(uint256 => uint256) public nftLevels;

    // Mapping from token ID to staking start time (0 if not staked)
    mapping(uint256 => uint256) public nftStakingStartTime;

    // Evolution stages in seconds (e.g., [1 day, 7 days, 30 days] for 3 stages)
    uint256[] public evolutionStages = [86400, 604800, 2592000]; // Default: [1 day, 7 days, 30 days]

    // DAO Members and Roles
    mapping(address => bool) public isDAOMemberAddress;
    mapping(address => DAORoles) public daoMemberRoles;
    struct DAORoles {
        bool canPropose;
        bool canExecute;
    }

    // Proposal struct
    struct Proposal {
        string paramName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime; // Proposal duration
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    uint256 public proposalDuration = 7 days; // Default proposal duration
    uint256 public quorumPercentage = 51; // Default quorum percentage for proposals to pass

    event NFTMinted(uint256 tokenId, address to);
    event NFTStaked(uint256 tokenId, address owner, uint256 startTime);
    event NFTUnstaked(uint256 tokenId, uint256 unstakeTime);
    event NFTEvolved(uint256 tokenId, uint256 newLevel);
    event ProposalCreated(uint256 proposalId, string paramName, uint256 newValue, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event DAOMemberAdded(address member, address addedBy);
    event DAOMemberRemoved(address member, address removedBy);
    event DAORolesUpdated(address member, bool canPropose, bool canExecute, address updatedBy);
    event BaseURISet(string newBaseURI, address setter);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event ContractBalanceWithdrawn(uint256 amount, address withdrawnBy);


    constructor(string memory _baseURI) ERC721("DynamicNFT", "DNFT") {
        baseURI = _baseURI;
        // Deployer is the initial DAO member with all roles
        isDAOMemberAddress[msg.sender] = true;
        daoMemberRoles[msg.sender] = DAORoles({canPropose: true, canExecute: true});
    }

    // ----------- Core NFT Functions -----------

    /**
     * @dev Mints a new NFT to the specified address. Only callable by the contract owner.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The base URI for the token metadata.
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(_to, tokenId);
        nftLevels[tokenId] = 1; // Initial level is 1
        baseURI = _baseURI; // Update base URI if needed on mint
        emit NFTMinted(tokenId, _to);
    }

    /**
     * @dev Transfers an NFT from one address to another.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not token owner nor approved");
        transferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev Returns the metadata URI for a given token ID.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    /**
     * @dev Returns the current evolution level of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The evolution level.
     */
    function getNFTLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return nftLevels[_tokenId];
    }

    /**
     * @dev Returns the staking start time of an NFT, or 0 if not staked.
     * @param _tokenId The ID of the NFT.
     * @return The staking start time (timestamp).
     */
    function getNFTStakingStartTime(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return nftStakingStartTime[_tokenId];
    }


    // ----------- Dynamic Evolution Functions -----------

    /**
     * @dev Stakes an NFT to initiate its evolution process.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not token owner nor approved");
        require(nftStakingStartTime[_tokenId] == 0, "Token is already staked");

        nftStakingStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender, block.timestamp);
    }

    /**
     * @dev Unstakes an NFT, stopping its evolution.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not token owner nor approved");
        require(nftStakingStartTime[_tokenId] != 0, "Token is not staked");

        nftStakingStartTime[_tokenId] = 0;
        emit NFTUnstaked(_tokenId, block.timestamp);
    }

    /**
     * @dev Manually triggers the evolution check for an NFT. Can be called by anyone, but evolution happens based on time.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(nftStakingStartTime[_tokenId] != 0, "Token is not staked");

        uint256 currentLevel = nftLevels[_tokenId];
        uint256 stakingDuration = block.timestamp - nftStakingStartTime[_tokenId];

        if (currentLevel < evolutionStages.length) {
            if (stakingDuration >= evolutionStages[currentLevel - 1]) {
                nftLevels[_tokenId]++;
                emit NFTEvolved(_tokenId, nftLevels[_tokenId]);
            }
        } else {
            // Max level reached
        }
    }

    /**
     * @dev Sets the evolution stages (time durations). Only callable by DAO members with execute role.
     * @param _stages An array of evolution stage durations in seconds.
     */
    function setEvolutionStages(uint256[] memory _stages) public onlyDAOMemberWithExecuteRole {
        evolutionStages = _stages;
    }

    /**
     * @dev Returns the duration for a specific evolution stage.
     * @param _stage The stage index (starting from 1).
     * @return The duration in seconds.
     */
    function getEvolutionStageDuration(uint256 _stage) public view returns (uint256) {
        require(_stage > 0 && _stage <= evolutionStages.length, "Invalid evolution stage");
        return evolutionStages[_stage - 1];
    }

    /**
     * @dev Returns the current evolution stage index of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current evolution stage index (starting from 1).
     */
    function getCurrentEvolutionStage(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return nftLevels[_tokenId];
    }


    // ----------- DAO Governance Functions -----------

    /**
     * @dev Creates a proposal to change a contract parameter. Only callable by DAO members with propose role.
     * @param _paramName The name of the parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function proposeNewParameter(string memory _paramName, uint256 _newValue) public onlyDAOMemberWithProposeRole whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        proposals[proposalId] = Proposal({
            paramName: _paramName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });
        emit ProposalCreated(proposalId, _paramName, _newValue, msg.sender);
    }

    /**
     * @dev Votes on a proposal. Only callable by DAO members.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyDAOMember whenNotPaused {
        require(proposals[_proposalId].startTime != 0, "Proposal does not exist");
        require(block.timestamp < proposals[_proposalId].endTime, "Proposal voting period ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a proposal if it passes. Only callable by DAO members with execute role after proposal duration.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyDAOMemberWithExecuteRole whenNotPaused {
        require(proposals[_proposalId].startTime != 0, "Proposal does not exist");
        require(block.timestamp >= proposals[_proposalId].endTime, "Proposal voting period not ended yet");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        uint256 totalVotes = proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst;
        uint256 percentageFor = (proposals[_proposalId].votesFor * 100) / totalVotes;

        if (percentageFor >= quorumPercentage) {
            proposals[_proposalId].passed = true;
            if (keccak256(abi.encodePacked(proposals[_proposalId].paramName)) == keccak256(abi.encodePacked("proposalDuration"))) {
                proposalDuration = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].paramName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
                quorumPercentage = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].paramName)) == keccak256(abi.encodePacked("evolutionStage1"))) {
                if (evolutionStages.length > 0) evolutionStages[0] = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].paramName)) == keccak256(abi.encodePacked("evolutionStage2"))) {
                if (evolutionStages.length > 1) evolutionStages[1] = proposals[_proposalId].newValue;
            } else if (keccak256(abi.encodePacked(proposals[_proposalId].paramName)) == keccak256(abi.encodePacked("evolutionStage3"))) {
                if (evolutionStages.length > 2) evolutionStages[2] = proposals[_proposalId].newValue;
            }
            // Add more parameters to be governed by DAO here...

        } else {
            proposals[_proposalId].passed = false;
        }
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId, proposals[_proposalId].passed);
    }

    /**
     * @dev Returns the status of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Status information including start time, end time, votes, etc.
     */
    function getProposalStatus(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Adds a new address to the DAO member list. Only callable by DAO members with execute role.
     * @param _member The address to add to the DAO.
     */
    function addDAOMember(address _member) public onlyDAOMemberWithExecuteRole {
        isDAOMemberAddress[_member] = true;
        daoMemberRoles[_member] = DAORoles({canPropose: false, canExecute: false}); // Default roles
        emit DAOMemberAdded(_member, msg.sender);
    }

    /**
     * @dev Removes an address from the DAO member list. Only callable by DAO members with execute role.
     * @param _member The address to remove from the DAO.
     */
    function removeDAOMember(address _member) public onlyDAOMemberWithExecuteRole {
        delete isDAOMemberAddress[_member];
        delete daoMemberRoles[_member];
        emit DAOMemberRemoved(_member, msg.sender);
    }

    /**
     * @dev Checks if an address is a DAO member.
     * @param _address The address to check.
     * @return True if the address is a DAO member, false otherwise.
     */
    function isDAOMember(address _address) public view returns (bool) {
        return isDAOMemberAddress[_address];
    }

    /**
     * @dev Sets the roles of a DAO member. Only callable by DAO members with execute role.
     * @param _member The address of the DAO member.
     * @param _canPropose Whether the member can create proposals.
     * @param _canExecute Whether the member can execute proposals.
     */
    function setDAORoles(address _member, bool _canPropose, bool _canExecute) public onlyDAOMemberWithExecuteRole {
        require(isDAOMemberAddress[_member], "Address is not a DAO member");
        daoMemberRoles[_member].canPropose = _canPropose;
        daoMemberRoles[_member].canExecute = _canExecute;
        emit DAORolesUpdated(_member, _canPropose, _canExecute, msg.sender);
    }

    /**
     * @dev Gets the roles of a DAO member.
     * @param _member The address of the DAO member.
     * @return Struct containing the roles (canPropose, canExecute).
     */
    function getDAORoles(address _member) public view returns (DAORoles memory) {
        return daoMemberRoles[_member];
    }


    // ----------- Admin & Utility Functions -----------

    /**
     * @dev Sets the base URI for NFT metadata. Only callable by the contract owner.
     * @param _baseURI The new base URI string.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI, msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw contract balance.
     */
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit ContractBalanceWithdrawn(balance, msg.sender);
    }

    /**
     * @dev Pauses certain contract functionalities. Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Resumes paused contract functionalities. Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // ----------- Modifiers -----------

    modifier onlyDAOMember() {
        require(isDAOMemberAddress[msg.sender], "You are not a DAO member");
        _;
    }

    modifier onlyDAOMemberWithProposeRole() {
        require(isDAOMemberAddress[msg.sender] && daoMemberRoles[msg.sender].canPropose, "You are not a DAO member with propose role");
        _;
    }

    modifier onlyDAOMemberWithExecuteRole() {
        require(isDAOMemberAddress[msg.sender] && daoMemberRoles[msg.sender].canExecute, "You are not a DAO member with execute role");
        _;
    }

    // ----------- Overrides for ERC721 -----------
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override whenNotPaused {
        super._burn(tokenId);
    }

    // ----------- Support for string conversion for tokenURI -----------
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
}
```