-- Database Creation and Clean Start
USE master;
GO

-- If the database exists, force disconnect all users (Rollback Immediate)
-- then switch to single-user mode and drop it
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'CennetKusEvi1')
BEGIN
    ALTER DATABASE CennetKusEvi1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CennetKusEvi1;
END
GO

-- Create a fresh database from scratch
CREATE DATABASE CennetKusEvi1;
GO

USE CennetKusEvi1;
GO

--1.LOCATION(Supertype)
CREATE TABLE Location (
    LocationID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    State NVARCHAR(50) NOT NULL,
    Phone VARCHAR(15),
    Email VARCHAR(100),
    LocationType VARCHAR(20) NOT NULL CHECK (LocationType IN ('Warehouse', 'Store', 'BreedingUnit')),
    CONSTRAINT UQ_Location_Email UNIQUE (Email)
);

-- 2. WAREHOUSE (Subtype)
CREATE TABLE Warehouse (
    LocationID INT PRIMARY KEY,
    GoodsCapacity INT NOT NULL DEFAULT 1000,
    CONSTRAINT FK_Warehouse_Location FOREIGN KEY (LocationID) REFERENCES Location(LocationID)
);

-- 3. STORE (Subtype)
CREATE TABLE Store (
    LocationID INT PRIMARY KEY,
    WorkingHours NVARCHAR(50),
    GoodsCapacity INT,
    BirdCapacity INT,
    FishCapacity INT,
    CONSTRAINT FK_Store_Location FOREIGN KEY (LocationID) REFERENCES Location(LocationID)
);

-- 4. BREEDING_UNIT (Subtype)
CREATE TABLE BreedingUnit (
    LocationID INT PRIMARY KEY,
    BirdCapacity INT,
    FishCapacity INT,
    CONSTRAINT FK_BreedingUnit_Location FOREIGN KEY (LocationID) REFERENCES Location(LocationID)
);

-- 5. EMPLOYEE (Supertype) 
-- Age will be added later using ALTER as a computed column
CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Salary DECIMAL(10,2) CHECK (Salary > 0),
    BirthDate DATE NOT NULL,
    Phone VARCHAR(15),
    EmployeeType VARCHAR(20) NOT NULL,
    WorksAtLocationID INT NOT NULL,

    CONSTRAINT FK_Employee_Location FOREIGN KEY (WorksAtLocationID) REFERENCES Location(LocationID)
);

-- 6. BREEDER (Subtype)
CREATE TABLE Breeder (
    EmployeeID INT PRIMARY KEY,
    AnimalSpeciality VARCHAR(50),
    CONSTRAINT FK_Breeder_Employee FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

-- 7. CARRIER (Subtype)
CREATE TABLE Carrier (
    EmployeeID INT PRIMARY KEY,
    ShippingMode VARCHAR(50),
    CONSTRAINT FK_Carrier_Employee FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

-- 8. VENDOR
CREATE TABLE Vendor (
    VendorID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Address NVARCHAR(255),
    Phone VARCHAR(15),
    Email VARCHAR(100),
    TaxID VARCHAR(20) UNIQUE NOT NULL
);

-- 9. PRODUCT (Supertype)
CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductType VARCHAR(20) NOT NULL CHECK (ProductType IN ('Animal', 'Goods')),
    StandardPrice DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

-- 10. GOODS (Subtype)
CREATE TABLE Goods (
    ProductID INT PRIMARY KEY,
    AnimalType VARCHAR(50),
    GoodsType VARCHAR(50),
    Size VARCHAR(20),
    ExpireDate DATE,
    Material VARCHAR(50),
    CONSTRAINT FK_Goods_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

-- 1. NEST TABLOSU (Merkez �s)
CREATE TABLE Nest (
    NestID INT IDENTITY(1,1) PRIMARY KEY,
    LocatedInUnitID INT NOT NULL,       -- Which Breeding Unit?
    ManagedByBreederID INT NOT NULL,   -- Responsible breeder
    AnimalType VARCHAR(50) NOT NULL,
    
    -- �li�kiler
    CONSTRAINT FK_Nest_BreedingUnit FOREIGN KEY (LocatedInUnitID) REFERENCES BreedingUnit(LocationID),
    CONSTRAINT FK_Nest_Breeder FOREIGN KEY (ManagedByBreederID) REFERENCES Breeder(EmployeeID)
);

-- 11. ANIMAL (Subtype) 
CREATE TABLE Animal (
    ProductID INT PRIMARY KEY, 
    HealthStatus VARCHAR(20) DEFAULT 'Healthy',
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    BirthDate DATE NOT NULL,
    Age AS (DATEDIFF(MONTH, BirthDate, GETDATE())),
    AnimalType VARCHAR(50) NOT NULL, 
    BreedType VARCHAR(50),          
    AssignedNestID INT NOT NULL,  
    
     
    CONSTRAINT FK_Animal_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    CONSTRAINT FK_Animal_Nest FOREIGN KEY (AssignedNestID) REFERENCES Nest(NestID)
);

-- 13. SUPPLY
CREATE TABLE Supply (
    SupplyID INT IDENTITY(1,1) PRIMARY KEY,
    VendorID INT NOT NULL,
    WarehouseID INT NOT NULL,
    SupplyDate DATETIME DEFAULT GETDATE(),
    TotalSize DECIMAL(10,2),
    CONSTRAINT FK_Supply_Vendor FOREIGN KEY (VendorID) REFERENCES Vendor(VendorID),
    CONSTRAINT FK_Supply_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(LocationID)
);

-- 14. SUPPLY_LINE
CREATE TABLE SupplyLine (
    SupplyID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    PRIMARY KEY (SupplyID, ProductID),
    CONSTRAINT FK_SupplyLine_Supply FOREIGN KEY (SupplyID) REFERENCES Supply(SupplyID),
    CONSTRAINT FK_SupplyLine_Product FOREIGN KEY (ProductID) REFERENCES Goods(ProductID)
);

-- 15. CUSTOMER
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Phone VARCHAR(15)
);

-- 16. ORDERS 
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    StoreID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    -- Ödenen miktar için ayrı bir alan gerekirse tutulabilir 
    -- ama sipariş toplamı her zaman OrderLine'dan gelmelidir.
    PaidAmount DECIMAL(10,2) DEFAULT 0.00 -- Müşterinin bu sipariş için yaptığı ödeme
    CONSTRAINT FK_Orders_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT FK_Orders_Store FOREIGN KEY (StoreID) REFERENCES Store(LocationID)
);

GO

-- 17. ORDER_LINE - LineTotal will be added using ALTER
CREATE TABLE OrderLine (
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL,
    LineTotal AS (Quantity * UnitPrice),
    PRIMARY KEY (OrderID, ProductID),
    CONSTRAINT FK_OrderLine_Order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_OrderLine_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

-- 18. TRANSFER
CREATE TABLE Transfer (
    TransferID INT IDENTITY(1,1) PRIMARY KEY,
    SourceLocationID INT NOT NULL,
    DestLocationID INT NOT NULL,
    CarrierID INT NOT NULL,
    ProductType VARCHAR(20) NOT NULL CHECK (ProductType IN ('Animal', 'Goods')),
    TransferDate DATETIME DEFAULT GETDATE(),
    ShippingMode VARCHAR(50),
    CONSTRAINT FK_Transfer_Source FOREIGN KEY (SourceLocationID) REFERENCES Location(LocationID),
    CONSTRAINT FK_Transfer_Dest FOREIGN KEY (DestLocationID) REFERENCES Location(LocationID),
    CONSTRAINT FK_Transfer_Carrier FOREIGN KEY (CarrierID) REFERENCES Carrier(EmployeeID),
    CONSTRAINT CK_Transfer_Locations CHECK (SourceLocationID <> DestLocationID)
);

-- 19. TRANSFER_LINE
CREATE TABLE TransferLine (
    TransferID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    PRIMARY KEY (TransferID, ProductID),
    CONSTRAINT FK_TransferLine_Transfer FOREIGN KEY (TransferID) REFERENCES Transfer(TransferID),
    CONSTRAINT FK_TransferLine_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);
GO

-- 20. LOCATION INVENTORY (Per-location stock tracking)
CREATE TABLE LocationInventory (
    LocationID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity >= 0),
    PRIMARY KEY (LocationID, ProductID),
    CONSTRAINT FK_LocationInventory_Location FOREIGN KEY (LocationID) REFERENCES Location(LocationID),
    CONSTRAINT FK_LocationInventory_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);
GO

ALTER TABLE Employee ADD Age AS (DATEDIFF(YEAR, BirthDate, GETDATE()));
GO

-- 1. Each employee's phone number must be unique in the system
ALTER TABLE Employee ADD CONSTRAINT UQ_Employee_Phone UNIQUE (Phone);
GO

-- 2. Location phone numbers must be unique (stores, warehouses, etc.)
ALTER TABLE Location ADD CONSTRAINT UQ_Location_Phone UNIQUE (Phone);
GO


--=================================
--===VIEWS
--=================================


-- 1. Detailed Product List (with Animal / Goods distinction)
CREATE VIEW vw_ProductDetails AS
SELECT p.ProductID, p.ProductType, p.StandardPrice,
       COALESCE(a.AnimalType, g.GoodsType) AS Category,
       COALESCE(a.HealthStatus, 'N/A') AS Health
FROM Product p
LEFT JOIN Animal a ON p.ProductID = a.ProductID
LEFT JOIN Goods g ON p.ProductID = g.ProductID;
GO

-- 2. Store-Based Sales Performance
CREATE OR ALTER VIEW vw_StoreSales AS
SELECT 
    s.LocationID, 
    l.Name AS StoreName, 
    COUNT(DISTINCT o.OrderID) AS TotalOrders, -- Count unique orders (prevents row duplication)
    ISNULL(SUM(ol.LineTotal), 0) AS Revenue   -- Sum totals from OrderLine
FROM Store s
JOIN Location l ON s.LocationID = l.LocationID
LEFT JOIN Orders o ON s.LocationID = o.StoreID
LEFT JOIN OrderLine ol ON o.OrderID = ol.OrderID
GROUP BY s.LocationID, l.Name;
GO

-- 3. Customer Debt Status
CREATE VIEW vw_CustomerDebtInfo AS
SELECT 
    c.CustomerID, 
    c.FirstName + ' ' + c.LastName AS FullName, 
    ISNULL(SUM(ol.LineTotal), 0) - ISNULL(SUM(DISTINCT o.PaidAmount), 0) AS CurrentDebt
FROM Customer c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderLine ol ON o.OrderID = ol.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName;
GO
-- 4. Transfer Tracking View
CREATE VIEW vw_TransferLog AS
SELECT t.TransferID, src.Name AS FromLoc, dst.Name AS ToLoc, e.FirstName + ' ' + e.LastName AS CarrierName, t.TransferDate
FROM Transfer t
JOIN Location src ON t.SourceLocationID = src.LocationID
JOIN Location dst ON t.DestLocationID = dst.LocationID
JOIN Employee e ON t.CarrierID = e.EmployeeID;
GO

CREATE VIEW vw_AllEmployees AS
SELECT 
    e.EmployeeID, e.FirstName, e.LastName, e.EmployeeType, e.Salary, e.Age, l.Name AS LocationName,
    CASE WHEN b.EmployeeID IS NOT NULL THEN 'Breeder' 
         WHEN c.EmployeeID IS NOT NULL THEN 'Carrier' 
         ELSE 'Staff' END AS RoleDetail,
    b.AnimalSpeciality,
    c.ShippingMode
FROM Employee e
JOIN Location l ON e.WorksAtLocationID = l.LocationID
LEFT JOIN Breeder b ON e.EmployeeID = b.EmployeeID
LEFT JOIN Carrier c ON e.EmployeeID = c.EmployeeID;
GO


CREATE VIEW vw_SickAnimals AS
SELECT 
    a.ProductID AS AnimalID,
    p.StandardPrice,
    a.BreedType,
    a.Age AS AgeMonths,
    a.HealthStatus,
    l.Name AS CurrentLocation
FROM Animal a
JOIN Product p ON a.ProductID = p.ProductID
LEFT JOIN Nest n ON a.AssignedNestID = n.NestID
LEFT JOIN BreedingUnit bu ON n.LocatedInUnitID = bu.LocationID
LEFT JOIN Location l ON bu.LocationID = l.LocationID
WHERE a.HealthStatus <> 'Healthy';
GO

CREATE VIEW vw_ExpiringGoods AS
SELECT 
    g.ProductID,
    g.GoodsType,
    g.ExpireDate,
    DATEDIFF(day, GETDATE(), g.ExpireDate) AS DaysRemaining
FROM Goods g
WHERE g.ExpireDate IS NOT NULL AND g.ExpireDate > GETDATE();
GO

-- 7. Location Inventory View
CREATE OR ALTER VIEW vw_LocationInventory AS
SELECT 
    li.LocationID,
    l.Name AS LocationName,
    l.LocationType,
    li.ProductID,
    p.ProductType,
    COALESCE(a.AnimalType, g.GoodsType) AS Category,
    li.Quantity
FROM LocationInventory li
JOIN Location l ON li.LocationID = l.LocationID
JOIN Product p ON li.ProductID = p.ProductID
LEFT JOIN Animal a ON p.ProductID = a.ProductID
LEFT JOIN Goods g ON p.ProductID = g.ProductID
WHERE li.Quantity > 0;
GO





-- =============================================
-- TRIGGER
-- =============================================
-- 1. Prevent Sale of Expired Goods
-- Scenario: If a cashier scans an expired product by mistake, the system must block the sale.
CREATE OR ALTER TRIGGER trg_PreventExpiredGoodsSale
ON OrderLine
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

        -- Check whether the inserted product exists in Goods
    -- and whether its expiration date has passed
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Goods g ON i.ProductID = g.ProductID
        WHERE g.ExpireDate IS NOT NULL AND g.ExpireDate < GETDATE()
    )
    BEGIN
        RAISERROR ('HATA: Son kullanma tarihi geçmiş ürünler satılamaz!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 2. Prevent Salary Decrease
-- Scenario: If an employee's salary is accidentally updated to a lower value, block the operation.
CREATE OR ALTER TRIGGER trg_PreventSalaryDecrease
ON Employee
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN deleted d ON i.EmployeeID = d.EmployeeID
        WHERE i.Salary < d.Salary
    )
    BEGIN
        RAISERROR ('HATA: Çalışan maaşı düşürülemez, sadece artırılabilir!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 3. Transfer Location Rules
-- Animal: BreedingUnit -> Store
-- Goods: Warehouse -> Store
CREATE OR ALTER TRIGGER trg_ValidateTransferLocationRules
ON Transfer
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Location src ON i.SourceLocationID = src.LocationID
        JOIN Location dst ON i.DestLocationID = dst.LocationID
        WHERE i.ProductType = 'Animal'
          AND (src.LocationType <> 'BreedingUnit' OR dst.LocationType <> 'Store')
    )
    BEGIN
        RAISERROR ('HATA: Canlı hayvanlar sadece BreedingUnit -> Store transfer edilebilir!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Location src ON i.SourceLocationID = src.LocationID
        JOIN Location dst ON i.DestLocationID = dst.LocationID
        WHERE i.ProductType = 'Goods'
          AND (src.LocationType <> 'Warehouse' OR dst.LocationType <> 'Store')
    )
    BEGIN
        RAISERROR ('HATA: Goods sadece Warehouse -> Store transfer edilebilir!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 4. Overpayment Control (Data Consistency)
-- Scenario: A customer cannot pay more than the total order amount.
CREATE OR ALTER TRIGGER trg_CheckOverPayment
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

     -- Execute only if PaidAmount is updated
    IF UPDATE(PaidAmount)
    BEGIN
          -- Calculate the actual total cost of the order
        DECLARE @OrderID INT;
        DECLARE @NewPaidAmount DECIMAL(10,2);
        DECLARE @ActualTotalCost DECIMAL(10,2);

        SELECT @OrderID = OrderID, @NewPaidAmount = PaidAmount FROM inserted;

         -- Get the real order total from OrderLine
        -- (using computed column LineTotal)
        SELECT @ActualTotalCost = ISNULL(SUM(LineTotal), 0)
        FROM OrderLine
        WHERE OrderID = @OrderID;

      -- If the paid amount exceeds the order total, block the update
        IF @NewPaidAmount > @ActualTotalCost
        BEGIN
            RAISERROR ('HATA: Ödenen miktar, siparişin toplam tutarından fazla olamaz!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO


--All inter–location deliveries are executed by Carrier employees only.
CREATE OR ALTER TRIGGER trg_ValidateTransferCarrier
ON Transfer
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

     -- Block the operation if the employee performing the transfer
    -- does not exist in the Carrier table
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN Carrier c ON i.CarrierID = c.EmployeeID
        WHERE c.EmployeeID IS NULL  -- Not registered as a Carrier
    )
    BEGIN
        RAISERROR ('HATA: Transfer işlemleri sadece Kurye (Carrier) yetkisine sahip çalışanlarca yapılabilir!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Store is the only sales location.
-- Warehouse and BreedingUnit cannot execute sales.
CREATE OR ALTER TRIGGER trg_ValidateSalesLocation
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Location l ON i.StoreID = l.LocationID
        WHERE l.LocationType <> 'Store'
    )
    BEGIN
        RAISERROR ('HATA: Satış işlemi sadece Mağazalarda (Store) yapılabilir. Depo veya Üretim tesisinden satış yapılamaz!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

--ProductType drives subtype validity
-- Goods tablosuna ekleme yapılırken ProductType kontrolü
CREATE OR ALTER TRIGGER trg_ValidateGoodsSubtype
ON Goods
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Product p ON i.ProductID = p.ProductID
        WHERE p.ProductType <> 'Goods'
    )
    BEGIN
        RAISERROR ('HATA: Product tablosunda tipi "Goods" olmayan bir kayıt Goods tablosuna eklenemez!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Validate ProductType when inserting into the Animal table
CREATE OR ALTER TRIGGER trg_ValidateAnimalSubtype
ON Animal
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN Product p ON i.ProductID = p.ProductID
        WHERE p.ProductType <> 'Animal'
    )
    BEGIN
        RAISERROR ('HATA: Product tablosunda tipi "Animal" olmayan bir kayıt Animal tablosuna eklenemez!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

--Every Nest must contain at least 2 animals.
CREATE OR ALTER TRIGGER trg_EnforceNestMinimumPopulation
ON Animal
AFTER DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

     -- Perform the check only if AssignedNestID was updated
    -- or if an animal record was deleted
    IF (UPDATE(AssignedNestID) OR NOT EXISTS (SELECT 1 FROM inserted))
    BEGIN
        DECLARE @AffectedNestID INT;
        
        -- Identify the affected (previous) nest

        SELECT TOP 1 @AffectedNestID = AssignedNestID FROM deleted;

        IF @AffectedNestID IS NOT NULL
        BEGIN
            DECLARE @RemainingCount INT;
            SELECT @RemainingCount = COUNT(*) FROM Animal WHERE AssignedNestID = @AffectedNestID;

                -- If the remaining number of animals in the nest
            -- drops below 2 and the nest is not empty
            IF @RemainingCount < 2 AND @RemainingCount > 0
            BEGIN
                RAISERROR ('UYARI: İş kuralı gereği bir yuvada en az 2 hayvan bulunmalıdır. İşlem engellendi.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
    END
END;
GO

-- 9. Inventory Update on SupplyLine (Warehouse receives goods)
CREATE OR ALTER TRIGGER trg_UpdateInventoryOnSupplyLine
ON SupplyLine
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE LocationInventory AS target
    USING (
        SELECT s.WarehouseID AS LocationID, i.ProductID, SUM(i.Quantity) AS Qty
        FROM inserted i
        JOIN Supply s ON i.SupplyID = s.SupplyID
        GROUP BY s.WarehouseID, i.ProductID
    ) AS src
    ON target.LocationID = src.LocationID AND target.ProductID = src.ProductID
    WHEN MATCHED THEN
        UPDATE SET Quantity = target.Quantity + src.Qty
    WHEN NOT MATCHED THEN
        INSERT (LocationID, ProductID, Quantity)
        VALUES (src.LocationID, src.ProductID, src.Qty);
END;
GO

-- 10. Inventory Update on TransferLine (Source decreases, destination increases)
CREATE OR ALTER TRIGGER trg_UpdateInventoryOnTransferLine
ON TransferLine
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF CAST(SESSION_CONTEXT(N'skip_inventory_trigger') AS INT) = 1
        RETURN;

    -- Validate product type matches transfer type
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Transfer t ON i.TransferID = t.TransferID
        JOIN Product p ON i.ProductID = p.ProductID
        WHERE p.ProductType <> t.ProductType
    )
    BEGIN
        RAISERROR ('HATA: Transfer tipi ile ürün tipi uyuşmuyor!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Enforce single-animal transfers
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Product p ON i.ProductID = p.ProductID
        WHERE p.ProductType = 'Animal' AND i.Quantity <> 1
    )
    BEGIN
        RAISERROR ('HATA: Canlı hayvan transferlerinde adet 1 olmalıdır!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT t.SourceLocationID AS LocationID, i.ProductID, SUM(i.Quantity) AS Qty
            FROM inserted i
            JOIN Transfer t ON i.TransferID = t.TransferID
            GROUP BY t.SourceLocationID, i.ProductID
        ) m
        LEFT JOIN LocationInventory li
            ON li.LocationID = m.LocationID AND li.ProductID = m.ProductID
        WHERE li.Quantity IS NULL OR li.Quantity < m.Qty
    )
    BEGIN
        RAISERROR ('HATA: Kaynak lokasyonda yeterli stok yok!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE li
    SET li.Quantity = li.Quantity - m.Qty
    FROM LocationInventory li
    JOIN (
        SELECT t.SourceLocationID AS LocationID, i.ProductID, SUM(i.Quantity) AS Qty
        FROM inserted i
        JOIN Transfer t ON i.TransferID = t.TransferID
        GROUP BY t.SourceLocationID, i.ProductID
    ) m
        ON li.LocationID = m.LocationID AND li.ProductID = m.ProductID;

    DELETE li
    FROM LocationInventory li
    JOIN (
        SELECT t.SourceLocationID AS LocationID, i.ProductID
        FROM inserted i
        JOIN Transfer t ON i.TransferID = t.TransferID
        GROUP BY t.SourceLocationID, i.ProductID
    ) m
        ON li.LocationID = m.LocationID AND li.ProductID = m.ProductID
    WHERE li.Quantity = 0;

    MERGE LocationInventory AS target
    USING (
        SELECT t.DestLocationID AS LocationID, i.ProductID, SUM(i.Quantity) AS Qty
        FROM inserted i
        JOIN Transfer t ON i.TransferID = t.TransferID
        GROUP BY t.DestLocationID, i.ProductID
    ) AS src
    ON target.LocationID = src.LocationID AND target.ProductID = src.ProductID
    WHEN MATCHED THEN
        UPDATE SET Quantity = target.Quantity + src.Qty
    WHEN NOT MATCHED THEN
        INSERT (LocationID, ProductID, Quantity)
        VALUES (src.LocationID, src.ProductID, src.Qty);
END;
GO

-- 11. Inventory Update on OrderLine (Store sales decrease stock)
CREATE OR ALTER TRIGGER trg_UpdateInventoryOnOrderLine
ON OrderLine
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF CAST(SESSION_CONTEXT(N'skip_inventory_trigger') AS INT) = 1
        RETURN;

    -- Enforce single-animal sales
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Product p ON i.ProductID = p.ProductID
        WHERE p.ProductType = 'Animal' AND i.Quantity <> 1
    )
    BEGIN
        RAISERROR ('HATA: Canlı hayvan satışlarında adet 1 olmalıdır!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Inventory update (no additional stock check - procedure already validated)
    UPDATE li
    SET li.Quantity = li.Quantity - s.Qty
    FROM LocationInventory li
    JOIN (
        SELECT o.StoreID AS LocationID, i.ProductID, SUM(i.Quantity) AS Qty
        FROM inserted i
        JOIN Orders o ON i.OrderID = o.OrderID
        GROUP BY o.StoreID, i.ProductID
    ) s
        ON li.LocationID = s.LocationID AND li.ProductID = s.ProductID;

    DELETE li
    FROM LocationInventory li
    JOIN (
        SELECT o.StoreID AS LocationID, i.ProductID
        FROM inserted i
        JOIN Orders o ON i.OrderID = o.OrderID
        GROUP BY o.StoreID, i.ProductID
    ) s
        ON li.LocationID = s.LocationID AND li.ProductID = s.ProductID
    WHERE li.Quantity = 0;
END;
GO

-- 12. Inventory Update on Animal Insert (BreedingUnit receives new animals)
CREATE OR ALTER TRIGGER trg_UpdateInventoryOnAnimalInsert
ON Animal
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE LocationInventory AS target
    USING (
        SELECT n.LocatedInUnitID AS LocationID, i.ProductID, COUNT(*) AS Qty
        FROM inserted i
        JOIN Nest n ON i.AssignedNestID = n.NestID
        GROUP BY n.LocatedInUnitID, i.ProductID
    ) AS src
    ON target.LocationID = src.LocationID AND target.ProductID = src.ProductID
    WHEN MATCHED THEN
        UPDATE SET Quantity = target.Quantity + src.Qty
    WHEN NOT MATCHED THEN
        INSERT (LocationID, ProductID, Quantity)
        VALUES (src.LocationID, src.ProductID, src.Qty);
END;
GO


-- =============================================
-- STORED PROCEDURES
-- =============================================


-- =============================================
-- STORED PROCEDURES
-- =============================================

-- 0. Session Context Helper (for disabling triggers when needed)
CREATE OR ALTER PROCEDURE sp_set_session_context
    @key NVARCHAR(MAX),
    @value SQL_VARIANT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_set_session_context @key = @key, @value = @value;
END;
GO

-- 1. Add Order (Only for Store locations)
CREATE OR ALTER PROCEDURE sp_AddOrderWithValidation
    @CustomerID INT,
    @StoreID INT,
    @InitialPaidAmount DECIMAL(10,2) = 0,
    @NewOrderID INT OUTPUT -- ADDED: Returns the newly generated OrderID to the caller
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Location WHERE LocationID = @StoreID AND LocationType = 'Store')
    BEGIN
        INSERT INTO Orders (CustomerID, StoreID, OrderDate, PaidAmount)
        VALUES (@CustomerID, @StoreID, GETDATE(), @InitialPaidAmount);
        
        -- Capture the generated ID and assign it to the output variable
        SET @NewOrderID = SCOPE_IDENTITY();
        
        PRINT 'Order header created. ID: ' + CAST(@NewOrderID AS VARCHAR);
    END
    ELSE
    BEGIN
        RAISERROR('Error: Sales can only be performed through Store-type locations!', 16, 1);
    END
END;
GO

-- 2. Add Product to Order (Automatically pulls price from Product table)
CREATE OR ALTER PROCEDURE sp_AddOrderLine
    @OrderID INT,
    @ProductID INT,
    @Qty INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Price DECIMAL(10,2);
        DECLARE @StoreID INT;
        DECLARE @Available INT;

        SELECT @Price = StandardPrice FROM Product WHERE ProductID = @ProductID;
        SELECT @StoreID = StoreID FROM Orders WHERE OrderID = @OrderID;

        IF @Price IS NULL
        BEGIN
            RAISERROR('Error: Product not found!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @StoreID IS NULL
        BEGIN
            RAISERROR('Error: Order not found!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (
            SELECT 1 FROM Product WHERE ProductID = @ProductID AND ProductType = 'Animal' AND @Qty <> 1
        )
        BEGIN
            RAISERROR('HATA: Canlı hayvan satışlarında adet 1 olmalıdır!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @Available = Quantity
        FROM LocationInventory
        WHERE LocationID = @StoreID AND ProductID = @ProductID;

        IF (@Available IS NULL OR @Available < @Qty)
        BEGIN
            RAISERROR('HATA: Satış için mağazada yeterli stok yok!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- INSERT into OrderLine - trigger will handle inventory update
        INSERT INTO OrderLine (OrderID, ProductID, Quantity, UnitPrice)
        VALUES (@OrderID, @ProductID, @Qty, @Price);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 3. Receive Payment
-- Customer table no longer stores Debt; we update PaidAmount in the Orders table instead.
-- Scenario: Customer pays their oldest unpaid order first.
CREATE OR ALTER PROCEDURE sp_MakePayment
    @CustomerID INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    DECLARE @TargetOrderID INT;
    DECLARE @TotalCost DECIMAL(10,2);
    DECLARE @CurrentPaid DECIMAL(10,2);
    DECLARE @RemainingDebt DECIMAL(10,2);
    DECLARE @AmountToPay DECIMAL(10,2);

    -- 1. Find the customer's OLDEST order that still has remaining debt
    SELECT TOP 1 
        @TargetOrderID = o.OrderID,
        @TotalCost = ISNULL(SUM(ol.LineTotal), 0),
        @CurrentPaid = o.PaidAmount
    FROM Orders o
    LEFT JOIN OrderLine ol ON o.OrderID = ol.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.PaidAmount, o.OrderDate
    HAVING (ISNULL(SUM(ol.LineTotal), 0) - o.PaidAmount) > 0 -- Only orders with remaining debt
    ORDER BY o.OrderDate ASC;

    -- 2. If there is a debt-carrying order, proceed
    IF @TargetOrderID IS NOT NULL
    BEGIN
        -- Calculate remaining debt
        SET @RemainingDebt = @TotalCost - @CurrentPaid;

        -- 3. SMART CHECK: If the given amount is greater than the remaining debt, collect only the debt amount
        IF @Amount > @RemainingDebt
        BEGIN
            SET @AmountToPay = @RemainingDebt;
            PRINT 'WARNING: Customer overpaid. Only the remaining debt (' + CAST(@RemainingDebt AS VARCHAR) + ' TL) was collected.';
        END
        ELSE
        BEGIN
            SET @AmountToPay = @Amount;
        END

        -- 4. Update (Trigger will not throw an error now because we capped the payment)
        UPDATE Orders 
        SET PaidAmount = PaidAmount + @AmountToPay 
        WHERE OrderID = @TargetOrderID;

        PRINT 'Payment Successful. Order ID: ' + CAST(@TargetOrderID AS VARCHAR) + ' | Paid: ' + CAST(@AmountToPay AS VARCHAR);
    END
    ELSE
    BEGIN
        PRINT 'No outstanding unpaid debt found for the customer.';
    END
END;
GO

CREATE PROCEDURE sp_StartTransfer
    @SrcID INT,
    @DstID INT,
    @CarrierID INT,
    @Type VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF (@SrcID <> @DstID) -- Transfer rule validation
    BEGIN
        INSERT INTO Transfer (SourceLocationID, DestLocationID, CarrierID, ProductType, TransferDate)
        VALUES (@SrcID, @DstID, @CarrierID, @Type, GETDATE());
    END
    ELSE
        PRINT 'Source and destination locations cannot be the same!';
END;
GO

-- 4. Create Transfer with Line (stock-aware via triggers)
CREATE OR ALTER PROCEDURE sp_CreateTransferWithLine
    @SrcID INT,
    @DstID INT,
    @CarrierID INT,
    @Type VARCHAR(20),
    @ProductID INT,
    @Qty INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF (@Qty <= 0)
        BEGIN
            RAISERROR('HATA: Miktar 0 veya negatif olamaz!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = @ProductID AND ProductType = @Type)
        BEGIN
            RAISERROR('HATA: Ürün tipi ile seçilen transfer tipi uyuşmuyor!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF (@Type = 'Animal' AND @Qty <> 1)
        BEGIN
            RAISERROR('HATA: Canlı hayvan transferlerinde adet 1 olmalıdır!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DECLARE @Available INT;
        SELECT @Available = Quantity
        FROM LocationInventory
        WHERE LocationID = @SrcID AND ProductID = @ProductID;

        IF (@Available IS NULL OR @Available < @Qty)
        BEGIN
            RAISERROR('HATA: Kaynak lokasyonda yeterli stok yok!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO Transfer (SourceLocationID, DestLocationID, CarrierID, ProductType, TransferDate)
        VALUES (@SrcID, @DstID, @CarrierID, @Type, GETDATE());

        DECLARE @NewTransferID INT = SCOPE_IDENTITY();

        EXEC sp_set_session_context @key = N'skip_inventory_trigger', @value = 1;

        UPDATE LocationInventory
        SET Quantity = Quantity - @Qty
        WHERE LocationID = @SrcID AND ProductID = @ProductID;

        DELETE FROM LocationInventory
        WHERE LocationID = @SrcID AND ProductID = @ProductID AND Quantity = 0;

        MERGE LocationInventory AS target
        USING (SELECT @DstID AS LocationID, @ProductID AS ProductID, @Qty AS Qty) AS src
        ON target.LocationID = src.LocationID AND target.ProductID = src.ProductID
        WHEN MATCHED THEN
            UPDATE SET Quantity = target.Quantity + src.Qty
        WHEN NOT MATCHED THEN
            INSERT (LocationID, ProductID, Quantity)
            VALUES (src.LocationID, src.ProductID, src.Qty);

        INSERT INTO TransferLine (TransferID, ProductID, Quantity)
        VALUES (@NewTransferID, @ProductID, @Qty);

        EXEC sp_set_session_context @key = N'skip_inventory_trigger', @value = 0;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE sp_ProcessSupply
    @VendorID INT,
    @WarehouseID INT,
    @Size DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Location WHERE LocationID = @WarehouseID AND LocationType = 'Warehouse')
    BEGIN
        INSERT INTO Supply (VendorID, WarehouseID, TotalSize, SupplyDate)
        VALUES (@VendorID, @WarehouseID, @Size, GETDATE());
    END
    ELSE
        PRINT 'Error: Supply processing can only be done through Warehouse locations!';
END;
GO

-- 5. Create Supply with Line (stock-aware via trigger)
CREATE OR ALTER PROCEDURE sp_CreateSupplyWithLine
    @VendorID INT,
    @WarehouseID INT,
    @Size DECIMAL(10,2),
    @ProductID INT,
    @Qty INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@Qty <= 0)
    BEGIN
        RAISERROR('HATA: Miktar 0 veya negatif olamaz!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Goods WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR('HATA: Mal kabul sadece Goods ürünleri için yapılabilir!', 16, 1);
        RETURN;
    END

    INSERT INTO Supply (VendorID, WarehouseID, TotalSize, SupplyDate)
    VALUES (@VendorID, @WarehouseID, @Size, GETDATE());

    DECLARE @NewSupplyID INT = SCOPE_IDENTITY();

    INSERT INTO SupplyLine (SupplyID, ProductID, Quantity)
    VALUES (@NewSupplyID, @ProductID, @Qty);
END;
GO

CREATE PROCEDURE sp_UpdateAnimalHealth
    @AnimalID INT,
    @Status VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Animal SET HealthStatus = @Status WHERE ProductID = @AnimalID;
END;
GO

CREATE PROCEDURE sp_AssignEmployeeToLocation
    @EmpID INT,
    @LocID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employee SET WorksAtLocationID = @LocID WHERE EmployeeID = @EmpID;
END;
GO

CREATE PROCEDURE sp_AddNewBreedingNest
    @UnitID INT,
    @BreederID INT,
    @Type VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Nest (LocatedInUnitID, ManagedByBreederID, AnimalType)
    VALUES (@UnitID, @BreederID, @Type);
END;
GO

CREATE PROCEDURE sp_RegisterNewAnimal
    @BreedType VARCHAR(50),
    @AnimalType VARCHAR(50), -- ADDED: Animal type parameter (Bird, Fish, etc.)
    @Gender CHAR(1),
    @BirthDate DATE,
    @NestID INT,
    @Price DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    -- First insert as a Product
    INSERT INTO Product (ProductType, StandardPrice) VALUES ('Animal', @Price);
    DECLARE @NewID INT = SCOPE_IDENTITY();
    
    -- Then insert Animal details (AnimalType is included here)
    INSERT INTO Animal (ProductID, Gender, BirthDate, BreedType, AssignedNestID, HealthStatus, AnimalType)
    VALUES (@NewID, @Gender, @BirthDate, @BreedType, @NestID, 'Healthy', @AnimalType);
END;
GO

CREATE PROCEDURE sp_IncreaseSalary
    @EmployeeID INT,
    @Percentage DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employee
    SET Salary = Salary * (1 + (@Percentage / 100))
    WHERE EmployeeID = @EmployeeID;
END;
GO


--================
-- INDEXES
--================


-- 1. Speed up product searches (Instructor's recommendation)
CREATE INDEX IX_Product_Type ON Product(ProductType);
GO

-- 2. Enable fast reporting based on order dates (Instructor's recommendation)
CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);
GO

-- 3. Improve performance for location-based employee filtering
CREATE INDEX IX_Employee_Location ON Employee(WorksAtLocationID);
GO

-- =============================================
-- SEED DATA (Tek dosyada kurulum icin)
-- =============================================

-- Locations
INSERT INTO Location (Name, City, State, Phone, Email, LocationType) VALUES 
('Samsun Lojistik Merkez', 'Samsun', 'Tekkekoy', '3624440001', 'depo_samsun@petshop.com', 'Warehouse'),
('Sinop Merkez Depo', 'Sinop', 'Merkez', '3682220002', 'depo_sinop@petshop.com', 'Warehouse');

INSERT INTO Warehouse (LocationID, GoodsCapacity) VALUES (1, 12000), (2, 6000);

INSERT INTO Location (Name, City, State, Phone, Email, LocationType) VALUES 
('Atakum Sahil Sube', 'Samsun', 'Atakum', '3624440003', 'atakum@petshop.com', 'Store'),
('Ciftlik Caddesi Sube', 'Samsun', 'Ilkadim', '3624440004', 'ilkadim@petshop.com', 'Store'),
('Sakarya Caddesi Sube', 'Sinop', 'Merkez', '3682220005', 'sakarya@petshop.com', 'Store'),
('Boyabat Sube', 'Sinop', 'Boyabat', '3682220006', 'boyabat@petshop.com', 'Store');

INSERT INTO Store (LocationID, WorkingHours, GoodsCapacity, BirdCapacity, FishCapacity) VALUES 
(3, '09:00-22:00', 800, 80, 150),
(4, '09:00-21:00', 600, 60, 100),
(5, '10:00-20:00', 400, 40, 50),
(6, '09:00-19:00', 300, 20, 40);

INSERT INTO Location (Name, City, State, Phone, Email, LocationType) VALUES 
('Bafra Kus Ciftligi', 'Samsun', 'Bafra', '3624440007', 'bafra@petshop.com', 'BreedingUnit'),
('Gerze Akvaryum Tesisi', 'Sinop', 'Gerze', '3682220008', 'gerze@petshop.com', 'BreedingUnit');

INSERT INTO BreedingUnit (LocationID, BirdCapacity, FishCapacity) VALUES 
(7, 2500, 0),
(8, 0, 4000);

-- Employees
INSERT INTO Employee (FirstName, LastName, Salary, BirthDate, Phone, EmployeeType, WorksAtLocationID) VALUES
('Temel', 'Yilmaz', 18000, '1985-05-10', '5550001001', 'Breeder', 7),
('Dursun', 'Oz', 17500, '1990-03-12', '5550001002', 'Breeder', 7),
('Fadime', 'Demir', 19000, '1988-07-20', '5550001003', 'Breeder', 8),
('Asiye', 'Celik', 17000, '1995-11-05', '5550001004', 'Breeder', 8),
('Idris', 'Kurt', 16500, '1992-01-30', '5550001005', 'Breeder', 7),
('Cemal', 'Koc', 14000, '1998-06-15', '5550002001', 'Carrier', 1),
('Hizir', 'Can', 14500, '1996-09-22', '5550002002', 'Carrier', 1),
('Yunus', 'Gence', 14000, '1999-02-14', '5550002003', 'Carrier', 2),
('Recep', 'Tayfur', 15000, '1994-04-10', '5550002004', 'Carrier', 7),
('Davut', 'Gurses', 15500, '1993-08-08', '5550002005', 'Carrier', 8),
('Merve', 'Yilmaz', 12500, '2000-01-01', '5550003001', 'Staff', 3),
('Emre', 'Karaca', 13000, '1999-05-05', '5550003002', 'Staff', 3),
('Burak', 'Manco', 13500, '1998-10-10', '5550003003', 'Staff', 4),
('Esra', 'Aksu', 12500, '2001-03-21', '5550003004', 'Staff', 4),
('Ozan', 'Tevet', 14000, '1997-12-12', '5550003005', 'Staff', 5),
('Elif', 'Pekkan', 13000, '2000-07-07', '5550003006', 'Staff', 5),
('Sinan', 'Dogulu', 12500, '2002-02-28', '5550003007', 'Staff', 6),
('Gamze', 'Erener', 13000, '1999-09-09', '5550003008', 'Staff', 6),
('Volkan', 'Boz', 12500, '2001-11-11', '5550003009', 'Staff', 3),
('Pelin', 'Acik', 12800, '2000-04-23', '5550003010', 'Staff', 4),
('Arda', 'Gorgulu', 12500, '2002-06-18', '5550003011', 'Staff', 6),
('Busra', 'Bastik', 12500, '2001-08-30', '5550003012', 'Staff', 3),
('Caner', 'Matiz', 12700, '1998-01-15', '5550003013', 'Staff', 4),
('Didem', 'Birsel', 13200, '1995-12-05', '5550003014', 'Staff', 5),
('Engin', 'Demirer', 13100, '1996-03-03', '5550003015', 'Staff', 6);

INSERT INTO Breeder (EmployeeID, AnimalSpeciality) VALUES
(1, 'Birds'), (2, 'Birds'), (3, 'Fish'), (4, 'Fish'), (5, 'Birds');
INSERT INTO Carrier (EmployeeID, ShippingMode) VALUES
(6, 'Van'), (7, 'Truck'), (8, 'Van'), (9, 'Minivan'), (10, 'SpecialTank');

-- Nests
INSERT INTO Nest (LocatedInUnitID, ManagedByBreederID, AnimalType) VALUES
(7, 1, 'Canary'), (7, 1, 'Parrot'), (7, 2, 'Parrot'), (7, 2, 'Canary'), (7, 5, 'Lovebird'),
(7, 5, 'Lovebird'), (7, 1, 'Parrot'), (7, 2, 'Parrot'), (7, 1, 'Canary'), (7, 5, 'Canary'),
(8, 3, 'Goldfish'), (8, 3, 'Betta'), (8, 4, 'Guppy'), (8, 4, 'Tetra'), (8, 3, 'Goldfish'),
(8, 4, 'AngelFish'), (8, 3, 'Discus'), (8, 4, 'Guppy'), (8, 3, 'Betta'), (8, 4, 'Tetra');

-- Products (Goods)
DECLARE @PID INT;
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 150.00); SET @PID = SCOPE_IDENTITY(); INSERT INTO Goods (ProductID, AnimalType, GoodsType, Size, ExpireDate, Material) VALUES (@PID, 'Bird', 'Food', '1kg', '2026-01-01', 'Seeds');
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 450.00); SET @PID = SCOPE_IDENTITY(); INSERT INTO Goods (ProductID, AnimalType, GoodsType, Size, ExpireDate, Material) VALUES (@PID, 'Bird', 'Cage', 'Medium', NULL, 'Metal');
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 80.00); SET @PID = SCOPE_IDENTITY(); INSERT INTO Goods (ProductID, AnimalType, GoodsType, Size, ExpireDate, Material) VALUES (@PID, 'Fish', 'Food', '200g', '2026-12-31', 'Flakes');
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 1200.00); SET @PID = SCOPE_IDENTITY(); INSERT INTO Goods (ProductID, AnimalType, GoodsType, Size, ExpireDate, Material) VALUES (@PID, 'Fish', 'Tank', '50L', NULL, 'Glass');
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 300.00); SET @PID = SCOPE_IDENTITY(); INSERT INTO Goods (ProductID, AnimalType, GoodsType, Size, ExpireDate, Material) VALUES (@PID, 'Cat', 'Food', '3kg', '2026-06-01', 'Chicken');
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 120.00); SET @PID = SCOPE_IDENTITY(); INSERT INTO Goods (ProductID, AnimalType, GoodsType, Size, ExpireDate, Material) VALUES (@PID, 'Dog', 'Accessory', 'L', NULL, 'Leather');

INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 50.00); INSERT INTO Goods (ProductID, AnimalType, GoodsType, ExpireDate) VALUES (SCOPE_IDENTITY(), 'Cat', 'Toy', NULL);
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 25.00); INSERT INTO Goods (ProductID, AnimalType, GoodsType, ExpireDate) VALUES (SCOPE_IDENTITY(), 'Dog', 'Toy', NULL);
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 200.00); INSERT INTO Goods (ProductID, AnimalType, GoodsType, ExpireDate) VALUES (SCOPE_IDENTITY(), 'Bird', 'Vitamin', '2025-12-15');
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 90.00); INSERT INTO Goods (ProductID, AnimalType, GoodsType, ExpireDate) VALUES (SCOPE_IDENTITY(), 'Fish', 'Filter', NULL);
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 600.00); INSERT INTO Goods (ProductID, AnimalType, GoodsType, ExpireDate) VALUES (SCOPE_IDENTITY(), 'Cat', 'Bed', NULL);
INSERT INTO Product (ProductType, StandardPrice) VALUES ('Goods', 500.00); INSERT INTO Goods (ProductID, AnimalType, GoodsType, ExpireDate) VALUES (SCOPE_IDENTITY(), 'Dog', 'Bed', NULL);

-- Animals
EXEC sp_RegisterNewAnimal 'Kanarya', 'Bird', 'M', '2024-01-01', 1, 500.00;
EXEC sp_RegisterNewAnimal 'Kanarya', 'Bird', 'F', '2024-02-15', 1, 500.00;
EXEC sp_RegisterNewAnimal 'Papagan', 'Bird', 'M', '2023-11-20', 2, 2500.00;
EXEC sp_RegisterNewAnimal 'Papagan', 'Bird', 'F', '2023-12-01', 2, 2500.00;
EXEC sp_RegisterNewAnimal 'Muhabbet', 'Bird', 'M', '2024-03-10', 5, 300.00;
EXEC sp_RegisterNewAnimal 'Muhabbet', 'Bird', 'F', '2024-03-12', 5, 300.00;
EXEC sp_RegisterNewAnimal 'Kanarya', 'Bird', 'M', '2024-05-01', 1, 500.00;
EXEC sp_RegisterNewAnimal 'Japon', 'Fish', 'M', '2024-06-01', 11, 50.00;
EXEC sp_RegisterNewAnimal 'Japon', 'Fish', 'F', '2024-06-05', 11, 50.00;
EXEC sp_RegisterNewAnimal 'Lepistes', 'Fish', 'M', '2024-07-01', 13, 25.00;
EXEC sp_RegisterNewAnimal 'Lepistes', 'Fish', 'F', '2024-07-01', 13, 25.00;
EXEC sp_RegisterNewAnimal 'Melek', 'Fish', 'M', '2024-04-10', 16, 150.00;
EXEC sp_RegisterNewAnimal 'Melek', 'Fish', 'F', '2024-04-12', 16, 150.00;

-- Vendors
INSERT INTO Vendor (FirstName, LastName, Address, Phone, Email, TaxID) VALUES
('Ali', 'Tedarik', 'Samsun OSB', '3624440099', 'ali@samsun.com', 'TAX001'),
('Veli', 'Toptan', 'Kutlukent', '3624440098', 'veli@samsun.com', 'TAX002'),
('Ayse', 'Yemci', 'Sinop Sanayi', '3684440003', 'ayse@sinop.com', 'TAX003'),
('Mehmet', 'Kafes', 'Bafra Sanayi', '3624440004', 'mehmet@bafra.com', 'TAX004'),
('Can', 'Akvaryum', 'Gida Borsasi', '3624440005', 'can@gida.com', 'TAX005');

-- Customers
INSERT INTO Customer (FirstName, LastName, Phone) VALUES
('Ahmet', 'Yilmaz', '5321000001'), ('Mehmet', 'Kaya', '5321000002'), ('Ayse', 'Demir', '5321000003'), ('Fatma', 'Sahin', '5321000004'), ('Mustafa', 'Celik', '5321000005'),
('Zeynep', 'Ozturk', '5321000006'), ('Emre', 'Aydin', '5321000007'), ('Burak', 'Yildiz', '5321000008'), ('Selin', 'Arslan', '5321000009'), ('Ceren', 'Dogan', '5321000010'),
('Can', 'Polat', '5321000011'), ('Ezgi', 'Koc', '5321000012'), ('Deniz', 'Kurt', '5321000013'), ('Baris', 'Ozkan', '5321000014'), ('Pelin', 'Cakir', '5321000015'),
('Ozan', 'Erdogan', '5321000016'), ('Merve', 'Guler', '5321000017'), ('Sinan', 'Tekin', '5321000018'), ('Gokhan', 'Yavuz', '5321000019'), ('Elif', 'Ucar', '5321000020'),
('Hakan', 'Simsek', '5321000021'), ('Buse', 'Kilic', '5321000022'), ('Tolga', 'Aksoy', '5321000023'), ('Hande', 'Tas', '5321000024'), ('Kerem', 'Bulut', '5321000025');

-- =============================================
-- INITIAL INVENTORY SETUP
-- =============================================
-- Depolara mal teslimi (supplier'dan alınan mallar)
-- Supply tablosu kullanarak (trg_UpdateInventoryOnSupplyLine otomatik LocationInventory'yi doldurur)

-- Samsun Lojistik Merkez'e (ID:1) mal gelmesi
INSERT INTO Supply (VendorID, WarehouseID, SupplyDate, TotalSize) VALUES (1, 1, GETDATE(), 2000.00);
DECLARE @Supply1 INT = SCOPE_IDENTITY();
INSERT INTO SupplyLine (SupplyID, ProductID, Quantity) VALUES 
(@Supply1, 1, 500), (@Supply1, 2, 100), (@Supply1, 3, 400), (@Supply1, 4, 30), 
(@Supply1, 5, 200), (@Supply1, 6, 100), (@Supply1, 7, 300), (@Supply1, 8, 300);

-- Sinop Merkez Depo'ya (ID:2) mal gelmesi
INSERT INTO Supply (VendorID, WarehouseID, SupplyDate, TotalSize) VALUES (2, 2, GETDATE(), 1500.00);
DECLARE @Supply2 INT = SCOPE_IDENTITY();
INSERT INTO SupplyLine (SupplyID, ProductID, Quantity) VALUES 
(@Supply2, 1, 300), (@Supply2, 3, 250), (@Supply2, 5, 150), (@Supply2, 10, 200),
(@Supply2, 11, 100), (@Supply2, 12, 100);

-- =============================================
-- STORE INVENTORY VIA TRANSFER
-- =============================================
-- Transfer procedure'ü LocationInventory'yi otomatik güncelliyor
-- Ancak seed data'da direkt LocationInventory'ye eklemek daha hızlı

-- Atakum Sahil Sube (ID:3) - Warehouse 1'den transfer
INSERT INTO LocationInventory (LocationID, ProductID, Quantity) VALUES 
(3, 1, 5000), (3, 2, 2500), (3, 3, 4000), (3, 4, 1000),
(3, 5, 3000), (3, 6, 2000), (3, 7, 2500), (3, 8, 2500),
(3, 10, 2500), (3, 11, 2000), (3, 12, 2000);

-- Ciftlik Caddesi Sube (ID:4) - Warehouse 1'den transfer
INSERT INTO LocationInventory (LocationID, ProductID, Quantity) VALUES 
(4, 1, 4500), (4, 2, 2000), (4, 3, 3500), (4, 5, 2500),
(4, 6, 1500), (4, 7, 2250), (4, 8, 2250), (4, 10, 2250),
(4, 11, 1500), (4, 12, 1500);

-- Sakarya Caddesi Sube (ID:5) - Warehouse 2'den transfer
INSERT INTO LocationInventory (LocationID, ProductID, Quantity) VALUES 
(5, 1, 4000), (5, 3, 3000), (5, 5, 2250), (5, 10, 2000),
(5, 11, 1500), (5, 12, 1500), (5, 2, 1750),
(5, 6, 1250), (5, 8, 1750);

-- Boyabat Sube (ID:6) - Warehouse 2'den transfer
INSERT INTO LocationInventory (LocationID, ProductID, Quantity) VALUES 
(6, 1, 3500), (6, 3, 2500), (6, 5, 2000), (6, 6, 1000),
(6, 10, 1750), (6, 11, 1250), (6, 12, 1250),
(6, 2, 1500), (6, 7, 2000);

-- 4. Enable fast lookup by customer phone number
CREATE INDEX IX_Customer_Phone ON Customer(Phone);
GO

-- 5. SEARCH BY ORDER DATE (Explicitly required by the instructor)
-- Scenario: Queries such as "How much did we sell last month?"
-- or "Today's orders" are executed frequently.
CREATE NONCLUSTERED INDEX IX_Product_ProductType 
ON Product(ProductType);
GO

-- 6. SEARCH BY PRODUCT TYPE
-- Scenario: When listing only Animals, the system avoids scanning all products.

-- 7. SEARCH BY CUSTOMER NAME (Real-world usage)
-- Scenario: Quickly retrieving a customer's debt by name.
CREATE NONCLUSTERED INDEX IX_Customer_FullName 
ON Customer(FirstName);
GO

-- 8. STORE-BASED QUERIES (LocationID performance)
-- Scenario: "What is the revenue of Kadıköy Store?"
-- Improves JOIN performance.
CREATE NONCLUSTERED INDEX IX_Orders_StoreID 
ON Orders(StoreID);
GO

-- 9. WAREHOUSE STOCK QUERIES
-- Scenario: "Which goods are stored in the central warehouse?"
CREATE NONCLUSTERED INDEX IX_Supply_WarehouseID 
ON Supply(WarehouseID);
GO

-- 10. ANIMAL–NEST QUERIES
-- Scenario: "Which animals are located in this nest?"
CREATE NONCLUSTERED INDEX IX_Animal_AssignedNestID 
ON Animal(AssignedNestID);
GO
