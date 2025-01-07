CREATE TABLE Customers (
    CustomerID NUMBER PRIMARY KEY,
    FullName VARCHAR2(100) NOT NULL,
    ContactNumber VARCHAR2(15) NOT NULL,
    Email VARCHAR2(100) UNIQUE NOT NULL,
    Address VARCHAR2(255)
);

CREATE TABLE Policies (
    PolicyID NUMBER PRIMARY KEY,
    PolicyType VARCHAR2(50) NOT NULL,
    PremiumAmount NUMBER(10, 2) NOT NULL,
    DurationYears NUMBER NOT NULL,
    CustomerID NUMBER NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);

CREATE TABLE Claims (
    ClaimID NUMBER PRIMARY KEY,
    ClaimAmount NUMBER(10, 2) NOT NULL,
    DateOfClaim DATE DEFAULT SYSDATE,
    PolicyID NUMBER NOT NULL,
    Status VARCHAR2(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Approved', 'Rejected')),
    FOREIGN KEY (PolicyID) REFERENCES Policies(PolicyID) ON DELETE CASCADE
);

CREATE TABLE Renewals (
    RenewalID NUMBER PRIMARY KEY,
    PolicyID NUMBER NOT NULL,
    RenewalDate DATE NOT NULL,
    ReminderSent CHAR(3) DEFAULT 'No' CHECK (ReminderSent IN ('Yes', 'No')),
    FOREIGN KEY (PolicyID) REFERENCES Policies(PolicyID) ON DELETE CASCADE
);

--Customers values
INSERT INTO Customers (CustomerID, FullName, ContactNumber, Email, Address) 
VALUES (1, 'Rajesh Sharma', '9876543210', 'rajesh.sharma@example.com', '123 MG Road, Mumbai, Maharashtra');

INSERT INTO Customers (CustomerID, FullName, ContactNumber, Email, Address) 
VALUES (2, 'Priya Gupta', '8765432109', 'priya.gupta@example.com', '45 Green Street, Lucknow, Uttar Pradesh');

INSERT INTO Customers (CustomerID, FullName, ContactNumber, Email, Address) 
VALUES (3, 'Amit Patel', '7654321098', 'amit.patel@example.com', '67 Lake View, Ahmedabad, Gujarat');

INSERT INTO Customers (CustomerID, FullName, ContactNumber, Email, Address) 
VALUES (4, 'Deepika Reddy', '6543210987', 'deepika.reddy@example.com', '89 Sunrise Colony, Hyderabad, Telangana');


--Policies values
INSERT INTO Policies (PolicyID, PolicyType, PremiumAmount, DurationYears, CustomerID) 
VALUES (1, 'Health', 12000.00, 5, 1);

INSERT INTO Policies (PolicyID, PolicyType, PremiumAmount, DurationYears, CustomerID) 
VALUES (2, 'Life', 25000.00, 15, 2);

INSERT INTO Policies (PolicyID, PolicyType, PremiumAmount, DurationYears, CustomerID) 
VALUES (3, 'Car', 18000.00, 3, 3);

INSERT INTO Policies (PolicyID, PolicyType, PremiumAmount, DurationYears, CustomerID) 
VALUES (4, 'Home', 22000.00, 10, 4);

INSERT INTO Policies (PolicyID, PolicyType, PremiumAmount, DurationYears, CustomerID) 
VALUES (5, 'Health', 15000.00, 7, 2);


--Claims values
INSERT INTO Claims (ClaimID, ClaimAmount, DateOfClaim, PolicyID, Status) 
VALUES (1, 2000.00, TO_DATE('2024-01-05', 'YYYY-MM-DD'), 1, 'Approved');

INSERT INTO Claims (ClaimID, ClaimAmount, DateOfClaim, PolicyID, Status) 
VALUES (2, 3500.00, TO_DATE('2024-02-15', 'YYYY-MM-DD'), 2, 'Pending');

INSERT INTO Claims (ClaimID, ClaimAmount, DateOfClaim, PolicyID, Status) 
VALUES (3, 1000.00, TO_DATE('2024-03-25', 'YYYY-MM-DD'), 3, 'Rejected');

INSERT INTO Claims (ClaimID, ClaimAmount, DateOfClaim, PolicyID, Status) 
VALUES (4, 4000.00, TO_DATE('2024-04-30', 'YYYY-MM-DD'), 1, 'Pending');


--Renewals values
INSERT INTO Renewals (RenewalID, PolicyID, RenewalDate, ReminderSent) 
VALUES (1, 1, TO_DATE('2025-01-15', 'YYYY-MM-DD'), 'No');

INSERT INTO Renewals (RenewalID, PolicyID, RenewalDate, ReminderSent) 
VALUES (2, 2, TO_DATE('2025-03-10', 'YYYY-MM-DD'), 'Yes');

INSERT INTO Renewals (RenewalID, PolicyID, RenewalDate, ReminderSent) 
VALUES (3, 3, TO_DATE('2024-12-20', 'YYYY-MM-DD'), 'No');

INSERT INTO Renewals (RenewalID, PolicyID, RenewalDate, ReminderSent) 
VALUES (4, 4, TO_DATE('2025-06-05', 'YYYY-MM-DD'), 'No');


SELECT * FROM Customers;


SELECT * FROM Policies;


SELECT * FROM Claims;


SELECT * FROM Renewals;



--Claim Trends by Policy Type
SELECT p.PolicyType, COUNT(c.ClaimID) AS TotalClaims, SUM(c.ClaimAmount) AS TotalClaimedAmount
FROM Policies p
JOIN Claims c ON p.PolicyID = c.PolicyID
GROUP BY p.PolicyType;

--Customers with Upcoming Renewals
SELECT c.FullName, p.PolicyType, r.RenewalDate
FROM Customers c
JOIN Policies p ON c.CustomerID = p.CustomerID
JOIN Renewals r ON p.PolicyID = r.PolicyID
WHERE r.RenewalDate BETWEEN SYSDATE AND SYSDATE + 30;

--Pending Claims
SELECT c.FullName, p.PolicyType, cl.ClaimAmount, cl.Status
FROM Claims cl
JOIN Policies p ON cl.PolicyID = p.PolicyID
JOIN Customers c ON p.CustomerID = c.CustomerID
WHERE cl.Status = 'Pending';


--Trigger that logs a reminder when the renewal date is close
CREATE OR REPLACE TRIGGER RenewalReminder
AFTER INSERT OR UPDATE ON Renewals
FOR EACH ROW
WHEN (NEW.RenewalDate <= SYSDATE + 7 AND NEW.ReminderSent = 'No')
BEGIN
    DBMS_OUTPUT.PUT_LINE('Reminder: Renewal due for Policy ' || :NEW.PolicyID || ' on ' || :NEW.RenewalDate);
   
    :NEW.ReminderSent := 'Yes';
END;
/

INSERT INTO Renewals (RenewalID, PolicyID, RenewalDate, ReminderSent)
VALUES (5, 1, SYSDATE + 5, 'No');

UPDATE Renewals
SET ReminderSent = 'No'
WHERE RenewalID = 5;

SELECT * FROM Renewals WHERE RenewalID = 5;


--procedure to recalculate premiums with discounts

CREATE OR REPLACE PROCEDURE CalculatePremium (
    p_PolicyID IN NUMBER,
    p_DiscountPercentage IN NUMBER
) AS
    v_NewPremium NUMBER;
BEGIN
    SELECT PremiumAmount - (PremiumAmount * p_DiscountPercentage / 100)
    INTO v_NewPremium
    FROM Policies
    WHERE PolicyID = p_PolicyID;

    UPDATE Policies
    SET PremiumAmount = v_NewPremium
    WHERE PolicyID = p_PolicyID;

    DBMS_OUTPUT.PUT_LINE('New Premium for Policy ' || p_PolicyID || ' is ' || v_NewPremium);
END;
/

BEGIN
    CalculatePremium(1, 10); 
    -- Apply 10% discount to PolicyID 1
END;