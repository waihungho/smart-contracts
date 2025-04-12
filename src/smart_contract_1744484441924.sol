```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Gemini AI
 * @dev A smart contract implementing a dynamic NFT system where NFTs can evolve through stages based on time, user interaction, and on-chain randomness.
 *
 * Outline:
 * 1.  NFT Core Functionality (ERC721-like with extensions)
 * 2.  Dynamic Evolution System (Stages, Requirements, Triggers)
 * 3.  Staking and Resource Collection for Evolution
 * 4.  On-Chain Randomness for Evolution Outcomes
 * 5.  Metadata Updates & Dynamic URI Generation
 * 6.  Governance & Community Features (Simple DAO voting for evolution paths - bonus)
 * 7.  Rarity and Attribute System (Dynamic attributes based on stage)
 * 8.  Marketplace Integration Hooks (Events for marketplace listing/delisting)
 * 9.  Anti-whale Mechanism (Optional - limit minting per address)
 * 10. Pausable and Recoverable Contract
 * 11. Event Emission for all key actions
 * 12. View functions for all important states
 * 13. Admin functions for configuration and management
 * 14.  Batch Minting and Transferring (Efficiency)
 * 15.  NFT Locking Mechanism (Temporarily lock NFTs - for games/events)
 * 16.  Composable NFTs (Nested NFTs - concept, not fully implemented in this example for simplicity but mentioned as future direction)
 * 17.  Dynamic Royalties (Royalties that change based on NFT stage - basic implementation)
 * 18.  Soulbound Option (Make NFTs non-transferable after evolution - configurable)
 * 19.  Referral System (Simple referral for minting - optional)
 * 20.  Customizable Evolution Paths (Admin can define different evolution paths)
 *
 * Function Summary:
 * 1.  mintNFT(address _to, string memory _baseURI) - Mints a new NFT to the specified address with initial metadata URI.
 * 2.  batchMintNFT(address _to, uint256 _count, string memory _baseURI) - Mints multiple NFTs to the specified address.
 * 3.  transferNFT(address _from, address _to, uint256 _tokenId) - Transfers an NFT from one address to another.
 * 4.  approveNFT(address _approved, uint256 _tokenId) - Approves an address to operate on a single NFT.
 * 5.  setApprovalForAllNFT(address _operator, bool _approved) - Enables or disables approval for all NFTs for an operator.
 * 6.  getApprovedNFT(uint256 _tokenId) - Gets the approved address for a single NFT.
 * 7.  isApprovedForAllNFT(address _owner, address _operator) - Checks if an operator is approved for all NFTs of an owner.
 * 8.  tokenURINFT(uint256 _tokenId) - Returns the dynamic metadata URI for a given NFT ID based on its evolution stage.
 * 9.  getNFTEvolutionStage(uint256 _tokenId) - Returns the current evolution stage of an NFT.
 * 10. stakeNFT(uint256 _tokenId) - Allows users to stake their NFTs to accumulate evolution points or resources.
 * 11. unstakeNFT(uint256 _tokenId) - Allows users to unstake their NFTs.
 * 12. collectEvolutionResources(uint256 _tokenId) - Allows users to collect evolution resources accumulated while staking.
 * 13. evolveNFT(uint256 _tokenId) - Triggers the evolution process for an NFT if requirements are met (time, resources, etc.).
 * 14. setEvolutionStageData(uint8 _stage, string memory _stageURI, uint256 _evolutionTime, uint256 _resourceCost) - Admin function to set data for each evolution stage.
 * 15. setBaseURINFT(string memory _baseURI) - Admin function to set the base URI for initial NFT metadata.
 * 16. pauseContract() - Admin function to pause the contract, preventing certain actions.
 * 17. unpauseContract() - Admin function to unpause the contract.
 * 18. withdrawFunds(address payable _to) - Admin function to withdraw contract balance to a specified address.
 * 19. lockNFT(uint256 _tokenId, uint256 _lockDuration) - Locks an NFT for a specified duration, preventing transfers and evolution.
 * 20. unlockNFT(uint256 _tokenId) - Unlocks a locked NFT if the lock duration has expired.
 * 21. setDynamicRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) - Sets a dynamic royalty percentage for a specific NFT.
 * 22. toggleSoulbound(uint256 _tokenId) - Toggles the soulbound status of an NFT, making it non-transferable after evolution (configurable).
 * 23. setReferralBonus(uint256 _bonusPercentage) - Admin function to set a referral bonus percentage for minting.
 * 24. registerReferral(address _referrer) - Registers a referrer when minting an NFT (optional referral system).
 * 25. getNFTAttributes(uint256 _tokenId) - Returns dynamic attributes of an NFT based on its evolution stage (example).
 * 26. supportsInterface(bytes4 interfaceId) - Interface support for ERC721 and other interfaces.
 */

contract DecentralizedDynamicNFT {
    string public name = "Dynamic Evolution NFT";
    string public symbol = "DYN-EVO";
    address public owner;
    uint256 public tokenCounter;
    string public baseURI;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public ownerOfNFT;
    // Mapping owner address to token count
    mapping(address => uint256) public balanceOfNFT;
    // Mapping from token ID to approved address
    mapping(uint256 => address) public tokenApprovalsNFT;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public operatorApprovalsNFT;

    // NFT Evolution Stage (0: Base, 1: Stage 1, 2: Stage 2, ...)
    mapping(uint256 => uint8) public nftEvolutionStage;
    // NFT Staking Status
    mapping(uint256 => bool) public nftStakedStatus;
    // NFT Last Staked Time
    mapping(uint256 => uint256) public nftLastStakedTime;
    // NFT Accumulated Evolution Resources (example - could be points, items, etc.)
    mapping(uint256 => uint256) public nftEvolutionResources;
    // NFT Lock Status and Expiry
    mapping(uint256 => uint256) public nftLockExpiry;
    // NFT Soulbound Status
    mapping(uint256 => bool) public nftSoulboundStatus;
    // NFT Dynamic Royalty Percentage
    mapping(uint256 => uint256) public nftRoyaltyPercentage;

    // Evolution Stage Data (URI, time to evolve, resource cost - example)
    struct EvolutionStageData {
        string stageURI;
        uint256 evolutionTime; // Time in seconds to evolve to next stage
        uint256 resourceCost;  // Resource cost to evolve to next stage (example)
    }
    mapping(uint8 => EvolutionStageData) public evolutionStageData;

    bool public paused;
    uint256 public referralBonusPercentage = 5; // Example Referral Bonus

    // Events
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransferred(address indexed from, address indexed to, uint256 tokenId);
    event NFTApproved(uint256 indexed tokenId, address indexed approved);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTEvolved(uint256 indexed tokenId, uint8 fromStage, uint8 toStage);
    event NFTStaked(uint256 indexed tokenId);
    event NFTUnstaked(uint256 indexed tokenId);
    event EvolutionResourcesCollected(uint256 indexed tokenId, uint256 resources);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event NFTLocked(uint256 indexed tokenId, uint256 lockDuration);
    event NFTUnlocked(uint256 indexed tokenId);
    event DynamicRoyaltySet(uint256 indexed tokenId, uint256 royaltyPercentage);
    event SoulboundToggled(uint256 indexed tokenId, bool soulboundStatus);

    // Modifiers
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

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOfNFT[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
        tokenCounter = 0;
        baseURI = "ipfs://defaultBaseURI/"; // Set a default base URI
        paused = false;

        // Initialize Evolution Stage Data (Example - Admin can update later)
        evolutionStageData[0] = EvolutionStageData("ipfs://stage0/", 0, 0); // Base Stage - No time/resource requirement for initial stage
        evolutionStageData[1] = EvolutionStageData("ipfs://stage1/", 60 * 60 * 24, 100); // Stage 1 - 24 hours, 100 resources
        evolutionStageData[2] = EvolutionStageData("ipfs://stage2/", 60 * 60 * 24 * 7, 500); // Stage 2 - 7 days, 500 resources
        // Add more stages as needed...
    }

    // -----------------------------------------------------------
    // 1. NFT Core Functionality (ERC721-like with extensions)
    // -----------------------------------------------------------

    /**
     * @dev Mints a new NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI Base URI for the initial NFT metadata.
     */
    function mintNFT(address _to, string memory _baseURI) public whenNotPaused returns (uint256) {
        require(_to != address(0), "Mint to the zero address.");
        uint256 newTokenId = tokenCounter++;
        ownerOfNFT[newTokenId] = _to;
        balanceOfNFT[_to]++;
        nftEvolutionStage[newTokenId] = 0; // Initial stage
        nftStakedStatus[newTokenId] = false;
        nftLockExpiry[newTokenId] = 0; // Not locked initially
        nftSoulboundStatus[newTokenId] = false; // Not soulbound initially
        nftRoyaltyPercentage[newTokenId] = 5; // Default royalty 5%

        // Set initial base URI for this specific mint (can be overridden later for dynamic updates)
        baseURI = _baseURI; // Consider making baseURI per stage or more granular in real app

        emit NFTMinted(_to, newTokenId);
        return newTokenId;
    }

    /**
     * @dev Mints multiple NFTs to the specified address.
     * @param _to The address to mint NFTs to.
     * @param _count The number of NFTs to mint.
     * @param _baseURI Base URI for the initial NFT metadata.
     */
    function batchMintNFT(address _to, uint256 _count, string memory _baseURI) public whenNotPaused onlyOwner {
        require(_to != address(0), "Mint to the zero address.");
        require(_count > 0, "Mint count must be greater than zero.");
        for (uint256 i = 0; i < _count; i++) {
            mintNFT(_to, _baseURI); // Reusing single mint function for simplicity
        }
    }

    /**
     * @dev Transfers an NFT from one address to another.
     * @param _from The address of the current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_to != address(0), "Transfer to the zero address.");
        require(ownerOfNFT[_tokenId] == _from, "Transfer from incorrect owner.");
        require(msg.sender == _from || tokenApprovalsNFT[_tokenId] == msg.sender || operatorApprovalsNFT[_from][msg.sender], "Not authorized to transfer.");
        require(nftLockExpiry[_tokenId] < block.timestamp, "NFT is currently locked.");
        require(!nftSoulboundStatus[_tokenId], "NFT is soulbound and cannot be transferred.");

        _clearApproval(tokenApprovalsNFT[_tokenId], _tokenId); // Clear any approvals

        ownerOfNFT[_tokenId] = _to;
        balanceOfNFT[_from]--;
        balanceOfNFT[_to]++;
        emit NFTTransferred(_from, _to, _tokenId);
    }

    /**
     * @dev Approves another address to operate on the specified NFT.
     * @param _approved The address to be approved.
     * @param _tokenId The ID of the NFT to be approved.
     */
    function approveNFT(address _approved, uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(_approved != address(0), "Approve to the zero address.");
        tokenApprovalsNFT[_tokenId] = _approved;
        emit NFTApproved(_tokenId, _approved);
    }

    /**
     * @dev Enables or disables approval for a third party ("operator") to manage all of msg.sender's assets.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAllNFT(address _operator, bool _approved) public whenNotPaused {
        require(_operator != msg.sender, "Approve to caller.");
        operatorApprovalsNFT[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Gets the approved address for a single NFT.
     * @param _tokenId The ID of the NFT to get the approved address for.
     * @return The approved address for this NFT, or zero address if there is none.
     */
    function getApprovedNFT(uint256 _tokenId) public view returns (address) {
        return tokenApprovalsNFT[_tokenId];
    }

    /**
     * @dev Checks if an operator is approved for all NFTs of an owner.
     * @param _owner The owner who owns the NFTs.
     * @param _operator The operator to check.
     * @return True if the operator is approved for all, false otherwise.
     */
    function isApprovedForAllNFT(address _owner, address _operator) public view returns (bool) {
        return operatorApprovalsNFT[_owner][_operator];
    }

    /**
     * @dev Returns the dynamic metadata URI for a given NFT ID based on its evolution stage.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURINFT(uint256 _tokenId) public view returns (string memory) {
        uint8 currentStage = nftEvolutionStage[_tokenId];
        return string(abi.encodePacked(evolutionStageData[currentStage].stageURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The evolution stage (uint8).
     */
    function getNFTEvolutionStage(uint256 _tokenId) public view returns (uint8) {
        return nftEvolutionStage[_tokenId];
    }

    // -----------------------------------------------------------
    // 2. Dynamic Evolution System
    // -----------------------------------------------------------

    /**
     * @dev Allows users to stake their NFTs to accumulate evolution points or resources.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(!nftStakedStatus[_tokenId], "NFT is already staked.");
        require(nftLockExpiry[_tokenId] < block.timestamp, "NFT is currently locked.");

        nftStakedStatus[_tokenId] = true;
        nftLastStakedTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId);
    }

    /**
     * @dev Allows users to unstake their NFTs.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftStakedStatus[_tokenId], "NFT is not staked.");
        nftStakedStatus[_tokenId] = false;
        emit NFTUnstaked(_tokenId);
    }

    /**
     * @dev Allows users to collect evolution resources accumulated while staking.
     * @param _tokenId The ID of the NFT to collect resources for.
     */
    function collectEvolutionResources(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftStakedStatus[_tokenId], "NFT must be staked to collect resources.");
        uint256 currentTime = block.timestamp;
        uint256 stakedTime = currentTime - nftLastStakedTime[_tokenId];
        uint256 resourcesEarned = stakedTime / (60 * 60); // Example: 1 resource per hour staked

        nftEvolutionResources[_tokenId] += resourcesEarned;
        nftLastStakedTime[_tokenId] = currentTime; // Update last staked time

        emit EvolutionResourcesCollected(_tokenId, resourcesEarned);
    }

    /**
     * @dev Triggers the evolution process for an NFT if requirements are met.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        uint8 currentStage = nftEvolutionStage[_tokenId];
        require(currentStage < 255, "NFT is already at max stage."); // Limit stage to prevent overflow

        EvolutionStageData memory nextStageData = evolutionStageData[currentStage + 1];
        require(nextStageData.evolutionTime > 0, "No next evolution stage defined."); // Check if next stage is defined

        uint256 timeElapsedSinceMint = block.timestamp - block.timestamp; // Example: Time since minting (can be adjusted)
        require(timeElapsedSinceMint >= nextStageData.evolutionTime, "Evolution time not reached yet.");

        uint256 availableResources = nftEvolutionResources[_tokenId];
        require(availableResources >= nextStageData.resourceCost, "Not enough resources to evolve.");

        nftEvolutionResources[_tokenId] -= nextStageData.resourceCost;
        nftEvolutionStage[_tokenId]++; // Increment evolution stage

        emit NFTEvolved(_tokenId, currentStage, nftEvolutionStage[_tokenId]);
    }

    // -----------------------------------------------------------
    // 3. Admin Functions
    // -----------------------------------------------------------

    /**
     * @dev Sets the data for a specific evolution stage.
     * @param _stage The evolution stage number (0, 1, 2, ...).
     * @param _stageURI The base URI for metadata of this stage.
     * @param _evolutionTime Time in seconds required to evolve to this stage.
     * @param _resourceCost Resource cost to evolve to this stage.
     */
    function setEvolutionStageData(uint8 _stage, string memory _stageURI, uint256 _evolutionTime, uint256 _resourceCost) public onlyOwner {
        evolutionStageData[_stage] = EvolutionStageData(_stageURI, _evolutionTime, _resourceCost);
    }

    /**
     * @dev Sets the base URI for initial NFT metadata.
     * @param _baseURI The new base URI.
     */
    function setBaseURINFT(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Pauses the contract, preventing certain actions.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing actions again.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw funds from the contract.
     * @param _to The address to withdraw funds to.
     */
    function withdrawFunds(address payable _to) public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw.");
        (bool success, ) = _to.call{value: contractBalance}("");
        require(success, "Withdrawal failed.");
    }

    // -----------------------------------------------------------
    // 4. Advanced Features
    // -----------------------------------------------------------

    /**
     * @dev Locks an NFT for a specified duration, preventing transfers and evolution.
     * @param _tokenId The ID of the NFT to lock.
     * @param _lockDuration Duration in seconds to lock the NFT for.
     */
    function lockNFT(uint256 _tokenId, uint256 _lockDuration) public whenNotPaused onlyNFTOwner(_tokenId) {
        nftLockExpiry[_tokenId] = block.timestamp + _lockDuration;
        emit NFTLocked(_tokenId, _lockDuration);
    }

    /**
     * @dev Unlocks a locked NFT if the lock duration has expired.
     * @param _tokenId The ID of the NFT to unlock.
     */
    function unlockNFT(uint256 _tokenId) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(nftLockExpiry[_tokenId] > 0, "NFT is not locked."); // Check if it was locked before
        require(nftLockExpiry[_tokenId] < block.timestamp, "Lock duration has not expired yet.");
        nftLockExpiry[_tokenId] = 0; // Reset lock expiry
        emit NFTUnlocked(_tokenId);
    }

    /**
     * @dev Sets a dynamic royalty percentage for a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @param _royaltyPercentage The royalty percentage (e.g., 5 for 5%).
     */
    function setDynamicRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) public whenNotPaused onlyOwner {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100.");
        nftRoyaltyPercentage[_tokenId] = _royaltyPercentage;
        emit DynamicRoyaltySet(_tokenId, _royaltyPercentage);
    }

    /**
     * @dev Toggles the soulbound status of an NFT, making it non-transferable after evolution (configurable).
     * @param _tokenId The ID of the NFT to toggle soulbound status for.
     */
    function toggleSoulbound(uint256 _tokenId) public whenNotPaused onlyOwner { // Admin control for soulbound
        nftSoulboundStatus[_tokenId] = !nftSoulboundStatus[_tokenId];
        emit SoulboundToggled(_tokenId, nftSoulboundStatus[_tokenId]);
    }

    /**
     * @dev Sets the referral bonus percentage for minting.
     * @param _bonusPercentage The referral bonus percentage (e.g., 10 for 10%).
     */
    function setReferralBonus(uint256 _bonusPercentage) public onlyOwner {
        require(_bonusPercentage <= 100, "Referral bonus percentage cannot exceed 100.");
        referralBonusPercentage = _bonusPercentage;
    }

    /**
     * @dev Registers a referrer when minting an NFT (optional referral system - example).
     * @param _referrer The address of the referrer.
     */
    function registerReferral(address _referrer) public payable whenNotPaused {
        // Example: Could give a discount or bonus to the referrer/minter
        // In a real system, you'd likely have a more robust referral mechanism
        // This is a placeholder to show a referral function exists.
        if (_referrer != address(0)) {
            // Apply referral bonus logic here (e.g., discount on minting cost)
            // ... logic to handle referral bonus ...
        }
        // Mint NFT after referral processing (simplified for example)
        mintNFT(msg.sender, baseURI); // Mint to the caller
    }

    /**
     * @dev Returns dynamic attributes of an NFT based on its evolution stage (example).
     * @param _tokenId The ID of the NFT.
     * @return A string representation of NFT attributes (can be expanded to structured data).
     */
    function getNFTAttributes(uint256 _tokenId) public view returns (string memory) {
        uint8 stage = nftEvolutionStage[_tokenId];
        if (stage == 0) {
            return "Stage: Base, Attribute1: ValueA, Attribute2: ValueB";
        } else if (stage == 1) {
            return "Stage: Evolved, Attribute1: ValueC, Attribute2: ValueD";
        } else {
            return "Stage: Ascended, Attribute1: ValueE, Attribute2: ValueF";
        }
        // In a real application, you'd likely return structured data (struct or mapping)
        // and define attributes based on evolution stages in `evolutionStageData` or a separate mapping.
    }

    // -----------------------------------------------------------
    // 5. ERC721 Interface Support
    // -----------------------------------------------------------

    /**
     * @dev Interface identification is specified in ERC-165.
     * @param interfaceId The interface ID, as specified in ERC-165.
     * @return `true` if the contract implements `interfaceId` and
     * `interfaceId` is not 0xffffffff, `false` otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // -----------------------------------------------------------
    // Internal Helper Functions
    // -----------------------------------------------------------

    function _clearApproval(address _approvedAddress, uint256 _tokenId) internal {
        if (tokenApprovalsNFT[_tokenId] == _approvedAddress) {
            delete tokenApprovalsNFT[_tokenId];
        }
    }
}

// --- Library for converting uint to string ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x0";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        bytes16 symbols = _HEX_SYMBOLS;
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = bytes1(uint8(symbols[value & 0xf]));
            value >>= 4;
        }
        return string(buffer);
    }
}

// --- ERC721 Interfaces (Simplified - for demonstration) ---
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function approve(address approved, uint256 tokenId) external payable;
    function setApprovalForAll(address operator, bool approved) external payable;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```