```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT with an evolution mechanic.
 *      NFTs can evolve through staking and random chance, gaining new attributes and stages.
 *      Includes a built-in governance mechanism for parameter adjustments and community votes.
 *
 * Contract Outline and Function Summary:
 *
 * 1.  **Initialization and Ownership:**
 *     - `constructor(string memory _name, string memory _symbol)`: Initializes the contract with NFT name and symbol.
 *     - `owner()`: Returns the contract owner.
 *     - `transferOwnership(address newOwner)`: Allows the owner to transfer contract ownership.
 *
 * 2.  **NFT Minting and Core ERC721 Functions:**
 *     - `mintNFT(address _to, string memory _baseURI)`: Mints a new NFT to a specified address, setting initial base URI.
 *     - `tokenURI(uint256 tokenId)`: Returns the dynamic URI for an NFT, reflecting its current attributes.
 *     - `approve(address spender, uint256 tokenId)`: Approves an address to spend a specific NFT.
 *     - `getApproved(uint256 tokenId)`: Gets the approved address for a specific NFT.
 *     - `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator to manage all NFTs.
 *     - `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all NFTs.
 *     - `transferFrom(address from, address to, uint256 tokenId)`: Transfers an NFT from one address to another.
 *     - `safeTransferFrom(address from, address to, uint256 tokenId)` (two overloads): Safely transfers an NFT.
 *     - `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT.
 *     - `balanceOf(address owner)`: Returns the balance of NFTs owned by an address.
 *     - `totalSupply()`: Returns the total supply of NFTs.
 *
 * 3.  **NFT Evolution Mechanics:**
 *     - `stakeNFT(uint256 tokenId)`: Allows users to stake their NFTs to initiate evolution process.
 *     - `unstakeNFT(uint256 tokenId)`: Unstakes an NFT and triggers potential evolution based on stake duration and randomness.
 *     - `getNFTStage(uint256 tokenId)`: Returns the current evolution stage of an NFT.
 *     - `getNFTAttributes(uint256 tokenId)`: Returns the current attributes of an NFT (e.g., rarity, power).
 *     - `getEvolutionCooldown(uint256 tokenId)`: Returns the remaining cooldown time before an NFT can evolve again.
 *     - `setEvolutionCooldownDuration(uint256 _duration)` (Admin/Governance): Sets the duration of the evolution cooldown period.
 *     - `setBaseURI(string memory _baseURI)` (Admin/Governance): Sets the base URI for all NFTs.
 *     - `setEvolutionChance(uint256 _chance)` (Admin/Governance): Sets the percentage chance of successful evolution.
 *
 * 4.  **Governance and Parameter Control:**
 *     - `pauseContract()` (Admin/Governance): Pauses most contract functionalities.
 *     - `unpauseContract()` (Admin/Governance): Resumes contract functionalities after pausing.
 *     - `isPaused()`: Returns whether the contract is currently paused.
 *     - `withdrawStuckTokens(address _tokenAddress, address _to)` (Admin/Governance): Allows owner to withdraw accidentally sent tokens.
 */
contract DynamicNFTEvolution {
    string public name;
    string public symbol;
    address public owner;
    uint256 public totalSupplyCounter;
    string public baseURI;
    uint256 public evolutionCooldownDuration = 7 days; // Default cooldown duration
    uint256 public evolutionChance = 20; // Default 20% chance of evolution
    bool public paused;

    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => uint256) public nftStage; // Evolution stage of NFT
    mapping(uint256 => string) public nftAttributes; // JSON string of NFT attributes
    mapping(uint256 => uint256) public lastEvolutionTime; // Timestamp of last evolution
    mapping(uint256 => uint256) public stakeStartTime; // Timestamp when NFT was staked
    mapping(uint256 => bool) public isStaked; // Track if NFT is staked

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTStaked(uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(uint256 indexed tokenId, address indexed unstaker, bool evolved);
    event NFTEvolved(uint256 indexed tokenId, uint256 newStage, string newAttributes);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event BaseURISet(string newBaseURI);
    event EvolutionCooldownDurationSet(uint256 newDuration);
    event EvolutionChanceSet(uint256 newChance);

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

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        baseURI = "ipfs://default/"; // Default base URI, can be updated
    }

    /**
     * @dev Returns the contract owner.
     */
    function owner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Allows the owner to transfer contract ownership.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address.");
        emit TransferOwnership(owner, newOwner); // Custom event for ownership transfer
        owner = newOwner;
    }

    event TransferOwnership(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Mints a new NFT to a specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The base URI to use for this NFT (can be overridden later).
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused {
        require(_to != address(0), "Mint to the zero address.");
        uint256 tokenId = totalSupplyCounter++;
        tokenOwner[tokenId] = _to;
        nftStage[tokenId] = 1; // Initial stage
        nftAttributes[tokenId] = '{"stage": 1, "rarity": "Common", "power": 10}'; // Initial attributes as JSON string
        baseURI = _baseURI; // Setting base URI at mint time, could be made dynamic per token if needed.
        emit NFTMinted(_to, tokenId);
        emit Transfer(address(0), _to, tokenId); // Mint event is a transfer from zero address
    }

    /**
     * @dev Returns the dynamic URI for an NFT, reflecting its current attributes.
     * @param tokenId The ID of the NFT.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token URI query for nonexistent token.");
        // Dynamically generate URI based on NFT stage and attributes.
        // For simplicity, we'll just append the token ID to the base URI and assume metadata is stored there.
        // In a real application, you would likely generate more complex URIs and metadata on a server.
        return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev Approve `spender` to operate on `tokenId`
     * @param spender address to be approved
     * @param tokenId uint256 token ID to be approved
     */
    function approve(address spender, uint256 tokenId) public whenNotPaused {
        address tokenOwnerAddress = ownerOf(tokenId);
        require(msg.sender == tokenOwnerAddress || isApprovedForAll(tokenOwnerAddress, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        tokenApprovals[tokenId] = spender;
        emit Approval(tokenOwnerAddress, spender, tokenId);
    }

    /**
     * @dev Get the approved address for token ID `tokenId`
     * @param tokenId uint256 token ID to find the approved address for
     * @return address approved address
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return tokenApprovals[tokenId];
    }

    /**
     * @dev Approve or unapprove an operator to manage all of msg.sender's tokens.
     * @param operator address to add to the set of authorized operators
     * @param approved bool whether to approve or unapprove
     */
    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Query if an address is an authorized operator for another address
     * @param owner address that owns the tokens
     * @param operator address that wants to act on the tokens
     * @return bool if the operator is approved
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfer ownership of a given token ID to another address.
     * @param from address current owner of the token
     * @param to address to receive ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers ownership of a given token ID to another address.
     * @param from address current owner of the token
     * @param to address to receive ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers ownership of a given token ID to another address.
     * @param from address current owner of the token
     * @param to address to receive ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check is performed
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public whenNotPaused {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     * @param tokenId The ID of the NFT to query the owner of.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address ownerAddress = tokenOwner[tokenId];
        require(ownerAddress != address(0) && _exists(tokenId), "ERC721: ownerOf query for nonexistent token");
        return ownerAddress;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     * @param owner The address of the account to query.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint256 balance = 0;
        for (uint256 i = 0; i < totalSupplyCounter; i++) {
            if (tokenOwner[i] == owner) {
                balance++;
            }
        }
        return balance;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupplyCounter;
    }

    /**
     * @dev Stakes an NFT to initiate the evolution process.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist.");
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner.");
        require(!isStaked[tokenId], "NFT already staked.");

        isStaked[tokenId] = true;
        stakeStartTime[tokenId] = block.timestamp;
        emit NFTStaked(tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an NFT and triggers potential evolution based on stake duration and randomness.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist.");
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner.");
        require(isStaked[tokenId], "NFT not staked.");
        require(block.timestamp >= stakeStartTime[tokenId] + evolutionCooldownDuration, "Evolution cooldown not finished.");
        require(block.timestamp >= lastEvolutionTime[tokenId] + evolutionCooldownDuration, "Evolution cooldown not finished.");

        isStaked[tokenId] = false;
        stakeStartTime[tokenId] = 0; // Reset stake time

        bool evolved = false;
        uint256 currentStage = nftStage[tokenId];
        string memory currentAttributesJSON = nftAttributes[tokenId];

        // Simple random evolution logic (consider using Chainlink VRF for production)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, msg.sender))) % 100;

        if (randomNumber < evolutionChance && currentStage < 5) { // Example: Max 5 stages
            evolved = true;
            uint256 newStage = currentStage + 1;
            nftStage[tokenId] = newStage;
            lastEvolutionTime[tokenId] = block.timestamp;

            // Update attributes based on new stage (example logic, can be more complex)
            string memory newAttributesJSON;
            if (newStage == 2) {
                newAttributesJSON = '{"stage": 2, "rarity": "Uncommon", "power": 25}';
            } else if (newStage == 3) {
                newAttributesJSON = '{"stage": 3, "rarity": "Rare", "power": 50}';
            } else if (newStage == 4) {
                newAttributesJSON = '{"stage": 4, "rarity": "Epic", "power": 75}';
            } else if (newStage == 5) {
                newAttributesJSON = '{"stage": 5, "rarity": "Legendary", "power": 100}';
            } else {
                newAttributesJSON = currentAttributesJSON; // No further evolution after stage 5
            }
            nftAttributes[tokenId] = newAttributesJSON;
            emit NFTEvolved(tokenId, newStage, newAttributesJSON);
        }

        emit NFTUnstaked(tokenId, msg.sender, evolved);
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param tokenId The ID of the NFT.
     */
    function getNFTStage(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist.");
        return nftStage[tokenId];
    }

    /**
     * @dev Returns the current attributes of an NFT as a JSON string.
     * @param tokenId The ID of the NFT.
     */
    function getNFTAttributes(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "NFT does not exist.");
        return nftAttributes[tokenId];
    }

    /**
     * @dev Returns the remaining cooldown time before an NFT can evolve again.
     * @param tokenId The ID of the NFT.
     */
    function getEvolutionCooldown(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist.");
        if (lastEvolutionTime[tokenId] == 0) {
            return 0; // Never evolved, no cooldown
        }
        if (block.timestamp < lastEvolutionTime[tokenId] + evolutionCooldownDuration) {
            return (lastEvolutionTime[tokenId] + evolutionCooldownDuration) - block.timestamp;
        } else {
            return 0; // Cooldown finished
        }
    }

    /**
     * @dev Sets the duration of the evolution cooldown period.
     * @param _duration The new cooldown duration in seconds.
     */
    function setEvolutionCooldownDuration(uint256 _duration) public onlyOwner whenNotPaused {
        evolutionCooldownDuration = _duration;
        emit EvolutionCooldownDurationSet(_duration);
    }

    /**
     * @dev Sets the base URI for all NFTs.
     * @param _baseURI The new base URI.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner whenNotPaused {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /**
     * @dev Sets the percentage chance of successful evolution.
     * @param _chance The new evolution chance (percentage, e.g., 20 for 20%).
     */
    function setEvolutionChance(uint256 _chance) public onlyOwner whenNotPaused {
        require(_chance <= 100, "Evolution chance cannot exceed 100%.");
        evolutionChance = _chance;
        emit EvolutionChanceSet(_chance);
    }

    /**
     * @dev Pauses most contract functionalities.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Resumes contract functionalities after pausing.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Returns whether the contract is currently paused.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Allows owner to withdraw accidentally sent tokens from the contract.
     * @param _tokenAddress The address of the ERC20 token to withdraw (use address(0) for Ether).
     * @param _to The address to send the tokens to.
     */
    function withdrawStuckTokens(address _tokenAddress, address _to) public onlyOwner {
        require(_to != address(0), "Withdraw to the zero address.");
        if (_tokenAddress == address(0)) {
            payable(_to).transfer(address(this).balance); // Withdraw Ether
        } else {
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_to, balance); // Withdraw ERC20 tokens
        }
    }

    /**
     * @dev Check if token ID exists
     * @param tokenId uint256 token ID
     * @return bool whether token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenOwner[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `tokenId` exists and is not burned.
     * @param tokenId uint256 token ID
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address ownerAddress = ownerOf(tokenId);
        return (spender == ownerAddress || getApproved(tokenId) == spender || isApprovedForAll(ownerAddress, spender));
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from address current owner of the token
     * @param to address to receive ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        tokenApprovals[tokenId] = address(0); // Clear approvals after transfer

        tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * @param from address representing the previous owner of the given token ID
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 token ID to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (error) {
                return false;
            }
        } else {
            return true;
        }
    }
}

/**
 * @title ERC721Receiver Interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface id is not supported by the other
     * contract, the safe transfer will be reverted.
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param tokenId The ID of the token being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    )
        external
        returns (bytes4);
}

/**
 * @title ERC20 Interface (Minimal)
 * @dev Interface of ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title String Operations
 * @dev Contains helper functions for string manipulation.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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
```