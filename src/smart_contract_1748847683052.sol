Okay, here is a Solidity smart contract designed around a conceptual "Decentralized Creative Foundry". It incorporates elements of ERC20 tokens, ERC721 NFTs, staking, on-chain dynamic properties, a credit system, and a basic governance mechanism, aiming for creativity and advanced concepts while implementing core logic manually to avoid direct duplication of standard open-source libraries like full OpenZeppelin contracts (though using standard interfaces is necessary and common practice).

**Constraint Interpretation:** "Don't duplicate any of open source" is interpreted here as: *Do not simply inherit full implementations of standard libraries (like `ERC20.sol`, `ERC721.sol`, `Governor.sol` from OpenZeppelin) without adding significant custom logic.* We will implement the necessary state and core logic for token/NFT management directly within the contract, using standard interfaces (`IERC20`, `IERC721`, etc.) as contracts must adhere to these standards to be interoperable.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Standard Interfaces (Necessary for Interoperability) ---
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC2981} from "@openzeppelin/contracts/token/common/IERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Note: While using interfaces and some common utilities like Ownable/Pausable/ReentrancyGuard from OpenZeppelin
// (as these are standard building blocks and not the 'creative' or 'application' logic),
// the core ERC20/ERC721 state management, staking, credits, dynamic NFTs, and governance logic are implemented
// manually within this contract to avoid duplicating full library implementations of standard tokens/protocols.

/**
 * @title DecentralizedCreativeFoundry
 * @dev A smart contract for a decentralized platform combining token staking,
 *      NFT creation with dynamic properties, a credit system, and simple governance.
 *      Users stake CRC tokens to earn more CRC and Creation Credits,
 *      use Credits to mint generative NFTs, evolve NFT properties, and participate in governance.
 */
contract DecentralizedCreativeFoundry is Ownable, Pausable, ReentrancyGuard, IERC20, IERC721, IERC721Metadata, IERC2981 {
    using SafeERC20 for IERC20; // Using SafeERC20 utilities for external token interactions

    // --- Outline ---
    // 1. Core Token (CRC) State & Logic (ERC20 implementation)
    // 2. Core NFT (DCFItem) State & Logic (ERC721 implementation with dynamic properties)
    // 3. Creation Credits System
    // 4. Staking Mechanism (Stake CRC to earn CRC and Credits)
    // 5. Dynamic NFT Evolution Logic
    // 6. Governance Mechanism (Simple token/NFT based proposals and voting)
    // 7. Treasury Management
    // 8. Standard Access Control & Pausability

    // --- Function Summary (at least 20 functions) ---
    // ERC20 (CRC Token) Functions:
    // 1. constructor(string, string, string, string, uint256, uint256, uint256): Initializes contracts, tokens, and parameters.
    // 2. name() external view returns (string memory): Returns the name of the CRC token.
    // 3. symbol() external view returns (string memory): Returns the symbol of the CRC token.
    // 4. decimals() external view returns (uint8): Returns the number of decimals for the CRC token.
    // 5. totalSupply() external view returns (uint256): Returns the total supply of CRC tokens.
    // 6. balanceOf(address account) external view returns (uint256): Returns balance of CRC tokens for an account.
    // 7. transfer(address to, uint256 amount) external returns (bool): Transfers CRC tokens.
    // 8. allowance(address owner, address spender) external view returns (uint256): Returns allowance for a spender.
    // 9. approve(address spender, uint256 amount) external returns (bool): Approves a spender to transfer tokens.
    // 10. transferFrom(address from, address to, uint256 amount) external returns (bool): Transfers CRC tokens via allowance.
    // 11. burn(uint256 amount) public nonReentrant whenNotPaused: Burns caller's CRC tokens.

    // ERC721 (DCFItem NFT) Functions:
    // 12. supportsInterface(bytes4 interfaceId) public view virtual override returns (bool): Supports ERC165 interfaces.
    // 13. balanceOf(address owner) public view override returns (uint256): Returns number of NFTs owned by an address.
    // 14. ownerOf(uint256 tokenId) public view override returns (address): Returns owner of a specific NFT.
    // 15. tokenURI(uint256 tokenId) public view override returns (string memory): Returns the metadata URI for an NFT.
    // 16. approve(address to, uint256 tokenId) public override nonReentrant whenNotPaused: Approves an address to transfer an NFT.
    // 17. getApproved(uint256 tokenId) public view override returns (address): Gets the approved address for an NFT.
    // 18. setApprovalForAll(address operator, bool approved) public override nonReentrant whenNotPaused: Sets approval for all NFTs to an operator.
    // 19. isApprovedForAll(address owner, address operator) public view override returns (bool): Checks if an operator is approved for all NFTs.
    // 20. transferFrom(address from, address to, uint256 tokenId) public override nonReentrant whenNotPaused: Transfers an NFT from one address to another.
    // 21. safeTransferFrom(address from, address to, uint256 tokenId) public override nonReentrant whenNotPaused: Safely transfers an NFT.
    // 22. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override nonReentrant whenNotPaused: Safely transfers an NFT with data.
    // 23. mintItem() public nonReentrant whenNotPaused: Mints a new NFT using Creation Credits.
    // 24. burnItem(uint256 tokenId) public nonReentrant whenNotPaused: Burns an NFT owned by the caller.

    // Dynamic NFT Functions:
    // 25. evolveItem(uint256 tokenId, bytes32 evolutionData) public nonReentrant whenNotPaused: Evolves an NFT's properties using Credits/CRC and external data.
    // 26. getItemProperties(uint256 tokenId) public view returns (ItemProperties memory): Gets the current dynamic properties of an NFT.
    // 27. toggleItemAttributeLock(uint256 tokenId, uint8 attributeIndex, bool locked) public nonReentrant whenNotPaused: Locks/unlocks specific NFT attributes from evolving.

    // Creation Credits & Staking Functions:
    // 28. stakeCRC(uint256 amount) public nonReentrant whenNotPaused: Stakes CRC tokens to earn rewards and credits.
    // 29. unstakeCRC(uint256 amount) public nonReentrant whenNotPaused: Unstakes CRC tokens.
    // 30. claimStakingRewards() public nonReentrant whenNotPaused: Claims accrued CRC staking rewards.
    // 31. claimCreationCredits() public nonReentrant whenNotPaused: Claims accrued Creation Credits.
    // 32. getAccruedCRCRewards(address account) public view returns (uint256): Gets pending CRC rewards.
    // 33. getAccruedCreationCredits(address account) public view returns (uint256): Gets pending Creation Credits.
    // 34. updateRewardRates(uint256 newCRCRate, uint256 newCreditRate) public onlyOwner nonReentrant: Updates the CRC and Credit earning rates (initially owner, could be governance).

    // Governance Functions (Simple):
    // 35. submitProposal(bytes memory proposalData, address target, uint256 value, bytes calldata callData) public nonReentrant whenNotPaused: Submits a new governance proposal.
    // 36. voteOnProposal(uint256 proposalId, bool support) public nonReentrant whenNotPaused: Casts a vote on a proposal.
    // 37. executeProposal(uint256 proposalId) public nonReentrant: Executes a successful proposal after timelock.
    // 38. getCurrentProposals() public view returns (Proposal[] memory): Gets details of active proposals.
    // 39. delegateVotePower(address delegatee) public nonReentrant whenNotPaused: Delegates voting power (CRC/NFT stake) to another address.

    // Treasury Functions:
    // 40. depositTreasury() public payable whenNotPaused: Allows depositing ETH into the treasury.
    // 41. depositTreasuryERC20(address tokenAddress, uint256 amount) public nonReentrant whenNotPaused: Allows depositing ERC20 into the treasury.
    // 42. withdrawTreasuryERC20(address tokenAddress, uint256 amount) public nonReentrant: Withdraws ERC20 from treasury (governance execution only).
    // 43. withdrawTreasuryETH(uint256 amount) public nonReentrant: Withdraws ETH from treasury (governance execution only).
    // 44. getTreasuryBalance(address tokenAddress) public view returns (uint256): Gets treasury balance for a specific token (use address(0) for ETH).

    // Admin/Utility Functions:
    // 45. pause() public onlyOwner nonReentrant: Pauses contract interactions.
    // 46. unpause() public onlyOwner nonReentrant: Unpauses contract interactions.
    // 47. updateMinStakeForVoting(uint256 newAmount) public onlyOwner nonReentrant: Updates minimum CRC stake required to submit/vote on proposals (initially owner, could be governance).
    // 48. updateItemMintCost(uint256 newCost) public onlyOwner nonReentrant: Updates the Creation Credit cost to mint an NFT (initially owner, could be governance).

    // --- State Variables ---

    // CRC Token State (Manual ERC20 Implementation)
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // DCFItem NFT State (Manual ERC721 Implementation)
    string private _nftName;
    string private _nftSymbol;
    uint256 private _nextTokenId; // Counter for unique token IDs
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balanceOfNFT;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _baseTokenURI; // Base URI for NFT metadata

    // Dynamic NFT Properties
    struct ItemProperties {
        uint8 attribute1; // e.g., Color/Type (0-255)
        uint8 attribute2; // e.g., Shape/Form (0-255)
        uint8 attribute3; // e.g., Rarity/Sparkle (0-255)
        bytes32 evolutionSeed; // Data used for evolution logic
        bool[] attributesLocked; // Which attributes are locked from evolution
        // Add more attributes as needed for creative expression
    }
    mapping(uint256 => ItemProperties) private _itemProperties;

    // Creation Credits & Staking
    uint256 public itemMintCost = 100; // Cost in Creation Credits to mint an NFT
    uint256 public crcRewardRatePerBlock; // Amount of CRC rewarded per staked CRC per block
    uint256 public creditRatePerBlock; // Amount of Creation Credits rewarded per staked CRC per block

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastRewardBlock; // Block number when rewards/credits were last claimed or staked amount changed
    mapping(address => uint256) public pendingCRCRewards;
    mapping(address => uint256) public pendingCreationCredits;
    mapping(address => uint256) public totalClaimedCreationCredits; // To prevent double claiming on updates

    mapping(address => uint256) private _creationCredits;

    // Governance
    struct Proposal {
        uint256 id;
        bytes proposalData; // Arbitrary data describing the proposal
        address target; // Target contract for execution
        uint256 value; // ETH value for execution
        bytes callData; // Calldata for execution
        uint256 startBlock;
        uint256 endBlock;
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) votePowerUsed; // Track vote power used by delegatee or voter
        bool executed;
        bool canceled;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;
    uint256 public minStakeForVoting = 1000 * (10**_decimals); // Minimum CRC stake to participate in governance
    uint256 public proposalVotingPeriod = 100; // Blocks for voting (example: ~20-30 mins)
    uint256 public proposalTimelock = 50; // Blocks between success and execution

    mapping(address => address) public voteDelegates;
    mapping(address => uint256) public delegatedVotePower; // Tracks power *received* by a delegatee

    // Treasury
    mapping(address => uint256) private _treasuryBalances; // Store balances of various tokens (address(0) for ETH)

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event TransferNFT(address indexed from, address indexed to, uint256 indexed tokenId);
    event ApprovalNFT(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAllNFT(address indexed owner, address indexed operator, bool approved);
    event ItemMinted(address indexed owner, uint256 indexed tokenId, uint256 costInCredits);
    event ItemBurned(address indexed owner, uint256 indexed tokenId);
    event ItemEvolved(uint256 indexed tokenId, bytes32 evolutionData, uint256 creditsSpent, uint256 crcSpent);
    event ItemAttributeLockToggled(uint256 indexed tokenId, uint8 indexed attributeIndex, bool locked);

    event CRCStaked(address indexed account, uint256 amount);
    event CRCUnstaked(address indexed account, uint256 amount);
    event CRCRewardsClaimed(address indexed account, uint256 amount);
    event CreationCreditsClaimed(address indexed account, uint256 amount);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes proposalData);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    event TreasuryDeposit(address indexed tokenAddress, uint256 amount);
    event TreasuryWithdrawal(address indexed tokenAddress, uint256 amount);
    event RewardRatesUpdated(uint256 newCRCRate, uint256 newCreditRate);
    event ItemMintCostUpdated(uint256 newCost);
    event MinStakeForVotingUpdated(uint256 newAmount);

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        string memory nftName_,
        string memory nftSymbol_,
        uint256 initialSupplyCRC,
        uint256 _crcRewardRatePerBlock,
        uint256 _creditRatePerBlock
    )
        Ownable(msg.sender)
    {
        _name = name_;
        _symbol = symbol_;
        _nftName = nftName_;
        _nftSymbol = nftSymbol_;
        crcRewardRatePerBlock = _crcRewardRatePerBlock;
        creditRatePerBlock = _creditRatePerBlock;

        // Initial CRC minting to deployer (owner)
        _mint(msg.sender, initialSupplyCRC);
    }

    // --- Internal Helpers ---

    function _generateItemProperties(uint256 tokenId, bytes32 initialSeed) internal pure returns (ItemProperties memory) {
        bytes32 seed = keccak256(abi.encodePacked(tokenId, initialSeed, block.timestamp, block.difficulty));
        // Simple deterministic property generation based on a seed
        // In a real application, use VRF for secure randomness if properties must be unpredictable
        uint8 attr1 = uint8(uint256(keccak256(abi.encodePacked(seed, "attr1"))) % 256);
        uint8 attr2 = uint8(uint256(keccak256(abi.encodePacked(seed, "attr2"))) % 256);
        uint8 attr3 = uint8(uint256(keccak256(abi.encodePacked(seed, "attr3"))) % 256);

        // Initialize attributes as unlocked
        bool[] memory locked = new bool[](3); // Based on the number of attributes above
        locked[0] = false;
        locked[1] = false;
        locked[2] = false;

        return ItemProperties({
            attribute1: attr1,
            attribute2: attr2,
            attribute3: attr3,
            evolutionSeed: initialSeed, // Store the initial seed, or a combination
            attributesLocked: locked
        });
    }

    function _evolveItemProperties(ItemProperties storage props, bytes32 evolutionData) internal {
        // Example evolution logic: Modify properties based on evolution data and lock status
        // This is a placeholder. Complex on-chain generative/evolution logic can be implemented here.
        if (!props.attributesLocked[0]) {
             props.attribute1 = uint8(uint256(keccak256(abi.encodePacked(props.evolutionSeed, evolutionData, block.timestamp, props.attribute1))) % 256);
        }
         if (!props.attributesLocked[1]) {
             props.attribute2 = uint8(uint256(keccak256(abi.encodePacked(props.evolutionSeed, evolutionData, block.timestamp, props.attribute2))) % 256);
        }
         if (!props.attributesLocked[2]) {
             props.attribute3 = uint8(uint256(keccak256(abi.encodePacked(props.evolutionSeed, evolutionData, block.timestamp, props.attribute3))) % 256);
        }
        // Update the evolution seed or combine it
        props.evolutionSeed = keccak256(abi.encodePacked(props.evolutionSeed, evolutionData, block.timestamp));

        // Example: Evolution might cost CRC as well as credits
        // (Cost logic is handled in evolveItem function)
    }

    // Calculate pending rewards/credits since last claim/stake event
    function _accrueRewards(address account) internal {
        uint256 currentStake = stakedAmount[account];
        uint256 lastBlock = lastRewardBlock[account];
        uint256 blocksPassed = block.number - lastBlock;

        if (currentStake > 0 && blocksPassed > 0) {
            pendingCRCRewards[account] += (currentStake * crcRewardRatePerBlock * blocksPassed);
            pendingCreationCredits[account] += (currentStake * creditRatePerBlock * blocksPassed);
        }
        lastRewardBlock[account] = block.number;
    }

    function _getVotePower(address account) internal view returns (uint256) {
         // Simple vote power = staked CRC + (100 * number of owned NFTs)
         // More complex logic could involve NFT attributes, lock status, etc.
         return stakedAmount[account] + (_balanceOfNFT[account] * 100 * (10**_decimals));
    }

     function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

     function _mintNFT(address to, bytes32 initialSeed) internal returns (uint256) {
        require(to != address(0), "ERC721: mint to the zero address");

        uint256 tokenId = _nextTokenId++;
        _owners[tokenId] = to;
        _balanceOfNFT[to]++;
        _itemProperties[tokenId] = _generateItemProperties(tokenId, initialSeed);

        emit TransferNFT(address(0), to, tokenId);
        return tokenId;
    }

     function _transferNFT(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals
        _approveNFT(address(0), tokenId);

        _balanceOfNFT[from]--;
        _owners[tokenId] = to;
        _balanceOfNFT[to]++;

        emit TransferNFT(from, to, tokenId);
    }

    function _approveNFT(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit ApprovalNFT(ownerOf(tokenId), to, tokenId);
    }

    // ERC165 Interface Support
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId || // Add ERC2981 Royalty Standard support
            interfaceId == type(IERC165).interfaceId; // ERC165 itself
    }

    // --- ERC20 (CRC Token) Functions ---

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    // 11. burn CRC
    function burn(uint256 amount) public nonReentrant whenNotPaused {
        _burn(msg.sender, amount);
    }

    // Admin function to mint initial supply (could be removed or changed after launch)
    function mintInitialCRC(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    // --- ERC721 (DCFItem NFT) Functions ---

    function balanceOf(address owner) public view override(IERC721, DecentralizedCreativeFoundry) returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOfNFT[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        // In a dynamic NFT, the metadata URI might include query parameters
        // or point to an API that serves dynamic JSON based on token properties.
        // For this example, we'll use a base URI + token ID.
        // A more advanced version would query _itemProperties[tokenId] and format the JSON dynamically.
        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        // This is a simplified concatenation. ERC4626 or similar libraries are better for robust string ops.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    function approve(address to, uint256 tokenId) public override(IERC721, DecentralizedCreativeFoundry) nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not token owner or approved for all");
        _approveNFT(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
         require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
         return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override nonReentrant whenNotPaused {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAllNFT(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, DecentralizedCreativeFoundry) nonReentrant whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferNFT(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, DecentralizedCreativeFoundry) nonReentrant whenNotPaused {
         safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(IERC721, DecentralizedCreativeFoundry) nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferNFT(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // Helper function to check if sender is owner or approved
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Helper function to check if receiver supports ERC721
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length == 0) { // Recipient is a plain address
            return true;
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // 23. mintItem: Mints a new NFT using Creation Credits
    function mintItem() public nonReentrant whenNotPaused {
        require(_creationCredits[msg.sender] >= itemMintCost, "Foundry: Not enough Creation Credits");

        // Deduct credits
        _creationCredits[msg.sender] -= itemMintCost;

        // Mint NFT
        uint256 newTokenId = _mintNFT(msg.sender, bytes32(uint256(keccak256(abi.encodePacked(msg.sender, _nextTokenId, block.timestamp))))); // Use sender and next ID for seed

        emit ItemMinted(msg.sender, newTokenId, itemMintCost);
    }

    // 24. burnItem: Burns an NFT owned by the caller
    function burnItem(uint256 tokenId) public nonReentrant whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Foundry: Must own the NFT to burn");

        // Clear approvals and ownership
        _approveNFT(address(0), tokenId); // Clear token approval
        delete _operatorApprovals[msg.sender]; // Clear operator approvals for this owner (simplified)

        _balanceOfNFT[msg.sender]--;
        delete _owners[tokenId];
        delete _itemProperties[tokenId]; // Remove dynamic properties

        emit ItemBurned(msg.sender, tokenId);
    }

    // --- Dynamic NFT Functions ---

    // 25. evolveItem: Evolves an NFT's properties
    function evolveItem(uint256 tokenId, bytes32 evolutionData) public nonReentrant whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Foundry: Must own the NFT to evolve it");
        // Evolution might cost Credits or CRC
        uint256 evolutionCostCredits = 10; // Example cost
        uint256 evolutionCostCRC = 1 * (10**_decimals); // Example cost

        require(_creationCredits[msg.sender] >= evolutionCostCredits, "Foundry: Not enough Creation Credits for evolution");
        require(_balances[msg.sender] >= evolutionCostCRC, "Foundry: Not enough CRC for evolution");

        // Deduct costs
        _creationCredits[msg.sender] -= evolutionCostCredits;
        _burn(msg.sender, evolutionCostCRC); // Burn CRC for evolution

        // Accrue rewards/credits before checking and updating stake
        _accrueRewards(msg.sender);

        // Update dynamic properties
        _evolveItemProperties(_itemProperties[tokenId], evolutionData);

        emit ItemEvolved(tokenId, evolutionData, evolutionCostCredits, evolutionCostCRC);
    }

    // 26. getItemProperties: Gets the current dynamic properties
    function getItemProperties(uint256 tokenId) public view returns (ItemProperties memory) {
         require(_owners[tokenId] != address(0), "Foundry: Item does not exist");
         return _itemProperties[tokenId];
    }

    // 27. toggleItemAttributeLock: Locks/unlocks specific attributes from evolving
    function toggleItemAttributeLock(uint256 tokenId, uint8 attributeIndex, bool locked) public nonReentrant whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Foundry: Must own the NFT to lock attributes");
        require(attributeIndex < _itemProperties[tokenId].attributesLocked.length, "Foundry: Invalid attribute index");

        _itemProperties[tokenId].attributesLocked[attributeIndex] = locked;

        emit ItemAttributeLockToggled(tokenId, attributeIndex, locked);
    }

    // ERC2981 Royalties (Collection Level Example) - Can be extended per token
    uint96 private _royaltyFraction = 1000; // 10% represented as 10000 / 100 = 100 -> 10000 / 1000 = 10
    address private _royaltyReceiver;

    function setRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
        require(receiver != address(0), "Foundry: Invalid receiver address");
        require(feeNumerator <= 10000, "Foundry: Fee numerator exceeds 100%"); // Max 100%
        _royaltyReceiver = receiver;
        _royaltyFraction = feeNumerator;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        // Check if token exists
        require(_owners[tokenId] != address(0), "Foundry: Item does not exist");
        receiver = _royaltyReceiver;
        // Calculate royalty based on sale price and fraction
        royaltyAmount = (salePrice * _royaltyFraction) / 10000;
    }


    // --- Creation Credits & Staking Functions ---

    // 28. stakeCRC: Stakes CRC tokens
    function stakeCRC(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Foundry: Stake amount must be positive");
        require(_balances[msg.sender] >= amount, "Foundry: Not enough CRC to stake");

        // Accrue rewards/credits before updating stake
        _accrueRewards(msg.sender);

        // Transfer tokens into the contract (or a dedicated staking pool)
        // For simplicity, tokens are 'burned' from user balance and tracked internally here.
        // A real staking contract might hold the tokens.
        _burn(msg.sender, amount); // Transfer amount from user to contract address (0)
        stakedAmount[msg.sender] += amount;

        // Update delegate power if user has delegated
        address delegatee = voteDelegates[msg.sender];
        if (delegatee != address(0) && delegatee != msg.sender) {
             uint256 oldVotePower = _getVotePower(msg.sender) - amount * (10**_decimals); // Assuming vote power includes stake
             uint256 newVotePower = _getVotePower(msg.sender);
             delegatedVotePower[delegatee] += (newVotePower - oldVotePower); // Add the increase
             emit DelegateVotesChanged(delegatee, oldVotePower, newVotePower);
        } else {
             emit DelegateVotesChanged(msg.sender, _getVotePower(msg.sender) - amount * (10**_decimals), _getVotePower(msg.sender));
        }


        emit CRCStaked(msg.sender, amount);
    }

    // 29. unstakeCRC: Unstakes CRC tokens
    function unstakeCRC(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "Foundry: Unstake amount must be positive");
        require(stakedAmount[msg.sender] >= amount, "Foundry: Not enough staked CRC");

        // Accrue rewards/credits before updating stake
        _accrueRewards(msg.sender);

        // Transfer tokens back to user (or 'mint' them back if burned on stake)
        _mint(msg.sender, amount); // Mint tokens back to user
        stakedAmount[msg.sender] -= amount;

        // Update delegate power if user has delegated
         address delegatee = voteDelegates[msg.sender];
        if (delegatee != address(0) && delegatee != msg.sender) {
             uint256 oldVotePower = _getVotePower(msg.sender) + amount * (10**_decimals);
             uint256 newVotePower = _getVotePower(msg.sender);
             delegatedVotePower[delegatee] -= (oldVotePower - newVotePower); // Subtract the decrease
             emit DelegateVotesChanged(delegatee, oldVotePower, newVotePower);
        } else {
             emit DelegateVotesChanged(msg.sender, _getVotePower(msg.sender) + amount * (10**_decimals), _getVotePower(msg.sender));
        }

        emit CRCUnstaked(msg.sender, amount);
    }

    // 30. claimStakingRewards: Claims accrued CRC staking rewards
    function claimStakingRewards() public nonReentrant whenNotPaused {
        _accrueRewards(msg.sender); // Accrue any pending rewards up to this block
        uint256 rewardsToClaim = pendingCRCRewards[msg.sender];
        require(rewardsToClaim > 0, "Foundry: No CRC rewards to claim");

        pendingCRCRewards[msg.sender] = 0;
        _mint(msg.sender, rewardsToClaim); // Mint rewards to the user

        emit CRCRewardsClaimed(msg.sender, rewardsToClaim);
    }

    // 31. claimCreationCredits: Claims accrued Creation Credits
    function claimCreationCredits() public nonReentrant whenNotPaused {
         _accrueRewards(msg.sender); // Accrue any pending credits up to this block
         uint256 creditsToClaim = pendingCreationCredits[msg.sender];
         require(creditsToClaim > 0, "Foundry: No Creation Credits to claim");

         // Credits are not a separate token; they are tracked internally
         _creationCredits[msg.sender] += creditsToClaim;
         pendingCreationCredits[msg.sender] = 0;

         emit CreationCreditsClaimed(msg.sender, creditsToClaim);
    }

    // 32. getAccruedCRCRewards: Gets pending CRC rewards
    function getAccruedCRCRewards(address account) public view returns (uint256) {
        uint256 currentStake = stakedAmount[account];
        uint256 lastBlock = lastRewardBlock[account];
        uint256 blocksPassed = block.number - lastBlock;

        return pendingCRCRewards[account] + (currentStake * crcRewardRatePerBlock * blocksPassed);
    }

    // 33. getAccruedCreationCredits: Gets pending Creation Credits
    function getAccruedCreationCredits(address account) public view returns (uint256) {
         uint256 currentStake = stakedAmount[account];
         uint256 lastBlock = lastRewardBlock[account];
         uint256 blocksPassed = block.number - lastBlock;

         return pendingCreationCredits[account] + (currentStake * creditRatePerBlock * blocksPassed);
    }

    // 34. updateRewardRates: Updates the CRC and Credit earning rates
    function updateRewardRates(uint256 newCRCRate, uint256 newCreditRate) public onlyOwner nonReentrant {
        // Consider implementing a timelock or governance for this in production
        crcRewardRatePerBlock = newCRCRate;
        creditRatePerBlock = newCreditRate;
        emit RewardRatesUpdated(newCRCRate, newCreditRate);
    }

    // Get current Creation Credits balance
    function getCreationCredits(address account) public view returns (uint256) {
        return _creationCredits[account];
    }

    // --- Governance Functions ---

    // 35. submitProposal: Submits a new governance proposal
    function submitProposal(bytes memory proposalData, address target, uint256 value, bytes calldata callData) public nonReentrant whenNotPaused {
        // Accrue rewards/credits before checking vote power
        _accrueRewards(msg.sender);

        require(_getVotePower(msg.sender) >= minStakeForVoting, "Foundry: Not enough vote power to submit proposal");

        uint256 proposalId = _nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposalData = proposalData; // Store description/details off-chain, hash on-chain, or structured data
        proposal.target = target;
        proposal.value = value;
        proposal.callData = callData;
        proposal.startBlock = block.number;
        proposal.endBlock = block.number + proposalVotingPeriod;
        proposal.executed = false;
        proposal.canceled = false;

        emit ProposalSubmitted(proposalId, msg.sender, proposalData);
    }

    // 36. voteOnProposal: Casts a vote on a proposal
    function voteOnProposal(uint256 proposalId, bool support) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.startBlock > 0 && !proposal.executed && !proposal.canceled, "Foundry: Proposal not active");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Foundry: Voting period ended");

        // Accrue rewards/credits before checking vote power
        _accrueRewards(msg.sender);

        address voter = msg.sender;
        address delegatee = voteDelegates[voter];
        address effectiveVoter = (delegatee != address(0)) ? delegatee : voter;

        require(!proposal.hasVoted[effectiveVoter], "Foundry: Already voted on this proposal");

        uint256 votePower = (delegatee != address(0)) ? delegatedVotePower[effectiveVoter] : _getVotePower(effectiveVoter);

        require(votePower > 0, "Foundry: No vote power");

        proposal.hasVoted[effectiveVoter] = true; // Mark effective voter as voted
        proposal.votePowerUsed[effectiveVoter] = votePower; // Record power used

        if (support) {
            proposal.voteCountYes += votePower;
        } else {
            proposal.voteCountNo += votePower;
        }

        emit VoteCast(proposalId, voter, support, votePower);
    }

    // 37. executeProposal: Executes a successful proposal after timelock
    function executeProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.startBlock > 0 && !proposal.executed && !proposal.canceled, "Foundry: Proposal not valid or already processed");
        require(block.number > proposal.endBlock, "Foundry: Voting period not ended yet");
        require(block.number > proposal.endBlock + proposalTimelock, "Foundry: Timelock not expired yet");

        // Simple majority check (can be changed to quorum + majority etc.)
        require(proposal.voteCountYes > proposal.voteCountNo, "Foundry: Proposal not passed");

        proposal.executed = true;

        // Execute the proposed action
        // Ensure the target is the treasury address for withdrawals
        require(proposal.target == address(this), "Foundry: Execution target must be this contract");

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "Foundry: Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

     // Governance view function (simplified, returns active/recent proposals)
     // 38. getCurrentProposals
     function getCurrentProposals() public view returns (Proposal[] memory) {
         // This is inefficient for a large number of proposals.
         // In production, use a subgraph or external indexer.
         // This is a basic implementation for demonstration.
         uint256 activeCount = 0;
         for (uint256 i = 0; i < _nextProposalId; i++) {
             if (!proposals[i].executed && !proposals[i].canceled) {
                 activeCount++;
             }
         }

         Proposal[] memory activeProposals = new Proposal[](activeCount);
         uint256 currentIndex = 0;
         for (uint256 i = 0; i < _nextProposalId; i++) {
             if (!proposals[i].executed && !proposals[i].canceled) {
                 activeProposals[currentIndex] = proposals[i];
                 // Note: Mapping `hasVoted` and `votePowerUsed` are not returned by default
                 // when returning structs containing mappings. You'd need separate functions
                 // to query vote details per proposal/voter.
                 currentIndex++;
             }
         }
         return activeProposals;
     }

    // 39. delegateVotePower: Delegates voting power
    function delegateVotePower(address delegatee) public nonReentrant whenNotPaused {
        address currentDelegatee = voteDelegates[msg.sender];
        require(currentDelegatee != delegatee, "Foundry: Cannot delegate to current delegatee");

        // Accrue rewards/credits before updating stake/vote power
        _accrueRewards(msg.sender); // Ensures stake reflects current state

        uint256 delegatorVotePower = _getVotePower(msg.sender);

        // Remove power from old delegatee (if any)
        if (currentDelegatee != address(0)) {
            delegatedVotePower[currentDelegatee] -= delegatorVotePower;
            emit DelegateVotesChanged(currentDelegatee, delegatedVotePower[currentDelegatee] + delegatorVotePower, delegatedVotePower[currentDelegatee]);
        }

        // Set new delegatee
        voteDelegates[msg.sender] = delegatee;

        // Add power to new delegatee (if not zero address)
        if (delegatee != address(0)) {
            delegatedVotePower[delegatee] += delegatorVotePower;
             emit DelegateVotesChanged(delegatee, delegatedVotePower[delegatee] - delegatorVotePower, delegatedVotePower[delegatee]);
        } else {
             emit DelegateVotesChanged(msg.sender, delegatorVotePower, 0); // Delegating to self/zero address
        }

        emit DelegateChanged(msg.sender, currentDelegatee, delegatee);
    }

    // Get effective vote power for an account (including delegation)
    function getEffectiveVotePower(address account) public view returns (uint256) {
         address delegatee = voteDelegates[account];
         if (delegatee != address(0) && delegatee != account) {
             return delegatedVotePower[delegatee]; // If delegated, the delegatee holds the power
         }
         return _getVotePower(account); // Otherwise, the account's own power
    }

     // Get total vote power represented by a delegatee
    function getTotalVotePower(address delegatee) public view returns (uint256) {
        return delegatedVotePower[delegatee];
    }


    // --- Treasury Functions ---

    // 40. depositTreasury (ETH)
    receive() external payable whenNotPaused {
        depositTreasury();
    }

    function depositTreasury() public payable whenNotPaused {
        require(msg.value > 0, "Treasury: Deposit amount must be positive");
        _treasuryBalances[address(0)] += msg.value; // Use address(0) for ETH
        emit TreasuryDeposit(address(0), msg.value);
    }

    // 41. depositTreasuryERC20
    function depositTreasuryERC20(address tokenAddress, uint256 amount) public nonReentrant whenNotPaused {
        require(tokenAddress != address(0), "Treasury: Invalid token address");
        require(amount > 0, "Treasury: Deposit amount must be positive");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        _treasuryBalances[tokenAddress] += amount;
        emit TreasuryDeposit(tokenAddress, amount);
    }

    // 42. withdrawTreasuryERC20 (Callable ONLY by Governance Execution)
    function withdrawTreasuryERC20(address tokenAddress, uint256 amount) public nonReentrant {
        // This function should only be callable via a successful governance proposal execution
        // The executeProposal function checks that the target is `address(this)`
        // Further checks within governance logic could ensure msg.sender is the contract itself
        // during execution or verify a specific flag/context.
        // For simplicity, relying on `executeProposal` being the *only* caller.
        // A more robust check would involve checking `msg.sender == address(this)` and
        // potentially an internal flag set ONLY by `executeProposal`.
        require(msg.sender == address(this), "Treasury: Withdrawals only via governance execution");
        require(tokenAddress != address(0), "Treasury: Invalid token address");
        require(amount > 0, "Treasury: Withdraw amount must be positive");
        require(_treasuryBalances[tokenAddress] >= amount, "Treasury: Insufficient balance");

        _treasuryBalances[tokenAddress] -= amount;
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(tx.origin, amount); // Send to the address that initiated the tx chain
                                              // or pass recipient address in proposal calldata

        emit TreasuryWithdrawal(tokenAddress, amount);
    }

     // 43. withdrawTreasuryETH (Callable ONLY by Governance Execution)
    function withdrawTreasuryETH(uint256 amount) public nonReentrant {
         require(msg.sender == address(this), "Treasury: Withdrawals only via governance execution");
         require(amount > 0, "Treasury: Withdraw amount must be positive");
         require(_treasuryBalances[address(0)] >= amount, "Treasury: Insufficient balance");

         _treasuryBalances[address(0)] -= amount;
         // Send ETH to the address that initiated the tx chain
         // Consider passing recipient in calldata for governed withdrawals
         (bool success, ) = payable(tx.origin).call{value: amount}("");
         require(success, "Treasury: ETH withdrawal failed");

         emit TreasuryWithdrawal(address(0), amount);
    }


    // 44. getTreasuryBalance
    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance; // Get actual contract balance for ETH
        }
        return _treasuryBalances[tokenAddress];
    }


    // --- Admin/Utility Functions ---

    // 45. pause
    function pause() public onlyOwner nonReentrant {
        _pause();
    }

    // 46. unpause
    function unpause() public onlyOwner nonReentrant {
        _unpause();
    }

    // 47. updateMinStakeForVoting
    function updateMinStakeForVoting(uint256 newAmount) public onlyOwner nonReentrant {
        minStakeForVoting = newAmount;
        emit MinStakeForVotingUpdated(newAmount);
    }

    // 48. updateItemMintCost
    function updateItemMintCost(uint256 newCost) public onlyOwner nonReentrant {
        itemMintCost = newCost;
        emit ItemMintCostUpdated(newCost);
    }

     // Set Base URI for NFT metadata
     function setBaseTokenURI(string memory uri) public onlyOwner {
         _baseTokenURI = uri;
     }
}

// Helper for uint to string conversion (often needed for tokenURI)
// Using a basic implementation here to avoid full OZ library dependence
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
```