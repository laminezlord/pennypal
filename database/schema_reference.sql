-- PennyPal conceptual relational schema reference.
-- The submitted application uses Firebase Firestore rather than SQL.
-- This file mirrors the SRS entities for the required database-design deliverable.

CREATE TABLE Users (
  UserId VARCHAR(128) PRIMARY KEY,
  FullName VARCHAR(200) NOT NULL,
  Email VARCHAR(255) NOT NULL,
  MobileNumber VARCHAR(40) NOT NULL,
  Role VARCHAR(20) NOT NULL DEFAULT 'student',
  CreatedAt TIMESTAMP,
  LastLogin TIMESTAMP
);

CREATE TABLE UserProfiles (
  ProfileId VARCHAR(128) PRIMARY KEY,
  UserId VARCHAR(128) NOT NULL,
  StudentStatus VARCHAR(40),
  CurrencyPreference VARCHAR(10),
  NotificationPreference BOOLEAN,
  ProfileImage TEXT
);

CREATE TABLE Transactions (
  TransactionId VARCHAR(128) PRIMARY KEY,
  UserId VARCHAR(128) NOT NULL,
  Type VARCHAR(20) NOT NULL,
  Amount DECIMAL(14,2) NOT NULL,
  CategoryId VARCHAR(128),
  Description TEXT,
  Date DATE,
  PaymentMode VARCHAR(50),
  ReceiptImageUrl TEXT,
  CreatedAt TIMESTAMP
);

CREATE TABLE Budgets (
  BudgetId VARCHAR(128) PRIMARY KEY,
  UserId VARCHAR(128) NOT NULL,
  Month VARCHAR(7) NOT NULL,
  CategoryId VARCHAR(128),
  LimitAmount DECIMAL(14,2) NOT NULL,
  AlertThreshold DECIMAL(5,2),
  CreatedAt TIMESTAMP
);

CREATE TABLE SavingsGoals (
  GoalId VARCHAR(128) PRIMARY KEY,
  UserId VARCHAR(128) NOT NULL,
  GoalName VARCHAR(200) NOT NULL,
  TargetAmount DECIMAL(14,2) NOT NULL,
  CurrentAmount DECIMAL(14,2) NOT NULL,
  TargetDate DATE,
  MonthlyContribution DECIMAL(14,2),
  Status VARCHAR(30)
);

CREATE TABLE LearningContent (
  ContentId VARCHAR(128) PRIMARY KEY,
  Title VARCHAR(200) NOT NULL,
  Topic VARCHAR(100),
  Body TEXT,
  DifficultyLevel VARCHAR(30),
  ImageUrl TEXT,
  IsActive BOOLEAN
);

CREATE TABLE Notifications (
  NotificationId VARCHAR(128) PRIMARY KEY,
  UserId VARCHAR(128) NOT NULL,
  Title VARCHAR(200),
  Message TEXT,
  Type VARCHAR(50),
  ReadStatus BOOLEAN,
  CreatedAt TIMESTAMP
);

CREATE TABLE SupportQueries (
  QueryId VARCHAR(128) PRIMARY KEY,
  UserId VARCHAR(128) NOT NULL,
  Subject VARCHAR(200),
  Message TEXT,
  Status VARCHAR(30),
  AdminResponse TEXT,
  SubmittedOn TIMESTAMP
);
