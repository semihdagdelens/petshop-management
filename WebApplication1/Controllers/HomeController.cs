using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using System.Data;
using System.Data.SqlClient;

namespace CennetKusEvi_Web.Controllers
{
    public class HomeController : Controller
    {
        private readonly IConfiguration _configuration;

        public HomeController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public override void OnActionExecuting(Microsoft.AspNetCore.Mvc.Filters.ActionExecutingContext context)
        {
            var role = HttpContext.Session.GetString("Role");
            if (!string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                context.Result = RedirectToAction("Login", "Account");
                return;
            }

            base.OnActionExecuting(context);
        }

        private string GetConnectionString()
        {
            return _configuration.GetConnectionString("PetShopDB");
        }

        // ========================================================
        // 1. DASHBOARD (ANASAYFA)
        // ========================================================
        public IActionResult Index()
        {
            DataTable dtSales = new DataTable();
            DataTable dtSick = new DataTable();
            DataTable dtDebt = new DataTable();
            DataTable dtTransfers = new DataTable();
            DataTable dtEmployees = new DataTable();
            DataTable dtExpiring = new DataTable();
            DataTable dtCatalogStats = new DataTable();

            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    // Tüm raporları çekiyoruz
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT * FROM vw_StoreSales", conn)) { da.Fill(dtSales); }
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT * FROM vw_SickAnimals", conn)) { da.Fill(dtSick); }
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT TOP 10 * FROM vw_CustomerDebtInfo WHERE CurrentDebt > 0 ORDER BY CurrentDebt DESC", conn)) { da.Fill(dtDebt); }
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT TOP 5 * FROM vw_TransferLog ORDER BY TransferDate DESC", conn)) { da.Fill(dtTransfers); }
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT TOP 10 * FROM vw_AllEmployees", conn)) { da.Fill(dtEmployees); }
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT TOP 5 * FROM vw_ExpiringGoods ORDER BY DaysRemaining ASC", conn)) { da.Fill(dtExpiring); }
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT COUNT(*) AS Total, SUM(CASE WHEN ProductType = 'Animal' THEN 1 ELSE 0 END) AS Animals, SUM(CASE WHEN ProductType = 'Goods' THEN 1 ELSE 0 END) AS Goods FROM Product", conn)) { da.Fill(dtCatalogStats); }
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            ViewBag.Sales = dtSales;
            ViewBag.Sick = dtSick;
            ViewBag.Debt = dtDebt;
            ViewBag.Transfers = dtTransfers;
            ViewBag.Employees = dtEmployees;
            ViewBag.Expiring = dtExpiring;
            ViewBag.CatalogStats = dtCatalogStats;

            return View();
        }

        // ========================================================
        // 2. SATIŞ & ÖDEME MODÜLLERİ
        // ========================================================
        // ========================================================
        // DROPDOWN DESTEKLİ SATIŞ SAYFASI (GET)
        // ========================================================
        // ========================================================
        // DROPDOWN DESTEKLİ SATIŞ SAYFASI (GET) - DÜZELTİLMİŞ HALİ
        // ========================================================
        [HttpGet]
        public IActionResult CreateOrder(int? storeId)
        {
            // 1. Müşteri Listesi
            ViewBag.Customers = GetList("SELECT CustomerID, FirstName + ' ' + LastName AS FullName FROM Customer");

            // 2. Mağaza Listesi
            ViewBag.Stores = GetList("SELECT LocationID, Name FROM Location WHERE LocationType = 'Store'");

            // 3. Ürün Listesi (sadece secili magazadaki stoklar)
            DataTable dtProducts = new DataTable();
            if (storeId.HasValue)
            {
                string prodQuery = @"
        SELECT 
            p.ProductID,
            CASE 
                WHEN p.ProductType = 'Animal' THEN ISNULL(a.BreedType, a.AnimalType) 
                WHEN p.ProductType = 'Goods' THEN g.GoodsType
                ELSE 'Ürün' 
            END + ' (' + CAST(p.StandardPrice AS VARCHAR) + ' ₺)' AS DisplayName
        FROM LocationInventory li
        JOIN Product p ON li.ProductID = p.ProductID
        LEFT JOIN Animal a ON p.ProductID = a.ProductID
        LEFT JOIN Goods g ON p.ProductID = g.ProductID
        WHERE li.LocationID = @StoreID AND li.Quantity > 0
        ORDER BY p.ProductType, DisplayName";

                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(prodQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@StoreID", storeId.Value);
                        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            da.Fill(dtProducts);
                        }
                    }
                }
            }

            ViewBag.Products = dtProducts;
            ViewBag.SelectedStoreId = storeId;

            return View();
        }

        // ========================================================
        // 2.5 ÜRÜN KATALOĞU (FİLTRE & ARAMA)
        // ========================================================
        [HttpGet]
        public IActionResult ProductCatalog(string type, string q, string health, string sort)
        {
            DataTable dtProducts = new DataTable();
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    string query = @"
SELECT 
    p.ProductID,
    p.ProductType,
    p.StandardPrice,
    COALESCE(a.AnimalType, g.GoodsType) AS Category,
    a.BreedType,
    a.HealthStatus,
    a.Gender,
    a.BirthDate,
    g.GoodsType AS GoodsName,
    g.Size,
    g.Material,
    g.ExpireDate,
    DATEDIFF(day, GETDATE(), g.ExpireDate) AS DaysRemaining
FROM Product p
LEFT JOIN Animal a ON p.ProductID = a.ProductID
LEFT JOIN Goods g ON p.ProductID = g.ProductID
WHERE 1=1";

                    using (SqlCommand cmd = new SqlCommand())
                    {
                        cmd.Connection = conn;
                        if (!string.IsNullOrWhiteSpace(type))
                        {
                            query += " AND p.ProductType = @Type";
                            cmd.Parameters.AddWithValue("@Type", type);
                        }

                        if (!string.IsNullOrWhiteSpace(q))
                        {
                            query += " AND (COALESCE(a.AnimalType, g.GoodsType) LIKE @Query OR a.BreedType LIKE @Query OR g.Material LIKE @Query)";
                            cmd.Parameters.AddWithValue("@Query", "%" + q + "%");
                        }

                        if (!string.IsNullOrWhiteSpace(health))
                        {
                            query += " AND a.HealthStatus = @Health";
                            cmd.Parameters.AddWithValue("@Health", health);
                        }

                        string orderBy = sort switch
                        {
                            "price_desc" => " ORDER BY p.StandardPrice DESC",
                            "price_asc" => " ORDER BY p.StandardPrice ASC",
                            "newest" => " ORDER BY p.ProductID DESC",
                            _ => " ORDER BY p.ProductID ASC"
                        };

                        cmd.CommandText = query + orderBy;
                        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            da.Fill(dtProducts);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            ViewBag.Products = dtProducts;
            ViewBag.Type = type;
            ViewBag.Query = q;
            ViewBag.Health = health;
            ViewBag.Sort = sort;

            return View();
        }

        [HttpPost]
        public IActionResult CreateOrder(int CustomerID, int StoreID, int ProductID, int Qty)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("sp_AddOrderWithValidation", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@CustomerID", CustomerID);
                    cmd.Parameters.AddWithValue("@StoreID", StoreID);
                    cmd.Parameters.AddWithValue("@InitialPaidAmount", 0);
                    SqlParameter outId = new SqlParameter("@NewOrderID", SqlDbType.Int) { Direction = ParameterDirection.Output };
                    cmd.Parameters.Add(outId);
                    cmd.ExecuteNonQuery();

                    int newID = (int)outId.Value;
                    SqlCommand cmdLine = new SqlCommand("sp_AddOrderLine", conn);
                    cmdLine.CommandType = CommandType.StoredProcedure;
                    cmdLine.Parameters.AddWithValue("@OrderID", newID);
                    cmdLine.Parameters.AddWithValue("@ProductID", ProductID);
                    cmdLine.Parameters.AddWithValue("@Qty", Qty);
                    cmdLine.ExecuteNonQuery();
                }

                TempData["Message"] = "✅ Sipariş oluşturuldu.";
                TempData["Type"] = "success";
            }
            catch (SqlException ex)
            {
                TempData["Message"] = "⛔ İŞ KURALI HATASI: " + ex.Message;
                TempData["Type"] = "danger";
            }
            catch (Exception ex)
            {
                TempData["Message"] = "Sistem Hatası: " + ex.Message;
                TempData["Type"] = "warning";
            }

            return RedirectToAction("CreateOrder", new { storeId = StoreID });
        }

        // ========================================================
        // DROPDOWN DESTEKLİ TAHSİLAT SAYFASI (GET)
        // ========================================================
        [HttpGet]
        public IActionResult MakePayment()
        {
            // Sadece borcu olan müşterileri getirip yanına borcunu yazalım
            string debtQuery = @"
        SELECT c.CustomerID, 
               c.FirstName + ' ' + c.LastName + ' (Güncel Borç: ' + CAST(v.CurrentDebt AS VARCHAR) + ' ₺)' AS FullName
        FROM Customer c
        JOIN vw_CustomerDebtInfo v ON c.CustomerID = v.CustomerID
        WHERE v.CurrentDebt > 0";

            ViewBag.Customers = GetList(debtQuery);

            return View();
        }

        // ========================================================
        // MÜŞTERİ SATIN ALIMLARI (RAPOR)
        // ========================================================
        [HttpGet]
        public IActionResult CustomerPurchases(int? customerId)
        {
            DataTable dtPurchases = new DataTable();
            try
            {
                ViewBag.Customers = GetList("SELECT CustomerID, FirstName + ' ' + LastName AS FullName FROM Customer ORDER BY FirstName, LastName");

                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    string query = @"
        SELECT 
            o.OrderID,
            o.OrderDate,
            c.CustomerID,
            c.FirstName + ' ' + c.LastName AS CustomerName,
            l.Name AS StoreName,
            p.ProductType,
            COALESCE(a.AnimalType, g.GoodsType) AS ProductName,
            ol.Quantity,
            ol.UnitPrice,
            ol.LineTotal
        FROM Orders o
        JOIN Customer c ON o.CustomerID = c.CustomerID
        JOIN Location l ON o.StoreID = l.LocationID
        JOIN OrderLine ol ON o.OrderID = ol.OrderID
        JOIN Product p ON ol.ProductID = p.ProductID
        LEFT JOIN Animal a ON p.ProductID = a.ProductID
        LEFT JOIN Goods g ON p.ProductID = g.ProductID
        WHERE (@CustomerID IS NULL OR c.CustomerID = @CustomerID)
        ORDER BY o.OrderDate DESC, o.OrderID DESC";

                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@CustomerID", (object?)customerId ?? DBNull.Value);
                        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            da.Fill(dtPurchases);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            ViewBag.Purchases = dtPurchases;
            ViewBag.SelectedCustomerId = customerId;
            return View();
        }

        [HttpPost]
        public IActionResult MakePayment(int CustomerID, decimal Amount)
        {
            return ExecuteDbAction(conn =>
            {
                SqlCommand cmd = new SqlCommand("sp_MakePayment", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@CustomerID", CustomerID);
                cmd.Parameters.AddWithValue("@Amount", Amount);
                cmd.ExecuteNonQuery();
                return "✅ Tahsilat işlemi kaydedildi.";
            });
        }

        // ========================================================
        // 3. LOJİSTİK & DEPO MODÜLLERİ
        // ========================================================
        [HttpGet]
        public IActionResult Transfer(int? goodsSrcId, int? animalSrcId)
        {
            try
            {
                ViewBag.Stores = GetList("SELECT LocationID, Name FROM Location WHERE LocationType = 'Store' ORDER BY Name");
                ViewBag.Warehouses = GetList("SELECT LocationID, Name FROM Location WHERE LocationType = 'Warehouse' ORDER BY Name");
                ViewBag.BreedingUnits = GetList("SELECT LocationID, Name FROM Location WHERE LocationType = 'BreedingUnit' ORDER BY Name");
                ViewBag.Carriers = GetList("SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName AS FullName FROM Carrier c JOIN Employee e ON c.EmployeeID = e.EmployeeID");

                DataTable dtGoods = new DataTable();
                if (goodsSrcId.HasValue)
                {
                    using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                    {
                        conn.Open();
                        string query = @"
        SELECT 
            p.ProductID,
            p.ProductType,
            g.GoodsType AS Name,
            p.StandardPrice,
            li.Quantity
        FROM LocationInventory li
        JOIN Product p ON li.ProductID = p.ProductID
        JOIN Goods g ON p.ProductID = g.ProductID
        WHERE li.LocationID = @SrcID AND li.Quantity > 0
        ORDER BY g.GoodsType";
                        using (SqlCommand cmd = new SqlCommand(query, conn))
                        {
                            cmd.Parameters.AddWithValue("@SrcID", goodsSrcId.Value);
                            using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                            {
                                da.Fill(dtGoods);
                            }
                        }
                    }
                }
                ViewBag.GoodsProducts = dtGoods;

                DataTable dtAnimals = new DataTable();
                if (animalSrcId.HasValue)
                {
                    using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                    {
                        conn.Open();
                        string query = @"
        SELECT 
            p.ProductID,
            p.ProductType,
            ISNULL(a.BreedType, a.AnimalType) AS Name,
            p.StandardPrice,
            li.Quantity
        FROM LocationInventory li
        JOIN Product p ON li.ProductID = p.ProductID
        JOIN Animal a ON p.ProductID = a.ProductID
        WHERE li.LocationID = @SrcID AND li.Quantity > 0
        ORDER BY Name";
                        using (SqlCommand cmd = new SqlCommand(query, conn))
                        {
                            cmd.Parameters.AddWithValue("@SrcID", animalSrcId.Value);
                            using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                            {
                                da.Fill(dtAnimals);
                            }
                        }
                    }
                }
                ViewBag.AnimalProducts = dtAnimals;

                ViewBag.Inventory = GetList(@"
        SELECT LocationName, LocationType, ProductType, Category, Quantity
        FROM vw_LocationInventory
        ORDER BY LocationType, LocationName, ProductType, Category");

                ViewBag.RecentTransfers = GetList(@"
        SELECT TOP 10 
            t.TransferID,
            t.TransferDate,
            src.Name AS FromLoc,
            dst.Name AS ToLoc,
            p.ProductType,
            COALESCE(a.AnimalType, g.GoodsType) AS Category,
            tl.Quantity,
            e.FirstName + ' ' + e.LastName AS CarrierName
        FROM Transfer t
        JOIN TransferLine tl ON t.TransferID = tl.TransferID
        JOIN Location src ON t.SourceLocationID = src.LocationID
        JOIN Location dst ON t.DestLocationID = dst.LocationID
        JOIN Product p ON tl.ProductID = p.ProductID
        LEFT JOIN Animal a ON p.ProductID = a.ProductID
        LEFT JOIN Goods g ON p.ProductID = g.ProductID
        JOIN Employee e ON t.CarrierID = e.EmployeeID
        ORDER BY t.TransferDate DESC, t.TransferID DESC");
                ViewBag.SelectedGoodsSrcId = goodsSrcId;
                ViewBag.SelectedAnimalSrcId = animalSrcId;
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            return View();
        }

        [HttpPost]
        public IActionResult Transfer(int SrcID, int DstID, int CarrierID, string Type, int ProductID, int Qty)
        {
            int? goodsSrcId = null;
            int? animalSrcId = null;
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("sp_CreateTransferWithLine", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@SrcID", SrcID);
                    cmd.Parameters.AddWithValue("@DstID", DstID);
                    cmd.Parameters.AddWithValue("@CarrierID", CarrierID);
                    cmd.Parameters.AddWithValue("@Type", Type);
                    cmd.Parameters.AddWithValue("@ProductID", ProductID);
                    cmd.Parameters.AddWithValue("@Qty", Qty);
                    cmd.ExecuteNonQuery();
                }

                TempData["Message"] = "✅ Transfer başarıyla oluşturuldu.";
                TempData["Type"] = "success";

                if (string.Equals(Type, "Goods", StringComparison.OrdinalIgnoreCase))
                {
                    goodsSrcId = SrcID;
                }
                else if (string.Equals(Type, "Animal", StringComparison.OrdinalIgnoreCase))
                {
                    animalSrcId = SrcID;
                }
            }
            catch (SqlException ex)
            {
                TempData["Message"] = "⛔ İŞ KURALI HATASI: " + ex.Message;
                TempData["Type"] = "danger";
            }
            catch (Exception ex)
            {
                TempData["Message"] = "Sistem Hatası: " + ex.Message;
                TempData["Type"] = "warning";
            }

            return RedirectToAction("Transfer", new { goodsSrcId, animalSrcId });
        }

        [HttpGet]
        public IActionResult ReceiveSupply()
        {
            try
            {
                ViewBag.Vendors = GetList("SELECT VendorID, FirstName + ' ' + LastName AS FullName FROM Vendor");
                ViewBag.Warehouses = GetList("SELECT LocationID, Name FROM Location WHERE LocationType = 'Warehouse'");
                ViewBag.Goods = GetList(@"
            SELECT p.ProductID,
                   g.GoodsType + ' (' + CAST(p.StandardPrice AS VARCHAR) + ' ₺)' AS DisplayName
            FROM Goods g
            JOIN Product p ON g.ProductID = p.ProductID");
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            return View();
        }

        [HttpPost]
        public IActionResult ReceiveSupply(int VendorID, int WarehouseID, decimal Size, int ProductID, int Qty)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("sp_CreateSupplyWithLine", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@VendorID", VendorID);
                    cmd.Parameters.AddWithValue("@WarehouseID", WarehouseID);
                    cmd.Parameters.AddWithValue("@Size", Size);
                    cmd.Parameters.AddWithValue("@ProductID", ProductID);
                    cmd.Parameters.AddWithValue("@Qty", Qty);
                    cmd.ExecuteNonQuery();
                }

                TempData["Message"] = "✅ Mal kabul işlemi tamamlandı.";
                TempData["Type"] = "success";
            }
            catch (SqlException ex)
            {
                TempData["Message"] = "⛔ İŞ KURALI HATASI: " + ex.Message;
                TempData["Type"] = "danger";
            }
            catch (Exception ex)
            {
                TempData["Message"] = "Sistem Hatası: " + ex.Message;
                TempData["Type"] = "warning";
            }

            return RedirectToAction("ReceiveSupply");
        }

        // ========================================================
        // 4. İK (MAAŞ & TAYİN) MODÜLLERİ
        // ========================================================
        [HttpGet]
        public IActionResult HR()
        {
            DataTable dtEmployees = new DataTable();
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    using (SqlDataAdapter da = new SqlDataAdapter(@"
        SELECT 
            e.EmployeeID,
            e.FirstName,
            e.LastName,
            e.EmployeeType,
            e.Salary,
            e.Age,
            l.LocationID,
            l.Name AS LocationName,
            l.LocationType
        FROM Employee e
        JOIN Location l ON e.WorksAtLocationID = l.LocationID
        ORDER BY l.Name, e.EmployeeID", conn))
                    {
                        da.Fill(dtEmployees);
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            ViewBag.Employees = dtEmployees;
            return View();
        } // İK Ana Sayfası

        [HttpPost]
        public IActionResult UpdateSalary(int EmployeeID, decimal Percentage)
        {
            return ExecuteDbAction(conn =>
            {
                SqlCommand cmd = new SqlCommand("sp_IncreaseSalary", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@EmployeeID", EmployeeID);
                cmd.Parameters.AddWithValue("@Percentage", Percentage);
                cmd.ExecuteNonQuery();
                return "✅ Maaş güncellemesi yapıldı.";
            });
        }

        [HttpPost]
        public IActionResult AssignLocation(int EmployeeID, int LocID)
        {
            return ExecuteDbAction(conn =>
            {
                SqlCommand cmd = new SqlCommand("sp_AssignEmployeeToLocation", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@EmpID", EmployeeID);
                cmd.Parameters.AddWithValue("@LocID", LocID);
                cmd.ExecuteNonQuery();
                return "✅ Personel yeni lokasyona atandı.";
            });
        }

        // ========================================================
        // 5. ÜRETİM & SAĞLIK (BREEDING & VET) MODÜLLERİ
        // ========================================================
        [HttpGet]
        public IActionResult Breeding(int? unitId)
        {
            DataTable dtNestAnimals = new DataTable();
            try
            {
                ViewBag.BreedingUnits = GetList("SELECT LocationID, Name FROM Location WHERE LocationType = 'BreedingUnit' ORDER BY Name");

                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    string query = @"
        SELECT
            l.LocationID AS UnitID,
            l.Name AS UnitName,
            n.NestID,
            n.AnimalType AS NestType,
            n.ManagedByBreederID,
            e.FirstName + ' ' + e.LastName AS BreederName,
            a.ProductID AS AnimalID,
            a.AnimalType,
            a.BreedType,
            a.Gender,
            a.BirthDate,
            a.HealthStatus,
            p.StandardPrice
        FROM Animal a
        JOIN Product p ON a.ProductID = p.ProductID
        JOIN Nest n ON a.AssignedNestID = n.NestID
        JOIN Location l ON n.LocatedInUnitID = l.LocationID
        LEFT JOIN Breeder b ON n.ManagedByBreederID = b.EmployeeID
        LEFT JOIN Employee e ON b.EmployeeID = e.EmployeeID
        WHERE l.LocationType = 'BreedingUnit'
          AND (@UnitID IS NULL OR l.LocationID = @UnitID)
        ORDER BY l.Name, n.NestID, a.ProductID";

                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@UnitID", (object?)unitId ?? DBNull.Value);
                        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            da.Fill(dtNestAnimals);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            ViewBag.NestAnimals = dtNestAnimals;
            ViewBag.SelectedUnitId = unitId;
            return View();
        }

        [HttpPost]
        public IActionResult AddNest(int UnitID, int BreederID, string Type)
        {
            return ExecuteDbAction(conn =>
            {
                SqlCommand cmd = new SqlCommand("sp_AddNewBreedingNest", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@UnitID", UnitID);
                cmd.Parameters.AddWithValue("@BreederID", BreederID);
                cmd.Parameters.AddWithValue("@Type", Type);
                cmd.ExecuteNonQuery();
                return "✅ Yeni yuva (Nest) açıldı.";
            });
        }

        [HttpPost]
        public IActionResult RegisterAnimal(string BreedType, string AnimalType, string Gender, DateTime BirthDate, int NestID, decimal Price)
        {
            return ExecuteDbAction(conn =>
            {
                SqlCommand cmd = new SqlCommand("sp_RegisterNewAnimal", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@BreedType", BreedType);
                cmd.Parameters.AddWithValue("@AnimalType", AnimalType);
                cmd.Parameters.AddWithValue("@Gender", Gender);
                cmd.Parameters.AddWithValue("@BirthDate", BirthDate);
                cmd.Parameters.AddWithValue("@NestID", NestID);
                cmd.Parameters.AddWithValue("@Price", Price);
                cmd.ExecuteNonQuery();
                return "✅ Yeni hayvan sisteme kaydedildi.";
            });
        }

        [HttpPost]
        public IActionResult UpdateHealth(int AnimalID, string Status)
        {
            return ExecuteDbAction(conn =>
            {
                SqlCommand cmd = new SqlCommand("sp_UpdateAnimalHealth", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@AnimalID", AnimalID);
                cmd.Parameters.AddWithValue("@Status", Status);
                cmd.ExecuteNonQuery();
                return "✅ Hayvanın sağlık durumu güncellendi.";
            });
        }

        // --- YARDIMCI METOT ---
        private IActionResult ExecuteDbAction(Func<SqlConnection, string> databaseAction)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    string successMessage = databaseAction(conn);
                    TempData["Message"] = successMessage;
                    TempData["Type"] = "success";
                }
            }
            catch (SqlException ex)
            {
                TempData["Message"] = "⛔ İŞ KURALI HATASI: " + ex.Message;
                TempData["Type"] = "danger";
            }
            catch (Exception ex)
            {
                TempData["Message"] = "Sistem Hatası: " + ex.Message;
                TempData["Type"] = "warning";
            }
            // İşlem hangi sayfadan geldiyse oraya dönmek mantıklı olur ama
            // basitlik için Index'e yönlendiriyoruz. İstersen Request.Referer kullanabilirsin.
            return RedirectToAction("Index");
        }

        // Yardımcı Metot: SQL sorgusuyla DataTable döndürür (Dropdownları doldurmak için)
        private DataTable GetList(string query)
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(GetConnectionString()))
            {
                conn.Open();
                using (SqlDataAdapter da = new SqlDataAdapter(query, conn))
                {
                    da.Fill(dt);
                }
            }
            return dt;
        }
    }
}
