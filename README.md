<h1 align="center">Flutter Advance base Easy game</h1>

<h2 align="center">This is a scientific experiment to predict lottery winnings based on the structure of a binary matrix

the logic of a binary matrix with 1 million participants and 1 billion cells </h2>



## Projects that inspired this project

https://github.com/user-attachments/assets/58c1ac8d-a3e3-452c-8c0c-01509652a688

https://github.com/user-attachments/assets/3de84796-1989-427a-940f-5a065092dabf

![image](https://github.com/user-attachments/assets/9827c830-0ba7-4259-9f9c-03e4612fdc90)

![image](https://github.com/user-attachments/assets/b22ca094-b357-4c67-8106-12e77d26ca82)

![image](https://github.com/user-attachments/assets/460be616-79b3-4d29-9181-e152b386c298)

![WhatsApp Image 2024-11-30 at 07 06 56](https://github.com/user-attachments/assets/eb0bae6e-7d97-43dc-b8cb-7c6c11633b31)








### Features that have been implemented and tested
- [x] Private key of wallet is used to fetch public key and eth in wallet.
- [x] Multiple Account can be saved for future use.
- [x] Light mode and Dark mode theme.
- [x] Dashboard with the list of public lotteries created by community.
- [x] Lotteries can only be activated by the creator of the lottery.
- [x] Lottery can only be deleted by the creator of the lottery.
- [x] Anyone can participate into lottery by spending eth limit set by the creator.
- [x] Maximum entries is also set by the creator of the lottery.
- [x] Winner is chosen by random inside the contract, triggered by lottery creator.
- [x] Total ether collected is paid to the winner automatically upon winner selection.



### Features to be implemented


- [ ]  Binary matrix system for 17 levels, filling slots sequentially (left-to-right) across multiple lines.
- [ ]  Dynamic slot allocation with priority for unoccupied cells in the uppermost rows.
- [ ] Full cycle logic: movement of participants to the next available line after slot completion.
- [ ]  Infinite matrix scalability for participants with binary growth structure (1 → 2 → 4 → 8).
- [ ]  ETH-based entry for each level with pre-defined costs, increasing with level hierarchy.
- [ ]  Reward distribution system:
- [ ] 80% base reward to a random higher participant in the same level.
- [ ]  20% referral rewards:
- [ ]  First-line referral: 9.5% (with 0.5% going to a special operational wallet).
- [ ] Second-line referral: 6%.
- [ ]  Third-line referral: 4%.
- [ ]  Smart contract automation for reward distribution and participant tracking, ensuring transparency and accuracy.
- [ ]  Notification system for participants, tracking referrals and reward status in real-time.
- [ ]  Freezing levels after two cycles if the next higher level is not activated, with a mechanism to unfreeze permanently upon final level activation.
- [ ]  Visualization of participant positions in the matrix, showing live slot allocation and progression.







### The final logic of the binary matrix with 1 million participants and 1 billion cells



Binary Matrix Structure
Total cell size: 1,000,000,000 (1 billion).
Number of participants: 1,000,000 (1 million).
How it works:
Each level contains 2^n cells, where n is the level number (starting with n = 0).
Participants are added from left to right, filling the top rows before moving to the bottom.


Calculating Filled Levels
Formula for calculating the number of participants needed to fill the first n levels:

\text{Participants} = \sum_{k=0}^{n} 2^k = 2^{n+1} - 1

Result for n = 19 :
2^{20} - 1 = 1,048,575 .
Since we only have 1,000,000 participants, only the first 19 levels are completely filled.
Remaining participants on level 20:
1,000,000 - 524,287 = 475,713 .
Available 2^{20} = 1,048,576 cells on level 20.
Filling: \frac{475,713}{1,048,576} \approx 45.36\% .

Recycles (Recycle)
Recycle conditions:
A recycle occurs when two cells under the player are filled.
The player moves to the next available level, starting with the left cell.
Number of recycles:
At the n -th level: R_n = \frac{2^n}{2} = 2^{n-1} .
For the first 19 levels (full filling):

R_{\text{19 levels}} = \sum_{n=1}^{19} 2^{n-1} = 524,287 \, \text{recycles}.

At the 20th level:
475,713 / 2 = 237,856 \, \text{recycles} .
At the 21st level:
237,856 / 2 = 118,928 \, \text{recycles} .
Total recycles:
\text{Total} = 524,287 + 237,856 + 118,928 + \dots , decreasing as you go down.

Final distribution of participants
Full occupancy:
Levels 1–19: fully occupied.
Partial occupancy:
Level 20: 45.36\% .
Level 21: \frac{237,856}{2,097,152} \approx 11.34\% .
Level 22: the process continues with decreasing density.
Recycle dynamics:
Recycles ensure the redistribution of participants across the lower levels while there are free spaces.
Occupancy density:
With 1 million participants:

\frac{1,000,000}{1,000,000,000} \times 100\% = 0.1\%.

Most of the matrix remains unoccupied, creating space for future participants.


Basic principles of the system
Room for growth:
The binary matrix allows for a virtually unlimited number of participants.
The system remains active even with a significant increase in participants.
Recycles and movement:
Recycles support the movement of participants down the matrix, ensuring uniform filling of new cells.
Level dynamics:
Participants fill the upper levels sequentially.
Upon reaching level 19, the matrix continues to partially fill the lower levels.


Example of participant movement
Levels 1–19:
Participants 1–524,287 completely fill these levels.
Level 20:
Participants 524,288–1,000,000 occupy 45.36\% of available cells.
First wave of recycles: 237,856 participants are redistributed downwards.
Level 21:
118,928 participants occupy 11.34\% of cells.
Redistribution continues.





