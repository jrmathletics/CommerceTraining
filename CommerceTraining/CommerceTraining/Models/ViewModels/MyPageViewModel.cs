using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using CommerceTraining.Models.Pages;
using Mediachase.Commerce.Customers;

namespace CommerceTraining.Models.ViewModels
{
    public class MyPageViewModel : PageViewModel<MyPage>
    {
        public MyPageViewModel(MyPage currentPage) : base(currentPage)
        {
            CurrentCustomer = CustomerContext.Current.CurrentContact;
        }
        
        public MyPageViewModel() { }
        
        public Guid AddressId { get; set; }
        public string Title { get; set; }
        public string FirstName { get; set; }
        public string LastName{ get; set; }
        public string Address1{ get; set; }
        public string PostalCode{ get; set; }
        public string City { get; set; }
        public string CountryCode{ get; set; }
        public CustomerContact CurrentCustomer { get; set; }
    }
}