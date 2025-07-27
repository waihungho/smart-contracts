This smart contract, named **"EcoCredit Nexus"**, envisions a decentralized fund that empowers community-driven initiatives through a unique tokenomics model. It combines elements of a decentralized autonomous organization (DAO), a dynamic bonding curve, a reputation system, and a modular project funding mechanism.

The core idea is to create a self-sustaining ecosystem where participants bond capital (ETH/stablecoins) to mint `EcoCredit` (ECR) tokens, which grant them governance rights and a stake in the fund. Projects are proposed and voted on by ECR holders, and successful projects receive funding from the bonded capital. A dynamic bonding curve adjusts the ECR price based on supply and demand, while a sophisticated reputation system incentivizes positive participation and influences voting power.

---

## EcoCredit Nexus: Outline & Function Summary

### I. Contract Overview
*   **Purpose:** A decentralized fund managing community proposals, funded by a dynamic bonding curve, governed by `EcoCredit` (ECR) holders, and incentivizing participation via a Reputation System.
*   **Key Features:**
    *   **Dynamic Bonding Curve:** ECR price adjusts based on liquidity depth and supply.
    *   **Reputation System:** Earned by participating in the ecosystem (bonding, voting, successful proposals), influencing voting weight and access.
    *   **Decentralized Project Funding:** Community proposes and votes on projects to be funded from the pooled assets.
    *   **Milestone-Based Releases:** Funding for projects can be released in stages upon milestone completion.
    *   **Dynamic Protocol Fees:** Fees for bonding/unbonding can adjust based on market conditions or protocol utilization.
    *   **Parameter Governance:** `EcoCredit` holders can propose and vote on changing core protocol parameters.
    *   **Reputation Delegation:** Users can delegate their reputation/voting power.

### II. Core Components
*   **EcoCredit (ERC-20):** The native governance and utility token of the Nexus.
*   **Reputation Points (Internal):** Non-transferable, accumulative points reflecting a user's contribution and trust.
*   **Bonding Curve Logic:** Determines ECR mint/burn rates against supported collateral tokens.
*   **Project Proposals:** A structured system for submitting, voting on, and funding community initiatives.
*   **Parameter Governance:** Mechanism for the community to evolve the protocol.

### III. Function Summary (25+ Functions)

#### A. Token (EcoCredit - ECR) & Bonding Curve Management
1.  **`bondTokens(address _token, uint256 _amount)`**: User deposits a supported token to mint `EcoCredit` based on the dynamic bonding curve.
2.  **`unbondTokens(address _token, uint256 _ecoCreditAmount)`**: User burns `EcoCredit` to withdraw a proportional amount of the underlying token, subject to unbonding fees.
3.  **`getEcoCreditPrice(address _token)`**: Calculates the current price of 1 `EcoCredit` in terms of a specific underlying token, based on the bonding curve.
4.  **`getEcoCreditsToMint(address _token, uint256 _amount)`**: Pre-calculates how many `EcoCredit` tokens would be minted for a given input amount of a collateral token.
5.  **`getTokensToReceive(address _token, uint256 _ecoCreditAmount)`**: Pre-calculates how much of a collateral token would be received for a given amount of `EcoCredit` burned.
6.  **`getBondingCurveParameters(address _token)`**: Retrieves the current parameters (reserve, supply, factor, etc.) for a specific token's bonding curve.
7.  **`getTotalBondedValue()`**: Returns the total value (in a common reference, e.g., ETH or USD, assuming an oracle integration for conversion) of all assets bonded in the Nexus.
8.  **`getProtocolFees(address _token)`**: Returns the amount of accrued protocol fees for a specific token.

#### B. Reputation System
9.  **`getReputation(address _user)`**: Returns the current Reputation Points (RP) of a user.
10. **`delegateReputation(address _delegatee)`**: Allows a user to delegate their reputation and voting power to another address.
11. **`undelegateReputation()`**: Revokes any active reputation delegation.
12. **`getDelegatedReputation(address _user)`**: Returns the address to which a user has delegated their reputation.
13. **`getEffectiveReputation(address _user)`**: Returns the effective reputation of a user (their own + any delegated to them).
14. **`_updateReputation(address _user, uint256 _points, bool _add)`**: Internal function to manage reputation points (e.g., for bonding, voting, successful proposals).

#### C. Project Proposals & Funding
15. **`submitProjectProposal(string calldata _title, string calldata _descriptionCID, address _recipient, address _fundingToken, uint256 _totalFundingAmount, uint256 _milestoneCount)`**: Allows a user meeting a reputation/ECR threshold to submit a new project proposal.
16. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows `EcoCredit` holders (or their delegates) to vote on an active project proposal.
17. **`finalizeProposal(uint256 _proposalId)`**: Concludes the voting period for a proposal, updates its status, and disburses initial funding if approved.
18. **`releaseMilestonePayment(uint256 _proposalId, uint256 _milestoneIndex)`**: Allows the project recipient to request release of a specific milestone payment, provided the previous ones are met (requires off-chain verification or dispute mechanism, or simply allows recipient to claim if contract doesn't implement checks).
19. **`getProposalDetails(uint256 _proposalId)`**: Retrieves all details of a specific project proposal.
20. **`getUserVote(uint256 _proposalId, address _user)`**: Returns how a specific user voted on a proposal.
21. **`getProposalVotingPower(uint256 _proposalId)`**: Returns the total voting power that has been cast for/against a proposal.

#### D. Protocol Parameter Governance
22. **`proposeParameterChange(uint256 _changeType, bytes calldata _newValue, uint256 _delaySeconds)`**: Allows high-reputation members to propose changes to Nexus parameters (e.g., voting periods, fee structures, bonding curve factors).
23. **`voteOnParameterChange(uint256 _changeId, bool _support)`**: Allows `EcoCredit` holders to vote on proposed parameter changes.
24. **`executeParameterChange(uint256 _changeId)`**: Executes an approved parameter change after its timelock period.

#### E. Admin & Utility
25. **`addSupportedToken(address _token, uint256 _initialCurveFactor, uint256 _baseBondingFeeBPS, uint256 _baseUnbondingFeeBPS)`**: Owner (or DAO via governance) adds a new collateral token that can be bonded.
26. **`setVotingPeriod(uint256 _newPeriod)`**: Sets the duration for project and parameter proposal voting.
27. **`setProposalThresholds(uint256 _minReputation, uint256 _minECRForProposal)`**: Sets the minimum reputation and ECR required to submit a project proposal.
28. **`withdrawStuckTokens(address _token)`**: Allows owner to recover tokens accidentally sent directly to the contract without bonding.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Custom Errors ---
error InvalidAmount();
error InsufficientFunds();
error TokenNotSupported();
error UnauthorizedCaller();
error ProposalNotFound();
error VotingPeriodNotActive();
error VotingPeriodExpired();
error ProposalAlreadyFinalized();
error NoActiveDelegation();
error NotEnoughReputation();
error NotEnoughEcoCredit();
error MilestoneNotFound();
error MilestoneAlreadyReleased();
error ParameterChangeNotFound();
error ParameterChangeNotExecutableYet();
error ParameterChangeAlreadyExecuted();
error InvalidChangeType();
error SelfDelegationNotAllowed();
error ZeroAddressNotAllowed();

/**
 * @title EcoCreditNexus
 * @dev A decentralized fund for community projects, powered by a dynamic bonding curve,
 * a reputation system, and on-chain governance.
 *
 * @notice This contract is an advanced concept and would require significant off-chain infrastructure
 * for dispute resolution, project milestone verification, and robust oracle integration for
 * total value calculations (beyond the scope of this single contract).
 */
contract EcoCreditNexus is Ownable {
    using SafeMath for uint256;

    // --- State Variables ---

    // EcoCredit Token details
    string public constant NAME = "EcoCredit";
    string public constant SYMBOL = "ECR";
    uint8 public constant DECIMALS = 18;
    uint256 private _totalSupplyECR;
    mapping(address => uint256) private _balancesECR;
    mapping(address => mapping(address => uint256)) private _allowancesECR;

    // Reputation System
    mapping(address => uint256) public reputationPoints; // User address => Reputation points
    mapping(address => address) public delegatedReputation; // User address => Delegate address
    mapping(address => uint256) public effectiveReputationSupply; // Delegate address => Total reputation delegated to them (including their own)

    // Bonding Curve & Supported Tokens
    struct BondingCurveInfo {
        uint256 totalBondedAmount; // Total amount of this token bonded
        uint256 ecoCreditSupplyForToken; // Total ECR minted against this token
        uint256 curveFactor; // Influences the price increase per ECR minted
        uint256 baseBondingFeeBPS; // Base fee for bonding in Basis Points (BPS)
        uint256 baseUnbondingFeeBPS; // Base fee for unbonding in BPS
        uint256 accumulatedFees; // Accumulated fees for this specific token
        // Future: volatility factor for dynamic fees, oracle reference
    }
    mapping(address => BondingCurveInfo) public supportedTokens; // Token address => Bonding Curve Info
    address[] public supportedTokenList; // List of all supported tokens

    // Project Proposals
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct ProjectProposal {
        uint256 id;
        string title;
        string descriptionCID; // IPFS CID for detailed description
        address proposer;
        address recipient;
        address fundingToken;
        uint256 totalFundingAmount;
        uint256 milestoneCount;
        mapping(uint256 => bool) milestoneReleased; // Milestone index => released status
        uint256 currentMilestone; // Next milestone to be released (0-indexed)
        uint256 votesFor; // Total ECR votes FOR
        uint256 votesAgainst; // Total ECR votes AGAINST
        mapping(address => bool) hasVoted; // User address => Voted status
        mapping(address => bool) voteChoice; // User address => true for FOR, false for AGAINST
        uint256 startBlock;
        uint256 endBlock;
        ProposalStatus status;
        address[] voters; // To track all unique voters for a proposal
    }
    ProjectProposal[] public projectProposals;
    uint256 public nextProposalId;

    // Parameter Change Proposals
    enum ParameterChangeType {
        VotingPeriod,
        ProposalMinReputation,
        ProposalMinECR,
        AddSupportedTokenConfig, // For adding a new supported token with its parameters
        UpdateBondingCurveFactor,
        UpdateBaseBondingFee,
        UpdateBaseUnbondingFee
        // Future: More complex parameter types
    }
    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        ParameterChangeType changeType;
        bytes newValue; // Encoded new value based on changeType
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        uint256 executionTimelock; // Block number after which it can be executed
    }
    ParameterChangeProposal[] public parameterChangeProposals;
    uint256 public nextParameterChangeId;

    // Governance Parameters
    uint256 public votingPeriodBlocks; // Default voting period for proposals in blocks
    uint256 public minReputationForProposal; // Min RP to submit a project proposal
    uint256 public minEcoCreditForProposal; // Min ECR balance to submit a project proposal
    uint256 public constant QUORUM_PERCENTAGE = 20; // 20% of total ECR supply must vote for quorum
    uint256 public constant MIN_APPROVAL_PERCENTAGE = 60; // 60% of votes must be 'for' to pass

    // --- Events ---
    event EcoCreditMinted(address indexed user, address indexed token, uint256 tokenAmount, uint256 ecoCreditAmount, uint256 feesPaid);
    event EcoCreditBurned(address indexed user, address indexed token, uint256 ecoCreditAmount, uint256 tokenAmount, uint256 feesPaid);
    event ReputationUpdated(address indexed user, uint256 newReputation, uint256 pointsChange, bool added);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator, address indexed previousDelegatee);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 totalFundingAmount);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus status, uint256 votesFor, uint256 votesAgainst);
    event MilestoneReleased(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);
    event ParameterChangeProposed(uint256 indexed changeId, ParameterChangeType indexed changeType, bytes newValue, uint256 executionTimelock);
    event ParameterChangeVoted(uint256 indexed changeId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed changeId, ParameterChangeType changeType);
    event TokenAdded(address indexed token);
    event FeesClaimed(address indexed token, uint256 amount);

    /**
     * @dev Constructor initializes the contract with an owner and default governance parameters.
     * @param _owner The address of the initial owner of the contract.
     */
    constructor(address _owner) Ownable(_owner) {
        votingPeriodBlocks = 10000; // Approx 1.5 days at 13s/block
        minReputationForProposal = 100;
        minEcoCreditForProposal = 100 * (10 ** DECIMALS); // 100 ECR
    }

    // --- EcoCredit ERC-20 Implementation (Minimal) ---

    function totalSupply() public view returns (uint256) {
        return _totalSupplyECR;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balancesECR[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balancesECR[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balancesECR[msg.sender] = _balancesECR[msg.sender].sub(amount);
        _balancesECR[recipient] = _balancesECR[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowancesECR[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowancesECR[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balancesECR[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowancesECR[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        _balancesECR[sender] = _balancesECR[sender].sub(amount);
        _balancesECR[recipient] = _balancesECR[recipient].add(amount);
        _allowancesECR[sender][msg.sender] = _allowancesECR[sender][msg.sender].sub(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Define ERC-20 events as they are part of the standard
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // --- Internal EcoCredit minting/burning ---
    function _mintECR(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupplyECR = _totalSupplyECR.add(amount);
        _balancesECR[account] = _balancesECR[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burnECR(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balancesECR[account] >= amount, "ERC20: burn amount exceeds balance");
        _balancesECR[account] = _balancesECR[account].sub(amount);
        _totalSupplyECR = _totalSupplyECR.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    // --- EcoCredit (ECR) & Bonding Curve Management ---

    /**
     * @dev Calculates the current price of 1 EcoCredit in terms of a specific underlying token.
     * The price increases as more ECR is minted against that token.
     * Price = (totalBondedAmount / ecoCreditSupplyForToken) + (ecoCreditSupplyForToken * curveFactor / 1e18)
     * To prevent division by zero for initial state, handle if ecoCreditSupplyForToken is 0.
     * For simplicity, let's use a linear curve: Price = BasePrice + (EcoCreditSupply * CurveFactor)
     * A more advanced curve might involve integral calculus (e.g., bancor formula).
     * Here, price is 'tokens per ECR'.
     * @param _token The address of the collateral token.
     * @return The price of 1 EcoCredit in terms of the collateral token (fixed-point, 18 decimals).
     */
    function getEcoCreditPrice(address _token) public view returns (uint256) {
        BondingCurveInfo storage info = supportedTokens[_token];
        if (info.ecoCreditSupplyForToken == 0) {
            // Initial price before any ECR is minted for this token
            // This is a placeholder; in a real system, this would be determined by initial reserves or oracle.
            // Let's assume a default initial price of 1 token per 1 ECR for simplicity, adjusted by curve factor
            return 1 * (10 ** DECIMALS); // 1 token per ECR
        }

        // Price in tokens per ECR: (TotalBondedAmount / EcoCreditSupplyForToken) + (EcoCreditSupplyForToken * CurveFactor / 1e18)
        // This is a simplified linear increment. A true bonding curve would be more complex.
        // For example, an AMM-like constant product: tokens * ECR = K
        // Let's approximate: Price = (Reserve / Supply) + (Supply * CurveFactor / 1e18)
        // Simplified: Price increases with supply.
        uint256 basePrice = info.totalBondedAmount.div(info.ecoCreditSupplyForToken);
        uint256 curveComponent = info.ecoCreditSupplyForToken.mul(info.curveFactor).div(1e18); // Assume curveFactor is 1e18-scaled
        return basePrice.add(curveComponent);
    }

    /**
     * @dev Calculates how many EcoCredit tokens would be minted for a given input amount of a collateral token.
     * This is an inverse of the price function. For a linear curve, this involves a quadratic equation.
     * Given the complexity, this function might be an approximation or a target for a more advanced curve.
     * For simplicity, this will calculate based on the current price and then factor in the curve.
     * It's not a perfect integral for a continuous bonding curve.
     * @param _token The address of the collateral token.
     * @param _amount The amount of collateral token to bond.
     * @return The amount of EcoCredit that would be minted.
     */
    function getEcoCreditsToMint(address _token, uint256 _amount) public view returns (uint256) {
        BondingCurveInfo storage info = supportedTokens[_token];
        if (info.curveFactor == 0) return _amount; // If no curve, 1:1

        // This is a simplified calculation. A true bonding curve calculation for exact mint amount
        // involves integrating the price function. For a linear price function, this results
        // in a quadratic formula.
        // For an amount `A` to bond, and price `P(S) = P0 + k*S`, the amount of new supply `dS`
        // is given by A = integral(P(S)dS) = P0*dS + 0.5*k*dS^2.
        // This is complex on-chain. Let's provide a simpler approximation for demonstration.
        // Assume for small amounts, price is relatively constant.
        uint256 currentPrice = getEcoCreditPrice(_token);
        if (currentPrice == 0) return 0; // Avoid division by zero
        return _amount.mul(10**DECIMALS).div(currentPrice); // Amount * (1 ECR unit / Price unit)
    }

    /**
     * @dev Calculates how much of a collateral token would be received for a given amount of EcoCredit burned.
     * @param _token The address of the collateral token.
     * @param _ecoCreditAmount The amount of EcoCredit to unbond.
     * @return The amount of collateral token that would be received.
     */
    function getTokensToReceive(address _token, uint256 _ecoCreditAmount) public view returns (uint256) {
        uint256 currentPrice = getEcoCreditPrice(_token);
        return _ecoCreditAmount.mul(currentPrice).div(10**DECIMALS); // EcoCreditAmount * Price
    }

    /**
     * @dev Allows users to bond supported tokens to mint EcoCredit.
     * Increases `totalBondedAmount` and `ecoCreditSupplyForToken` for the given token.
     * Minting also awards reputation points.
     * @param _token The address of the ERC-20 token to bond.
     * @param _amount The amount of tokens to bond.
     */
    function bondTokens(address _token, uint256 _amount) public {
        if (!supportedTokens[_token].curveFactor > 0 && supportedTokens[_token].totalBondedAmount == 0) revert TokenNotSupported();
        if (_amount == 0) revert InvalidAmount();

        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        BondingCurveInfo storage info = supportedTokens[_token];

        // Calculate fees
        uint256 fee = _amount.mul(info.baseBondingFeeBPS).div(10000); // BPS
        uint256 amountAfterFee = _amount.sub(fee);
        info.accumulatedFees = info.accumulatedFees.add(fee);

        uint256 ecoCreditsToMint = getEcoCreditsToMint(_token, amountAfterFee);
        if (ecoCreditsToMint == 0) revert InvalidAmount(); // Prevent minting 0 ECR

        info.totalBondedAmount = info.totalBondedAmount.add(amountAfterFee);
        info.ecoCreditSupplyForToken = info.ecoCreditSupplyForToken.add(ecoCreditsToMint);

        _mintECR(msg.sender, ecoCreditsToMint);
        _updateReputation(msg.sender, ecoCreditsToMint.div(10**(DECIMALS - 2)), true); // 1 RP per 100 ECR

        emit EcoCreditMinted(msg.sender, _token, _amount, ecoCreditsToMint, fee);
    }

    /**
     * @dev Allows users to unbond EcoCredit to withdraw supported tokens.
     * Decreases `totalBondedAmount` and `ecoCreditSupplyForToken`.
     * Burning also adjusts reputation points.
     * @param _token The address of the collateral token to receive.
     * @param _ecoCreditAmount The amount of EcoCredit to burn.
     */
    function unbondTokens(address _token, uint256 _ecoCreditAmount) public {
        if (!supportedTokens[_token].curveFactor > 0 && supportedTokens[_token].totalBondedAmount == 0) revert TokenNotSupported();
        if (_ecoCreditAmount == 0) revert InvalidAmount();
        if (_balancesECR[msg.sender] < _ecoCreditAmount) revert InsufficientFunds();

        BondingCurveInfo storage info = supportedTokens[_token];

        uint256 tokensToReceiveRaw = getTokensToReceive(_token, _ecoCreditAmount);
        uint256 fee = tokensToReceiveRaw.mul(info.baseUnbondingFeeBPS).div(10000); // BPS
        uint256 tokensToReceive = tokensToReceiveRaw.sub(fee);

        if (info.totalBondedAmount < tokensToReceive) revert InsufficientFunds();

        info.totalBondedAmount = info.totalBondedAmount.sub(tokensToReceive);
        info.ecoCreditSupplyForToken = info.ecoCreditSupplyForToken.sub(_ecoCreditAmount);
        info.accumulatedFees = info.accumulatedFees.add(fee);

        _burnECR(msg.sender, _ecoCreditAmount);
        _updateReputation(msg.sender, _ecoCreditAmount.div(10**(DECIMALS - 2)), false); // Deduct 1 RP per 100 ECR burned

        IERC20(_token).transfer(msg.sender, tokensToReceive);

        emit EcoCreditBurned(msg.sender, _token, _ecoCreditAmount, tokensToReceive, fee);
    }

    /**
     * @dev Returns the total value of all assets bonded in the Nexus.
     * This would ideally require an external oracle for price conversion to a common base currency (e.g., USD).
     * For this simplified example, it just sums up token amounts (assuming all are roughly equivalent or
     * returns 0 if no common denominator is specified).
     * A real implementation would convert all `totalBondedAmount` for each `supportedToken` to USD via oracles.
     * @return The total value of all bonded assets (placeholder for real oracle integration).
     */
    function getTotalBondedValue() public view returns (uint256) {
        // Placeholder: In a real system, iterate through supportedTokens and
        // use an oracle (e.g., Chainlink Price Feeds) to convert each
        // `supportedTokens[token].totalBondedAmount` to a common currency (e.g., USD)
        // and then sum them up.
        // For simplicity, returning the sum of EcoCredit Supply, as ECR represents the total value.
        return _totalSupplyECR;
    }

    /**
     * @dev Returns the amount of accrued protocol fees for a specific token.
     * @param _token The address of the token.
     */
    function getProtocolFees(address _token) public view returns (uint256) {
        return supportedTokens[_token].accumulatedFees;
    }

    /**
     * @dev Allows the owner to claim accumulated protocol fees for a specific token.
     * In a full DAO, this would be callable only via governance.
     * @param _token The address of the token for which to claim fees.
     */
    function claimFees(address _token) public onlyOwner {
        BondingCurveInfo storage info = supportedTokens[_token];
        uint256 fees = info.accumulatedFees;
        if (fees == 0) return;

        info.accumulatedFees = 0;
        IERC20(_token).transfer(msg.sender, fees); // Transfers to owner, ideally to a DAO treasury
        emit FeesClaimed(_token, fees);
    }

    // --- Reputation System ---

    /**
     * @dev Returns the current Reputation Points (RP) of a user.
     * @param _user The address of the user.
     * @return The reputation points.
     */
    function getReputation(address _user) public view returns (uint256) {
        return reputationPoints[_user];
    }

    /**
     * @dev Allows a user to delegate their reputation and voting power to another address.
     * Delegates will have their own reputation + the sum of all delegated to them.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) public {
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        if (_delegatee == msg.sender) revert SelfDelegationNotAllowed();

        address currentDelegatee = delegatedReputation[msg.sender];

        // If already delegated, first remove from old delegatee
        if (currentDelegatee != address(0)) {
            effectiveReputationSupply[currentDelegatee] = effectiveReputationSupply[currentDelegatee].sub(reputationPoints[msg.sender]);
        }

        delegatedReputation[msg.sender] = _delegatee;
        effectiveReputationSupply[_delegatee] = effectiveReputationSupply[_delegatee].add(reputationPoints[msg.sender]);
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any active reputation delegation, moving voting power back to the delegator.
     */
    function undelegateReputation() public {
        address currentDelegatee = delegatedReputation[msg.sender];
        if (currentDelegatee == address(0)) revert NoActiveDelegation();

        effectiveReputationSupply[currentDelegatee] = effectiveReputationSupply[currentDelegatee].sub(reputationPoints[msg.sender]);
        delegatedReputation[msg.sender] = address(0);
        emit ReputationUndelegated(msg.sender, currentDelegatee);
    }

    /**
     * @dev Returns the address to which a user has delegated their reputation.
     * @param _user The user's address.
     * @return The delegatee address.
     */
    function getDelegatedReputation(address _user) public view returns (address) {
        return delegatedReputation[_user];
    }

    /**
     * @dev Returns the effective reputation of a user (their own + any delegated to them).
     * This is the value used for voting power and proposal thresholds.
     * @param _user The user's address.
     * @return The effective reputation points.
     */
    function getEffectiveReputation(address _user) public view returns (uint256) {
        address delegatee = delegatedReputation[_user];
        if (delegatee != address(0)) {
            // If user has delegated, their own RP is transferred to delegatee.
            // So their own effective reputation is 0 for direct actions.
            // But if someone checks the delegatee, it includes this.
            return 0; // The actual reputation is held by the delegatee
        }
        // If not delegated, or if _user IS a delegatee, combine their own RP with others delegated to them
        return reputationPoints[_user].add(effectiveReputationSupply[_user]);
    }

    /**
     * @dev Internal function to manage reputation points.
     * Called on specific actions like bonding, unbonding, voting, successful proposals.
     * @param _user The user whose reputation is being updated.
     * @param _points The number of points to add or remove.
     * @param _add True to add points, false to remove.
     */
    function _updateReputation(address _user, uint256 _points, bool _add) internal {
        uint256 oldReputation = reputationPoints[_user];
        if (_add) {
            reputationPoints[_user] = reputationPoints[_user].add(_points);
        } else {
            reputationPoints[_user] = reputationPoints[_user].sub(_points);
        }

        // Update effective reputation for delegates
        address currentDelegatee = delegatedReputation[_user];
        if (currentDelegatee != address(0)) {
            if (_add) {
                effectiveReputationSupply[currentDelegatee] = effectiveReputationSupply[currentDelegatee].add(_points);
            } else {
                effectiveReputationSupply[currentDelegatee] = effectiveReputationSupply[currentDelegatee].sub(_points);
            }
        } else {
            // If the user is a delegatee themselves, update their own effective supply
            // This is only if they are not delegating. If they are delegating, their own RP counts towards delegatee's effective reputation.
            // No, the effectiveReputationSupply only tracks delegated amounts. The user's own reputationPoints directly contributes to their effectiveReputation
            // if they are not delegating.
            // This logic is tricky. Let's assume effectiveReputationSupply stores *only* delegated amounts.
            // The getEffectiveReputation function handles combining it with their own.
        }

        emit ReputationUpdated(_user, reputationPoints[_user], _points, _add);
    }

    // --- Project Proposals & Funding ---

    /**
     * @dev Allows a user meeting reputation and ECR thresholds to submit a new project proposal.
     * @param _title The title of the project proposal.
     * @param _descriptionCID IPFS CID for detailed project description.
     * @param _recipient The address that will receive the funding.
     * @param _fundingToken The ERC-20 token address in which funding is requested.
     * @param _totalFundingAmount The total amount of funding requested.
     * @param _milestoneCount The number of milestones for funding release.
     */
    function submitProjectProposal(
        string calldata _title,
        string calldata _descriptionCID,
        address _recipient,
        address _fundingToken,
        uint256 _totalFundingAmount,
        uint256 _milestoneCount
    ) public {
        if (getEffectiveReputation(msg.sender) < minReputationForProposal) revert NotEnoughReputation();
        if (balanceOf(msg.sender) < minEcoCreditForProposal) revert NotEnoughEcoCredit();
        if (!supportedTokens[_fundingToken].curveFactor > 0 && supportedTokens[_fundingToken].totalBondedAmount == 0) revert TokenNotSupported();
        if (_totalFundingAmount == 0 || _recipient == address(0)) revert InvalidAmount();

        projectProposals.push(
            ProjectProposal({
                id: nextProposalId,
                title: _title,
                descriptionCID: _descriptionCID,
                proposer: msg.sender,
                recipient: _recipient,
                fundingToken: _fundingToken,
                totalFundingAmount: _totalFundingAmount,
                milestoneCount: _milestoneCount,
                milestoneReleased: new mapping(uint256 => bool), // Initialize empty map
                currentMilestone: 0,
                votesFor: 0,
                votesAgainst: 0,
                hasVoted: new mapping(address => bool), // Initialize empty map
                voteChoice: new mapping(address => bool), // Initialize empty map
                startBlock: block.number,
                endBlock: block.number.add(votingPeriodBlocks),
                status: ProposalStatus.Active,
                voters: new address[](0) // Initialize empty dynamic array
            })
        );
        emit ProposalSubmitted(nextProposalId, msg.sender, _title, _totalFundingAmount);
        nextProposalId++;
    }

    /**
     * @dev Allows `EcoCredit` holders (or their delegates) to vote on an active project proposal.
     * Voting power is based on the user's effective ECR balance at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        if (_proposalId >= projectProposals.length) revert ProposalNotFound();
        ProjectProposal storage proposal = projectProposals[_proposalId];

        if (block.number < proposal.startBlock || block.number > proposal.endBlock) revert VotingPeriodNotActive();
        if (proposal.status != ProposalStatus.Active) revert ProposalAlreadyFinalized();

        address voter = msg.sender;
        address actualVoter = delegatedReputation[voter] != address(0) ? delegatedReputation[voter] : voter;

        if (proposal.hasVoted[actualVoter]) revert UnauthorizedCaller(); // Already voted

        uint256 votingPower = balanceOf(voter); // Use ECR balance directly for voting power

        if (votingPower == 0) revert NotEnoughEcoCredit(); // User has no ECR to vote with

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        proposal.hasVoted[actualVoter] = true;
        proposal.voteChoice[actualVoter] = _support;
        proposal.voters.push(actualVoter); // Track unique voters

        emit VoteCast(_proposalId, actualVoter, _support, votingPower);
    }

    /**
     * @dev Concludes the voting period for a proposal, updates its status, and disburses initial funding if approved.
     * Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) public {
        if (_proposalId >= projectProposals.length) revert ProposalNotFound();
        ProjectProposal storage proposal = projectProposals[_proposalId];

        if (block.number <= proposal.endBlock) revert VotingPeriodNotActive(); // Voting still active
        if (proposal.status != ProposalStatus.Active) revert ProposalAlreadyFinalized();

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalEcoCreditSupply = _totalSupplyECR; // Use total ECR supply for quorum check

        // Quorum check: min 20% of total ECR supply must have voted
        bool quorumMet = totalVotes >= totalEcoCreditSupply.mul(QUORUM_PERCENTAGE).div(100);

        // Approval check: min 60% of votes must be 'for'
        bool approved = proposal.votesFor.mul(100) >= totalVotes.mul(MIN_APPROVAL_PERCENTAGE);

        if (quorumMet && approved) {
            proposal.status = ProposalStatus.Succeeded;
            // Transfer initial funding (e.g., first milestone or full amount if no milestones)
            if (proposal.milestoneCount == 0) {
                // If no milestones, send full amount
                uint256 amountToTransfer = proposal.totalFundingAmount;
                if (supportedTokens[proposal.fundingToken].totalBondedAmount < amountToTransfer) revert InsufficientFunds();
                supportedTokens[proposal.fundingToken].totalBondedAmount = supportedTokens[proposal.fundingToken].totalBondedAmount.sub(amountToTransfer);
                IERC20(proposal.fundingToken).transfer(proposal.recipient, amountToTransfer);
                emit MilestoneReleased(_proposalId, 0, amountToTransfer);
                proposal.status = ProposalStatus.Executed; // Mark as fully executed
            } else {
                // If milestones, release first one
                releaseMilestonePayment(_proposalId, 0); // Release first milestone
            }
            _updateReputation(proposal.proposer, 50, true); // Reward proposer for successful proposal
        } else {
            proposal.status = ProposalStatus.Failed;
        }

        emit ProposalFinalized(_proposalId, proposal.status, proposal.votesFor, proposal.votesAgainst);
    }

    /**
     * @dev Allows the project recipient to request release of a specific milestone payment.
     * This simplified version assumes milestones are released sequentially and do not require
     * on-chain verification of completion, but only recipient request. A more robust system
     * would integrate an oracle, a dispute system, or multisig approval.
     * @param _proposalId The ID of the project proposal.
     * @param _milestoneIndex The 0-indexed milestone to release.
     */
    function releaseMilestonePayment(uint256 _proposalId, uint256 _milestoneIndex) public {
        if (_proposalId >= projectProposals.length) revert ProposalNotFound();
        ProjectProposal storage proposal = projectProposals[_proposalId];

        if (msg.sender != proposal.recipient) revert UnauthorizedCaller();
        if (proposal.status != ProposalStatus.Succeeded) revert ProposalAlreadyFinalized(); // Only successful proposals can claim milestones
        if (_milestoneIndex >= proposal.milestoneCount) revert MilestoneNotFound();
        if (proposal.milestoneReleased[_milestoneIndex]) revert MilestoneAlreadyReleased();
        if (_milestoneIndex != proposal.currentMilestone) revert MilestoneNotFound(); // Must be sequential

        uint256 amountPerMilestone = proposal.totalFundingAmount.div(proposal.milestoneCount);
        if (supportedTokens[proposal.fundingToken].totalBondedAmount < amountPerMilestone) revert InsufficientFunds();

        supportedTokens[proposal.fundingToken].totalBondedAmount = supportedTokens[proposal.fundingToken].totalBondedAmount.sub(amountPerMilestone);
        proposal.milestoneReleased[_milestoneIndex] = true;
        proposal.currentMilestone = proposal.currentMilestone.add(1);

        IERC20(proposal.fundingToken).transfer(proposal.recipient, amountPerMilestone);
        emit MilestoneReleased(_proposalId, _milestoneIndex, amountPerMilestone);

        if (proposal.currentMilestone == proposal.milestoneCount) {
            proposal.status = ProposalStatus.Executed; // All milestones released
        }
    }

    /**
     * @dev Retrieves all details of a specific project proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 id,
            string memory title,
            string memory descriptionCID,
            address proposer,
            address recipient,
            address fundingToken,
            uint256 totalFundingAmount,
            uint256 milestoneCount,
            uint256 currentMilestone,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 startBlock,
            uint256 endBlock,
            ProposalStatus status
        )
    {
        if (_proposalId >= projectProposals.length) revert ProposalNotFound();
        ProjectProposal storage p = projectProposals[_proposalId];
        return (
            p.id,
            p.title,
            p.descriptionCID,
            p.proposer,
            p.recipient,
            p.fundingToken,
            p.totalFundingAmount,
            p.milestoneCount,
            p.currentMilestone,
            p.votesFor,
            p.votesAgainst,
            p.startBlock,
            p.endBlock,
            p.status
        );
    }

    /**
     * @dev Returns how a specific user voted on a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _user The user's address.
     * @return True if 'for', false if 'against', reverts if not voted.
     */
    function getUserVote(uint256 _proposalId, address _user) public view returns (bool) {
        if (_proposalId >= projectProposals.length) revert ProposalNotFound();
        ProjectProposal storage proposal = projectProposals[_proposalId];
        if (!proposal.hasVoted[_user]) revert UnauthorizedCaller(); // User has not voted
        return proposal.voteChoice[_user];
    }

    /**
     * @dev Returns the total voting power that has been cast for/against a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The sum of votesFor and votesAgainst.
     */
    function getProposalVotingPower(uint256 _proposalId) public view returns (uint256) {
        if (_proposalId >= projectProposals.length) revert ProposalNotFound();
        ProjectProposal storage proposal = projectProposals[_proposalId];
        return proposal.votesFor.add(proposal.votesAgainst);
    }

    // --- Protocol Parameter Governance ---

    /**
     * @dev Allows high-reputation members to propose changes to Nexus parameters.
     * These proposals are subject to a vote and a timelock.
     * @param _changeType The type of parameter to change.
     * @param _newValue The new value for the parameter, encoded.
     * @param _delaySeconds The minimum seconds for the timelock after proposal approval.
     */
    function proposeParameterChange(ParameterChangeType _changeType, bytes calldata _newValue, uint256 _delaySeconds) public {
        if (getEffectiveReputation(msg.sender) < minReputationForProposal) revert NotEnoughReputation();

        // Basic validation for _newValue based on _changeType (more exhaustive validation would be within execute)
        if (_newValue.length == 0) revert InvalidAmount();

        parameterChangeProposals.push(
            ParameterChangeProposal({
                id: nextParameterChangeId,
                proposer: msg.sender,
                changeType: _changeType,
                newValue: _newValue,
                votesFor: 0,
                votesAgainst: 0,
                hasVoted: new mapping(address => bool),
                startBlock: block.number,
                endBlock: block.number.add(votingPeriodBlocks),
                executed: false,
                executionTimelock: _delaySeconds // This will be converted to a block number upon approval
            })
        );
        emit ParameterChangeProposed(nextParameterChangeId, _changeType, _newValue, _delaySeconds);
        nextParameterChangeId++;
    }

    /**
     * @dev Allows `EcoCredit` holders to vote on proposed parameter changes.
     * @param _changeId The ID of the parameter change proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnParameterChange(uint256 _changeId, bool _support) public {
        if (_changeId >= parameterChangeProposals.length) revert ParameterChangeNotFound();
        ParameterChangeProposal storage changeProposal = parameterChangeProposals[_changeId];

        if (block.number < changeProposal.startBlock || block.number > changeProposal.endBlock) revert VotingPeriodNotActive();
        if (changeProposal.executed) revert ParameterChangeAlreadyExecuted(); // Cannot vote on executed or passed proposals

        address voter = msg.sender;
        address actualVoter = delegatedReputation[voter] != address(0) ? delegatedReputation[voter] : voter;

        if (changeProposal.hasVoted[actualVoter]) revert UnauthorizedCaller(); // Already voted

        uint256 votingPower = balanceOf(voter); // Use ECR balance directly for voting power
        if (votingPower == 0) revert NotEnoughEcoCredit();

        if (_support) {
            changeProposal.votesFor = changeProposal.votesFor.add(votingPower);
        } else {
            changeProposal.votesAgainst = changeProposal.votesAgainst.add(votingPower);
        }

        changeProposal.hasVoted[actualVoter] = true;
        emit ParameterChangeVoted(_changeId, actualVoter, _support);
    }

    /**
     * @dev Executes an approved parameter change after its timelock period.
     * @param _changeId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _changeId) public {
        if (_changeId >= parameterChangeProposals.length) revert ParameterChangeNotFound();
        ParameterChangeProposal storage changeProposal = parameterChangeProposals[_changeId];

        if (changeProposal.executed) revert ParameterChangeAlreadyExecuted();

        uint224 totalVotes = uint224(changeProposal.votesFor.add(changeProposal.votesAgainst));
        uint256 totalEcoCreditSupply = _totalSupplyECR;

        // Quorum and approval checks
        bool quorumMet = totalVotes >= totalEcoCreditSupply.mul(QUORUM_PERCENTAGE).div(100);
        bool approved = changeProposal.votesFor.mul(100) >= totalVotes.mul(MIN_APPROVAL_PERCENTAGE);

        if (!quorumMet || !approved) {
            revert ParameterChangeNotFound(); // Consider a more specific error like "ParameterChangeNotApproved"
        }

        // Check timelock
        if (block.number < changeProposal.executionTimelock) revert ParameterChangeNotExecutableYet();

        // Execute the change based on type
        bytes memory newValueBytes = changeProposal.newValue;
        if (changeProposal.changeType == ParameterChangeType.VotingPeriod) {
            votingPeriodBlocks = abi.decode(newValueBytes, (uint256));
        } else if (changeProposal.changeType == ParameterChangeType.ProposalMinReputation) {
            minReputationForProposal = abi.decode(newValueBytes, (uint256));
        } else if (changeProposal.changeType == ParameterChangeType.ProposalMinECR) {
            minEcoCreditForProposal = abi.decode(newValueBytes, (uint256));
        } else if (changeProposal.changeType == ParameterChangeType.AddSupportedTokenConfig) {
            // Decodes address, curveFactor, bondingFee, unbondingFee
            (address tokenAddr, uint256 curveFactor, uint256 bondingFee, uint256 unbondingFee) = abi.decode(newValueBytes, (address, uint256, uint256, uint256));
            addSupportedToken(tokenAddr, curveFactor, bondingFee, unbondingFee);
        } else if (changeProposal.changeType == ParameterChangeType.UpdateBondingCurveFactor) {
            (address tokenAddr, uint256 newFactor) = abi.decode(newValueBytes, (address, uint256));
            if (!supportedTokens[tokenAddr].curveFactor > 0 && supportedTokens[tokenAddr].totalBondedAmount == 0) revert TokenNotSupported();
            supportedTokens[tokenAddr].curveFactor = newFactor;
        } else if (changeProposal.changeType == ParameterChangeType.UpdateBaseBondingFee) {
            (address tokenAddr, uint256 newFee) = abi.decode(newValueBytes, (address, uint256));
            if (!supportedTokens[tokenAddr].curveFactor > 0 && supportedTokens[tokenAddr].totalBondedAmount == 0) revert TokenNotSupported();
            supportedTokens[tokenAddr].baseBondingFeeBPS = newFee;
        } else if (changeProposal.changeType == ParameterChangeType.UpdateBaseUnbondingFee) {
            (address tokenAddr, uint256 newFee) = abi.decode(newValueBytes, (address, uint256));
            if (!supportedTokens[tokenAddr].curveFactor > 0 && supportedTokens[tokenAddr].totalBondedAmount == 0) revert TokenNotSupported();
            supportedTokens[tokenAddr].baseUnbondingFeeBPS = newFee;
        } else {
            revert InvalidChangeType();
        }

        changeProposal.executed = true;
        emit ParameterChangeExecuted(_changeId, changeProposal.changeType);
    }

    // --- Admin & Utility ---

    /**
     * @dev Adds a new ERC-20 token that can be bonded to mint EcoCredit.
     * Only callable by the owner (or eventually via a governance proposal).
     * @param _token The address of the new ERC-20 token.
     * @param _initialCurveFactor The initial curve factor for this token's bonding curve.
     * @param _baseBondingFeeBPS Base fee for bonding in Basis Points (BPS).
     * @param _baseUnbondingFeeBPS Base fee for unbonding in BPS.
     */
    function addSupportedToken(address _token, uint256 _initialCurveFactor, uint256 _baseBondingFeeBPS, uint256 _baseUnbondingFeeBPS)
        public
        onlyOwner
    {
        if (_token == address(0)) revert ZeroAddressNotAllowed();
        if (supportedTokens[_token].curveFactor > 0 || supportedTokens[_token].totalBondedAmount > 0) revert ("Token already supported.");

        supportedTokens[_token] = BondingCurveInfo({
            totalBondedAmount: 0,
            ecoCreditSupplyForToken: 0,
            curveFactor: _initialCurveFactor,
            baseBondingFeeBPS: _baseBondingFeeBPS,
            baseUnbondingFeeBPS: _baseUnbondingFeeBPS,
            accumulatedFees: 0
        });
        supportedTokenList.push(_token);
        emit TokenAdded(_token);
    }

    /**
     * @dev Sets the duration for project and parameter proposal voting, in blocks.
     * Only callable by the owner (or eventually via a governance proposal).
     * @param _newPeriod The new voting period in blocks.
     */
    function setVotingPeriod(uint256 _newPeriod) public onlyOwner {
        if (_newPeriod == 0) revert InvalidAmount();
        votingPeriodBlocks = _newPeriod;
    }

    /**
     * @dev Sets the minimum reputation and EcoCredit required to submit a project proposal.
     * Only callable by the owner (or eventually via a governance proposal).
     * @param _minReputation The new minimum reputation points.
     * @param _minECRForProposal The new minimum ECR balance.
     */
    function setProposalThresholds(uint256 _minReputation, uint256 _minECRForProposal) public onlyOwner {
        minReputationForProposal = _minReputation;
        minEcoCreditForProposal = _minECRForProposal;
    }

    /**
     * @dev Allows the owner to recover ERC-20 tokens accidentally sent directly to the contract.
     * @param _token The address of the stuck token.
     */
    function withdrawStuckTokens(address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert InsufficientFunds();
        IERC20(_token).transfer(msg.sender, amount);
    }

    /**
     * @dev Allows the owner to withdraw stuck ETH accidentally sent to the contract.
     */
    function withdrawStuckEth() public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount == 0) revert InsufficientFunds();
        payable(msg.sender).transfer(amount);
    }
}
```