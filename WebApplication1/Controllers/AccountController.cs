using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using System.Data;
using System.Data.SqlClient;

namespace CennetKusEvi_Web.Controllers
{
    public class AccountController : Controller
    {
        private readonly IConfiguration _configuration;

        public AccountController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        private string GetConnectionString()
        {
            return _configuration.GetConnectionString("PetShopDB");
        }

        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Login(string role, string username, string password, int? customerId)
        {
            if (string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                var adminUser = _configuration["AdminAuth:Username"];
                var adminPass = _configuration["AdminAuth:Password"];
                if (!string.IsNullOrWhiteSpace(adminUser) &&
                    !string.IsNullOrWhiteSpace(adminPass) &&
                    string.Equals(username, adminUser, StringComparison.OrdinalIgnoreCase) &&
                    password == adminPass)
                {
                    HttpContext.Session.SetString("Role", "Admin");
                    return RedirectToAction("Index", "Home");
                }

                ViewBag.Error = "Admin giriş bilgileri hatalı.";
                return View();
            }

            if (customerId.HasValue)
            {
                DataTable dtCustomer = new DataTable();
                using (SqlConnection conn = new SqlConnection(GetConnectionString()))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand("SELECT CustomerID, FirstName, LastName FROM Customer WHERE CustomerID = @CustomerID", conn))
                    {
                        cmd.Parameters.AddWithValue("@CustomerID", customerId.Value);
                        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            da.Fill(dtCustomer);
                        }
                    }
                }

                if (dtCustomer.Rows.Count > 0)
                {
                    HttpContext.Session.SetString("Role", "Customer");
                    HttpContext.Session.SetInt32("CustomerID", customerId.Value);
                    var fullName = $"{dtCustomer.Rows[0]["FirstName"]} {dtCustomer.Rows[0]["LastName"]}";
                    HttpContext.Session.SetString("CustomerName", fullName);
                    return RedirectToAction("Shop", "Customer");
                }
            }

            ViewBag.Error = "Müşteri ID bulunamadı.";
            return View();
        }

        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Login");
        }
    }
}
