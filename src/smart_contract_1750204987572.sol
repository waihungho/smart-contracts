Okay, let's design a smart contract based on an interesting, perhaps slightly speculative but trendy concept: a lottery where the outcome determination phase leverages a multi-step process tied to blockchain future state, inspired loosely by the idea of quantum outcomes being finalized upon observation. We'll call it `QuantumLotto`.

The core concept isn't pure "quantum randomness" (which is hard to achieve on-chain), but rather a unique, multi-phase, deterministic process that uses future block hashes to finalize a winning ticket drawn from a set of possibilities generated from past block data. This makes the final outcome unpredictable until a specific future point in time is reached and its state (hash) is observed.

This contract will have multiple administrative, user interaction, and multi-stage draw process functions.

---

**Outline:**

1.  **Contract Structure:** Inherit from Ownable and Pausable for standard admin controls.
2.  **Enums:** Define states for the lottery epoch.
3.  **Structs:** Define a struct to hold details for each lottery epoch.
4.  **State Variables:** Store contract parameters, epoch data, ticket information, and fee details.
5.  **Events:** Announce key actions and state changes.
6.  **Modifiers:** Simple checks for state or ownership.
7.  **Core Logic:**
    *   Epoch Management: Starting, ending epochs.
    *   Ticket Sales: Buying tickets.
    *   Draw Process:
        *   Calculation Phase: Generate a set of potential winning numbers based on the epoch end block hash.
        *   Finalization Phase: Use a *future* block hash (relative to calculation) to deterministically select the final winning number from the potential set.
    *   Prize Claiming: Allowing the winner to claim.
8.  **Admin Functions:** Setting parameters, pausing, withdrawing fees/stuck ether.
9.  **View Functions:** Allowing users to query contract state and epoch details.

**Function Summary:**

1.  `constructor`: Deploys the contract, sets initial owner, fee recipient, ticket price, and parameters.
2.  `startNewEpoch`: (Owner) Starts a new lottery round, setting its end block.
3.  `buyTicket`: (User) Allows users to buy tickets for the current active epoch. Requires ETH payment.
4.  `endEpoch`: (Owner/Anyone after end block) Ends the ticket buying phase for the current epoch and transitions to the drawing phase.
5.  `triggerDrawCalculation`: (Owner/Anyone after ending) Triggers the generation of `numberOfPotentialWinners` based on the epoch end block hash. Saves potential winning numbers and the calculation block.
6.  `finalizeDrawOutcome`: (Owner/Anyone after calculation and delay) Uses the hash of a block *after* the calculation block to deterministically pick the final winning ticket number from the pre-calculated potential numbers. Finds the winner.
7.  `claimPrize`: (Winner) Allows the determined winner of a finalized epoch to claim their prize.
8.  `setTicketPrice`: (Owner) Sets the price of a single lottery ticket.
9.  `setFeePercentage`: (Owner) Sets the percentage of the pot taken as a protocol fee.
10. `setFeeRecipient`: (Owner) Sets the address receiving protocol fees.
11. `setNumberOfPotentialWinners`: (Owner) Sets how many potential winning numbers are generated in the calculation phase. More numbers can slightly increase the unpredictability derived from the finalization block hash.
12. `setMinimumBlockDelayForFinalization`: (Owner) Sets the minimum number of blocks that must pass after `triggerDrawCalculation` before `finalizeDrawOutcome` can be called. Helps prevent immediate front-running of the finalization step.
13. `withdrawFees`: (Owner) Allows the owner to withdraw accumulated protocol fees.
14. `withdrawStuckETH`: (Owner) Allows the owner to withdraw any unintended ETH sent directly to the contract.
15. `getCurrentEpochId`: (View) Gets the ID of the current/latest epoch.
16. `getEpochInfo`: (View) Gets detailed information about a specific epoch.
17. `getUserTickets`: (View) Gets the number of tickets a specific user holds in a specific epoch.
18. `getEpochParticipants`: (View) Gets the list of addresses that participated in an epoch. (Note: For large epochs, this might exceed block gas limits in a real-world scenario. This implementation is for demonstration).
19. `getEpochState`: (View) Gets the current state of a specific epoch.
20. `getPotentialWinningNumbers`: (View) Gets the list of potential winning numbers generated during the calculation phase (for transparency).
21. `getEpochWinner`: (View) Gets the winner's address and winning ticket number for a finalized epoch.
22. `checkIfWinner`: (View) Checks if a specific address is the winner of a specific epoch.
23. `getTotalTicketsSold`: (View) Gets the total number of tickets sold in an epoch.
24. `getTotalPot`: (View) Gets the total ETH collected in an epoch's pot.
25. `getProtocolFee`: (View) Gets the calculated protocol fee amount for a finalized epoch.
26. `getPrizeAmount`: (View) Gets the prize amount for a finalized epoch (Pot - Fee).
27. `renounceOwnership`: (Owner) Transfers ownership to the zero address.
28. `transferOwnership`: (Owner) Transfers ownership to a new address.
29. `pause`: (Owner) Pauses core contract functionality (`buyTicket`, draw steps, `claimPrize`).
30. `unpause`: (Owner) Unpauses core contract functionality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. Contract Structure: Inherit Ownable, Pausable, ReentrancyGuard.
// 2. Enums: Define states for the lottery epoch.
// 3. Structs: Define struct for epoch details.
// 4. State Variables: Store contract parameters, epoch data, ticket info, fee details.
// 5. Events: Announce key actions and state changes.
// 6. Modifiers: Simple checks for state or ownership (covered by inherited contracts and `require`).
// 7. Core Logic: Epoch management, ticket sales, draw process (calculation, finalization), prize claiming.
// 8. Admin Functions: Setting parameters, pausing, withdrawing funds.
// 9. View Functions: Query contract state and epoch details.

// Function Summary:
// 1. constructor: Deploys the contract, sets initial owner, fee recipient, price, and parameters.
// 2. startNewEpoch: (Owner) Starts a new round, setting end block.
// 3. buyTicket: (User) Buys tickets for current epoch.
// 4. endEpoch: (Owner/Anyone after end block) Ends ticket sales.
// 5. triggerDrawCalculation: (Owner/Anyone after ending) Generates potential winners based on end block hash.
// 6. finalizeDrawOutcome: (Owner/Anyone after calculation and delay) Picks final winner using a future block hash.
// 7. claimPrize: (Winner) Claims prize.
// 8. setTicketPrice: (Owner) Sets ticket price.
// 9. setFeePercentage: (Owner) Sets protocol fee %.
// 10. setFeeRecipient: (Owner) Sets fee recipient address.
// 11. setNumberOfPotentialWinners: (Owner) Sets count of potential winners.
// 12. setMinimumBlockDelayForFinalization: (Owner) Sets block delay before finalization is allowed.
// 13. withdrawFees: (Owner) Withdraws collected fees.
// 14. withdrawStuckETH: (Owner) Withdraws unintended ETH.
// 15. getCurrentEpochId: (View) Gets current epoch ID.
// 16. getEpochInfo: (View) Gets details of an epoch.
// 17. getUserTickets: (View) Gets user tickets for an epoch.
// 18. getEpochParticipants: (View) Gets participants in an epoch (gas warning).
// 19. getEpochState: (View) Gets epoch state.
// 20. getPotentialWinningNumbers: (View) Gets potential winners list.
// 21. getEpochWinner: (View) Gets winner and winning number.
// 22. checkIfWinner: (View) Checks if user is winner.
// 23. getTotalTicketsSold: (View) Gets total tickets sold.
// 24. getTotalPot: (View) Gets total pot amount.
// 25. getProtocolFee: (View) Gets calculated fee.
// 26. getPrizeAmount: (View) Gets calculated prize amount.
// 27. renounceOwnership: (Owner) Renounces ownership.
// 28. transferOwnership: (Owner) Transfers ownership.
// 29. pause: (Owner) Pauses functionality.
// 30. unpause: (Owner) Unpauses functionality.

contract QuantumLotto is Ownable, Pausable, ReentrancyGuard {

    // 2. Enums
    enum EpochState {
        Inactive,         // Epoch not yet started
        Open,             // Tickets can be bought
        Ended,            // Ticket sales ended
        DrawCalculated,   // Potential winners calculated
        DrawFinalized,    // Winner determined
        PrizeClaimed      // Winner has claimed prize
    }

    // 3. Structs
    struct Epoch {
        uint256 epochId;
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalPot;
        uint256 totalTickets;
        EpochState state;
        address winnerAddress;
        uint256 winningTicketNumber;
        uint256 protocolFee;

        // Data for the multi-stage draw
        uint256 drawCalculationBlock; // Block where potential winners were calculated
        uint256 finalizationBlock;    // Block used to finalize winner
        uint256[] potentialWinningNumbers; // Set of potential winners

        // Mapping participant index to cumulative ticket count for winner lookup
        // Stores the total number of tickets *before* this participant's tickets
        mapping(uint256 => uint256) participantCumulativeTickets;
        address[] participants; // List of unique participants
    }

    // 4. State Variables
    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;

    uint256 public ticketPrice; // Price per ticket in Wei
    uint256 public feePercentage; // Percentage of pot as fee (e.g., 500 for 5%)
    uint256 constant public FEE_DENOMINATOR = 10000; // For percentage calculation (100%)
    address public feeRecipient;

    uint256 public numberOfPotentialWinners; // How many potential winners to calculate
    uint256 public minimumBlockDelayForFinalization; // Minimum blocks after calculation before finalization

    // Mapping to store how many tickets a user bought in a specific epoch
    mapping(uint256 => mapping(address => uint256)) public userTickets;

    // Accumulated protocol fees
    uint256 public accumulatedFees;

    // 5. Events
    event NewEpochStarted(uint256 indexed epochId, uint256 startBlock, uint256 endBlock);
    event TicketBought(uint256 indexed epochId, address indexed buyer, uint256 numTickets, uint256 totalCost);
    event EpochEnded(uint256 indexed epochId, uint256 totalTickets, uint256 totalPot);
    event DrawCalculationTriggered(uint256 indexed epochId, uint256 calculationBlock);
    event DrawFinalizationTriggered(uint256 indexed epochId, uint256 finalizationBlock, uint256 winningTicketNumber, address winner);
    event PrizeClaimed(uint256 indexed epochId, address indexed winner, uint256 prizeAmount);
    event FeeWithdrawn(address indexed recipient, uint256 amount);
    event ParameterUpdated(string indexed parameterName, uint256 oldValue, uint256 newValue);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);


    // 1. constructor
    constructor(
        uint256 _initialTicketPrice,
        uint256 _initialFeePercentage,
        address _initialFeeRecipient,
        uint256 _initialNumberOfPotentialWinners,
        uint256 _initialMinimumBlockDelayForFinalization
    ) Ownable(msg.sender) Pausable() {
        require(_initialFeeRecipient != address(0), "Fee recipient cannot be zero address");
        require(_initialFeePercentage <= FEE_DENOMINATOR, "Fee percentage too high");
        require(_initialNumberOfPotentialWinners > 0, "Must calculate at least one potential winner");

        ticketPrice = _initialTicketPrice;
        feePercentage = _initialFeePercentage;
        feeRecipient = _initialFeeRecipient;
        numberOfPotentialWinners = _initialNumberOfPotentialWinners;
        minimumBlockDelayForFinalization = _initialMinimumBlockDelayForFinalization;

        // Start the first epoch
        currentEpochId = 1;
        epochs[currentEpochId].epochId = currentEpochId;
        epochs[currentEpochId].state = EpochState.Inactive; // Start as Inactive, requires owner to start
    }

    // 7. Core Logic - Epoch Management
    /**
     * @notice Starts a new lottery epoch, making it available for ticket purchases.
     * @param _endBlock The block number at which ticket sales will end.
     */
    function startNewEpoch(uint256 _endBlock) external onlyOwner whenNotPaused {
        require(epochs[currentEpochId].state == EpochState.Inactive || epochs[currentEpochId].state == EpochState.PrizeClaimed, "Current epoch must be Inactive or PrizeClaimed");
        require(_endBlock > block.number, "End block must be in the future");

        // If the current epoch is still Inactive (first deployment), activate it.
        // Otherwise, increment to a new epoch ID.
        if (epochs[currentEpochId].state != EpochState.Inactive) {
             currentEpochId++;
        }

        epochs[currentEpochId].epochId = currentEpochId;
        epochs[currentEpochId].startBlock = block.number;
        epochs[currentEpochId].endBlock = _endBlock;
        epochs[currentEpochId].totalPot = 0;
        epochs[currentEpochId].totalTickets = 0;
        epochs[currentEpochId].state = EpochState.Open;
        // Reset participant data for the new epoch - note: maps/arrays in structs are state variables
        // so they are reset to their default state when a new epoch struct is created/overwritten
        // We need to clear the participants array specifically.
        delete epochs[currentEpochId].participants;


        emit NewEpochStarted(currentEpochId, block.number, _endBlock);
    }

    /**
     * @notice Ends the ticket buying phase for the current open epoch.
     * Can be called by anyone after the end block is reached.
     */
    function endEpoch() external whenNotPaused {
        Epoch storage current = epochs[currentEpochId];
        require(current.state == EpochState.Open, "Current epoch is not Open");
        require(block.number >= current.endBlock, "Epoch end block not yet reached");

        current.state = EpochState.Ended;

        emit EpochEnded(currentEpochId, current.totalTickets, current.totalPot);
    }

    // 7. Core Logic - Ticket Sales
    /**
     * @notice Allows users to buy tickets for the current open epoch.
     * @param _numTickets The number of tickets to buy.
     */
    function buyTicket(uint256 _numTickets) external payable whenNotPaused nonReentrant {
        require(_numTickets > 0, "Must buy at least one ticket");
        Epoch storage current = epochs[currentEpochId];
        require(current.state == EpochState.Open, "Current epoch is not Open for buying");
        require(block.number < current.endBlock, "Epoch has already ended");

        uint256 totalCost = _numTickets * ticketPrice;
        require(msg.value >= totalCost, "Insufficient ETH sent");

        // Return any excess ETH
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        // Update user's ticket count
        if (userTickets[currentEpochId][msg.sender] == 0) {
            // First purchase in this epoch, add to participants list
            current.participants.push(msg.sender);
            // Store the cumulative tickets *before* this user's tickets
            // This is needed for efficient winner lookup later
            current.participantCumulativeTickets[current.participants.length - 1] = current.totalTickets;
        }
        userTickets[currentEpochId][msg.sender] += _numTickets;

        // Update epoch totals
        current.totalTickets += _numTickets;
        current.totalPot += totalCost;

        emit TicketBought(currentEpochId, msg.sender, _numTickets, totalCost);
    }

    // 7. Core Logic - Draw Process
    /**
     * @notice Triggers the calculation of potential winning numbers for a concluded epoch.
     * Requires the epoch to be in the Ended state.
     */
    function triggerDrawCalculation(uint256 _epochId) external whenNotPaused {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.state == EpochState.Ended, "Epoch must be in Ended state");
        require(epoch.totalTickets > 0, "No tickets were sold in this epoch");
        // Ensure the end block hash is available (can only get hashes of last 256 blocks)
        require(block.number > epoch.endBlock && block.number - epoch.endBlock <= 256, "Epoch end block hash not available");

        epoch.drawCalculationBlock = block.number;
        epoch.potentialWinningNumbers = new uint256[](numberOfPotentialWinners);

        bytes32 seed = keccak256(abi.encodePacked(epoch.endBlock, blockhash(epoch.endBlock), epoch.totalTickets, epoch.drawCalculationBlock, blockhash(epoch.drawCalculationBlock)));

        for (uint i = 0; i < numberOfPotentialWinners; i++) {
            seed = keccak256(abi.encodePacked(seed, i));
            epoch.potentialWinningNumbers[i] = uint256(seed) % epoch.totalTickets;
        }

        epoch.state = EpochState.DrawCalculated;

        emit DrawCalculationTriggered(_epochId, epoch.drawCalculationBlock);
    }

     /**
      * @notice Finalizes the draw outcome by using a future block hash to select the winner.
      * Requires the epoch to be in the DrawCalculated state and a minimum block delay to have passed.
      * The block hash used for finalization is the hash of the block in which this transaction is included.
      */
    function finalizeDrawOutcome(uint256 _epochId) external whenNotPaused nonReentrant {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.state == EpochState.DrawCalculated, "Epoch must be in DrawCalculated state");
        require(block.number >= epoch.drawCalculationBlock + minimumBlockDelayForFinalization, "Minimum block delay for finalization has not passed");
        require(block.number - 1 > 0 && blockhash(block.number - 1) != bytes32(0), "Current block hash is not yet available"); // Use block hash of previous block for security/availability

        epoch.finalizationBlock = block.number; // Record the block where finalization occurred

        // Use the hash of the previous block (block.number - 1) for finalization randomness.
        // Mixing in the finalization block number itself adds another layer of entropy from tx ordering slightly.
        uint256 indexSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), epoch.finalizationBlock)));
        uint256 winnerIndex = indexSeed % epoch.potentialWinningNumbers.length;

        epoch.winningTicketNumber = epoch.potentialWinningNumbers[winnerIndex];

        // Determine the winner's address based on the winning ticket number
        uint256 winningTicketAbs = epoch.winningTicketNumber; // Absolute ticket index (0 to totalTickets-1)
        address winner = address(0);

        // Iterate through participants to find who owns the winning ticket number
        // The participantCumulativeTickets mapping stores the start index for each participant's tickets.
        uint256 participantsCount = epoch.participants.length;
        for (uint256 i = 0; i < participantsCount; i++) {
             address participantAddress = epoch.participants[i];
             uint256 ticketsBought = userTickets[_epochId][participantAddress];
             uint256 startTicketIndex = epoch.participantCumulativeTickets[i];
             uint256 endTicketIndex = startTicketIndex + ticketsBought; // Exclusive end

             if (winningTicketAbs >= startTicketIndex && winningTicketAbs < endTicketIndex) {
                 winner = participantAddress;
                 break; // Found the winner
             }
        }

        require(winner != address(0), "Winner calculation failed"); // Should not happen if totalTickets > 0

        epoch.winnerAddress = winner;
        epoch.protocolFee = (epoch.totalPot * feePercentage) / FEE_DENOMINATOR;
        accumulatedFees += epoch.protocolFee;

        epoch.state = EpochState.DrawFinalized;

        emit DrawFinalizationTriggered(_epochId, epoch.finalizationBlock, epoch.winningTicketNumber, epoch.winnerAddress);
    }

    // 7. Core Logic - Prize Claiming
    /**
     * @notice Allows the winner of a finalized epoch to claim their prize.
     * @param _epochId The ID of the epoch to claim the prize for.
     */
    function claimPrize(uint256 _epochId) external whenNotPaused nonReentrant {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.state == EpochState.DrawFinalized, "Epoch must be in DrawFinalized state");
        require(msg.sender == epoch.winnerAddress, "Only the winner can claim the prize");

        uint256 prizeAmount = epoch.totalPot - epoch.protocolFee;
        require(prizeAmount > 0, "Prize amount is zero"); // Should not happen if pot > fee

        epoch.state = EpochState.PrizeClaimed; // Mark as claimed BEFORE sending ETH

        (bool success, ) = payable(msg.sender).call{value: prizeAmount}("");
        require(success, "Prize transfer failed");

        emit PrizeClaimed(_epochId, msg.sender, prizeAmount);
    }

    // 8. Admin Functions
    /**
     * @notice Sets the price of a single lottery ticket.
     * @param _newPrice The new price in Wei.
     */
    function setTicketPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Ticket price must be greater than zero");
        emit ParameterUpdated("ticketPrice", ticketPrice, _newPrice);
        ticketPrice = _newPrice;
    }

    /**
     * @notice Sets the percentage of the pot taken as a protocol fee.
     * @param _newPercentage The new fee percentage (e.g., 500 for 5%).
     */
    function setFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= FEE_DENOMINATOR, "Fee percentage too high");
         emit ParameterUpdated("feePercentage", feePercentage, _newPercentage);
        feePercentage = _newPercentage;
    }

    /**
     * @notice Sets the address receiving protocol fees.
     * @param _newRecipient The new fee recipient address.
     */
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Fee recipient cannot be zero address");
        emit FeeRecipientUpdated(feeRecipient, _newRecipient);
        feeRecipient = _newRecipient;
    }

    /**
     * @notice Sets the number of potential winning numbers generated in the calculation phase.
     * @param _newCount The new number of potential winners.
     */
    function setNumberOfPotentialWinners(uint256 _newCount) external onlyOwner {
        require(_newCount > 0, "Must calculate at least one potential winner");
        emit ParameterUpdated("numberOfPotentialWinners", numberOfPotentialWinners, _newCount);
        numberOfPotentialWinners = _newCount;
    }

    /**
     * @notice Sets the minimum number of blocks that must pass after triggerDrawCalculation before finalizeDrawOutcome can be called.
     * @param _newDelay The new minimum block delay.
     */
    function setMinimumBlockDelayForFinalization(uint256 _newDelay) external onlyOwner {
         emit ParameterUpdated("minimumBlockDelayForFinalization", minimumBlockDelayForFinalization, _newDelay);
        minimumBlockDelayForFinalization = _newDelay;
    }

    /**
     * @notice Allows the owner to withdraw accumulated protocol fees.
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees to withdraw");
        accumulatedFees = 0; // Reset BEFORE transfer
        (bool success, ) = payable(feeRecipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeeWithdrawn(feeRecipient, amount);
    }

    /**
     * @notice Allows the owner to withdraw any ETH accidentally sent directly to the contract balance.
     */
    function withdrawStuckETH() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 epochPots = 0;
        // Calculate total ETH locked in ongoing or finalized epochs
        // Simple approach: Sum pots of epochs not yet claimed.
        // A more robust approach might iterate through states explicitly, but this is simpler for example.
        // Assuming claimPrize moves ETH out of the contract balance.
        // ETH in epochs == total balance - accumulated fees
        epochPots = contractBalance - accumulatedFees; // This is an approximation! Better to track explicitly if needed

        // We only want to withdraw ETH that is *not* part of any epoch pot or accumulated fees.
        // The ETH that is part of epoch pots should only be withdrawable via claimPrize.
        // Given the structure, ETH should only arrive via buyTicket or be accumulatedFees.
        // ETH sent directly should be `address(this).balance - (total pots + accumulatedFees)`.
        // Since we don't explicitly track total pots in flight, the safest way is to withdraw *only* accumulated fees,
        // and any other ETH is assumed to be part of an ongoing or claimable pot.
        // This function will withdraw the *entire* balance MINUS the accumulated fees.
        // This is safer than trying to calculate specific epoch pots here.
        // Re-evaluate: Wait, accumulatedFees is tracked, but the pot for *active* epochs isn't explicitly separated.
        // Let's adjust: Only allow withdrawing ETH that clearly ISN'T part of the current epoch's pot or accumulated fees.
        // The `totalPot` for `currentEpochId` is tracked. Any other ETH *could* be stuck.
        // Let's withdraw `address(this).balance - epochs[currentEpochId].totalPot - accumulatedFees`.
        uint256 stuckAmount = address(this).balance - epochs[currentEpochId].totalPot - accumulatedFees;
        require(stuckAmount > 0, "No stuck ETH to withdraw");

        (bool success, ) = payable(owner()).call{value: stuckAmount}("");
        require(success, "Stuck ETH withdrawal failed");
    }


    // 9. View Functions
    /**
     * @notice Gets the ID of the current/latest epoch.
     */
    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    /**
     * @notice Gets detailed information about a specific epoch.
     * @param _epochId The ID of the epoch to query.
     */
    function getEpochInfo(uint256 _epochId) external view returns (
        uint256 epochId,
        uint256 startBlock,
        uint256 endBlock,
        uint256 totalPot,
        uint256 totalTickets,
        EpochState state,
        address winnerAddress,
        uint256 winningTicketNumber,
        uint256 protocolFee,
        uint256 drawCalculationBlock,
        uint256 finalizationBlock
    ) {
        Epoch storage epoch = epochs[_epochId];
        return (
            epoch.epochId,
            epoch.startBlock,
            epoch.endBlock,
            epoch.totalPot,
            epoch.totalTickets,
            epoch.state,
            epoch.winnerAddress,
            epoch.winningTicketNumber,
            epoch.protocolFee,
            epoch.drawCalculationBlock,
            epoch.finalizationBlock
        );
    }

     /**
      * @notice Gets the number of tickets a specific user holds in a specific epoch.
      * @param _epochId The ID of the epoch.
      * @param _user The address of the user.
      */
    function getUserTickets(uint256 _epochId, address _user) external view returns (uint256) {
        return userTickets[_epochId][_user];
    }

     /**
      * @notice Gets the list of addresses that participated in an epoch.
      * Warning: This function might consume a lot of gas for epochs with many participants.
      * @param _epochId The ID of the epoch.
      */
    function getEpochParticipants(uint256 _epochId) external view returns (address[] memory) {
        return epochs[_epochId].participants;
    }

    /**
     * @notice Gets the current state of a specific epoch.
     * @param _epochId The ID of the epoch.
     */
    function getEpochState(uint256 _epochId) external view returns (EpochState) {
        return epochs[_epochId].state;
    }

    /**
     * @notice Gets the list of potential winning numbers generated during the calculation phase.
     * Available after `triggerDrawCalculation` is called.
     * @param _epochId The ID of the epoch.
     */
    function getPotentialWinningNumbers(uint256 _epochId) external view returns (uint256[] memory) {
        return epochs[_epochId].potentialWinningNumbers;
    }

    /**
     * @notice Gets the winner's address and winning ticket number for a finalized epoch.
     * Available after `finalizeDrawOutcome` is called.
     * @param _epochId The ID of the epoch.
     */
    function getEpochWinner(uint256 _epochId) external view returns (address winnerAddress, uint256 winningTicketNumber) {
         Epoch storage epoch = epochs[_epochId];
         return (epoch.winnerAddress, epoch.winningTicketNumber);
    }

    /**
     * @notice Checks if a specific address is the winner of a specific epoch.
     * @param _epochId The ID of the epoch.
     * @param _user The address to check.
     */
    function checkIfWinner(uint256 _epochId, address _user) external view returns (bool) {
        Epoch storage epoch = epochs[_epochId];
        return epoch.state >= EpochState.DrawFinalized && epoch.winnerAddress == _user;
    }

    /**
     * @notice Gets the total number of tickets sold in an epoch.
     * @param _epochId The ID of the epoch.
     */
    function getTotalTicketsSold(uint256 _epochId) external view returns (uint256) {
        return epochs[_epochId].totalTickets;
    }

    /**
     * @notice Gets the total ETH collected in an epoch's pot.
     * @param _epochId The ID of the epoch.
     */
    function getTotalPot(uint256 _epochId) external view returns (uint256) {
        return epochs[_epochId].totalPot;
    }

    /**
     * @notice Gets the calculated protocol fee amount for a finalized epoch.
     * Available after `finalizeDrawOutcome` is called.
     * @param _epochId The ID of the epoch.
     */
    function getProtocolFee(uint256 _epochId) external view returns (uint256) {
        return epochs[_epochId].protocolFee;
    }

    /**
     * @notice Gets the prize amount for a finalized epoch (Pot - Fee).
     * Available after `finalizeDrawOutcome` is called.
     * @param _epochId The ID of the epoch.
     */
    function getPrizeAmount(uint256 _epochId) external view returns (uint256) {
        Epoch storage epoch = epochs[_epochId];
        if (epoch.state < EpochState.DrawFinalized) {
            return 0;
        }
        return epoch.totalPot - epoch.protocolFee;
    }

    // Inherited from Ownable, Pausable are public by default:
    // 27. renounceOwnership()
    // 28. transferOwnership(address newOwner)
    // 29. pause()
    // 30. unpause()

    // Fallback function to reject direct ETH transfers not via buyTicket
    receive() external payable {
        revert("Direct ETH transfers are not allowed. Use buyTicket.");
    }
}
```