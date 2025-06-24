Okay, let's design a smart contract that goes beyond typical token standards or simple DeFi interactions. We'll create a "Programmable Asset Network" (PAN) where assets (represented as NFTs) have dynamic properties, can interact with each other, and participate in conditional processes based on their state and connections.

This concept involves on-chain state manipulation of individual assets, creation of relationships between assets, and logic triggered by state or relationships.

---

**Outline and Function Summary: Programmable Asset Network (PAN) Contract**

This contract implements a system where assets (Nodes) are non-fungible tokens (ERC721-like) with dynamic states. Nodes can be linked to form a network, influencing each other's properties and enabling participation in on-chain challenges.

**Core Concepts:**

1.  **Nodes:** ERC721-like tokens with state (Level, Energy, Generation, etc.).
2.  **Links:** Unidirectional connections between owned Nodes, forming a graph.
3.  **Energy:** A consumable/regenerable resource tied to each Node, used for actions like linking or evolving.
4.  **Evolution:** Increasing a Node's Level based on conditions.
5.  **Challenges:** Owner-defined, on-chain mini-games or tasks Nodes can participate in based on their state and links, yielding rewards.
6.  **Environmental Events:** Owner-triggered global modifiers affecting Node behavior (e.g., energy regeneration boost).

**State Variables:**

*   `_nodeCounter`: Auto-incrementing ID for new Nodes.
*   `_nodeData`: Mapping from Node ID to its state (`NodeData` struct).
*   `_nodeLinks`: Mapping from Node ID to an array of Node IDs it links to.
*   `_owners`: Mapping from Node ID to owner address (basic ERC721).
*   `_balances`: Mapping from owner address to count of owned Nodes (basic ERC721).
*   `_approved`: Mapping from Node ID to approved address (basic ERC721).
*   `_operatorApprovals`: Mapping owner => operator => approved (basic ERC721).
*   `_environmentalModifier`: A global value affected by events.
*   `_challengeData`: Details of the current challenge.

**Structs:**

*   `NodeData`: Stores state for a single Node (level, energy, generation, lastEnergyHarvestBlock, etc.).
*   `Challenge`: Stores parameters for a challenge (requiredLevel, requiredLinks, rewardAmount, etc.).

**Events:**

*   `NodeMinted`: When a new Node is created.
*   `NodeTransferred`: When a Node changes owner.
*   `NodeBurned`: When a Node is destroyed.
*   `NodeLinked`: When a link between Nodes is created.
*   `NodeUnlinked`: When a link between Nodes is broken.
*   `NodeEvolved`: When a Node levels up.
*   `EnergyHarvested`: When energy is harvested from a Node.
*   `ChallengeSet`: When a new challenge is configured.
*   `ChallengeCompleted`: When a Node successfully completes a challenge.
*   `EnvironmentalEventTriggered`: When the owner triggers an event.

**Functions (Total: 32)**

*   **ERC721 Standard (8 functions):**
    1.  `balanceOf(address owner)`: Get number of Nodes owned by address. (view)
    2.  `ownerOf(uint256 tokenId)`: Get owner of a specific Node. (view)
    3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer ownership. (external)
    4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer. (external)
    5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer with data. (external)
    6.  `approve(address to, uint256 tokenId)`: Approve address to transfer a Node. (external)
    7.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove operator for all owner's Nodes. (external)
    8.  `getApproved(uint256 tokenId)`: Get the approved address for a Node. (view)
    9.  `isApprovedForAll(address owner, address operator)`: Check if operator is approved for owner. (view)
    10. `supportsInterface(bytes4 interfaceId)`: Check if contract supports an interface (ERC165). (view)
    *   *(Note: ERC721 requires 10 functions including `supportsInterface`. We implement the common set.)*

*   **ERC721 Metadata (2 functions):**
    11. `name()`: Contract name. (view)
    12. `symbol()`: Contract symbol. (view)
    13. `tokenURI(uint256 tokenId)`: Get metadata URI for a Node. (view)
    14. `setBaseURI(string memory baseURI)`: Set base URI for metadata (Owner only). (external)

*   **Ownership (2 functions - using Ownable pattern):**
    15. `owner()`: Get contract owner. (view)
    16. `transferOwnership(address newOwner)`: Transfer contract ownership. (external)
    17. `renounceOwnership()`: Renounce contract ownership. (external)
    *   *(Note: Ownable provides 3 functions)*

*   **Node Management (6 functions):**
    18. `mintNode(address to, uint256 generation)`: Mint a new Node (Owner only). (external)
    19. `burnNode(uint256 tokenId)`: Burn a Node (Owner or approved). (external)
    20. `getNodeDetails(uint256 tokenId)`: Get all stored data for a Node. (view)
    21. `getNodesByOwner(address owner)`: Get list of Node IDs owned by an address (potentially gas-heavy). (view)
    22. `getNumberOfNodes()`: Get total number of Nodes minted. (view)
    23. `updateNodeMetadataUri(uint256 tokenId, string memory newUri)`: Update metadata URI for a specific node (Owner of node or contract owner). (external)

*   **Network & Interaction (5 functions):**
    24. `linkNodes(uint256 fromNodeId, uint256 toNodeId)`: Create a unidirectional link from one owned Node to another owned Node (consumes energy). (external)
    25. `unlinkNodes(uint256 fromNodeId, uint256 toNodeId)`: Remove a link. (external)
    26. `getLinkedNodes(uint256 tokenId)`: Get list of Nodes linked *from* a Node. (view)
    27. `harvestEnergy(uint256 tokenId)`: Harvest energy from a Node (updates energy, returns amount harvested). (external)
    28. `evolveNode(uint256 tokenId)`: Attempt to evolve a Node to the next level (requires energy, potentially links). (external)

*   **Advanced Concepts (5 functions):**
    29. `calculateNodeScore(uint256 tokenId)`: Calculate a score based on Node properties and links. (view)
    30. `triggerEnvironmentalEvent(int256 modifierChange)`: Owner triggers a global event affecting `_environmentalModifier`. (external)
    31. `setChallenge(uint256 requiredLevel, uint256 requiredLinks, uint256 rewardAmount)`: Owner sets parameters for the current challenge. (external)
    32. `participateInChallenge(uint256 tokenId)`: Owner of Node attempts challenge (checks conditions, pseudo-random outcome, updates Node state, potentially rewards). (external)

*(Total functions implemented: 32, meeting the >= 20 requirement)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // Required for supportsInterface


// --- Outline and Function Summary ---
// Contract: Programmable Asset Network (PAN)
// Description: ERC721-like tokens (Nodes) with dynamic state, linkable into a network,
//              participating in on-chain challenges and affected by global events.

// Core Concepts:
// 1. Nodes: ERC721-like tokens with state (Level, Energy, Generation, etc.).
// 2. Links: Unidirectional connections between owned Nodes, forming a graph.
// 3. Energy: A consumable/regenerable resource tied to each Node, used for actions.
// 4. Evolution: Increasing a Node's Level based on conditions.
// 5. Challenges: Owner-defined, on-chain mini-games based on Node state/links.
// 6. Environmental Events: Owner-triggered global modifiers affecting Node behavior.

// State Variables:
// - _nodeCounter: Auto-incrementing ID for new Nodes.
// - _nodeData: Mapping from Node ID to its state (`NodeData` struct).
// - _nodeLinks: Mapping from Node ID to an array of Node IDs it links to.
// - _owners: Mapping from Node ID to owner address (basic ERC721).
// - _balances: Mapping from owner address to count of owned Nodes (basic ERC721).
// - _approved: Mapping from Node ID to approved address (basic ERC721).
// - _operatorApprovals: Mapping owner => operator => approved (basic ERC721).
// - _environmentalModifier: A global value affected by events.
// - _challengeData: Details of the current challenge.
// - _tokenURIs: Mapping from Node ID to specific URI (overrides base URI).
// - _baseTokenURI: Base URI for metadata.

// Structs:
// - NodeData: Node properties (level, energy, generation, lastEnergyUpdateBlock).
// - Challenge: Challenge parameters (requiredLevel, requiredLinks, rewardAmount, isActive).

// Events:
// - NodeMinted, NodeTransferred, NodeBurned, NodeLinked, NodeUnlinked,
// - NodeEvolved, EnergyHarvested, ChallengeSet, ChallengeCompleted,
// - EnvironmentalEventTriggered.

// Functions (32 Total):
// ERC721 Standard (10 functions including ERC165):
// 1. balanceOf(address owner) (view)
// 2. ownerOf(uint256 tokenId) (view)
// 3. transferFrom(address from, address to, uint256 tokenId) (external)
// 4. safeTransferFrom(address from, address to, uint256 tokenId) (external)
// 5. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) (external)
// 6. approve(address to, uint256 tokenId) (external)
// 7. setApprovalForAll(address operator, bool approved) (external)
// 8. getApproved(uint256 tokenId) (view)
// 9. isApprovedForAll(address owner, address operator) (view)
// 10. supportsInterface(bytes4 interfaceId) (view)

// ERC721 Metadata (4 functions):
// 11. name() (view)
// 12. symbol() (view)
// 13. tokenURI(uint256 tokenId) (view)
// 14. setBaseURI(string memory baseURI) (external, Ownable)

// Ownership (3 functions - from Ownable):
// 15. owner() (view)
// 16. transferOwnership(address newOwner) (external, Ownable)
// 17. renounceOwnership() (external, Ownable)

// Node Management (6 functions):
// 18. mintNode(address to, uint256 generation) (external, Ownable)
// 19. burnNode(uint256 tokenId) (external)
// 20. getNodeDetails(uint256 tokenId) (view)
// 21. getNodesByOwner(address owner) (view, potentially gas-heavy)
// 22. getNumberOfNodes() (view)
// 23. updateNodeMetadataUri(uint256 tokenId, string memory newUri) (external)

// Network & Interaction (5 functions):
// 24. linkNodes(uint256 fromNodeId, uint256 toNodeId) (external)
// 25. unlinkNodes(uint256 fromNodeId, uint256 toNodeId) (external)
// 26. getLinkedNodes(uint256 tokenId) (view)
// 27. harvestEnergy(uint256 tokenId) (external)
// 28. evolveNode(uint256 tokenId) (external)

// Advanced Concepts (5 functions):
// 29. calculateNodeScore(uint256 tokenId) (view)
// 30. triggerEnvironmentalEvent(int256 modifierChange) (external, Ownable)
// 31. setChallenge(uint256 requiredLevel, uint256 requiredLinks, uint256 rewardAmount) (external, Ownable)
// 32. participateInChallenge(uint256 tokenId) (external)

contract ProgrammableAssetNetwork is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- State Variables ---

    Counters.Counter private _nodeCounter;

    struct NodeData {
        uint256 level;
        uint256 energy; // Represents internal energy/resource
        uint256 generation;
        uint256 lastEnergyUpdateBlock; // Block number when energy was last updated
        // Add other potential state variables here (e.g., type, lastHarvestBlock, etc.)
    }

    mapping(uint256 => NodeData) private _nodeData;
    mapping(uint256 => uint256[]) private _nodeLinks; // Unidirectional links: tokenId => array of tokenIds it links to

    // ERC721 core mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ERC721 Metadata mappings
    mapping(uint256 => string) private _tokenURIs; // Specific URI per token
    string private _baseTokenURI;

    // Custom state for advanced concepts
    int256 public _environmentalModifier = 0; // Affects energy regeneration, challenge difficulty, etc.

    struct Challenge {
        uint256 requiredLevel;
        uint256 requiredLinks; // Minimum number of outgoing links required
        uint256 rewardAmount; // Simulated reward (e.g., energy boost, virtual points)
        bool isActive;
    }
    Challenge public _challengeData; // Stores the parameters for the current challenge

    // --- Events ---
    event NodeMinted(address indexed to, uint256 indexed tokenId, uint256 generation);
    event NodeTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event NodeBurned(uint256 indexed tokenId);
    event NodeLinked(uint256 indexed fromNodeId, uint256 indexed toNodeId);
    event NodeUnlinked(uint256 indexed fromNodeId, uint256 indexed toNodeId);
    event NodeEvolved(uint256 indexed tokenId, uint256 newLevel);
    event EnergyHarvested(uint256 indexed tokenId, uint256 amountHarvested);
    event ChallengeSet(uint256 requiredLevel, uint256 requiredLinks, uint256 rewardAmount);
    event ChallengeCompleted(uint256 indexed tokenId, uint256 rewardClaimed);
    event EnvironmentalEventTriggered(int256 modifierChange, int256 newModifier);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        // Default challenge is inactive
        _challengeData = Challenge(0, 0, 0, false);
    }

    // --- ERC165 Support ---

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721_METADATA ||
               super.supportsInterface(interfaceId);
    }

    // --- ERC721 Core Implementations ---

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line require-valid-address
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    // --- ERC721 Metadata Implementations ---

    string private _name;
    string private _symbol;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Prioritize token-specific URI
        string memory tokenURI_ = _tokenURIs[tokenId];
        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }

        // Fallback to base URI if set
        if (bytes(_baseTokenURI).length == 0) {
            return "";
        }

        // Append token ID if base URI is set
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    function setBaseURI(string memory baseURI) public virtual onlyOwner {
        _baseTokenURI = baseURI;
    }

    function updateNodeMetadataUri(uint256 tokenId, string memory newUri) public virtual {
        require(_exists(tokenId), "PAN: Token does not exist");
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner || _msgSender() == Ownable.owner(), "PAN: Only token owner or contract owner can update metadata URI");
        _tokenURIs[tokenId] = newUri;
    }

    // --- Internal ERC721 Helpers ---

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approval

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit NodeTransferred(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(
            to.isContract() ?
            _checkOnERC721Received(from, to, tokenId, data) :
            true,
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer (unknown reason)");
            } else {
                /// @solidity automatically catches reverts and appends the reason string.
                revert(string(reason));
            }
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        emit NodeMinted(to, tokenId, _nodeData[tokenId].generation); // Use already set generation
        emit Transfer(address(0), to, tokenId); // Standard ERC721 Transfer event
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist

        _approve(address(0), tokenId); // Clear approvals
        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId]; // Just being explicit

        // Clean up node-specific data
        delete _nodeData[tokenId];
        delete _nodeLinks[tokenId]; // Remove outgoing links
        // Note: Incoming links from other nodes to this burned node are NOT automatically removed.
        // This is an intentional design choice for potential complexity or can be handled
        // off-chain, or require an expensive on-chain cleanup mechanism if needed.

        emit NodeBurned(tokenId);
        emit Transfer(owner, address(0), tokenId); // Standard ERC721 Transfer event
    }

    // --- Custom Node Management Functions ---

    function mintNode(address to, uint256 generation) public virtual onlyOwner {
        _nodeCounter.increment();
        uint256 newItemId = _nodeCounter.current();

        _nodeData[newItemId] = NodeData({
            level: 1,
            energy: 100, // Starting energy
            generation: generation,
            lastEnergyUpdateBlock: block.number
            // Initialize other fields
        });

        _mint(to, newItemId);
    }

    function burnNode(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "PAN: caller is not token owner or approved");
        _burn(tokenId);
    }

    function getNumberOfNodes() public view returns (uint256) {
        return _nodeCounter.current();
    }

    function getNodeDetails(uint256 tokenId) public view returns (NodeData memory) {
         require(_exists(tokenId), "PAN: Token does not exist");
         return _nodeData[tokenId];
    }

    // This function can be very gas-heavy for owners with many tokens.
    // In production, a more efficient enumeration or off-chain indexing might be needed.
    function getNodesByOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        // Simple but potentially inefficient iteration for demo purposes
        uint256[] memory tokens = new uint256[](tokenCount);
        uint256 index = 0;
        // Iterate through all possible token IDs up to the current counter.
        // A more optimized approach involves maintaining an explicit list per owner during transfers.
        // For simplicity in this example, we'll iterate:
        uint256 totalMinted = _nodeCounter.current();
        for (uint256 i = 1; i <= totalMinted; i++) {
            if (_owners[i] == owner) {
                tokens[index] = i;
                index++;
                if (index == tokenCount) break; // Optimization
            }
        }
        return tokens;
    }

    // --- Network & Interaction Functions ---

    // Internal helper to calculate energy based on elapsed blocks and modifier
    function _calculateCurrentEnergy(uint256 tokenId) internal view returns (uint256) {
        NodeData storage node = _nodeData[tokenId];
        uint256 elapsedBlocks = block.number - node.lastEnergyUpdateBlock;
        uint256 regenerationRate = node.level * 1; // Simple regeneration rate based on level
        // Apply environmental modifier (can be positive or negative)
        int256 adjustedRate = int256(regenerationRate) + _environmentalModifier;
        if (adjustedRate < 0) adjustedRate = 0;

        uint256 potentialGain = uint256(adjustedRate) * elapsedBlocks;
        uint256 currentEnergy = node.energy + potentialGain;

        // Cap energy at a max value (e.g., level * 100)
        uint256 maxEnergy = node.level * 100;
        if (maxEnergy == 0) maxEnergy = 100; // Min cap
        return currentEnergy > maxEnergy ? maxEnergy : currentEnergy;
    }

    // Internal helper to update node energy state
    function _updateNodeEnergy(uint256 tokenId) internal {
        NodeData storage node = _nodeData[tokenId];
        node.energy = _calculateCurrentEnergy(tokenId);
        node.lastEnergyUpdateBlock = block.number;
    }


    function linkNodes(uint256 fromNodeId, uint256 toNodeId) public virtual {
        require(_exists(fromNodeId), "PAN: From node does not exist");
        require(_exists(toNodeId), "PAN: To node does not exist");
        require(ownerOf(fromNodeId) == _msgSender(), "PAN: Caller must own the 'from' node");
        require(ownerOf(toNodeId) == _msgSender(), "PAN: Caller must own the 'to' node");
        require(fromNodeId != toNodeId, "PAN: Cannot link a node to itself");

        // Prevent duplicate links
        for (uint i = 0; i < _nodeLinks[fromNodeId].length; i++) {
            if (_nodeLinks[fromNodeId][i] == toNodeId) {
                revert("PAN: Nodes are already linked");
            }
        }

        _updateNodeEnergy(fromNodeId); // Update energy before consuming
        NodeData storage fromNode = _nodeData[fromNodeId];
        uint256 linkCost = fromNode.level * 5; // Cost based on 'from' node level

        require(fromNode.energy >= linkCost, "PAN: From node has insufficient energy to link");

        fromNode.energy -= linkCost;
        _nodeLinks[fromNodeId].push(toNodeId);

        emit NodeLinked(fromNodeId, toNodeId);
    }

    function unlinkNodes(uint256 fromNodeId, uint256 toNodeId) public virtual {
        require(_exists(fromNodeId), "PAN: From node does not exist");
        require(_exists(toNodeId), "PAN: To node does not exist");
        require(ownerOf(fromNodeId) == _msgSender(), "PAN: Caller must own the 'from' node");

        uint256[] storage links = _nodeLinks[fromNodeId];
        bool found = false;
        for (uint i = 0; i < links.length; i++) {
            if (links[i] == toNodeId) {
                // Swap the last element with the one to remove and pop
                links[i] = links[links.length - 1];
                links.pop();
                found = true;
                break; // Assumes only one link between the same two nodes in the same direction
            }
        }

        require(found, "PAN: Link does not exist");

        // Maybe refund some energy or have a small cost to unlink
        // For now, just unlink.

        emit NodeUnlinked(fromNodeId, toNodeId);
    }

    function getLinkedNodes(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "PAN: Token does not exist");
        return _nodeLinks[tokenId];
    }

    function harvestEnergy(uint256 tokenId) public virtual returns (uint256) {
        require(_exists(tokenId), "PAN: Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "PAN: Caller must own the node");

        _updateNodeEnergy(tokenId); // Ensure energy is up-to-date
        NodeData storage node = _nodeData[tokenId];

        uint256 harvestable = node.energy / 2; // Example: Harvest half of current energy
        if (harvestable == 0) {
             // Maybe allow harvesting 1 if energy is low but > 0
             if (node.energy > 0) harvestable = 1; else revert("PAN: Node has no energy to harvest");
        }

        node.energy -= harvestable;
        // node.lastEnergyUpdateBlock = block.number; // Already updated by _updateNodeEnergy

        // In a real system, this might mint a separate resource token or update another state.
        // Here, we just return the amount and update the internal energy state.

        emit EnergyHarvested(tokenId, harvestable);
        return harvestable;
    }

    function evolveNode(uint256 tokenId) public virtual {
        require(_exists(tokenId), "PAN: Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "PAN: Caller must own the node");

        _updateNodeEnergy(tokenId); // Ensure energy is up-to-date
        NodeData storage node = _nodeData[tokenId];

        uint256 requiredEnergy = node.level * 50 + 100; // Example: increases with level
        uint256 requiredLinks = node.level / 2; // Example: increases with level

        require(node.energy >= requiredEnergy, "PAN: Insufficient energy to evolve");
        require(_nodeLinks[tokenId].length >= requiredLinks, "PAN: Insufficient linked nodes to evolve");

        node.energy -= requiredEnergy;
        node.level += 1;
        // node.lastEnergyUpdateBlock = block.number; // Already updated by _updateNodeEnergy

        emit NodeEvolved(tokenId, node.level);
    }

    // --- Advanced Concepts Functions ---

    function calculateNodeScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "PAN: Token does not exist");
        NodeData memory node = _nodeData[tokenId];
        uint256 numLinks = _nodeLinks[tokenId].length;

        // Simple scoring formula: (level * 10) + (currentEnergy / 10) + (numLinks * 5) + (generation * 2)
        // Note: Energy needs to be calculated first to be current
        uint256 currentEnergy = _calculateCurrentEnergy(tokenId); // Use view safe calculation
        return (node.level * 10) + (currentEnergy / 10) + (numLinks * 5) + (node.generation * 2);
    }

    function triggerEnvironmentalEvent(int256 modifierChange) public virtual onlyOwner {
        _environmentalModifier += modifierChange;
        emit EnvironmentalEventTriggered(modifierChange, _environmentalModifier);
    }

    function setChallenge(uint256 requiredLevel, uint256 requiredLinks, uint256 rewardAmount) public virtual onlyOwner {
        _challengeData = Challenge({
            requiredLevel: requiredLevel,
            requiredLinks: requiredLinks,
            rewardAmount: rewardAmount,
            isActive: true
        });
        emit ChallengeSet(requiredLevel, requiredLinks, rewardAmount);
    }

    function participateInChallenge(uint256 tokenId) public virtual {
        require(_challengeData.isActive, "PAN: No active challenge");
        require(_exists(tokenId), "PAN: Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "PAN: Caller must own the node");

        NodeData storage node = _nodeData[tokenId];
        _updateNodeEnergy(tokenId); // Update energy before checks/use

        uint256 numLinks = _nodeLinks[tokenId].length;

        // Check challenge requirements
        require(node.level >= _challengeData.requiredLevel, "PAN: Node level too low for challenge");
        require(numLinks >= _challengeData.requiredLinks, "PAN: Node has insufficient links for challenge");

        // Simulate a pseudo-random outcome based on block data and node properties
        // NOTE: block.timestamp and block.number are easily front-runnable and NOT cryptographically secure.
        // For real applications requiring secure randomness, use Chainlink VRF or similar.
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, node.level, numLinks)));
        bool success = (entropy % 100) < (node.level * 5 + numLinks * 3); // Example success chance formula

        // Apply environmental modifier to challenge difficulty/success chance
        // Let's say positive modifier *decreases* success chance (makes it harder)
        // Or better, positive modifier *increases* success chance (makes it easier)
        if (_environmentalModifier > 0) {
             uint256 bonusChance = uint256(_environmentalModifier) * 2; // Example: +2% chance per modifier point
             success = success || ((entropy / 100) % 100) < bonusChance; // Check another part of entropy
        } else if (_environmentalModifier < 0) {
             uint256 penaltyChance = uint256(-_environmentalModifier) * 2; // Example: -2% chance per modifier point
             success = success && ((entropy / 100) % 100) >= penaltyChance; // Check another part of entropy
        }


        if (success) {
            // Success: Award reward
            uint256 actualReward = _challengeData.rewardAmount;
            // Example: Reward could be added to energy
            node.energy += actualReward;

            emit ChallengeCompleted(tokenId, actualReward);
            // In a real system, you might mint a token here or update a score.
        } else {
            // Failure: Maybe a small penalty or just no reward
            // Example: Consume some energy on failure
            uint256 failureCost = node.level * 2;
            if (node.energy > failureCost) {
                 node.energy -= failureCost;
            } else {
                 node.energy = 0;
            }
            // No event for failure, or a separate one
        }

        // Challenge could become inactive after one attempt per node, or limited uses, etc.
        // For this example, the challenge remains active until owner sets a new one.
    }

    // --- Utility/Helper Functions ---

    // Helper to convert uint256 to string (basic, could use OpenZeppelin's Strings)
    library Strings {
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

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **Dynamic On-Chain State (`NodeData` struct, `_nodeData` mapping):** Unlike typical NFTs which are often static IDs pointing to off-chain metadata, these Nodes have core properties (level, energy, generation) stored directly on-chain in a struct. This allows for complex logic based on these properties without relying solely on external data.
2.  **Programmable Energy (`energy`, `lastEnergyUpdateBlock`, `_calculateCurrentEnergy`, `_updateNodeEnergy`, `harvestEnergy`):** Each Node has a simulated internal resource (Energy) that regenerates over time (based on blocks). This energy is a core mechanic for performing actions like linking or evolving. The calculation includes a global modifier (`_environmentalModifier`). `harvestEnergy` allows extracting this energy, providing a simple on-chain interaction loop.
3.  **On-Chain Network Structure (`_nodeLinks` mapping, `linkNodes`, `unlinkNodes`, `getLinkedNodes`):** Nodes aren't isolated; they can be linked together. This creates an explicit, queryable graph structure on the blockchain. The links are unidirectional (`fromNodeId` -> `toNodeId`) and cost energy to create, adding strategic depth.
4.  **Conditional Evolution (`evolveNode`):** Nodes can increase their `level`, but this isn't automatic. It requires meeting specific criteria based on the Node's current state (energy) and its position/activity in the network (number of links). This makes Node progression an active choice and interaction within the contract.
5.  **On-Chain Challenges (`Challenge` struct, `_challengeData`, `setChallenge`, `participateInChallenge`):** The contract owner can configure a challenge with on-chain requirements (Node level, links) and a simulated on-chain outcome. `participateInChallenge` checks these requirements and uses pseudo-randomness (based on block data – *with the standard caution about its security*) to determine success. This provides a framework for on-chain mini-games or achievement systems tied directly to the asset's state and network activity.
6.  **Global Environmental Events (`_environmentalModifier`, `triggerEnvironmentalEvent`):** The contract owner (or potentially a decentralized oracle/DAO in a more complex version) can trigger events that change a global state variable (`_environmentalModifier`). This modifier can then influence various aspects of the system, like energy regeneration or challenge difficulty, introducing an external factor that affects all assets and interactions.
7.  **Dynamic Scoring (`calculateNodeScore`):** A function to calculate a composite score for a Node based on multiple dynamic factors (level, energy, links, generation). This is a simple example but could be extended to complex trait-based scoring, useful for leaderboards or ranking assets within the network.
8.  **Mixed Metadata (`_tokenURIs`, `_baseTokenURI`, `tokenURI`, `setBaseURI`, `updateNodeMetadataUri`):** Supports both a base URI for standard tokens and the ability for the contract owner *or* the individual token owner to set a specific URI for a single token, offering flexibility for dynamic or personalized metadata.

This contract combines ERC721 fundamentals with custom state, resource management, on-chain relationships, conditional logic, simulated external factors, and pseudo-random outcomes, resulting in a system significantly more complex and interactive than a basic NFT or token contract. It provides a foundation for a GameFi element, a decentralized network visualization, or an experimental digital ecosystem.