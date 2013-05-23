CREATE TABLE IF NOT EXISTS Promotions (
    Id INT NOT NULL AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    CONSTRAINT PRIMARY KEY CLUSTERED (Id),
    UNIQUE INDEX UQ_Promotions_Name (Name)
);

CREATE TABLE IF NOT EXISTS Fighters (
    Id INT NOT NULL AUTO_INCREMENT,
    FirstName varchar(100) NOT NULL,
    LastName varchar(100) NOT NULL,
    DOB datetime NOT NULL,
    Country varchar(100) NOT NULL,
    HeightInCm int NOT NULL,
    ReachInCm int NOT NULL,
    WeightInLb int NOT NULL,

    CONSTRAINT PRIMARY KEY CLUSTERED (Id),
    UNIQUE INDEX UQ_Fighters_LastName_FirstName (LastName, FirstName)
);

CREATE TABLE IF NOT EXISTS Events (
    Id INT NOT NULL AUTO_INCREMENT,
    Name varchar(100) NOT NULL,
    Date datetime NOT NULL,
    PromotionId int NOT NULL,

    CONSTRAINT PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT FK_Events_Promotions FOREIGN KEY (PromotionId) REFERENCES Promotions (Id)
);

CREATE TABLE IF NOT EXISTS Fights (
    Id INT NOT NULL AUTO_INCREMENT,
    EventId int NOT NULL,

    WeightInLb int NOT NULL,
    TookPlace bit NOT NULL,
    EarlyStoppage bit NOT NULL,
    TitleFight bit NOT NULL,
    CatchWeight bit NOT NULL,
    Knockout bit NOT NULL,
    Submission bit NOT NULL,
    Draw bit NOT NULL,

    WinnerId int NULL,
    LoserId int NULL,

    DefendingFighterId int NOT NULL,
    ContendingFighterId int NOT NULL,

    CONSTRAINT PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT FK_Fights_Events FOREIGN KEY (EventId) REFERENCES Events (Id),
    CONSTRAINT FK_Fights_Fighters_DefendingFighter FOREIGN KEY (DefendingFighterId) REFERENCES Fighters (Id),
    CONSTRAINT FK_Fights_Fighters_ContendingFighter FOREIGN KEY (ContendingFighterId) REFERENCES Fighters (Id),
    CONSTRAINT FK_Fights_Fighters_Winner FOREIGN KEY (WinnerId) REFERENCES Fighters (Id),
    CONSTRAINT FK_Fights_Fighters_Loser FOREIGN KEY (LoserId) REFERENCES Fighters (Id)
);

CREATE TABLE IF NOT EXISTS Rounds (
    FightId int NOT NULL,
    Number int NOT NULL,

    FinalRound bit NOT NULL,
    ScheduledDuration int NOT NULL,
    ActualDuration int NOT NULL,
    EarlyStoppage bit NULL,

    CONSTRAINT PRIMARY KEY CLUSTERED (FightId, Number),
    CONSTRAINT FK_Rounds_Fights FOREIGN KEY (FightId) REFERENCES Fights (Id)
);