CREATE SEQUENCE "SEQ_Promotion_Id";
CREATE TABLE "Promotions" (
    "Id" int NOT NULL CONSTRAINT "PK_Promotions" PRIMARY KEY DEFAULT nextval('"SEQ_Promotion_Id"'),
    "Name" varchar(100) NOT NULL,
    CONSTRAINT "UQ_Promotions_Name" UNIQUE ("Name")
);
ALTER SEQUENCE "SEQ_Promotion_Id" OWNED BY "Promotions"."Id";

CREATE SEQUENCE "SEQ_Fighter_Id";
CREATE TABLE "Fighters" (
    "Id" int NOT NULL CONSTRAINT "PK_Fighters" PRIMARY KEY DEFAULT nextval('"SEQ_Fighter_Id"'),
    "FirstName" varchar(100) NOT NULL,
    "LastName" varchar(100) NOT NULL,
    "DOB" timestamp NOT NULL,
    "Country" varchar(100) NOT NULL,
    "HeightInCm" int NOT NULL,
    "ReachInCm" int NOT NULL,
    "WeightInLb" int NOT NULL,

    CONSTRAINT "UQ_Fighters_LastName_FirstName" UNIQUE ("LastName", "FirstName")
);
ALTER SEQUENCE "SEQ_Fighter_Id" OWNED BY "Fighters"."Id";

CREATE SEQUENCE "SEQ_Event_Id";
CREATE TABLE "Events" (
    "Id" int NOT NULL CONSTRAINT "PK_Events" PRIMARY KEY DEFAULT nextval('"SEQ_Event_Id"'),
    "Name" varchar(100) NOT NULL,
    "Date" timestamps NOT NULL,
    "PromotionId" int NOT NULL,
    CONSTRAINT "FK_Events_Promotions" FOREIGN KEY ("PromotionId") REFERENCES "Promotions"
);
ALTER SEQUENCE "SEQ_Event_Id" OWNED BY "Events"."Id";

CREATE SEQUENCE "SEQ_Fight_Id";
CREATE TABLE "Fights" (
    "Id" int NOT NULL CONSTRAINT "PK_Fights" PRIMARY KEY DEFAULT nextval('"SEQ_Fight_Id"'),
    "EventId" int NOT NULL,
    "WeightInLb" int NOT NULL,
    "TookPlace" bit NOT NULL,
    "EarlyStoppage" bit NOT NULL,
    "TitleFight" bit NOT NULL,
    "CatchWeight" bit NOT NULL,
    "Knockout" bit NOT NULL,
    "Submission" bit NOT NULL,
    "Draw" bit NOT NULL,
    
    "WinnerId" int NULL,
    "LoserId" int NULL,

    "DefendingFighterId" int NOT NULL,
    "ContendingFighterId" int NOT NULL,

    CONSTRAINT "FK_Fights_Events" FOREIGN KEY ("EventId") REFERENCES "Events",
    CONSTRAINT "FK_Fights_Fighters_DefendingFighter" FOREIGN KEY ("DefendingFighterId") REFERENCES "Fighters",
    CONSTRAINT "FK_Fights_Fighters_ContendingFighter" FOREIGN KEY ("ContendingFighterId") REFERENCES "Fighters",
    CONSTRAINT "FK_Fights_FightersWinner" FOREIGN KEY ("WinnerId") REFERENCES "Fighters",
    CONSTRAINT "FK_Fights_Loser" FOREIGN KEY ("LoserId") REFERENCES "Fighters"
);
ALTER SEQUENCE "SEQ_Fight_Id" OWNED BY "Fights"."Id";

CREATE TABLE "Rounds" (
    "FightId" int NOT NULL,
    "Number" int NOT NULL,
    "FinalRound" bit NOT NULL,
    "ScheduledDuration" int NOT NULL,
    "ActualDuration" int NOT NULL,
    "EarlyStoppage" bit NULL,

    CONSTRAINT "PK_ROUNDS" PRIMARY KEY ("FightId", "Number"),
    CONSTRAINT "FK_Rounds_Fights" FOREIGN KEY ("FightId") REFERENCES "Fights"
);
