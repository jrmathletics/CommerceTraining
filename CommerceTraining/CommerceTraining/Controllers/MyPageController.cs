using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using CommerceTraining.Models.Pages;
using CommerceTraining.Models.ViewModels;
using EPiServer.Web.Mvc;
using Mediachase.Commerce.Core;
using Mediachase.Commerce.Customers;

namespace CommerceTraining.Controllers
{
    public class MyPageController : PageController<MyPage>
    {
        public ActionResult Index(MyPage currentPage)
        {
            MyPageViewModel model = new MyPageViewModel(currentPage);

            //var contact = CustomerContext.Current.CurrentContact;
            //var address = contact.PreferredShippingAddress;
            //PopulateModel(address, model);

            return View(model);
        }

        public ActionResult SaveAddress(MyPage currentPage, MyPageViewModel viewModel)
        {
            var contact = CustomerContext.Current.CurrentContact;
            CustomerAddress address;

            if (viewModel.AddressId.Equals(Guid.Empty))
            {
                address = CreateAddress(viewModel);
                contact.AddContactAddress(address);
            }
            else
            {
                address = UpdateAddress(viewModel, contact);
                contact.UpdateContactAddress(address);
            }

            contact.PreferredBillingAddress = address;
            contact.PreferredShippingAddress = address;

            contact.SaveChanges();
            return View("Index", viewModel);
        }

        private CustomerAddress CreateAddress(MyPageViewModel viewModel)
        {
            CustomerAddress address = CustomerAddress.CreateForApplication(AppContext.Current.ApplicationId);
            viewModel.AddressId = address.AddressId;
            PopulateAddress(address,viewModel);
            return address;
        }

        private CustomerAddress UpdateAddress(MyPageViewModel viewModel, CustomerContact customer)
        {
            CustomerAddress address = customer.ContactAddresses.FirstOrDefault(x => x.AddressId == viewModel.AddressId);
            if (address != null)
            {
                PopulateAddress(address,viewModel);
            }
            return address;
        }

        private void PopulateAddress(CustomerAddress address, MyPageViewModel viewModel)
        {
            address.FirstName = viewModel.FirstName;
            address.LastName = viewModel.LastName;
            address.Line1 = viewModel.Address1;
            address.PostalCode= viewModel.PostalCode;
            address.City = viewModel.City;
            address.Name = viewModel.Title;
            address.CountryCode = viewModel.CountryCode;
        }

        private void PopulateModel(CustomerAddress address, MyPageViewModel viewModel)
        {
            viewModel.AddressId = address.AddressId;
            viewModel.FirstName = address.FirstName;
            viewModel.LastName = address.LastName;
            viewModel.Address1 = address.Line1;
            viewModel.PostalCode = address.PostalCode;
            viewModel.City = address.City;
            viewModel.Title = address.Name;
            viewModel.CountryCode = address.CountryCode;
        }
    }
}