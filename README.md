# TicTacToe iOS App

## Overview
This is a simple TicTacToe game developed for iOS using Swift. The app allows users to play TicTacToe against each other or against a computer.

## Features
- **Two Player Mode:** Play against a friend.
- **Single Player Mode:** Play against the computer.
- **Score Tracking:** Keep track of wins.
- **User-friendly Interface:** Easy to navigate.

## Architecture
The app is built using the Model-View-Controller (MVC) design pattern. The key components include:
- **Model:** Represents the game state and logic.
- **View:** Displays the game board and user interface.
- **Controller:** Manages user interactions and game flow.

## Gameplay
Players take turns marking a cell in a 3x3 grid. The first player to get three in a row (horizontally, vertically, or diagonally) wins the game. If all cells are filled without any player achieving three in a row, the game ends in a draw.

## Requirements
- **Xcode**: Latest version
- **Swift**: Latest version (Swift 6 or later)
- **iOS Deployment Target**: iOS 14.0 or later

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/peternicholls/tictactoe.git
   ```
2. Open the project in Xcode.
3. Build and run the project.

## Modern Swift 6 Implementation
This app utilizes the latest Swift 6 features and best practices such as:
- **Concurrency:** Using async/await for smoother asynchronous tasks.
- **SwiftUI:** Leveraging the SwiftUI framework for building user interfaces.
- **Combine Framework:** For handling events and data flow reactive way.

Enjoy playing TicTacToe!