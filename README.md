<h1 align="center">Flutter Advance base Easy game</h1>

<h2 align="center">This is a scientific experiment to predict lottery winnings based on the structure of a binary matrix

the logic of a binary matrix with 1 million participants and 1 billion cells </h2>



## Projects that inspired this project

https://github.com/user-attachments/assets/58c1ac8d-a3e3-452c-8c0c-01509652a688

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


- [] Binary matrix system for 17 levels, filling slots sequentially (left-to-right) across multiple lines.
- [] Dynamic slot allocation with priority for unoccupied cells in the uppermost rows.
- [] Full cycle logic: movement of participants to the next available line after slot completion.
- [] Infinite matrix scalability for participants with binary growth structure (1 → 2 → 4 → 8).
- [] ETH-based entry for each level with pre-defined costs, increasing with level hierarchy.
- [] 	Reward distribution system:
	•	80% base reward to a random higher participant in the same level.
	•	20% referral rewards:
	•	First-line referral: 9.5% (with 0.5% going to a special operational wallet).
	•	Second-line referral: 6%.
	•	Third-line referral: 4%.
- [] Smart contract automation for reward distribution and participant tracking, ensuring transparency and accuracy.
- [] Notification system for participants, tracking referrals and reward status in real-time.
- [] Freezing levels after two cycles if the next higher level is not activated, with a mechanism to unfreeze permanently upon final level activation.
- [] Visualization of participant positions in the matrix, showing live slot allocation and progression.
