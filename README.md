# GlobalAccountBook

## Introduction
A lightweight and efficient personal finance management app built for HarmonyOS 5+. This project demonstrates how to build a real-world ArkTS application using the HarmonyOS SDK, including UI layout, state management, data persistence, and multi-device adaptability.
```
Accountbook/
├── entry/
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/
│   │   │   │   ├── pages/           # Main pages (Home, AddRecord, Statistics)
│   │   │   │   ├── models/          # data logic
│   │   │   │   ├── utils/           # Helpers (currency, date, format)
│   │   │   │   └── data/            # Local storage & persistence
│   │   │   ├── resources/           # App resources (strings, images)
│   │   │   └── config.json/         # App configuration
│   └── build-profile.json5/         # Build configuration
└── ...

```

 Features
 - Expense & Income Recording  
Add daily transactions with category, amount, date, and notes.

 - Multi‑Currency Support  
Supports 30+ currencies with automatic conversion to a base currency.

 - Statistics Dashboard  
Monthly and yearly charts for spending trends and category breakdown.

 - Record Filtering  
Filter by date, category, or keyword.

 - Category Management  
Customize income and expense categories.

- Light & Dark Mode  
Adaptive UI based on system theme.

Video Demo for adding a new record 
![2025-12-30 21-31-34 (1)](https://github.com/user-attachments/assets/84c3d663-869f-43c1-b7b7-2aab92310ccd)

An screenshot for currency page. The currency subscription board and currency card were displayed.

<img width="438" height="944" alt="Screenshot_20251230221821964" src="https://github.com/user-attachments/assets/bcbcbecc-8f1c-4070-8079-3ec930d7d16c" />


Running on the HarmonyOS Emulator
This project supports running on the HarmonyOS emulator (6.0.0 or above) provided by DevEco Studio.
You can launch the application directly on an emulator without requiring a physical device.

The emulator supports most features used in this project, including UI rendering, navigation, state management, and local data storage.

Build
Open DevEco Studio
```
Select File > Open and choose the Accountbook project folder
```

Wait for dependencies to sync
Select the entry module
Click ```Build > Build App(s)```


