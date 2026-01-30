using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using System.Data;
using System.Data.SqlClient;

namespace CennetKusEvi_Web.Controllers
{
    public class CustomerController : Controller
    {
        private readonly IConfiguration _configuration;

        public CustomerController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        private string GetConnectionString()
        {
            return _configuration.GetConnectionString("PetShopDB");
        }

        public override void OnActionExecuting(Microsoft.AspNetCore.Mvc.Filters.ActionExecutingContext context)
        {
            var role = HttpContext.Session.GetString("Role");
            if (!string.Equals(role, "Customer", StringComparison.OrdinalIgnoreCase))
            {
                context.Result = RedirectToAction("Login", "Account");
                return;
            }

            base.OnActionExecuting(context);
        }

        [HttpGet]
        public IActionResult Shop(int? storeId)
        {
            DataTable dtStores = new DataTable();
            DataTable dtProducts = new DataTable();
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    using (SqlDataAdapter da = new SqlDataAdapter("SELECT LocationID, Name FROM Location WHERE LocationType = 'Store' ORDER BY Name", conn))
                    {
                        da.Fill(dtStores);
                    }

                    if (storeId.HasValue)
                    {
                        string prodQuery = @"
        SELECT 
            p.ProductID,
            p.ProductType,
            li.Quantity AS Stock,
            p.StandardPrice,
            CASE 
                WHEN p.ProductType = 'Animal' THEN ISNULL(a.BreedType, a.AnimalType)
                WHEN p.ProductType = 'Goods' THEN g.GoodsType
                ELSE 'Ürün'
            END AS DisplayName
        FROM LocationInventory li
        JOIN Product p ON li.ProductID = p.ProductID
        LEFT JOIN Animal a ON p.ProductID = a.ProductID
        LEFT JOIN Goods g ON p.ProductID = g.ProductID
        WHERE li.LocationID = @StoreID AND li.Quantity > 0
        ORDER BY p.ProductType, DisplayName";

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
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Veri Çekme Hatası: " + ex.Message;
            }

            ViewBag.Stores = dtStores;
            ViewBag.Products = dtProducts;
            ViewBag.SelectedStoreId = storeId;
            ViewBag.CustomerName = HttpContext.Session.GetString("CustomerName");
            return View();
        }

        [HttpPost]
        public IActionResult Purchase(int storeId, int productId, int qty)
        {
            int? customerId = HttpContext.Session.GetInt32("CustomerID");
            if (!customerId.HasValue)
            {
                return RedirectToAction("Login", "Account");
            }

            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("sp_AddOrderWithValidation", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@CustomerID", customerId.Value);
                    cmd.Parameters.AddWithValue("@StoreID", storeId);
                    cmd.Parameters.AddWithValue("@InitialPaidAmount", 0);
                    SqlParameter outId = new SqlParameter("@NewOrderID", SqlDbType.Int) { Direction = ParameterDirection.Output };
                    cmd.Parameters.Add(outId);
                    cmd.ExecuteNonQuery();

                    int newID = (int)outId.Value;
                    SqlCommand cmdLine = new SqlCommand("sp_AddOrderLine", conn);
                    cmdLine.CommandType = CommandType.StoredProcedure;
                    cmdLine.Parameters.AddWithValue("@OrderID", newID);
                    cmdLine.Parameters.AddWithValue("@ProductID", productId);
                    cmdLine.Parameters.AddWithValue("@Qty", qty);
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

            return RedirectToAction("Shop", new { storeId });
        }
    }
}
