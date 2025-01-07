
CREATE TABLE Employees (
    Employee_ID NUMBER PRIMARY KEY,
    Employee_Name VARCHAR2(100),
    Department VARCHAR2(50),
    Base_Salary NUMBER(15, 2),
    Bonus NUMBER(15, 2) DEFAULT 0,
    Deductions NUMBER(15, 2) DEFAULT 0,
    Net_Salary NUMBER(15, 2),
    Created_Date DATE DEFAULT SYSDATE
);


CREATE TABLE Attendance (
    Attendance_ID NUMBER PRIMARY KEY,
    Employee_ID NUMBER,
    Days_Worked NUMBER,
    Total_Days NUMBER DEFAULT 30,
    FOREIGN KEY (Employee_ID) REFERENCES Employees(Employee_ID)
);


CREATE TABLE Salary_Slabs (
    Slab_ID NUMBER PRIMARY KEY,
    Min_Salary NUMBER(15, 2),
    Max_Salary NUMBER(15, 2),
    Tax_Percentage NUMBER(5, 2)
);


CREATE TABLE Payroll_Log (
    Payroll_ID NUMBER PRIMARY KEY,
    Employee_ID NUMBER,
    Net_Salary NUMBER(15, 2),
    Payment_Date DATE DEFAULT SYSDATE,
    FOREIGN KEY (Employee_ID) REFERENCES Employees(Employee_ID)
);


INSERT INTO Employees (Employee_ID, Employee_Name, Department, Base_Salary, Bonus, Deductions) 
VALUES (1, 'Alice Johnson', 'IT', 50000, 5000, 2000);

INSERT INTO Employees (Employee_ID, Employee_Name, Department, Base_Salary, Bonus, Deductions) 
VALUES (2, 'Bob Smith', 'HR', 40000, 3000, 1500);


INSERT INTO Attendance (Attendance_ID, Employee_ID, Days_Worked) 
VALUES (1, 1, 28);

INSERT INTO Attendance (Attendance_ID, Employee_ID, Days_Worked) 
VALUES (2, 2, 25);


INSERT INTO Salary_Slabs (Slab_ID, Min_Salary, Max_Salary, Tax_Percentage) 
VALUES (1, 0, 30000, 5);

INSERT INTO Salary_Slabs (Slab_ID, Min_Salary, Max_Salary, Tax_Percentage) 
VALUES (2, 30001, 60000, 10);

CREATE OR REPLACE PROCEDURE Calculate_Net_Salary IS
BEGIN
    FOR emp IN (SELECT * FROM Employees) LOOP
        DECLARE
            v_attendance_percentage NUMBER;
            v_tax_percentage NUMBER;
            v_net_salary NUMBER;
        BEGIN
            
            SELECT (Days_Worked / Total_Days) * 100 INTO v_attendance_percentage
            FROM Attendance
            WHERE Employee_ID = emp.Employee_ID;

            
            SELECT Tax_Percentage INTO v_tax_percentage
            FROM Salary_Slabs
            WHERE emp.Base_Salary BETWEEN Min_Salary AND Max_Salary;

            
            v_net_salary := (emp.Base_Salary + emp.Bonus - emp.Deductions) 
                            * (v_attendance_percentage / 100)
                            * (1 - (v_tax_percentage / 100));

            
            UPDATE Employees
            SET Net_Salary = v_net_salary
            WHERE Employee_ID = emp.Employee_ID;
        END;
    END LOOP;
    COMMIT;
END Calculate_Net_Salary;
/

CREATE OR REPLACE PROCEDURE Generate_Payroll IS
BEGIN
    FOR emp IN (SELECT Employee_ID, Net_Salary FROM Employees) LOOP
        INSERT INTO Payroll_Log (Payroll_ID, Employee_ID, Net_Salary) 
        VALUES ((SELECT NVL(MAX(Payroll_ID), 0) + 1 FROM Payroll_Log), emp.Employee_ID, emp.Net_Salary);
    END LOOP;
    COMMIT;
END Generate_Payroll;
/

CREATE OR REPLACE TRIGGER Update_Net_Salary
AFTER UPDATE OF Base_Salary, Bonus, Deductions ON Employees
FOR EACH ROW
BEGIN
    Calculate_Net_Salary;
END Update_Net_Salary;
/

CREATE OR REPLACE TRIGGER Log_Attendance_Update
AFTER INSERT OR UPDATE OF Days_Worked ON Attendance
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Attendance updated for Employee ID: ' || :NEW.Employee_ID || 
                         ', Days Worked: ' || :NEW.Days_Worked);
END Log_Attendance_Update;
/

BEGIN
    Calculate_Net_Salary;
END;
/

BEGIN
    Generate_Payroll;
END;
/

-- View employees
SELECT * FROM Employees;

-- View payroll log
SELECT * FROM Payroll_Log;
